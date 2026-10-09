import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/person.dart';
import '../models/person_dose.dart';
import '../services/registry_csv_service.dart';
import '../widgets/dose_widgets.dart';
import 'person_dose_screen.dart';
import 'person_entry_screen.dart';

/// A személyek globális nyilvántartása — a műszerekhez/forrásokhoz hasonlóan
/// egyszer felveszed, utána bármelyik felméréshez hozzárendelheted, nem kell
/// újra kitölteni az adatait minden felméréshez.
class PersonListScreen extends StatefulWidget {
  const PersonListScreen({super.key});

  @override
  State<PersonListScreen> createState() => _PersonListScreenState();
}

class _PersonListScreenState extends State<PersonListScreen> {
  late Future<_PersonListData> _dataFuture;
  int _year = DateTime.now().year;
  final _dateFormat = DateFormat('yyyy.MM.dd');
  final _csvService = RegistryCsvService();
  String _searchQuery = '';
  bool _isTransferring = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _dataFuture = _load();
    });
  }

  Future<_PersonListData> _load() async {
    final db = DatabaseHelper.instance;
    final persons = await db.getPersons();
    final totals = await db.getAnnualDoseTotals(_year);
    final years = await db.getDoseYears();
    if (!years.contains(_year)) years.add(_year);
    years.sort((a, b) => b.compareTo(a));
    return _PersonListData(persons, totals, years);
  }

  Future<void> _openDoses(Person person) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonDoseScreen(person: person, initialYear: _year),
      ),
    );
    _reload();
  }

  Future<void> _openEntry({Person? existing}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PersonEntryScreen(existing: existing),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _confirmDelete(Person person) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deletePersonConfirmTitle),
        content: Text(loc.deletePersonConfirmMessage(person.name)),
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
      await DatabaseHelper.instance.deletePerson(person.id!);
      _reload();
    }
  }

  Future<void> _exportCsv({bool doses = false}) async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _isTransferring = true);
    try {
      final file = doses
          ? await _csvService.exportPersonDoses()
          : await _csvService.exportPersons();
      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        subject: loc.registryCsvExportSubject,
      ));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.exportErrorMessage('$error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isTransferring = false);
    }
  }

  Future<void> _importCsv({bool doses = false}) async {
    final loc = AppLocalizations.of(context)!;
    final policy = await showDialog<DuplicateImportPolicy>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.duplicatePolicyTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in DuplicateImportPolicy.values)
              ListTile(
                title: Text(switch (option) {
                  DuplicateImportPolicy.replace => loc.duplicateReplace,
                  DuplicateImportPolicy.skip => loc.duplicateSkip,
                  DuplicateImportPolicy.keepDuplicate => loc.duplicateKeep,
                }),
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cancelButton),
          ),
        ],
      ),
    );
    if (policy == null || !mounted) return;
    try {
      final selection = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
      );
      if (selection.isEmpty || !mounted) return;
      setState(() => _isTransferring = true);
      // A dózisok névvel hivatkoznak a személyekre, ezért előbb a személyek
      // CSV-jét kell betölteni.
      final text = utf8.decode(await selection.single.readAsBytes());
      final result = doses
          ? await _csvService.importPersonDoses(text, policy)
          : await _csvService.importPersons(text, policy);
      final imported = result.imported,
          replaced = result.replaced,
          skipped = result.skipped;
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.registryImportSummary(imported, replaced, skipped)),
      ));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.importErrorMessage('$error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isTransferring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.personsTitle),
        actions: [
          PopupMenuButton<String>(
            enabled: !_isTransferring,
            onSelected: (action) => switch (action) {
              'import' => _importCsv(),
              'export' => _exportCsv(),
              'import_doses' => _importCsv(doses: true),
              _ => _exportCsv(doses: true),
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    const Icon(Icons.file_upload),
                    const SizedBox(width: 8),
                    Text(loc.importPersonCsv),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.file_download),
                    const SizedBox(width: 8),
                    Text(loc.exportPersonCsv),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'import_doses',
                child: Row(
                  children: [
                    const Icon(Icons.file_upload),
                    const SizedBox(width: 8),
                    Text(loc.importPersonDosesCsv),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export_doses',
                child: Row(
                  children: [
                    const Icon(Icons.file_download),
                    const SizedBox(width: 8),
                    Text(loc.exportPersonDosesCsv),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<_PersonListData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final allPersons = data.persons;
          final query = _searchQuery.trim().toLowerCase();
          final persons = allPersons
              .where((person) => person.name.toLowerCase().contains(query))
              .toList();
          final now = DateTime.now();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: loc.searchHint,
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _year,
                        hint: Text(loc.doseYearLabel),
                        items: [
                          for (final y in data.years)
                            DropdownMenuItem(value: y, child: Text('$y')),
                        ],
                        onChanged: (y) {
                          if (y == null) return;
                          _year = y;
                          _reload();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: allPersons.isEmpty
                    ? Center(child: Text(loc.noPersonsYet))
                    : persons.isEmpty
                        ? Center(child: Text(loc.searchNoResults))
                        : ListView.separated(
                            itemCount: persons.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final p = persons[index];
                              final expired = p.isExpiredAt(now);
                              final totals =
                                  data.totals[p.id] ?? DoseTotals.zero;
                              return ListTile(
                                leading: Icon(
                                  expired
                                      ? Icons.warning_amber
                                      : Icons.person_outline,
                                  color: expired
                                      ? Colors.deepOrange
                                      : Colors.grey,
                                ),
                                title: Text(p.name),
                                isThreeLine: true,
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${loc.medicalExamExpiryDateLabel}: '
                                      '${p.medicalExamExpiryDate == null ? loc.notSetLabel : _dateFormat.format(p.medicalExamExpiryDate!)}'
                                      ' · ${loc.trainingExpiryDateLabel}: '
                                      '${p.trainingExpiryDate == null ? loc.notSetLabel : _dateFormat.format(p.trainingExpiryDate!)}',
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${loc.annualDoseLabel(_year)}: '
                                      '${formatDose(context, totals.total)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(doseBreakdownText(context, totals)),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.radar),
                                      tooltip: loc.personDosesTooltip,
                                      onPressed: () => _openDoses(p),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _confirmDelete(p),
                                    ),
                                  ],
                                ),
                                onTap: () => _openEntry(existing: p),
                              );
                            },
                          ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEntry(),
        icon: const Icon(Icons.add),
        label: Text(loc.newPersonButton),
      ),
    );
  }
}

class _PersonListData {
  final List<Person> persons;
  final Map<int, DoseTotals> totals;
  final List<int> years;

  const _PersonListData(this.persons, this.totals, this.years);
}
