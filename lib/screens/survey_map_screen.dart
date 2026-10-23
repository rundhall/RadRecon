import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/map_area.dart';
import '../models/map_measure_line.dart';
import '../models/measurement_point.dart';
import '../models/measurement_type.dart';
import '../models/nuclide_id.dart';
import '../services/dose_unit_converter.dart';
import '../services/display_units.dart';
import '../services/unit_format.dart';
import '../services/screenshot_service.dart';
import 'map_area_dialog.dart';
import 'measurement_entry_screen.dart';

/// A pont térképi kategóriája: a mintavétel a `isSample` jelzőből, minden más
/// a típusából adódik. Csak a `doseRate` kap színskálát, a többi egyszínű ikon.
MeasurementType mapKindOf({required bool isSample, required MeasurementType type}) =>
    isSample ? MeasurementType.sample : type;

/// A felmérés pontjait jeleníti meg térképen (OpenStreetMap csempék), a
/// dózisteljesítmény szerint színezve (a többi mérés egyszínű ikonnal), és
/// a bejárt útvonalat (időrendi sorrend)
/// egy vonallal összekötve.
class SurveyMapScreen extends StatefulWidget {
  final int surveySessionId;

  const SurveyMapScreen({super.key, required this.surveySessionId});

  @override
  State<SurveyMapScreen> createState() => _SurveyMapScreenState();
}

class _SurveyMapScreenState extends State<SurveyMapScreen> {
  final _mapController = MapController();
  final _dateFormat = DateFormat('MM.dd HH:mm');
  final _mapBoundaryKey = GlobalKey();

  List<MeasurementPoint> _points = [];
  bool _loading = true;
  bool _isCapturing = false;
  List<MapArea> _areas = [];
  _DrawState? _draw; // folyamatban lévő területrajzolás
  bool _measuring = false; // távolságmérő mód
  List<MapMeasureLine> _lines = []; // a felmérés mérővonalai (adatbázisból)
  ll.LatLng? _pending; // az aktuális vonal kezdőpontja
  int? _selectedLine; // kijelölt vonal indexe
  int _measureColor = mapAreaPalette.first; // új vonalak színe

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final points =
        await DatabaseHelper.instance.getMeasurementPoints(widget.surveySessionId);
    final areas =
        await DatabaseHelper.instance.getMapAreas(widget.surveySessionId);
    final lines = await DatabaseHelper.instance
        .getMapMeasureLines(widget.surveySessionId);
    if (!mounted) return;
    setState(() {
      _points = points.map(withCurrentDoseUnit).toList();
      _areas = areas;
      _lines = lines;
      _loading = false;
    });
  }

  /// A nem dózisteljesítmény mérések egyszínű ikonjai (ikon, szín).
  static const _kindStyle = <MeasurementType, (IconData, Color)>{
    MeasurementType.surfaceContamination: (Icons.texture, Colors.purple),
    MeasurementType.cps: (Icons.flash_on, Colors.orange),
    MeasurementType.neutronCps: (Icons.blur_circular, Colors.teal),
    MeasurementType.sample: (Icons.science, Colors.blueGrey),
    MeasurementType.meteorology: (Icons.thermostat, Colors.indigo),
    MeasurementType.gasMeasurement: (Icons.air, Colors.brown),
  };

  MeasurementType _kindOf(MeasurementPoint p) =>
      mapKindOf(isSample: p.isSample, type: p.type);

  /// A dózisteljesítményen kívüli kategóriák, amelyek a térképen előfordulnak.
  List<MeasurementType> _otherKinds() {
    final kinds = <MeasurementType>{};
    for (final p in _points) {
      final k = _kindOf(p);
      if (k != MeasurementType.doseRate) kinds.add(k);
    }
    return kinds.toList();
  }

  /// Dózisteljesítmény-skála: típusonként (csak dózis) normalizál, min→zöld,
  /// max→piros.
  Map<int, Color> _computeColors() {
    final byType = _colorGroups();

    final colors = <int, Color>{};
    for (final entry in byType.entries) {
      final values = entry.value.map((p) => p.value!).toList();
      final min = values.reduce((a, b) => a < b ? a : b);
      final max = values.reduce((a, b) => a > b ? a : b);
      for (final p in entry.value) {
        final t = (max == min) ? 0.5 : (p.value! - min) / (max - min);
        colors[p.id!] = Color.lerp(Colors.green, Colors.red, t)!;
      }
    }
    return colors;
  }

  Map<MeasurementType, List<MeasurementPoint>> _colorGroups() {
    final byType = <MeasurementType, List<MeasurementPoint>>{};
    for (final p in _points) {
      if (p.value == null || p.isSample) continue;
      if (p.type != MeasurementType.doseRate) continue;
      byType.putIfAbsent(p.type, () => []).add(p);
    }
    return byType;
  }

  Widget _buildLegend() {
    final groups = _colorGroups();
    final others = _otherKinds();
    if (groups.isEmpty && others.isEmpty) return const SizedBox.shrink();
    String fmt(double v) => '${double.parse(v.toStringAsFixed(4))}';
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in groups.entries)
            Builder(builder: (context) {
              final values = e.value.map((p) => p.value!).toList();
              final min = values.reduce((a, b) => a < b ? a : b);
              final max = values.reduce((a, b) => a > b ? a : b);
              final unit = e.value.first.unit;
              const style = TextStyle(fontSize: 11, color: Colors.black87);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${e.key.label(context)} ($unit)',
                        style: style.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Container(
                      width: 160,
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: const LinearGradient(
                            colors: [Colors.green, Colors.red]),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(fmt(min), style: style),
                          Text(fmt(max), style: style),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          for (final kind in others)
            Builder(builder: (context) {
              final st = _kindStyle[kind];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(st?.$1 ?? Icons.location_on,
                        color: st?.$2 ?? Colors.blue, size: 16),
                    const SizedBox(width: 6),
                    Text(kind.label(context),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black87)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  ll.LatLng _center() {
    if (_points.isEmpty) return const ll.LatLng(47.4979, 19.0402); // Budapest
    final avgLat = _points.map((p) => p.latitude).reduce((a, b) => a + b) / _points.length;
    final avgLon = _points.map((p) => p.longitude).reduce((a, b) => a + b) / _points.length;
    return ll.LatLng(avgLat, avgLon);
  }

  void _showPointDetails(MeasurementPoint p) {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.locationLabel ?? '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(p.type.label(context)),
              if (p.value != null)
                Text(loc.valueLabel(
                    '${double.parse(displayValueOf(p).value!.toStringAsFixed(4))}', displayValueOf(p).unit)),
              if (p.distanceFromSourceMeters != null)
                Text('${loc.distanceFromSourceShortLabel}: '
                    '${formatDistanceMeters(p.distanceFromSourceMeters!)}'),
              if (p.nuclideStatus != NuclideIdStatus.notSpecified)
                Text('${loc.nuclideIdSectionTitle}: ${nuclideSummaryText(
                  status: p.nuclideStatus,
                  nuclides: p.nuclides,
                  statusLabel: (s) => s.label(loc),
                )}'),
              Text(loc.timestampLabel(_dateFormat.format(p.timestamp))),
              if (p.isSourcePosition)
                Text(loc.sourcePositionLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: Text(loc.editButton),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MeasurementEntryScreen(
                          surveySessionId: widget.surveySessionId,
                          existingPoint: p,
                        ),
                      ),
                    ).then((saved) {
                      if (saved == true) _load();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _captureScreenshot() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _isCapturing = true);
    try {
      await ScreenshotService.capture(
        boundaryKey: _mapBoundaryKey,
        surveySessionId: widget.surveySessionId,
        label: 'terkep',
        l10n: loc,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.screenshotSavedMessage),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.screenshotErrorMessage('$e'))));
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  // ---------------------------------------------------------------------
  // Területjelölés
  // ---------------------------------------------------------------------

  // ---------------------------------------------------------------------
  void _startMeasure() => setState(() => _measuring = true);

  /// Kilépéskor a vonalak a térképen maradnak (az adatbázisban is).
  void _stopMeasure() => setState(() {
        _measuring = false;
        _pending = null;
        _selectedLine = null;
      });

  /// Az első koppintás a vonal kezdőpontja, a második a végpontja. A kész
  /// vonal azonnal az adatbázisba kerül.
  Future<void> _onMeasureTap(ll.LatLng p) async {
    final start = _pending;
    if (start == null) {
      setState(() {
        _selectedLine = null;
        _pending = p;
      });
      return;
    }
    final line = MapMeasureLine(
      surveySessionId: widget.surveySessionId,
      colorArgb: _measureColor,
      a: start,
      b: p,
    );
    final id = await DatabaseHelper.instance.insertMapMeasureLine(line);
    if (!mounted) return;
    setState(() {
      _pending = null;
      _selectedLine = null;
      _lines.add(line.copyWith(id: id));
    });
  }

  bool get _canUndo => _pending != null || _lines.isNotEmpty;

  /// Folyamatban lévő kezdőpont, vagy az utolsó kész vonal visszavonása.
  Future<void> _undoMeasure() async {
    if (_pending != null) {
      setState(() => _pending = null);
      return;
    }
    if (_lines.isEmpty) return;
    final last = _lines.last;
    setState(() {
      _lines.removeLast();
      _selectedLine = null;
    });
    await DatabaseHelper.instance.deleteMapMeasureLine(last.id!);
  }

  Future<void> _clearAll() async {
    setState(() {
      _lines = [];
      _pending = null;
      _selectedLine = null;
    });
    await DatabaseHelper.instance
        .deleteAllMapMeasureLines(widget.surveySessionId);
  }

  Future<void> _deleteSelected() async {
    final i = _selectedLine;
    if (i == null) return;
    final line = _lines[i];
    setState(() {
      _lines.removeAt(i);
      _selectedLine = null;
    });
    await DatabaseHelper.instance.deleteMapMeasureLine(line.id!);
  }

  void _selectLine(int i) => setState(() {
        _selectedLine = _selectedLine == i ? null : i;
      });

  /// A paletta színe az új vonalakra; a kijelölt vonalra azonnal, és az
  /// adatbázisban is átíródik.
  Future<void> _setColor(int c) async {
    setState(() => _measureColor = c);
    final i = _selectedLine;
    if (i == null) return;
    final line = _lines[i];
    setState(() => _lines[i] = line.copyWith(colorArgb: c));
    await DatabaseHelper.instance.updateMapMeasureLineColor(line.id!, c);
  }

  Marker _endpointMarker(ll.LatLng p, Color color) => Marker(
        point: p,
        width: 16,
        height: 16,
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
            ),
          ),
        ),
      );

  /// Az elkészült vonalak, a folyamatban lévő kezdőpont és a távolság-feliratok.
  List<Widget> _measureLayers() {
    final pending = _pending;
    return [
      if (_lines.isNotEmpty)
        PolylineLayer(polylines: [
          for (var i = 0; i < _lines.length; i++)
            Polyline(
              points: [_lines[i].a, _lines[i].b],
              strokeWidth: i == _selectedLine ? 6 : 3,
              color: Color(_lines[i].colorArgb),
            ),
        ]),
      MarkerLayer(markers: [
        for (var i = 0; i < _lines.length; i++) ...[
          _endpointMarker(_lines[i].a, Color(_lines[i].colorArgb)),
          _endpointMarker(_lines[i].b, Color(_lines[i].colorArgb)),
          Marker(
            point: _lines[i].midpoint,
            width: 160,
            height: 26,
            child: IgnorePointer(
              ignoring: !_measuring,
              child: GestureDetector(
                onTap: () => _selectLine(i),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(_lines[i].colorArgb).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.white,
                        width: i == _selectedLine ? 2 : 0,
                      ),
                    ),
                    child: Text(
                      formatDistanceMeters(_lines[i].meters),
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        if (pending != null) _endpointMarker(pending, Color(_measureColor)),
      ]),
    ];
  }

  Widget _buildMeasureBar(AppLocalizations loc) {
    final i = _selectedLine;
    final selected = i == null ? null : _lines[i];
    final nothingToClear = _lines.isEmpty && _pending == null;
    return Material(
      elevation: 4,
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selected == null
                  ? loc.mapMeasureHint
                  : formatDistanceMeters(selected.meters),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: selected == null ? 12 : 18,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final c in mapAreaPalette)
                  GestureDetector(
                    onTap: () => _setColor(c),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c == (selected?.colorArgb ?? _measureColor)
                              ? Colors.black
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  onPressed: _canUndo ? _undoMeasure : null,
                  child: Text(loc.mapAreaUndo),
                ),
                if (selected == null)
                  TextButton(
                    onPressed: nothingToClear ? null : _clearAll,
                    child: Text(loc.mapMeasureClear),
                  )
                else
                  TextButton(
                    onPressed: _deleteSelected,
                    child: Text(loc.mapMeasureDeleteSelected),
                  ),
                FilledButton(
                  onPressed: _stopMeasure,
                  child: Text(loc.mapAreaDone),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startAreaDraw() async {
    final draft = await showMapAreaDraftDialog(context);
    if (draft == null || !mounted) return;
    setState(() => _draw = _DrawState(draft));
  }

  void _onMapTap(ll.LatLng p) {
    if (_measuring) {
      _onMeasureTap(p);
      return;
    }
    final d = _draw;
    if (d == null) return;
    setState(() {
      if (d.draft.shape == MapAreaShape.polygon) {
        d.vertices.add(p);
      } else if (d.center == null) {
        d.center = p;
      } else {
        d.edge = p; // a sugárpont újra koppintva áthelyezhető
      }
    });
  }

  void _undoDraw() {
    final d = _draw;
    if (d == null) return;
    setState(() {
      if (d.draft.shape == MapAreaShape.polygon) {
        if (d.vertices.isNotEmpty) d.vertices.removeLast();
      } else if (d.edge != null) {
        d.edge = null;
      } else {
        d.center = null;
      }
    });
  }

  void _cancelDraw() => setState(() => _draw = null);

  /// Sugár (méter) a középpont és a sugárpont között, ha mindkettő megvan.
  double? _previewRadius(_DrawState d) {
    final c = d.center;
    final e = d.edge;
    if (c == null || e == null) return null;
    return ll.Distance().as(ll.LengthUnit.Meter, c, e);
  }

  List<ll.LatLng> _outline(_DrawState d) {
    if (d.draft.shape != MapAreaShape.polygon) return const [];
    final v = d.vertices;
    return [...v, if (v.length >= 3) v.first];
  }

  List<ll.LatLng> _handlePoints(_DrawState d) {
    if (d.draft.shape == MapAreaShape.polygon) return d.vertices;
    return [
      if (d.center != null) d.center!,
      if (d.edge != null) d.edge!,
    ];
  }

  Future<void> _finishDraw() async {
    final loc = AppLocalizations.of(context)!;
    final d = _draw;
    if (d == null) return;
    final MapArea area;
    if (d.draft.shape == MapAreaShape.polygon) {
      if (d.vertices.length < 3) {
        _snack(loc.mapAreaMinPointsError);
        return;
      }
      area = MapArea(
        surveySessionId: widget.surveySessionId,
        name: d.draft.name,
        colorArgb: d.draft.colorArgb,
        shape: MapAreaShape.polygon,
        polygon: [for (final v in d.vertices) [v.latitude, v.longitude]],
      );
    } else {
      final c = d.center;
      final radius = _previewRadius(d);
      if (c == null || radius == null || radius < 1) {
        _snack(loc.mapAreaCircleIncomplete);
        return;
      }
      area = MapArea(
        surveySessionId: widget.surveySessionId,
        name: d.draft.name,
        colorArgb: d.draft.colorArgb,
        shape: MapAreaShape.circle,
        center: [c.latitude, c.longitude],
        radiusMeters: radius,
      );
    }
    await DatabaseHelper.instance.insertMapArea(area);
    if (!mounted) return;
    setState(() => _draw = null);
    await _load();
  }

  Future<bool> _confirmDeleteArea() async {
    final loc = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(loc.mapAreaDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.mapAreaDeleteTooltip),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _showAreaList() {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.mapAreaListTooltip,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_areas.isEmpty) Text(loc.mapAreaNoAreas),
              for (final a in _areas)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Color(a.colorArgb),
                    radius: 10,
                  ),
                  title: Text(a.name),
                  subtitle: Text(a.shape == MapAreaShape.polygon
                      ? loc.mapAreaPolygon
                      : loc.mapAreaCircle),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: loc.mapAreaDeleteTooltip,
                    onPressed: () async {
                      if (!await _confirmDeleteArea()) return;
                      await DatabaseHelper.instance.deleteMapArea(a.id!);
                      await _load();
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// A terület címkéjének helye: körnél a középpont, poligonnál a csúcsok átlaga.
  ll.LatLng? _areaAnchor(MapArea a) {
    if (a.shape == MapAreaShape.circle) {
      final c = a.center;
      return c == null ? null : ll.LatLng(c[0], c[1]);
    }
    if (a.polygon.isEmpty) return null;
    final n = a.polygon.length;
    final lat = a.polygon.fold<double>(0, (s, v) => s + v[0]) / n;
    final lng = a.polygon.fold<double>(0, (s, v) => s + v[1]) / n;
    return ll.LatLng(lat, lng);
  }

  Widget _buildDrawBar(AppLocalizations loc, _DrawState d) {
    final isPolygon = d.draft.shape == MapAreaShape.polygon;
    return Material(
      elevation: 4,
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(d.draft.colorArgb),
                  radius: 8,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    d.draft.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isPolygon ? loc.mapAreaHintPolygon : loc.mapAreaHintCircle,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton(onPressed: _undoDraw, child: Text(loc.mapAreaUndo)),
                TextButton(onPressed: _cancelDraw, child: Text(loc.cancelButton)),
                FilledButton(onPressed: _finishDraw, child: Text(loc.mapAreaDone)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final loc = AppLocalizations.of(context)!;
    final colors = _computeColors();
    final routePoints = _points.map((p) => ll.LatLng(p.latitude, p.longitude)).toList();
    final d = _draw;
    final previewColor = d == null ? Colors.blue : Color(d.draft.colorArgb);
    final previewRadius = d == null ? null : _previewRadius(d);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.mapTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: loc.mapAreaButtonTooltip,
            onPressed: _draw == null && !_measuring ? _startAreaDraw : null,
          ),
          IconButton(
            icon: const Icon(Icons.straighten),
            tooltip: loc.mapMeasureTooltip,
            color: _measuring ? Theme.of(context).colorScheme.primary : null,
            onPressed: _draw != null
                ? null
                : (_measuring ? _stopMeasure : _startMeasure),
          ),
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            tooltip: loc.mapAreaListTooltip,
            onPressed: _showAreaList,
          ),
          if (_points.isNotEmpty)
            IconButton(
              icon: _isCapturing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt_outlined),
              tooltip: loc.saveScreenshotTooltip,
              onPressed: _isCapturing ? null : _captureScreenshot,
            ),
        ],
      ),
      body: RepaintBoundary(
        key: _mapBoundaryKey,
        child: Stack(children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center(),
              initialZoom: 16,
              onTap: (_, p) => _onMapTap(p),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rundhall.rad_recon',
              ),
              // Területek: áttetsző kitöltés, teljes színű körvonal.
              PolygonLayer(
                polygons: [
                  for (final a in _areas)
                    if (a.shape == MapAreaShape.polygon && a.polygon.length >= 3)
                      Polygon(
                        points: [for (final v in a.polygon) ll.LatLng(v[0], v[1])],
                        color: Color(a.colorArgb).withValues(alpha: 0.3),
                        borderColor: Color(a.colorArgb),
                        borderStrokeWidth: 2,
                      ),
                ],
              ),
              CircleLayer(
                circles: [
                  for (final a in _areas)
                    if (a.shape == MapAreaShape.circle && a.center != null)
                      CircleMarker(
                        point: ll.LatLng(a.center![0], a.center![1]),
                        radius: a.radiusMeters ?? 0,
                        useRadiusInMeter: true,
                        color: Color(a.colorArgb).withValues(alpha: 0.3),
                        borderColor: Color(a.colorArgb),
                        borderStrokeWidth: 2,
                      ),
                ],
              ),
              Align(
                alignment: Alignment.topRight,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    color: Colors.white.withValues(alpha: 0.75),
                    child: const Text(
                      '© OpenStreetMap contributors',
                      style: TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ),
                ),
              ),
              if (routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 3,
                      color: Colors.blueAccent.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              // Folyamatban lévő rajzolás előnézete.
              if (d != null) ...[
                PolylineLayer(
                  polylines: [
                    if (_outline(d).length > 1)
                      Polyline(
                        points: _outline(d),
                        strokeWidth: 2,
                        color: previewColor,
                      ),
                  ],
                ),
                CircleLayer(
                  circles: [
                    if (d.center != null && previewRadius != null)
                      CircleMarker(
                        point: d.center!,
                        radius: previewRadius,
                        useRadiusInMeter: true,
                        color: previewColor.withValues(alpha: 0.3),
                        borderColor: previewColor,
                        borderStrokeWidth: 2,
                      ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    for (final h in _handlePoints(d))
                      Marker(
                        point: h,
                        width: 16,
                        height: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: previewColor, width: 3),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              // Területek nevei a közepükön.
              MarkerLayer(
                markers: [
                  for (final a in _areas)
                    if (_areaAnchor(a) case final anchor?)
                      Marker(
                        point: anchor,
                        width: 200,
                        height: 26,
                        child: IgnorePointer(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(a.colorArgb).withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                a.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
              ..._measureLayers(),
              MarkerLayer(
                markers: _points.map((p) {
                  final kind = _kindOf(p);
                  final isDose = kind == MeasurementType.doseRate;
                  final style = _kindStyle[kind];
                  final color = isDose
                      ? (colors[p.id!] ?? Colors.blue)
                      : (style?.$2 ?? Colors.blue);
                  return Marker(
                    point: ll.LatLng(p.latitude, p.longitude),
                    width: 36,
                    height: 36,
                    child: GestureDetector(
                      // Rajzolás közben a pont nem nyit részletet, a koppintás a csúcs.
                      onTap: d == null && !_measuring ? () => _showPointDetails(p) : null,
                      child: Icon(
                        p.isSourcePosition
                            ? Icons.warning_amber
                            : (isDose
                                ? Icons.location_on
                                : (style?.$1 ?? Icons.location_on)),
                        color: color,
                        size: 34,
                        shadows: const [Shadow(color: Colors.black45, blurRadius: 3)],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned(right: 8, bottom: 8, child: _buildLegend()),
          if (d != null)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: _buildDrawBar(loc, d),
            ),
          if (_measuring)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: _buildMeasureBar(loc),
            ),
          if (_points.isEmpty && d == null)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(loc.noPointsRecordedYet),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

/// Folyamatban lévő területrajzolás állapota.
class _DrawState {
  _DrawState(this.draft);

  final MapAreaDraft draft;
  final List<ll.LatLng> vertices = []; // poligon csúcsai
  ll.LatLng? center; // kör középpontja
  ll.LatLng? edge; // kör sugárpontja
}
