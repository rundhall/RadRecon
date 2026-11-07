import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/hardware_button.dart';
import '../services/hardware_buttons.dart';

/// Saját kamera-nézet fényképezéshez. A rendszer kamera-alkalmazásának
/// "OK" megerősítése Bluetooth-gombbal nem nyomható meg, ezért itt a
/// takePhoto parancs azonnal készít képet és visszatér a fájl útvonalával.
class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  bool _failed = false;
  bool _busy = false;
  late final ButtonCommandHandler _buttonHandler = _onButton;

  @override
  void initState() {
    super.initState();
    HardwareButtons.register(_buttonHandler);
    _open();
  }

  Future<void> _open() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw StateError('no camera');
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  bool _onButton(ButtonCommand command) {
    if (command != ButtonCommand.takePhoto) return false;
    _capture();
    return true;
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _busy || !controller.value.isInitialized) {
      return;
    }
    setState(() => _busy = true);
    try {
      final photo = await controller.takePicture();
      if (mounted) Navigator.of(context).pop(photo.path);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    HardwareButtons.unregister(_buttonHandler);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(loc.takePhotoLabel)),
      body: _failed
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  loc.cameraUnavailableError,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
          : controller == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    Positioned.fill(child: CameraPreview(controller)),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: FloatingActionButton.large(
                          onPressed: _busy ? null : _capture,
                          child: const Icon(Icons.camera_alt),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
