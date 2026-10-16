import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/company_document.dart';

/// Cég-dokumentum vagy engedély felvétele/szerkesztése (azonosító, lejárat,
/// tetszőleges számú csatolt fájl).
class CompanyDocumentEntryScreen extends StatefulWidget {
  final CompanyDocument? existing;

  const CompanyDocumentEntryScreen({super.key, this.existing});

  @override
  State<CompanyDocumentEntryScreen> createState() =>
      _CompanyDocumentEntryScreenState();
}

class _CompanyDocumentEntryScreenState
    extends State<CompanyDocumentEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fmt = DateFormat('yyyy.MM.dd');

  final _titleCtrl = TextEditingController();
  final _identifierCtrl = TextEditingController();
  final _issuerCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _issuedOn;
  DateTime? _validUntil;
  List<String> _files = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _identifierCtrl.text = e.identifier ?? '';
      _issuerCtrl.text = e.issuer ?? '';
      _notesCtrl.text = e.notes ?? '';
      _issuedOn = e.issuedOn;
      _validUntil = e.validUntil;
      _files = [...e.filePaths];
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _identifierCtrl.dispose();
    _issuerCtrl.dispose();
    _notesCtrl.dispose();
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
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (selection.isEmpty) return;
    final file = selection.single;
    final bytes = await file.readAsBytes();
    final dir = await getApplicationDocumentsDirectory();
    final target = Directory(p.join(dir.path, 'company_documents'));
    await target.create(recursive: true);
    final name = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final saved = File(p.join(target.path, name));
    await saved.writeAsBytes(bytes);
    if (mounted) setState(() => _files = [..._files, saved.path]);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    String? clean(String s) => s.trim().isEmpty ? null : s.trim();
    final doc = CompanyDocument(
      id: widget.existing?.id,
      title: _titleCtrl.text.trim(),
      identifier: clean(_identifierCtrl.text),
      issuer: clean(_issuerCtrl.text),
      issuedOn: _issuedOn,
      validUntil: _validUntil,
      notes: clean(_notesCtrl.text),
      filePaths: _files,
    );
    if (widget.existing == null) {
      await DatabaseHelper.instance.insertCompanyDocument(doc);
    } else {
      await DatabaseHelper.instance.updateCompanyDocument(doc);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final suggestions = [
      loc.companyDocSuggestRadiationPolicy,
      loc.companyDocSuggestRadiationDescription,
      loc.companyDocSuggestPhysicalProtection,
      loc.companyDocSuggestEmergencyPlan,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null
            ? loc.companyDocumentNew
            : loc.companyDocumentEdit),
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
              controller: _titleCtrl,
              decoration:
                  InputDecoration(labelText: loc.companyDocumentTitleLabel),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? loc.requiredFieldError
                  : null,
            ),
            if (widget.existing == null) ...[
              const SizedBox(height: 8),
              Text(loc.companyDocSuggestionsLabel,
                  style: Theme.of(context).textTheme.bodySmall),
              Wrap(
                spacing: 8,
                children: [
                  for (final s in suggestions)
                    ActionChip(
                      label: Text(s),
                      onPressed: () => setState(() => _titleCtrl.text = s),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _identifierCtrl,
              decoration: InputDecoration(
                  labelText: loc.companyDocumentIdentifierLabel),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _issuerCtrl,
              decoration:
                  InputDecoration(labelText: loc.companyDocumentIssuerLabel),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.companyDocumentIssuedLabel),
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
              title: Text(loc.companyDocumentValidUntilLabel),
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
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(labelText: loc.notesLabel),
              maxLines: 3,
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(loc.companyDocumentFilesTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: Text(loc.companyDocumentAttach),
                  onPressed: _attach,
                ),
              ],
            ),
            for (var i = 0; i < _files.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: Text(p.basename(_files[i]),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => SharePlus.instance
                    .share(ShareParams(files: [XFile(_files[i])])),
                trailing: IconButton(
                  tooltip: loc.calibrationRemoveFile,
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      setState(() => _files = [..._files]..removeAt(i)),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(loc.saveButton)),
          ],
        ),
      ),
    );
  }
}
