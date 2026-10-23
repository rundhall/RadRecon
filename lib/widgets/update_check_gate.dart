import 'package:flutter/material.dart';

import '../services/app_update_service.dart';
import 'app_update_dialog.dart';

/// Checks for a newer version on start and whenever the app comes back to
/// the foreground. Sits above the home screen so the dialog has a Navigator.
class UpdateCheckGate extends StatefulWidget {
  final Widget child;

  const UpdateCheckGate({super.key, required this.child});

  @override
  State<UpdateCheckGate> createState() => _UpdateCheckGateState();
}

class _UpdateCheckGateState extends State<UpdateCheckGate>
    with WidgetsBindingObserver {
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _check();
    }
  }

  Future<void> _check() async {
    if (_dialogOpen || !mounted) return;

    final info = await AppUpdateService.checkForUpdate();
    if (info == null || !mounted || _dialogOpen) return;

    _dialogOpen = true;
    try {
      await showAppUpdateDialog(context, info);
    } finally {
      _dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
