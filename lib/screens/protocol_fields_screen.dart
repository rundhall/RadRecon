import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../l10n/domain_labels.dart';
import '../models/protocol_field.dart';
import '../models/survey_purpose.dart';
import '../services/waste_assessment.dart';

/// Egy felmérés jegyzőkönyv-mezőinek szerkesztése: a hulladék-cél beépített
/// mezői és a felhasználó egyedi mezői. Az egyedi mezők minden célnál
/// megjelennek a jegyzőkönyvben.
class ProtocolFieldsScreen extends StatefulWidget {
  const ProtocolFieldsScreen({super.key, required this.surveySessionId});

  final int surveySessionId;

  @override
  State<ProtocolFieldsScreen> createState() => _ProtocolFieldsScreenState();
}

/// Egy szerkesztés alatt álló mező beviteli vezérlői.
class _FieldDraft {
  _FieldDraft({required this.key, String? customLabel, String? value})
      : labelCtrl = TextEditingController(text: customLabel ?? ''),
        valueCtrl = TextEditingController(text: value ?? '');

  final String key;
  final TextEditingController labelCtrl;
  final TextEditingController valueCtrl;

  void dispose() {
    labelCtrl.dispose();
    valueCtrl.dispose();
  }
}

/// Egy nuklid beviteli vezérlői (hulladék-cél).
class _IsotopeDraft {
  _IsotopeDraft({
    String nuclide = '',
    String activity = '',
    this.halfLifeOver30y = false,
  })  : nuclideCtrl = TextEditingController(text: nuclide),
        activityCtrl = TextEditingController(text: activity);

  final TextEditingController nuclideCtrl;
  final TextEditingController activityCtrl;
  bool halfLifeOver30y;

  void dispose() {
    nuclideCtrl.dispose();
    activityCtrl.dispose();
  }
}

class _ProtocolFieldsScreenState extends State<ProtocolFieldsScreen> {
  SurveyPurpose? _purpose;
  // A beépített mezők minden célnál megmaradnak, cél-váltáskor sem vesznek el.
  final Map<String, _FieldDraft> _builtin = {};
  final List<_FieldDraft> _custom = [];
  final List<_IsotopeDraft> _isotopes = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final draft in _builtin.values) {
      draft.dispose();
    }
    for (final draft in _custom) {
      draft.dispose();
    }
    for (final draft in _isotopes) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final db = DatabaseHelper.instance;
    final session = await db.getSurveySession(widget.surveySessionId);
    final fields = await db.getProtocolFields(widget.surveySessionId);
    if (!mounted) return;
    final storedBuiltin = {
      for (final field in fields)
        if (!field.isCustom) field.key: field,
    };
    setState(() {
      _purpose = session?.purpose;
      for (final key in allBuiltinProtocolFieldKeys) {
        _builtin[key] =
            _FieldDraft(key: key, value: storedBuiltin[key]?.value);
      }
      for (final field in fields.where((f) => f.isCustom)) {
        _custom.add(_FieldDraft(
          key: ProtocolFieldKeys.custom,
          customLabel: field.customLabel,
          value: field.value,
        ));
      }
      for (final iso
          in WasteIsotope.listFromJson(storedBuiltin[ProtocolFieldKeys.isotopes]?.value)) {
        _isotopes.add(_IsotopeDraft(
          nuclide: iso.nuclide,
          activity: iso.activityBq?.toString() ?? '',
          halfLifeOver30y: iso.halfLifeOver30y,
        ));
      }
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final sessionId = widget.surveySessionId;
    final rows = <ProtocolField>[];
    var order = 0;
    for (final key in allBuiltinProtocolFieldKeys) {
      rows.add(ProtocolField(
        surveySessionId: sessionId,
        key: key,
        value: _nullIfBlank(_builtin[key]!.valueCtrl.text),
        sortOrder: order++,
      ));
    }
    for (final draft in _custom) {
      final label = draft.labelCtrl.text.trim();
      // Név nélküli egyedi mező nem kerül a jegyzőkönyvbe.
      if (label.isEmpty) continue;
      rows.add(ProtocolField(
        surveySessionId: sessionId,
        key: ProtocolFieldKeys.custom,
        customLabel: label,
        value: _nullIfBlank(draft.valueCtrl.text),
        sortOrder: order++,
      ));
    }
    rows.add(ProtocolField(
      surveySessionId: sessionId,
      key: ProtocolFieldKeys.isotopes,
      value: WasteIsotope.listToJson([
        for (final draft in _isotopes)
          if (draft.nuclideCtrl.text.trim().isNotEmpty)
            WasteIsotope(
              nuclide: draft.nuclideCtrl.text.trim(),
              activityBq: parseDecimalInput(draft.activityCtrl.text),
              halfLifeOver30y: draft.halfLifeOver30y,
            ),
      ]),
      sortOrder: order++,
    ));
    await DatabaseHelper.instance.replaceProtocolFields(sessionId, rows);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  String? _nullIfBlank(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isWaste = _purpose == SurveyPurpose.waste;
    final isDecom = _purpose == SurveyPurpose.decommissioning;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.protocolFieldsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: loc.saveButton,
            onPressed: (_loading || _saving) ? null : _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (isDecom) ...[
                  _sectionTitle(loc.protocolFieldsDecomSection),
                  for (final key in decommissioningProtocolFieldKeys)
                    _builtinField(loc, key),
                  const SizedBox(height: 16),
                ],
                if (isWaste) ...[
                  _sectionTitle(loc.protocolFieldsWasteSection),
                  for (final key in wasteProtocolFieldKeys)
                    _builtinField(loc, key),
                  _sectionTitle(loc.isotopesSectionTitle),
                  for (var i = 0; i < _isotopes.length; i++)
                    _isotopeRow(loc, i),
                  OutlinedButton.icon(
                    onPressed: () => setState(
                      () => _isotopes.add(_IsotopeDraft()),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(loc.addIsotopeButton),
                  ),
                  const SizedBox(height: 16),
                ],
                _sectionTitle(loc.protocolFieldsCustomSection),
                for (var i = 0; i < _custom.length; i++) _customField(loc, i),
                OutlinedButton.icon(
                  onPressed: () => setState(
                    () => _custom.add(
                      _FieldDraft(key: ProtocolFieldKeys.custom),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(loc.addCustomFieldButton),
                ),
              ],
            ),
    );
  }

  Widget _isotopeRow(AppLocalizations loc, int index) {
    final draft = _isotopes[index];
    return Card(
      key: ObjectKey(draft),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: draft.nuclideCtrl,
                    decoration:
                        InputDecoration(labelText: loc.isotopeNameLabel),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: loc.removeIsotopeTooltip,
                  onPressed: () => setState(() {
                    _isotopes.removeAt(index).dispose();
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: draft.activityCtrl,
              decoration: InputDecoration(labelText: loc.isotopeActivityLabel),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<bool>(
              initialValue: draft.halfLifeOver30y,
              isExpanded: true,
              decoration: InputDecoration(labelText: loc.isotopeHalfLifeLabel),
              items: [
                DropdownMenuItem<bool>(
                  value: false,
                  child: Text(loc.wasteHalfLifeLe30),
                ),
                DropdownMenuItem<bool>(
                  value: true,
                  child: Text(loc.wasteHalfLifeGt30),
                ),
              ],
              onChanged: (value) => draft.halfLifeOver30y = value ?? false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _builtinField(AppLocalizations loc, String key) {
    final draft = _builtin[key]!;
    final label = protocolBuiltinLabel(key, loc);
    final isCoded = key == ProtocolFieldKeys.halfLifeClass ||
        key == ProtocolFieldKeys.betaWork ||
        key == ProtocolFieldKeys.decomNoSources;
    if (isCoded) {
      final codes = key == ProtocolFieldKeys.halfLifeClass
          ? halfLifeClassValues
          : yesNoValues;
      final current = draft.valueCtrl.text;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          initialValue: codes.contains(current) ? current : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [
            for (final code in codes)
              DropdownMenuItem<String>(
                value: code,
                child: Text(protocolFieldValueText(key, code, loc)),
              ),
          ],
          onChanged: (value) => draft.valueCtrl.text = value ?? '',
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: draft.valueCtrl,
        decoration: InputDecoration(labelText: label),
        keyboardType: key == ProtocolFieldKeys.massKg
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
      ),
    );
  }

  Widget _customField(AppLocalizations loc, int index) {
    final draft = _custom[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: draft.labelCtrl,
                    decoration:
                        InputDecoration(labelText: loc.customFieldNameLabel),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: loc.removeFieldTooltip,
                  onPressed: () => setState(() {
                    _custom.removeAt(index).dispose();
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: draft.valueCtrl,
              decoration: InputDecoration(labelText: loc.customFieldValueLabel),
            ),
          ],
        ),
      ),
    );
  }
}
