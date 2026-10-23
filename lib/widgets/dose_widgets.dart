import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/person_dose.dart';
import '../models/session_dosimeter.dart';
import '../models/session_person_link.dart';
import '../services/session_dose_calculator.dart';
import '../services/display_units.dart';

/// Dózis megjelenítése: 1 mSv alatt µSv-ben, fölötte mSv-ben.
String formatDose(BuildContext context, double microSv) {
  final locale = Localizations.localeOf(context).toString();
  final target = DisplayUnits.dose.value;
  if (target.isNotEmpty) {
    final v = DisplayUnits.doseFromMicroSv(microSv, target);
    return '${NumberFormat('0.###', locale).format(v)} $target';
  }
  if (microSv.abs() >= 1000) {
    return '${NumberFormat('0.###', locale).format(microSv / 1000)} mSv';
  }
  final pattern = microSv.abs() < 1 ? '0.###' : '0.##';
  return '${NumberFormat(pattern, locale).format(microSv)} µSv';
}

/// Dózis beviteli mező vezérlője: szöveg + egység (µSv / mSv). Az értéket
/// mindig µSv-ben adja vissza.
class DoseFieldController {
  DoseFieldController();

  final text = TextEditingController();
  final milli = ValueNotifier<bool>(false);
  String _initialText = '';
  bool _initialMilli = false;

  /// Kezdőérték beállítása (µSv); 1 mSv fölött mSv-ben jelenik meg.
  /// A mező ezután nem számít módosítottnak.
  void setMicroSv(double? microSv, String locale) {
    final useMilli = microSv != null && microSv >= 1000;
    milli.value = useMilli;
    if (microSv == null || microSv == 0) {
      text.text = '';
    } else {
      final shown = useMilli ? microSv / 1000 : microSv;
      text.text = NumberFormat('0.###', locale).format(shown);
    }
    _initialText = text.text;
    _initialMilli = milli.value;
  }

  /// Program által beírt érték (pl. a pontokból számolt dózis) úgy, hogy a
  /// mező módosítottnak számítson, és mentéskor íródjon.
  void setMicroSvKeepDirty(double microSv, String locale) {
    final useMilli = microSv >= 1000;
    milli.value = useMilli;
    final shown = useMilli ? microSv / 1000 : microSv;
    text.text = NumberFormat('0.###', locale).format(shown);
  }

  bool get isDirty => text.text != _initialText || milli.value != _initialMilli;

  /// `null`: üres vagy érvénytelen. Az üres mező 0-nak számít a hívó oldalon.
  double? get microSv {
    final raw = text.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    final v = double.tryParse(raw);
    if (v == null || v < 0) return null;
    return milli.value ? v * 1000 : v;
  }

  bool get isEmpty => text.text.trim().isEmpty;

  void dispose() {
    text.dispose();
    milli.dispose();
  }
}

/// Szám + egységválasztó (µSv / mSv).
class DoseValueField extends StatelessWidget {
  const DoseValueField({
    super.key,
    required this.controller,
    required this.label,
    this.required = false,
  });

  final DoseFieldController controller;
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return ValueListenableBuilder<bool>(
      valueListenable: controller.milli,
      builder: (context, milli, _) => TextFormField(
        controller: controller.text,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<bool>(
                value: milli,
                isDense: true,
                items: const [
                  DropdownMenuItem(value: false, child: Text('µSv')),
                  DropdownMenuItem(value: true, child: Text('mSv')),
                ],
                onChanged: (v) => controller.milli.value = v ?? false,
              ),
            ),
          ),
        ),
        validator: (_) {
          if (controller.isEmpty) return required ? loc.requiredFieldError : null;
          return controller.microSv == null ? loc.invalidValueError : null;
        },
      ),
    );
  }
}

/// Egy felmérés résztvevőinek felmérési dózisa egy űrlapon. Egy mező személyenként,
/// mellette az "éves dózisba beszámít" jelölő, és egy gomb, amely a felmérés
/// dózisteljesítmény-pontjaiból számolja a dózist (mindenkire ugyanazt).
/// A [SessionDosesEditorState.save] validál és csak a módosított értékeket írja.
class SessionDosesEditor extends StatefulWidget {
  const SessionDosesEditor({
    super.key,
    required this.surveySessionId,
    required this.persons,
    required this.doses,
    this.showNames = true,
  });

  final int surveySessionId;
  final List<AttachedPerson> persons;
  final SessionDoseSnapshot doses;
  final bool showNames;

  @override
  State<SessionDosesEditor> createState() => SessionDosesEditorState();
}

class SessionDosesEditorState extends State<SessionDosesEditor> {
  final _formKey = GlobalKey<FormState>();
  final _values = <int, DoseFieldController>{};
  final _include = <int, bool>{};
  final _initialInclude = <int, bool>{};
  String? _calcInfo;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final locale = Localizations.localeOf(context).toString();
    for (final a in widget.persons) {
      final id = a.person.id!;
      final dose = widget.doses.sessionDoseOf(id);
      _values[id] = DoseFieldController()
        ..setMicroSv(dose?.doseMicroSv, locale);
      final include = dose?.includeAnnual ?? true;
      _include[id] = include;
      _initialInclude[id] = include;
    }
  }

  @override
  void dispose() {
    for (final c in _values.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// A felmérés dózisteljesítmény-pontjaiból számított dózis beírása minden
  /// résztvevőhöz (mentésig nem íródik az adatbázisba).
  Future<void> _calculate() async {
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final locale = Localizations.localeOf(context).toString();
    final points = await DatabaseHelper.instance
        .getMeasurementPoints(widget.surveySessionId);
    final result = SessionDoseCalculator.fromPoints(points);
    if (!mounted) return;
    if (result == null) {
      setState(() => _calcInfo = null);
      messenger.showSnackBar(
        SnackBar(content: Text(loc.calcDoseNeedTwoPoints)),
      );
      return;
    }
    for (final a in widget.persons) {
      _values[a.person.id!]!
          .setMicroSvKeepDirty(result.doseMicroSv, locale);
    }
    setState(() => _calcInfo = loc.calcDoseResultInfo(result.pointCount));
  }

  /// Validál és ment; `false`, ha érvénytelen mező van.
  Future<bool> save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    for (final a in widget.persons) {
      final id = a.person.id!;
      final value = _values[id]!;
      final includeChanged = _include[id] != _initialInclude[id];
      if (!value.isDirty && !includeChanged) continue;
      await DatabaseHelper.instance.setSessionDose(
        personId: id,
        surveySessionId: widget.surveySessionId,
        doseMicroSv: value.microSv ?? 0,
        includeAnnual: _include[id],
      );
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.calculate_outlined),
              label: Text(loc.calcDoseFromPointsButton),
            ),
          ),
          if (_calcInfo != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _calcInfo!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          for (final a in widget.persons) ...[
            if (widget.showNames)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Text(
                  a.person.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            DoseValueField(
              controller: _values[a.person.id!]!,
              label: loc.sessionDoseLabel,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: _include[a.person.id!] ?? true,
              title: Text(loc.includeInAnnualLabel),
              onChanged: (v) =>
                  setState(() => _include[a.person.id!] = v ?? true),
            ),
            for (final d in widget.doses.dosimetersOf(a.person.id!))
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${dosimeterKindLabel(loc, d.kind)} · ${d.identifier}: '
                  '${d.resolvedDoseUsv == null ? loc.dosimeterNoReading : formatDose(context, d.resolvedDoseUsv!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// A dózis forrásának megjelenési neve és ikonja (felmérési / passzív).
String doseSourceLabel(AppLocalizations loc, DoseSource source) =>
    switch (source) {
      DoseSource.session => loc.sessionDoseLabel,
      DoseSource.passive => loc.doseSourcePassive,
    };

IconData doseSourceIcon(DoseSource source) => switch (source) {
      DoseSource.session => Icons.edit_outlined,
      DoseSource.passive => Icons.badge_outlined,
    };

/// A doziméter típusának megjelenési neve.
String dosimeterKindLabel(AppLocalizations loc, DosimeterKind kind) =>
    switch (kind) {
      DosimeterKind.epdGamma => loc.dosimeterKindEpdGamma,
      DosimeterKind.epdNeutron => loc.dosimeterKindEpdNeutron,
      DosimeterKind.tlOfficial => loc.dosimeterKindTlOfficial,
      DosimeterKind.tlWorkplace => loc.dosimeterKindTlWorkplace,
    };

/// "Felmérési X · Doziméter Y · Passzív Z" összefoglaló sor.
String doseBreakdownText(BuildContext context, DoseTotals t) {
  final loc = AppLocalizations.of(context)!;
  return '${loc.sessionDoseLabel} ${formatDose(context, t.session)} · '
      '${loc.dosimeterDoseLabel} ${formatDose(context, t.dosimeter)} · '
      '${loc.doseSourcePassive} ${formatDose(context, t.passive)}';
}
