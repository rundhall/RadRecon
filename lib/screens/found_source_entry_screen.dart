import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/activity_origin.dart';
import '../models/measurement_point.dart';
import '../services/dose_unit_controller.dart';
import '../services/found_source_builder.dart';
import '../services/number_input.dart';
import '../widgets/quantity_field.dart';

/// Talált forrás felvétele egy mérési ponthoz. Az űrlap a mérésből (dózis
/// vagy spektrum) előtöltött nuklid-sorokat kap, mindegyik módosítható.
/// Mentéskor a forrás a központi nyilvántartásba kerül, és a ponthoz rendelődik.
class FoundSourceEntryScreen extends StatefulWidget {
  const FoundSourceEntryScreen({
    super.key,
    required this.measurementPoint,
    required this.initialNuclides,
    this.initialDistanceMeters,
  });

  final MeasurementPoint measurementPoint;
  final List<FoundNuclideDraft> initialNuclides;
  final double? initialDistanceMeters;

  @override
  State<FoundSourceEntryScreen> createState() => _FoundSourceEntryScreenState();
}

class _NuclideRow {
  _NuclideRow({
    required String nuclide,
    required String activityText,
    required this.origin,
  })  : nuclideCtrl = TextEditingController(text: nuclide),
        activityCtrl = TextEditingController(text: activityText);

  final TextEditingController nuclideCtrl;
  final TextEditingController activityCtrl;
  ActivityOrigin origin;

  void dispose() {
    nuclideCtrl.dispose();
    activityCtrl.dispose();
  }
}

class _FoundSourceEntryScreenState extends State<FoundSourceEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _now = DateTime.now();
  late final TextEditingController _identifierCtrl;
  late final TextEditingController _distanceCtrl;
  final List<_NuclideRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _identifierCtrl = TextEditingController(text: foundSourceIdentifier(_now));
    final d = widget.initialDistanceMeters;
    _distanceCtrl = TextEditingController(
      text: d == null ? '' : QuantityField.formatNumber(d),
    );
    final unit = ActivityUnitController.current;
    for (final n in widget.initialNuclides) {
      final mbq = n.activityMBq;
      _rows.add(_NuclideRow(
        nuclide: n.nuclide,
        activityText:
            mbq == null ? '' : QuantityField.formatNumber(unit.fromMBq(mbq)),
        origin: n.origin,
      ));
    }
    if (_rows.isEmpty) {
      _rows.add(_NuclideRow(
        nuclide: '',
        activityText: '',
        origin: ActivityOrigin.manual,
      ));
    }
  }

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _distanceCtrl.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _originLabel(AppLocalizations loc, ActivityOrigin o) => switch (o) {
        ActivityOrigin.measurement => loc.foundSourceOriginMeasurement,
        ActivityOrigin.shieldedMeasurement => loc.foundSourceOriginShielded,
        ActivityOrigin.spectrum => loc.foundSourceOriginSpectrum,
        ActivityOrigin.manual => loc.foundSourceOriginManual,
      };

  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    final distance = parseDecimal(_distanceCtrl.text);
    if (distance == null || distance <= 0) {
      _showError(loc.foundSourceNoDistanceError);
      return;
    }
    final unit = ActivityUnitController.current;
    final drafts = <FoundNuclideDraft>[];
    for (final row in _rows) {
      final name = row.nuclideCtrl.text.trim();
      final activityText = row.activityCtrl.text.trim();
      if (name.isEmpty) {
        if (activityText.isNotEmpty) {
          _showError(loc.foundSourceNuclideRequiredError);
          return;
        }
        continue; // üres sor kimarad
      }
      // Üres aktivitás = ismeretlen; ilyen sor nem számít be a besorolásba.
      final value = activityText.isEmpty ? null : parseDecimal(activityText);
      if (activityText.isNotEmpty && value == null) {
        _showError(loc.numberRequiredError);
        return;
      }
      drafts.add(FoundNuclideDraft(
        nuclide: name,
        activityMBq: value == null ? null : unit.toMBq(value),
        origin: row.origin,
      ));
    }

    final nuclides = buildFoundNuclideRows(
      drafts: drafts,
      referenceDate: widget.measurementPoint.timestamp,
      now: _now,
    );
    final source = buildFoundSource(
      identifier: _identifierCtrl.text.trim(),
      nuclides: nuclides,
      now: _now,
    );
    final sourceId = await DatabaseHelper.instance
        .insertRadiationSourceWithNuclides(source, nuclides);
    await DatabaseHelper.instance.insertPointSource(
      measurementPointId: widget.measurementPoint.id!,
      radiationSourceId: sourceId,
      distanceMeters: distance,
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Widget _buildRow(AppLocalizations loc, String unitSymbol, int index) {
    final row = _rows[index];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: row.nuclideCtrl,
                    decoration:
                        InputDecoration(labelText: loc.foundSourceNuclideLabel),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      setState(() => _rows.removeAt(index).dispose()),
                ),
              ],
            ),
            TextFormField(
              controller: row.activityCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '${loc.foundSourceActivityLabel} ($unitSymbol)',
              ),
            ),
            DropdownButtonFormField<ActivityOrigin>(
              initialValue: row.origin,
              isExpanded: true,
              decoration:
                  InputDecoration(labelText: loc.foundSourceOriginLabel),
              items: [
                for (final o in ActivityOrigin.values)
                  DropdownMenuItem(
                    value: o,
                    child: Text(_originLabel(loc, o)),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => row.origin = v);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final unitSymbol = ActivityUnitController.current.symbol;
    return Scaffold(
      appBar: AppBar(title: Text(loc.foundSourceTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _identifierCtrl,
              decoration: InputDecoration(labelText: loc.sourceIdentifierLabel),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? loc.requiredFieldError
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              loc.foundSourceUnknownHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _rows.length; i++)
              _buildRow(loc, unitSymbol, i),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add),
                label: Text(loc.foundSourceAddNuclide),
                onPressed: () => setState(() => _rows.add(_NuclideRow(
                      nuclide: '',
                      activityText: '',
                      origin: ActivityOrigin.manual,
                    ))),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _distanceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  InputDecoration(labelText: loc.distanceFromSourceLabel),
              validator: (v) =>
                  parseDecimal(v ?? '') == null ? loc.numberRequiredError : null,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(loc.cancelButton),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _save,
                  child: Text(loc.saveButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
