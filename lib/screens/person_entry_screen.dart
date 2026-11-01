import '../models/session_person_link.dart';
import '../l10n/domain_labels.dart';
import '../models/victim_details.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/person.dart';
import '../models/person_certificate.dart';
import '../widgets/person_certificate_dialog.dart';
import 'victim_details_screen.dart';

/// Egy személy felvétele/szerkesztése a globális nyilvántartásban.
///
/// A személy itt csak egyszer kerül felvitelre; a felmérésekhez utána
/// hozzárendelhető, anélkül hogy ezt az űrlapot újra ki kellene tölteni.
class PersonEntryScreen extends StatefulWidget {
  final Person? existing;

  const PersonEntryScreen({super.key, this.existing});

  @override
  State<PersonEntryScreen> createState() => _PersonEntryScreenState();
}

class _PersonEntryScreenState extends State<PersonEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('yyyy.MM.dd');

  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _phoneCtrl = TextEditingController();
  final List<TextEditingController> _emailCtrls = [];

  List<PersonCertificate> _certs = [];

  DateTime? _medicalExamExpiryDate;
  DateTime? _trainingExpiryDate;
  VictimSex? _sex;
  List<({SessionPersonLink link, String surveyTitle, DateTime startedAt})> _sheets = [];
  final _identifierCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _notesCtrl.text = e.notes ?? '';
      _phoneCtrl.text = e.phone ?? '';
      _certs = [...e.certificates];
      for (final m in e.emails) {
        _emailCtrls.add(TextEditingController(text: m));
      }
      _medicalExamExpiryDate = e.medicalExamExpiryDate;
      _trainingExpiryDate = e.trainingExpiryDate;
      _sex = e.sex;
      _identifierCtrl.text = e.identifier ?? '';
      _addressCtrl.text = e.address ?? '';
      _ageCtrl.text = e.ageYears?.toString() ?? '';
      _weightCtrl.text = e.weightKg == null ? '' : _fmtNum(e.weightKg!);
      _heightCtrl.text = e.heightCm == null ? '' : _fmtNum(e.heightCm!);
      _loadSheets();
    }
  }

  Future<void> _loadSheets() async {
    final id = widget.existing?.id;
    if (id == null) return;
    final list = await DatabaseHelper.instance.getVictimSheetsOfPerson(id);
    if (!mounted) return;
    setState(() => _sheets = list);
  }

  Future<void> _openSheet(
      ({SessionPersonLink link, String surveyTitle, DateTime startedAt}) s) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VictimDetailsScreen(
          attached: AttachedPerson(link: s.link, person: widget.existing!),
        ),
      ),
    );
    _loadSheets();
  }

  static String _fmtNum(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  static String? _text(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  static double? _parseNum(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  String _sexText(AppLocalizations loc, VictimSex s) => switch (s) {
        VictimSex.female => loc.victimSexFemale,
        VictimSex.male => loc.victimSexMale,
        VictimSex.unknown => loc.victimSexUnknown,
      };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _identifierCtrl.dispose();
    _addressCtrl.dispose();
    for (final c in _emailCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickMedicalExamExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _medicalExamExpiryDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _medicalExamExpiryDate = picked);
  }

  Future<void> _pickTrainingExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _trainingExpiryDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _trainingExpiryDate = picked);
  }

  Future<void> _editCert({int? index}) async {
    final result = await showPersonCertificateDialog(
      context,
      existing: index == null ? null : _certs[index],
    );
    if (result == null || !mounted) return;
    setState(() {
      final list = [..._certs];
      if (index == null) {
        list.add(result);
      } else {
        list[index] = result;
      }
      _certs = list;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final person = Person(
      id: widget.existing?.id,
      name: _nameCtrl.text.trim(),
      medicalExamExpiryDate: _medicalExamExpiryDate,
      trainingExpiryDate: _trainingExpiryDate,
      identifier: _text(_identifierCtrl),
      address: _text(_addressCtrl),
      sex: _sex,
      ageYears: int.tryParse(_ageCtrl.text.trim()),
      weightKg: _parseNum(_weightCtrl),
      heightCm: _parseNum(_heightCtrl),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      emails: _emailCtrls
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );

    final int personId;
    if (widget.existing == null) {
      personId = await DatabaseHelper.instance.insertPerson(person);
    } else {
      await DatabaseHelper.instance.updatePerson(person);
      personId = widget.existing!.id!;
    }
    await DatabaseHelper.instance.replacePersonCertificates(personId, _certs);

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? loc.newPersonTitle : loc.editPersonTitle,
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
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: loc.personNameLabel),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? loc.requiredFieldError
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: InputDecoration(labelText: loc.personPhoneLabel),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _identifierCtrl,
              decoration: InputDecoration(labelText: loc.personIdentifierLabel),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: InputDecoration(labelText: loc.personAddressLabel),
              maxLines: 2,
            ),
            for (var i = 0; i < _emailCtrls.length; i++) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailCtrls[i],
                      decoration:
                          InputDecoration(labelText: loc.personEmailLabel),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return null;
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)
                            ? null
                            : loc.personEmailInvalidError;
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: loc.personRemoveEmail,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() {
                      _emailCtrls.removeAt(i).dispose();
                    }),
                  ),
                ],
              ),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add),
                label: Text(loc.personAddEmail),
                onPressed: () =>
                    setState(() => _emailCtrls.add(TextEditingController())),
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.medicalExamExpiryDateLabel),
              subtitle: Text(
                _medicalExamExpiryDate == null
                    ? loc.notSetLabel
                    : _dateFormat.format(_medicalExamExpiryDate!),
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickMedicalExamExpiryDate,
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.trainingExpiryDateLabel),
              subtitle: Text(
                _trainingExpiryDate == null
                    ? loc.notSetLabel
                    : _dateFormat.format(_trainingExpiryDate!),
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickTrainingExpiryDate,
            ),
            const Divider(height: 32),
            Text(loc.personPhysicalHeading,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<VictimSex?>(
              initialValue: _sex,
              decoration: InputDecoration(labelText: loc.victimSexLabel),
              items: [
                const DropdownMenuItem<VictimSex?>(
                    value: null, child: Text('—')),
                for (final s in VictimSex.values)
                  DropdownMenuItem<VictimSex?>(
                      value: s, child: Text(_sexText(loc, s))),
              ],
              onChanged: (v) => setState(() => _sex = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: loc.victimAgeLabel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _weightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: loc.victimWeightLabel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _heightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: loc.victimHeightLabel),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(loc.personCertificatesTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(loc.personCertificateAdd),
                  onPressed: () => _editCert(),
                ),
              ],
            ),
            if (_certs.isEmpty)
              Text(loc.personCertificatesEmpty,
                  style: Theme.of(context).textTheme.bodySmall),
            for (var i = 0; i < _certs.length; i++)
              Card(
                child: ListTile(
                  title: Text(_certs[i].name),
                  subtitle: Text([
                    if (_certs[i].validUntil != null)
                      '${loc.calibrationValidUntilLabel}: '
                          '${_dateFormat.format(_certs[i].validUntil!)}',
                    if (_certs[i].number != null) _certs[i].number!,
                    if (_certs[i].issuer != null) _certs[i].issuer!,
                  ].join('\n')),
                  textColor: _certs[i].isExpiredAt(DateTime.now())
                      ? Theme.of(context).colorScheme.error
                      : null,
                  onTap: () => _editCert(index: i),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_certs[i].filePath != null)
                        IconButton(
                          tooltip: loc.calibrationOpenFile,
                          icon: const Icon(Icons.attach_file),
                          onPressed: () => SharePlus.instance.share(
                            ShareParams(files: [XFile(_certs[i].filePath!)]),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => setState(
                            () => _certs = [..._certs]..removeAt(i)),
                      ),
                    ],
                  ),
                ),
              ),
            const Divider(height: 32),
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(labelText: loc.notesLabel),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(loc.saveButton)),
            if (widget.existing != null) ...[
              const Divider(height: 32),
              Text(loc.personPatientSheetsHeading,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_sheets.isEmpty)
                Text(loc.personPatientSheetsEmpty)
              else
                for (final s in _sheets)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.medical_services_outlined,
                          color: Colors.red),
                      title: Text(s.surveyTitle),
                      subtitle: Text([
                        _dateFormat.format(s.startedAt),
                        s.link.triage?.localized(loc) ?? loc.rrTriageNone,
                      ].join(' · ')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openSheet(s),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
