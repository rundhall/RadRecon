import 'dart:io';
import '../services/basis_unit_controller.dart';
import '../models/activity_concentration.dart';
import '../l10n/domain_labels.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../services/number_input.dart';
import '../l10n/app_localizations.dart';
import '../models/activity_unit.dart';
import '../models/decimal_separator.dart';
import '../models/hardware_button.dart';
import '../services/hardware_buttons.dart';
import '../models/distance_unit.dart';
import '../models/dose_rate_unit.dart';
import '../models/measurement_type.dart';
import '../services/app_reset.dart';
import '../services/database_transfer_service.dart';
import '../services/dose_unit_controller.dart';
import '../models/unit_catalog.dart';
import '../services/display_units.dart';
import '../widgets/display_unit_dropdown.dart';
import '../services/expiry_notification_service.dart';
import '../services/help_launcher.dart';
import '../services/locale_controller.dart';
import '../services/regulatory_profile.dart';
import '../services/settings_service.dart';
import '../services/theme_controller.dart';
import 'company_switch_screen.dart';
import 'contributors_screen.dart';

/// Típusonkénti riasztási küszöbértékek beállítása. Ha egy mérési pont
/// rögzítésekor a mért érték eléri/túllépi a küszöböt, az app figyelmeztet.
/// A Beállítások főmenüjének kategóriái (a null azt jelenti: a főmenü látszik).
enum _SettingsCategory { appearance, units, bluetooth, alerts, expiry, data, help }

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
  _SettingsCategory? _category;

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

  String _leadLabel(AppLocalizations loc, ExpiryLeadTime lead) {
    if (lead.isMonths) return loc.expiryLeadMonths(lead.months);
    return switch (lead) {
      ExpiryLeadTime.sameDay => loc.expiryLeadSameDay,
      ExpiryLeadTime.oneDay => loc.expiryLeadOneDay,
      ExpiryLeadTime.twoDays => loc.expiryLeadTwoDays,
      ExpiryLeadTime.oneWeek => loc.expiryLeadOneWeek,
      ExpiryLeadTime.twoWeeks => loc.expiryLeadTwoWeeks,
      _ => loc.expiryLeadSameDay,
    };
  }

  /// Átváltás után ne maradjanak lebegőpontos farkak (pl. 0.30000000000000004).
  String _trimNumber(double v) => double.parse(v.toStringAsPrecision(12)).toString();

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
      final picked = selection.single;
      if (!mounted) return;
      final ok = await _confirmDialog(
        loc.loadDatabaseConfirmTitle,
        loc.loadDatabaseConfirmBody,
        loc.loadButton,
        destructive: true,
      );
      if (!ok || !mounted) return;
      setState(() => _dataBusy = true);
      // Helyi útvonal esetén streamelve töltjük be; egyébként bájtokból.
      final path = picked.path;
      final companyName = path != null
          ? await DatabaseTransferService.instance.importFromFile(File(path))
          : await DatabaseTransferService.instance
              .importFromBytes(await picked.readAsBytes());
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
      if (!type.hasValue) continue;
      final text = _controllers[type]!.text.trim();
      final value = text.isEmpty ? null : parseDecimal(text);
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

  List<Widget> _menuTiles(AppLocalizations loc) {
    ListTile tile(_SettingsCategory c, IconData icon, String title) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => setState(() => _category = c),
        );
    return [
      tile(_SettingsCategory.appearance, Icons.palette_outlined, loc.appearanceSectionTitle),
      tile(_SettingsCategory.units, Icons.straighten, loc.unitsSectionTitle),
      tile(_SettingsCategory.bluetooth, Icons.bluetooth, loc.btnSectionTitle),
      tile(_SettingsCategory.alerts, Icons.notifications_outlined, loc.alertThresholdsTooltip),
      tile(_SettingsCategory.expiry, Icons.event_outlined, loc.expiryNotificationsSectionTitle),
      tile(_SettingsCategory.data, Icons.storage, loc.dataManagementSectionTitle),
      tile(_SettingsCategory.help, Icons.help_outline, loc.helpManualTitle),
    ];
  }

  String _categoryTitle(AppLocalizations loc, _SettingsCategory c) => switch (c) {
        _SettingsCategory.appearance => loc.appearanceSectionTitle,
        _SettingsCategory.units => loc.unitsSectionTitle,
        _SettingsCategory.bluetooth => loc.btnSectionTitle,
        _SettingsCategory.alerts => loc.alertThresholdsTooltip,
        _SettingsCategory.expiry => loc.expiryNotificationsSectionTitle,
        _SettingsCategory.data => loc.dataManagementSectionTitle,
        _SettingsCategory.help => loc.helpManualTitle,
      };

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final category = _category;
    return PopScope(
      canPop: category == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && category != null) setState(() => _category = null);
      },
      child: Scaffold(
      appBar: AppBar(
        leading: category == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => setState(() => _category = null),
              ),
        title: Text(
          category == null ? loc.settingsTitle : _categoryTitle(loc, category),
        ),
        actions: [
          if (category != null)
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
              children: category == null
                  ? _menuTiles(loc)
                  : [
                if (category == _SettingsCategory.appearance) ...[
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
                ],
                if (category == _SettingsCategory.units) ...[
                Text(
                  loc.unitsSectionTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(loc.doseUnitSectionHint,
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                // Azonnal érvénybe lép, mint a téma és a nyelv. Zárt listák:
                // nincs beírás, így az egység nem rontható el.
                ValueListenableBuilder<DoseRateUnit>(
                  valueListenable: DoseUnitController.unit,
                  builder: (context, current, _) {
                    return DropdownButtonFormField<DoseRateUnit>(
                      key: ValueKey('dose-${current.name}'),
                      initialValue: current,
                      isExpanded: true,
                      decoration:
                          InputDecoration(labelText: loc.doseUnitSectionTitle),
                      items: [
                        for (final u in DoseRateUnit.values)
                          DropdownMenuItem(value: u, child: Text(u.symbol)),
                      ],
                      onChanged: (u) async {
                        if (u == null) return;
                        await DoseUnitController.setUnit(u);
                        // A mentett dózisteljesítmény-küszöb átváltódott.
                        final t = await _service.getDoseRateThreshold();
                        if (!mounted) return;
                        setState(() {
                          _controllers[MeasurementType.doseRate]!.text =
                              t == null ? '' : _trimNumber(t);
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<ActivityUnit>(
                  valueListenable: ActivityUnitController.unit,
                  builder: (context, current, _) {
                    return DropdownButtonFormField<ActivityUnit>(
                      key: ValueKey('activity-${current.name}'),
                      initialValue: current,
                      isExpanded: true,
                      decoration:
                          InputDecoration(labelText: loc.activityUnitLabel),
                      items: [
                        for (final u in ActivityUnit.values)
                          DropdownMenuItem(value: u, child: Text(u.symbol)),
                      ],
                      onChanged: (u) {
                        if (u != null) ActivityUnitController.setUnit(u);
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                for (final k in BasisKind.values) ...[
                  ValueListenableBuilder<BasisUnit>(
                    valueListenable: BasisUnitController.notifierOf(k),
                    builder: (context, current, _) {
                      return DropdownButtonFormField<BasisUnit>(
                        key: ValueKey('basis-${k.name}-${current.symbol}'),
                        initialValue: current,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: k.settingLabel(loc)),
                        items: [
                          for (final u in BasisUnit.ofKind(k))
                            DropdownMenuItem(value: u, child: Text(u.symbol)),
                        ],
                        onChanged: (u) {
                          if (u != null) BasisUnitController.setUnit(u);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                ValueListenableBuilder<DistanceUnit>(
                  valueListenable: DistanceUnitController.unit,
                  builder: (context, current, _) {
                    return DropdownButtonFormField<DistanceUnit>(
                      key: ValueKey('distance-${current.name}'),
                      initialValue: current,
                      isExpanded: true,
                      decoration:
                          InputDecoration(labelText: loc.distanceUnitLabel),
                      items: [
                        for (final u in DistanceUnit.values)
                          DropdownMenuItem(value: u, child: Text(u.symbol)),
                      ],
                      onChanged: (u) {
                        if (u != null) DistanceUnitController.setUnit(u);
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<DecimalSeparatorMode>(
                  valueListenable: DecimalSeparatorController.mode,
                  builder: (context, current, _) {
                    return DropdownButtonFormField<DecimalSeparatorMode>(
                      key: ValueKey('decimal-${current.name}'),
                      initialValue: current,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: loc.decimalSeparatorLabel,
                        helperText: loc.decimalSeparatorHint,
                        helperMaxLines: 3,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: DecimalSeparatorMode.auto,
                          child: Text(loc.decimalSeparatorAuto),
                        ),
                        DropdownMenuItem(
                          value: DecimalSeparatorMode.comma,
                          child: Text(loc.decimalSeparatorComma),
                        ),
                        DropdownMenuItem(
                          value: DecimalSeparatorMode.dot,
                          child: Text(loc.decimalSeparatorDot),
                        ),
                      ],
                      onChanged: (m) {
                        if (m != null) DecimalSeparatorController.setMode(m);
                      },
                    );
                  },
                ),
                ],
                if (category == _SettingsCategory.bluetooth) ...[
                Text(
                  loc.btnSectionTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: HardwareButtonController.enabled,
                  builder: (context, isOn, _) => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(loc.btnEnabledLabel),
                    subtitle: Text(loc.btnEnabledHelp),
                    value: isOn,
                    onChanged: (v) => HardwareButtonController.setEnabled(v),
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: HardwareButtonController.keepScreenOn,
                  builder: (context, isOn, _) => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(loc.keepScreenOnLabel),
                    subtitle: Text(loc.keepScreenOnHelp),
                    value: isOn,
                    onChanged: (v) =>
                        HardwareButtonController.setKeepScreenOn(v),
                  ),
                ),
                const SizedBox(height: 8),
                for (final button in _visibleButtons()) ...[
                  ValueListenableBuilder<ButtonCommand>(
                    valueListenable: HardwareButtonController.commandOf(button),
                    builder: (context, current, _) {
                      return DropdownButtonFormField<ButtonCommand>(
                        key: ValueKey('button-${button.name}-${current.name}'),
                        initialValue: current,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: _buttonLabel(loc, button),
                        ),
                        items: [
                          for (final c in ButtonCommand.values)
                            DropdownMenuItem(
                              value: c,
                              child: Text(_commandLabel(loc, c)),
                            ),
                        ],
                        onChanged: (c) {
                          if (c != null) {
                            HardwareButtonController.setCommand(button, c);
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 12),
                Text(
                  loc.btnKeyboardSectionTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(loc.btnKeyboardHelp, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                ValueListenableBuilder<List<LearnedKey>>(
                  valueListenable: HardwareButtonController.learnedKeys,
                  builder: (context, keys, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (keys.isEmpty)
                        Text(
                          loc.btnKeyboardEmpty,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      for (final k in keys) ...[
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<ButtonCommand>(
                                key: ValueKey(
                                  'learned-${k.keyId}-${k.command.name}',
                                ),
                                initialValue: k.command,
                                isExpanded: true,
                                decoration: InputDecoration(labelText: k.label),
                                items: [
                                  for (final c in ButtonCommand.values)
                                    DropdownMenuItem(
                                      value: c,
                                      child: Text(_commandLabel(loc, c)),
                                    ),
                                ],
                                onChanged: (c) {
                                  if (c != null) {
                                    HardwareButtonController
                                        .setLearnedKeyCommand(k.keyId, c);
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              tooltip: loc.deleteButton,
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => HardwareButtonController
                                  .removeLearnedKey(k.keyId),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text(loc.btnKeyboardAdd),
                        onPressed: () => _learnKeyboardKey(context, loc),
                      ),
                    ],
                  ),
                ),
                ],
                if (category == _SettingsCategory.units) ...[
                Text(loc.displayUnitsHint, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                DisplayUnitDropdown(
                  label: loc.displayDoseUnitLabel,
                  notifier: DisplayUnits.dose,
                  category: UnitCategory.dose,
                  autoLabel: loc.displayDoseAutoOption,
                  onChanged: DisplayUnits.setDose,
                ),
                const SizedBox(height: 12),
                DisplayUnitDropdown(
                  label: loc.displaySurfaceUnitLabel,
                  notifier: DisplayUnits.surface,
                  category: UnitCategory.surfaceContamination,
                  onChanged: DisplayUnits.setSurface,
                ),
                const SizedBox(height: 12),
                DisplayUnitDropdown(
                  label: loc.displayTemperatureUnitLabel,
                  notifier: DisplayUnits.temperature,
                  category: UnitCategory.temperature,
                  onChanged: DisplayUnits.setTemperature,
                ),
                const SizedBox(height: 12),
                DisplayUnitDropdown(
                  label: loc.displayPressureUnitLabel,
                  notifier: DisplayUnits.pressure,
                  category: UnitCategory.pressure,
                  onChanged: DisplayUnits.setPressure,
                ),
                const SizedBox(height: 12),
                DisplayUnitDropdown(
                  label: loc.displayWindUnitLabel,
                  notifier: DisplayUnits.wind,
                  category: UnitCategory.speed,
                  onChanged: DisplayUnits.setWind,
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<RegulatoryProfile>(
                  valueListenable: RegulatoryProfileController.profile,
                  builder: (context, current, _) {
                    return DropdownButtonFormField<RegulatoryProfile>(
                      key: ValueKey('regprofile-${current.name}'),
                      initialValue: current,
                      isExpanded: true,
                      decoration: InputDecoration(
                          labelText: loc.regulatoryProfileLabel),
                      items: [
                        DropdownMenuItem(
                          value: RegulatoryProfile.international,
                          child: Text(loc.regulatoryProfileInternational),
                        ),
                        DropdownMenuItem(
                          value: RegulatoryProfile.hungary,
                          child: Text(loc.regulatoryProfileHungary),
                        ),
                      ],
                      onChanged: (p) {
                        if (p != null) {
                          RegulatoryProfileController.setProfile(p);
                        }
                      },
                    );
                  },
                ),
                ],
                if (category == _SettingsCategory.appearance) ...[
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
                        const DropdownMenuItem(
                          value: Locale('de'),
                          child: Text('Deutsch'),
                        ),
                        const DropdownMenuItem(
                          value: Locale('es'),
                          child: Text('Español'),
                        ),
                        const DropdownMenuItem(
                          value: Locale('fr'),
                          child: Text('Français'),
                        ),
                        const DropdownMenuItem(
                          value: Locale('it'),
                          child: Text('Italiano'),
                        ),
                      ],
                      onChanged: LocaleController.setLocale,
                    );
                  },
                ),
                ],
                if (category == _SettingsCategory.data) ...[
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
                ],
                if (category == _SettingsCategory.expiry) ...[
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
                ],
                ],
                if (category == _SettingsCategory.alerts) ...[
                Text(
                  loc.alertThresholdExplanation,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 20),
                ...MeasurementType.values
                    .where((t) => t.hasValue)
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
                ],
                if (category == _SettingsCategory.help) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.help_outline),
                  title: Text(loc.helpManualTitle),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () async {
                    final ok = await HelpLauncher.openManual();
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.helpManualOpenError)),
                      );
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.volunteer_activism),
                  title: Text(loc.contributorsTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openContributors,
                ),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    if (info == null) return const SizedBox.shrink();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.info_outline),
                      title: Text(loc.appVersionLabel),
                      trailing: Text('${info.version} (${info.buildNumber})'),
                    );
                  },
                ),
                ],
              ],
            ),
      ),
    );
  }
}

/// Az iPhone nem adja át a hangerőgombokat, ezért azok nem kötehetők.
List<HardwareButton> _visibleButtons() => [
      for (final b in HardwareButton.values)
        if (!(Platform.isIOS &&
            (b == HardwareButton.volumeUp || b == HardwareButton.volumeDown)))
          b,
    ];

/// Megtanítja a következő lenyomott billentyűt a távirányítóról.
Future<void> _learnKeyboardKey(
  BuildContext context,
  AppLocalizations loc,
) async {
  final navigator = Navigator.of(context);
  var open = true;
  HardwareButtons.startLearning((key) {
    HardwareButtonController.addLearnedKey(key);
    if (open) {
      open = false;
      navigator.pop();
    }
  });
  await showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(loc.btnKeyboardLearnTitle),
      content: Text(loc.btnKeyboardLearnBody),
      actions: [
        TextButton(
          onPressed: () {
            if (open) {
              open = false;
              navigator.pop();
            }
          },
          child: Text(loc.cancelButton),
        ),
      ],
    ),
  );
  open = false;
  HardwareButtons.stopLearning();
}

String _buttonLabel(AppLocalizations loc, HardwareButton button) =>
    switch (button) {
      HardwareButton.volumeUp => loc.btnKeyVolumeUp,
      HardwareButton.volumeDown => loc.btnKeyVolumeDown,
      HardwareButton.play => loc.btnKeyPlay,
      HardwareButton.next => loc.btnKeyNext,
      HardwareButton.previous => loc.btnKeyPrevious,
    };

String _commandLabel(AppLocalizations loc, ButtonCommand command) =>
    switch (command) {
      ButtonCommand.nothing => loc.btnCommandNothing,
      ButtonCommand.newPoint => loc.btnCommandNewPoint,
      ButtonCommand.takePhoto => loc.btnCommandTakePhoto,
      ButtonCommand.modbusQuery => loc.btnCommandModbus,
      ButtonCommand.savePoint => loc.btnCommandSavePoint,
      ButtonCommand.saveAndNewPoint => loc.btnCommandSaveAndNew,
      ButtonCommand.discardPoint => loc.btnCommandDiscard,
      ButtonCommand.nextMeasurementType => loc.btnCommandNextType,
      ButtonCommand.previousMeasurementType => loc.btnCommandPrevType,
      ButtonCommand.modbusAveraging => loc.btnCommandAveraging,
      ButtonCommand.toggleSourcePosition => loc.btnCommandSourcePosition,
      ButtonCommand.toggleAutoLog => loc.btnCommandToggleAutoLog,
    };
