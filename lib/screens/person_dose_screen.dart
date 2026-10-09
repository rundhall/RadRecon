import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/person.dart';
import '../models/person_dose.dart';
import '../widgets/dose_widgets.dart';

/// Egy személy dózisai egy évre: felméréshez kötött (online / manuális) és
/// felmérésektől független passzív dozimetriás bejegyzések, külön jelölve.
class PersonDoseScreen extends StatefulWidget {
  final Person person;
  final int initialYear;

  const PersonDoseScreen({
    super.key,
    required this.person,
    required this.initialYear,
  });

  @override
  State<PersonDoseScreen> createState() => _PersonDoseScreenState();
}

class _PersonDoseScreenState extends State<PersonDoseScreen> {
  late int _year = widget.initialYear;
  List<int> _years = [];
  List<PersonDose> _doses = [];
  bool _loading = true;
  final _dateFormat = DateFormat('yyyy.MM.dd');

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final db = DatabaseHelper.instance;
    final years = await db.getDoseYears();
    if (!years.contains(_year)) years.add(_year);
    years.sort((a, b) => b.compareTo(a));
    final doses = await db.getPersonDoses(widget.person.id!, _year);
    if (!mounted) return;
    setState(() {
      _years = years;
      _doses = doses;
      _loading = false;
    });
  }

  DoseTotals get _totals => _doses.fold(
        DoseTotals.zero,
        (t, d) => t.add(d.source, d.doseMicroSv),
      );

  Future<void> _edit({PersonDose? existing}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _DoseEditDialog(
        personId: widget.person.id!,
        existing: existing,
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _delete(PersonDose dose) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.doseDeleteConfirmTitle),
        content: Text(loc.doseDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.deleteButton),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.deleteDose(dose.id!);
      _reload();
    }
  }

  String _subtitle(PersonDose d, AppLocalizations loc) {
    final parts = <String>[];
    if (d.source == DoseSource.passive) {
      if (d.periodStart != null && d.periodEnd != null) {
        parts.add('${_dateFormat.format(d.periodStart!)} – '
            '${_dateFormat.format(d.periodEnd!)}');
      }
    } else {
      if (d.surveyTitle != null) parts.add(d.surveyTitle!);
      parts.add(_dateFormat.format(d.doseDate));
    }
    if (d.notes != null && d.notes!.isNotEmpty) parts.add(d.notes!);
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final totals = _totals;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.personDosesTitle(widget.person.name)),
        actions: [
          if (_years.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _year,
                  items: [
                    for (final y in _years)
                      DropdownMenuItem(value: y, child: Text('$y')),
                  ],
                  onChanged: (y) {
                    if (y == null) return;
                    setState(() => _year = y);
                    _reload();
                  },
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${loc.annualDoseLabel(_year)}: '
                          '${formatDose(context, totals.total)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        for (final s in DoseSource.values)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(doseSourceIcon(s), size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(doseSourceLabel(loc, s))),
                                Text(formatDose(context, totals.of(s))),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_doses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(loc.noDosesYet)),
                  )
                else
                  for (final d in _doses)
                    ListTile(
                      leading: Icon(doseSourceIcon(d.source)),
                      title: Text(
                        '${formatDose(context, d.doseMicroSv)} · '
                        '${doseSourceLabel(loc, d.source)}',
                      ),
                      subtitle: Text(_subtitle(d, loc)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(d),
                      ),
                      onTap: () => _edit(existing: d),
                    ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: Text(loc.addPassiveDoseButton),
      ),
    );
  }
}

/// Új passzív dozimetriás bejegyzés, vagy meglévő bejegyzés szerkesztése.
/// Felméréshez kötött bejegyzésnél csak az érték és a megjegyzés szerkeszthető.
class _DoseEditDialog extends StatefulWidget {
  final int personId;
  final PersonDose? existing;

  const _DoseEditDialog({required this.personId, this.existing});

  @override
  State<_DoseEditDialog> createState() => _DoseEditDialogState();
}

class _DoseEditDialogState extends State<_DoseEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dose = DoseFieldController();
  final _notes = TextEditingController();
  final _dateFormat = DateFormat('yyyy.MM.dd');
  late DateTime _start;
  late DateTime _end;
  bool _initialized = false;
  bool _endBeforeStart = false;

  bool get _isPassive =>
      widget.existing == null || widget.existing!.source == DoseSource.passive;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final e = widget.existing;
    if (e != null) {
      _dose.setMicroSv(e.doseMicroSv, Localizations.localeOf(context).toString());
      _notes.text = e.notes ?? '';
    }
    final now = DateTime.now();
    // Alapértelmezés: az előző hónap (tipikus havi kiértékelés).
    _start = e?.periodStart ?? DateTime(now.year, now.month - 1, 1);
    _end = e?.periodEnd ?? DateTime(now.year, now.month, 0);
  }

  @override
  void dispose() {
    _dose.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final initial = start ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
      _endBeforeStart = _end.isBefore(_start);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isPassive && _end.isBefore(_start)) {
      setState(() => _endBeforeStart = true);
      return;
    }
    final now = DateTime.now();
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    final db = DatabaseHelper.instance;
    final e = widget.existing;
    if (e == null) {
      await db.insertPassiveDose(PersonDose(
        personId: widget.personId,
        source: DoseSource.passive,
        doseMicroSv: _dose.microSv!,
        doseDate: DateTime(_end.year, _end.month, _end.day),
        periodStart: DateTime(_start.year, _start.month, _start.day),
        periodEnd: DateTime(_end.year, _end.month, _end.day),
        notes: notes,
        createdAt: now,
        updatedAt: now,
      ));
    } else {
      await db.updatePassiveDose(PersonDose(
        id: e.id,
        personId: e.personId,
        surveySessionId: e.surveySessionId,
        source: e.source,
        doseMicroSv: _dose.microSv!,
        doseDate: _isPassive
            ? DateTime(_end.year, _end.month, _end.day)
            : e.doseDate,
        periodStart: _isPassive
            ? DateTime(_start.year, _start.month, _start.day)
            : e.periodStart,
        periodEnd: _isPassive
            ? DateTime(_end.year, _end.month, _end.day)
            : e.periodEnd,
        notes: notes,
        createdAt: e.createdAt,
        updatedAt: now,
      ));
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.existing == null
          ? loc.newPassiveDoseTitle
          : loc.editDoseTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DoseValueField(
                controller: _dose,
                label: loc.doseValueLabel,
                required: true,
              ),
              if (_isPassive) ...[
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(loc.dosePeriodStartLabel),
                  subtitle: Text(_dateFormat.format(_start)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _pickDate(start: true),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(loc.dosePeriodEndLabel),
                  subtitle: Text(_dateFormat.format(_end)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _pickDate(start: false),
                ),
                if (_endBeforeStart)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      loc.dosePeriodEndBeforeStartError,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: _notes,
                decoration: InputDecoration(labelText: loc.notesLabel),
                maxLines: 2,
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
        FilledButton(onPressed: _save, child: Text(loc.saveButton)),
      ],
    );
  }
}
