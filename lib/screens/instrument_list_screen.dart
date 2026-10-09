import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/instrument.dart';
import '../services/registry_csv_service.dart';
import 'instrument_entry_screen.dart';

/// A terepre vitt műszerek listája — innen adhatók hozzá, szerkeszthetők
/// vagy törölhetők, és ez a lista tölti fel a rögzítő képernyő
/// műszerválasztóját is.
class InstrumentListScreen extends StatefulWidget {
  const InstrumentListScreen({super.key});

  @override
  State<InstrumentListScreen> createState() => _InstrumentListScreenState();
}

class _InstrumentListScreenState extends State<InstrumentListScreen> {
  late Future<List<Instrument>> _instrumentsFuture;
  String _searchQuery = '';
  final _csvService = RegistryCsvService();
  bool _isTransferring = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _instrumentsFuture = DatabaseHelper.instance.getInstruments();
    });
  }

  Future<void> _openEntry({Instrument? existing}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => InstrumentEntryScreen(existing: existing),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _confirmDelete(Instrument instrument) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.instrumentDeleteTitle),
        content: Text(loc.instrumentDeleteConfirm(instrument.name)),
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
      await DatabaseHelper.instance.deleteInstrument(instrument.id!);
      _reload();
    }
  }

  Future<void> _exportCsv() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _isTransferring = true);
    try {
      final file = await _csvService.exportInstruments();
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

  Future<void> _importCsv() async {
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
      final selectedFile = selection.single;
      final bytes = await selectedFile.readAsBytes();
      final result = await _csvService.importInstruments(utf8.decode(bytes), policy);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.registryImportSummary(
          result.imported,
          result.replaced,
          result.skipped,
        )),
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
        title: Text(loc.instrumentsTooltip),
        actions: [
          PopupMenuButton<String>(
            enabled: !_isTransferring,
            onSelected: (action) => action == 'import' ? _importCsv() : _exportCsv(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    const Icon(Icons.file_upload),
                    const SizedBox(width: 8),
                    Text(loc.importRegistryCsv),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.file_download),
                    const SizedBox(width: 8),
                    Text(loc.exportRegistryCsv),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Instrument>>(
        future: _instrumentsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final allInstruments = snapshot.data!;
          final query = _searchQuery.trim().toLowerCase();
          final instruments = allInstruments
              .where(
                (instrument) =>
                    instrument.name.toLowerCase().contains(query) ||
                    (instrument.serialNumber?.toLowerCase().contains(query) ??
                        false),
              )
              .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: loc.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              Expanded(
                child: allInstruments.isEmpty
                    ? Center(child: Text(loc.noInstrumentsYet))
                    : instruments.isEmpty
                        ? Center(child: Text(loc.searchNoResults))
                        : ListView.separated(
                            itemCount: instruments.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final i = instruments[index];
                              final calibrationText = i.nextCalibrationDate == null
                                  ? loc.noCalibrationData
                                  : loc.nextCalibrationOn(
                                      '${i.nextCalibrationDate!.year}.'
                                      '${i.nextCalibrationDate!.month.toString().padLeft(2, '0')}.'
                                      '${i.nextCalibrationDate!.day.toString().padLeft(2, '0')}',
                                    );
                              return ListTile(
                                leading: Icon(
                                  i.isModbusConnected
                                      ? Icons.wifi
                                      : Icons.edit_note,
                                  color: i.isModbusConnected
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                                title: Text(i.name),
                                subtitle: Text(
                                  '${i.serialNumber ?? loc.noSerialNumber} · $calibrationText',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _confirmDelete(i),
                                ),
                                onTap: () => _openEntry(existing: i),
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
        label: Text(loc.newInstrumentButton),
      ),
    );
  }
}