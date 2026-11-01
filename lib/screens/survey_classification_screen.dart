import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../services/source_classification.dart';
import '../services/source_composition.dart';
import '../services/survey_source_total.dart';

/// Egy felmérés besorolása: a bekerülő források R-je és a fizikai védelmi
/// kategória. A forrás be- és kizárható, a számítás dátuma állítható.
class SurveyClassificationScreen extends StatefulWidget {
  const SurveyClassificationScreen({
    super.key,
    required this.surveySessionId,
    required this.surveyTitle,
  });

  final int surveySessionId;
  final String surveyTitle;

  @override
  State<SurveyClassificationScreen> createState() =>
      _SurveyClassificationScreenState();
}

class _SurveyClassificationScreenState
    extends State<SurveyClassificationScreen> {
  late Future<SurveyClassification?> _future;
  final _dateFormat = DateFormat('yyyy.MM.dd');

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = loadSurveyClassification(widget.surveySessionId);
    });
  }

  static String _fmt(double v) {
    if (v == 0) return '0';
    final a = v.abs();
    if (a >= 1e5 || a < 1e-3) return v.toStringAsExponential(2);
    return v.toStringAsPrecision(3);
  }

  Future<void> _setIncluded(PlacementClassification row, bool value) async {
    await DatabaseHelper.instance
        .updateSurveyPlacement(row.placement.copyWith(included: value));
    _reload();
  }

  Future<void> _pickCalcDate(PlacementClassification row) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: row.asOf,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    await DatabaseHelper.instance
        .updateSurveyPlacement(row.placement.copyWith(calcDateOverride: picked));
    _reload();
  }

  Future<void> _resetCalcDate(PlacementClassification row) async {
    await DatabaseHelper.instance.updateSurveyPlacement(
      row.placement.copyWith(clearCalcDateOverride: true),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.classificationTitle)),
      body: FutureBuilder<SurveyClassification?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null) return Center(child: Text(loc.noSourcesYet));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.surveyTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                loc.classificationDisclaimer,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              _buildTotal(loc, data.total),
              const SizedBox(height: 12),
              if (data.rows.isEmpty) Text(loc.surveyClassEmpty),
              for (final row in data.rows) _buildRow(loc, row),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTotal(AppLocalizations loc, SurveyTotal t) {
    final theme = Theme.of(context);
    final cat = t.physicalCategory;
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.classificationTotal,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            if (t.rSum == null || cat == null)
              Text(loc.surveyClassNoRSum)
            else ...[
              Text('R = ${_fmt(t.rSum!)}'),
              Text('${loc.classificationPhysCat}: $cat · '
                  '${loc.classificationProtLevel}: ${physicalProtectionLevel(cat)}'),
            ],
            if (!t.isComplete) ...[
              const SizedBox(height: 4),
              Text(
                '${loc.classificationUnknownCount}: ${t.unknownCount}',
                style: const TextStyle(color: Colors.deepOrange),
              ),
              Text(
                loc.surveyClassLowerBound,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(AppLocalizations loc, PlacementClassification row) {
    final c = row.composition;
    final r = c.rSum;
    final cat = c.physicalCategory;
    final nuclideText = row.nuclides.isEmpty
        ? '—'
        : row.nuclides.map((n) => n.nuclide).join(', ');
    final lines = <String>[];
    if (r != null && cat != null) {
      lines.add('R = ${_fmt(r)} · ${loc.classificationPhysCat}: $cat · '
          '${loc.classificationProtLevel}: ${physicalProtectionLevel(cat)}');
    }
    if (!c.isComplete) lines.add(loc.surveyClassIncompleteSource);
    if (c.contributions.any((x) => !x.decayCorrected)) {
      lines.add(loc.classificationNotDecayCorrected);
    }
    final overridden = row.placement.calcDateOverride != null;
    return Card(
      child: Column(
        children: [
          CheckboxListTile(
            value: row.placement.included,
            onChanged: (v) => _setIncluded(row, v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              loc.surveyClassIncluded,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            subtitle: Text(
              [
                '${row.source.identifier} · $nuclideText',
                ...lines,
              ].join('\n'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${loc.surveyClassCalcDate}: ${_dateFormat.format(row.asOf)}'
                    '${overridden ? '' : ' · ${loc.surveyClassCalcDateDefault}'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  tooltip: loc.surveyClassCalcDate,
                  icon: const Icon(Icons.edit_calendar_outlined),
                  onPressed: () => _pickCalcDate(row),
                ),
                if (overridden)
                  IconButton(
                    tooltip: loc.surveyClassCalcDateDefault,
                    icon: const Icon(Icons.restore),
                    onPressed: () => _resetCalcDate(row),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
