import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../l10n/app_localizations.dart';
import '../models/plan_calibration.dart';
import '../services/plan_georeference.dart';
import '../widgets/position_averaging_dialog.dart';

/// Az alaprajz kalibrálása. Feltöltött képnél a méretarány az A–B távolságból
/// adódik. Generált háttérnél ([fixedMetersPerPx]) a méretarány adott.
/// A horgony lehet kint átlagolt GPS-koordináta, vagy GPS nélküli helyi
/// koordináta ([localCoordinates]), ahol nincs földrajzi horgony.
/// Visszatérési érték a kész [PlanCalibration]; mentés nélküli kilépésnél `null`.
class PlanCalibrationScreen extends StatefulWidget {
  final String imagePath;
  final int widthPx;
  final int heightPx;
  final double? fixedMetersPerPx;

  const PlanCalibrationScreen({
    super.key,
    required this.imagePath,
    required this.widthPx,
    required this.heightPx,
    this.fixedMetersPerPx,
  });

  @override
  State<PlanCalibrationScreen> createState() => _PlanCalibrationScreenState();
}

class _PlanCalibrationScreenState extends State<PlanCalibrationScreen> {
  final _transform = TransformationController();
  bool _fitted = false;
  bool _settingB = false; // a következő koppintás az A (false) vagy a B (true) pont
  bool _localMode = false; // GPS nélküli, helyi koordináta
  Offset? _pointA; // pixelkoordináta
  Offset? _pointB;
  double? _anchorLat; // az A pont GPS-szélessége
  double? _anchorLon; // az A pont GPS-hosszúsága
  double? _anchorAccuracy; // az átlagolt GPS pontossága (m)
  double? _realMeters; // A és B valós távolsága
  String? _errorText;
  bool _busy = false;

  bool get _isFixedScale => widget.fixedMetersPerPx != null;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  double? _parseNumber(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _errorText = message;
      _busy = false;
    });
  }

  void _onTap(Offset local) {
    setState(() {
      if (_settingB && !_isFixedScale) {
        _pointB = local;
      } else {
        _pointA = local;
      }
    });
  }

  /// Az A pont GPS-koordinátája kint, átlagolva (a szokásos átlagoló dialógussal).
  Future<void> _averageAnchorGps() async {
    final loc = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _errorText = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _fail(loc.locationServiceDisabledError);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _fail(loc.locationPermissionDeniedError);
        return;
      }
      if (!mounted) return;
      final result = await showPositionAveragingDialog(context);
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (result != null) {
          _anchorLat = result.latitude;
          _anchorLon = result.longitude;
          _anchorAccuracy = result.accuracyMeters;
          _errorText = null;
        }
      });
    } catch (_) {
      _fail(loc.planGpsFailed);
    }
  }

  Future<void> _enterAnchorManually() async {
    final loc = AppLocalizations.of(context)!;
    final latCtrl = TextEditingController(text: _anchorLat?.toString() ?? '');
    final lonCtrl = TextEditingController(text: _anchorLon?.toString() ?? '');
    const numberKeyboard =
        TextInputType.numberWithOptions(decimal: true, signed: true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.planCoordDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latCtrl,
              keyboardType: numberKeyboard,
              decoration: InputDecoration(labelText: loc.planLatLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lonCtrl,
              keyboardType: numberKeyboard,
              decoration: InputDecoration(labelText: loc.planLonLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.okButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final lat = _parseNumber(latCtrl.text);
    final lon = _parseNumber(lonCtrl.text);
    if (lat == null || lon == null || lat.abs() > 90 || lon.abs() > 180) {
      _fail(loc.planInvalidValue);
      return;
    }
    setState(() {
      _anchorLat = lat;
      _anchorLon = lon;
      _anchorAccuracy = null;
      _errorText = null;
    });
  }

  Future<void> _enterDistance() async {
    final loc = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: _realMeters?.toString() ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.planDistanceLabel),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: loc.planDistanceLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.okButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final meters = _parseNumber(ctrl.text);
    if (meters == null || meters <= 0) {
      _fail(loc.planInvalidValue);
      return;
    }
    setState(() {
      _realMeters = meters;
      _errorText = null;
    });
  }

  /// A méretarány: generált háttérnél a rögzített, feltöltött képnél az A–B
  /// távolságból számolt érték. `null`, ha még nincs elég adat.
  double? _metersPerPx() {
    final fixed = widget.fixedMetersPerPx;
    if (fixed != null) return fixed;
    final a = _pointA;
    final b = _pointB;
    final real = _realMeters;
    if (a == null || b == null || real == null) return null;
    final pxDist = pixelDistance(a.dx, a.dy, b.dx, b.dy);
    if (pxDist <= 0) return null;
    return metersPerPixelFromCalibration(
      pixelDistance: pxDist,
      realMeters: real,
    );
  }

  /// A kész kalibráció: helyi módban a fix origó, GPS-módban az A pont horgonya.
  PlanCalibration? _buildCalibration() {
    final mpp = _metersPerPx();
    if (mpp == null) return null;
    var originLat = localPlanOriginLat;
    var originLon = localPlanOriginLon;
    if (!_localMode) {
      final a = _pointA;
      final lat = _anchorLat;
      final lon = _anchorLon;
      if (a == null || lat == null || lon == null) return null;
      final origin = originFromAnchor(
        anchorX: a.dx,
        anchorY: a.dy,
        anchorLat: lat,
        anchorLon: lon,
        metersPerPx: mpp,
      );
      originLat = origin.lat;
      originLon = origin.lon;
    }
    return PlanCalibration(
      imagePath: widget.imagePath,
      widthPx: widget.widthPx,
      heightPx: widget.heightPx,
      originLat: originLat,
      originLon: originLon,
      metersPerPx: mpp,
      localCoordinates: _localMode,
    );
  }

  Widget _marker(Offset at, Color color, String label) => Positioned(
        left: at.dx - 12,
        top: at.dy - 40,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                backgroundColor: Colors.white70,
              ),
            ),
            Icon(Icons.place, color: color, size: 24),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final w = widget.widthPx.toDouble();
    final h = widget.heightPx.toDouble();
    final calibration = _buildCalibration();
    final hint = _localMode
        ? loc.planLocalModeHint
        : (_isFixedScale ? loc.planCalibrationHintGenerated : loc.planCalibrationHint);
    return Scaffold(
      appBar: AppBar(title: Text(loc.planCalibrationTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(hint),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (!_fitted) {
                  _fitted = true;
                  final fit = math.min(
                    constraints.maxWidth / w,
                    constraints.maxHeight / h,
                  );
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _transform.value = Matrix4.identity()
                        ..scaleByDouble(fit, fit, fit, 1);
                    }
                  });
                }
                return InteractiveViewer(
                  transformationController: _transform,
                  constrained: false,
                  minScale: 0.05,
                  maxScale: 10,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) => _onTap(d.localPosition),
                    child: SizedBox(
                      width: w,
                      height: h,
                      child: Stack(
                        children: [
                          Image.file(
                            File(widget.imagePath),
                            width: w,
                            height: h,
                            fit: BoxFit.fill,
                          ),
                          if (_pointA != null) _marker(_pointA!, Colors.green, 'A'),
                          if (_pointB != null) _marker(_pointB!, Colors.blue, 'B'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_isFixedScale) ...[
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: false, label: Text(loc.planPointA)),
                      ButtonSegment(value: true, label: Text(loc.planPointB)),
                    ],
                    selected: {_settingB},
                    onSelectionChanged: (s) => setState(() => _settingB = s.first),
                  ),
                  const SizedBox(height: 8),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(loc.planLocalModeSwitch),
                  value: _localMode,
                  onChanged: (v) => setState(() {
                    _localMode = v;
                    _anchorLat = null;
                    _anchorLon = null;
                    _anchorAccuracy = null;
                    _errorText = null;
                  }),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (!_localMode)
                      OutlinedButton(
                        onPressed: _busy ? null : _averageAnchorGps,
                        child: Text(loc.planGpsAtAButton),
                      ),
                    if (!_localMode)
                      OutlinedButton(
                        onPressed: _enterAnchorManually,
                        child: Text(loc.planManualCoordButton),
                      ),
                    if (!_isFixedScale)
                      OutlinedButton(
                        onPressed: (_pointA != null && _pointB != null)
                            ? _enterDistance
                            : null,
                        child: Text(loc.planDistanceButton),
                      ),
                  ],
                ),
                if (!_localMode && _anchorLat != null && _anchorLon != null)
                  Text(
                    'A: ${_anchorLat!.toStringAsFixed(6)}, '
                    '${_anchorLon!.toStringAsFixed(6)}',
                  ),
                if (!_localMode && _anchorAccuracy != null)
                  Text(
                    '${loc.planAccuracyLabel}: '
                    '±${_anchorAccuracy!.toStringAsFixed(1)} m',
                  ),
                if (!_isFixedScale && _realMeters != null)
                  Text(
                    '${loc.planDistanceLabel}: '
                    '${_realMeters!.toStringAsFixed(2)} m',
                  ),
                if (_errorText != null)
                  Text(_errorText!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: calibration == null
                      ? null
                      : () => Navigator.of(context).pop(calibration),
                  child: Text(loc.planSaveButton),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
