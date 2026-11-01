import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../models/plan_calibration.dart';
import '../services/plan_georeference.dart';

/// Az alaprajz határa flutter_map-típusban.
LatLngBounds planLatLngBounds(PlanGeoref georef) {
  final b = georef.bounds;
  return LatLngBounds(ll.LatLng(b.south, b.west), ll.LatLng(b.north, b.east));
}

/// Kamera, amely az egész alaprajzot a képernyőre illeszti.
CameraFit planCameraFit(PlanGeoref georef) => CameraFit.bounds(
      bounds: planLatLngBounds(georef),
      padding: const EdgeInsets.all(24),
    );

/// Az alaprajz rétege a térképen. Csempe nélkül is látszik, így offline
/// módban is működik.
OverlayImageLayer planOverlayLayer(PlanCalibration calibration) {
  return OverlayImageLayer(
    overlayImages: [
      OverlayImage(
        imageProvider: FileImage(File(calibration.imagePath)),
        bounds: planLatLngBounds(PlanGeoref(calibration)),
      ),
    ],
  );
}
