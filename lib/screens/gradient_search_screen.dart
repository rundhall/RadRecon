import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/measurement_point.dart';
import '../models/measurement_type.dart';
import '../services/gradient_search_service.dart';
import 'measurement_entry_screen.dart';

const _cardinalLabelsHu = [
  'É', 'ÉÉK', 'ÉK', 'KÉK', 'K', 'KDK', 'DK', 'DDK',
  'D', 'DDNy', 'DNy', 'NyDNy', 'Ny', 'NyÉNy', 'ÉNy', 'ÉÉNy',
];
const _cardinalLabelsEn = [
  'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
  'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
];

List<String> _cardinalLabelsFor(BuildContext context) {
  return Localizations.localeOf(context).languageCode == 'en'
      ? _cardinalLabelsEn
      : _cardinalLabelsHu;
}

/// Egyszerű, gradiens-becslésen alapuló forráskereső segéd.
///
/// A felmérésen belül eddig rögzített, azonos típusú mérési pontokból
/// megbecsüli, merre nő az érték, és ebbe az irányba javasolja a
/// továbbhaladást. Nem helyettesíti a szakmai megítélést.
class GradientSearchScreen extends StatefulWidget {
  final int surveySessionId;

  const GradientSearchScreen({super.key, required this.surveySessionId});

  @override
  State<GradientSearchScreen> createState() => _GradientSearchScreenState();
}

class _GradientSearchScreenState extends State<GradientSearchScreen> {
  MeasurementType _type = MeasurementType.doseRate;
  List<MeasurementPoint> _points = [];
  GradientSearchResult? _result;
  bool _loading = false;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _reload();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startLocationTracking());
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    final loc = AppLocalizations.of(context)!;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showLocationError(loc.locationServiceDisabledError);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showLocationError(loc.locationPermissionDeniedError);
        return;
      }

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      ).listen((_) => _recalculate());
    } catch (e) {
      _showLocationError(loc.gpsErrorMessage('$e'));
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final all = await DatabaseHelper.instance.getMeasurementPoints(
      widget.surveySessionId,
    );
    final filtered = all.where((p) => p.type == _type).toList();
    if (!mounted) return;
    setState(() {
      _points = filtered;
      _result = GradientSearchService.estimate(_points);
      _loading = false;
    });
  }

  void _recalculate() {
    if (!mounted) return;
    setState(() => _result = GradientSearchService.estimate(_points));
  }

  Future<void> _addMeasurement() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            MeasurementEntryScreen(surveySessionId: widget.surveySessionId),
      ),
    );
    if (saved == true) await _reload();
  }

  String _cardinal(BuildContext context, double bearing) {
    final index = ((bearing / 22.5) + 0.5).floor() % 16;
    return _cardinalLabelsFor(context)[index];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: Text(loc.sourceSearchTitle)),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<MeasurementType>(
              initialValue: _type,
              decoration: InputDecoration(labelText: loc.measurementTypeLabel),
              items: MeasurementType.values
                  .where((t) => t != MeasurementType.sample)
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t.label(context))))
                  .toList(),
              onChanged: (t) {
                if (t == null) return;
                setState(() => _type = t);
                _reload();
              },
            ),
            const SizedBox(height: 8),
            Text(
              loc.pointsRecordedForType(_points.length),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (!_loading && result != null && !result.success)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(result.errorMessage!),
                ),
              ),
            if (!_loading && result != null && result.success) ...[
              Center(
                child: Transform.rotate(
                  angle: result.bearingDegrees! * math.pi / 180.0,
                  child: const Icon(
                    Icons.navigation,
                    size: 96,
                    color: Colors.deepOrange,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '${result.bearingDegrees!.toStringAsFixed(0)}° '
                  '(${_cardinal(context, result.bearingDegrees!)})',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 4),
              Center(child: Text(loc.directionEstimateHint)),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.gradientEstimateLabel(
                          result.gradientMagnitudePerMeter!.toStringAsFixed(3),
                          _type.defaultUnit,
                        ),
                      ),
                      if (result.lowConfidence) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(loc.lowConfidenceWarning),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  loc.sourceSearchDisclaimer,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _addMeasurement,
              icon: const Icon(Icons.add_location_alt),
              label: Text(loc.newMeasurementButton),
            ),
          ],
        ),
      ),
    );
  }
}