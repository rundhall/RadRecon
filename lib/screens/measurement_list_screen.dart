import '../models/hardware_button.dart';
import '../widgets/filter_label.dart';
import '../services/hardware_buttons.dart';
import '../models/bio_agent.dart';
import '../l10n/domain_labels.dart';
import '../models/measurement_type.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/measurement_point.dart';
import '../models/calibration_labels.dart';
import '../models/shielding_labels.dart';
import '../widgets/dose_widgets.dart';
import '../widgets/measurement_kind_icon.dart';
import '../models/survey_purpose.dart';
import '../models/survey_session.dart';
import '../widgets/survey_purpose_dropdown.dart';
import 'protocol_fields_screen.dart';
import '../services/point_exchange_service.dart';
import '../services/measurement_filter.dart';
import '../services/survey_filter.dart';
import '../services/protocol_export_service.dart';
import '../services/screenshot_service.dart';
import 'auto_log_screen.dart';
import 'distance_tool_screen.dart';
import '../services/unit_format.dart';
import 'gradient_search_screen.dart';
import 'isotope_calculator_screen.dart';
import 'unit_converter_screen.dart';
import '../services/display_units.dart';
import 'decay_calculator_screen.dart';
import 'measurement_entry_screen.dart';
import 'session_person_link_screen.dart';
import 'survey_map_screen.dart';
import 'sample_analysis_screen.dart';

enum _ListMenuAction {
  editSurveyDetails,
  protocolFields,
  sessionPersons,
  autoLog,
  distanceTool,
  isotopeCalculator,
  decayCalculator,
  gradientSearch,
  unitConverter,
  closeSurvey,
  exportProtocol,
  exportJsonData,
  exportCsvData,
  importJsonData,
  captureListScreenshot,
}

/// Egy felmérés (survey session) eddig rögzített pontjainak listája.
class MeasurementListScreen extends StatefulWidget {
  final int surveySessionId;
  final String surveyTitle;

  const MeasurementListScreen({
    super.key,
    required this.surveySessionId,
    required this.surveyTitle,
  });

  @override
  State<MeasurementListScreen> createState() => _MeasurementListScreenState();
}

class _MeasurementListScreenState extends State<MeasurementListScreen> {
  late final ButtonCommandHandler _buttonHandler = _onButtonCommand;
  late Future<List<SurveyListItem>> _pointsFuture;
  final _dateFormat = DateFormat('MM.dd HH:mm:ss');
  final _exportService = ProtocolExportService();
  final _exchangeService = PointExchangeService();
  bool _isExporting = false;
  bool _isExchanging = false;
  SurveySession? _session;
  final _listBoundaryKey = GlobalKey();
  String _query = '';
  MeasurementType? _kind; // null = minden típus
  bool _sourceOnly = false;
  SurveyTimeFilter _time = SurveyTimeFilter.all;
  DateTime? _customFrom;
  DateTime? _customTo; // a tartomány utáni nap eleje (nyílt vég)
  MeasurementSort _sort = MeasurementSort.timeNewest;

  @override
  void initState() {
    super.initState();
    HardwareButtons.register(_buttonHandler);
    _reload();
    _loadSession();
  }

  @override
  void dispose() {
    HardwareButtons.unregister(_buttonHandler);
    super.dispose();
  }

  /// Bluetooth-gomb: új mérési pont a felmérésbe.
  bool _onButtonCommand(ButtonCommand command) {
    // Csak a legfelső képernyő reagáljon: egy másik képernyő (pl. a mérési pont
    // felvétele) fölött a gomb ne nyisson újabb képernyőt a háttérben lévőből.
    if (!mounted || ModalRoute.of(context)?.isCurrent == false) return false;
    if (command == ButtonCommand.toggleAutoLog && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AutoLogScreen(
            surveySessionId: widget.surveySessionId,
            autoStart: true,
          ),
        ),
      );
      return true;
    }
    if (command != ButtonCommand.newPoint || !mounted) return false;
    Navigator.of(context)
        .push<bool>(
          MaterialPageRoute(
            builder: (_) => MeasurementEntryScreen(
              surveySessionId: widget.surveySessionId,
            ),
          ),
        )
        .then((saved) {
      if (saved == true) _reload();
    });
    return true;
  }

  Future<void> _loadSession() async {
    final session =
        await DatabaseHelper.instance.getSurveySession(widget.surveySessionId);
    if (mounted) setState(() => _session = session);
  }

  /// A felmérés aktuális neve — a widget konstruktorába adott érték csak a
  /// kezdeti megnevezés, ezt később a felhasználó szerkesztheti, ezért itt a
  /// betöltött [_session] a hiteles forrás, ha már elérhető.
  String get _displayTitle => _session?.title ?? widget.surveyTitle;

  Future<void> _editSurveyDetails() async {
    final loc = AppLocalizations.of(context)!;
    final session = _session;
    if (session == null) return;
    final titleCtrl = TextEditingController(text: session.title);
    final locationCtrl = TextEditingController(text: session.location ?? '');
    SurveyPurpose? purpose = session.purpose;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.editSurveyDetailsTitle),
        content: Column(
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.saveButton),
          ),
        ],
      ),
    );

    if (confirmed != true || titleCtrl.text.trim().isEmpty) return;
    final newTitle = titleCtrl.text.trim();
    final newLocation =
        locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim();

    await DatabaseHelper.instance.updateSurveySessionDetails(
      widget.surveySessionId,
      newTitle,
      newLocation,
      purpose,
    );
    if (mounted) {
      setState(
        () => _session = SurveySession(
          id: session.id,
          title: newTitle,
          location: newLocation,
          notes: session.notes,
          startedAt: session.startedAt,
          closedAt: session.closedAt,
          purpose: purpose,
        ),
      );
    }
  }

  /// Mérési pontok, és a térképen elhelyezett források (térképi pozícióval).
  Future<List<SurveyListItem>> _loadItems() async {
    final db = DatabaseHelper.instance;
    final points = await db.getMeasurementPoints(widget.surveySessionId);
    final placements = await db.getSurveyPlacements(widget.surveySessionId);
    final sources = await db.getRadiationSources();
    final nuclidesBySource = await db.getNuclideNamesBySource();
    final byId = {for (final src in sources) if (src.id != null) src.id!: src};
    final items = <SurveyListItem>[for (final p in points) SurveyListItem.point(p)];
    for (final pl in placements) {
      if (!pl.hasMapPosition) continue;
      final src = byId[pl.radiationSourceId];
      if (src == null) continue;
      items.add(SurveyListItem.source(
        pl,
        src.identifier,
        nuclidesBySource[src.id] ?? [src.nuclideName],
      ));
    }
    return items;
  }

  void _reload() {
    setState(() {
      _pointsFuture = _loadItems();
    });
  }

  Future<void> _closeSurvey() async {
    final loc = AppLocalizations.of(context)!;
    final db = DatabaseHelper.instance;
    final attached = await db.getAttachedPersons(widget.surveySessionId);
    final doses = await db.getSessionDoseSnapshot(widget.surveySessionId);
    if (!mounted) return;

    // A résztvevők dózisát a lezárás előtt még utoljára lehet módosítani.
    final editorKey = GlobalKey<SessionDosesEditorState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.closeSurveyTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.closeSurveyConfirm),
              if (attached.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  loc.closeSurveyDosesTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  loc.closeSurveyDosesHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SessionDosesEditor(
                  key: editorKey,
                  surveySessionId: widget.surveySessionId,
                  persons: attached,
                  doses: doses,
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
            onPressed: () async {
              final editor = editorKey.currentState;
              if (editor != null && !await editor.save()) return;
              if (context.mounted) Navigator.of(context).pop(true);
            },
            child: Text(loc.closeSurveyButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await DatabaseHelper.instance
        .closeSurveySession(widget.surveySessionId, DateTime.now());
    await _loadSession();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.surveyClosedMessage)));
    }
  }

  Future<void> _openEntryScreen({
    MeasurementPoint? existing,
    MeasurementPoint? template,
  }) async {
    MeasurementPoint? source;
    if (template != null) {
      final key = await DatabaseHelper.instance.ensureGroupKey(template);
      source = template.copyWith(groupKey: key);
    }
    if (!mounted) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MeasurementEntryScreen(
          surveySessionId: widget.surveySessionId,
          existingPoint: existing,
          templatePoint: source,
        ),
      ),
    );
    if (saved == true) _reload();
  }

  void _handleMenuAction(_ListMenuAction action) {
    switch (action) {
      case _ListMenuAction.editSurveyDetails:
        _editSurveyDetails();
        break;
      case _ListMenuAction.protocolFields:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProtocolFieldsScreen(
              surveySessionId: widget.surveySessionId,
            ),
          ),
        );
        break;
      case _ListMenuAction.sessionPersons:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SessionPersonLinkScreen(
              surveySessionId: widget.surveySessionId,
            ),
          ),
        );
        break;
        
      case _ListMenuAction.autoLog:
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) =>
                    AutoLogScreen(surveySessionId: widget.surveySessionId),
              ),
            )
            .then((_) => _reload());
        break;
      case _ListMenuAction.distanceTool:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                DistanceToolScreen(surveySessionId: widget.surveySessionId),
          ),
        );
        break;
      case _ListMenuAction.isotopeCalculator:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const IsotopeCalculatorScreen()),
        );
        break;
      case _ListMenuAction.decayCalculator:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DecayCalculatorScreen()),
        );
        break;
      case _ListMenuAction.gradientSearch:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                GradientSearchScreen(surveySessionId: widget.surveySessionId),
          ),
        );
        break;
      case _ListMenuAction.unitConverter:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const UnitConverterScreen()),
        );
        break;
      case _ListMenuAction.closeSurvey:
        _closeSurvey();
        break;
      case _ListMenuAction.exportProtocol:
        _exportProtocol();
        break;
      case _ListMenuAction.exportJsonData:
        _exportJsonData();
        break;
      case _ListMenuAction.exportCsvData:
        _exportCsvData();
        break;
      case _ListMenuAction.importJsonData:
        _importJsonData();
        break;
      case _ListMenuAction.captureListScreenshot:
        _captureListScreenshot();
        break;
    }
  }

  /// Elmenti a listából éppen látszó részt képként. Görgetéssel takart
  /// sorok nem kerülnek rá — ha a teljes lista kell, több képernyőkép
  /// készítése ajánlott görgetés közben.
  Future<void> _captureListScreenshot() async {
    final loc = AppLocalizations.of(context)!;
    try {
      await ScreenshotService.capture(
        boundaryKey: _listBoundaryKey,
        surveySessionId: widget.surveySessionId,
        label: 'pontok_lista',
        l10n: loc,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.listScreenshotSavedMessage),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.screenshotErrorMessage('$e'))));
      }
    }
  }

  Future<void> _exportProtocol() async {
    final loc = AppLocalizations.of(context)!;
    final choice = await showDialog<(ProtocolFormat, ProtocolExportOptions)>(
      context: context,
      builder: (ctx) {
        var includeImages = true;
        var shrinkImages = true;
        var autoRotate = true;
        ProtocolExportOptions current() => ProtocolExportOptions(
              includeImages: includeImages,
              shrinkImages: shrinkImages,
              autoRotate: autoRotate,
            );
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) => AlertDialog(
            title: Text(loc.protocolFormatTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(loc.protocolIncludeImages),
                  value: includeImages,
                  onChanged: (v) =>
                      setDialogState(() => includeImages = v ?? true),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(loc.protocolShrinkImages),
                  value: shrinkImages,
                  onChanged: includeImages
                      ? (v) => setDialogState(() => shrinkImages = v ?? true)
                      : null,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(loc.protocolAutoRotate),
                  value: autoRotate,
                  onChanged: includeImages
                      ? (v) => setDialogState(() => autoRotate = v ?? true)
                      : null,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogCtx, (ProtocolFormat.word, current())),
                child: Text(loc.protocolFormatWord),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(dialogCtx, (ProtocolFormat.pdf, current())),
                child: Text(loc.protocolFormatPdf),
              ),
            ],
          ),
        );
      },
    );
    if (choice == null || !mounted) return;
    final (format, options) = choice;

    setState(() => _isExporting = true);
    try {
      final file = format == ProtocolFormat.pdf
          ? await _exportService.exportSurveyPdf(
              widget.surveySessionId, loc, options: options)
          : await _exportService.exportSurvey(
              widget.surveySessionId, loc, options: options);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: loc.protocolShareSubject(_displayTitle),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.exportErrorMessage('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// Nyers mérési adatok exportálása JSON-ba — más RadRecon-telepítésbe
  /// visszatölthető, teljes adattartalommal (fényképek nélkül).
  Future<void> _exportJsonData() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _isExchanging = true);
    try {
      final file = await _exchangeService.exportJson(widget.surveySessionId);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: loc.dataExportSubject(_displayTitle),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.exportErrorMessage('$e'))));
      }
    } finally {
      if (mounted) setState(() => _isExchanging = false);
    }
  }

  /// Táblázatos (CSV) nézet Excelhez — csak megtekintésre, nem tölthető
  /// vissza az appba.
  Future<void> _exportCsvData() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _isExchanging = true);
    try {
      final file = await _exchangeService.exportCsv(
        widget.surveySessionId,
          typeLabel: (t) => t.name,
        csvHeaders: CsvHeaders(
          serialNumber: loc.csvHeaderSerialNumber,
          basis: loc.csvHeaderBasis,
          radiation: loc.csvHeaderRadiation,
          quantity: loc.csvHeaderQuantity,
          spectrum: loc.csvHeaderSpectrum,
          location: loc.csvHeaderLocation,
          type: loc.csvHeaderType,
          value: loc.csvHeaderValue,
          unit: loc.csvHeaderUnit,
          distanceFromSource: loc.csvHeaderDistanceFromSource,
          instrument: loc.csvHeaderInstrument,
          gpsLatitude: loc.csvHeaderGpsLatitude,
          gpsLongitude: loc.csvHeaderGpsLongitude,
          gpsAccuracy: loc.csvHeaderGpsAccuracy,
          timestamp: loc.csvHeaderTimestamp,
          sample: loc.csvHeaderSample,
          notes: loc.csvHeaderNotes,
          estimatedActivity: loc.csvHeaderEstimatedActivity,
          attachedSources: loc.csvHeaderAttachedSources,
          calculatedDoseRate: loc.csvHeaderCalculatedDoseRate,
          doseRateDifference: loc.csvHeaderDoseRateDifference,
          nuclides: loc.csvHeaderNuclides,
          instrumentCalibration: loc.csvHeaderInstrumentCalibration,
          valueError: loc.csvHeaderValueError,
          averaging: loc.csvHeaderAveraging,
          calibrationKindLabel: (k) => calibrationKindLabel(loc, k),
          validUntilLabel: loc.calibrationValidUntilLabel,
          certificateLabel: loc.calibrationCertificateLabel,
          expiredNote: loc.calibrationStatusExpired,
          nuclideStatusLabel: (s) => s.label(loc),
          shieldingMaterialLabel: (m) => shieldingMaterialLabel(loc, m),
          unshieldedNote: loc.csvUnshieldedNote,
          shieldedSourceNote: loc.csvShieldedSourceNote,
          yes: loc.csvYes,
          no: loc.csvNo,
        ),
      );
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: loc.csvExportSubject(_displayTitle),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.exportErrorMessage('$e'))));
      }
    } finally {
      if (mounted) setState(() => _isExchanging = false);
    }
  }

  /// Egy másik RadRecon-exportból (JSON) importálja a pontokat ebbe a
  /// felmérésbe. A hiányzó műszereket névazonosítás alapján létrehozza.
  Future<void> _importJsonData() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'json'],
    );
    if (picked.isEmpty) return;
    final path = picked.first.path;
    if (path == null || !mounted) return;

    final loc = AppLocalizations.of(context)!;
    setState(() => _isExchanging = true);
    try {
      final result = await _exchangeService.importJson(
        path,
        widget.surveySessionId,
        unknownTypeWarning: loc.importUnknownTypeWarning,
        missingGpsWarning: loc.importMissingGpsWarning,
      );
      _reload();
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(loc.importDoneTitle),
            content: Text(
              loc.importedPointsMessage(
                    result.pointsImported,
                    result.instrumentsCreated,
                    result.sourcesCreated,
                  ) +
                  (result.warnings.isEmpty
                      ? ''
                      : '\n\n${result.warnings.join('\n')}'),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(loc.okButton),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.importErrorMessage('$e'))));
      }
    } finally {
      if (mounted) setState(() => _isExchanging = false);
    }
  }

  String _sortLabel(AppLocalizations loc, MeasurementSort f) => switch (f) {
        MeasurementSort.timeNewest => loc.surveySortTimeNewest,
        MeasurementSort.timeOldest => loc.surveySortTimeOldest,
        MeasurementSort.valueHighest => loc.measurementSortValueHighest,
        MeasurementSort.valueLowest => loc.measurementSortValueLowest,
        MeasurementSort.nameAsc => loc.surveySortNameAsc,
        MeasurementSort.nameDesc => loc.surveySortNameDesc,
      };

  String _timeLabel(AppLocalizations loc, SurveyTimeFilter f) => switch (f) {
        SurveyTimeFilter.all => loc.surveyTimeAll,
        SurveyTimeFilter.last7 => loc.surveyTimeLast7,
        SurveyTimeFilter.last30 => loc.surveyTimeLast30,
        SurveyTimeFilter.thisYear => loc.surveyTimeThisYear,
        SurveyTimeFilter.custom => loc.surveyTimeCustom,
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_displayTitle, overflow: TextOverflow.ellipsis),
            if (_session?.location != null && _session!.location!.isNotEmpty)
              Text(
                _session!.location!,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
         
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: loc.mapTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    SurveyMapScreen(surveySessionId: widget.surveySessionId),
              ),
            ),
          ),
          if (_isExporting || _isExchanging)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            PopupMenuButton<_ListMenuAction>(
              tooltip: loc.toolsTooltip,
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [

                PopupMenuItem(
                  value: _ListMenuAction.editSurveyDetails,
                  child: ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(loc.editSurveyDetailsTooltip),
                  ),
                ),
                PopupMenuItem(
                  value: _ListMenuAction.protocolFields,
                  child: ListTile(
                    leading: const Icon(Icons.fact_check_outlined),
                    title: Text(loc.protocolFieldsTooltip),
                  ),
                ),
        
                PopupMenuItem(
                  value: _ListMenuAction.sessionPersons,
                  child: ListTile(
                    leading: const Icon(Icons.people_outline),
                    title: Text(loc.sessionPersonsTitle),
                  ),
                ),
                PopupMenuItem(
                  value: _ListMenuAction.autoLog,
                  child: ListTile(
                    leading: const Icon(Icons.radar),
                    title: Text(loc.autoLogMenuItem),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: _ListMenuAction.distanceTool,
                  child: ListTile(
                    leading: const Icon(Icons.straighten),
                    title: Text(loc.distanceToolTitle),
                  ),
                ),
                PopupMenuItem(
                  value: _ListMenuAction.isotopeCalculator,
                  child: ListTile(
                    leading: const Icon(Icons.calculate_outlined),
                    title: Text(loc.isotopeCalculatorTitle),
                  ),
                ),
                PopupMenuItem(
                  value: _ListMenuAction.decayCalculator,
                  child: ListTile(
                    leading: const Icon(Icons.timelapse),
                    title: Text(loc.decayCalcTitle),
                  ),
                ),
                PopupMenuItem(
                  value: _ListMenuAction.gradientSearch,
                  child: ListTile(
                    leading: const Icon(Icons.explore_outlined),
                    title: Text(loc.sourceSearchTitle),
                  ),
                ),
                PopupMenuItem(
                  value: _ListMenuAction.unitConverter,
                  child: ListTile(
                    leading: const Icon(Icons.swap_horiz),
                    title: Text(loc.unitConverterTitle),
                  ),
                ),
                PopupMenuItem(
                  value: _ListMenuAction.captureListScreenshot,
                  child: ListTile(
                    leading: const Icon(Icons.camera_alt_outlined),
                    title: Text(loc.captureListScreenshotMenuItem),
                  ),
                ),
                const PopupMenuDivider(),
                if (_session != null && !_session!.isClosed)
                  PopupMenuItem(
                    value: _ListMenuAction.closeSurvey,
                    child: ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(loc.closeSurveyTitle),
                    ),
                  ),
                PopupMenuItem(
                  value: _ListMenuAction.exportProtocol,
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(loc.exportProtocolMenuItem),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: _ListMenuAction.exportJsonData,
                  child: ListTile(
                    leading: const Icon(Icons.upload_file_outlined),
                    title: Text(loc.exportJsonMenuItem),
                  ),
                ),
                PopupMenuItem(
                  value: _ListMenuAction.exportCsvData,
                  child: ListTile(
                    leading: const Icon(Icons.table_chart_outlined),
                    title: Text(loc.exportCsvMenuItem),
                  ),
                ),
                PopupMenuItem(
                  value: _ListMenuAction.importJsonData,
                  child: ListTile(
                    leading: const Icon(Icons.download_outlined),
                    title: Text(loc.importJsonMenuItem),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: FutureBuilder<List<SurveyListItem>>(
        future: _pointsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data!;
          if (all.isEmpty) {
            return Center(child: Text(loc.noPointsRecordedYet));
          }
          final now = DateTime.now();
          final points = sortItems(
            all
                .where((p) =>
                    itemMatchesKind(p, _kind) &&
                    itemMatchesSourceOnly(p, _sourceOnly) &&
                    itemMatchesTime(
                      p,
                      _time,
                      now: now,
                      customFrom: _customFrom,
                      customTo: _customTo,
                    ) &&
                    itemMatchesQuery(p, _query))
                .toList(),
            _sort,
          );
          return RepaintBoundary(
            key: _listBoundaryKey,
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: loc.searchHint,
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        suffixText: '${points.length} / ${all.length}',
                        isDense: true,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButton<Object>(
                                isExpanded: true,
                                value: _sourceOnly ? #sourceOnly : (_kind ?? #allKinds),
                                items: [
                                  DropdownMenuItem<Object>(
                                    value: #allKinds,
                                    child: filterLabel(loc.measurementFilterAllKinds),
                                  ),
                                  DropdownMenuItem<Object>(
                                    value: #sourceOnly,
                                    child: filterLabel(loc.measurementFilterSourceOnly),
                                  ),
                                  for (final t in MeasurementType.values)
                                    DropdownMenuItem<Object>(
                                      value: t,
                                      child: filterLabel(t.label(context)),
                                    ),
                                ],
                                onChanged: (v) => setState(() {
                                  _sourceOnly = v == #sourceOnly;
                                  _kind = v is MeasurementType ? v : null;
                                }),
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
                                      child: filterLabel(_timeLabel(loc, f)),
                                    ),
                                ],
                                onChanged: _onTimeChanged,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButton<MeasurementSort>(
                          isExpanded: true,
                          value: _sort,
                          items: [
                            for (final f in MeasurementSort.values)
                              DropdownMenuItem(
                                value: f,
                                child: filterLabel(_sortLabel(loc, f)),
                              ),
                          ],
                          onChanged: (v) => setState(() => _sort = v ?? _sort),
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
                    child: points.isEmpty
                        ? Center(child: Text(loc.searchNoResults))
                        : ListView.separated(
                            itemCount: points.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final it = points[index];
                              if (it.isSourceRow) {
                                final nuclides = it.nuclides
                                    .where((n) => n.isNotEmpty)
                                    .toSet()
                                    .join(', ');
                                return ListTile(
                                  leading: Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.amber.shade800,
                                  ),
                                  title: Text(it.sourceIdentifier),
                                  subtitle: Text(
                                    nuclides.isEmpty
                                        ? loc.sourceOnMapListLabel
                                        : '${loc.sourceOnMapListLabel} · $nuclides',
                                  ),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => SurveyMapScreen(
                                        surveySessionId: widget.surveySessionId,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final p = it.point!;
                              return ListTile(
                                leading: p.isSourcePosition
                                    ? const Icon(Icons.warning_amber, color: Colors.deepOrange)
                                    : Icon(measurementKindIcon(isSample: p.isSample, type: p.type)),
                                title: Text(measurementName(p)),
                                subtitle: Text(
                                  p.isSample
                                      ? loc.sampleTakenListLabel(_dateFormat.format(p.timestamp))
                                      : p.type == MeasurementType.biological
                                          ? '${bioAgentsSummary(p.bioAgents)} · ${_dateFormat.format(p.timestamp)}'
                                          : '${p.type == MeasurementType.spectrum ? spectrumSummaryLine(loc, p) : displayValueText(p)} · ${_dateFormat.format(p.timestamp)}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (p.isSample || p.type == MeasurementType.biological)
                                      IconButton(
                                        icon: const Icon(Icons.biotech),
                                        tooltip: loc.sampleAnalysisTooltip,
                                        onPressed: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => SampleAnalysisScreen(point: p),
                                          ),
                                        ),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.copy_all),
                                      tooltip: loc.pointCopyTooltip,
                                      onPressed: () => _openEntryScreen(template: p),
                                    ),
                                    if (p.gpsAccuracyMeters != null)
                                      Text('±${formatDistanceMeters(p.gpsAccuracyMeters!)}'),
                                  ],
                                ),
                                onTap: () => _openEntryScreen(existing: p),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEntryScreen(),
        icon: const Icon(Icons.add),
        label: Text(loc.newPointButton),
      ),
    );
  }
}
