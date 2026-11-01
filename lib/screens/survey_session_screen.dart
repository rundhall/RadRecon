import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import 'survey_classification_screen.dart';
import '../l10n/app_localizations.dart';
import '../l10n/domain_labels.dart';
import '../models/plan_calibration.dart';
import '../models/survey_purpose.dart';
import '../models/survey_session.dart';
import '../services/plan_import_service.dart';
import '../services/survey_filter.dart';
import '../widgets/survey_purpose_dropdown.dart';
import 'company_document_list_screen.dart';
import 'instrument_list_screen.dart';
import 'measurement_list_screen.dart';
import 'person_list_screen.dart';
import 'plan_calibration_screen.dart';
import 'radiation_source_list_screen.dart';
import 'settings_screen.dart';

/// Alaprajz forrása plan módban: feltöltött kép vagy generált háttér.
enum _PlanSource { image, generated }

/// A generált háttér választható színei (ARGB és címke).
final List<({int argb, String Function(AppLocalizations loc) label})>
    _planBackgrounds = [
  (argb: 0xFFFFFFFF, label: (loc) => loc.planColorWhite),
  (argb: 0xFFE0E0E0, label: (loc) => loc.planColorLightGrey),
  (argb: 0xFFFFF8E1, label: (loc) => loc.planColorCream),
  (argb: 0xFFE3F2FD, label: (loc) => loc.planColorLightBlue),
  (argb: 0xFFE8F5E9, label: (loc) => loc.planColorLightGreen),
];

double? _parseMeters(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

/// Induló képernyő: meglévő felmérések listája, és új felmérés indítása.
class SurveySessionScreen extends StatefulWidget {
  const SurveySessionScreen({super.key});

  @override
  State<SurveySessionScreen> createState() => _SurveySessionScreenState();
}

class _SurveySessionScreenState extends State<SurveySessionScreen> {
  late Future<List<SurveySession>> _sessionsFuture;
  final _dateFormat = DateFormat('yyyy.MM.dd HH:mm');
  String _query = '';
  SurveyStatusFilter _status = SurveyStatusFilter.active;
  SurveyTimeFilter _time = SurveyTimeFilter.all;
  SurveySort _sort = SurveySort.timeNewest;
  DateTime? _customFrom;
  DateTime? _customTo; // a tartomány utáni nap eleje (nyílt vég)

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _sessionsFuture = DatabaseHelper.instance.getSurveySessions();
    });
  }

  Future<void> _createSession() async {
    final loc = AppLocalizations.of(context)!;
    final titleCtrl = TextEditingController(
      text: loc.surveyDefaultTitle(
        DateFormat('yyyy.MM.dd').format(DateTime.now()),
      ),
    );
    final locationCtrl = TextEditingController();
    SurveyPurpose? purpose;
    var mapMode = SurveyMapMode.online;
    var planSource = _PlanSource.image;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.newSurveyDialogTitle),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(labelText: loc.surveyNameLabel),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationCtrl,
                decoration: InputDecoration(labelText: loc.surveyLocationLabel),
              ),
              const SizedBox(height: 12),
              SurveyPurposeDropdown(
                value: purpose,
                onChanged: (value) => purpose = value,
              ),
              const SizedBox(height: 12),
              SegmentedButton<SurveyMapMode>(
                segments: [
                  ButtonSegment(
                    value: SurveyMapMode.online,
                    label: Text(loc.surveyMapModeOnline),
                  ),
                  ButtonSegment(
                    value: SurveyMapMode.plan,
                    label: Text(loc.surveyMapModePlan),
                  ),
                ],
                selected: {mapMode},
                onSelectionChanged: (s) =>
                    setDialogState(() => mapMode = s.first),
              ),
              if (mapMode == SurveyMapMode.plan) ...[
                const SizedBox(height: 12),
                SegmentedButton<_PlanSource>(
                  segments: [
                    ButtonSegment(
                      value: _PlanSource.image,
                      label: Text(loc.planSourceImage),
                    ),
                    ButtonSegment(
                      value: _PlanSource.generated,
                      label: Text(loc.planSourceGenerated),
                    ),
                  ],
                  selected: {planSource},
                  onSelectionChanged: (s) =>
                      setDialogState(() => planSource = s.first),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.startButton),
          ),
        ],
      ),
    );

    if (confirmed != true || titleCtrl.text.trim().isEmpty) return;

    PlanCalibration? plan;
    if (mapMode == SurveyMapMode.plan) {
      plan = planSource == _PlanSource.image
          ? await _pickAndCalibratePlan()
          : await _generateAndCalibratePlan();
      if (plan == null) return; // a felhasználó megszakította
    }

    final session = SurveySession(
      title: titleCtrl.text.trim(),
      location:
          locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
      startedAt: DateTime.now(),
      purpose: purpose,
      mapMode: mapMode,
      planCalibration: plan,
    );
    final id = await DatabaseHelper.instance.insertSurveySession(session);
    _reload();
    if (mounted) _openSession(id, session.title);
  }

  /// Feltöltött alaprajz: kiválasztás, másolás, kalibrálás. `null`, ha a
  /// felhasználó megszakítja vagy a fájl nem olvasható (a másolat törlődik).
  Future<PlanCalibration?> _pickAndCalibratePlan() async {
    final loc = AppLocalizations.of(context)!;
    final selection = await FilePicker.pickFiles(type: FileType.image);
    if (selection.isEmpty) return null;
    final sourcePath = selection.single.path;
    if (sourcePath == null) return null;

    final copied = await copyPlanIntoAppStorage(sourcePath);
    final size = await _tryImageSize(copied);
    if (size == null) {
      await File(copied).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.planImageUnreadable)),
        );
      }
      return null;
    }
    if (!mounted) return null;

    final calibration = await Navigator.of(context).push<PlanCalibration>(
      MaterialPageRoute(
        builder: (_) => PlanCalibrationScreen(
          imagePath: copied,
          widthPx: size.width,
          heightPx: size.height,
        ),
      ),
    );
    if (calibration == null) {
      await File(copied).delete();
    }
    return calibration;
  }

  /// Generált háttér: méret és szín megadása, majd a fix méretarányú
  /// kalibráció (az A pont GPS-koordinátája). `null`, ha megszakad.
  Future<PlanCalibration?> _generateAndCalibratePlan() async {
    final spec = await _askGeneratedPlanSpec();
    if (spec == null || !mounted) return null;

    final generated = await generateBlankPlan(
      widthM: spec.widthM,
      heightM: spec.heightM,
      backgroundArgb: spec.argb,
    );
    if (!mounted) {
      await File(generated.path).delete();
      return null;
    }

    final calibration = await Navigator.of(context).push<PlanCalibration>(
      MaterialPageRoute(
        builder: (_) => PlanCalibrationScreen(
          imagePath: generated.path,
          widthPx: generated.widthPx,
          heightPx: generated.heightPx,
          fixedMetersPerPx: generated.metersPerPx,
        ),
      ),
    );
    if (calibration == null) {
      await File(generated.path).delete();
    }
    return calibration;
  }

  /// A generált háttér mérete (méterben) és színe. `null`, ha megszakítják.
  Future<({double widthM, double heightM, int argb})?>
      _askGeneratedPlanSpec() async {
    final loc = AppLocalizations.of(context)!;
    final widthCtrl = TextEditingController(text: '20');
    final heightCtrl = TextEditingController(text: '20');
    const numberKeyboard = TextInputType.numberWithOptions(decimal: true);
    var colorIndex = 0;
    String? errorText;

    return showDialog<({double widthM, double heightM, int argb})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(loc.planSourceGenerated),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: widthCtrl,
                keyboardType: numberKeyboard,
                decoration: InputDecoration(labelText: loc.planBgWidthLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: heightCtrl,
                keyboardType: numberKeyboard,
                decoration: InputDecoration(labelText: loc.planBgHeightLabel),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(loc.planBgColorLabel),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _planBackgrounds.length; i++)
                    ChoiceChip(
                      label: Text(_planBackgrounds[i].label(loc)),
                      selected: colorIndex == i,
                      onSelected: (_) => setDialogState(() => colorIndex = i),
                    ),
                ],
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(errorText!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(loc.cancelButton),
            ),
            FilledButton(
              onPressed: () {
                final w = _parseMeters(widthCtrl.text);
                final h = _parseMeters(heightCtrl.text);
                if (w == null || h == null || w <= 0 || h <= 0 || w > 1000 || h > 1000) {
                  setDialogState(() => errorText = loc.planInvalidValue);
                  return;
                }
                Navigator.of(ctx).pop((
                  widthM: w,
                  heightM: h,
                  argb: _planBackgrounds[colorIndex].argb,
                ));
              },
              child: Text(loc.okButton),
            ),
          ],
        ),
      ),
    );
  }

  Future<({int width, int height})?> _tryImageSize(String path) async {
    try {
      return await planImageSize(path);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openSession(int id, String title) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            MeasurementListScreen(surveySessionId: id, surveyTitle: title),
      ),
    );
    // Session details (e.g. title) may have changed while on that screen.
    _reload();
  }

  String _statusLabel(AppLocalizations loc, SurveyStatusFilter f) => switch (f) {
        SurveyStatusFilter.active => loc.surveyFilterActive,
        SurveyStatusFilter.open => loc.surveyFilterOpen,
        SurveyStatusFilter.closed => loc.surveyFilterClosed,
        SurveyStatusFilter.archived => loc.surveyFilterArchived,
      };

  String _timeLabel(AppLocalizations loc, SurveyTimeFilter f) => switch (f) {
        SurveyTimeFilter.all => loc.surveyTimeAll,
        SurveyTimeFilter.last7 => loc.surveyTimeLast7,
        SurveyTimeFilter.last30 => loc.surveyTimeLast30,
        SurveyTimeFilter.thisYear => loc.surveyTimeThisYear,
        SurveyTimeFilter.custom => loc.surveyTimeCustom,
      };

  String _sortLabel(AppLocalizations loc, SurveySort f) => switch (f) {
        SurveySort.timeNewest => loc.surveySortTimeNewest,
        SurveySort.timeOldest => loc.surveySortTimeOldest,
        SurveySort.nameAsc => loc.surveySortNameAsc,
        SurveySort.nameDesc => loc.surveySortNameDesc,
      };

  /// Egyéni időszak kiválasztása. Megszakításnál a korábbi szűrő marad.
  Future<void> _onTimeChanged(SurveyTimeFilter? value) async {
    if (value == null) return;
    if (value != SurveyTimeFilter.custom) {
      setState(() => _time = value);
      return;
    }
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (range == null || !mounted) return;
    setState(() {
      _customFrom = DateTime(range.start.year, range.start.month, range.start.day);
      _customTo = DateTime(range.end.year, range.end.month, range.end.day + 1);
      _time = SurveyTimeFilter.custom;
    });
  }

  String _customRangeText() {
    final f = DateFormat('yyyy.MM.dd');
    return '${f.format(_customFrom!)} – '
        '${f.format(_customTo!.subtract(const Duration(days: 1)))}';
  }

  /// Archiválás, illetve az archiválás visszavonása. Az adatok nem változnak.
  /// Az archiválás megerősítést kér, hogy véletlenül ne kerüljön ki a lista.
  Future<void> _toggleArchive(SurveySession s) async {
    if (!s.isArchived) {
      final loc = AppLocalizations.of(context)!;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.surveyArchiveConfirmTitle),
          content: Text(loc.surveyArchiveConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(loc.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(loc.surveyArchiveAction),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    await DatabaseHelper.instance.setSurveySessionArchived(
      s.id!,
      s.isArchived ? null : DateTime.now(),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('RadRecon'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sensors),
            tooltip: loc.instrumentsTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InstrumentListScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sunny),
            tooltip: loc.sourcesTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RadiationSourceListScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: loc.personsTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PersonListScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: loc.companyDocumentsTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CompanyDocumentListScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: loc.alertThresholdsTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<SurveySession>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data!;
          if (all.isEmpty) {
            return Center(child: Text(loc.noSurveysYet));
          }
          final now = DateTime.now();
          final sessions = sortSurveys(
            all
                .where((s) =>
                    surveyMatchesStatus(s, _status) &&
                    surveyMatchesTime(
                      s,
                      _time,
                      now: now,
                      customFrom: _customFrom,
                      customTo: _customTo,
                    ) &&
                    surveyMatchesQuery(s, _query))
                .toList(),
            _sort,
          );
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: loc.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<SurveyStatusFilter>(
                        isExpanded: true,
                        value: _status,
                        items: [
                          for (final f in SurveyStatusFilter.values)
                            DropdownMenuItem(
                              value: f,
                              child: Text(_statusLabel(loc, f)),
                            ),
                        ],
                        onChanged: (v) => setState(() => _status = v ?? _status),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<SurveyTimeFilter>(
                        isExpanded: true,
                        value: _time,
                        items: [
                          for (final f in SurveyTimeFilter.values)
                            DropdownMenuItem(
                              value: f,
                              child: Text(_timeLabel(loc, f)),
                            ),
                        ],
                        onChanged: _onTimeChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<SurveySort>(
                        isExpanded: true,
                        value: _sort,
                        items: [
                          for (final f in SurveySort.values)
                            DropdownMenuItem(
                              value: f,
                              child: Text(_sortLabel(loc, f)),
                            ),
                        ],
                        onChanged: (v) => setState(() => _sort = v ?? _sort),
                      ),
                    ),
                  ],
                ),
              ),
              if (_time == SurveyTimeFilter.custom && _customFrom != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_customRangeText()),
                  ),
                ),
              const Divider(height: 1),
              Expanded(
                child: sessions.isEmpty
                    ? Center(child: Text(loc.searchNoResults))
                    : ListView.separated(
                        itemCount: sessions.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final s = sessions[index];
                          return ListTile(
                            leading: Icon(
                              s.isArchived
                                  ? Icons.inventory_2_outlined
                                  : (s.isClosed
                                      ? Icons.check_circle_outline
                                      : Icons.radar),
                              color: s.isArchived || s.isClosed
                                  ? Colors.grey
                                  : Colors.deepOrange,
                            ),
                            title: Text(s.title),
                            subtitle: Text(
                              [
                                if (s.purpose != null) s.purpose!.localized(loc),
                                s.location ?? loc.noLocationPlaceholder,
                                _dateFormat.format(s.startedAt),
                              ].join(' · '),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    s.isArchived
                                        ? Icons.unarchive_outlined
                                        : Icons.archive_outlined,
                                  ),
                                  tooltip: s.isArchived
                                      ? loc.surveyUnarchiveAction
                                      : loc.surveyArchiveAction,
                                  onPressed: () => _toggleArchive(s),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.rule),
                                  tooltip: loc.classificationTitle,
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => SurveyClassificationScreen(
                                        surveySessionId: s.id!,
                                        surveyTitle: s.title,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => _openSession(s.id!, s.title),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSession,
        icon: const Icon(Icons.add),
        label: Text(loc.newSurveyButton),
      ),
    );
  }
}