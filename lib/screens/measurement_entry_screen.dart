import '../models/bio_agent.dart';
import '../services/plan_georeference.dart';
import '../models/survey_session.dart';
import '../models/plan_calibration.dart';
import '../models/radiation_kind.dart';
import '../models/dose_quantity.dart';
import '../models/count_rate_unit.dart';
import '../services/last_measurement_type.dart';
import '../services/basis_unit_controller.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import 'package:image_picker/image_picker.dart';
import '../models/hardware_button.dart';
import '../services/hardware_buttons.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:file_selector/file_selector.dart' as fs;

import '../widgets/distance_echo.dart';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/calibration_labels.dart';
import '../models/instrument.dart';
import '../models/instrument_calibration.dart';
import '../models/isotope.dart';
import '../models/measurement_point.dart';
import '../models/measurement_type.dart';
import '../models/nuclide_id.dart';
import '../models/point_source_link.dart';
import '../l10n/domain_labels.dart';
import '../models/gas_reading.dart';
import '../models/concentration_unit.dart';
import '../models/meteorology.dart';
import '../models/sample_unit.dart';
import '../models/shielding.dart';
import '../models/shielding_labels.dart';
import '../models/distance_unit.dart';
import '../services/display_units.dart';
import '../models/dose_rate_unit.dart';
import '../services/activity_estimate.dart';
import '../services/number_input.dart';
import '../services/dose_unit_controller.dart';
import '../services/dose_unit_converter.dart';
import '../services/modbus_reader_service.dart';
import '../services/unit_format.dart';
import '../models/activity_origin.dart';
import '../services/found_source_builder.dart';
import 'found_source_entry_screen.dart';
import '../services/settings_service.dart';
import '../services/value_averager.dart';
import '../widgets/position_averaging_dialog.dart';
import '../widgets/spectrum_chart.dart';
import '../services/spectrum_service.dart';
import '../models/spectrum.dart';
import '../models/activity_unit.dart';
import '../models/activity_concentration.dart';
import '../widgets/disclaimer_info_icon.dart';
import '../widgets/nuclide_id_section.dart';
import '../widgets/quantity_field.dart';
import 'instrument_entry_screen.dart';
import 'map_point_picker_screen.dart';
import 'point_source_link_screen.dart';

/// Kerekít és levágja a felesleges záró nullákat (pl. float32 műszerértékhez).
String _fmt(double v, int decimals) =>
    double.parse(v.toStringAsFixed(decimals)).toString();

/// Egy új mérési pont felvétele terepen.
///
/// A pozíció alapértelmezetten a telefon GPS-éből töltődik, de mivel a
/// mérés helye nem mindig egyezik a telefon tényleges tartózkodási helyével
/// (beltéri mérés, vagy utólagos/máshol történő rögzítés), a koordináták
/// kézzel is szerkeszthetők, illetve térképről is kiválaszthatók.
class MeasurementEntryScreen extends StatefulWidget {
  final int surveySessionId;
  final MeasurementPoint? existingPoint; // nem null: szerkesztés
  final MeasurementPoint? templatePoint; // nem null: másolat ennek alapján

  const MeasurementEntryScreen({
    super.key,
    required this.surveySessionId,
    this.existingPoint,
    this.templatePoint,
  });

  @override
  State<MeasurementEntryScreen> createState() => _MeasurementEntryScreenState();
}

class _MeasurementEntryScreenState extends State<MeasurementEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ButtonCommandHandler _buttonHandler = _onButtonCommand;
  bool _lastSaveOk = false;
  DateTime? _discardArmedAt;

  MeasurementType _type = MeasurementType.doseRate;
  final _locationLabelCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _distanceCtrl = TextEditingController();
  DistanceUnit _distanceUnit = DistanceUnitController.current;
  final _notesCtrl = TextEditingController();

  final _sampleContainerCtrl = TextEditingController();
  final _sampleAmountCtrl = TextEditingController();
  final _sampleMethodCtrl = TextEditingController();
  final _sampleUnitCtrl = TextEditingController();
  SampleUnit? _sampleUnit;

  // Aktivitás és aktivitáskoncentráció.
  ActivityUnit _concActivityUnit = ActivityUnitController.current;
  BasisUnit _basisUnit = BasisUnitController.of(BasisKind.mass);
  final _basisAmountCtrl = TextEditingController();
  final _calcActivityCtrl = TextEditingController();
  ActivityUnit _calcActivityUnit = ActivityUnitController.current;
  String? _valueTypedText;

  // Spektrum: az app-mappában tárolt N42 másolat és a beolvasott adatok.
  String? _spectrumPath;
  String? _spectrumFileName;
  SpectrumKind _spectrumKind = SpectrumKind.gamma;
  Spectrum? _spectrum;
  bool _spectrumLog = false;
  List<NuclideActivity> _spectrumNuclideActivities = const [];

  // Sugárzás típusa (dózisteljesítmény és beütésszám), mennyiség és mélység.
  RadiationKind _radiation = RadiationKind.gamma;
  DoseQuantity _doseQuantity = DoseQuantity.h10;
  double? _doseDepthMm;

  // Meteorológia (opcionális, bármelyik mező üres maradhat).
  static const _metKeys = [
    'temp', 'humidity', 'pressure', 'wind', 'windDir', 'gust', 'precip',
    'solar', 'cloud', 'visibility', 'soil', 'aerosol',
  ];
  final Map<String, TextEditingController> _metCtrls = {
    for (final k in _metKeys) k: TextEditingController(),
  };
  final _metOtherCtrl = TextEditingController();
  PrecipitationState? _precipitation;

  // Gázmérés: tetszőleges számú vegyület egy mérési ponton.
  final List<_GasEdit> _gases = [];
  final List<_GasEdit> _discardedGases = [];
  final List<_BioEdit> _bios = [];
  final List<_BioEdit> _discardedBios = [];

  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();
  double? _gpsAccuracy;
  bool _isFetchingGps = false;
  bool _positionManuallySet = false;

  bool _isSourcePosition = false;
  bool _isSample = false;
  /// Nyitott-e a felmérés (lezárt felmérésből nem törölhető pont).
  bool _sessionOpen = false;

  int? _instrumentId;
  List<Instrument> _instruments = [];
  bool _isQueryingModbus = false;

  // Mérési hiba (±) és átlagolt Modbus-mérés.
  final _errorCtrl = TextEditingController();
  /// Az utoljára kézzel beírt hibaérték (lásd QuantityField).
  String? _errorTypedText;
  int? _avgSamples;
  int? _avgSeconds;
  int _avgDuration = 60;
  bool _isAveraging = false;
  bool _avgStop = false; // "Kész": az eddigi mintákat elfogadjuk
  bool _avgAbort = false; // "Mégse": eldobjuk
  int _avgElapsed = 0;
  final List<double> _avgValues = [];

  String? _photoPath;

  List<AttachedSource> _attachedSources = [];

  /// A ténylegesen mentett pont — kezdetben `widget.existingPoint`, de új
  /// pont esetén is felveszi az értéket, amint forrás hozzárendeléséhez
  /// (vagy a "Mentés" gombbal) először elmentjük az adatbázisba. Ettől
  /// kezdve a "Mentés" már frissít, nem duplikálja a pontot. A képernyő
  /// címe (új/szerkesztés) továbbra is `widget.existingPoint` alapján dönt,
  /// hogy ne változzon meg a felhasználó szeme láttára.
  MeasurementPoint? _editingPoint;

  /// A "forrás távolság" mező melletti nuklidválasztó — a mért értékből
  /// visszafelé számolt aktivitáshoz (nem mentett forrás, csak gyors
  /// becslés). Alapértelmezés: Cs-137.

  // Nuklid-azonosítás
  NuclideIdStatus _nuclideStatus = NuclideIdStatus.notSpecified;
  List<String> _nuclides = [];

  // Opcionális árnyékolás (anyag + vastagság) az árnyékolt forrás aktivitásához.
  final List<_LayerEdit> _layers = [];

  late Future<void> _sessionFuture;
  PlanCalibration? _plan; // alaprajz mód: a felmérés kalibrált alaprajza

  @override
  void initState() {
    super.initState();
    HardwareButtons.register(_buttonHandler);
    _editingPoint = widget.existingPoint;
    if (_editingPoint == null) {
      // Új pont: az utoljára használt mérési típussal indul.
      _type = LastMeasurementTypeController.current;
      _isSample = _type == MeasurementType.sample;
    }
    _unitCtrl.text = _displayUnitFor(_type);
    _loadInstruments();
    _sessionFuture = _loadSessionState();
    if (_editingPoint != null) {
      _prefillFromExisting(_editingPoint!);
      _loadAttachedSources();
    } else if (widget.templatePoint != null) {
      _prefillCopyMetadata(widget.templatePoint!);
      _loadTemplateSources();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Alaprajz módban nincs automatikus GPS-kitöltés: a pozíciót az alaprajz adja.
        _sessionFuture.then((_) {
          if (mounted && _plan == null) _fetchGpsPosition();
        });
      });
    }
  }

  Future<void> _loadSessionState() async {
    final session =
        await DatabaseHelper.instance.getSurveySession(widget.surveySessionId);
    if (!mounted) return;
    setState(() {
      _sessionOpen = session != null && !session.isClosed;
      _plan = session?.mapMode == SurveyMapMode.plan
          ? session?.planCalibration
          : null;
    });
  }

  /// Mérési pont törlése megerősítés után, csak nyitott felmérésben.
  Future<void> _confirmDeletePoint() async {
    final loc = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deletePointTitle),
        content: Text(loc.deletePointBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.deleteButton),
          ),
        ],
      ),
    );
    final id = _editingPoint?.id;
    if (ok != true || id == null || !mounted) return;
    await DatabaseHelper.instance.deleteMeasurementPoint(id);
    if (mounted) Navigator.of(context).pop(true);
  }

  /// Másolat: a hely és a mérőbeállítások átkerülnek (eszköz, nuklidok,
  /// árnyékolás, távolság, sugárzás- és dózis-beállítás). A mért érték, a
  /// mintavétel, a spektrum, a fotó, a gázok és a meteorológia üres marad.
  void _prefillCopyMetadata(MeasurementPoint t) {
    _locationLabelCtrl.text = t.locationLabel ?? '';
    _latCtrl.text = _fmt(t.latitude, 6);
    _lonCtrl.text = _fmt(t.longitude, 6);
    _gpsAccuracy = t.gpsAccuracyMeters;
    _isSourcePosition = t.isSourcePosition;
    _instrumentId = t.instrumentId;
    _nuclideStatus = t.nuclideStatus;
    _nuclides = [...t.nuclides];
    for (final l in t.shieldingLayers) {
      final e = _LayerEdit(l.material);
      e.ctrl.text = QuantityField.formatNumber(e.unit.fromMeters(l.thicknessCm / 100));
      _layers.add(e);
    }
    _distanceCtrl.text = t.distanceFromSourceMeters == null
        ? ''
        : QuantityField.formatNumber(
            _distanceUnit.fromMeters(t.distanceFromSourceMeters!));
    _radiation = RadiationKind.fromDbValue(t.radiationKind);
    _doseQuantity = DoseQuantity.fromDbValue(t.doseQuantity);
    _doseDepthMm = t.doseDepthMm;
    _notesCtrl.text = t.notes ?? '';
    if (t.isSample || t.type == MeasurementType.biological) {
      // Minta vagy biológiai pont másolata megtartja a típusát, hogy az elemzések látszanak.
      _type = t.type;
      _isSample = t.isSample;
      _unitCtrl.text = _displayUnitFor(_type);
    }
    if (t.isSample) {
      _sampleContainerCtrl.text = t.sampleContainerId ?? '';
      _sampleAmountCtrl.text = t.sampleAmount?.toString() ?? '';
      _sampleUnit = SampleUnit.matchStored(t.sampleUnit);
      if (_sampleUnit == SampleUnit.other) _sampleUnitCtrl.text = t.sampleUnit ?? '';
      _sampleMethodCtrl.text = t.sampleMethod ?? '';
    }
  }

  void _prefillFromExisting(MeasurementPoint p) {
    _type = p.type;
    _locationLabelCtrl.text = p.locationLabel ?? '';
    final isSurface = p.type == MeasurementType.surfaceContamination;
    _valueCtrl.text = p.value == null
        ? ''
        : _fmt(isSurface ? DisplayUnits.surfaceFromCanonical(p.value!) : p.value!, 4);
    _errorCtrl.text = p.valueError == null
        ? ''
        : QuantityField.formatNumber(
            isSurface ? DisplayUnits.surfaceFromCanonical(p.valueError!) : p.valueError!);
    _avgSamples = p.averagingSamples;
    _avgSeconds = p.averagingSeconds;
    _unitCtrl.text = isSurface ? DisplayUnits.surface.value : p.unit;
    _distanceCtrl.text = p.distanceFromSourceMeters == null
        ? ''
        : QuantityField.formatNumber(
            _distanceUnit.fromMeters(p.distanceFromSourceMeters!));
    _nuclideStatus = p.nuclideStatus;
    _nuclides = [...p.nuclides];
    for (final l in p.shieldingLayers) {
      final e = _LayerEdit(l.material);
      e.ctrl.text = QuantityField.formatNumber(e.unit.fromMeters(l.thicknessCm / 100));
      _layers.add(e);
    }
    _notesCtrl.text = p.notes ?? '';
    _sampleContainerCtrl.text = p.sampleContainerId ?? '';
    _sampleAmountCtrl.text = p.sampleAmount?.toString() ?? '';
    _sampleUnit = SampleUnit.matchStored(p.sampleUnit);
    if (_sampleUnit == SampleUnit.other) _sampleUnitCtrl.text = p.sampleUnit ?? '';
    _sampleMethodCtrl.text = p.sampleMethod ?? '';
    if (p.type == MeasurementType.activityConcentration) {
      final parts = p.unit.split('/');
      if (parts.length == 2) {
        _concActivityUnit = ActivityUnit.values.firstWhere(
          (u) => u.symbol == parts[0],
          orElse: () => ActivityUnitController.current,
        );
      }
    }
    _basisUnit = BasisUnit.fromSymbol(p.basisUnit) ?? _basisUnit;
    _basisAmountCtrl.text = p.basisAmount == null
        ? ''
        : QuantityField.formatNumber(p.basisAmount!);
    _spectrumPath = p.spectrumPath;
    _spectrumFileName = p.spectrumFileName;
    _spectrumKind = SpectrumKind.fromDbValue(p.spectrumKind);
    _spectrumNuclideActivities = NuclideActivity.listFromJson(p.spectrumActivityJson);
    _radiation = RadiationKind.fromDbValue(p.radiationKind);
    _doseQuantity = DoseQuantity.fromDbValue(p.doseQuantity);
    _doseDepthMm = p.doseDepthMm;
    final spectrumPath = p.spectrumPath;
    if (spectrumPath != null) {
      SpectrumService.load(spectrumPath).then((s) {
        if (mounted) setState(() => _spectrum = s);
      });
    }
    _latCtrl.text = _fmt(p.latitude, 6);
    _lonCtrl.text = _fmt(p.longitude, 6);
    _gpsAccuracy = p.gpsAccuracyMeters;
    _isSourcePosition = p.isSourcePosition;
    _isSample = p.isSample;
    _instrumentId = p.instrumentId;
    _photoPath = p.photoPath;

    final mv = p.meteorology;
    if (mv != null) {
      void setMet(String key, double? v) {
        if (v != null) _metCtrls[key]!.text = _fmt(v, 2);
      }

      setMet('temp', DisplayUnits.tempFromC(mv.airTemperatureC));
      setMet('humidity', mv.relativeHumidityPct);
      setMet('pressure', DisplayUnits.pressureFromHpa(mv.pressureHpa));
      setMet('wind', DisplayUnits.windFromMs(mv.windSpeedMs));
      setMet('windDir', mv.windDirectionDeg);
      setMet('gust', DisplayUnits.windFromMs(mv.gustMs));
      setMet('precip', mv.precipitationMmH);
      setMet('solar', mv.solarWm2);
      setMet('cloud', mv.cloudOkta);
      setMet('visibility', mv.visibilityM);
      setMet('soil', mv.soilMoisturePct);
      setMet('aerosol', mv.aerosolUgM3);
      _precipitation = mv.precipitation;
      _metOtherCtrl.text = mv.other ?? '';
    }
    for (final g in p.gases) {
      final known = gasSpecies.any((s) => s.name == g.name);
      final e = _GasEdit(
        species: known ? g.name : otherGasName,
        unit: g.unit,
        state: g.state,
      );
      if (!known) {
        e.nameCtrl.text = g.name;
        e.formulaCtrl.text = g.formula;
      }
      e.concCtrl.text = _fmt(g.concentration, 4);
      _gases.add(e);
    }
    for (final b in p.bioAgents) {
      final e = _BioEdit(kind: b.kind);
      e.nameCtrl.text = b.name;
      e.quantityCtrl.text = b.quantity;
      _bios.add(e);
    }
  }

  Future<void> _loadInstruments() async {
    final instruments = await DatabaseHelper.instance.getInstruments();
    if (!mounted) return;
    setState(() => _instruments = instruments);
  }

  /// Másolatnál a sablon forrásai már látszanak; mentéskor átmásolódnak.
  Future<void> _loadTemplateSources() async {
    final id = widget.templatePoint?.id;
    if (id == null) return;
    final attached = await DatabaseHelper.instance.getAttachedSources(id);
    if (!mounted) return;
    setState(() => _attachedSources = attached);
  }

  Future<void> _loadAttachedSources() async {
    final id = _editingPoint?.id;
    if (id == null) return;
    final attached = await DatabaseHelper.instance.getAttachedSources(id);
    if (!mounted) return;
    setState(() => _attachedSources = attached);
  }

  /// Az aktivitás-becsléshez használt nuklid: csak akkor van, ha az azonosítás
  /// "Azonosított" és pontosan egy nuklid van kiválasztva.
  String? get _estimationNuclide =>
      _nuclideStatus == NuclideIdStatus.identified && _nuclides.length == 1
          ? _nuclides.first
          : null;

  /// Az érvényes (pozitív vastagságú) árnyékoló rétegek.
  List<ShieldingLayer> _validLayers() {
    final out = <ShieldingLayer>[];
    for (final e in _layers) {
      final v = parseDecimal(e.ctrl.text);
      if (v != null && v > 0) {
        out.add(ShieldingLayer(e.material, e.unit.toMeters(v) * 100));
      }
    }
    return out;
  }

  /// A "forrás távolság" mező értéke méterben (a választott egységből).
  double? _distanceMeters() {
    final v = parseDecimal(_distanceCtrl.text);
    return v == null ? null : _distanceUnit.toMeters(v);
  }

  /// Talált forrás felvétele a mérésből. Új pontot előbb ment, hogy legyen
  /// azonosítója a hozzárendeléshez.
  Future<void> _startFoundSource(List<FoundNuclideDraft> nuclides) async {
    final point = await _ensureSavedForSourceLink();
    if (point == null || !mounted) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FoundSourceEntryScreen(
          measurementPoint: point,
          initialNuclides: nuclides,
          initialDistanceMeters: _distanceMeters(),
        ),
      ),
    );
    if (saved == true) _loadAttachedSources();
  }

  Future<void> _openSources() async {
    final point = await _ensureSavedForSourceLink();
    if (point == null || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PointSourceLinkScreen(
              measurementPoint: point,
              initialDistanceMeters: _distanceMeters(),
            ),
      ),
    );
    _loadAttachedSources();
  }

  String _formatValue(double v) {
    if (v.abs() >= 1000 || (v != 0 && v.abs() < 0.01)) {
      return v.toStringAsExponential(3);
    }
    return v.toStringAsFixed(3);
  }

  /// Az adott ponthoz rendelt források összesített, számított
  /// dózisteljesítménye (µSv/h) a mérés időpontjára visszaszámolva — ez
  /// vethető össze a ponton tényleg mért értékkel. A második elem azt
  /// mondja meg, hány hozzárendelt forrás nuklidja nem ismert (ezért nem
  /// szerepel az összegben).
  (double, int) _totalCalculatedDoseRateUSvH(DateTime asOf) {
    double total = 0;
    int unknownCount = 0;
    for (final attached in _attachedSources) {
      final isotope = attached.source.knownIsotope;
      final decayed = attached.source.decayedActivityMBqAt(asOf);
      if (isotope == null || decayed == null) {
        unknownCount++;
        continue;
      }
      total += isotope.doseRateAt(
        activityMBq: decayed,
        distanceM: attached.link.distanceMeters,
      );
    }
    return (total, unknownCount);
  }

  /// A mért érték, a "forrás távolság" mező és a kiválasztott nuklid
  /// gamma-állandója alapján visszafelé számolt aktivitás — nem tartozik
  /// mentett forráshoz, csak gyors becslés. Null, ha a bemenetek nem
  /// elégségesek, vagy a mértékegység nem alakítható µSv/h-ra.
  /// Sugárzás választó (dózisteljesítmény és beütésszám). Beütésszámnál a
  /// neutron-sugárzás az "n" előtagos egységet (ncps…) adja.
  List<Widget> _buildRadiationSelector(AppLocalizations loc) {
    return [
      DropdownButtonFormField<RadiationKind>(
        key: ValueKey('radiation-${_radiation.name}'),
        initialValue: _radiation,
        isExpanded: true,
        decoration: InputDecoration(labelText: loc.radiationKindLabel),
        items: [
          for (final r in RadiationKind.values)
            DropdownMenuItem<RadiationKind>(
              value: r,
              child: Text(r.localized(loc)),
            ),
        ],
        onChanged: (r) {
          if (r == null) return;
          setState(() {
            _radiation = r;
            if (_type == MeasurementType.countRate) {
              final base = CountRateOption.fromSymbol(_unitCtrl.text)?.unit ??
                  CountRateUnit.perSecond;
              _unitCtrl.text =
                  CountRateOption(base, r == RadiationKind.neutron).symbol;
            }
          });
        },
      ),
      const SizedBox(height: 12),
    ];
  }

  /// Dózisteljesítmény mennyisége és (Hp(d), H'(d,Ω) esetén) mélysége.
  List<Widget> _buildDoseQuantitySelectors(AppLocalizations loc) {
    final depths = _doseQuantity.depthOptionsMm;
    return [
      DropdownButtonFormField<DoseQuantity>(
        key: ValueKey('dose-quantity-${_doseQuantity.dbValue}'),
        initialValue: _doseQuantity,
        isExpanded: true,
        decoration: InputDecoration(labelText: loc.doseQuantityLabel),
        items: [
          for (final q in DoseQuantity.values)
            DropdownMenuItem<DoseQuantity>(
              value: q,
              child: Text(q.localized(loc)),
            ),
        ],
        onChanged: (q) {
          if (q != null) _changeDoseQuantity(q);
        },
      ),
      const SizedBox(height: 12),
      if (depths.isNotEmpty) ...[
        DropdownButtonFormField<double>(
          key: ValueKey(
              'dose-depth-${_doseQuantity.dbValue}-${_doseDepthMm ?? 0}'),
          initialValue: depths.contains(_doseDepthMm) ? _doseDepthMm : depths.first,
          isExpanded: true,
          decoration: InputDecoration(labelText: loc.doseDepthLabel),
          items: [
            for (final d in depths)
              DropdownMenuItem<double>(value: d, child: Text(_depthText(d))),
          ],
          onChanged: (d) => setState(() => _doseDepthMm = d),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  String _depthText(double d) => d == d.roundToDouble()
      ? '${d.toStringAsFixed(0)} mm'
      : '${d.toString().replaceAll('.', ',')} mm';

  /// Mennyiségváltás. A H és a K között nincs átszámítás: ilyenkor az érték
  /// és az egység is törlődik, hogy ne lehessen csendben átcímkézni.
  void _changeDoseQuantity(DoseQuantity q) {
    final wasKerma = _doseQuantity == DoseQuantity.kerma;
    final isKerma = q == DoseQuantity.kerma;
    setState(() {
      _doseQuantity = q;
      _doseDepthMm = q.depthOptionsMm.isEmpty
          ? null
          : (q.defaultDepthMm ?? q.depthOptionsMm.first);
      if (wasKerma != isKerma) {
        _unitCtrl.text = isKerma
            ? KermaRateUnit.defaultUnit.symbol
            : DoseUnitController.current.symbol;
        _valueCtrl.clear();
      }
    });
  }

  /// Légkerma (K): saját Gy/h-család egységekkel.
  Widget _buildKermaValueField(AppLocalizations loc) {
    return QuantityField<KermaRateUnit>(
      controller: _valueCtrl,
      label: loc.measuredValueLabel,
      units: KermaRateUnit.values,
      unit: KermaRateUnit.fromSymbol(_unitCtrl.text),
      onUnitChanged: (u) => setState(() => _unitCtrl.text = u.symbol),
      onChanged: () => setState(() {}),
      validator: _numberValidator(loc),
    );
  }

  /// Beütésszám: a sugárzás szerinti egységlista (neutronnál ncps…).
  Widget _buildCountRateValueField(AppLocalizations loc) {
    final neutron = _radiation == RadiationKind.neutron;
    final units = CountRateOption.forRadiation(neutron: neutron);
    final base = CountRateOption.fromSymbol(_unitCtrl.text)?.unit ??
        CountRateUnit.perSecond;
    return QuantityField<CountRateOption>(
      controller: _valueCtrl,
      label: loc.measuredValueLabel,
      units: units,
      unit: units.firstWhere((o) => o.unit == base),
      onUnitChanged: (u) => setState(() => _unitCtrl.text = u.symbol),
      onChanged: () => setState(() {}),
      validator: _numberValidator(loc),
    );
  }

  bool get _isActivityKind =>
      _type == MeasurementType.activity ||
      _type == MeasurementType.activityConcentration;

  ActivityUnit _activityUnitFromCtrl() => ActivityUnit.values.firstWhere(
        (u) => u.symbol == _unitCtrl.text.trim(),
        orElse: () => ActivityUnitController.current,
      );

  String? Function(String?) _numberValidator(AppLocalizations loc) => (v) {
        if (v == null || v.trim().isEmpty) return loc.requiredFieldError;
        if (parseDecimal(v) == null) return loc.numberRequiredError;
        return null;
      };

  /// Aktivitás: szám + egység (zárt lista), egységváltáskor átszámol.
  Widget _buildActivityValueField(AppLocalizations loc) {
    return QuantityField<ActivityUnit>(
      controller: _valueCtrl,
      label: loc.measuredValueLabel,
      units: ActivityUnit.values,
      unit: _activityUnitFromCtrl(),
      onUnitChanged: (u) => setState(() {
        final old = _activityUnitFromCtrl();
        final err = parseDecimal(_errorCtrl.text);
        final typedError =
            _errorTypedText != null && _errorCtrl.text == _errorTypedText;
        if (err != null && !typedError) {
          _errorCtrl.text = QuantityField.formatNumber(old.convertTo(u, err));
        }
        _unitCtrl.text = u.symbol;
      }),
      onChanged: () => setState(() {}),
      validator: _numberValidator(loc),
    );
  }

  /// Egységváltás az aktivitáskoncentrációnál: a kézzel beírt szám marad,
  /// a programmal kitöltött érték átszámolódik.
  void _changeConcentrationUnits({ActivityUnit? activity, BasisUnit? basis}) {
    final newActivity = activity ?? _concActivityUnit;
    final newBasis = basis ?? _basisUnit;
    final factor = concentrationConversionFactor(
      fromActivity: _concActivityUnit,
      fromBasis: _basisUnit,
      toActivity: newActivity,
      toBasis: newBasis,
    );
    setState(() {
      final typed =
          _valueTypedText != null && _valueCtrl.text == _valueTypedText;
      _valueCtrl.text = unitChangeText(
        text: _valueCtrl.text,
        typedByUser: typed,
        fromBase: factor,
        toBase: 1,
      );
      _concActivityUnit = newActivity;
      _basisUnit = newBasis;
    });
  }

  /// Aktivitáskoncentráció: aktivitás-egység, minta alapja (tömeg/térfogat/
  /// felület) és mennyiségi egység külön választható; a mennyiség a mezőben
  /// van, a koncentrációt a számláló szekcióból lehet kiszámolni.
  Widget _buildConcentrationValueField(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<ActivityUnit>(
                key: ValueKey('conc-act-${_concActivityUnit.symbol}'),
                initialValue: _concActivityUnit,
                isExpanded: true,
                decoration: InputDecoration(labelText: loc.activityPlainLabel),
                items: [
                  for (final u in ActivityUnit.values)
                    DropdownMenuItem<ActivityUnit>(
                      value: u,
                      child: Text(u.symbol),
                    ),
                ],
                onChanged: (u) {
                  if (u != null) _changeConcentrationUnits(activity: u);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<BasisKind>(
                key: ValueKey('conc-kind-${_basisUnit.kind.name}'),
                initialValue: _basisUnit.kind,
                isExpanded: true,
                decoration: InputDecoration(labelText: loc.basisKindLabel),
                items: [
                  for (final k in BasisKind.values)
                    DropdownMenuItem<BasisKind>(
                      value: k,
                      child: Text(k.localized(loc)),
                    ),
                ],
                onChanged: (k) {
                  if (k != null) {
                    _changeConcentrationUnits(basis: BasisUnitController.of(k));
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<BasisUnit>(
                key: ValueKey('conc-basis-${_basisUnit.symbol}'),
                initialValue: _basisUnit,
                isExpanded: true,
                decoration: InputDecoration(labelText: loc.unitLabel),
                items: [
                  for (final u in BasisUnit.ofKind(_basisUnit.kind))
                    DropdownMenuItem<BasisUnit>(
                      value: u,
                      child: Text(u.symbol),
                    ),
                ],
                onChanged: (u) {
                  if (u != null) _changeConcentrationUnits(basis: u);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _valueCtrl,
          decoration: InputDecoration(
            labelText: loc.measuredValueLabel,
            suffixText: concentrationSymbol(_concActivityUnit, _basisUnit),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: _numberValidator(loc),
          onChanged: (v) {
            _valueTypedText = v;
            setState(() {});
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _basisAmountCtrl,
          decoration: InputDecoration(
            labelText: '${loc.basisAmountLabel} (${_basisUnit.symbol})',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            final t = v?.trim() ?? '';
            if (t.isEmpty) return null;
            final n = parseDecimal(t);
            return (n == null || n <= 0) ? loc.numberRequiredError : null;
          },
          onChanged: (_) => setState(() {}),
        ),
        _buildConcentrationCalculator(loc),
      ],
    );
  }

  /// Koncentráció számítása: összes aktivitás ÷ minta mennyisége.
  Widget _buildConcentrationCalculator(AppLocalizations loc) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text(loc.concentrationCalcTitle),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _calcActivityCtrl,
                decoration: InputDecoration(
                  labelText: loc.concentrationTotalActivityLabel,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 118,
              child: DropdownButtonFormField<ActivityUnit>(
                key: ValueKey('calc-act-${_calcActivityUnit.symbol}'),
                initialValue: _calcActivityUnit,
                isExpanded: true,
                decoration: InputDecoration(labelText: loc.activityPlainLabel),
                items: [
                  for (final u in ActivityUnit.values)
                    DropdownMenuItem<ActivityUnit>(
                      value: u,
                      child: Text(u.symbol),
                    ),
                ],
                onChanged: (u) {
                  if (u != null) setState(() => _calcActivityUnit = u);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _applyConcentrationCalc,
          icon: const Icon(Icons.calculate_outlined),
          label: Text(loc.concentrationCalcButton),
        ),
      ],
    );
  }

  void _applyConcentrationCalc() {
    final loc = AppLocalizations.of(context)!;
    final total = parseDecimal(_calcActivityCtrl.text);
    final amount = parseDecimal(_basisAmountCtrl.text);
    if (total == null || total < 0 || amount == null || amount <= 0) {
      _showError(loc.concentrationCalcError);
      return;
    }
    final result = concentrationFrom(
      totalActivity: total,
      activityUnit: _calcActivityUnit,
      amount: amount,
      basisUnit: _basisUnit,
      resultActivity: _concActivityUnit,
      resultBasis: _basisUnit,
    );
    setState(() {
      _valueCtrl.text = QuantityField.formatNumber(result);
      _valueTypedText = null;
    });
  }

  /// Spektrum-fájl kiválasztása, ellenőrzése, másolása az app-mappába.
  Future<void> _pickSpectrumFile() async {
    final loc = AppLocalizations.of(context)!;
    // Az iOS és Android dokumentumválasztó az ismeretlen .n42 kiterjesztést
    // szürkíti, ezért minden fájl választható; a tartalmat a parser ellenőrzi.
    final selection = await FilePicker.pickFiles(type: FileType.any);
    if (selection.isEmpty) return;
    final file = selection.single;
    List<int>? bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      bytes = null;
    }
    if (bytes == null) {
      _showError(loc.spectrumParseError);
      return;
    }
    var all = <Spectrum>[];
    try {
      all = N42Parser.parseAll(utf8.decode(bytes, allowMalformed: true));
    } catch (_) {
      all = <Spectrum>[];
    }
    if (all.isEmpty) {
      _showError(loc.spectrumParseError);
      return;
    }
    final Spectrum? picked =
        all.length == 1 ? all.first : await _chooseSpectrum(loc, all);
    if (picked == null) return;
    // A kiválasztott spektrum egyspektrumos, tömörítetlen N42 másolatként kerül mentésre.
    final path = await SpectrumService.importFile(
      bytes: utf8.encode(picked.toN42Xml()),
      fileName: file.name,
    );
    if (!mounted) return;
    // Az aktivitás a fájlban egység nélkül van: a Beállításokban beállított
    // aktivitás-egységet használjuk, a tárolás MBq.
    final activityUnit = ActivityUnitController.current;
    final activities = [
      for (final r in picked.nuclideResults)
        if (r.value != null)
          NuclideActivity(
            nuclide: r.nuclide,
            mbq: r.value! * activityUnit.mbqFactor,
            uncertaintyMbq: r.uncertainty == null
                ? null
                : r.uncertainty! * activityUnit.mbqFactor,
          ),
    ];
    final category = picked.detectorCategory?.toLowerCase();
    setState(() {
      _spectrumPath = path;
      _spectrumFileName = file.name;
      _spectrum = picked;
      _spectrumNuclideActivities = activities;
      // A fájl detektor-kategóriája adja az alapértelmezett típust.
      if (category == 'neutron') _spectrumKind = SpectrumKind.neutron;
      if (category == 'gamma') _spectrumKind = SpectrumKind.gamma;
      // A fájl azonosított nuklidjai a pont nuklid-mezőjébe kerülnek.
      if (picked.identifiedNuclides.isNotEmpty) {
        _nuclideStatus = NuclideIdStatus.identified;
        _nuclides = [...picked.identifiedNuclides];
      }
    });
  }

  /// Több spektrum a fájlban: a felhasználó választ egyet.
  Future<Spectrum?> _chooseSpectrum(AppLocalizations loc, List<Spectrum> all) {
    final kind = _spectrumKind.localized(loc);
    String summary(Spectrum s) => loc.spectrumSummaryText(
          kind,
          '${s.channelCount}',
          s.liveTimeSeconds == null
              ? '—'
              : '${s.liveTimeSeconds!.toStringAsFixed(1)} s',
          '${s.totalCounts}',
        );
    return showDialog<Spectrum>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(loc.spectrumChooseTitle),
        children: [
          for (var i = 0; i < all.length; i++)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(all[i]),
              child: Text('#${i + 1} · ${summary(all[i])}'),
            ),
        ],
      ),
    );
  }

  /// Spektrum-szekció: fájl, típus (alapértelmezés: gamma), összegzés, ábra.
  List<Widget> _buildSpectrumSection(AppLocalizations loc) {
    final s = _spectrum;
    return [
      OutlinedButton.icon(
        onPressed: _pickSpectrumFile,
        icon: const Icon(Icons.upload_file),
        label: Text(
          _spectrumPath == null
              ? loc.spectrumFileButton
              : loc.spectrumFileChangeButton,
        ),
      ),
      if (_spectrumFileName != null) ...[
        const SizedBox(height: 4),
        Text(
          _spectrumFileName!,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
      const SizedBox(height: 12),
      DropdownButtonFormField<SpectrumKind>(
        initialValue: _spectrumKind,
        decoration: InputDecoration(labelText: loc.spectrumKindLabel),
        items: [
          for (final k in SpectrumKind.values)
            DropdownMenuItem<SpectrumKind>(
              value: k,
              child: Text(k.localized(loc)),
            ),
        ],
        onChanged: (k) {
          if (k != null) setState(() => _spectrumKind = k);
        },
      ),
      if (s != null) ...[
        const SizedBox(height: 12),
        Text(
          loc.spectrumSummaryText(
            _spectrumKind.localized(loc),
            '${s.channelCount}',
            s.liveTimeSeconds == null
                ? '—'
                : '${s.liveTimeSeconds!.toStringAsFixed(1)} s',
            '${s.totalCounts}',
          ),
        ),
        for (final a in _spectrumNuclideActivities)
          Text(nuclideActivityText(a)),
        if (_spectrumNuclideActivities.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: Text(loc.foundSourceButton),
              onPressed: () => _startFoundSource([
                for (final a in _spectrumNuclideActivities)
                  FoundNuclideDraft(
                    nuclide: a.nuclide,
                    activityMBq: a.mbq,
                    origin: ActivityOrigin.spectrum,
                  ),
              ]),
            ),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(loc.spectrumLogScaleLabel),
          value: _spectrumLog,
          onChanged: (v) => setState(() => _spectrumLog = v),
        ),
        SpectrumChart(
          spectrum: s,
          logScale: _spectrumLog,
          xLabel: spectrumAxisLabel(loc, s),
        ),
      ],
      const SizedBox(height: 12),
      NuclideIdSection(
        status: _nuclideStatus,
        nuclides: _nuclides,
        onStatusChanged: (st) => setState(() => _nuclideStatus = st),
        onNuclidesChanged: (list) => setState(() => _nuclides = list),
      ),
    ];
  }

  /// Aktivitás-becslés a dózisteljesítményes mérésből (csak dózisnál értelmes).
  Widget? _buildActivityFromMeasurementPanel(AppLocalizations loc) {
    if (_type != MeasurementType.doseRate ||
        _radiation != RadiationKind.gamma ||
        _doseQuantity != DoseQuantity.h10) {
      return null;
    }
    final measuredValue = parseDecimal(_valueCtrl.text);
    final distance = _distanceMeters();
    if (measuredValue == null || distance == null || distance <= 0) {
      return null;
    }

    // Csak akkor számolunk, ha pontosan egy (ismert) nuklid van azonosítva.
    final nuclideName = _estimationNuclide;
    if (nuclideName == null) return null;
    if (Isotope.findByName(nuclideName) == null) return null;

    final measuredUSvH =
        toMicroSievertPerHour(measuredValue, _unitCtrl.text.trim());
    if (measuredUSvH == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          loc.unrecognizedUnitForComparisonNote(_unitCtrl.text.trim()),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    final estimate = estimateActivity(
      nuclide: nuclideName,
      doseRateUSvH: measuredUSvH,
      distanceM: distance,
      layers: _validLayers(),
    );
    if (estimate == null) return null;
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.estimatedActivityFromMeasurementLabel,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${loc.unshieldedActivityLabel}: '
              '${formatActivityMBq(estimate.unshieldedMBq)}',
            ),
            const Divider(height: 24),
            Text(loc.shieldingSectionTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(loc.shieldingHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            for (var i = 0; i < _layers.length; i++) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ShieldingMaterial>(
                      key: ValueKey('layer-$i-${_layers[i].material.name}'),
                      initialValue: _layers[i].material,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: '${loc.shieldingLayerLabel} ${i + 1}: '
                            '${loc.shieldingMaterialLabel}',
                      ),
                      items: [
                        for (final m in ShieldingMaterial.values)
                          DropdownMenuItem(
                            value: m,
                            child: Text(shieldingMaterialLabel(loc, m)),
                          ),
                      ],
                      onChanged: (m) {
                        if (m != null) setState(() => _layers[i].material = m);
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: loc.shieldingRemoveLayer,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() {
                      _layers.removeAt(i).ctrl.dispose();
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              QuantityField<DistanceUnit>(
                key: ValueKey('layer-th-${_layers[i].hashCode}'),
                controller: _layers[i].ctrl,
                label: loc.shieldingThicknessLabel,
                units: DistanceUnit.values,
                unit: _layers[i].unit,
                onUnitChanged: (u) => setState(() => _layers[i].unit = u),
                onChanged: () => setState(() {}),
                validator: (v) {
                  final t = parseDecimal(v ?? '');
                  return (t == null || t <= 0)
                      ? loc.shieldingThicknessError
                      : null;
                },
              ),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add),
                label: Text(loc.shieldingAddLayer),
                onPressed: () => setState(
                    () => _layers.add(_LayerEdit(ShieldingMaterial.lead))),
              ),
            ),
            if (estimate.shieldedMBq != null) ...[
              const SizedBox(height: 8),
              Text(
                '${loc.shieldedActivityLabel}: '
                '${formatActivityMBq(estimate.shieldedMBq!)}',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: Text(loc.foundSourceButton),
                onPressed: () => _startFoundSource([
                  FoundNuclideDraft(
                    nuclide: nuclideName,
                    activityMBq: estimate.shieldedMBq ?? estimate.unshieldedMBq,
                    origin: estimate.shieldedMBq != null
                        ? ActivityOrigin.shieldedMeasurement
                        : ActivityOrigin.measurement,
                  ),
                ]),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: DisclaimerInfoIcon(
                text: estimate.shieldedMBq != null
                    ? '${loc.sourceCalculationDisclaimer}\n\n'
                        '${loc.shieldingDisclaimer}'
                    : loc.sourceCalculationDisclaimer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addInstrument() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const InstrumentEntryScreen()),
    );
    if (saved == true) await _loadInstruments();
  }

  /// Figyelmeztető sáv, ha a kiválasztott műszer hitelesítése/kalibrálása
  /// lejárt, hamarosan lejár, vagy nincs róla adat.
  Widget _buildCalibrationBanner(AppLocalizations loc, Instrument i) {
    final st = instrumentCalibrationStatus(i);
    if (st == CalibrationStatus.valid) return const SizedBox.shrink();
    final date = i.nextCalibrationDate == null
        ? ''
        : ' ${calibrationDateText(i.nextCalibrationDate!)}';
    final String text;
    final Color color;
    switch (st) {
      case CalibrationStatus.expired:
        text = '${loc.calibrationExpiredWarning}$date';
        color = Theme.of(context).colorScheme.error;
        break;
      case CalibrationStatus.expiringSoon:
        text = '${loc.calibrationSoonWarning}$date';
        color = Colors.orange.shade800;
        break;
      default:
        text = loc.calibrationUnknownWarning;
        color = Theme.of(context).colorScheme.outline;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Instrument? get _selectedInstrument {
    if (_instrumentId == null) return null;
    for (final i in _instruments) {
      if (i.id == _instrumentId) return i;
    }
    return null;
  }

  /// Lekérdezi az aktuálisan kiválasztott, Modbus/TCP-n elérhető műszer
  /// mért értékét, és beírja a "Mért érték" mezőbe.
  Future<void> _queryModbus() async {
    final instrument = _selectedInstrument;
    if (instrument == null) return;

    final loc = AppLocalizations.of(context)!;
    setState(() => _isQueryingModbus = true);
    try {
      final result = await ModbusReaderService.readFloatRegister(instrument, loc);
      if (!mounted) return;
      if (result.success) {
        setState(() {
          // A műszer határozza meg, mit mér és milyen egységben adja vissza:
          // a mérés típusát átállítjuk, az értéket pedig az alapegységre váltjuk.
          _type = instrument.modbusMeasurementType;
          if (_type == MeasurementType.countRate) {
            _radiation = radiationForInstrument(instrument);
          }
          _isSample = false;
          _unitCtrl.text = _displayUnitFor(_type);
          _valueCtrl.text = QuantityField.formatNumber(
            _shownValue(_type, instrumentReadingInAppUnit(instrument, result.value!)),
          );
          _errorCtrl.clear();
          _avgSamples = null;
          _avgSeconds = null;
          if (result.hasGps) {
            _latCtrl.text = _fmt(result.latitude!, 6);
            _lonCtrl.text = _fmt(result.longitude!, 6);
            _gpsAccuracy = null;
            _positionManuallySet = true;
          }
        });
      } else {
        _showError(
          result.errorMessage ?? loc.unknownModbusError,
        );
      }
    } finally {
      if (mounted) setState(() => _isQueryingModbus = false);
    }
  }

  /// Átlagoló mérés: a kiválasztott időtartamig másodpercenként olvassa a
  /// műszert, az értékbe az átlag, a hibába az átlag standard hibája (1σ)
  /// kerül.
  Future<void> _startModbusAveraging() async {
    final instrument = _selectedInstrument;
    if (instrument == null || _isAveraging) return;
    final loc = AppLocalizations.of(context)!;
    setState(() {
      _isAveraging = true;
      _avgStop = false;
      _avgAbort = false;
      _avgElapsed = 0;
      _avgValues.clear();
    });
    ModbusLiveSession? session;
    ModbusReadResult? lastGps;
    var failed = 0;
    try {
      session = await ModbusLiveSession.connect(instrument, loc);
      final start = DateTime.now();
      while (mounted && !_avgStop && !_avgAbort) {
        final elapsed = DateTime.now().difference(start).inSeconds;
        if (elapsed >= _avgDuration) break;
        final r = await session.read();
        if (r.success) {
          _avgValues.add(instrumentReadingInAppUnit(instrument, r.value!));
          if (r.hasGps) lastGps = r;
        } else {
          failed++;
        }
        if (mounted) {
          setState(() => _avgElapsed = DateTime.now().difference(start).inSeconds);
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      _showError(loc.modbusConnectErrorMessage('$e'));
      _avgAbort = true;
    } finally {
      await session?.close();
    }
    if (!mounted) return;
    final stats = _avgAbort ? null : valueStats(_avgValues);
    final seconds = _avgElapsed;
    setState(() {
      _isAveraging = false;
      if (stats == null) return;
      _type = instrument.modbusMeasurementType;
      if (_type == MeasurementType.countRate) {
        _radiation = radiationForInstrument(instrument);
      }
      _isSample = false;
      _unitCtrl.text = _displayUnitFor(_type);
      _valueCtrl.text = QuantityField.formatNumber(_shownValue(_type, stats.mean));
      final se = stats.standardError;
      _errorCtrl.text =
          se == null ? '' : QuantityField.formatNumber(_shownValue(_type, se));
      _avgSamples = stats.n;
      _avgSeconds = seconds;
      final g = lastGps;
      if (g != null) {
        _latCtrl.text = _fmt(g.latitude!, 6);
        _lonCtrl.text = _fmt(g.longitude!, 6);
        _gpsAccuracy = null;
        _positionManuallySet = true;
      }
    });
    if (stats != null && stats.n < 2) _showError(loc.modbusAverageTooFew);
    if (stats == null && !_avgAbort && failed > 0) {
      _showError(loc.unknownModbusError);
    }
  }

  Future<void> _fetchGpsPosition() async {
    if (_plan != null) return; // alaprajz módban a GPS nem adja a pozíciót
    final loc = AppLocalizations.of(context)!;
    setState(() => _isFetchingGps = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError(loc.locationServiceDisabledError);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showError(loc.locationPermissionDeniedError);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      setState(() {
        _latCtrl.text = _fmt(position.latitude, 6);
        _lonCtrl.text = _fmt(position.longitude, 6);
        _gpsAccuracy = position.accuracy;
        _positionManuallySet = false;
      });
    } catch (e) {
      _showError(loc.gpsErrorMessage('$e'));
    } finally {
      if (mounted) setState(() => _isFetchingGps = false);
    }
  }

  Future<void> _averageGpsPosition() async {
    if (_plan != null) return; // alaprajz módban a GPS nem adja a pozíciót
    final loc = AppLocalizations.of(context)!;
    if (!await Geolocator.isLocationServiceEnabled()) {
      _showError(loc.locationServiceDisabledError);
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showError(loc.locationPermissionDeniedError);
      return;
    }
    if (!mounted) return;
    final result = await showPositionAveragingDialog(context);
    if (result == null || !mounted) return;
    setState(() {
      _latCtrl.text = _fmt(result.latitude, 6);
      _lonCtrl.text = _fmt(result.longitude, 6);
      _gpsAccuracy = result.accuracyMeters;
      _positionManuallySet = false;
    });
  }

  /// Helyi koordináta kijelzése alaprajz módban (X/Y méterben).
  Widget _localPositionHint(AppLocalizations loc) {
    final plan = _plan;
    final lat = parseDecimal(_latCtrl.text);
    final lon = parseDecimal(_lonCtrl.text);
    if (plan == null || lat == null || lon == null) {
      return const SizedBox.shrink();
    }
    final m = planLocalMetres(plan, lat, lon);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '${loc.planLocalCoordLabel}: X ${m.x.toStringAsFixed(2)} m, '
        'Y ${m.y.toStringAsFixed(2)} m',
      ),
    );
  }

  Future<void> _openMapPicker() async {
    final currentLat = parseDecimal(_latCtrl.text);
    final currentLon = parseDecimal(_lonCtrl.text);
    final initialCenter = (currentLat != null && currentLon != null)
        ? ll.LatLng(currentLat, currentLon)
        : (_plan != null
            ? _planCentreLatLng(_plan!)
            : const ll.LatLng(47.4979, 19.0402)); // Budapest, ha még nincs pozíció

    final picked = await Navigator.of(context).push<ll.LatLng>(
      MaterialPageRoute(
        builder: (_) => MapPointPickerScreen(
          initialCenter: initialCenter,
          plan: _plan,
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _latCtrl.text = _fmt(picked.latitude, 6);
      _lonCtrl.text = _fmt(picked.longitude, 6);
      _gpsAccuracy = null; // térképről kijelölt pont, nincs eszköz-pontosság
      _positionManuallySet = true;
    });
  }

  /// Bluetooth-gomb parancsa. Ami ezen a képernyőn nem értelmezhető (pl. új
  /// pont, automatikus rögzítés), azt false-szal a mögötte lévő képernyőre hagyja.
  bool _onButtonCommand(ButtonCommand command) {
    if (!mounted) return false;
    if (command == ButtonCommand.savePoint) {
      unawaited(_save());
      return true;
    }
    if (command == ButtonCommand.saveAndNewPoint) {
      unawaited(_saveAndNewPoint());
      return true;
    }
    if (command == ButtonCommand.discardPoint) {
      _discardPressed();
      return true;
    }
    if (command == ButtonCommand.takePhoto) {
      unawaited(_pickPhoto(directCamera: true));
      return true;
    }
    if (command == ButtonCommand.modbusQuery) {
      if (_selectedInstrument?.isModbusConnected != true || _isQueryingModbus) {
        return false;
      }
      unawaited(_queryModbus());
      return true;
    }
    if (command == ButtonCommand.modbusAveraging) {
      if (_isAveraging) {
        setState(() => _avgStop = true);
        return true;
      }
      if (_selectedInstrument?.isModbusConnected != true) return false;
      unawaited(_startModbusAveraging());
      return true;
    }
    if (command == ButtonCommand.nextMeasurementType) {
      _stepMeasurementType(1);
      return true;
    }
    if (command == ButtonCommand.previousMeasurementType) {
      _stepMeasurementType(-1);
      return true;
    }
    if (command == ButtonCommand.toggleSourcePosition) {
      setState(() => _isSourcePosition = !_isSourcePosition);
      return true;
    }
    return false;
  }

  /// Mentés, majd új pont ugyanabban a felmérésben. A visszatérés a szerkesztő
  /// helyére új példányt tesz, így a lista a sikeres mentést látja.
  Future<void> _saveAndNewPoint() async {
    await _save(popAfter: false);
    if (!_lastSaveOk || !mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MeasurementEntryScreen(
          surveySessionId: widget.surveySessionId,
        ),
      ),
      result: true,
    );
  }

  /// Mérési típus léptetése; ugyanazt teszi, mint a típus-legördülő.
  void _stepMeasurementType(int step) {
    final values = MeasurementType.values;
    final next =
        values[(values.indexOf(_type) + step + values.length) % values.length];
    setState(() {
      _type = next;
      _unitCtrl.text = _displayUnitFor(next);
      _isSample = next == MeasurementType.sample;
    });
    LastMeasurementTypeController.remember(next);
  }

  /// Mégse, mentés nélkül. Az első nyomás csak figyelmeztet; a 3 másodpercen
  /// belüli második nyomás zárja be a képernyőt. Mentett adat nem törlődik.
  void _discardPressed() {
    final now = DateTime.now();
    final armedAt = _discardArmedAt;
    if (armedAt != null &&
        now.difference(armedAt) < const Duration(seconds: 3)) {
      Navigator.of(context).pop(false);
      return;
    }
    _discardArmedAt = now;
    _showError(AppLocalizations.of(context)!.discardConfirmHint);
  }

  Future<void> _pickPhoto({bool directCamera = false}) async {
    final loc = AppLocalizations.of(context)!;
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    if (isDesktop) {
      // Desktopon nincs kamera-delegate, egyből fájlválasztó nyílik
      const typeGroup = fs.XTypeGroup(
        label: 'images',
        extensions: ['jpg', 'jpeg', 'png', 'heic'],
      );
      final file = await fs.openFile(acceptedTypeGroups: [typeGroup]);
      if (file != null) {
        setState(() => _photoPath = file.path);
      }
      return;
    }

    final ImageSource? source = directCamera
        ? ImageSource.camera
        : await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(loc.takePhotoLabel),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(loc.chooseFromGalleryLabel),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (photo != null) {
      setState(() => _photoPath = photo.path);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// A mintavétel egységének tárolt alakja: a rövidítés, vagy az "egyéb"
  /// választásnál a felhasználó saját szövege.
  /// A típus bevitelben használt egysége: felületi szennyezettségnél a
  /// beállított megjelenítési egység, egyébként az alapegység.
  String _displayUnitFor(MeasurementType t) {
    if (t == MeasurementType.surfaceContamination) {
      return DisplayUnits.surface.value;
    }
    if (t == MeasurementType.countRate) {
      return CountRateOption(CountRateUnit.perSecond,
              _radiation == RadiationKind.neutron)
          .symbol;
    }
    if (t == MeasurementType.doseRate &&
        _doseQuantity == DoseQuantity.kerma) {
      return KermaRateUnit.defaultUnit.symbol;
    }
    return t.defaultUnit;
  }

  /// Tárolt (kanonikus) értékből a bevitelben megjelenő érték.
  double _shownValue(MeasurementType t, double v) =>
      t == MeasurementType.surfaceContamination
          ? DisplayUnits.surfaceFromCanonical(v)
          : v;

  /// A bevitt (megjelenítési egységű) értékből a tárolt érték.
  double? _toStoredValue(double? v) =>
      (v == null || _type != MeasurementType.surfaceContamination)
          ? v
          : DisplayUnits.surfaceToCanonical(v);

  /// A mentett egység: felületi szennyezettségnél mindig a tárolt Bq/cm².
  String _storedUnit() => switch (_type) {
        MeasurementType.surfaceContamination => kSurfaceCanonicalUnit,
        MeasurementType.activityConcentration =>
          concentrationSymbol(_concActivityUnit, _basisUnit),
        MeasurementType.spectrum => '',
        _ => _unitCtrl.text.trim(),
      };

  /// A meteorológiai címke a beállított egységgel (ha az egység váltható).
  String _metLabel(AppLocalizations loc, String key) {
    final base = _metLabelBase(loc, key);
    final unit = switch (key) {
      'temp' => DisplayUnits.temperature.value,
      'pressure' => DisplayUnits.pressure.value,
      'wind' || 'gust' => DisplayUnits.wind.value,
      _ => null,
    };
    if (unit == null) return base;
    final stripped = base.replaceFirst(RegExp(r'\s*\([^)]*\)$'), '');
    return '$stripped ($unit)';
  }

  String _metLabelBase(AppLocalizations loc, String key) => switch (key) {
        'temp' => loc.rrMetTemp,
        'humidity' => loc.rrMetHumidity,
        'pressure' => loc.rrMetPressure,
        'wind' => loc.rrMetWind,
        'windDir' => loc.rrMetWindDir,
        'gust' => loc.rrMetGust,
        'precip' => loc.rrMetPrecipIntensity,
        'solar' => loc.rrMetSolar,
        'cloud' => loc.rrMetCloud,
        'visibility' => loc.rrMetVisibility,
        'soil' => loc.rrMetSoil,
        _ => loc.rrMetAerosol,
      };

  void _removeBio(_BioEdit b) {
    setState(() {
      _bios.remove(b);
      _discardedBios.add(b);
    });
  }

  List<BioAgentReading> _bioValues() {
    final out = <BioAgentReading>[];
    for (final b in _bios) {
      final name = b.nameCtrl.text.trim();
      if (name.isEmpty) continue;
      out.add(BioAgentReading(
        name: name,
        kind: b.kind,
        quantity: b.quantityCtrl.text.trim(),
      ));
    }
    return out;
  }

  Widget _bioEditor(_BioEdit b) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<BioKind>(
                  isExpanded: true,
                  initialValue: b.kind,
                  decoration: InputDecoration(labelText: loc.rrBioKindLabel),
                  items: [
                    for (final k in BioKind.values)
                      DropdownMenuItem(value: k, child: Text(k.localized(loc))),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => b.kind = v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: b.nameCtrl,
                  decoration: InputDecoration(labelText: loc.rrBioAgentName),
                ),
              ),
              IconButton(
                tooltip: loc.rrDeleteTooltip,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _removeBio(b),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: b.quantityCtrl,
            decoration: InputDecoration(labelText: loc.rrBioQuantityLabel),
          ),
        ],
      ),
    );
  }

  void _removeGas(_GasEdit g) {
    setState(() {
      _gases.remove(g);
      _discardedGases.add(g);
    });
  }

  double? _metValue(String key) {
    final t = _metCtrls[key]!.text.trim();
    return t.isEmpty ? null : parseDecimal(t);
  }

  Meteorology? _meteorologyValue() {
    final other = _metOtherCtrl.text.trim();
    final m = Meteorology(
      airTemperatureC: DisplayUnits.tempToC(_metValue('temp')),
      relativeHumidityPct: _metValue('humidity'),
      pressureHpa: DisplayUnits.pressureToHpa(_metValue('pressure')),
      windSpeedMs: DisplayUnits.windToMs(_metValue('wind')),
      windDirectionDeg: _metValue('windDir'),
      precipitation: _precipitation,
      gustMs: DisplayUnits.windToMs(_metValue('gust')),
      precipitationMmH: _metValue('precip'),
      solarWm2: _metValue('solar'),
      cloudOkta: _metValue('cloud'),
      visibilityM: _metValue('visibility'),
      soilMoisturePct: _metValue('soil'),
      aerosolUgM3: _metValue('aerosol'),
      other: other.isEmpty ? null : other,
    );
    return m.isEmpty ? null : m;
  }

  /// Mértékegység: arány (ppm, vol% …), vagy tömeg / alap, ahol a tömeg és az
  /// alap külön választható. Az alapértékek a Beállítások mintaegységei.
  Widget _unitSelector(_GasEdit g, AppLocalizations loc) {
    final u = g.unit;
    final isRatio = u.ratio != null;
    final basisKinds = basisKindsFor(g.state);
    void setMode(bool ratio) => setState(() {
          g.unit = ratio
              ? const ConcentrationUnit.ratio(RatioUnit.ppm)
              : ConcentrationUnit.perBasis(
                  mass: BasisUnitController.of(BasisKind.mass),
                  basis: BasisUnitController.of(basisKinds.first),
                );
        });
    return SizedBox(
      key: ValueKey('${u.symbol}|${g.state.name}'),
      width: double.infinity,
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: DropdownButtonFormField<bool>(
              isExpanded: true,
              initialValue: isRatio,
              decoration: InputDecoration(labelText: loc.rrUnitMode),
              items: [
                DropdownMenuItem(value: true, child: Text(loc.rrUnitRatio)),
                DropdownMenuItem(value: false, child: Text(loc.rrUnitMassPerBasis)),
              ],
              onChanged: (v) {
                if (v != null) setMode(v);
              },
            ),
          ),
          const SizedBox(width: 6),
          if (isRatio)
            Expanded(
              child: DropdownButtonFormField<RatioUnit>(
                isExpanded: true,
                initialValue: u.ratio,
                decoration: InputDecoration(labelText: loc.rrGasUnit),
                items: [
                  for (final r in RatioUnit.values)
                    if (!r.gasOnly || g.state == PhysicalState.gas)
                      DropdownMenuItem(value: r, child: Text(r.symbol)),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => g.unit = ConcentrationUnit.ratio(v));
                  }
                },
              ),
            )
          else ...[
            Expanded(
              child: DropdownButtonFormField<BasisUnit>(
                isExpanded: true,
                initialValue: u.massUnit,
                decoration: InputDecoration(labelText: loc.rrUnitMass),
                items: [
                  for (final m in BasisUnit.ofKind(BasisKind.mass))
                    DropdownMenuItem(value: m, child: Text(m.symbol)),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => g.unit = ConcentrationUnit.perBasis(
                          mass: v,
                          basis: u.basisUnit!,
                        ));
                  }
                },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: DropdownButtonFormField<BasisUnit>(
                isExpanded: true,
                initialValue: u.basisUnit,
                decoration: InputDecoration(labelText: loc.rrUnitBasis),
                items: [
                  for (final k in basisKinds)
                    for (final b in BasisUnit.ofKind(k))
                      DropdownMenuItem(value: b, child: Text(b.symbol)),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => g.unit = ConcentrationUnit.perBasis(
                          mass: u.massUnit!,
                          basis: v,
                        ));
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Halmazállapot-váltásnál az érvénytelen egység a halmazállapothoz illőre cserélődik.
  static ConcentrationUnit _coerceUnit(ConcentrationUnit u, PhysicalState state) {
    final r = u.ratio;
    if (r != null) {
      return r.gasOnly && state != PhysicalState.gas
          ? const ConcentrationUnit.ratio(RatioUnit.ppm)
          : u;
    }
    final kinds = basisKindsFor(state);
    if (kinds.contains(u.basisUnit!.kind)) return u;
    return ConcentrationUnit.perBasis(
      mass: u.massUnit!,
      basis: BasisUnitController.of(kinds.first),
    );
  }

  /// A gázmérési sorok; koncentráció nélküli vagy név nélküli sor kimarad.
  List<GasReading> _gasValues() {
    final out = <GasReading>[];
    for (final g in _gases) {
      final conc = parseDecimal(g.concCtrl.text.trim());
      if (conc == null) continue;
      final isOther = g.species == otherGasName;
      final name = isOther ? g.nameCtrl.text.trim() : g.species;
      if (name.isEmpty) continue;
      out.add(GasReading(
        name: name,
        formula: isOther ? g.formulaCtrl.text.trim() : gasFormulaOf(g.species),
        concentration: conc,
        unit: g.unit,
        state: g.state,
      ));
    }
    return out;
  }

  Widget _gasEditor(_GasEdit g) {
    final loc = AppLocalizations.of(context)!;
    final isOther = g.species == otherGasName;
    final formula = gasFormulaOf(g.species);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: g.species,
                  decoration: InputDecoration(labelText: loc.rrChemicalSpecies),
                  items: [
                    for (final s in gasSpecies)
                      DropdownMenuItem(
                        value: s.name,
                        child: Text(
                          localizedGasName(loc, s.name),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    DropdownMenuItem(
                      value: otherGasName,
                      child: Text(loc.rrGasOther),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => g.species = v);
                  },
                ),
              ),
              IconButton(
                tooltip: loc.rrDeleteTooltip,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _removeGas(g),
              ),
            ],
          ),
          if (!isOther && formula.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Text('${loc.rrFormulaLabel}: $formula'),
            ),
          if (isOther) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: g.nameCtrl,
              decoration: InputDecoration(labelText: loc.rrGasOtherName),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: g.formulaCtrl,
              decoration: InputDecoration(labelText: loc.rrFormulaLabel),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: g.concCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(labelText: loc.rrGasConcentration),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return null;
                    final n = parseDecimal(t);
                    return (n == null || n < 0) ? loc.rrInvalidValue : null;
                  },
                ),
              ),
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<PhysicalState>(
                  isExpanded: true,
                  initialValue: g.state,
                  decoration: InputDecoration(labelText: loc.physicalStateLabel),
                  items: [
                    for (final s in PhysicalState.values)
                      DropdownMenuItem(value: s, child: Text(s.localized(loc))),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        g.state = v;
                        g.unit = _coerceUnit(g.unit, v);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _unitSelector(g, loc),
        ],
      ),
    );
  }

  String? _sampleUnitStored() {
    final u = _sampleUnit;
    if (u == null) return null;
    if (u.isCustom) {
      final t = _sampleUnitCtrl.text.trim();
      return t.isEmpty ? null : t;
    }
    return u.symbol;
  }

  /// Az űrlap mezőiből épít fel egy `MeasurementPoint`-ot. `id`/`timestamp`/
  /// `createdAt` nélkül új pontot ad (a `_save` és a forrás-hozzárendelés
  /// előtti automatikus mentés is ezt hívja), meglévő pontra hivatkozva
  /// pedig a szerkesztést.
  MeasurementPoint _buildPointFromForm({
    int? id,
    required double latitude,
    required double longitude,
    DateTime? timestamp,
    DateTime? createdAt,
  }) {
    final now = DateTime.now();
    return MeasurementPoint(
      id: id,
      surveySessionId: widget.surveySessionId,
      groupKey: _editingPoint?.groupKey ?? widget.templatePoint?.groupKey,
      locationLabel: _locationLabelCtrl.text.trim().isEmpty
          ? null
          : _locationLabelCtrl.text.trim(),
      latitude: latitude,
      longitude: longitude,
      gpsAccuracyMeters: _gpsAccuracy,
      type: _type,
      value: !_type.hasValue || _valueCtrl.text.trim().isEmpty
          ? null
          : _toStoredValue(parseDecimal(_valueCtrl.text)),
      valueError: _isSample || !_type.hasValue || _errorCtrl.text.trim().isEmpty
          ? null
          : _toStoredValue(double.tryParse(_errorCtrl.text.trim().replaceAll(',', '.'))?.abs()),
      averagingSamples:
          _isSample || _errorCtrl.text.trim().isEmpty && _avgSamples == null
              ? null
              : _avgSamples,
      averagingSeconds:
          _isSample || _errorCtrl.text.trim().isEmpty && _avgSamples == null
              ? null
              : _avgSeconds,
      unit: _storedUnit(),
      distanceFromSourceMeters:
          _distanceCtrl.text.trim().isEmpty ? null : _distanceMeters(),
      activityCalcNuclide:
          _isSample || !_type.hasValue || _isActivityKind ? null : _estimationNuclide,
      instrumentId: _instrumentId,
      nuclideStatus:
          _isSample || (!_type.hasValue && _type != MeasurementType.spectrum)
              ? NuclideIdStatus.notSpecified
              : _nuclideStatus,
      nuclides: (_type.hasValue || _type == MeasurementType.spectrum) &&
              !_isSample &&
              _nuclideStatus.hasNuclideList
          ? _nuclides
          : const [],
      shieldingLayers: _isSample || _isActivityKind || _estimationNuclide == null
          ? const []
          : _validLayers(),
      isSourcePosition: _isSourcePosition,
      isSample: _isSample,
      sampleContainerId:
          _isSample && _sampleContainerCtrl.text.trim().isNotEmpty
          ? _sampleContainerCtrl.text.trim()
          : null,
      sampleAmount: _isSample && _sampleAmountCtrl.text.trim().isNotEmpty
          ? parseDecimal(_sampleAmountCtrl.text)
          : null,
      sampleUnit: _isSample ? _sampleUnitStored() : null,
      basisAmount: _type == MeasurementType.activityConcentration &&
              _basisAmountCtrl.text.trim().isNotEmpty
          ? parseDecimal(_basisAmountCtrl.text)
          : null,
      basisUnit: _type == MeasurementType.activityConcentration
          ? _basisUnit.symbol
          : null,
      spectrumKind:
          _type == MeasurementType.spectrum ? _spectrumKind.dbValue : null,
      spectrumFileName:
          _type == MeasurementType.spectrum ? _spectrumFileName : null,
      spectrumPath: _type == MeasurementType.spectrum ? _spectrumPath : null,
      spectrumChannels: _type == MeasurementType.spectrum
          ? (_spectrum?.channelCount ?? _editingPoint?.spectrumChannels)
          : null,
      spectrumLiveSeconds: _type == MeasurementType.spectrum
          ? (_spectrum?.liveTimeSeconds ?? _editingPoint?.spectrumLiveSeconds)
          : null,
      radiationKind: _type == MeasurementType.doseRate ||
              _type == MeasurementType.countRate
          ? _radiation.dbValue
          : null,
      doseQuantity:
          _type == MeasurementType.doseRate ? _doseQuantity.dbValue : null,
      doseDepthMm: _type == MeasurementType.doseRate &&
              _doseQuantity.depthOptionsMm.isNotEmpty
          ? (_doseDepthMm ?? _doseQuantity.defaultDepthMm)
          : null,
      spectrumActivityJson: _type == MeasurementType.spectrum &&
              _spectrumNuclideActivities.isNotEmpty
          ? NuclideActivity.listToJson(_spectrumNuclideActivities)
          : null,
      spectrumTotalCounts: _type == MeasurementType.spectrum
          ? (_spectrum?.totalCounts ?? _editingPoint?.spectrumTotalCounts)
          : null,
      meteorology: _type == MeasurementType.meteorology ? _meteorologyValue() : null,
      gases: _type == MeasurementType.gasMeasurement ? _gasValues() : const [],
      bioAgents: _type == MeasurementType.biological ? _bioValues() : const [],
      sampleMethod: _isSample && _sampleMethodCtrl.text.trim().isNotEmpty
          ? _sampleMethodCtrl.text.trim()
          : null,
      photoPath: _photoPath,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      timestamp: timestamp ?? now,
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
  }

  /// Ha a mérési pont még nincs elmentve (új pont felvétele közben), a
  /// forráshoz-rendeléshez szükséges adatbázis-ID megszerzéséhez most
  /// menti — így új ponthoz is rendelhető forrás anélkül, hogy előbb ki
  /// kellene lépni a képernyőről. Ettől kezdve a "Mentés" gomb már ezt a
  /// rekordot frissíti, nem hoz létre újat. Null-lal tér vissza, ha a
  /// pozíció/űrlap még nem érvényes.
  Future<MeasurementPoint?> _ensureSavedForSourceLink() async {
    if (_editingPoint != null) return _editingPoint;

    if (!_formKey.currentState!.validate()) return null;
    final latitude = parseDecimal(_latCtrl.text);
    final longitude = parseDecimal(_lonCtrl.text);
    if (latitude == null || longitude == null) {
      _showError(AppLocalizations.of(context)!.noValidPositionError);
      return null;
    }

    final point = _buildPointFromForm(latitude: latitude, longitude: longitude);
    final id = await _insertNewPoint(point);
    if (!mounted) return null;
    final saved = point.copyWith(id: id);
    setState(() => _editingPoint = saved);
    return saved;
  }

  /// Új pont beszúrása. Másolatnál a forrás-kapcsolatok is átkerülnek az eredetiről.
  Future<int> _insertNewPoint(MeasurementPoint point) async {
    final db = DatabaseHelper.instance;
    final id = await db.insertMeasurementPoint(point);
    final sourceId = widget.templatePoint?.id;
    if (sourceId != null) await db.copyPointSources(sourceId, id);
    if (sourceId != null) await db.copySampleAnalyses(sourceId, id);
    return id;
  }

  Future<void> _save({bool popAfter = true}) async {
    _lastSaveOk = false;
    if (!_formKey.currentState!.validate()) return;
    final latitude = parseDecimal(_latCtrl.text);
    final longitude = parseDecimal(_lonCtrl.text);
    if (latitude == null || longitude == null) {
      _showError(AppLocalizations.of(context)!.noValidPositionError);
      return;
    }

    // Spektrumpontot N42 fájl és fotó nélkül is lehet menteni; a spektrum
    // a kiértékelésnél, a pont szerkesztésével később csatolható.

    // Azonosított / egyéb nuklidnál legalább egy nuklid nevét meg kell adni.
    if (_type.hasValue &&
        !_isSample &&
        (_nuclideStatus == NuclideIdStatus.identified ||
            _nuclideStatus == NuclideIdStatus.other) &&
        _nuclides.isEmpty) {
      _showError(AppLocalizations.of(context)!.nuclideRequiredError);
      return;
    }

    // Lejárt hitelesítésű/kalibrálású műszerrel csak megerősítéssel mentünk.
    final instr = _selectedInstrument;
    if (instr != null &&
        instrumentCalibrationStatus(instr) == CalibrationStatus.expired) {
      final loc = AppLocalizations.of(context)!;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.calibrationSaveAnywayTitle),
          content: Text(loc.calibrationSaveAnywayBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(loc.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(loc.calibrationSaveAnywayConfirm),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    final point = _buildPointFromForm(
      id: _editingPoint?.id,
      latitude: latitude,
      longitude: longitude,
      timestamp: _editingPoint?.timestamp,
      createdAt: _editingPoint?.createdAt,
    );

    await _checkThresholdAndWarn(point);
    if (!mounted) return;

    if (_editingPoint == null) {
      await _insertNewPoint(point);
    } else {
      await DatabaseHelper.instance.updateMeasurementPoint(
        _editingPoint!,
        point,
      );
    }

    _lastSaveOk = true;
    if (mounted && popAfter) Navigator.of(context).pop(true);
  }

  /// A mentés előtt figyelmeztet, ha a mért érték eléri/túllépi a
  /// beállított riasztási küszöböt. Nem blokkolja a mentést — csak jelez.
  Future<void> _checkThresholdAndWarn(MeasurementPoint point) async {
    // A légkerma (K) nem dózisegyenérték: a küszöböt nem hasonlítjuk hozzá.
    if (point.doseQuantity == DoseQuantity.kerma.dbValue) return;
    // A küszöb gamma/általános beütésszámra vonatkozik; neutronnál nincs riasztás.
    if (point.type == MeasurementType.countRate &&
        point.radiationKind == RadiationKind.neutron.dbValue) {
      return;
    }
    if (point.value == null) return;
    final threshold = await SettingsService().getThreshold(point.type);
    if (threshold == null) return;
    var comparable = point.value!;
    var shownUnit = point.unit;
    if (point.type == MeasurementType.doseRate) {
      // A küszöb az aktuális alapegységben van; a pont más egységben is
      // rögzülhetett, ezért átváltva hasonlítunk.
      final pointUnit = DoseRateUnit.fromSymbol(point.unit);
      if (pointUnit != null) {
        comparable =
            pointUnit.convertTo(DoseUnitController.current, point.value!);
        shownUnit = DoseUnitController.current.symbol;
      }
    }
    if (comparable < threshold) return;
    if (!mounted) return;

    final loc = AppLocalizations.of(context)!;
    HapticFeedback.heavyImpact();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber,
          color: Colors.deepOrange,
          size: 40,
        ),
        title: Text(loc.thresholdExceededTitle),
        content: Text(
          loc.thresholdExceededMessage(
            '${double.parse(comparable.toStringAsFixed(4))}',
            shownUnit,
            point.type.label(context),
            '$threshold',
          ),
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

  @override
  void dispose() {
    HardwareButtons.unregister(_buttonHandler);
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _locationLabelCtrl.dispose();
    _avgAbort = true;
    _errorCtrl.dispose();
    _valueCtrl.dispose();
    _unitCtrl.dispose();
    _distanceCtrl.dispose();
    for (final e in _layers) {
      e.ctrl.dispose();
    }
    _notesCtrl.dispose();
    _sampleContainerCtrl.dispose();
    _sampleAmountCtrl.dispose();
    _sampleMethodCtrl.dispose();
    _sampleUnitCtrl.dispose();
    _basisAmountCtrl.dispose();
    _calcActivityCtrl.dispose();
    _metOtherCtrl.dispose();
    for (final c in _metCtrls.values) {
      c.dispose();
    }
    for (final g in [..._gases, ..._discardedGases]) {
      g.dispose();
    }
    for (final b in [..._bios, ..._discardedBios]) {
      b.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingPoint == null ? loc.newPointTitle : loc.editPointTitle,
        ),
        actions: [
          if (_editingPoint != null && _sessionOpen)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: loc.deletePointTooltip,
              onPressed: _confirmDeletePoint,
            ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: loc.saveButton,
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildGpsRow(loc),
            const SizedBox(height: 16),
            DropdownButtonFormField<MeasurementType>(
              initialValue: _type,
              decoration: InputDecoration(labelText: loc.measurementTypeLabel),
              items: MeasurementType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.label(context)),
                    ),
                  )
                  .toList(),
              onChanged: (t) {
                if (t == null) return;
                setState(() {
                  _type = t;
                  _unitCtrl.text = _displayUnitFor(t);
                  _isSample = t == MeasurementType.sample;
                });
                LastMeasurementTypeController.remember(t);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationLabelCtrl,
              decoration: InputDecoration(
                labelText: loc.locationLabelFieldLabel,
              ),
            ),
            const SizedBox(height: 12),
            if (_type.hasValue) ...[
              if (_type == MeasurementType.activity)
                _buildActivityValueField(loc)
              else if (_type == MeasurementType.activityConcentration)
                _buildConcentrationValueField(loc)
              else if (_type == MeasurementType.countRate)
                _buildCountRateValueField(loc)
              else if (_type == MeasurementType.doseRate &&
                  _doseQuantity == DoseQuantity.kerma)
                _buildKermaValueField(loc)
              else if (_type == MeasurementType.doseRate &&
                  DoseRateUnit.fromSymbol(_unitCtrl.text) != null)
                // Zárt listából választható egység (nem lehet elgépelni);
                // váltáskor a beírt szám automatikusan átváltódik.
                QuantityField<DoseRateUnit>(
                  controller: _valueCtrl,
                  label: loc.measuredValueLabel,
                  units: DoseRateUnit.values,
                  unit: DoseRateUnit.fromSymbol(_unitCtrl.text)!,
                  onUnitChanged: (u) => setState(() {
                    final old = DoseRateUnit.fromSymbol(_unitCtrl.text);
                    final err = parseDecimal(_errorCtrl.text);
                    // Kézzel beírt hibaértéknél a szám marad, mint a mért értéknél.
                    final typedError = _errorTypedText != null &&
                        _errorCtrl.text == _errorTypedText;
                    if (old != null && err != null && !typedError) {
                      _errorCtrl.text = QuantityField.formatNumber(
                          old.convertTo(u, err));
                    }
                    _unitCtrl.text = u.symbol;
                  }),
                  onChanged: () => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return loc.requiredFieldError;
                    }
                    if (parseDecimal(v) == null) {
                      return loc.numberRequiredError;
                    }
                    return null;
                  },
                )
              else
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _valueCtrl,
                      decoration: InputDecoration(
                        labelText: loc.measuredValueLabel,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return loc.requiredFieldError;
                        }
                        if (parseDecimal(v) == null) {
                          return loc.numberRequiredError;
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitCtrl,
                      decoration: InputDecoration(labelText: loc.unitLabel),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_type == MeasurementType.doseRate ||
                  _type == MeasurementType.countRate)
                ..._buildRadiationSelector(loc),
              if (_type == MeasurementType.doseRate)
                ..._buildDoseQuantitySelectors(loc),
              _buildErrorField(loc),
              const SizedBox(height: 12),
              QuantityField<DistanceUnit>(
                controller: _distanceCtrl,
                label: loc.distanceFromSourcePlainLabel,
                units: DistanceUnit.values,
                unit: _distanceUnit,
                onUnitChanged: (u) => setState(() => _distanceUnit = u),
                onChanged: () => setState(() {}),
              ),
              DistanceEcho(text: _distanceCtrl.text, unit: _distanceUnit),
              const SizedBox(height: 12),
              NuclideIdSection(
                status: _nuclideStatus,
                nuclides: _nuclides,
                onStatusChanged: (s) => setState(() => _nuclideStatus = s),
                onNuclidesChanged: (list) => setState(() => _nuclides = list),
              ),
              if (_buildActivityFromMeasurementPanel(loc) != null) ...[
                const SizedBox(height: 8),
                _buildActivityFromMeasurementPanel(loc)!,
              ],
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      // Amíg a műszerlista be nem töltött (aszinkron
                      // _loadInstruments), a szerkesztett pont instrumentId-ja
                      // még nem szerepelhet az items között — ha ilyenkor
                      // mégis átadnánk értékként, a DropdownButton assertion
                      // hibával elszáll (ezért fagyott le a pont megnyitása).
                      // A key biztosítja, hogy a lista betöltése után a mező
                      // újra inicializálódjon a helyes initialValue-val,
                      // ne maradjon üresen.
                      key: ValueKey('instrument_dd_${_instruments.length}'),
                      initialValue:
                          _instruments.any((i) => i.id == _instrumentId)
                          ? _instrumentId
                          : null,
                      decoration: InputDecoration(
                        labelText: loc.instrumentLabel,
                      ),
                      items: _instruments
                          .map(
                            (i) => DropdownMenuItem(
                              value: i.id,
                              child: Text(i.name),
                            ),
                          )
                          .toList(),
                      onChanged: (id) => setState(() => _instrumentId = id),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: loc.addInstrumentTooltip,
                    onPressed: _addInstrument,
                  ),
                ],
              ),
              if (_selectedInstrument != null)
                _buildCalibrationBanner(loc, _selectedInstrument!),
              if (_selectedInstrument?.isModbusConnected == true) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isQueryingModbus ? null : _queryModbus,
                  icon: _isQueryingModbus
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering),
                  label: Text(
                    _isQueryingModbus
                        ? loc.queryingLabel
                        : loc.modbusQueryButton(_selectedInstrument!.name),
                  ),
                ),
                const SizedBox(height: 8),
                _buildAveragingControls(loc),
              ],
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(loc.sourcePositionSwitchLabel),
                value: _isSourcePosition,
                onChanged: (v) => setState(() => _isSourcePosition = v),
              ),
            ],
            if (_type.hasValue)
              SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.sampleTakenSwitchLabel),
              value: _isSample,
              onChanged: (v) => setState(() => _isSample = v),
            ),
            if (_isSample) ...[
              TextFormField(
                controller: _sampleContainerCtrl,
                decoration: InputDecoration(
                  labelText: loc.sampleContainerLabel,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sampleAmountCtrl,
                decoration: InputDecoration(labelText: loc.sampleAmountLabel),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return null;
                  final n = parseDecimal(t);
                  return (n == null || n < 0) ? loc.sampleAmountInvalid : null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SampleUnit?>(
                initialValue: _sampleUnit,
                decoration: InputDecoration(labelText: loc.sampleUnitLabel),
                items: [
                  const DropdownMenuItem<SampleUnit?>(
                    value: null,
                    child: Text('—'),
                  ),
                  for (final u in SampleUnit.values)
                    DropdownMenuItem<SampleUnit?>(
                      value: u,
                      child: Text(u.isCustom ? loc.sampleUnitOther : u.symbol),
                    ),
                ],
                onChanged: (v) => setState(() => _sampleUnit = v),
              ),
              if (_sampleUnit == SampleUnit.other) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sampleUnitCtrl,
                  decoration:
                      InputDecoration(labelText: loc.sampleUnitCustomLabel),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _sampleMethodCtrl,
                decoration: InputDecoration(labelText: loc.sampleMethodLabel),
              ),
              const SizedBox(height: 12),
            ],
            if (_type == MeasurementType.spectrum) ..._buildSpectrumSection(loc),
            if (_type == MeasurementType.meteorology) ...[
                for (final key in _metKeys) ...[
                  TextFormField(
                    controller: _metCtrls[key],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration:
                        InputDecoration(labelText: _metLabel(loc, key)),
                  ),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<PrecipitationState?>(
                  isExpanded: true,
                  initialValue: _precipitation,
                  decoration:
                      InputDecoration(labelText: loc.rrPrecipState),
                  items: [
                    const DropdownMenuItem<PrecipitationState?>(
                      value: null,
                      child: Text('—'),
                    ),
                    for (final s in PrecipitationState.values)
                      DropdownMenuItem<PrecipitationState?>(
                        value: s,
                        child: Text(s.localized(loc)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _precipitation = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _metOtherCtrl,
                  decoration:
                      InputDecoration(labelText: loc.rrMetOther),
                ),
                const SizedBox(height: 12),
            ],
            if (_type == MeasurementType.biological) ...[
                for (final b in _bios)
                  KeyedSubtree(key: ObjectKey(b), child: _bioEditor(b)),
                TextButton.icon(
                  onPressed: () => setState(() => _bios.add(_BioEdit())),
                  icon: const Icon(Icons.add),
                  label: Text(loc.rrAddBioAgent),
                ),
                const SizedBox(height: 12),
            ],
            if (_type == MeasurementType.gasMeasurement) ...[
                for (final g in _gases)
                  KeyedSubtree(key: ObjectKey(g), child: _gasEditor(g)),
                TextButton.icon(
                  onPressed: () => setState(
                    () => _gases.add(_GasEdit(species: gasSpecies.first.name)),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(loc.rrAddChemical),
                ),
                const SizedBox(height: 12),
            ],
            if (_type.usesRadioactiveSources) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.radio_button_checked),
              title: Text(loc.manageSourcesLabel),
              subtitle: Text(loc.sourcesCountLabel(_attachedSources.length)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openSources,
            ),
            if (_attachedSources.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSourcesSummaryPanel(loc),
            ],
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(labelText: loc.notesLabel),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildPhotoPicker(loc),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(loc.saveButton)),
          ],
        ),
      ),
    );
  }

  /// Mérési hiba (±) mező — átlagolt mérésnél automatikusan kitöltődik,
  /// kézzel feltöltött értéknél kézzel adható meg.
  Widget _buildErrorField(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _errorCtrl,
          decoration: InputDecoration(
            labelText: '${loc.measurementErrorLabel} (${_unitCtrl.text})',
            helperText: loc.measurementErrorHelper,
            helperMaxLines: 3,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            final t = (v ?? '').trim();
            if (t.isEmpty) return null;
            final n = double.tryParse(t.replaceAll(',', '.'));
            if (n == null) return loc.numberRequiredError;
            return null;
          },
          onChanged: (v) => setState(() {
            _errorTypedText = v;
            _avgSamples = null; // kézzel módosított hiba: nem átlagolt adat
            _avgSeconds = null;
          }),
        ),
        if (_avgSamples != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${loc.measurementAveragedLabel}: n=$_avgSamples'
              '${_avgSeconds == null ? '' : ', $_avgSeconds s'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _buildAveragingControls(AppLocalizations loc) {
    if (_isAveraging) {
      final stats = valueStats(_avgValues);
      final se = stats?.standardError;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: (_avgElapsed / _avgDuration).clamp(0.0, 1.0).toDouble()),
              const SizedBox(height: 8),
              Text('${loc.modbusAverageRunning}: n=${_avgValues.length} '
                  '($_avgElapsed / $_avgDuration s)'),
              if (stats != null)
                Text(se == null
                    ? QuantityField.formatNumber(stats.mean)
                    : formatValueWithError(stats.mean, se)),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() => _avgAbort = true),
                    child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _avgValues.isEmpty
                        ? null
                        : () => setState(() => _avgStop = true),
                    child: Text(loc.modbusAverageDone),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return Row(
      children: [
        DropdownButton<int>(
          value: _avgDuration,
          items: const [10, 30, 60, 120, 300]
              .map((s) => DropdownMenuItem(value: s, child: Text('$s s')))
              .toList(),
          onChanged: (v) => setState(() => _avgDuration = v ?? 60),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isQueryingModbus ? null : _startModbusAveraging,
            icon: const Icon(Icons.timeline),
            label: Text(loc.modbusAverageButton),
          ),
        ),
      ],
    );
  }

  Widget _buildGpsRow(AppLocalizations loc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _isFetchingGps
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _positionManuallySet
                            ? Icons.edit_location_alt
                            : Icons.gps_fixed,
                      ),
                const SizedBox(width: 8),
                Text(
                  loc.positionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (_gpsAccuracy != null)
                  Text(
                    '±${formatDistanceMeters(_gpsAccuracy!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latCtrl,
                    decoration: InputDecoration(labelText: loc.latitudeLabel),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    onChanged: (_) =>
                        setState(() => _positionManuallySet = true),
                    validator: (v) {
                      final parsed = parseDecimal(v ?? '');
                      if (parsed == null) return loc.invalidValueError;
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _lonCtrl,
                    decoration: InputDecoration(labelText: loc.longitudeLabel),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    onChanged: (_) =>
                        setState(() => _positionManuallySet = true),
                    validator: (v) {
                      final parsed = parseDecimal(v ?? '');
                      if (parsed == null) return loc.invalidValueError;
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_plan == null) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isFetchingGps ? null : _fetchGpsPosition,
                      icon: const Icon(Icons.my_location),
                      label: Text(loc.liveGpsButton),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openMapPicker,
                      icon: const Icon(Icons.map_outlined),
                      label: Text(loc.onMapButton),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isFetchingGps ? null : _averageGpsPosition,
                  icon: const Icon(Icons.filter_tilt_shift),
                  label: Text(loc.gpsAverageButton),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openMapPicker,
                  icon: const Icon(Icons.map_outlined),
                  label: Text(loc.onMapButton),
                ),
              ),
          if (_plan?.localCoordinates ?? false) _localPositionHint(loc),
          ],
        ),
      ),
    );
  }

  Widget _buildSourcesSummaryPanel(AppLocalizations loc) {
    final asOf = _editingPoint?.timestamp ?? DateTime.now();
    final (totalCalculatedUSvH, unknownCount) =
        _totalCalculatedDoseRateUSvH(asOf);

    final rows = <Widget>[
      _summaryRow(
        loc.totalCalculatedDoseRateLabel,
        formatDoseRateUSvH(totalCalculatedUSvH),
      ),
    ];

    if (unknownCount > 0) {
      rows.add(const SizedBox(height: 4));
      rows.add(
        Row(
          children: [
            Icon(Icons.info_outline,
                color: Theme.of(context).colorScheme.error, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                loc.sourcesUnknownNuclideSkippedNote(unknownCount),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    final measuredValue = parseDecimal(_valueCtrl.text);
    if (measuredValue == null) {
      rows.add(const Divider());
      rows.add(Text(loc.noMeasuredValueForComparisonNote));
    } else {
      final measuredUSvH =
          toMicroSievertPerHour(measuredValue, _unitCtrl.text.trim());
      rows.add(const Divider());
      if (measuredUSvH == null) {
        rows.add(
          Text(loc.unrecognizedUnitForComparisonNote(_unitCtrl.text.trim())),
        );
      } else {
        rows.add(_summaryRow(
          loc.measuredDoseRateResultLabel,
          formatDoseRateUSvH(measuredUSvH),
        ));
        final diff = measuredUSvH - totalCalculatedUSvH;
        final diffPercent = totalCalculatedUSvH == 0
            ? null
            : diff / totalCalculatedUSvH * 100;
        final diffText = diffPercent == null
            ? formatDoseRateUSvH(diff)
            : '${formatDoseRateUSvH(diff)} (${diffPercent >= 0 ? '+' : ''}${_formatValue(diffPercent)}%)';
        rows.add(_summaryRow(loc.doseRateDifferenceResultLabel, diffText));
      }
    }

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...rows,
            Align(
              alignment: Alignment.centerRight,
              child: DisclaimerInfoIcon(text: loc.sourceCalculationDisclaimer),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPhotoPicker(AppLocalizations loc) {
    return Row(
      children: [
        if (_photoPath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(_photoPath!),
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
        if (_photoPath != null) const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: _pickPhoto,
          icon: const Icon(Icons.camera_alt),
          label: Text(
            _photoPath == null ? loc.takePhotoLabel : loc.retakePhotoLabel,
          ),
        ),
      ],
    );
  }
}

/// Egy szerkesztés alatt álló árnyékoló réteg űrlap-állapota.
class _LayerEdit {
  _LayerEdit(this.material);
  ShieldingMaterial material;
  final TextEditingController ctrl = TextEditingController();
  DistanceUnit unit = DistanceUnit.cm;
}

/// Egy szerkesztés alatti biológiai anyag-sor a vezérlőivel.
class _BioEdit {
  _BioEdit({this.kind = BioKind.bacterium});

  BioKind kind;
  final nameCtrl = TextEditingController();
  final quantityCtrl = TextEditingController();

  void dispose() {
    nameCtrl.dispose();
    quantityCtrl.dispose();
  }
}

/// Egy szerkesztés alatti gázmérés-sor a vezérlőivel.
class _GasEdit {
  _GasEdit({
    required this.species,
    this.unit = const ConcentrationUnit.ratio(RatioUnit.ppm),
    this.state = PhysicalState.gas,
  });

  String species;
  ConcentrationUnit unit;
  PhysicalState state;
  final nameCtrl = TextEditingController();
  final formulaCtrl = TextEditingController();
  final concCtrl = TextEditingController();

  void dispose() {
    nameCtrl.dispose();
    formulaCtrl.dispose();
    concCtrl.dispose();
  }
}

/// Az alaprajz közepe mint flutter_map-koordináta (a picker kezdőpontja).
ll.LatLng _planCentreLatLng(PlanCalibration plan) {
  final c = PlanGeoref(plan).centre;
  return ll.LatLng(c.lat, c.lon);
}
