import '../models/hardware_button.dart';
import '../services/hardware_buttons.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../l10n/domain_labels.dart';
import '../l10n/modbus_quantity_labels.dart';
import '../models/meteorology.dart';
import '../models/modbus_reading.dart';
import '../models/map_area.dart';
import '../models/map_measure_line.dart';
import '../models/measurement_point.dart';
import '../models/measurement_type.dart';
import '../models/nuclide_id.dart';
import '../models/radiation_source.dart';
import '../models/survey_session.dart';
import '../models/survey_source_placement.dart';
import '../services/dose_unit_converter.dart';
import '../services/plan_georeference.dart';
import '../services/source_search.dart';
import '../services/display_units.dart';
import '../services/unit_format.dart';
import '../services/screenshot_service.dart';
import 'map_area_dialog.dart';
import 'measurement_entry_screen.dart';
import '../widgets/plan_map_layers.dart';

/// A pont térképi kategóriája: a mintavétel a `isSample` jelzőből, minden más
/// a típusából adódik. A színezhető mennyiségeket a színezési lista adja.
MeasurementType mapKindOf({required bool isSample, required MeasurementType type}) =>
    isSample ? MeasurementType.sample : type;

/// Az IDW-becslés bemenete: a mintapontok síkbeli koordinátái és a rácsgeometria.
/// Csak egyszerű adatokat tartalmaz, így átadható a háttérszálnak.
class _IdwGrid {
  _IdwGrid({
    required this.lat0,
    required this.lon0,
    required this.mPerLat,
    required this.mPerLon,
    required this.xs,
    required this.ys,
    required this.vs,
    required this.minX,
    required this.minY,
    required this.cell,
    required this.nx,
    required this.ny,
    required this.lo,
    required this.hi,
  });

  final double lat0;
  final double lon0;
  final double mPerLat;
  final double mPerLon;
  final List<double> xs;
  final List<double> ys;
  final List<double> vs;
  final double minX;
  final double minY;
  final double cell;
  final int nx;
  final int ny;
  final double lo;
  final double hi;
}

/// A rajzolási és mérési módok menüpontjai (egymást kizáró módok).
enum _ToolAction { area, measure, source }

/// Színezhető mennyiség forrása: mérési típus, meteorológiai mező vagy gáz.
enum _ScaleSource { typed, meteo, gas }

/// Egy színezhető mennyiség azonosítója (forrás + név + egység).
class _ScaleKey {
  const _ScaleKey(this.source, this.name, this.unit);

  final _ScaleSource source;
  final String name; // MeasurementType.name, meteorológiai mezőkulcs vagy gáznév
  final String unit;

  @override
  bool operator ==(Object other) =>
      other is _ScaleKey &&
      other.source == source &&
      other.name == name &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(source, name, unit);
}

/// A színezési lista egy eleme.
class _ScaleOption {
  const _ScaleOption(this.key, this.label);

  final _ScaleKey key;
  final String label;

  String get unit => key.unit;
}

/// A felmérés pontjait jeleníti meg térképen (OpenStreetMap csempék), a
/// a kiválasztott mennyiség szerint színezve (a többi mérés egyszínű ikonnal), és
/// a bejárt útvonalat (időrendi sorrend)
/// egy vonallal összekötve.
class SurveyMapScreen extends StatefulWidget {
  final int surveySessionId;

  const SurveyMapScreen({super.key, required this.surveySessionId});

  @override
  State<SurveyMapScreen> createState() => _SurveyMapScreenState();
}

class _SurveyMapScreenState extends State<SurveyMapScreen> {
  late final ButtonCommandHandler _buttonHandler = _onButtonCommand;
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
  PlanGeoref? _georef; // alaprajz mód: a felmérés kalibrált alaprajza
  List<RadiationSource> _sources = []; // a központi forráslista
  List<SurveySourcePlacement> _placements = []; // a felmérés forrás-elhelyezései
  int? _placingSourceId; // ha nem null, a következő koppintás ennek a forrásnak a helyét adja meg
  Map<int, List<String>> _nuclidesBySource = {}; // forrásonként a nuklidok (kereséshez)
  double _zoom = 16; // a térkép nagyítása: a forrás-feliratok ettől látszanak
  static const _sourceLabelMinZoom = 17.0;
  _ScaleKey? _scaleKey; // a színezett mennyiség (nincs kiválasztva: a dózisteljesítmény)
  bool _showInterpolation = false; // becsült (IDW) felület réteg
  Object? _interpSource; // az utoljára kiszámolt felület pontlistája (_points azonossága)
  _ScaleKey? _interpKey; // és mennyisége
  List<Polygon> _interpPolys = const [];
  int _interpToken = 0; // a háttérszámítás azonosítója: csak a legutolsó eredmény érvényes
  Object? _interpJobSource; // a folyamatban lévő számítás pontlistája
  _ScaleKey? _interpJobKey; // és mennyisége
  bool _viewRestored = false; // a mentett nézet visszatöltése megtörtént-e
  bool _showPoints = true; // mérési pontok és a bejárt útvonal
  bool _showAreas = true; // jelölt területek (kitöltés, kör, név)
  bool _showSources = true; // forrás-elhelyezések ikonjai
  bool _showDistances = true; // mentett mérővonalak és távolságcímkéik
  final Set<int> _hiddenAreaIds = {}; // egyenként elrejtett területek
  final Set<int> _hiddenLineIds = {}; // egyenként elrejtett mérővonalak

  @override
  void initState() {
    super.initState();
    HardwareButtons.register(_buttonHandler);
    _restoreView();
    _load();
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
      if (saved == true) _load();
    });
    return true;
  }

  /// Rajzolási és mérési módok egy menüben. A módok egymást kizárják, ezért
  /// a menüpontok a futó módtól függően tiltódnak.
  Widget _buildToolsMenu(AppLocalizations loc) {
    final busy = _draw != null;
    final active = busy || _measuring || _placingSourceId != null;
    ListTile item(IconData icon, String title) => ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon),
          title: Text(title),
        );
    return PopupMenuButton<_ToolAction>(
      tooltip: loc.mapToolsTooltip,
      icon: Icon(
        Icons.edit_outlined,
        color: active ? Theme.of(context).colorScheme.primary : null,
      ),
      onSelected: (action) {
        switch (action) {
          case _ToolAction.area:
            _startAreaDraw();
          case _ToolAction.measure:
            if (_measuring) {
              _stopMeasure();
            } else {
              _startMeasure();
            }
          case _ToolAction.source:
            if (_placingSourceId == null) {
              _showSourcePicker();
            } else {
              _cancelSourcePlacement();
            }
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _ToolAction.area,
          enabled: !busy && !_measuring,
          child: item(Icons.add_location_alt_outlined, loc.mapAreaButtonTooltip),
        ),
        PopupMenuItem(
          value: _ToolAction.measure,
          enabled: !busy,
          child: item(
            Icons.straighten,
            _measuring ? loc.mapMeasureStopTooltip : loc.mapMeasureTooltip,
          ),
        ),
        PopupMenuItem(
          value: _ToolAction.source,
          enabled: !busy && !_measuring,
          child: _placingSourceId == null
              ? item(Icons.warning_amber_rounded, loc.mapPlaceSourceTooltip)
              : item(Icons.close, loc.mapPlaceSourceCancelTooltip),
        ),
      ],
    );
  }

  /// Gyűjtő: egy elem rejtése vagy mutatása a halmazban.
  static void _setHidden(Set<int> hidden, int? id, bool hide) {
    if (id == null) return;
    if (hide) {
      hidden.add(id);
    } else {
      hidden.remove(id);
    }
  }

  /// Összes be/ki: ha bármi látszik, mindent elrejt; különben mindent mutat.
  static void _toggleAll(Iterable<int> ids, Set<int> hidden) {
    final list = ids.toList();
    final allShown = list.every((id) => !hidden.contains(id));
    hidden.clear();
    if (allShown) hidden.addAll(list);
  }

  Future<bool> _confirmAction(String message, String actionLabel) async {
    final loc = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  /// Mérővonal törlése a listából és az adatbázisból.
  Future<void> _deleteLine(MapMeasureLine line) async {
    setState(() {
      _lines.removeWhere((l) => identical(l, line));
      _selectedLine = null;
      _hiddenLineIds.remove(line.id);
    });
    _persistView();
    if (line.id != null) {
      await DatabaseHelper.instance.deleteMapMeasureLine(line.id!);
    }
  }

  /// A színezési legördülő elemei, forrásonként fejléccel (a fejléc értéke null,
  /// így kiválasztva sem változtat a színezésen).
  List<DropdownMenuItem<_ScaleKey?>> _scaleMenuItems(
      BuildContext context, List<_ScaleOption> options) {
    final loc = AppLocalizations.of(context)!;
    final items = <DropdownMenuItem<_ScaleKey?>>[];
    _ScaleSource? group;
    for (final o in options) {
      final src = o.key.source;
      if (src != group) {
        group = src;
        final header = switch (src) {
          _ScaleSource.typed => loc.mapScaleGroupTypes,
          _ScaleSource.meteo => MeasurementType.meteorology.label(context),
          _ScaleSource.gas => MeasurementType.gasMeasurement.label(context),
        };
        items.add(DropdownMenuItem<_ScaleKey?>(
          value: null,
          child: Text(header,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ));
      }
      items.add(DropdownMenuItem<_ScaleKey?>(
        value: o.key,
        child: Text('${o.label} (${o.unit})'),
      ));
    }
    return items;
  }

  /// Rétegek: megjelenítési chipek, jelölt területek és mérővonalak soronként
  /// (be-/kikapcsolás, törlés), és a színezett mennyiség legördülője. A két
  /// lista összecsukható, hogy sok elem esetén is átlátható maradjon a lap.
  void _showLayersSheet() {
    final options = _scaleOptions(context);
    // A fejléc-elem kiválasztásakor a mező újraépül, hogy ne maradjon rajta a fejléc.
    var scaleFieldEpoch = 0;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final loc = AppLocalizations.of(sheetContext)!;
          final theme = Theme.of(sheetContext).textTheme;
          final active = _activeOption(options);

          void changed(VoidCallback change) {
            setState(change);
            setSheet(() {});
            _persistView();
          }

          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              children: [
                Text(loc.mapLayersTooltip, style: theme.titleMedium),
                const SizedBox(height: 12),
                Text(loc.mapVisibilityTitle, style: theme.labelLarge),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    FilterChip(
                      label: Text(loc.mapPointsLayerTitle),
                      selected: _showPoints,
                      onSelected: (v) => changed(() => _showPoints = v),
                    ),
                    FilterChip(
                      label: Text(loc.mapAreasLayerTitle),
                      selected: _showAreas,
                      onSelected: (v) => changed(() => _showAreas = v),
                    ),
                    FilterChip(
                      label: Text(loc.mapSourcesLayerTitle),
                      selected: _showSources,
                      onSelected: (v) => changed(() => _showSources = v),
                    ),
                    FilterChip(
                      label: Text(loc.mapDistancesLayerTitle),
                      selected: _showDistances,
                      onSelected: (v) => changed(() => _showDistances = v),
                    ),
                    FilterChip(
                      label: Text(loc.mapInterpolationTitle),
                      selected: _showInterpolation,
                      onSelected: (v) => changed(() => _showInterpolation = v),
                    ),
                  ],
                ),
                const Divider(height: 24),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('${loc.mapAreaListTooltip} (${_areas.length})'),
                  children: [
                    if (_areas.isEmpty)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(loc.mapAreaNoAreas),
                      )
                    else
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => changed(() => _toggleAll(
                              _areas.map((a) => a.id).whereType<int>(),
                              _hiddenAreaIds)),
                          child: Text(loc.mapToggleAllLabel),
                        ),
                      ),
                    for (final a in _areas)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Color(a.colorArgb),
                          radius: 10,
                        ),
                        title: Text(a.name),
                        subtitle: Text(a.shape == MapAreaShape.polygon
                            ? loc.mapAreaPolygon
                            : loc.mapAreaCircle),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: !_hiddenAreaIds.contains(a.id),
                              onChanged: (v) => changed(
                                  () => _setHidden(_hiddenAreaIds, a.id, !v)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: loc.mapAreaDeleteTooltip,
                              onPressed: () async {
                                if (!await _confirmDeleteArea()) return;
                                await DatabaseHelper.instance
                                    .deleteMapArea(a.id!);
                                setState(() {
                                  _hiddenAreaIds.remove(a.id);
                                });
                                _persistView();
                                await _load();
                                if (sheetContext.mounted) setSheet(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title:
                      Text('${loc.mapDistancesLayerTitle} (${_lines.length})'),
                  children: [
                    if (_lines.isEmpty)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(loc.mapNoDistanceLines),
                      )
                    else
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => changed(() => _toggleAll(
                              _lines.map((l) => l.id).whereType<int>(),
                              _hiddenLineIds)),
                          child: Text(loc.mapToggleAllLabel),
                        ),
                      ),
                    for (final line in _lines)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Color(line.colorArgb),
                          radius: 10,
                        ),
                        title: Text(formatDistanceMeters(line.meters)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: !_hiddenLineIds.contains(line.id),
                              onChanged: (v) => changed(() =>
                                  _setHidden(_hiddenLineIds, line.id, !v)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: loc.mapLineDeleteTooltip,
                              onPressed: () async {
                                if (!await _confirmAction(
                                    loc.mapLineDeleteConfirm,
                                    loc.mapLineDeleteTooltip)) {
                                  return;
                                }
                                await _deleteLine(line);
                                if (sheetContext.mounted) setSheet(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const Divider(height: 24),
                if (options.isEmpty)
                  Text(loc.mapNoScalableValues)
                else ...[
                  DropdownButtonFormField<_ScaleKey?>(
                    key: ValueKey((scaleFieldEpoch, active?.key)),
                    isExpanded: true,
                    initialValue: active?.key,
                    decoration:
                        InputDecoration(labelText: loc.mapColorScaleTitle),
                    items: _scaleMenuItems(sheetContext, options),
                    onChanged: (v) {
                      if (v != null) {
                        changed(() => _scaleKey = v);
                      } else {
                        setSheet(() {
                          scaleFieldEpoch++;
                        });
                      }
                    },
                  ),
                  if (_showInterpolation)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(loc.mapInterpolationSubtitle,
                          style: theme.bodySmall),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  static String _viewKey(int sessionId) => 'map_view_$sessionId';

  static Set<int> _intSet(Object? raw) =>
      raw is List ? raw.whereType<int>().toSet() : <int>{};

  /// A térkép nézetének visszatöltése (rétegek és egyenként elrejtett elemek)
  /// munkamenetenként. A mentés ezen az eszközön marad.
  Future<void> _restoreView() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_viewKey(widget.surveySessionId));
    if (mounted && raw != null) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        setState(() {
          _showPoints = m['points'] as bool? ?? _showPoints;
          _showAreas = m['areas'] as bool? ?? _showAreas;
          _showSources = m['sources'] as bool? ?? _showSources;
          _showDistances = m['distances'] as bool? ?? _showDistances;
          _showInterpolation = m['interp'] as bool? ?? _showInterpolation;
          _hiddenAreaIds
            ..clear()
            ..addAll(_intSet(m['hiddenAreas']));
          _hiddenLineIds
            ..clear()
            ..addAll(_intSet(m['hiddenLines']));
        });
      } on Object {
        // Hibás vagy régi mentésnél marad az alapértelmezett nézet.
      }
    }
    _viewRestored = true;
  }

  /// A nézet mentése: a rétegek állapota és az egyenként elrejtett elemek.
  Future<void> _persistView() async {
    if (!_viewRestored) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _viewKey(widget.surveySessionId),
      jsonEncode({
        'points': _showPoints,
        'areas': _showAreas,
        'sources': _showSources,
        'distances': _showDistances,
        'interp': _showInterpolation,
        'hiddenAreas': _hiddenAreaIds.toList(),
        'hiddenLines': _hiddenLineIds.toList(),
      }),
    );
  }

  Future<void> _load() async {
    final points =
        await DatabaseHelper.instance.getMeasurementPoints(widget.surveySessionId);
    final areas =
        await DatabaseHelper.instance.getMapAreas(widget.surveySessionId);
    final lines = await DatabaseHelper.instance
        .getMapMeasureLines(widget.surveySessionId);
    final session =
        await DatabaseHelper.instance.getSurveySession(widget.surveySessionId);
    final plan = session?.mapMode == SurveyMapMode.plan
        ? session?.planCalibration
        : null;
    final sources = await DatabaseHelper.instance.getRadiationSources();
    final nuclidesBySource =
        await DatabaseHelper.instance.getNuclideNamesBySource();
    final placements = await DatabaseHelper.instance
        .getSurveyPlacements(widget.surveySessionId);
    if (!mounted) return;
    setState(() {
      _points = points.map(withCurrentDoseUnit).toList();
      _areas = areas;
      _lines = lines;
      _georef = plan == null ? null : PlanGeoref(plan);
      _sources = sources;
      _nuclidesBySource = nuclidesBySource;
      _placements = placements;
      _loading = false;
    });
  }

  /// A nem dózisteljesítmény mérések egyszínű ikonjai (ikon, szín).
  static const _kindStyle = <MeasurementType, (IconData, Color)>{
    MeasurementType.surfaceContamination: (Icons.texture, Colors.purple),
    MeasurementType.countRate: (Icons.flash_on, Colors.orange),
    MeasurementType.sample: (Icons.science, Colors.blueGrey),
    MeasurementType.meteorology: (Icons.thermostat, Colors.indigo),
    MeasurementType.gasMeasurement: (Icons.air, Colors.brown),
    MeasurementType.biological: (Icons.coronavirus, Colors.green),
    MeasurementType.activity: (Icons.radio_button_checked, Colors.deepOrange),
    MeasurementType.activityConcentration: (Icons.water_drop, Colors.lightBlue),
    MeasurementType.spectrum: (Icons.show_chart, Colors.pinkAccent),
  };

  MeasurementType _kindOf(MeasurementPoint p) =>
      mapKindOf(isSample: p.isSample, type: p.type);

  /// Színezhető típusok: a dózisteljesítmény mellett a számlálási és aktivitási
  /// mennyiségek. A mintavétel (isSample) nem kap színskálát.
  static const _typedScalable = <MeasurementType>{
    MeasurementType.doseRate,
    MeasurementType.countRate,
    MeasurementType.surfaceContamination,
    MeasurementType.activity,
    MeasurementType.activityConcentration,
  };

  /// A meteorológiai mezők közül a színezhetőek (a szélirány körkörös, nem skálázható).
  static final _meteoScaleKeys = [
    for (final k in kModbusMeteoUnits.keys)
      if (k != 'wind_direction_deg') k,
  ];

  static bool _isKerma(MeasurementPoint p) =>
      p.type == MeasurementType.doseRate && p.doseQuantity == 'kerma';

  static double? _meteoField(String key, Meteorology m) => switch (key) {
        'air_temperature_c' => m.airTemperatureC,
        'relative_humidity_pct' => m.relativeHumidityPct,
        'pressure_hpa' => m.pressureHpa,
        'wind_speed_ms' => m.windSpeedMs,
        'gust_ms' => m.gustMs,
        'precipitation_mm_h' => m.precipitationMmH,
        'solar_wm2' => m.solarWm2,
        'cloud_okta' => m.cloudOkta,
        'visibility_m' => m.visibilityM,
        'soil_moisture_pct' => m.soilMoisturePct,
        'aerosol_ug_m3' => m.aerosolUgM3,
        _ => null,
      };

  /// A térkép színezhető mennyiségei a felmérés pontjaiból: csak a ténylegesen
  /// előforduló típus+egység, meteorológiai mező és gázvegyület+egység párok.
  List<_ScaleOption> _scaleOptions(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final byKey = <_ScaleKey, _ScaleOption>{};
    void add(_ScaleKey key, String label) =>
        byKey.putIfAbsent(key, () => _ScaleOption(key, label));
    for (final p in _points) {
      if (p.isSample) continue;
      if (p.value != null && _typedScalable.contains(p.type) && !_isKerma(p)) {
        add(_ScaleKey(_ScaleSource.typed, p.type.name, p.unit),
            p.type.label(context));
      }
      final m = p.meteorology;
      if (m != null) {
        for (final k in _meteoScaleKeys) {
          if (_meteoField(k, m) != null) {
            add(_ScaleKey(_ScaleSource.meteo, k, kModbusMeteoUnits[k]!.first),
                modbusMeteoLabel(loc, k));
          }
        }
      }
      for (final g in p.gases) {
        add(_ScaleKey(_ScaleSource.gas, g.name, g.unit.symbol),
            localizedGasName(loc, g.name));
      }
    }
    return byKey.values.toList()
      ..sort((a, b) {
        final bySource = a.key.source.index.compareTo(b.key.source.index);
        if (bySource != 0) return bySource;
        final aDose = a.key.name == MeasurementType.doseRate.name ? 0 : 1;
        final bDose = b.key.name == MeasurementType.doseRate.name ? 0 : 1;
        if (aDose != bDose) return aDose.compareTo(bDose);
        return a.label.compareTo(b.label);
      });
  }

  /// A ténylegesen színezett mennyiség: a kiválasztott, vagy alapértelmezésben a
  /// dózisteljesítmény (ha van), különben az első elérhető.
  _ScaleOption? _activeOption(List<_ScaleOption> options) {
    if (options.isEmpty) return null;
    for (final o in options) {
      if (o.key == _scaleKey) return o;
    }
    return options.firstWhere(
      (o) =>
          o.key.source == _ScaleSource.typed &&
          o.key.name == MeasurementType.doseRate.name,
      orElse: () => options.first,
    );
  }

  /// Egy pont értéke a kiválasztott mennyiségből (null: nem színezhető).
  static double? _scaleValue(_ScaleKey k, MeasurementPoint p) {
    if (p.isSample) return null;
    if (k.source == _ScaleSource.typed) {
      if (p.type.name != k.name ||
          p.unit != k.unit ||
          p.value == null ||
          _isKerma(p)) {
        return null;
      }
      return p.value;
    }
    if (k.source == _ScaleSource.meteo) {
      final m = p.meteorology;
      return m == null ? null : _meteoField(k.name, m);
    }
    for (final g in p.gases) {
      if (g.name == k.name && g.unit.symbol == k.unit) return g.concentration;
    }
    return null;
  }

  List<(MeasurementPoint, double)> _scaleSamples(_ScaleKey key) {
    final out = <(MeasurementPoint, double)>[];
    for (final p in _points) {
      final v = _scaleValue(key, p);
      if (v != null) out.add((p, v));
    }
    return out;
  }

  static (double, double) _range(Iterable<double> values) {
    var lo = double.infinity;
    var hi = double.negativeInfinity;
    for (final v in values) {
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    return (lo, hi);
  }

  /// Zöld (legkisebb) → piros (legnagyobb) skála.
  static Color _scaleColor(double v, double lo, double hi) {
    final raw = hi == lo ? 0.5 : (v - lo) / (hi - lo);
    final t = raw < 0 ? 0.0 : (raw > 1 ? 1.0 : raw);
    return Color.lerp(Colors.green, Colors.red, t)!;
  }

  Map<int, Color> _computeColors(_ScaleKey? key) {
    final colors = <int, Color>{};
    if (key == null) return colors;
    final samples = _scaleSamples(key);
    if (samples.isEmpty) return colors;
    final (lo, hi) = _range(samples.map((s) => s.$2));
    for (final (p, v) in samples) {
      colors[p.id!] = _scaleColor(v, lo, hi);
    }
    return colors;
  }

  /// A becsült felület (IDW) cellái a kiválasztott mennyiségre. A számítás
  /// háttérszálon fut, így nem akasztja a térképet; amíg tart, nincs felület.
  /// Ha a pontlista vagy a mennyiség változik, a régi eredményt eldobja.
  List<Polygon> _interpolationPolygons(_ScaleKey key) {
    final ready = identical(_interpSource, _points) && _interpKey == key;
    final inFlight =
        identical(_interpJobSource, _points) && _interpJobKey == key;
    if (ready) return _interpPolys;
    if (!inFlight) _startInterpolation(key);
    return const [];
  }

  void _startInterpolation(_ScaleKey key) {
    final src = _points;
    final token = ++_interpToken;
    final grid = _idwPrepare(_scaleSamples(key));
    if (grid == null) {
      _interpSource = src;
      _interpKey = key;
      _interpPolys = const [];
      _interpJobSource = null;
      _interpJobKey = null;
      return;
    }
    _interpJobSource = src;
    _interpJobKey = key;
    compute(_idwRun, grid).then(
      (values) {
        if (!mounted || token != _interpToken) return;
        final polys = _idwPolygons(grid, values);
        setState(() {
          _interpSource = src;
          _interpKey = key;
          _interpPolys = polys;
          _interpJobSource = null;
          _interpJobKey = null;
        });
      },
      onError: (Object _, StackTrace _) {
        if (!mounted || token != _interpToken) return;
        setState(() {
          _interpSource = src;
          _interpKey = key;
          _interpPolys = const [];
          _interpJobSource = null;
          _interpJobKey = null;
        });
      },
    );
  }

  /// Az IDW-előkészítés: a mintapontok rácskoordinátái és a rács geometriája.
  /// A fő szálon fut, mert csak O(n) munka.
  static _IdwGrid? _idwPrepare(List<(MeasurementPoint, double)> samples) {
    if (samples.length < 3) return null;
    final lat0 = samples.map((s) => s.$1.latitude).reduce((a, b) => a + b) /
        samples.length;
    final lon0 = samples.map((s) => s.$1.longitude).reduce((a, b) => a + b) /
        samples.length;
    const mPerLat = 111320.0;
    final mPerLon = 111320.0 * math.cos(lat0 * math.pi / 180);
    final xs = [for (final s in samples) (s.$1.longitude - lon0) * mPerLon];
    final ys = [for (final s in samples) (s.$1.latitude - lat0) * mPerLat];
    final vs = [for (final s in samples) s.$2];
    final minX = xs.reduce((a, b) => a < b ? a : b);
    final maxX = xs.reduce((a, b) => a > b ? a : b);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final span = math.max(maxX - minX, maxY - minY);
    final cell = math.max(span / 50, 1.0);
    final nx = (maxX - minX) ~/ cell + 1;
    final ny = (maxY - minY) ~/ cell + 1;
    final (lo, hi) = _range(vs);
    return _IdwGrid(
      lat0: lat0,
      lon0: lon0,
      mPerLat: mPerLat,
      mPerLon: mPerLon,
      xs: xs,
      ys: ys,
      vs: vs,
      minX: minX,
      minY: minY,
      cell: cell,
      nx: nx,
      ny: ny,
      lo: lo,
      hi: hi,
    );
  }

  /// Az IDW-becslés rácsonként, háttérszálon. A NaN a mintától túl távoli cella.
  /// Csak a legközelebbi mérési ponthoz képest a pontsűrűségből adódó sugáron
  /// belüli cellák kapnak értéket, hogy a bejárt területen kívül ne legyen felület.
  static Float64List _idwRun(_IdwGrid g) {
    final cutoff = math.max(5.0, 3 * _medianNearest(g.xs, g.ys));
    final values = Float64List(g.nx * g.ny);
    for (var iy = 0; iy < g.ny; iy++) {
      for (var ix = 0; ix < g.nx; ix++) {
        final cx = g.minX + (ix + 0.5) * g.cell;
        final cy = g.minY + (iy + 0.5) * g.cell;
        var wSum = 0.0;
        var vSum = 0.0;
        var nearest = double.infinity;
        for (var i = 0; i < g.xs.length; i++) {
          final dx = g.xs[i] - cx;
          final dy = g.ys[i] - cy;
          final d2 = dx * dx + dy * dy + 1e-6;
          if (d2 < nearest) nearest = d2;
          final w = 1 / d2;
          wSum += w;
          vSum += w * g.vs[i];
        }
        values[iy * g.nx + ix] =
            math.sqrt(nearest) > cutoff ? double.nan : vSum / wSum;
      }
    }
    return values;
  }

  /// A háttérszámítás cellaértékeiből a színezett poligonok (fő szál).
  static List<Polygon> _idwPolygons(_IdwGrid g, Float64List values) {
    ll.LatLng at(double x, double y) =>
        ll.LatLng(g.lat0 + y / g.mPerLat, g.lon0 + x / g.mPerLon);
    final out = <Polygon>[];
    for (var iy = 0; iy < g.ny; iy++) {
      for (var ix = 0; ix < g.nx; ix++) {
        final v = values[iy * g.nx + ix];
        if (v.isNaN) continue;
        final cx = g.minX + (ix + 0.5) * g.cell;
        final cy = g.minY + (iy + 0.5) * g.cell;
        final x0 = cx - g.cell / 2;
        final x1 = cx + g.cell / 2;
        final y0 = cy - g.cell / 2;
        final y1 = cy + g.cell / 2;
        out.add(Polygon(
          points: [at(x0, y0), at(x1, y0), at(x1, y1), at(x0, y1)],
          color: _scaleColor(v, g.lo, g.hi).withValues(alpha: 0.45),
          borderStrokeWidth: 0,
          borderColor: Colors.transparent,
        ));
      }
    }
    return out;
  }

  /// A pontok legközelebbi-szomszéd távolságának mediánja (legfeljebb ~200 mintán).
  static double _medianNearest(List<double> xs, List<double> ys) {
    final n = xs.length;
    final step = math.max(1, n ~/ 200);
    final dists = <double>[];
    for (var i = 0; i < n; i += step) {
      var best = double.infinity;
      for (var j = 0; j < n; j++) {
        if (j == i) continue;
        final dx = xs[i] - xs[j];
        final dy = ys[i] - ys[j];
        final d = math.sqrt(dx * dx + dy * dy);
        if (d < best) best = d;
      }
      if (best.isFinite) dists.add(best);
    }
    if (dists.isEmpty) return 5.0;
    dists.sort();
    return dists[dists.length ~/ 2];
  }

  Widget _buildLegend(
      AppLocalizations loc, _ScaleOption? active, Map<int, Color> colors) {
    final others = <MeasurementType>{};
    if (_showPoints) {
      for (final p in _points) {
        if (!colors.containsKey(p.id)) others.add(_kindOf(p));
      }
    }
    final samples = active == null
        ? const <(MeasurementPoint, double)>[]
        : _scaleSamples(active.key);
    final hasScale = active != null &&
        samples.isNotEmpty &&
        (_showPoints || _showInterpolation);
    if (!hasScale && others.isEmpty) return const SizedBox.shrink();
    final (lo, hi) = _range(samples.map((s) => s.$2));
    String fmt(double v) => '${double.parse(v.toStringAsFixed(4))}';
    const style = TextStyle(fontSize: 11, color: Colors.black87);
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
          if (active != null && hasScale) ...[
            Text('${active.label} (${active.unit})',
                style: style.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Container(
              width: 160,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient:
                    const LinearGradient(colors: [Colors.green, Colors.red]),
              ),
            ),
            SizedBox(
              width: 160,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(fmt(lo), style: style),
                  Text(fmt(hi), style: style),
                ],
              ),
            ),
            if (_showInterpolation)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: LinearGradient(colors: [
                          Colors.green.withValues(alpha: 0.45),
                          Colors.red.withValues(alpha: 0.45),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(loc.mapInterpolationLegend, style: style),
                  ],
                ),
              ),
            const SizedBox(height: 4),
          ],
          for (final kind in others)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_kindStyle[kind]?.$1 ?? Icons.location_on,
                      color: _kindStyle[kind]?.$2 ?? Colors.blue, size: 16),
                  const SizedBox(width: 6),
                  Text(kind.label(context), style: style),
                ],
              ),
            ),
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

  /// A pont helye a részletekben: alaprajz módban a helyi X/Y (méter), egyébként a GPS.
  String _positionText(MeasurementPoint p) {
    final plan = _georef?.calibration;
    if (plan != null && plan.localCoordinates) {
      final m = planLocalMetres(plan, p.latitude, p.longitude);
      final loc = AppLocalizations.of(context)!;
      return '${loc.planLocalCoordLabel}: X ${m.x.toStringAsFixed(2)} m, '
          'Y ${m.y.toStringAsFixed(2)} m';
    }
    return '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
  }

  /// Azonos koordinátájú pontok (másolatok) csoportjai: egy jelölő, számlálóval.
  List<List<MeasurementPoint>> _pointGroups() {
    final byPos = <String, List<MeasurementPoint>>{};
    for (final p in _points) {
      byPos.putIfAbsent('${p.latitude}|${p.longitude}', () => []).add(p);
    }
    return byPos.values.toList();
  }

  Widget _countBadge(int n) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          '$n',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  /// Egy helyen készült mérések listája; tételre koppintva a részletek nyílnak.
  void _showGroupDetails(List<MeasurementPoint> group) {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                group.first.locationLabel ?? _positionText(group.first),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final p in group)
              ListTile(
                title: Text('${p.type.label(context)} · ${_dateFormat.format(p.timestamp)}'),
                subtitle: p.value == null
                    ? null
                    : Text(loc.valueLabel(
                        '${double.parse(displayValueOf(p).value!.toStringAsFixed(4))}',
                        displayValueOf(p).unit)),
                onTap: () {
                  Navigator.of(context).pop();
                  _showPointDetails(p);
                },
              ),
          ],
        ),
      ),
    );
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
                p.locationLabel ?? _positionText(p),
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
      if (_showDistances && _lines.isNotEmpty)
        PolylineLayer(polylines: [
          for (var i = 0; i < _lines.length; i++)
            if (!_hiddenLineIds.contains(_lines[i].id))
            Polyline(
              points: [_lines[i].a, _lines[i].b],
              strokeWidth: i == _selectedLine ? 6 : 3,
              color: Color(_lines[i].colorArgb),
            ),
        ]),
      MarkerLayer(markers: [
        if (_showDistances)
        for (var i = 0; i < _lines.length; i++)
          if (!_hiddenLineIds.contains(_lines[i].id)) ...[
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

  RadiationSource? _sourceById(int id) {
    for (final s in _sources) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Forrásikon: az ikon közepe a koppintott helyen van, az azonosító alatta.
  Marker _placedSourceMarker(SurveySourcePlacement pl) {
    if (_zoom < _sourceLabelMinZoom) {
      // Kis nagyításnál csak az ikon, hogy a feliratok ne takarják egymást.
      return Marker(
        point: ll.LatLng(pl.mapLat!, pl.mapLon!),
        width: 32,
        height: 32,
        child: GestureDetector(
          onTap: () => _showPlacedSourceDetails(pl),
          child: Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber.shade800,
            size: 28,
          ),
        ),
      );
    }
    final identifier = _sourceById(pl.radiationSourceId)?.identifier ?? '';
    const boxWidth = 160.0;
    const boxHeight = 72.0;
    const iconSize = 32.0;
    return Marker(
      point: ll.LatLng(pl.mapLat!, pl.mapLon!),
      width: boxWidth,
      height: boxHeight,
      child: GestureDetector(
        onTap: () => _showPlacedSourceDetails(pl),
        child: Stack(
          children: [
            // A doboz közepe a pont: az ikon közepe is ide kerül.
            Positioned(
              left: (boxWidth - iconSize) / 2,
              top: boxHeight / 2 - iconSize / 2,
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber.shade800,
                size: iconSize,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: boxHeight / 2 + iconSize / 2 + 2,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    identifier,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reloadPlacements() async {
    final placements = await DatabaseHelper.instance
        .getSurveyPlacements(widget.surveySessionId);
    if (!mounted) return;
    setState(() => _placements = placements);
  }

  void _cancelSourcePlacement() => setState(() => _placingSourceId = null);

  /// Forrásválasztó: a központi lista forrásai. A kiválasztott forrás helyét
  /// a következő koppintás adja meg.
  /// Forrásválasztó lap; a keresőmező vezérlőjét a lap saját állapota kezeli.
  void _showSourcePicker() {
    final placedIds = {
      for (final pl in _placements)
        if (pl.hasMapPosition) pl.radiationSourceId,
    };
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SourcePickerSheet(
        sources: _sources,
        nuclidesBySource: _nuclidesBySource,
        placedSourceIds: placedIds,
        onPick: (source) {
          setState(() => _placingSourceId = source.id);
          _snack(AppLocalizations.of(context)!.mapPlaceSourceHint);
        },
      ),
    );
  }

  /// A kiválasztott forrás helyének rögzítése: új elhelyezés, vagy a meglévő
  /// áthelyezése. Az elhelyezés a felmérés R-jébe is bekerül.
  Future<void> _placeSource(int sourceId, ll.LatLng p) async {
    final db = DatabaseHelper.instance;
    SurveySourcePlacement? existing;
    for (final pl in _placements) {
      if (pl.radiationSourceId == sourceId) existing = pl;
    }
    if (existing == null) {
      await db.insertSurveyPlacement(SurveySourcePlacement(
        surveySessionId: widget.surveySessionId,
        radiationSourceId: sourceId,
        mapLat: p.latitude,
        mapLon: p.longitude,
        createdAt: DateTime.now(),
      ));
    } else {
      await db.updateSurveyPlacement(
        existing.copyWith(mapLat: p.latitude, mapLon: p.longitude),
      );
    }
    if (!mounted) return;
    setState(() => _placingSourceId = null);
    await _reloadPlacements();
  }

  /// Részletek és műveletek: áthelyezés, pozíció törlése.
  void _showPlacedSourceDetails(SurveySourcePlacement pl) {
    final loc = AppLocalizations.of(context)!;
    final source = _sourceById(pl.radiationSourceId);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(source?.identifier ?? '—'),
        content: Text(
          source == null || source.nuclideName.isEmpty
              ? '—'
              : source.nuclideName,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              setState(() => _placingSourceId = pl.radiationSourceId);
            },
            child: Text(loc.mapSourceRelocate),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await DatabaseHelper.instance.updateSurveyPlacement(
                pl.copyWith(clearMapPosition: true),
              );
              await _reloadPlacements();
            },
            child: Text(loc.mapSourceClearPosition),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(loc.mapSourceDialogClose),
          ),
        ],
      ),
    );
  }

  void _onMapTap(ll.LatLng p) {
    final placingId = _placingSourceId;
    if (placingId != null) {
      _placeSource(placingId, p);
      return;
    }
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
    final scaleOptions = _scaleOptions(context);
    final activeScale = _activeOption(scaleOptions);
    final colors = _computeColors(activeScale?.key);
    final routePoints = _points.map((p) => ll.LatLng(p.latitude, p.longitude)).toList();
    final d = _draw;
    final previewColor = d == null ? Colors.blue : Color(d.draft.colorArgb);
    final previewRadius = d == null ? null : _previewRadius(d);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.mapTitle),
        actions: [
          _buildToolsMenu(loc),
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            tooltip: loc.mapLayersTooltip,
            color: _showInterpolation
                ? Theme.of(context).colorScheme.primary
                : null,
            onPressed: _showLayersSheet,
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
              initialCameraFit:
                  _georef == null ? null : planCameraFit(_georef!),
              onTap: (_, p) => _onMapTap(p),
              onMapReady: () {
                if (mounted) setState(() => _zoom = _mapController.camera.zoom);
              },
              onPositionChanged: (camera, _) {
                final wasShown = _zoom >= _sourceLabelMinZoom;
                _zoom = camera.zoom;
                if (wasShown != (_zoom >= _sourceLabelMinZoom)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() {});
                  });
                }
              },
            ),
            children: [
              if (_georef != null) planOverlayLayer(_georef!.calibration),
              if (_georef == null)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.rundhall.rad_recon',
                ),
              if (_showInterpolation && activeScale != null)
                PolygonLayer(
                  polygons: _interpolationPolygons(activeScale.key),
                ),
              // Területek: áttetsző kitöltés, teljes színű körvonal.
              if (_showAreas)
              PolygonLayer(
                polygons: [
                  for (final a in _areas)
                    if (!_hiddenAreaIds.contains(a.id))
                    if (a.shape == MapAreaShape.polygon && a.polygon.length >= 3)
                      Polygon(
                        points: [for (final v in a.polygon) ll.LatLng(v[0], v[1])],
                        color: Color(a.colorArgb).withValues(alpha: 0.3),
                        borderColor: Color(a.colorArgb),
                        borderStrokeWidth: 2,
                      ),
                ],
              ),
              if (_showAreas)
              CircleLayer(
                circles: [
                  for (final a in _areas)
                    if (!_hiddenAreaIds.contains(a.id))
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
              if (_georef == null)
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
              if (_showPoints && routePoints.length > 1)
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
              // Forrás-elhelyezések: külön ikon, koppintásra részletek.
              if (_showSources)
              MarkerLayer(
                markers: [
                  for (final pl in _placements)
                    if (pl.hasMapPosition) _placedSourceMarker(pl),
                ],
              ),
              // Területek nevei a közepükön.
              if (_showAreas)
              MarkerLayer(
                markers: [
                  for (final a in _areas)
                    if (!_hiddenAreaIds.contains(a.id))
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
              if (_showPoints)
              MarkerLayer(
                markers: _pointGroups().map((group) {
                  final p = group.first;
                  // A csoport azon pontja, amelyiknek van színezhető értéke (ha van).
                  final rep = group.firstWhere(
                      (q) => colors.containsKey(q.id),
                      orElse: () => p);
                  final scaled = colors.containsKey(rep.id);
                  final kind = _kindOf(rep);
                  final style = _kindStyle[kind];
                  final color = scaled
                      ? colors[rep.id]!
                      : (style?.$2 ?? Colors.blue);
                  return Marker(
                    point: ll.LatLng(p.latitude, p.longitude),
                    width: 36,
                    height: 36,
                    child: GestureDetector(
                      // Rajzolás közben a pont nem nyit részletet, a koppintás a csúcs.
                      onTap: d == null && !_measuring
                          ? () => (group.length == 1
                              ? _showPointDetails(p)
                              : _showGroupDetails(group))
                          : null,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                      Icon(
                        p.isSourcePosition
                            ? Icons.warning_amber
                            : (scaled || kind == MeasurementType.doseRate
                                ? Icons.location_on
                                : (style?.$1 ?? Icons.location_on)),
                        color: color,
                        size: 34,
                        shadows: const [Shadow(color: Colors.black45, blurRadius: 3)],
                      ),
                        if (group.length > 1)
                          Positioned(right: -6, top: -6, child: _countBadge(group.length)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned(
              right: 8,
              bottom: 8,
              child: _buildLegend(loc, activeScale, colors)),
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

/// Forrásválasztó: kereső mező, azonosító- és nuklidszűrés, ABC-sorrend.
/// A keresőmező vezérlőjét ez az állapot szabadítja fel, nem a lap bezárása.
class _SourcePickerSheet extends StatefulWidget {
  final List<RadiationSource> sources;
  final Map<int, List<String>> nuclidesBySource;
  final Set<int> placedSourceIds;
  final ValueChanged<RadiationSource> onPick;

  const _SourcePickerSheet({
    required this.sources,
    required this.nuclidesBySource,
    required this.placedSourceIds,
    required this.onPick,
  });

  @override
  State<_SourcePickerSheet> createState() => _SourcePickerSheetState();
}

class _SourcePickerSheetState extends State<_SourcePickerSheet> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final matches = widget.sources
        .where((s) =>
            s.id != null &&
            sourceMatchesQuery(
              identifier: s.identifier,
              nuclides: widget.nuclidesBySource[s.id] ?? [s.nuclideName],
              query: _searchCtrl.text,
            ))
        .toList()
      ..sort((x, y) => x.identifier.compareTo(y.identifier));
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                loc.mapPlaceSourceTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: loc.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: widget.sources.isEmpty
                  ? Center(child: Text(loc.mapNoSources))
                  : matches.isEmpty
                      ? Center(child: Text(loc.searchNoResults))
                      : ListView.builder(
                          itemCount: matches.length,
                          itemBuilder: (context, i) {
                            final s = matches[i];
                            final nuclides =
                                (widget.nuclidesBySource[s.id] ?? [s.nuclideName])
                                    .where((n) => n.isNotEmpty)
                                    .toSet()
                                    .join(', ');
                            return ListTile(
                              leading: const Icon(Icons.warning_amber_rounded),
                              title: Text(s.identifier),
                              subtitle: Text(nuclides.isEmpty ? '—' : nuclides),
                              trailing: widget.placedSourceIds.contains(s.id)
                                  ? const Icon(Icons.check)
                                  : null,
                              onTap: () {
                                Navigator.of(context).pop();
                                widget.onPick(s);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
