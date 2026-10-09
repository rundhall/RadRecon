import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/person.dart';

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

  DateTime? _medicalExamExpiryDate;
  DateTime? _trainingExpiryDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _notesCtrl.text = e.notes ?? '';
      _medicalExamExpiryDate = e.medicalExamExpiryDate;
      _trainingExpiryDate = e.trainingExpiryDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final person = Person(
      id: widget.existing?.id,
      name: _nameCtrl.text.trim(),
      medicalExamExpiryDate: _medicalExamExpiryDate,
      trainingExpiryDate: _trainingExpiryDate,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.existing == null) {
      await DatabaseHelper.instance.insertPerson(person);
    } else {
      await DatabaseHelper.instance.updatePerson(person);
    }

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
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(labelText: loc.notesLabel),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(loc.saveButton)),
          ],
        ),
      ),
    );
  }
}
