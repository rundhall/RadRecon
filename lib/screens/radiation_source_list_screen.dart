import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/radiation_source.dart';
import '../services/registry_csv_service.dart';
import 'radiation_source_entry_screen.dart';

/// A sugárforrások globális nyilvántartása — a műszerekhez hasonlóan
/// egyszer felveszed, utána bármelyik mérési ponthoz hozzárendelheted, nem
/// kell újra kitölteni az adatait minden méréshez.
class RadiationSourceListScreen extends StatefulWidget {
  const RadiationSourceListScreen({super.key});

  @override
  State<RadiationSourceListScreen> createState() =>
      _RadiationSourceListScreenState();
}

class _RadiationSourceListScreenState
    extends State<RadiationSourceListScreen> {
  late Future<List<RadiationSource>> _sourcesFuture;
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
      _sourcesFuture = DatabaseHelper.instance.getRadiationSources();
    });
  }

  Future<void> _openEntry({RadiationSource? existing}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RadiationSourceEntryScreen(existing: existing),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _confirmDelete(RadiationSource source) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteSourceConfirmTitle),
        content: Text(loc.deleteSourceConfirmMessage(source.identifier)),
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
      await DatabaseHelper.instance.deleteRadiationSource(source.id!);
      _reload();
    }
  }

  Future<void> _exportCsv() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _isTransferring = true);
    try {
      final file = await _csvService.exportRadiationSources();
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
      final result = await _csvService.importRadiationSources(utf8.decode(bytes), policy);
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
        title: Text(loc.radiationSourcesTitle),
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
      body: FutureBuilder<List<RadiationSource>>(
        future: _sourcesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final allSources = snapshot.data!;
          final query = _searchQuery.trim().toLowerCase();
          final sources = allSources
              .where(
                (source) =>
                    source.identifier.toLowerCase().contains(query) ||
                    source.nuclideName.toLowerCase().contains(query),
              )
              .toList();
          final now = DateTime.now();
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
                child: allSources.isEmpty
                    ? Center(child: Text(loc.noSourcesYet))
                    : sources.isEmpty
                        ? Center(child: Text(loc.searchNoResults))
                        : ListView.separated(
                            itemCount: sources.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final s = sources[index];
                              final expired = s.isExpiredAt(now);
                              return ListTile(
                                leading: Icon(
                                  expired
                                      ? Icons.warning_amber
                                      : Icons.radio_button_checked,
                                  color: expired
                                      ? Colors.deepOrange
                                      : Colors.grey,
                                ),
                                title: Text(
                                  '${s.identifier} · ${s.nuclideName}',
                                ),
                                subtitle: Text(
                                  '${loc.manufactureDateLabel}: ${_dateFormat.format(s.manufactureDate)}'
                                  '${s.serviceLifeExpiryDate != null ? ' · ${loc.serviceLifeExpiryDateLabel}: ${_dateFormat.format(s.serviceLifeExpiryDate!)}' : ''}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _confirmDelete(s),
                                ),
                                onTap: () => _openEntry(existing: s),
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
        label: Text(loc.newSourceButton),
      ),
    );
  }
}
