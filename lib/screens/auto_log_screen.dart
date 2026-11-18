import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:wakelock_plus/wakelock_plus.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../l10n/modbus_quantity_labels.dart';
import '../models/concentration_unit.dart';
import '../models/decimal_separator.dart';
import '../models/distance_unit.dart';
import '../models/gas_reading.dart';
import '../models/hardware_button.dart';
import '../models/auto_log_position.dart';
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
import '../services/auto_log_chart_controller.dart';
import 'instrument_list_screen.dart';
import 'map_point_picker_screen.dart';
import 'package:intl/intl.dart';

enum _TriggerMode { time, distance }

/// Mérési érték nagy kijelzőre: a műszer-kijelzőhöz hasonló, kevés tizedessel,
/// a helyi tizedesjellel.
String _formatReading(BuildContext context, double v) {
  final locale = Localizations.localeOf(context).toString();
  final a = v.abs();
  if (a == 0) return '0';
  if (a >= 1e5 || a < 1e-3) {
    return NumberFormat('0.00E0', locale).format(v);
  }
  final pattern = a >= 100 ? '#,##0' : a >= 10 ? '0.0' : a >= 1 ? '0.00' : '0.0000';
  return NumberFormat(pattern, locale).format(v);
}

/// Egy kiválasztható csatorna: melyik műszer, melyik regiszter.
class _Source {
  _Source(this.instrument, this.channel);

  final Instrument instrument;
  final ModbusChannel channel;
  bool selected = false;
}

/// Egy csatorna, amelyhez futás közben nyitott kapcsolat tartozik.
/// Egy műszer pozíció-beállítása az automatikus méréshez.
class _InstrumentPosition {
  const _InstrumentPosition(this.source, {this.latitude, this.longitude});

  final AutoLogPositionSource source;
  final double? latitude;
  final double? longitude;

  bool get hasFixed => latitude != null && longitude != null;
}

/// Egy pont helyzete.
class _Fix {
  const _Fix(this.latitude, this.longitude, this.accuracy);

  final double latitude;
  final double longitude;
  final double? accuracy;
}

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
/// helyzettel. A pozíciót műszerenként a beállítás adja: telefon GPS, fix
/// koordináta vagy a műszer Modbus GPS-e.
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

  /// Műszerenként a pozíció-beállítás (forrás, fix koordináta).
  final Map<int, _InstrumentPosition> _positions = {};

  /// Távolság módban a mozgást adó Modbus-GPS-es műszer, ha nincs telefonos.
  Instrument? _triggerInstrument;

  /// Dózisteljesítmény-csatornánként egy integrátor (futás közben).
  final Map<_Source, DoseIntegrator> _doses = {};

  /// A személyekhez mentett dózis forrása (a futás elején rögzül).
  _Source? _doseSrc;

  /// A felhasználó által választott mentési forrás.
  _Source? _doseChoice;

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
  StreamSubscription<Position>? _positionSub;
  Position? _currentPosition;
  (double, double)? _lastTriggerPosition;

  /// A kijelölt dózisteljesítmény-csatornák.
  List<_Source> get _doseSources => [
        for (final s in _selectedSources)
          if (s.channel.type == MeasurementType.doseRate) s,
      ];

  /// A személyekhez mentésre kerülő integrátor, ha van.
  DoseIntegrator? get _savedDose => _doseSrc == null ? null : _doses[_doseSrc];

  _InstrumentPosition _positionOf(Instrument i) {
    const fallback = _InstrumentPosition(AutoLogPositionSource.phone);
    final id = i.id;
    if (id == null) return fallback;
    return _positions[id] ?? fallback;
  }

  /// Legalább egy kijelölt műszer a telefon GPS-ét használja.
  bool _anyPhoneSource(List<_Source> list) => list.any(
        (s) => _positionOf(s.instrument).source == AutoLogPositionSource.phone,
      );

  /// A futás alatt olvasott értékek csatornánként, alapegységben (az
  /// idődiagramhoz). Minden kijelölt csatorna a saját pufferébe ír.
  final Map<_Source, List<TimeSample>> _series = {};
  static const _maxSamples = 7200;
  double? _threshold;
  String get _chartUnit => _chartSrc?.channel.type.defaultUnit ?? '';
  List<TimeSample> get _chartSamples => _series[_chartSrc] ?? const [];

  /// A megjelenített csatorna utolsó mért értéke (alapegységben).
  double? get _currentValue =>
      _chartSamples.isEmpty ? null : _chartSamples.last.value;

  /// A kijelzőn az érték a küszöb fölött van (riasztási szín).
  bool get _isAlarm =>
      _currentValue != null &&
      _threshold != null &&
      _currentValue! >= _threshold!;

  /// A csatorna neve a kijelzőn és a legördülőben: műszer · csatorna.
  String _chartChannelLabel(
      BuildContext context, AppLocalizations loc, _Source s) =>
      '${s.instrument.name} · ${modbusChannelLabel(loc, s.channel, s.channel.type.label(context))}';

  int _capturedCount = 0;
  int _errorCount = 0;
  String? _lastError;

  List<_Source> get _selectedSources => [
        for (final s in _sources)
          if (s.selected) s,
      ];

  /// A diagramra került minták: a legutóbbi [limit] db (0 = mind).
  List<TimeSample> _lastSamples(int limit) {
    final samples = _chartSamples;
    if (limit <= 0 || samples.length <= limit) return samples;
    return samples.sublist(samples.length - limit);
  }

  void _addSample(double raw, _Source s) {
    final list = _series.putIfAbsent(s, () => <TimeSample>[]);
    list.add(
      TimeSample(DateTime.now(), channelReadingInAppUnit(s.channel, raw)),
    );
    if (list.length > _maxSamples) {
      list.removeRange(0, list.length - _maxSamples);
    }
  }

  Future<double?> _loadThreshold(_Source? s) => s == null
      ? Future.value(null)
      : SettingsService().getThreshold(s.channel.type);

  /// A diagramon megjelenített csatorna váltása (futás közben is).
  Future<void> _selectChartSource(_Source s) async {
    final threshold = await _loadThreshold(s);
    if (!mounted) return;
    setState(() {
      _chartSrc = s;
      _threshold = threshold;
    });
  }

  /// A megjelenített csatorna diagramjának újraindítása: a puffere ürül, a
  /// többi csatornáé érintetlen. A mérési pontok az adatbázisban maradnak.
  void _resetChart() {
    final s = _chartSrc;
    if (s == null) return;
    setState(() => _series[s]?.clear());
  }

  @override
  void initState() {
    super.initState();
    HardwareButtons.register(_buttonHandler);
    _loadInstruments();
  }

  Future<void> _openInstruments() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InstrumentListScreen()),
    );
    if (!mounted) return;
    // A műszerek változhattak: a korábbi diagram csatornája már nem érvényes.
    setState(() {
      _chartSrc = null;
      _threshold = null;
      _series.clear();
    });
    await _loadInstruments(allowAutoStart: false);
  }

  Future<void> _loadInstruments({bool allowAutoStart = true}) async {
    final all = await DatabaseHelper.instance.getInstruments();
    if (!mounted) return;
    _positions.clear();
    for (final i in all) {
      final id = i.id;
      if (id == null) continue;
      var source = i.autoLogPositionSource;
      // A Modbus-GPS-t a műszeren ki lehet kapcsolni: akkor a telefon marad.
      if (source == AutoLogPositionSource.modbus && !i.isModbusGpsEnabled) {
        source = AutoLogPositionSource.phone;
      }
      _positions[id] = _InstrumentPosition(
        source,
        latitude: i.autoLogLatitude,
        longitude: i.autoLogLongitude,
      );
    }
    setState(() {
      _sources = [
        for (final i in all)
          if (i.isModbusConnected)
            for (final c in i.effectiveModbusChannels) _Source(i, c),
      ];
      if (_sources.isNotEmpty) _sources.first.selected = true;
    });
    if (allowAutoStart && widget.autoStart && !_isRunning && !_starting) {
      unawaited(_start());
    }
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

    // Pozíció-beállítások ellenőrzése műszerenként.
    final instruments = <Instrument>[];
    for (final s in selected) {
      if (!instruments.any((i) => identical(i, s.instrument))) {
        instruments.add(s.instrument);
      }
    }
    for (final i in instruments) {
      final p = _positionOf(i);
      if (p.source == AutoLogPositionSource.modbus && !i.isModbusGpsEnabled) {
        _showError(loc.autoLogPositionModbusError(i.name));
        return;
      }
      if (p.source == AutoLogPositionSource.fixed && !p.hasFixed) {
        _showError(loc.autoLogPositionFixedError(i.name));
        return;
      }
    }
    final anyPhone = _anyPhoneSource(selected);
    _triggerInstrument = null;
    if (_mode == _TriggerMode.distance && !anyPhone) {
      // Mozgó pozíció nélkül a távolság nem mérhető: a Modbus-GPS dönt.
      Instrument? mover;
      for (final i in instruments) {
        if (_positionOf(i).source == AutoLogPositionSource.modbus) {
          mover = i;
          break;
        }
      }
      if (mover == null) {
        _showError(loc.autoLogDistanceNeedsMoving);
        return;
      }
      _triggerInstrument = mover;
    }
    if (anyPhone && !await _ensureLocationPermission()) return;

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
    final doseSources = _doseSources;
    _doseSrc = doseSources.contains(_doseChoice)
        ? _doseChoice
        : (doseSources.isEmpty ? null : doseSources.first);
    _chartSrc = _firstOf(selected, (s) => _isRadiation(s.channel.type)) ??
        (selected.isEmpty ? null : selected.first);

    unawaited(WakelockPlus.enable());
    _threshold = await _loadThreshold(_chartSrc);
    setState(() {
      _series.clear();
      _isRunning = true;
      _starting = false;
      _capturedCount = 0;
      _errorCount = 0;
      _lastError = null;
      _lastTriggerPosition = null;
      _doses.clear();
      for (final s in doseSources) {
        _doses[s] = DoseIntegrator();
      }
    });

    if (_mode == _TriggerMode.time) {
      // Telefon-GPS esetén a legfrissebb pozíciót folyamatosan frissítjük,
      // nem várjuk meg minden tick-nél külön a GPS-t.
      if (anyPhone) {
        _positionSub = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
          ),
        ).listen((position) => _currentPosition = position);
      }
      _timer = Timer.periodic(
        Duration(seconds: interval),
        (_) => _captureTick(_currentPosition),
      );
      return;
    }

    if (anyPhone) {
      // Telefonos mozgás-trigger: a megtett út szerint rögzít, minden
      // műszer a saját pozícióját kapja.
      _positionSub = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: distance.round(),
        ),
      ).listen(_captureTick);
      _doseTimer =
          Timer.periodic(const Duration(seconds: 1), (_) => _doseTick());
    } else {
      // Modbus-GPS mozgás-trigger: 1 mp-es lekérdezés, a megtett utat a
      // kijelölt műszer GPS-éből számoljuk.
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _captureTick(null, minDistance: distance),
      );
    }
  }

  /// Csak dózis-integráláshoz szükséges olvasás (nem rögzít mérési pontot).
  Future<void> _doseTick() async {
    final doseActives = [
      for (final a in _active)
        if (a.source.channel.type == MeasurementType.doseRate) a,
    ];
    if (_busy || !_isRunning || doseActives.isEmpty) return;
    _busy = true;
    try {
      final results = await Future.wait([
        for (final a in doseActives) a.session.read(withGps: false),
      ]);
      var any = false;
      for (var i = 0; i < doseActives.length; i++) {
        final a = doseActives[i];
        final value = results[i].value;
        if (results[i].success && value != null) {
          _doses[a.source]
              ?.addSample(value, a.source.channel.unit, DateTime.now());
          _addSample(value, a.source);
          any = true;
        }
      }
      if (any && mounted) setState(() {});
    } finally {
      _busy = false;
    }
  }

  void _resetDoses() {
    for (final d in _doses.values) {
      d.reset();
    }
  }

  /// A leállításkor összegzett dózist elmenti a felméréshez rendelt összes
  /// személynek (online dózisként, a korábbi indításokhoz hozzáadva). Az
  /// elmentett személyek számát adja vissza, -1-et ha nincs hozzárendelt
  /// személy; `null`, ha nem volt mit menteni.
  Future<(int?, double)> _persistDose() async {
    final integrator = _savedDose;
    if (integrator == null || !integrator.hasData) {
      _resetDoses();
      return (null, 0.0);
    }
    final dose = integrator.doseMicroSv;
    _resetDoses();
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

  /// Egy rögzítési kör: a csatornák olvasása, majd pontok írása
  /// műszerenként a beállított pozícióval.
  Future<void> _captureTick(Position? phonePosition, {double? minDistance}) async {
    if (_busy || !_isRunning) return;
    _busy = true;
    try {
      final loc = AppLocalizations.of(context)!;
      // Minden kijelölt csatorna egy időpontban, párhuzamosan olvasódik.
      final actives = List<_ActiveSource>.of(_active);
      final results = await Future.wait([
        for (final a in actives) a.session.read(withGps: _isGpsCarrier(a)),
      ]);
      final readings = <(_ActiveSource, ModbusReadResult)>[];
      // Műszerenként az első sikeres GPS-olvasás.
      final gpsByInstrument = <int, (double, double)>{};
      for (var i = 0; i < actives.length; i++) {
        final a = actives[i];
        final r = results[i];
        final id = a.source.instrument.id;
        final lat = r.latitude;
        final lon = r.longitude;
        if (id != null &&
            r.success &&
            lat != null &&
            lon != null &&
            !gpsByInstrument.containsKey(id)) {
          gpsByInstrument[id] = (lat, lon);
        }
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
        _doses[a.source]
            ?.addSample(raw, a.source.channel.unit, DateTime.now());
        _addSample(raw, a.source);
      }

      // Távolság módban a mozgást adó műszer GPS-e dönti el, rögzítünk-e.
      final trigger = _triggerInstrument;
      if (_mode == _TriggerMode.distance && trigger != null) {
        final moved = gpsByInstrument[trigger.id];
        if (moved == null) {
          if (mounted) setState(() {});
          return;
        }
        final last = _lastTriggerPosition;
        if (last != null &&
            Geolocator.distanceBetween(
                  last.$1,
                  last.$2,
                  moved.$1,
                  moved.$2,
                ) <
                (minDistance ?? 5)) {
          return;
        }
        _lastTriggerPosition = moved;
      }

      // Műszerenként a pozíció: telefon, fix koordináta vagy a műszer GPS-e.
      final fixes = <int?, _Fix?>{};
      _Fix? fixFor(Instrument i) {
        if (fixes.containsKey(i.id)) return fixes[i.id];
        final p = _positionOf(i);
        _Fix? fix;
        switch (p.source) {
          case AutoLogPositionSource.phone:
            final pos = phonePosition ?? _currentPosition;
            if (pos != null) {
              fix = _Fix(pos.latitude, pos.longitude, pos.accuracy);
            }
          case AutoLogPositionSource.fixed:
            final lat = p.latitude;
            final lon = p.longitude;
            if (lat != null && lon != null) fix = _Fix(lat, lon, null);
          case AutoLogPositionSource.modbus:
            final id = i.id;
            final g = id == null ? null : gpsByInstrument[id];
            if (g != null) fix = _Fix(g.$1, g.$2, null);
        }
        fixes[i.id] = fix;
        return fix;
      }

      final now = DateTime.now();
      final points = <MeasurementPoint>[];

      // Sugárzási csatornánként egy pont.
      for (final (a, r) in readings) {
        final c = a.source.channel;
        if (!_isRadiation(c.type)) continue;
        final fix = fixFor(a.source.instrument);
        if (fix == null) {
          _lastError = loc.autoLogNoPosition(a.source.instrument.name);
          continue;
        }
        points.add(_point(
          type: c.type,
          value: channelReadingInAppUnit(c, r.value!),
          unit: c.type.defaultUnit,
          latitude: fix.latitude,
          longitude: fix.longitude,
          accuracy: fix.accuracy,
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
        final inst = entry.value.first.$1.source.instrument;
        final fix = fixFor(inst);
        if (fix == null) {
          _lastError = loc.autoLogNoPosition(inst.name);
          continue;
        }
        final meteo = _meteorologyFrom(entry.value);
        if (meteo == null) continue;
        points.add(_point(
          type: MeasurementType.meteorology,
          meteorology: meteo,
          latitude: fix.latitude,
          longitude: fix.longitude,
          accuracy: fix.accuracy,
          now: now,
          instrumentId: entry.key,
        ));
      }
      for (final entry in gasGroups.entries) {
        final inst = entry.value.first.$1.source.instrument;
        final fix = fixFor(inst);
        if (fix == null) {
          _lastError = loc.autoLogNoPosition(inst.name);
          continue;
        }
        final gases = _gasesFrom(entry.value);
        if (gases.isEmpty) continue;
        points.add(_point(
          type: MeasurementType.gasMeasurement,
          gases: gases,
          latitude: fix.latitude,
          longitude: fix.longitude,
          accuracy: fix.accuracy,
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
      if (mounted) setState(() {});
    } finally {
      _busy = false;
    }
  }

  /// A csatorna GPS-t kérjen-e ezen a körön: a GPS-es műszer első csatornája.
  bool _isGpsCarrier(_ActiveSource a) {
    final inst = a.source.instrument;
    final needsGps =
        _positionOf(inst).source == AutoLogPositionSource.modbus ||
            identical(inst, _triggerInstrument);
    if (!needsGps) return false;
    for (final o in _active) {
      if (identical(o.source.instrument, inst)) return identical(o, a);
    }
    return false;
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

  Widget _buildDoseSourcePicker(AppLocalizations loc) {
    final sources = _doseSources;
    final current =
        sources.contains(_doseChoice) ? _doseChoice! : sources.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<_Source>(
        key: ValueKey<Object>(current),
        initialValue: current,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: loc.autoLogDoseSourceLabel,
          helperText: loc.autoLogDoseSourceHelper,
          isDense: true,
        ),
        items: [
          for (final s in sources)
            DropdownMenuItem(
              value: s,
              child: Text(_chartChannelLabel(context, loc, s)),
            ),
        ],
        onChanged:
            _isRunning ? null : (v) => setState(() => _doseChoice = v),
      ),
    );
  }

  Widget _buildPositionCard(AppLocalizations loc, List<_Source> selected) {
    final theme = Theme.of(context);
    final instruments = <Instrument>[];
    for (final s in selected) {
      if (!instruments.any((i) => identical(i, s.instrument))) {
        instruments.add(s.instrument);
      }
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.autoLogPositionTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(loc.autoLogPositionHelper, style: theme.textTheme.bodySmall),
            for (final i in instruments) _positionRow(loc, i),
          ],
        ),
      ),
    );
  }

  Widget _positionRow(AppLocalizations loc, Instrument i) {
    final p = _positionOf(i);
    final sep = decimalSeparatorFor(
      DecimalSeparatorController.current,
      loc.protoDecimalSep,
    );
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(i.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          DropdownButtonFormField<AutoLogPositionSource>(
            key: ValueKey('pos-${i.id}-${p.source.name}'),
            initialValue: p.source,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: loc.autoLogPositionSourceLabel,
              isDense: true,
            ),
            items: [
              DropdownMenuItem(
                value: AutoLogPositionSource.phone,
                child: Text(loc.autoLogPositionPhone),
              ),
              DropdownMenuItem(
                value: AutoLogPositionSource.fixed,
                child: Text(loc.autoLogPositionFixed),
              ),
              if (i.isModbusGpsEnabled)
                DropdownMenuItem(
                  value: AutoLogPositionSource.modbus,
                  child: Text(loc.autoLogPositionModbus),
                ),
            ],
            onChanged: _isRunning
                ? null
                : (v) {
                    if (v != null) unawaited(_setPositionSource(i, v));
                  },
          ),
          if (p.source == AutoLogPositionSource.fixed)
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  p.hasFixed
                      ? '${_fmtCoord(p.latitude!, sep)}, '
                          '${_fmtCoord(p.longitude!, sep)}'
                      : loc.autoLogPositionFixedNotSet,
                  style: theme.textTheme.bodySmall,
                ),
                TextButton.icon(
                  onPressed: _isRunning ? null : () => _pickFixedOnMap(i),
                  icon: const Icon(Icons.map),
                  label: Text(loc.autoLogPositionPickMap),
                ),
                TextButton.icon(
                  onPressed: _isRunning ? null : () => _typeFixed(i),
                  icon: const Icon(Icons.edit),
                  label: Text(loc.autoLogPositionType),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _fmtCoord(double v, String sep) =>
      v.toStringAsFixed(6).replaceAll('.', sep);

  Future<void> _setPositionSource(
      Instrument i, AutoLogPositionSource src) async {
    final current = _positionOf(i);
    await _savePosition(i, src, current.latitude, current.longitude);
  }

  Future<void> _savePosition(
    Instrument i,
    AutoLogPositionSource src,
    double? lat,
    double? lon,
  ) async {
    final id = i.id;
    if (id == null) return;
    await DatabaseHelper.instance.setAutoLogPosition(id, src, lat, lon);
    if (!mounted) return;
    setState(() {
      _positions[id] =
          _InstrumentPosition(src, latitude: lat, longitude: lon);
    });
  }

  Future<void> _pickFixedOnMap(Instrument i) async {
    final p = _positionOf(i);
    final pos = _currentPosition;
    final ll.LatLng initial;
    if (p.hasFixed) {
      initial = ll.LatLng(p.latitude!, p.longitude!);
    } else if (pos != null) {
      initial = ll.LatLng(pos.latitude, pos.longitude);
    } else {
      initial = const ll.LatLng(47.4979, 19.0402); // Budapest, ha nincs helyzet
    }
    final picked = await Navigator.of(context).push<ll.LatLng>(
      MaterialPageRoute(
        builder: (_) => MapPointPickerScreen(initialCenter: initial),
      ),
    );
    if (picked == null) return;
    await _savePosition(
      i,
      AutoLogPositionSource.fixed,
      picked.latitude,
      picked.longitude,
    );
  }

  Future<void> _typeFixed(Instrument i) async {
    final p = _positionOf(i);
    final result = await showDialog<(double, double)>(
      context: context,
      builder: (_) => _CoordinateDialog(
        latitude: p.latitude,
        longitude: p.longitude,
      ),
    );
    if (result == null) return;
    await _savePosition(
        i, AutoLogPositionSource.fixed, result.$1, result.$2);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final selected = _selectedSources;
    final hasDose =
        selected.any((s) => s.channel.type == MeasurementType.doseRate);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.autoLogMenuItem),
        actions: [
          // Futás közben nem nyitható meg: a visszatéréskor újratöltött
          // műszerlista lecserélné a futó lekérdezés csatornáit.
          IconButton(
            icon: const Icon(Icons.sensors),
            tooltip: loc.instrumentsTooltip,
            onPressed: _isRunning || _starting ? null : _openInstruments,
          ),
        ],
      ),
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
            if (_doseSources.length > 1) _buildDoseSourcePicker(loc),
            if (selected.isNotEmpty) _buildPositionCard(loc, selected),
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
            if (_chartSrc != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(loc.autoLogChartTitle,
                                style: Theme.of(context).textTheme.titleSmall),
                          ),
                          IconButton(
                            tooltip: loc.autoLogChartResetTooltip,
                            icon: const Icon(Icons.restart_alt),
                            onPressed: _resetChart,
                          ),
                        ],
                      ),
                      if (_selectedSources.length > 1) ...[
                        const SizedBox(height: 4),
                        DropdownButtonFormField<_Source>(
                          key: ValueKey(_chartSrc),
                          initialValue: _chartSrc,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: loc.autoLogChartSourceLabel,
                          ),
                          items: [
                            for (final s in _selectedSources)
                              DropdownMenuItem<_Source>(
                                value: s,
                                child: Text(
                                  _chartChannelLabel(context, loc, s),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (s) {
                            if (s != null) _selectChartSource(s);
                          },
                        ),
                      ],
                      if (_currentValue != null) ...[
                        Text(
                          _chartChannelLabel(context, loc, _chartSrc!),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                              child: Text(
                                _formatReading(context, _currentValue!),
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _isAlarm
                                          ? Theme.of(context).colorScheme.error
                                          : null,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _chartUnit,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      ValueListenableBuilder<int>(
                        valueListenable: AutoLogChartController.points,
                        builder: (context, limit, _) => TimeSeriesChart(
                          samples: _lastSamples(limit),
                          unit: _chartUnit,
                          threshold: _threshold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_chartSrc != null) const SizedBox(height: 16),
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
                      for (final s in _doseSources) ...[
                        if (_doses[s]?.hasData ?? false)
                          Text(
                            loc.autoLogDoseSourceLine(
                                  _chartChannelLabel(context, loc, s),
                                  formatDose(context, _doses[s]!.doseMicroSv),
                                ) +
                                (s == _doseSrc ? loc.autoLogDoseSavedMark : ''),
                          ),
                        if ((_doses[s]?.gapCount ?? 0) > 0)
                          Text(
                            '${_chartChannelLabel(context, loc, s)}: '
                            '${loc.autoLogDoseGaps(_doses[s]!.gapCount)}',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error),
                          ),
                      ],
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

/// Fix koordináta beírása. A pont és a tizedesvessző is jó.
class _CoordinateDialog extends StatefulWidget {
  const _CoordinateDialog({this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;

  @override
  State<_CoordinateDialog> createState() => _CoordinateDialogState();
}

class _CoordinateDialogState extends State<_CoordinateDialog> {
  late final TextEditingController _lat;
  late final TextEditingController _lon;
  bool _invalid = false;

  @override
  void initState() {
    super.initState();
    _lat = TextEditingController(
      text: widget.latitude?.toStringAsFixed(6) ?? '',
    );
    _lon = TextEditingController(
      text: widget.longitude?.toStringAsFixed(6) ?? '',
    );
  }

  @override
  void dispose() {
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  void _save() {
    final lat = parseDecimal(_lat.text);
    final lon = parseDecimal(_lon.text);
    if (lat == null ||
        lon == null ||
        lat < -90 ||
        lat > 90 ||
        lon < -180 ||
        lon > 180) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop((lat, lon));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    const numberKeyboard = TextInputType.numberWithOptions(
      decimal: true,
      signed: true,
    );
    return AlertDialog(
      title: Text(loc.autoLogCoordinatesTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _lat,
            keyboardType: numberKeyboard,
            decoration: InputDecoration(labelText: loc.autoLogLatLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lon,
            keyboardType: numberKeyboard,
            decoration: InputDecoration(labelText: loc.autoLogLonLabel),
          ),
          if (_invalid)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                loc.autoLogCoordinatesInvalid,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancelButton),
        ),
        FilledButton(onPressed: _save, child: Text(loc.saveButton)),
      ],
    );
  }
}
