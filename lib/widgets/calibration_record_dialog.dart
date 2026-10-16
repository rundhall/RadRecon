import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../l10n/app_localizations.dart';
import '../models/calibration_labels.dart';
import '../models/instrument_calibration.dart';

/// Egy hitelesítési/kalibrálási bejegyzés felvétele vagy szerkesztése.
/// A mentett bejegyzést adja vissza (vagy null, ha a felhasználó mégsem).
Future<InstrumentCalibration?> showCalibrationRecordDialog(
  BuildContext context, {
  InstrumentCalibration? existing,
}) {
  return showDialog<InstrumentCalibration>(
    context: context,
    builder: (_) => _CalibrationRecordDialog(existing: existing),
  );
}

class _CalibrationRecordDialog extends StatefulWidget {
  const _CalibrationRecordDialog({this.existing});
  final InstrumentCalibration? existing;

  @override
  State<_CalibrationRecordDialog> createState() =>
      _CalibrationRecordDialogState();
}

class _CalibrationRecordDialogState extends State<_CalibrationRecordDialog> {
  final _fmt = DateFormat('yyyy.MM.dd');
  final _certCtrl = TextEditingController();
  final _byCtrl = TextEditingController();
  CalibrationKind _kind = CalibrationKind.calibration;
  DateTime _performedOn = DateTime.now();
  DateTime? _validUntil;
  String? _filePath;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _kind = e.kind;
      _performedOn = e.performedOn;
      _validUntil = e.validUntil;
      _certCtrl.text = e.certificateNumber ?? '';
      _byCtrl.text = e.performedBy ?? '';
      _filePath = e.filePath;
    }
  }

  @override
  void dispose() {
    _certCtrl.dispose();
    _byCtrl.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime initial) => showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );

  Future<void> _attach() async {
    final selection = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (selection.isEmpty) return;
    final file = selection.single;
    final bytes = await file.readAsBytes();
    final dir = await getApplicationDocumentsDirectory();
    final target = Directory(p.join(dir.path, 'calibration_docs'));
    await target.create(recursive: true);
    final name = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final saved = File(p.join(target.path, name));
    await saved.writeAsBytes(bytes);
    if (mounted) setState(() => _filePath = saved.path);
  }

  void _ok() {
    final loc = AppLocalizations.of(context)!;
    if (_validUntil != null && _validUntil!.isBefore(_performedOn)) {
      setState(() => _error = loc.calibrationValidUntilBeforeError);
      return;
    }
    String? clean(String s) => s.trim().isEmpty ? null : s.trim();
    Navigator.of(context).pop(InstrumentCalibration(
      id: widget.existing?.id,
      instrumentId: widget.existing?.instrumentId,
      kind: _kind,
      performedOn: _performedOn,
      validUntil: _validUntil,
      certificateNumber: clean(_certCtrl.text),
      performedBy: clean(_byCtrl.text),
      filePath: _filePath,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.calibrationDialogTitle),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<CalibrationKind>(
                initialValue: _kind,
                isExpanded: true,
                decoration: InputDecoration(labelText: loc.calibrationKindLabel),
                items: [
                  for (final k in CalibrationKind.values)
                    DropdownMenuItem(
                      value: k,
                      child: Text(calibrationKindLabel(loc, k)),
                    ),
                ],
                onChanged: (k) {
                  if (k != null) setState(() => _kind = k);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(loc.calibrationPerformedOnLabel),
                subtitle: Text(_fmt.format(_performedOn)),
                trailing: const Icon(Icons.edit_calendar),
                onTap: () async {
                  final d = await _pickDate(_performedOn);
                  if (d != null) setState(() => _performedOn = d);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(loc.calibrationValidUntilLabel),
                subtitle: Text(_validUntil == null
                    ? loc.notSetLabel
                    : _fmt.format(_validUntil!)),
                trailing: const Icon(Icons.edit_calendar),
                onTap: () async {
                  final d = await _pickDate(_validUntil ?? _performedOn);
                  if (d != null) setState(() => _validUntil = d);
                },
              ),
              TextField(
                controller: _certCtrl,
                decoration:
                    InputDecoration(labelText: loc.calibrationCertificateLabel),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _byCtrl,
                decoration:
                    InputDecoration(labelText: loc.calibrationPerformedByLabel),
              ),
              const SizedBox(height: 8),
              if (_filePath == null)
                OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: Text(loc.calibrationAttachFile),
                  onPressed: _attach,
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined),
                  title: Text(p.basename(_filePath!),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    tooltip: loc.calibrationRemoveFile,
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _filePath = null),
                  ),
                ),
              if (_error != null)
                Text(_error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancelButton),
        ),
        FilledButton(onPressed: _ok, child: Text(loc.saveButton)),
      ],
    );
  }
}
