import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/measurement_point.dart';
import '../models/measurement_type.dart';
import '../services/screenshot_service.dart';
import 'measurement_entry_screen.dart';

/// A felmérés pontjait jeleníti meg térképen (OpenStreetMap csempék), a
/// mért érték szerint színezve, és a bejárt útvonalat (időrendi sorrend)
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final points =
        await DatabaseHelper.instance.getMeasurementPoints(widget.surveySessionId);
    if (!mounted) return;
    setState(() {
      _points = points;
      _loading = false;
    });
  }

  /// Típusonként normalizálja az értékeket (min→zöld, max→piros), hogy a
  /// térképen relatíve lássuk, hol volt magasabb/alacsonyabb a kibocsátás.
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
      byType.putIfAbsent(p.type, () => []).add(p);
    }
    return byType;
  }

  Widget _buildLegend() {
    final groups = _colorGroups();
    if (groups.isEmpty) return const SizedBox.shrink();
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
                    '${double.parse(p.value!.toStringAsFixed(4))}', p.unit)),
              if (p.distanceFromSourceMeters != null)
                Text(loc.distanceFromSourceValue(
                    '${double.parse(p.distanceFromSourceMeters!.toStringAsFixed(2))}')),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final loc = AppLocalizations.of(context)!;
    final colors = _computeColors();
    final routePoints = _points.map((p) => ll.LatLng(p.latitude, p.longitude)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.mapTitle),
        actions: [
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
      body: _points.isEmpty
          ? Center(child: Text(loc.noPointsRecordedYet))
          : RepaintBoundary(
              key: _mapBoundaryKey,
              child: Stack(children: [
                FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center(),
                  initialZoom: 16,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.rundhall.rad_recon',
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
                  MarkerLayer(
                    markers: _points.map((p) {
                      final color = p.isSample
                          ? Colors.blueGrey
                          : (colors[p.id!] ?? Colors.blue);
                      return Marker(
                        point: ll.LatLng(p.latitude, p.longitude),
                        width: 36,
                        height: 36,
                        child: GestureDetector(
                          onTap: () => _showPointDetails(p),
                          child: Icon(
                            p.isSourcePosition
                                ? Icons.warning_amber
                                : (p.isSample ? Icons.science : Icons.location_on),
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
              ]),
            ),
    );
  }
}