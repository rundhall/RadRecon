import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/isotope.dart';
import '../models/radiation_source.dart';
import '../widgets/disclaimer_info_icon.dart';

const String _customNuclideSentinel = '__custom__';

/// Egy sugárforrás felvétele/szerkesztése a globális nyilvántartásban.
///
/// A forrás itt csak egyszer kerül felvitelre; a mérési pontokhoz utána
/// hozzárendelhető (a ponton érvényes távolsággal), anélkül hogy ezt az
/// űrlapot újra ki kellene tölteni.
class RadiationSourceEntryScreen extends StatefulWidget {
  final RadiationSource? existing;

  const RadiationSourceEntryScreen({super.key, this.existing});

  @override
  State<RadiationSourceEntryScreen> createState() =>
      _RadiationSourceEntryScreenState();
}

class _RadiationSourceEntryScreenState
    extends State<RadiationSourceEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('yyyy.MM.dd');

  final _identifierCtrl = TextEditingController();
  final _customNuclideCtrl = TextEditingController();
  final _activityCtrl = TextEditingController();
  final _errorPercentCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _nuclideName = kKnownIsotopes.first.name;
  bool _isCustomNuclide = false;

  DateTime? _manufactureDate;
  DateTime? _expiryDate;
  DateTime? _nextInspectionDate;
  DateTime _asOfDate = DateTime.now();

  bool _manufactureDateTouched = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _identifierCtrl.text = e.identifier;
      final known = Isotope.findByName(e.nuclideName);
      if (known != null) {
        _nuclideName = known.name;
        _isCustomNuclide = false;
      } else {
        _isCustomNuclide = true;
        _customNuclideCtrl.text = e.nuclideName;
      }
      _activityCtrl.text = e.activityAtManufactureMBq.toString();
      _errorPercentCtrl.text = e.activityErrorPercent?.toString() ?? '';
      _notesCtrl.text = e.notes ?? '';
      _manufactureDate = e.manufactureDate;
      _expiryDate = e.serviceLifeExpiryDate;
      _nextInspectionDate = e.nextInspectionDate;
    }
  }

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _customNuclideCtrl.dispose();
    _activityCtrl.dispose();
    _errorPercentCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String get _effectiveNuclideName =>
      _isCustomNuclide ? _customNuclideCtrl.text.trim() : _nuclideName;

  Future<void> _pickManufactureDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _manufactureDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _manufactureDate = picked;
        _manufactureDateTouched = true;
      });
    }
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? _manufactureDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _pickNextInspectionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextInspectionDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _nextInspectionDate = picked);
  }

  Future<void> _pickAsOfDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _asOfDate,
      firstDate: _manufactureDate ?? DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _asOfDate = picked);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final nuclideName = _effectiveNuclideName;
    final loc = AppLocalizations.of(context)!;
    if (nuclideName.isEmpty) {
      _showError(loc.requiredFieldError);
      return;
    }
    if (_manufactureDate == null) {
      setState(() => _manufactureDateTouched = true);
      _showError(loc.requiredFieldError);
      return;
    }

    final now = DateTime.now();
    final source = RadiationSource(
      id: widget.existing?.id,
      identifier: _identifierCtrl.text.trim(),
      nuclideName: nuclideName,
      activityAtManufactureMBq: double.parse(_activityCtrl.text.trim()),
      activityErrorPercent: _errorPercentCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_errorPercentCtrl.text.trim()),
      manufactureDate: _manufactureDate!,
      serviceLifeExpiryDate: _expiryDate,
      nextInspectionDate: _nextInspectionDate,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.existing == null) {
      await DatabaseHelper.instance.insertRadiationSource(source);
    } else {
      await DatabaseHelper.instance.updateRadiationSource(source);
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  String _formatValue(double v) {
    if (v.abs() >= 1000 || (v != 0 && v.abs() < 0.01)) {
      return v.toStringAsExponential(3);
    }
    return v.toStringAsFixed(3);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? loc.newSourceTitle : loc.editSourceTitle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: loc.saveButton,
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _identifierCtrl,
              decoration:
                  InputDecoration(labelText: loc.sourceIdentifierLabel),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? loc.requiredFieldError
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue:
                  _isCustomNuclide ? _customNuclideSentinel : _nuclideName,
              decoration: InputDecoration(labelText: loc.nuclideLabel),
              items: [
                ...kKnownIsotopes.map(
                  (i) => DropdownMenuItem(
                    value: i.name,
                    child: Text(i.name),
                  ),
                ),
                DropdownMenuItem(
                  value: _customNuclideSentinel,
                  child: Text(loc.customNuclideOption),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _isCustomNuclide = v == _customNuclideSentinel;
                  if (!_isCustomNuclide) _nuclideName = v;
                });
              },
            ),
            if (_isCustomNuclide) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customNuclideCtrl,
                decoration:
                    InputDecoration(labelText: loc.customNuclideNameLabel),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? loc.requiredFieldError
                    : null,
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _activityCtrl,
                    decoration: InputDecoration(
                      labelText: loc.activityAtManufactureLabel,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return loc.requiredFieldError;
                      }
                      final parsed = double.tryParse(v.trim());
                      if (parsed == null || parsed <= 0) {
                        return loc.numberRequiredError;
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _errorPercentCtrl,
                    decoration: InputDecoration(
                      labelText: loc.activityErrorPercentLabel,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.manufactureDateLabel),
              subtitle: Text(
                _manufactureDate == null
                    ? loc.notSetLabel
                    : _dateFormat.format(_manufactureDate!),
                style: (_manufactureDateTouched && _manufactureDate == null)
                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                    : null,
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickManufactureDate,
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.serviceLifeExpiryDateLabel),
              subtitle: Text(
                _expiryDate == null
                    ? loc.notSetLabel
                    : _dateFormat.format(_expiryDate!),
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickExpiryDate,
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.nextInspectionDateLabel),
              subtitle: Text(
                _nextInspectionDate == null
                    ? loc.notSetLabel
                    : _dateFormat.format(_nextInspectionDate!),
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickNextInspectionDate,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(labelText: loc.notesLabel),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildCalculationPanel(loc),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(loc.saveButton)),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationPanel(AppLocalizations loc) {
    final activity = double.tryParse(_activityCtrl.text.trim());
    final nuclideName = _effectiveNuclideName;

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.asOfDateLabel),
              subtitle: Text(_dateFormat.format(_asOfDate)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickAsOfDate,
            ),
            const Divider(),
            ..._buildCalculationBody(loc, activity, nuclideName),
            Align(
              alignment: Alignment.centerRight,
              child: DisclaimerInfoIcon(text: loc.sourceCalculationDisclaimer),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCalculationBody(
    AppLocalizations loc,
    double? activity,
    String nuclideName,
  ) {
    if (activity == null ||
        activity <= 0 ||
        _manufactureDate == null ||
        nuclideName.isEmpty) {
      return [
        Text(loc.notSetLabel, style: Theme.of(context).textTheme.bodySmall),
      ];
    }

    final isotope = Isotope.findByName(nuclideName);
    if (isotope == null) {
      return [
        Row(
          children: [
            Icon(Icons.info_outline,
                color: Theme.of(context).colorScheme.error, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(loc.unknownNuclideDecayWarning)),
          ],
        ),
      ];
    }

    final elapsedDays =
        _asOfDate.difference(_manufactureDate!).inHours / 24.0;
    final decayedActivity = isotope.decayedActivityMBq(
      initialActivityMBq: activity,
      elapsedDays: elapsedDays,
    )!;

    final errorPercent = double.tryParse(_errorPercentCtrl.text.trim());
    final activityLine = errorPercent == null
        ? '${_formatValue(decayedActivity)} MBq'
        : '${_formatValue(decayedActivity)} MBq (±${_formatValue(decayedActivity * errorPercent / 100)} MBq)';

    final widgets = <Widget>[
      _resultRow(loc.currentActivityResultLabel, activityLine),
    ];

    if (_expiryDate != null && _expiryDate!.isBefore(_asOfDate)) {
      widgets.add(const SizedBox(height: 4));
      widgets.add(
        Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.deepOrange, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(loc.sourceExpiredWarning)),
          ],
        ),
      );
    }

    return widgets;
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
