import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/measurement_point.dart';
import '../widgets/dose_widgets.dart';
import '../models/survey_session.dart';
import '../services/point_exchange_service.dart';
import '../services/protocol_export_service.dart';
import '../services/screenshot_service.dart';
import 'auto_log_screen.dart';
import 'distance_tool_screen.dart';
import 'gradient_search_screen.dart';
import 'isotope_calculator_screen.dart';
import 'measurement_entry_screen.dart';
import 'session_person_link_screen.dart';
import 'survey_map_screen.dart';

enum _ListMenuAction {
  editSurveyDetails,
  sessionPersons,
  autoLog,
  distanceTool,
  isotopeCalculator,
  gradientSearch,
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
  late Future<List<MeasurementPoint>> _pointsFuture;
  final _dateFormat = DateFormat('MM.dd HH:mm:ss');
  final _exportService = ProtocolExportService();
  final _exchangeService = PointExchangeService();
  bool _isExporting = false;
  bool _isExchanging = false;
  SurveySession? _session;
  final _listBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _reload();
    _loadSession();
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

    await DatabaseHelper.instance.updateSurveySessionTitleAndLocation(
      widget.surveySessionId,
      newTitle,
      newLocation,
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
        ),
      );
    }
  }

  void _reload() {
    setState(() {
      _pointsFuture =
          DatabaseHelper.instance.getMeasurementPoints(widget.surveySessionId);
    });
  }

  Future<void> _closeSurvey() async {
    final loc = AppLocalizations.of(context)!;
    final db = DatabaseHelper.instance;
    final attached = await db.getAttachedPersons(widget.surveySessionId);
    final doses = await db.getSessionDoses(widget.surveySessionId);
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

  Future<void> _openEntryScreen({MeasurementPoint? existing}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MeasurementEntryScreen(
          surveySessionId: widget.surveySessionId,
          existingPoint: existing,
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
      case _ListMenuAction.gradientSearch:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                GradientSearchScreen(surveySessionId: widget.surveySessionId),
          ),
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
    setState(() => _isExporting = true);
    try {
      final zipFile = await _exportService.exportSurvey(widget.surveySessionId);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(zipFile.path)],
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
      allowedExtensions: ['json'],
    );
    if (picked.isEmpty) return;
    final path = picked.first.path;
    if (path == null) return;

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
                  value: _ListMenuAction.gradientSearch,
                  child: ListTile(
                    leading: const Icon(Icons.explore_outlined),
                    title: Text(loc.sourceSearchTitle),
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
      body: FutureBuilder<List<MeasurementPoint>>(
        future: _pointsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final points = snapshot.data!;
          if (points.isEmpty) {
            return Center(child: Text(loc.noPointsRecordedYet));
          }
          return RepaintBoundary(
            key: _listBoundaryKey,
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ListView.separated(
                itemCount: points.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final p = points[index];
                  return ListTile(
                    leading: p.isSourcePosition
                        ? const Icon(Icons.warning_amber, color: Colors.deepOrange)
                        : Icon(p.isSample ? Icons.science_outlined : Icons.place),
                    title: Text(
                      p.locationLabel ??
                          '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
                    ),
                    subtitle: Text(
                      p.isSample
                          ? loc.sampleTakenListLabel(_dateFormat.format(p.timestamp))
                          : '${p.value == null ? '—' : double.parse(p.value!.toStringAsFixed(4))} ${p.unit} · ${_dateFormat.format(p.timestamp)}',
                    ),
                    trailing: p.gpsAccuracyMeters != null
                        ? Text('±${p.gpsAccuracyMeters!.toStringAsFixed(1)} m')
                        : null,
                    onTap: () => _openEntryScreen(existing: p),
                  );
                },
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