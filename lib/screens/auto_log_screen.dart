import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../l10n/modbus_quantity_labels.dart';
import '../models/concentration_unit.dart';
import '../models/distance_unit.dart';
import '../models/gas_reading.dart';
import '../models/hardware_button.dart';
import '../models/instrument.dart';
import '../models/measurement_point.dart';
import '../models/measurement_type.dart';
import '../models/meteorology.dart';
import '../models/modbus_reading.dart';
import '../services/dose_integrator.dart';
import '../services/dose_unit_controller.dart';
import '../services/dose_unit_converter.dart';
import '../services/hardware_buttons.dart';
import '../services/modbus_reader_service.dart';
import '../services/number_input.dart';
import '../services/settings_service.dart';
import '../widgets/dose_widgets.dart';
import '../widgets/quantity_field.dart';
import '../widgets/time_series_chart.dart';

enum _TriggerMode { time, distance }

/// Egy kiválasztható csatorna: melyik műszer, melyik regiszter.
class _Source {
  _Source(this.instrument, this.channel);

  final Instrument instrument;
  final ModbusChannel channel;
  bool selected = false;
}

/// Egy csatorna, amelyhez futás közben nyitott kapcsolat tartozik.
class _ActiveSource {
  _ActiveSource(this.source, this.session);

  final _Source source;
  final ModbusLiveSession session;
}

bool _isRadiation(MeasurementType t) =>
    t == MeasurementType.doseRate ||
    t == MeasurementType.countRate ||
    t == MeasurementType.surfaceContamination;

_Source? _firstOf(List<_Source> list, bool Function(_Source) test) {
  for (final s in list) {
    if (test(s)) return s;
  }
  return null;
}

/// Automatikus mintavételezés: időközönként (pl. 1 mp) vagy megtett
/// távolságonként (pl. 5 m) magától rögzít pontokat. A kijelölt Modbus-
/// csatornákat egyszerre olvassa: több műszer több csatornája egyidejűleg
/// rögzíthető. A sugárzási értékek pontonként, a meteorológia és a gázok
/// tickenként egy-egy összevont pontban mentődnek, közös időponttal és
/// helyzettel. A GPS az első kijelölt, GPS-es műszertől, különben a telefontól jön.
///
/// FONTOS KORLÁT: a rögzítés csak addig fut, amíg ez a képernyő nyitva /
/// előtérben van — háttérbe kerülve (kikapcsolt kijelző, másik app) a
/// Flutter időzítő és a helyzet-figyelő szüneteltethető az operációs
/// rendszer által, tehát a mérés is szünetel.
class AutoLogScreen extends StatefulWidget {
  final int surveySessionId;

  /// Ha igaz, a megnyitás után azonnal indul a rögzítés (Bluetooth-gombról).
  final bool autoStart;

  const AutoLogScreen({
    super.key,
    required this.surveySessionId,
    this.autoStart = false,
  });

  @override
  State<AutoLogScreen> createState() => _AutoLogScreenState();
}

class _AutoLogScreenState extends State<AutoLogScreen> {
  List<_Source> _sources = [];
  List<_ActiveSource> _active = [];

  /// A GPS forrása (ha van Modbus-GPS-es kijelölt műszer).
  _Source? _gpsSrc;

  /// Dózisintegráláshoz: legfeljebb egy dózisteljesítmény-csatorna.
  _Source? _doseSrc;

  /// Idődiagram és küszöb: az első kijelölt sugárzási csatorna.
  _Source? _chartSrc;

  _TriggerMode _mode = _TriggerMode.time;

  final _intervalCtrl = TextEditingController(text: '1');
  DistanceUnit _distanceUnit = DistanceUnitController.current;
  late final _distanceCtrl = TextEditingController(
    text: QuantityField.formatNumber(_distanceUnit.fromMeters(5)),
  );

  bool _isRunning = false;
  late final ButtonCommandHandler _buttonHandler = _onButtonCommand;
  bool _starting = false;
  bool _busy = false; // egy tick fut-e éppen (átfedés elkerülése)

  Timer? _timer;

  /// Távolság-módban telefon-GPS-szel a mérés csak megtett útra triggerel, a
  /// dózis integrálásához ettől függetlenül másodpercenként olvasunk.
  Timer? _doseTimer;
  final _dose = DoseIntegrator();
  StreamSubscription<Position>? _positionSub;
  Position? _currentPosition;
  (double, double)? _lastModbusGpsPosition;

  bool get _useModbusGps => _gpsSrc != null;

  /// A futás alatt olvasott értékek az idődiagramhoz (alapegységben).
  final List<TimeSample> _samples = [];
  static const _maxSamples = 7200;
  double? _threshold;
  String _chartUnit = '';

  int _capturedCount = 0;
  int _errorCount = 0;
  double? _lastValue;
  String _lastUnit = '';
  String? _lastError;

  List<_Source> get _selectedSources => [
        for (final s in _sources)
          if (s.selected) s,
      ];

  _ActiveSource? _activeFor(_Source? s) {
    if (s == null) return null;
    for (final a in _active) {
      if (identical(a.source, s)) return a;
    }
    return null;
  }

  void _addSample(double raw, _Source s) {
    _samples.add(
      TimeSample(DateTime.now(), channelReadingInAppUnit(s.channel, raw)),
    );
    if (_samples.length > _maxSamples) {
      _samples.removeRange(0, _samples.length - _maxSamples);
    }
  }

  @override
  void initState() {
    super.initState();
    HardwareButtons.register(_buttonHandler);
    _loadInstruments();
  }

  Future<void> _loadInstruments() async {
    final all = await DatabaseHelper.instance.getInstruments();
    if (!mounted) return;
    setState(() {
      _sources = [
        for (final i in all)
          if (i.isModbusConnected)
            for (final c in i.effectiveModbusChannels) _Source(i, c),
      ];
      if (_sources.isNotEmpty) _sources.first.selected = true;
    });
    if (widget.autoStart && !_isRunning && !_starting) unawaited(_start());
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
    final selected = _selectedSources;
    if (selected.isEmpty) {
      _showError(loc.autoLogSelectChannel);
      return;
    }
    final doseCount = selected
        .where((s) => s.channel.type == MeasurementType.doseRate)
        .length;
    if (doseCount > 1) {
      _showError(loc.autoLogOneDoseSource);
      return;
    }

    final interval = int.tryParse(_intervalCtrl.text.trim()) ?? 1;
    // A távolságköz méterben (a választott egységből átszámolva).
    final distance =
        _distanceUnit.toMeters(parseDecimal(_distanceCtrl.text) ?? 5);
    if (_mode == _TriggerMode.time && interval < 1) {
      _showError(loc.intervalMinError);
      return;
    }
    if (_mode == _TriggerMode.distance && distance < 1) {
      _showError(loc.distanceMinError);
      return;
    }

    final gpsCandidate =
        _firstOf(selected, (s) => s.instrument.isModbusGpsEnabled);
    if (gpsCandidate == null && !await _ensureLocationPermission()) return;

    setState(() => _starting = true);
    final opened = <_ActiveSource>[];
    try {
      for (final s in selected) {
        final session =
            await ModbusLiveSession.connect(s.instrument, s.channel, loc);
        opened.add(_ActiveSource(s, session));
      }
    } catch (e) {
      for (final a in opened) {
        await a.session.close();
      }
      _showError(loc.modbusConnectErrorMessage('$e'));
      if (mounted) setState(() => _starting = false);
      return;
    }

    _active = opened;
    _gpsSrc = gpsCandidate;
    _doseSrc = _firstOf(
        selected, (s) => s.channel.type == MeasurementType.doseRate);
    _chartSrc = _firstOf(selected, (s) => _isRadiation(s.channel.type));

    unawaited(WakelockPlus.enable());
    final chart = _chartSrc;
    _threshold = chart == null
        ? null
        : await SettingsService().getThreshold(chart.channel.type);
    _chartUnit = chart?.channel.type.defaultUnit ?? '';
    setState(() {
      _samples.clear();
      _isRunning = true;
      _starting = false;
      _capturedCount = 0;
      _errorCount = 0;
      _lastValue = null;
      _lastUnit = '';
      _lastError = null;
      _lastModbusGpsPosition = null;
      _dose.reset();
    });

    if (_useModbusGps) {
      // Modbus-GPS: a kijelölt műszer helyzetét használjuk, nem a telefonét.
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
          distanceFilter: distance.round(),
        ),
      ).listen(_captureTick);
      _doseTimer =
          Timer.periodic(const Duration(seconds: 1), (_) => _doseTick());
    }
  }

  /// Csak dózis-integráláshoz szükséges olvasás (nem rögzít mérési pontot).
  Future<void> _doseTick() async {
    final doseActive = _activeFor(_doseSrc);
    if (_busy || !_isRunning || doseActive == null) return;
    _busy = true;
    try {
      final result = await doseActive.session.read();
      final value = result.value;
      if (result.success && value != null) {
        _dose.addSample(value, doseActive.source.channel.unit, DateTime.now());
        if (identical(_chartSrc, _doseSrc)) {
          _addSample(value, doseActive.source);
        }
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
        doseMicroSv: dose,
        accumulate: true,
      );
    }
    return (persons.length, dose);
  }

  MeasurementPoint _point({
    required MeasurementType type,
    required double latitude,
    required double longitude,
    required double? accuracy,
    required DateTime now,
    required int? instrumentId,
    double? value,
    String unit = '',
    Meteorology? meteorology,
    List<GasReading> gases = const [],
  }) =>
      MeasurementPoint(
        surveySessionId: widget.surveySessionId,
        latitude: latitude,
        longitude: longitude,
        gpsAccuracyMeters: accuracy,
        type: type,
        value: value,
        unit: unit,
        instrumentId: instrumentId,
        meteorology: meteorology,
        gases: gases,
        timestamp: now,
        createdAt: now,
        updatedAt: now,
      );

  /// Egy műszer meteorológiai csatornáiból egy megfigyelés (a többi mező üres).
  Meteorology? _meteorologyFrom(List<(_ActiveSource, ModbusReadResult)> items) {
    final values = <String, double>{};
    for (final (a, r) in items) {
      final c = a.source.channel;
      final key = c.quantity;
      if (c.type != MeasurementType.meteorology || key == null) continue;
      values[key] = meteoValueToStored(key, c.unit, r.value!);
    }
    if (values.isEmpty) return null;
    return Meteorology(
      airTemperatureC: values['air_temperature_c'],
      relativeHumidityPct: values['relative_humidity_pct'],
      pressureHpa: values['pressure_hpa'],
      windSpeedMs: values['wind_speed_ms'],
      windDirectionDeg: values['wind_direction_deg'],
      gustMs: values['gust_ms'],
      precipitationMmH: values['precipitation_mm_h'],
      solarWm2: values['solar_wm2'],
      cloudOkta: values['cloud_okta'],
      visibilityM: values['visibility_m'],
      soilMoisturePct: values['soil_moisture_pct'],
      aerosolUgM3: values['aerosol_ug_m3'],
    );
  }

  /// Egy műszer gázcsatornáiból a vegyületek listája.
  List<GasReading> _gasesFrom(List<(_ActiveSource, ModbusReadResult)> items) {
    final out = <GasReading>[];
    for (final (a, r) in items) {
      final c = a.source.channel;
      final name = c.quantity;
      final unit = ConcentrationUnit.fromSymbol(c.unit);
      if (c.type != MeasurementType.gasMeasurement || name == null || unit == null) {
        continue;
      }
      out.add(GasReading(
        name: name,
        formula: gasFormulaOf(name),
        concentration: r.value!,
        unit: unit,
      ));
    }
    return out;
  }

  Future<void> _captureTick(Position? position, {double? minDistance}) async {
    if ((position == null && !_useModbusGps) || _busy || !_isRunning) return;
    _busy = true;
    try {
      // Minden kijelölt csatorna egy időpontban, párhuzamosan olvasódik.
      final actives = List<_ActiveSource>.of(_active);
      final results =
          await Future.wait([for (final a in actives) a.session.read()]);
      final readings = <(_ActiveSource, ModbusReadResult)>[];
      ModbusReadResult? gpsRead;
      for (var i = 0; i < actives.length; i++) {
        final a = actives[i];
        final r = results[i];
        if (identical(a.source, _gpsSrc)) gpsRead = r;
        if (!r.success || r.value == null) {
          _errorCount++;
          _lastError = r.errorMessage;
          continue;
        }
        readings.add((a, r));
      }

      // Dózis és idődiagram a sikeres olvasásokból (a GPS-szűrés előtt).
      for (final (a, r) in readings) {
        final raw = r.value!;
        if (identical(a.source, _doseSrc)) {
          _dose.addSample(raw, a.source.channel.unit, DateTime.now());
        }
        if (identical(a.source, _chartSrc)) _addSample(raw, a.source);
      }

      final double latitude;
      final double longitude;
      final double? accuracy;
      if (_useModbusGps) {
        final lat = gpsRead?.latitude;
        final lon = gpsRead?.longitude;
        if (gpsRead == null || !gpsRead.success || lat == null || lon == null) {
          if (mounted) setState(() {});
          return;
        }
        latitude = lat;
        longitude = lon;
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
      final points = <MeasurementPoint>[];

      // Sugárzási csatornánként egy pont.
      for (final (a, r) in readings) {
        final c = a.source.channel;
        if (!_isRadiation(c.type)) continue;
        points.add(_point(
          type: c.type,
          value: channelReadingInAppUnit(c, r.value!),
          unit: c.type.defaultUnit,
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
          now: now,
          instrumentId: a.source.instrument.id,
        ));
      }

      // Meteorológia és gáz: műszerenként egy-egy összevont pont.
      final metaGroups = <int?, List<(_ActiveSource, ModbusReadResult)>>{};
      final gasGroups = <int?, List<(_ActiveSource, ModbusReadResult)>>{};
      for (final e in readings) {
        final t = e.$1.source.channel.type;
        final id = e.$1.source.instrument.id;
        if (t == MeasurementType.meteorology) {
          metaGroups.putIfAbsent(id, () => []).add(e);
        } else if (t == MeasurementType.gasMeasurement) {
          gasGroups.putIfAbsent(id, () => []).add(e);
        }
      }
      for (final entry in metaGroups.entries) {
        final meteo = _meteorologyFrom(entry.value);
        if (meteo == null) continue;
        points.add(_point(
          type: MeasurementType.meteorology,
          meteorology: meteo,
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
          now: now,
          instrumentId: entry.key,
        ));
      }
      for (final entry in gasGroups.entries) {
        final gases = _gasesFrom(entry.value);
        if (gases.isEmpty) continue;
        points.add(_point(
          type: MeasurementType.gasMeasurement,
          gases: gases,
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
          now: now,
          instrumentId: entry.key,
        ));
      }

      for (final p in points) {
        await DatabaseHelper.instance.insertMeasurementPoint(p);
      }

      // Küszöb: a sugárzási pontokra, típusonként.
      for (final (a, r) in readings) {
        final c = a.source.channel;
        if (!_isRadiation(c.type)) continue;
        final threshold = await SettingsService().getThreshold(c.type);
        if (threshold != null &&
            channelReadingInAppUnit(c, r.value!) >= threshold) {
          HapticFeedback.heavyImpact();
        }
      }

      _capturedCount += points.length;
      for (final (a, r) in readings) {
        if (identical(a.source, _chartSrc)) {
          _lastValue = channelReadingInAppUnit(a.source.channel, r.value!);
          _lastUnit = a.source.channel.type.defaultUnit;
        }
      }
      if (mounted) setState(() {});
    } finally {
      _busy = false;
    }
  }

  Future<void> _closeSessions() async {
    final actives = _active;
    _active = [];
    for (final a in actives) {
      await a.session.close();
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _timer = null;
    _doseTimer?.cancel();
    _doseTimer = null;
    await _positionSub?.cancel();
    _positionSub = null;
    await _closeSessions();
    unawaited(HardwareButtonController.applyScreenWake());
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

  /// Bluetooth-gomb: automatikus rögzítés indítása vagy leállítása.
  bool _onButtonCommand(ButtonCommand command) {
    if (!mounted || command != ButtonCommand.toggleAutoLog) return false;
    if (_isRunning) {
      unawaited(_stop());
    } else {
      unawaited(_start());
    }
    return true;
  }

  @override
  void dispose() {
    HardwareButtons.unregister(_buttonHandler);
    _timer?.cancel();
    _doseTimer?.cancel();
    // Ha a képernyőt a felhasználó leállítás nélkül hagyja el, a már
    // összegzett dózis akkor sem veszhet el.
    if (_isRunning) unawaited(_persistDose());
    _positionSub?.cancel();
    for (final a in _active) {
      unawaited(a.session.close());
    }
    unawaited(HardwareButtonController.applyScreenWake());
    _intervalCtrl.dispose();
    _distanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final selected = _selectedSources;
    final hasDose =
        selected.any((s) => s.channel.type == MeasurementType.doseRate);
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
          if (_sources.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(loc.noModbusInstrumentMessage),
              ),
            )
          else ...[
            Text(
              loc.autoLogSourcesTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              loc.autoLogSourcesHelper,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            for (final s in _sources)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: s.selected,
                onChanged: _isRunning
                    ? null
                    : (v) => setState(() => s.selected = v ?? false),
                title: Text(s.instrument.name),
                subtitle: Text(
                  '${modbusChannelLabel(loc, s.channel, s.channel.type.label(context))}'
                  ' (${s.channel.unit})',
                ),
              ),
            if (!hasDose)
              Padding(
                padding: const EdgeInsets.only(top: 4),
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
              IgnorePointer(
                ignoring: _isRunning,
                child: Opacity(
                  opacity: _isRunning ? 0.5 : 1,
                  child: QuantityField<DistanceUnit>(
                    controller: _distanceCtrl,
                    label: loc.distanceIntervalPlainLabel,
                    units: DistanceUnit.values,
                    unit: _distanceUnit,
                    onUnitChanged: (u) => setState(() => _distanceUnit = u),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (!_isRunning)
              FilledButton.icon(
                onPressed: _starting || selected.isEmpty ? null : _start,
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
            if (_samples.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.autoLogChartTitle,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      TimeSeriesChart(
                        samples: _samples,
                        unit: _chartUnit,
                        threshold: _threshold,
                      ),
                    ],
                  ),
                ),
              ),
            if (_samples.isNotEmpty) const SizedBox(height: 16),
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
                            _lastUnit)),
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
