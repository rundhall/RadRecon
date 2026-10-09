import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:file_selector/file_selector.dart' as fs;

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/instrument.dart';
import '../models/isotope.dart';
import '../models/measurement_point.dart';
import '../models/measurement_type.dart';
import '../models/point_source_link.dart';
import '../services/dose_unit_converter.dart';
import '../services/modbus_reader_service.dart';
import '../services/settings_service.dart';
import '../widgets/disclaimer_info_icon.dart';
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
  String _activityCalcNuclide = 'Cs-137';

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
    _unitCtrl.text = p.unit;
    _distanceCtrl.text = p.distanceFromSourceMeters == null
        ? ''
        : _fmt(p.distanceFromSourceMeters!, 2);
    _activityCalcNuclide = p.activityCalcNuclide ?? 'Cs-137';
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

  Future<void> _openSources() async {
    final point = await _ensureSavedForSourceLink();
    if (point == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PointSourceLinkScreen(
              measurementPoint: point,
              initialDistanceMeters:
                  double.tryParse(_distanceCtrl.text.trim()),
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
    final distance = double.tryParse(_distanceCtrl.text.trim());
    if (measuredValue == null || distance == null || distance <= 0) {
      return null;
    }

    final isotope = Isotope.findByName(_activityCalcNuclide);
    if (isotope == null) return null;

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

    final activityMBq = isotope.activityFrom(
      doseRateUSvH: measuredUSvH,
      distanceM: distance,
    );
    final activityGBq = activityMBq / 1000;

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.estimatedActivityFromMeasurementLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              loc.calculatedActivityResult(
                _formatValue(activityMBq),
                _formatValue(activityGBq),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: DisclaimerInfoIcon(text: loc.sourceCalculationDisclaimer),
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
          _valueCtrl.text = _fmt(result.value!, 4);
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
      unit: _unitCtrl.text.trim(),
      distanceFromSourceMeters: _distanceCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_distanceCtrl.text.trim()),
      activityCalcNuclide: _activityCalcNuclide,
      instrumentId: _instrumentId,
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
    if (threshold == null || point.value! < threshold) return;
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
            '${double.parse(point.value!.toStringAsFixed(4))}',
            point.unit,
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
    _valueCtrl.dispose();
    _unitCtrl.dispose();
    _distanceCtrl.dispose();
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _distanceCtrl,
                      decoration: InputDecoration(
                        labelText: loc.distanceFromSourceLabel,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _activityCalcNuclide,
                      decoration: InputDecoration(
                        labelText: loc.nuclideLabel,
                      ),
                      items: kKnownIsotopes
                          .map(
                            (i) => DropdownMenuItem(
                              value: i.name,
                              child: Text(i.name),
                            ),
                          )
                          .toList(),
                      onChanged: (name) {
                        if (name == null) return;
                        setState(() => _activityCalcNuclide = name);
                      },
                    ),
                  ),
                ],
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
                    '±${_gpsAccuracy!.toStringAsFixed(1)} m',
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
        '${_formatValue(totalCalculatedUSvH)} µSv/h',
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
          '${_formatValue(measuredUSvH)} µSv/h',
        ));
        final diff = measuredUSvH - totalCalculatedUSvH;
        final diffPercent = totalCalculatedUSvH == 0
            ? null
            : diff / totalCalculatedUSvH * 100;
        final diffText = diffPercent == null
            ? '${_formatValue(diff)} µSv/h'
            : '${_formatValue(diff)} µSv/h (${diffPercent >= 0 ? '+' : ''}${_formatValue(diffPercent)}%)';
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
