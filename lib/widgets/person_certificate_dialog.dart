import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../l10n/app_localizations.dart';
import '../models/person_certificate.dart';

/// Egy személyi bizonyítvány felvétele/szerkesztése. A mentett bejegyzést
/// adja vissza, vagy null-t, ha a felhasználó mégsem.
Future<PersonCertificate?> showPersonCertificateDialog(
  BuildContext context, {
  PersonCertificate? existing,
}) {
  return showDialog<PersonCertificate>(
    context: context,
    builder: (_) => _PersonCertificateDialog(existing: existing),
  );
}

class _PersonCertificateDialog extends StatefulWidget {
  const _PersonCertificateDialog({this.existing});
  final PersonCertificate? existing;

  @override
  State<_PersonCertificateDialog> createState() =>
      _PersonCertificateDialogState();
}

class _PersonCertificateDialogState extends State<_PersonCertificateDialog> {
  final _fmt = DateFormat('yyyy.MM.dd');
  final _nameCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _issuerCtrl = TextEditingController();
  DateTime? _issuedOn;
  DateTime? _validUntil;
  String? _filePath;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _numberCtrl.text = e.number ?? '';
      _issuerCtrl.text = e.issuer ?? '';
      _issuedOn = e.issuedOn;
      _validUntil = e.validUntil;
      _filePath = e.filePath;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    _issuerCtrl.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime? initial) => showDatePicker(
        context: context,
        initialDate: initial ?? DateTime.now(),
        firstDate: DateTime(1950),
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
    final target = Directory(p.join(dir.path, 'person_certificates'));
    await target.create(recursive: true);
    final name = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final saved = File(p.join(target.path, name));
    await saved.writeAsBytes(bytes);
    if (mounted) setState(() => _filePath = saved.path);
  }

  void _ok() {
    final loc = AppLocalizations.of(context)!;
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = loc.personCertificateNameRequired);
      return;
    }
    if (_issuedOn != null &&
        _validUntil != null &&
        _validUntil!.isBefore(_issuedOn!)) {
      setState(() => _error = loc.personCertificateValidBeforeError);
      return;
    }
    String? clean(String s) => s.trim().isEmpty ? null : s.trim();
    Navigator.of(context).pop(PersonCertificate(
      id: widget.existing?.id,
      personId: widget.existing?.personId,
      name: _nameCtrl.text.trim(),
      number: clean(_numberCtrl.text),
      issuer: clean(_issuerCtrl.text),
      issuedOn: _issuedOn,
      validUntil: _validUntil,
      filePath: _filePath,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.personCertificateDialogTitle),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration:
                    InputDecoration(labelText: loc.personCertificateNameLabel),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _numberCtrl,
                decoration: InputDecoration(
                    labelText: loc.personCertificateNumberLabel),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _issuerCtrl,
                decoration: InputDecoration(
                    labelText: loc.personCertificateIssuerLabel),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(loc.personCertificateIssuedLabel),
                subtitle: Text(
                    _issuedOn == null ? loc.notSetLabel : _fmt.format(_issuedOn!)),
                trailing: const Icon(Icons.edit_calendar),
                onTap: () async {
                  final d = await _pickDate(_issuedOn);
                  if (d != null) setState(() => _issuedOn = d);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(loc.calibrationValidUntilLabel),
                subtitle: Text(_validUntil == null
                    ? loc.notSetLabel
                    : _fmt.format(_validUntil!)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_validUntil != null)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _validUntil = null),
                      ),
                    const Icon(Icons.edit_calendar),
                  ],
                ),
                onTap: () async {
                  final d = await _pickDate(_validUntil ?? _issuedOn);
                  if (d != null) setState(() => _validUntil = d);
                },
              ),
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
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
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
