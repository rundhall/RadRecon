import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/measurement_point.dart';
import '../models/sample_analysis.dart';

/// Egy minta vizsgálatai: módszer, műszer, eredmény és csatolt fájl.
/// Egy mintán több vizsgálat is lehet.
class SampleAnalysisScreen extends StatefulWidget {
  final MeasurementPoint point;

  const SampleAnalysisScreen({super.key, required this.point});

  @override
  State<SampleAnalysisScreen> createState() => _SampleAnalysisScreenState();
}

class _SampleAnalysisScreenState extends State<SampleAnalysisScreen> {
  late Future<List<SampleAnalysis>> _future;
  final _dateFormat = DateFormat('yyyy.MM.dd HH:mm');

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = DatabaseHelper.instance.getSampleAnalyses(widget.point.id!);
    });
  }

  String _methodLabel(AppLocalizations loc, SampleAnalysisMethod m) =>
      m == SampleAnalysisMethod.other ? loc.analysisMethodOther : m.fixedLabel;

  Future<void> _add() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _AnalysisFormDialog(pointId: widget.point.id!),
    );
    if (saved == true) _reload();
  }

  void _showDetails(AppLocalizations loc, SampleAnalysis a) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_methodLabel(loc, a.method)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${loc.analysisPerformedAtLabel}: ${_dateFormat.format(a.performedAt)}'),
              if (a.instrumentName != null)
                Text('${loc.analysisInstrumentLabel}: ${a.instrumentName}'),
              if (a.operatorName != null)
                Text('${loc.analysisOperatorLabel}: ${a.operatorName}'),
              if (a.result != null) ...[
                const SizedBox(height: 8),
                Text('${loc.analysisResultLabel}:'),
                Text(a.result!),
              ],
              if (a.notes != null) ...[
                const SizedBox(height: 8),
                Text('${loc.analysisNotesLabel}: ${a.notes}'),
              ],
              if (a.filePath != null) ...[
                const SizedBox(height: 8),
                Text('${loc.analysisFileLabel}: ${p.basename(a.filePath!)}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.cancelButton),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(AppLocalizations loc, SampleAnalysis a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(loc.analysisDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.deleteButton),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (a.filePath != null) {
      final f = File(a.filePath!);
      if (await f.exists()) await f.delete();
    }
    await DatabaseHelper.instance.deleteSampleAnalysis(a.id!);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.sampleAnalysisTitle)),
      body: FutureBuilder<List<SampleAnalysis>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return Center(child: Text(loc.sampleAnalysisEmpty));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final a = items[index];
              final firstLine = (a.result ?? '').split('\n').first;
              return ListTile(
                leading: const Icon(Icons.biotech),
                title: Text(
                  [
                    _methodLabel(loc, a.method),
                    if (a.instrumentName != null) a.instrumentName!,
                  ].join(' · '),
                ),
                subtitle: Text(
                  [
                    _dateFormat.format(a.performedAt),
                    if (firstLine.isNotEmpty) firstLine,
                  ].join(' · '),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(loc, a),
                ),
                onTap: () => _showDetails(loc, a),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text(loc.sampleAnalysisAddButton),
      ),
    );
  }
}

/// Új vizsgálat felvétele: módszer, műszer, idő, kezelő, eredmény, csatolt fájl.
class _AnalysisFormDialog extends StatefulWidget {
  const _AnalysisFormDialog({required this.pointId});

  final int pointId;

  @override
  State<_AnalysisFormDialog> createState() => _AnalysisFormDialogState();
}

class _AnalysisFormDialogState extends State<_AnalysisFormDialog> {
  SampleAnalysisMethod _method = SampleAnalysisMethod.ftir;
  final _instrumentCtrl = TextEditingController();
  final _operatorCtrl = TextEditingController();
  final _resultCtrl = TextEditingController();
  final _pcrTargetCtrl = TextEditingController();
  final _pcrCtCtrl = TextEditingController();
  PcrOutcome _pcrOutcome = PcrOutcome.positive;
  final _notesCtrl = TextEditingController();
  DateTime _performedAt = DateTime.now();
  String? _filePath;

  @override
  void dispose() {
    _instrumentCtrl.dispose();
    _operatorCtrl.dispose();
    _resultCtrl.dispose();
    _pcrTargetCtrl.dispose();
    _pcrCtCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  static String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _pickFile() async {
    final selection = await FilePicker.pickFiles(type: FileType.any);
    if (selection.isEmpty) return;
    setState(() => _filePath = selection.single.path);
  }

  Future<void> _pickTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _performedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_performedAt),
    );
    if (time == null || !mounted) return;
    setState(() => _performedAt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  /// A csatolt fájl másolata az app `analyses/` mappájában.
  Future<String> _copyFile(String source) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'analyses'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final target = p.join(
      dir.path,
      'analysis_${DateTime.now().millisecondsSinceEpoch}_${p.basename(source)}',
    );
    await File(source).copy(target);
    return target;
  }

  double? _parsedCt() =>
      double.tryParse(_pcrCtCtrl.text.trim().replaceAll(',', '.'));

  String _pcrOutcomeText(AppLocalizations loc, PcrOutcome o) => switch (o) {
        PcrOutcome.positive => loc.pcrOutcomePositive,
        PcrOutcome.negative => loc.pcrOutcomeNegative,
        PcrOutcome.invalid => loc.pcrOutcomeInvalid,
      };

  /// A PCR mezőiből összefoglaló szöveg; ezt látja a lista és a részletek.
  String _pcrSummary(AppLocalizations loc) {
    final target = _pcrTargetCtrl.text.trim();
    final ct = _parsedCt();
    return [
      if (target.isNotEmpty) '${loc.pcrTargetLabel}: $target',
      '${loc.pcrOutcomeLabel}: ${_pcrOutcomeText(loc, _pcrOutcome)}',
      if (ct != null) '${loc.pcrCtLabel}: ${_pcrCtCtrl.text.trim()}',
    ].join(' · ');
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;
    final source = _filePath;
    final filePath = source == null ? null : await _copyFile(source);
    await DatabaseHelper.instance.insertSampleAnalysis(SampleAnalysis(
      measurementPointId: widget.pointId,
      method: _method,
      instrumentName: _nullIfEmpty(_instrumentCtrl.text),
      performedAt: _performedAt,
      operatorName: _nullIfEmpty(_operatorCtrl.text),
      result: _method == SampleAnalysisMethod.pcr
          ? _pcrSummary(loc)
          : _nullIfEmpty(_resultCtrl.text),
      pcrTarget: _method == SampleAnalysisMethod.pcr ? _nullIfEmpty(_pcrTargetCtrl.text) : null,
      pcrOutcome: _method == SampleAnalysisMethod.pcr ? _pcrOutcome : null,
      pcrCt: _method == SampleAnalysisMethod.pcr ? _parsedCt() : null,
      notes: _nullIfEmpty(_notesCtrl.text),
      filePath: filePath,
      createdAt: DateTime.now(),
    ));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final f = DateFormat('yyyy.MM.dd HH:mm');
    return AlertDialog(
      title: Text(loc.sampleAnalysisAddButton),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<SampleAnalysisMethod>(
                initialValue: _method,
                decoration: InputDecoration(labelText: loc.analysisMethodLabel),
                items: [
                  for (final m in SampleAnalysisMethod.values)
                    DropdownMenuItem(
                      value: m,
                      child: Text(m == SampleAnalysisMethod.other
                          ? loc.analysisMethodOther
                          : m.fixedLabel),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _method = v);
                },
              ),
              TextField(
                controller: _instrumentCtrl,
                decoration: InputDecoration(labelText: loc.analysisInstrumentLabel),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(loc.analysisPerformedAtLabel),
                subtitle: Text(f.format(_performedAt)),
                trailing: const Icon(Icons.edit_calendar),
                onTap: _pickTime,
              ),
              TextField(
                controller: _operatorCtrl,
                decoration: InputDecoration(labelText: loc.analysisOperatorLabel),
              ),
              if (_method == SampleAnalysisMethod.pcr) ...[
                TextField(
                  controller: _pcrTargetCtrl,
                  decoration: InputDecoration(labelText: loc.pcrTargetLabel),
                ),
                DropdownButtonFormField<PcrOutcome>(
                  initialValue: _pcrOutcome,
                  decoration: InputDecoration(labelText: loc.pcrOutcomeLabel),
                  items: [
                    for (final o in PcrOutcome.values)
                      DropdownMenuItem(value: o, child: Text(_pcrOutcomeText(loc, o))),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _pcrOutcome = v);
                  },
                ),
                TextField(
                  controller: _pcrCtCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: loc.pcrCtLabel),
                ),
              ],
              if (_method != SampleAnalysisMethod.pcr)
              TextField(
                controller: _resultCtrl,
                maxLines: 3,
                decoration: InputDecoration(labelText: loc.analysisResultLabel),
              ),
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(labelText: loc.analysisNotesLabel),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(loc.analysisAttachFile),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _filePath == null ? '' : p.basename(_filePath!),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(loc.cancelButton),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(loc.saveButton),
        ),
      ],
    );
  }
}
