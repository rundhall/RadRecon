import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/measurement_point.dart';
import '../models/point_source_link.dart';
import '../services/dose_unit_converter.dart';
import '../widgets/disclaimer_info_icon.dart';
import 'radiation_source_entry_screen.dart';

/// Egy ponthoz rendelt forrás részletei: szerkeszthető távolság, és a
/// bomlás/dózisteljesítmény élő számítása — a mért (a ponton rögzített)
/// dózisteljesítménnyel összevetve.
class PointSourceDetailScreen extends StatefulWidget {
  final AttachedSource attached;
  final MeasurementPoint measurementPoint;

  const PointSourceDetailScreen({
    super.key,
    required this.attached,
    required this.measurementPoint,
  });

  @override
  State<PointSourceDetailScreen> createState() =>
      _PointSourceDetailScreenState();
}

class _PointSourceDetailScreenState extends State<PointSourceDetailScreen> {
  final _dateFormat = DateFormat('yyyy.MM.dd');
  late final TextEditingController _distanceCtrl;
  DateTime _asOfDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _distanceCtrl = TextEditingController(
      text: widget.attached.link.distanceMeters.toString(),
    );
  }

  @override
  void dispose() {
    _distanceCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveDistance() async {
    final loc = AppLocalizations.of(context)!;
    final parsed = double.tryParse(_distanceCtrl.text.trim());
    if (parsed == null || parsed <= 0) {
      _showError(loc.numberRequiredError);
      return;
    }
    await DatabaseHelper.instance.updatePointSourceDistance(
      widget.attached.link.id!,
      parsed,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _editGlobalSource() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            RadiationSourceEntryScreen(existing: widget.attached.source),
      ),
    );
    if (saved == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _confirmDetach() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.detachSourceConfirmTitle),
        content: Text(
          loc.detachSourceConfirmMessage(widget.attached.source.identifier),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.detachButton),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.deletePointSource(widget.attached.link.id!);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  Future<void> _pickAsOfDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _asOfDate,
      firstDate: widget.attached.source.manufactureDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _asOfDate = picked);
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
    final source = widget.attached.source;
    return Scaffold(
      appBar: AppBar(
        title: Text('${source.identifier} · ${source.nuclideName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: loc.editSourceTitle,
            onPressed: _editGlobalSource,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: loc.saveButton,
            onPressed: _saveDistance,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _distanceCtrl,
            decoration: InputDecoration(labelText: loc.sourceDistanceLabel),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Text(
            '${loc.manufactureDateLabel}: ${_dateFormat.format(source.manufactureDate)}'
            '${source.serviceLifeExpiryDate != null ? '  ·  ${loc.serviceLifeExpiryDateLabel}: ${_dateFormat.format(source.serviceLifeExpiryDate!)}' : ''}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          _buildCalculationPanel(loc),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: _confirmDetach,
            icon: const Icon(Icons.link_off),
            label: Text(loc.detachButton),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationPanel(AppLocalizations loc) {
    final distance = double.tryParse(_distanceCtrl.text.trim());
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
            ..._buildCalculationBody(loc, distance),
            Align(
              alignment: Alignment.centerRight,
              child: DisclaimerInfoIcon(text: loc.sourceCalculationDisclaimer),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCalculationBody(AppLocalizations loc, double? distance) {
    final source = widget.attached.source;
    if (distance == null || distance <= 0) {
      return [
        Text(loc.notSetLabel, style: Theme.of(context).textTheme.bodySmall),
      ];
    }

    final isotope = source.knownIsotope;
    if (isotope == null) {
      return [
        Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(loc.unknownNuclideDecayWarning)),
          ],
        ),
      ];
    }

    final decayedActivity = source.decayedActivityMBqAt(_asOfDate)!;
    final calculatedDoseUSvH = isotope.doseRateAt(
      activityMBq: decayedActivity,
      distanceM: distance,
    );

    final errorPercent = source.activityErrorPercent;
    final activityLine = errorPercent == null
        ? '${_formatValue(decayedActivity)} MBq'
        : '${_formatValue(decayedActivity)} MBq (±${_formatValue(decayedActivity * errorPercent / 100)} MBq)';

    final widgets = <Widget>[
      _resultRow(loc.currentActivityResultLabel, activityLine),
      _resultRow(
        loc.calculatedDoseRateResultLabel,
        '${_formatValue(calculatedDoseUSvH)} µSv/h',
      ),
    ];

    if (source.isExpiredAt(_asOfDate)) {
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

    widgets.add(const Divider());

    final measuredValue = widget.measurementPoint.value;
    final measuredUnit = widget.measurementPoint.unit;
    if (measuredValue == null) {
      widgets.add(Text(loc.noMeasuredValueForComparisonNote));
      return widgets;
    }

    final measuredUSvH = toMicroSievertPerHour(measuredValue, measuredUnit);
    if (measuredUSvH == null) {
      widgets.add(Text(loc.unrecognizedUnitForComparisonNote(measuredUnit)));
      return widgets;
    }

    widgets.add(
      _resultRow(
        loc.measuredDoseRateResultLabel,
        '${_formatValue(measuredUSvH)} µSv/h',
      ),
    );
    final diff = measuredUSvH - calculatedDoseUSvH;
    final diffPercent = calculatedDoseUSvH == 0
        ? null
        : diff / calculatedDoseUSvH * 100;
    final diffText = diffPercent == null
        ? '${_formatValue(diff)} µSv/h'
        : '${_formatValue(diff)} µSv/h (${diffPercent >= 0 ? '+' : ''}${_formatValue(diffPercent)}%)';
    widgets.add(_resultRow(loc.doseRateDifferenceResultLabel, diffText));

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
