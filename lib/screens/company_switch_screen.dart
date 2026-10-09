import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../services/app_reset.dart';
import '../services/database_transfer_service.dart';

/// Cégváltó képernyő: kilistázza a cégek mappájában lévő mentéseket, és a
/// kiválasztottat betölti. Váltáskor az aktuális állapot automatikusan
/// visszamentődik az aktív cég fájljába, így nem vész el semmi.
class CompanySwitchScreen extends StatefulWidget {
  const CompanySwitchScreen({super.key});

  @override
  State<CompanySwitchScreen> createState() => _CompanySwitchScreenState();
}

class _CompanySwitchScreenState extends State<CompanySwitchScreen> {
  final _service = DatabaseTransferService.instance;

  bool _loading = true;
  bool _busy = false;
  String _activeCompany = '';
  String _folderPath = '';
  bool _customFolder = false;
  List<CompanyBackup> _companies = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final active = await _service.getActiveCompanyName();
      final folder = await _service.getFolderDescription();
      final custom = await _service.isUsingCustomFolder();
      final companies = await _service.listCompanies();
      if (!mounted) return;
      setState(() {
        _activeCompany = active;
        _folderPath = folder;
        _customFolder = custom;
        _companies = companies;
      });
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.importErrorMessage('$error'))),
    );
  }

  Future<bool> _confirm(String title, String body, String actionLabel,
      {bool destructive = false}) async {
    final loc = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _switchTo(CompanyBackup company) async {
    final loc = AppLocalizations.of(context)!;
    if (company.companyName == _activeCompany) return;
    final ok = await _confirm(
      loc.companySwitchConfirmTitle,
      loc.companySwitchConfirmBody(company.companyName, _activeCompany),
      loc.companySwitchAction,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.switchToCompany(company);
      if (!mounted) return;
      // Az egész app újraépül, hogy minden képernyő az új adatot mutassa.
      final messenger = ScaffoldMessenger.of(context);
      final message = loc.companySwitchedMessage(company.companyName);
      AppReset.reset();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      _showError(e);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createCompany() async {
    final loc = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.newCompanyDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: loc.companyNameLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(loc.createButton),
          ),
        ],
      ),
    );
    // A controllert szándékosan nem dispose-oljuk itt: a dialog záródó
    // animációja alatt a TextField még használja, korai dispose összeomlást okozna.
    if (name == null || name.isEmpty || !mounted) return;
    final safeName = DatabaseTransferService.sanitizeName(name).toLowerCase();
    if (_companies.any((c) => c.companyName.toLowerCase() == safeName) ||
        safeName == _activeCompany.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.companyNameExistsMessage)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await _service.createCompany(name);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final message = loc.companySwitchedMessage(name);
      AppReset.reset();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      _showError(e);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addFromFile() async {
    try {
      final selection = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['zip'],
      );
      if (selection.isEmpty || !mounted) return;
      setState(() => _busy = true);
      final bytes = await selection.single.readAsBytes();
      await _service.addToCompaniesFolder(bytes);
      await _reload();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseFolder() async {
    try {
      if (await _service.pickCompaniesFolder()) await _reload();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _resetFolder() async {
    await _service.resetCompaniesFolder();
    await _reload();
  }

  Future<void> _delete(CompanyBackup company) async {
    final loc = AppLocalizations.of(context)!;
    final ok = await _confirm(
      loc.deleteCompanyBackupTitle,
      loc.deleteCompanyBackupBody(company.companyName),
      loc.deleteButton,
      destructive: true,
    );
    if (!ok) return;
    await _service.deleteCompanyBackup(company);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMd(loc.localeName).add_Hm();
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.companySwitchTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined),
            tooltip: loc.newCompanyButton,
            onPressed: _busy ? null : _createCompany,
          ),
          IconButton(
            icon: const Icon(Icons.file_open_outlined),
            tooltip: loc.addCompanyFromFileButton,
            onPressed: _busy ? null : _addFromFile,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.business),
                        title: Text(loc.activeCompanyLabel),
                        subtitle: Text(_activeCompany),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(loc.companiesFolderLabel),
                      subtitle: Text(_folderPath),
                      trailing: DatabaseTransferService.supportsFolderPicking
                          ? PopupMenuButton<String>(
                              onSelected: (v) =>
                                  v == 'pick' ? _chooseFolder() : _resetFolder(),
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'pick',
                                  child: Text(loc.chooseFolderButton),
                                ),
                                if (_customFolder)
                                  PopupMenuItem(
                                    value: 'reset',
                                    child: Text(loc.resetFolderButton),
                                  ),
                              ],
                            )
                          : null,
                    ),
                    if (DatabaseTransferService.isAndroid && !_customFolder) ...[
                      Text(loc.privateFolderHint,
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        onPressed: _busy ? null : _chooseFolder,
                        icon: const Icon(Icons.folder_open),
                        label: Text(loc.chooseFolderButton),
                      ),
                    ],
                    const Divider(height: 24),
                    if (_companies.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(loc.noCompaniesYet),
                      ),
                    for (final c in _companies)
                      Card(
                        child: ListTile(
                          leading: Icon(
                            c.companyName == _activeCompany
                                ? Icons.check_circle
                                : Icons.business_outlined,
                            color: c.companyName == _activeCompany
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          title: Text(c.companyName),
                          subtitle: Text(
                            loc.companyBackupInfo(dateFormat.format(c.modified)),
                          ),
                          onTap: _busy ? null : () => _switchTo(c),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: loc.deleteButton,
                            onPressed: _busy ? null : () => _delete(c),
                          ),
                        ),
                      ),
                  ],
                ),
                if (_busy)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black26,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
    );
  }
}
