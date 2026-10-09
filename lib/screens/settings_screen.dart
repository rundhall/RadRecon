import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/measurement_type.dart';
import '../services/app_reset.dart';
import '../services/database_transfer_service.dart';
import '../services/expiry_notification_service.dart';
import '../services/locale_controller.dart';
import '../services/settings_service.dart';
import '../services/theme_controller.dart';
import 'company_switch_screen.dart';
import 'contributors_screen.dart';

/// Típusonkénti riasztási küszöbértékek beállítása. Ha egy mérési pont
/// rögzítésekor a mért érték eléri/túllépi a küszöböt, az app figyelmeztet.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = SettingsService();
  final _controllers = <MeasurementType, TextEditingController>{
    for (final t in MeasurementType.values) t: TextEditingController(),
  };
  bool _loading = true;
  bool _dataBusy = false;
  bool _expiryNotifEnabled = false;
  ExpiryLeadTime _expiryLead = ExpiryLeadTime.sameDay;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final thresholds = await _service.getAllThresholds();
    _expiryNotifEnabled = await _service.getExpiryNotificationsEnabled();
    _expiryLead = await _service.getExpiryLeadTime();
    for (final entry in thresholds.entries) {
      _controllers[entry.key]!.text = entry.value?.toString() ?? '';
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Be/kikapcsolás azonnal érvénybe lép (mint a téma és a nyelv). Bekapcsolás
  /// előtt elkérjük az értesítési engedélyt; ha nem kapjuk meg, a kapcsoló
  /// kikapcsolva marad.
  Future<void> _setExpiryNotifEnabled(bool value) async {
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final notifService = ExpiryNotificationService.instance;
    if (value && !await notifService.requestPermission()) {
      messenger.showSnackBar(
        SnackBar(content: Text(loc.expiryNotificationsPermissionDenied)),
      );
      return;
    }
    await _service.setExpiryNotificationsEnabled(value);
    if (mounted) setState(() => _expiryNotifEnabled = value);
    await notifService.rescheduleAll();
  }

  Future<void> _setExpiryLead(ExpiryLeadTime value) async {
    await _service.setExpiryLeadTime(value);
    if (mounted) setState(() => _expiryLead = value);
    await ExpiryNotificationService.instance.rescheduleAll();
  }

  String _leadLabel(AppLocalizations loc, ExpiryLeadTime lead) =>
      switch (lead) {
        ExpiryLeadTime.sameDay => loc.expiryLeadSameDay,
        ExpiryLeadTime.oneDay => loc.expiryLeadOneDay,
        ExpiryLeadTime.twoDays => loc.expiryLeadTwoDays,
        ExpiryLeadTime.oneWeek => loc.expiryLeadOneWeek,
      };

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _confirmDialog(
    String title,
    String body,
    String action, {
    bool destructive = false,
  }) async {
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
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  /// Mentés fájlba: desktopon "Mentés másként" párbeszéd, mobilon a
  /// megosztás-lap (onnan Drive-ra, e-mailbe, fájlok közé menthető).
  Future<void> _saveDatabase() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _dataBusy = true);
    try {
      final transfer = DatabaseTransferService.instance;
      final name = await transfer.getActiveCompanyName();
      final file = await transfer.exportToFile(companyName: name);
      if (!mounted) return;
      if (DatabaseTransferService.isDesktop) {
        final location = await fs.getSaveLocation(
          suggestedName: file.uri.pathSegments.last,
          acceptedTypeGroups: const [
            fs.XTypeGroup(label: 'RadRecon backup', extensions: ['zip']),
          ],
        );
        if (location == null) return;
        await file.copy(location.path);
        _snack(loc.databaseSavedMessage(location.path));
      } else {
        await SharePlus.instance.share(ShareParams(
          files: [XFile(file.path)],
          subject: loc.saveDatabaseSubject,
        ));
      }
    } catch (e) {
      _snack(loc.exportErrorMessage('$e'));
    } finally {
      if (mounted) setState(() => _dataBusy = false);
    }
  }

  Future<void> _loadDatabase() async {
    final loc = AppLocalizations.of(context)!;
    try {
      final selection = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['zip'],
      );
      if (selection.isEmpty || !mounted) return;
      final bytes = await selection.single.readAsBytes();
      if (!mounted) return;
      final ok = await _confirmDialog(
        loc.loadDatabaseConfirmTitle,
        loc.loadDatabaseConfirmBody,
        loc.loadButton,
        destructive: true,
      );
      if (!ok || !mounted) return;
      setState(() => _dataBusy = true);
      final companyName =
          await DatabaseTransferService.instance.importFromBytes(bytes);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final message = loc.databaseLoadedMessage(companyName);
      AppReset.reset();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      _snack(loc.importErrorMessage('$e'));
      if (mounted) setState(() => _dataBusy = false);
    }
  }

  Future<void> _clearDatabase() async {
    final loc = AppLocalizations.of(context)!;
    final ok = await _confirmDialog(
      loc.clearDatabaseConfirmTitle,
      loc.clearDatabaseConfirmBody,
      loc.deleteButton,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _dataBusy = true);
    try {
      await DatabaseTransferService.instance.clearDatabase();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final message = loc.databaseClearedMessage;
      AppReset.reset();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      _snack('$e');
      if (mounted) setState(() => _dataBusy = false);
    }
  }

  Future<void> _openCompanySwitch() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CompanySwitchScreen()),
    );
  }

  Future<void> _openContributors() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ContributorsScreen()),
    );
  }

  Future<void> _save() async {
    for (final type in MeasurementType.values) {
      if (type == MeasurementType.sample) continue;
      final text = _controllers[type]!.text.trim();
      final value = text.isEmpty ? null : double.tryParse(text);
      await _service.setThreshold(type, value);
    }
    if (mounted) {
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.settingsSavedMessage)));
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settingsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: loc.saveButton,
            onPressed: _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  loc.appearanceSectionTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                // A téma-választás azonnal érvénybe lép (nincs hozzá
                // "Mentés" gomb) — ez a ThemeController-en keresztül az
                // egész appot azonnal átváltja, és SharedPreferences-be is
                // kiírja, hogy újraindítás után is megmaradjon.
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: ThemeController.themeMode,
                  builder: (context, currentMode, _) {
                    return SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(loc.themeLight),
                          icon: const Icon(Icons.light_mode_outlined),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(loc.themeDark),
                          icon: const Icon(Icons.dark_mode_outlined),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(loc.themeSystem),
                          icon: const Icon(Icons.smartphone_outlined),
                        ),
                      ],
                      selected: {currentMode},
                      onSelectionChanged: (selection) {
                        ThemeController.setThemeMode(selection.first);
                      },
                    );
                  },
                ),
                const Divider(height: 32),
                Text(
                  loc.languageSectionTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                // Ugyanaz a minta, mint a témánál: azonnal érvénybe lép és
                // a LocaleController-en keresztül a SharedPreferences-be is
                // kiírásra kerül. `null` = kövesse a telefon nyelvét.
                ValueListenableBuilder<Locale?>(
                  valueListenable: LocaleController.locale,
                  builder: (context, currentLocale, _) {
                    return DropdownButton<Locale?>(
                      isExpanded: true,
                      value: currentLocale,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(loc.languageSystemOption),
                        ),
                        const DropdownMenuItem(
                          value: Locale('hu'),
                          child: Text('Magyar'),
                        ),
                        const DropdownMenuItem(
                          value: Locale('en'),
                          child: Text('English'),
                        ),
                      ],
                      onChanged: LocaleController.setLocale,
                    );
                  },
                ),
                const Divider(height: 32),
                Text(
                  loc.dataManagementSectionTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(loc.dataManagementHint, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.business),
                  title: Text(loc.companySwitchButton),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: !_dataBusy,
                  onTap: _openCompanySwitch,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.save_alt),
                  title: Text(loc.saveDatabaseButton),
                  enabled: !_dataBusy,
                  onTap: _saveDatabase,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.file_open_outlined),
                  title: Text(loc.loadDatabaseButton),
                  enabled: !_dataBusy,
                  onTap: _loadDatabase,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text(
                    loc.clearDatabaseButton,
                    style: const TextStyle(color: Colors.red),
                  ),
                  enabled: !_dataBusy,
                  onTap: _clearDatabase,
                ),
                if (_dataBusy)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(),
                  ),
                const Divider(height: 32),
                if (ExpiryNotificationService.isSupported) ...[
                  Text(
                    loc.expiryNotificationsSectionTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(loc.expiryNotificationsSwitchTitle),
                    subtitle: Text(loc.expiryNotificationsSwitchSubtitle),
                    value: _expiryNotifEnabled,
                    onChanged: _setExpiryNotifEnabled,
                  ),
                  if (_expiryNotifEnabled) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ExpiryLeadTime>(
                      initialValue: _expiryLead,
                      decoration:
                          InputDecoration(labelText: loc.expiryLeadTimeLabel),
                      items: [
                        for (final lead in ExpiryLeadTime.values)
                          DropdownMenuItem(
                            value: lead,
                            child: Text(_leadLabel(loc, lead)),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) _setExpiryLead(v);
                      },
                    ),
                  ],
                  const Divider(height: 32),
                ],
                Text(
                  loc.alertThresholdExplanation,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 20),
                ...MeasurementType.values
                    .where((t) => t != MeasurementType.sample)
                    .map(
                      (type) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextField(
                          controller: _controllers[type],
                          decoration: InputDecoration(
                            labelText:
                                '${type.label(context)} (${type.defaultUnit})',
                            hintText: loc.noThresholdSetHint,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 12),
                FilledButton(onPressed: _save, child: Text(loc.saveButton)),
                const Divider(height: 32),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.volunteer_activism),
                  title: Text(loc.contributorsTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openContributors,
                ),
              ],
            ),
    );
  }
}
