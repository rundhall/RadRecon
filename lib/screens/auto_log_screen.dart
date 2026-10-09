import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/instrument.dart';
import '../models/measurement_point.dart';
import '../models/measurement_type.dart';
import '../models/person_dose.dart';
import '../services/dose_integrator.dart';
import '../services/modbus_reader_service.dart';
import '../services/settings_service.dart';
import '../widgets/dose_widgets.dart';

enum _TriggerMode { time, distance }

/// Automatikus mintavételezés: időközönként (pl. 1 mp) vagy megtett
/// távolságonként (pl. 5 m) magától rögzít egy mérési pontot a kiválasztott,
/// Modbus/TCP-n elérhető műszer aktuális értékéből és az aktuális GPS
/// pozícióból.
///
/// FONTOS KORLÁT: a rögzítés csak addig fut, amíg ez a képernyő nyitva /
/// előtérben van — háttérbe kerülve (kikapcsolt kijelző, másik app) a
/// Flutter időzítő és a helyzet-figyelő szüneteltethető az operációs
/// rendszer által, tehát a mérés is szünetel.
class AutoLogScreen extends StatefulWidget {
  final int surveySessionId;

  const AutoLogScreen({super.key, required this.surveySessionId});

  @override
  State<AutoLogScreen> createState() => _AutoLogScreenState();
}

class _AutoLogScreenState extends State<AutoLogScreen> {
  List<Instrument> _modbusInstruments = [];
  Instrument? _instrument;
  MeasurementType _type = MeasurementType.doseRate;
  _TriggerMode _mode = _TriggerMode.time;

  final _intervalCtrl = TextEditingController(text: '1');
  final _distanceCtrl = TextEditingController(text: '5');

  bool _isRunning = false;
  bool _starting = false;
  bool _busy = false; // egy tick fut-e éppen (átfedés elkerülése)

  ModbusLiveSession? _session;
  Timer? _timer;

  /// Távolság-módban telefon-GPS-szel a mérés csak megtett útra triggerel, a
  /// dózis integrálásához ettől függetlenül másodpercenként olvasunk.
  Timer? _doseTimer;
  final _dose = DoseIntegrator();
  StreamSubscription<Position>? _positionSub;
  Position? _currentPosition;
  (double, double)? _lastModbusGpsPosition;

  bool get _useModbusGps => _instrument?.isModbusGpsEnabled ?? false;
  int _capturedCount = 0;
  int _errorCount = 0;
  double? _lastValue;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _loadInstruments();
  }

  Future<void> _loadInstruments() async {
    final all = await DatabaseHelper.instance.getInstruments();
    if (!mounted) return;
    setState(() {
      _modbusInstruments = all.where((i) => i.isModbusConnected).toList();
      if (_modbusInstruments.isNotEmpty) {
        _instrument = _modbusInstruments.first;
      }
    });
  }

  Future<bool> _ensureLocationPermission() async {
    final loc = AppLocalizations.of(context)!;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError(loc.locationServiceDisabledError);
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showError(loc.locationPermissionDeniedError);
      return false;
    }
    return true;
  }

  Future<void> _start() async {
    final loc = AppLocalizations.of(context)!;
    final instrument = _instrument;
    if (instrument == null) return;

    final interval = int.tryParse(_intervalCtrl.text.trim()) ?? 1;
    final distance = int.tryParse(_distanceCtrl.text.trim()) ?? 5;
    if (_mode == _TriggerMode.time && interval < 1) {
      _showError(loc.intervalMinError);
      return;
    }
    if (_mode == _TriggerMode.distance && distance < 1) {
      _showError(loc.distanceMinError);
      return;
    }

    if (!_useModbusGps && !await _ensureLocationPermission()) return;

    setState(() => _starting = true);
    try {
      _session = await ModbusLiveSession.connect(instrument, loc);
    } catch (e) {
      _showError(loc.modbusConnectErrorMessage('$e'));
      if (mounted) setState(() => _starting = false);
      return;
    }

    unawaited(WakelockPlus.enable());
    setState(() {
      _isRunning = true;
      _starting = false;
      _capturedCount = 0;
      _errorCount = 0;
      _lastValue = null;
      _lastError = null;
      _lastModbusGpsPosition = null;
      _dose.reset();
    });

    if (_useModbusGps) {
      // Távolság módban 1 mp-es lekérdezés, a megtett utat a műszer GPS-éből számoljuk.
      final seconds = _mode == _TriggerMode.time ? interval : 1;
      _timer = Timer.periodic(
        Duration(seconds: seconds),
        (_) => _captureTick(null, minDistance: distance),
      );
      return;
    }

    if (_mode == _TriggerMode.time) {
      // Folyamatosan frissülő pozíció a legfrissebb koordinátákhoz —
      // nem várjuk meg minden tick-nél külön a GPS-t, mert az lassítaná
      // a másodperces gyakoriságot.
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      ).listen((position) => _currentPosition = position);

      _timer = Timer.periodic(
        Duration(seconds: interval),
        (_) => _captureTick(_currentPosition),
      );
    } else {
      _positionSub = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: distance,
        ),
      ).listen(_captureTick);
      _doseTimer = Timer.periodic(const Duration(seconds: 1), (_) => _doseTick());
    }
  }

  /// Dózisteljesítmény-minta hozzáadása az integrálóhoz (csak dózisteljesítmény
  /// típusú mérésnél).
  void _accumulateDose(double value) {
    if (_type != MeasurementType.doseRate) return;
    _dose.addSample(value, _type.defaultUnit, DateTime.now());
  }

  /// Csak dózis-integráláshoz szükséges olvasás (nem rögzít mérési pontot).
  Future<void> _doseTick() async {
    if (_busy || !_isRunning || _type != MeasurementType.doseRate) return;
    _busy = true;
    try {
      final result = await _session?.read();
      if (result != null && result.success) {
        _accumulateDose(result.value!);
        if (mounted) setState(() {});
      }
    } finally {
      _busy = false;
    }
  }

  /// A leállításkor összegzett dózist elmenti a felméréshez rendelt összes
  /// személynek (online dózisként, a korábbi indításokhoz hozzáadva). Az
  /// elmentett személyek számát adja vissza, -1-et ha nincs hozzárendelt
  /// személy; `null`, ha nem volt mit menteni.
  Future<(int?, double)> _persistDose() async {
    if (!_dose.hasData) {
      _dose.reset();
      return (null, 0.0);
    }
    final dose = _dose.doseMicroSv;
    _dose.reset();
    final persons = await DatabaseHelper.instance
        .getAttachedPersons(widget.surveySessionId);
    if (persons.isEmpty) return (-1, dose);
    for (final a in persons) {
      await DatabaseHelper.instance.setSessionDose(
        personId: a.person.id!,
        surveySessionId: widget.surveySessionId,
        source: DoseSource.online,
        doseMicroSv: dose,
        accumulate: true,
      );
    }
    return (persons.length, dose);
  }

  Future<void> _captureTick(Position? position, {int? minDistance}) async {
    if ((position == null && !_useModbusGps) || _busy || !_isRunning) return;
    _busy = true;
    try {
      final result = await _session!.read();
      if (!result.success) {
        _errorCount++;
        _lastError = result.errorMessage;
        if (mounted) setState(() {});
        return;
      }
      _accumulateDose(result.value!);

      final double latitude;
      final double longitude;
      final double? accuracy;
      if (_useModbusGps) {
        latitude = result.latitude!;
        longitude = result.longitude!;
        accuracy = null;
        if (_mode == _TriggerMode.distance) {
          final last = _lastModbusGpsPosition;
          if (last != null &&
              Geolocator.distanceBetween(
                    last.$1,
                    last.$2,
                    latitude,
                    longitude,
                  ) <
                  (minDistance ?? 5)) {
            return;
          }
          _lastModbusGpsPosition = (latitude, longitude);
        }
      } else {
        latitude = position!.latitude;
        longitude = position.longitude;
        accuracy = position.accuracy;
      }

      final now = DateTime.now();
      final point = MeasurementPoint(
        surveySessionId: widget.surveySessionId,
        latitude: latitude,
        longitude: longitude,
        gpsAccuracyMeters: accuracy,
        type: _type,
        value: result.value,
        unit: _type.defaultUnit,
        instrumentId: _instrument!.id,
        timestamp: now,
        createdAt: now,
        updatedAt: now,
      );
      await DatabaseHelper.instance.insertMeasurementPoint(point);

      final threshold = await SettingsService().getThreshold(_type);
      if (threshold != null && result.value! >= threshold) {
        HapticFeedback.heavyImpact();
      }

      _capturedCount++;
      _lastValue = result.value;
      if (mounted) setState(() {});
    } finally {
      _busy = false;
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _timer = null;
    _doseTimer?.cancel();
    _doseTimer = null;
    await _positionSub?.cancel();
    _positionSub = null;
    await _session?.close();
    _session = null;
    unawaited(WakelockPlus.disable());
    if (mounted) setState(() => _isRunning = false);

    final (count, dose) = await _persistDose();
    if (!mounted || count == null) return;
    final loc = AppLocalizations.of(context)!;
    _showError(count < 0
        ? loc.autoLogDoseNoPersons(formatDose(context, dose))
        : loc.autoLogDoseSaved(count, formatDose(context, dose)));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _doseTimer?.cancel();
    // Ha a képernyőt a felhasználó leállítás nélkül hagyja el, a már
    // összegzett dózis akkor sem veszhet el.
    if (_isRunning) unawaited(_persistDose());
    _positionSub?.cancel();
    _session?.close();
    unawaited(WakelockPlus.disable());
    _intervalCtrl.dispose();
    _distanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.autoLogMenuItem)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                loc.autoLogDisclaimer,
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_modbusInstruments.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(loc.noModbusInstrumentMessage),
              ),
            )
          else ...[
            DropdownButtonFormField<Instrument>(
              initialValue: _instrument,
              decoration: InputDecoration(labelText: loc.instrumentLabel),
              items: _modbusInstruments
                  .map((i) => DropdownMenuItem(value: i, child: Text(i.name)))
                  .toList(),
              onChanged: _isRunning
                  ? null
                  : (i) => setState(() => _instrument = i),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MeasurementType>(
              initialValue: _type,
              decoration: InputDecoration(labelText: loc.measurementTypeLabel),
              items: MeasurementType.values
                  .where((t) => t != MeasurementType.sample)
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t.label(context))))
                  .toList(),
              onChanged: _isRunning
                  ? null
                  : (t) {
                      if (t == null) return;
                      setState(() => _type = t);
                    },
            ),
            if (_type != MeasurementType.doseRate)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  loc.autoLogDoseOnlyDoseRate,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 16),
            SegmentedButton<_TriggerMode>(
              segments: [
                ButtonSegment(
                  value: _TriggerMode.time,
                  label: Text(loc.triggerModeTime),
                  icon: const Icon(Icons.timer_outlined),
                ),
                ButtonSegment(
                  value: _TriggerMode.distance,
                  label: Text(loc.triggerModeDistance),
                  icon: const Icon(Icons.straighten),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: _isRunning
                  ? null
                  : (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 12),
            if (_mode == _TriggerMode.time)
              TextField(
                controller: _intervalCtrl,
                enabled: !_isRunning,
                decoration: InputDecoration(
                  labelText: loc.intervalSecondsLabel,
                ),
                keyboardType: TextInputType.number,
              )
            else
              TextField(
                controller: _distanceCtrl,
                enabled: !_isRunning,
                decoration: InputDecoration(
                  labelText: loc.distanceIntervalLabel,
                ),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 24),
            if (!_isRunning)
              FilledButton.icon(
                onPressed: _starting || _instrument == null ? null : _start,
                icon: _starting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_starting ? loc.connectingLabel : loc.startButton),
              )
            else
              FilledButton.tonalIcon(
                onPressed: _stop,
                icon: const Icon(Icons.stop),
                label: Text(loc.stopButton),
              ),
            const SizedBox(height: 24),
            if (_isRunning || _capturedCount > 0 || _errorCount > 0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_isRunning)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          Text(
                            _isRunning ? loc.loggingRunningLabel : loc.loggingStoppedLabel,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(loc.capturedPointsLabel(_capturedCount)),
                      if (_dose.hasData)
                        Text(loc.autoLogDoseLabel(
                            formatDose(context, _dose.doseMicroSv))),
                      if (_dose.gapCount > 0)
                        Text(
                          loc.autoLogDoseGaps(_dose.gapCount),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                      if (_lastValue != null)
                        Text(loc.lastValueLabel(
                            '${double.parse(_lastValue!.toStringAsFixed(4))}',
                            _type.defaultUnit)),
                      if (_errorCount > 0)
                        Text(
                          loc.failedReadingsLabel(_errorCount) +
                              (_lastError != null
                                  ? loc.lastErrorSuffix(_lastError!)
                                  : ''),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}