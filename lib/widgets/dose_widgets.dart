import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/person_dose.dart';
import '../models/session_person_link.dart';

/// Dózis megjelenítése: 1 mSv alatt µSv-ben, fölötte mSv-ben.
String formatDose(BuildContext context, double microSv) {
  final locale = Localizations.localeOf(context).toString();
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

/// Egy felmérés résztvevőinek online és manuális dózisa egy űrlapon — a
/// felmérés lezárásakor és a résztvevők listáján is ezt használjuk.
/// A [SessionDosesEditorState.save] validál és csak a módosított értékeket
/// írja az adatbázisba.
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
  final Map<int, Map<DoseSource, double>> doses;
  final bool showNames;

  @override
  State<SessionDosesEditor> createState() => SessionDosesEditorState();
}

class SessionDosesEditorState extends State<SessionDosesEditor> {
  final _formKey = GlobalKey<FormState>();
  final _online = <int, DoseFieldController>{};
  final _manual = <int, DoseFieldController>{};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final locale = Localizations.localeOf(context).toString();
    for (final a in widget.persons) {
      final id = a.person.id!;
      final d = widget.doses[id] ?? const {};
      _online[id] = DoseFieldController()
        ..setMicroSv(d[DoseSource.online], locale);
      _manual[id] = DoseFieldController()
        ..setMicroSv(d[DoseSource.manual], locale);
    }
  }

  @override
  void dispose() {
    for (final c in [..._online.values, ..._manual.values]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Validál és ment; `false`, ha érvénytelen mező van.
  Future<bool> save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    for (final a in widget.persons) {
      final id = a.person.id!;
      for (final (source, c) in [
        (DoseSource.online, _online[id]!),
        (DoseSource.manual, _manual[id]!),
      ]) {
        if (!c.isDirty) continue;
        await DatabaseHelper.instance.setSessionDose(
          personId: id,
          surveySessionId: widget.surveySessionId,
          source: source,
          doseMicroSv: c.microSv ?? 0,
        );
      }
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
              controller: _online[a.person.id!]!,
              label: loc.onlineDoseLabel,
            ),
            const SizedBox(height: 8),
            DoseValueField(
              controller: _manual[a.person.id!]!,
              label: loc.manualDoseLabel,
            ),
          ],
        ],
      ),
    );
  }
}

/// A dózisforrás megjelenítési neve és ikonja.
String doseSourceLabel(AppLocalizations loc, DoseSource source) =>
    switch (source) {
      DoseSource.online => loc.doseSourceOnline,
      DoseSource.manual => loc.doseSourceManual,
      DoseSource.passive => loc.doseSourcePassive,
    };

IconData doseSourceIcon(DoseSource source) => switch (source) {
      DoseSource.online => Icons.sensors,
      DoseSource.manual => Icons.edit_outlined,
      DoseSource.passive => Icons.badge_outlined,
    };

/// "online X · manuális Y · passzív Z" összefoglaló sor.
String doseBreakdownText(BuildContext context, DoseTotals t) {
  final loc = AppLocalizations.of(context)!;
  return loc.doseBreakdownLabel(
    formatDose(context, t.online),
    formatDose(context, t.manual),
    formatDose(context, t.passive),
  );
}
