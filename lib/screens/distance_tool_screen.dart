import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/measurement_point.dart';

const _cardinalLabelsHu = [
  'É', 'ÉÉK', 'ÉK', 'KÉK', 'K', 'KDK', 'DK', 'DDK',
  'D', 'DDNy', 'DNy', 'NyDNy', 'Ny', 'NyÉNy', 'ÉNy', 'ÉÉNy',
];
const _cardinalLabelsEn = [
  'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
  'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
];

/// Nyelvfüggő iránytű-rövidítések — az app nyelvétől (nem a rendszer-
/// nyelvtől) függ, mert a `Localizations.localeOf` a feloldott, aktív
/// locale-t adja vissza.
List<String> _cardinalLabelsFor(BuildContext context) {
  return Localizations.localeOf(context).languageCode == 'en'
      ? _cardinalLabelsEn
      : _cardinalLabelsHu;
}

/// Távolság- és irányméréshez két felmérési pont között, vagy a jelenlegi
/// GPS-pozíció és egy kiválasztott pont között.
///
/// "Élő követés" módban a GPS-t folyamatosan figyeli, és minden mozdulatra
/// újraszámolja a távolságot és az irányt a célponthoz — így könnyen vissza
/// lehet találni egy ponthoz, adott irányban fix távolságot megtenni, vagy
/// egymás után több pont felé navigálva szabályos formációt (pl. négyzetet)
/// bejárni.
class DistanceToolScreen extends StatefulWidget {
  final int surveySessionId;

  const DistanceToolScreen({super.key, required this.surveySessionId});

  @override
  State<DistanceToolScreen> createState() => _DistanceToolScreenState();
}

class _DistanceToolScreenState extends State<DistanceToolScreen> {
  List<MeasurementPoint> _points = [];
  MeasurementPoint? _from;
  MeasurementPoint? _to;

  bool _useCurrentPositionAsFrom = true;
  Position? _currentPosition;
  bool _isFetchingGps = false;

  bool _liveMode = false;
  StreamSubscription<Position>? _positionSub;

  double? _distanceMeters;
  double? _bearingDegrees;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _loadPoints() async {
    final points =
        await DatabaseHelper.instance.getMeasurementPoints(widget.surveySessionId);
    if (!mounted) return;
    setState(() => _points = points);
    if (_useCurrentPositionAsFrom) await _fetchCurrentPosition();
  }

  Future<bool> _ensureLocationPermission() async {
    final loc = AppLocalizations.of(context)!;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _errorText = loc.locationServiceDisabledError);
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _errorText = loc.locationPermissionDeniedError);
      return false;
    }
    return true;
  }

  Future<void> _fetchCurrentPosition() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _isFetchingGps = true);
    try {
      if (!await _ensureLocationPermission()) return;
      final position =
          await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      setState(() {
        _currentPosition = position;
        _errorText = null;
      });
      _recalculate();
    } catch (e) {
      setState(() => _errorText = loc.gpsErrorMessage('$e'));
    } finally {
      if (mounted) setState(() => _isFetchingGps = false);
    }
  }

  Future<void> _toggleLiveMode(bool value) async {
    if (value) {
      if (_to == null) {
        setState(
          () => _errorText = AppLocalizations.of(context)!.selectTargetFirstError,
        );
        return;
      }
      if (!_useCurrentPositionAsFrom) {
        // Élő követésnek csak a saját, mozgó pozícióval van értelme.
        setState(() => _useCurrentPositionAsFrom = true);
      }
      if (!await _ensureLocationPermission()) return;

      setState(() {
        _liveMode = true;
        _errorText = null;
      });
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      ).listen((position) {
        _currentPosition = position;
        _recalculate();
      });
    } else {
      await _positionSub?.cancel();
      _positionSub = null;
      setState(() => _liveMode = false);
    }
  }

  void _calculate() {
    final loc = AppLocalizations.of(context)!;
    setState(() => _errorText = null);

    if (_useCurrentPositionAsFrom && _currentPosition == null) {
      setState(() => _errorText = loc.noGpsPositionError);
      return;
    }
    if (!_useCurrentPositionAsFrom && _from == null) {
      setState(() => _errorText = loc.selectStartPointError);
      return;
    }
    if (_to == null) {
      setState(() => _errorText = loc.selectTargetPointError);
      return;
    }
    _recalculate();
  }

  /// Újraszámolja a távolságot és az irányt a jelenlegi From/To
  /// kiválasztás alapján. Élő módban ezt minden GPS-frissítés meghívja.
  void _recalculate() {
    if (_to == null) return;

    double lat1, lon1;
    if (_useCurrentPositionAsFrom) {
      if (_currentPosition == null) return;
      lat1 = _currentPosition!.latitude;
      lon1 = _currentPosition!.longitude;
    } else {
      if (_from == null) return;
      lat1 = _from!.latitude;
      lon1 = _from!.longitude;
    }

    final distance =
        Geolocator.distanceBetween(lat1, lon1, _to!.latitude, _to!.longitude);
    var bearing =
        Geolocator.bearingBetween(lat1, lon1, _to!.latitude, _to!.longitude);
    if (bearing < 0) bearing += 360;

    if (!mounted) return;
    setState(() {
      _distanceMeters = distance;
      _bearingDegrees = bearing;
    });
  }

  String _cardinal(BuildContext context, double bearing) {
    final index = ((bearing / 22.5) + 0.5).floor() % 16;
    return _cardinalLabelsFor(context)[index];
  }

  String _pointLabel(MeasurementPoint p) =>
      p.locationLabel ?? '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.distanceToolTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(loc.startFromCurrentPositionLabel),
            subtitle: _useCurrentPositionAsFrom
                ? Text(
                    _currentPosition == null
                        ? loc.noPositionFetchedYet
                        : '${_currentPosition!.latitude.toStringAsFixed(6)}, '
                            '${_currentPosition!.longitude.toStringAsFixed(6)}',
                  )
                : null,
            value: _useCurrentPositionAsFrom,
            onChanged: _liveMode
                ? null
                : (v) {
                    setState(() => _useCurrentPositionAsFrom = v);
                    if (v) _fetchCurrentPosition();
                  },
          ),
          if (_useCurrentPositionAsFrom)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: (_isFetchingGps || _liveMode) ? null : _fetchCurrentPosition,
                icon: _isFetchingGps
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(loc.refreshGpsButton),
              ),
            )
          else
            DropdownButtonFormField<MeasurementPoint>(
              initialValue: _from,
              decoration: InputDecoration(labelText: loc.startPointLabel),
              items: _points
                  .map((p) => DropdownMenuItem(value: p, child: Text(_pointLabel(p))))
                  .toList(),
              onChanged: (p) => setState(() => _from = p),
            ),
          const SizedBox(height: 16),
          DropdownButtonFormField<MeasurementPoint>(
            initialValue: _to,
            decoration: InputDecoration(labelText: loc.targetPointLabel),
            items: _points
                .map((p) => DropdownMenuItem(value: p, child: Text(_pointLabel(p))))
                .toList(),
            onChanged: _liveMode
                ? null
                : (p) {
                    setState(() => _to = p);
                    _recalculate();
                  },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(loc.liveTrackingLabel),
            subtitle: Text(loc.liveTrackingSubtitle),
            value: _liveMode,
            onChanged: (v) => _toggleLiveMode(v),
          ),
          if (!_liveMode) ...[
            const SizedBox(height: 8),
            FilledButton(onPressed: _calculate, child: Text(loc.calculateDistanceButton)),
          ],
          const SizedBox(height: 20),
          if (_errorText != null)
            Text(_errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          if (_distanceMeters != null && _bearingDegrees != null) ...[
            Center(
              child: Transform.rotate(
                angle: _bearingDegrees! * math.pi / 180.0,
                child: Icon(
                  Icons.navigation,
                  size: 88,
                  color: _liveMode ? Colors.deepOrange : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${_bearingDegrees!.toStringAsFixed(0)}° '
                '(${_cardinal(context, _bearingDegrees!)})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    _distanceMeters! >= 1000
                        ? '${(_distanceMeters! / 1000).toStringAsFixed(3)} km  '
                            '(${_distanceMeters!.toStringAsFixed(1)} m)'
                        : '${_distanceMeters!.toStringAsFixed(1)} m',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            if (_liveMode)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    loc.liveTrackingRunningHint,
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}