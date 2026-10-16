import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:file_selector/file_selector.dart' as fs;

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
import '../models/shielding.dart';
import '../models/shielding_labels.dart';
import '../models/distance_unit.dart';
import '../models/dose_rate_unit.dart';
import '../services/activity_estimate.dart';
import '../services/dose_unit_controller.dart';
import '../services/dose_unit_converter.dart';
import '../services/modbus_reader_service.dart';
import '../services/unit_format.dart';
import '../services/settings_service.dart';
import '../services/value_averager.dart';
import '../widgets/position_averaging_dialog.dart';
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

  const MeasurementEntryScreen({
    super.key,
    required this.surveySessionId,
    this.existingPoint,
  });

  @override
  State<MeasurementEntryScreen> createState() => _MeasurementEntryScreenState();
}

class _MeasurementEntryScreenState extends State<MeasurementEntryScreen> {
  final _formKey = GlobalKey<FormState>();

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

  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();
  double? _gpsAccuracy;
  bool _isFetchingGps = false;
  bool _positionManuallySet = false;

  bool _isSourcePosition = false;
  bool _isSample = false;

  int? _instrumentId;
  List<Instrument> _instruments = [];
  bool _isQueryingModbus = false;

  // Mérési hiba (±) és átlagolt Modbus-mérés.
  final _errorCtrl = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    _editingPoint = widget.existingPoint;
    _unitCtrl.text = _type.defaultUnit;
    _loadInstruments();
    if (_editingPoint != null) {
      _prefillFromExisting(_editingPoint!);
      _loadAttachedSources();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchGpsPosition();
      });
    }
  }

  void _prefillFromExisting(MeasurementPoint p) {
    _type = p.type;
    _locationLabelCtrl.text = p.locationLabel ?? '';
    _valueCtrl.text = p.value == null ? '' : _fmt(p.value!, 4);
    _errorCtrl.text =
        p.valueError == null ? '' : QuantityField.formatNumber(p.valueError!);
    _avgSamples = p.averagingSamples;
    _avgSeconds = p.averagingSeconds;
    _unitCtrl.text = p.unit;
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
    _sampleMethodCtrl.text = p.sampleMethod ?? '';
    _latCtrl.text = _fmt(p.latitude, 6);
    _lonCtrl.text = _fmt(p.longitude, 6);
    _gpsAccuracy = p.gpsAccuracyMeters;
    _isSourcePosition = p.isSourcePosition;
    _isSample = p.isSample;
    _instrumentId = p.instrumentId;
    _photoPath = p.photoPath;
  }

  Future<void> _loadInstruments() async {
    final instruments = await DatabaseHelper.instance.getInstruments();
    if (!mounted) return;
    setState(() => _instruments = instruments);
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
      final v = double.tryParse(e.ctrl.text.trim());
      if (v != null && v > 0) {
        out.add(ShieldingLayer(e.material, e.unit.toMeters(v) * 100));
      }
    }
    return out;
  }

  /// A "forrás távolság" mező értéke méterben (a választott egységből).
  double? _distanceMeters() {
    final v = double.tryParse(_distanceCtrl.text.trim());
    return v == null ? null : _distanceUnit.toMeters(v);
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
  Widget? _buildActivityFromMeasurementPanel(AppLocalizations loc) {
    final measuredValue = double.tryParse(_valueCtrl.text.trim());
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
                  final t = double.tryParse((v ?? '').trim());
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
          _isSample = false;
          _unitCtrl.text = _type.defaultUnit;
          _valueCtrl.text = QuantityField.formatNumber(
            instrumentReadingInAppUnit(instrument, result.value!),
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
      _isSample = false;
      _unitCtrl.text = _type.defaultUnit;
      _valueCtrl.text = QuantityField.formatNumber(stats.mean);
      final se = stats.standardError;
      _errorCtrl.text = se == null ? '' : QuantityField.formatNumber(se);
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

  Future<void> _openMapPicker() async {
    final currentLat = double.tryParse(_latCtrl.text.trim());
    final currentLon = double.tryParse(_lonCtrl.text.trim());
    final initialCenter = (currentLat != null && currentLon != null)
        ? ll.LatLng(currentLat, currentLon)
        : const ll.LatLng(47.4979, 19.0402); // Budapest, ha még nincs pozíció

    final picked = await Navigator.of(context).push<ll.LatLng>(
      MaterialPageRoute(
        builder: (_) => MapPointPickerScreen(initialCenter: initialCenter),
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

  Future<void> _pickPhoto() async {
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

    final source = await showModalBottomSheet<ImageSource>(
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
      locationLabel: _locationLabelCtrl.text.trim().isEmpty
          ? null
          : _locationLabelCtrl.text.trim(),
      latitude: latitude,
      longitude: longitude,
      gpsAccuracyMeters: _gpsAccuracy,
      type: _type,
      value: _valueCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_valueCtrl.text.trim()),
      valueError: _isSample || _errorCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_errorCtrl.text.trim().replaceAll(',', '.'))?.abs(),
      averagingSamples:
          _isSample || _errorCtrl.text.trim().isEmpty && _avgSamples == null
              ? null
              : _avgSamples,
      averagingSeconds:
          _isSample || _errorCtrl.text.trim().isEmpty && _avgSamples == null
              ? null
              : _avgSeconds,
      unit: _unitCtrl.text.trim(),
      distanceFromSourceMeters:
          _distanceCtrl.text.trim().isEmpty ? null : _distanceMeters(),
      activityCalcNuclide: _isSample ? null : _estimationNuclide,
      instrumentId: _instrumentId,
      nuclideStatus: _isSample ? NuclideIdStatus.notSpecified : _nuclideStatus,
      nuclides: !_isSample && _nuclideStatus.hasNuclideList ? _nuclides : const [],
      shieldingLayers: _isSample || _estimationNuclide == null
          ? const []
          : _validLayers(),
      isSourcePosition: _isSourcePosition,
      isSample: _isSample,
      sampleContainerId:
          _isSample && _sampleContainerCtrl.text.trim().isNotEmpty
          ? _sampleContainerCtrl.text.trim()
          : null,
      sampleAmount: _isSample && _sampleAmountCtrl.text.trim().isNotEmpty
          ? double.tryParse(_sampleAmountCtrl.text.trim())
          : null,
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
    final latitude = double.tryParse(_latCtrl.text.trim());
    final longitude = double.tryParse(_lonCtrl.text.trim());
    if (latitude == null || longitude == null) {
      _showError(AppLocalizations.of(context)!.noValidPositionError);
      return null;
    }

    final point = _buildPointFromForm(latitude: latitude, longitude: longitude);
    final id = await DatabaseHelper.instance.insertMeasurementPoint(point);
    if (!mounted) return null;
    final saved = point.copyWith(id: id);
    setState(() => _editingPoint = saved);
    return saved;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final latitude = double.tryParse(_latCtrl.text.trim());
    final longitude = double.tryParse(_lonCtrl.text.trim());
    if (latitude == null || longitude == null) {
      _showError(AppLocalizations.of(context)!.noValidPositionError);
      return;
    }

    // Azonosított / egyéb nuklidnál legalább egy nuklid nevét meg kell adni.
    if (!_isSample &&
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
      await DatabaseHelper.instance.insertMeasurementPoint(point);
    } else {
      await DatabaseHelper.instance.updateMeasurementPoint(
        _editingPoint!,
        point,
      );
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  /// A mentés előtt figyelmeztet, ha a mért érték eléri/túllépi a
  /// beállított riasztási küszöböt. Nem blokkolja a mentést — csak jelez.
  Future<void> _checkThresholdAndWarn(MeasurementPoint point) async {
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
                  _unitCtrl.text = t.defaultUnit;
                  _isSample = t == MeasurementType.sample;
                });
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
            if (_type != MeasurementType.sample) ...[
              if (_type == MeasurementType.doseRate &&
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
                    final err = double.tryParse(
                        _errorCtrl.text.trim().replaceAll(',', '.'));
                    if (old != null && err != null) {
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
                    if (double.tryParse(v.trim()) == null) {
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
                        if (double.tryParse(v.trim()) == null) {
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
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sampleMethodCtrl,
                decoration: InputDecoration(labelText: loc.sampleMethodLabel),
              ),
              const SizedBox(height: 12),
            ],
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
          onChanged: (_) => setState(() {
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
                      final parsed = double.tryParse((v ?? '').trim());
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
                      final parsed = double.tryParse((v ?? '').trim());
                      if (parsed == null) return loc.invalidValueError;
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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

    final measuredValue = double.tryParse(_valueCtrl.text.trim());
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
