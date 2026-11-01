import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../l10n/app_localizations.dart';
import '../models/plan_calibration.dart';
import '../services/plan_georeference.dart';
import '../widgets/plan_map_layers.dart';

/// Térképen koppintva választható ki egy pozíció — arra az esetre, ha a
/// mérés helye nem egyezik a telefon aktuális GPS-fixével (beltér, vagy
/// utólagos/máshol történő rögzítés).
class MapPointPickerScreen extends StatefulWidget {
  final ll.LatLng initialCenter;
  /// Alaprajz mód: ha meg van adva, az alaprajzon kell koordinátát választani.
  final PlanCalibration? plan;

  const MapPointPickerScreen({
    super.key,
    required this.initialCenter,
    this.plan,
  });

  @override
  State<MapPointPickerScreen> createState() => _MapPointPickerScreenState();
}

class _MapPointPickerScreenState extends State<MapPointPickerScreen> {
  late ll.LatLng _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.initialCenter;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.pickPositionTitle)),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _picked,
              initialZoom: 17,
              initialCameraFit: widget.plan == null
                  ? null
                  : planCameraFit(PlanGeoref(widget.plan!)),
              onTap: (tapPosition, point) => setState(() => _picked = point),
            ),
            children: [
              if (widget.plan != null) planOverlayLayer(widget.plan!),
              if (widget.plan == null)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.rundhall.rad_recon',
                ),
              if (widget.plan == null)
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
              MarkerLayer(
                markers: [
                  Marker(
                    point: _picked,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_picked.latitude.toStringAsFixed(6)}, ${_picked.longitude.toStringAsFixed(6)}',
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(_picked),
                          icon: const Icon(Icons.check),
                          label: Text(loc.confirmPositionButton),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}