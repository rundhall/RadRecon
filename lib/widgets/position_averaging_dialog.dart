import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../l10n/app_localizations.dart';
import '../services/position_averager.dart';

/// Álló helyzetben végzett GPS-átlagolás: a megadott ideig gyűjti a pozíciókat,
/// majd pontosság-súlyozott, kiugró-szűrt átlagot ad vissza.
Future<AveragedPosition?> showPositionAveragingDialog(BuildContext context) {
  return showDialog<AveragedPosition>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _PositionAveragingDialog(),
  );
}

class _PositionAveragingDialog extends StatefulWidget {
  const _PositionAveragingDialog();

  @override
  State<_PositionAveragingDialog> createState() =>
      _PositionAveragingDialogState();
}

class _PositionAveragingDialogState extends State<_PositionAveragingDialog> {
  int _seconds = 60;
  bool _running = false;
  int _elapsed = 0;
  final List<GpsSample> _samples = [];
  double? _lastAccuracy;
  AveragedPosition? _current;
  StreamSubscription<Position>? _sub;
  Timer? _timer;

  void _start() {
    setState(() => _running = true);
    _sub = Geolocator.getPositionStream(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.best),
    ).listen((p) {
      _samples.add(GpsSample(p.latitude, p.longitude, p.accuracy));
      _lastAccuracy = p.accuracy;
      _current = averagePositions(_samples);
      if (mounted) setState(() {});
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed++;
      if (_elapsed >= _seconds) {
        _finish();
      } else if (mounted) {
        setState(() {});
      }
    });
  }

  void _finish() {
    _stopAll();
    Navigator.of(context).pop(_current);
  }

  void _stopAll() {
    _timer?.cancel();
    _timer = null;
    _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    _stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.gpsAverageTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_running) ...[
            Text(loc.gpsAverageHint),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 30, label: Text('30 s')),
                ButtonSegment(value: 60, label: Text('60 s')),
                ButtonSegment(value: 120, label: Text('120 s')),
              ],
              selected: {_seconds},
              onSelectionChanged: (s) => setState(() => _seconds = s.first),
            ),
          ] else ...[
            LinearProgressIndicator(value: _elapsed / _seconds),
            const SizedBox(height: 12),
            Text('${loc.gpsAverageSamples}: ${_samples.length} '
                '($_elapsed / $_seconds s)'),
            if (_lastAccuracy != null)
              Text('${loc.gpsAverageCurrent}: ±${_lastAccuracy!.toStringAsFixed(1)} m'),
            if (_current != null)
              Text('${loc.gpsAverageResult}: ±${_current!.accuracyMeters.toStringAsFixed(1)} m'),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _stopAll();
            Navigator.of(context).pop();
          },
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        if (!_running)
          FilledButton(onPressed: _start, child: Text(loc.gpsAverageStart))
        else
          FilledButton(
            onPressed: _current == null ? null : _finish,
            child: Text(loc.gpsAverageUse),
          ),
      ],
    );
  }
}
