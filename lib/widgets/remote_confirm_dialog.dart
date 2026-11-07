import 'package:flutter/material.dart';

import '../models/hardware_button.dart';
import '../services/hardware_buttons.dart';

/// Megerősítő párbeszédablak, amelyet Bluetooth-távirányítóval is lehet
/// kezelni. A mentés gomb megerősít (true), az eldobás gomb megszakít (false).
/// A képernyőn látható gombok ugyanúgy működnek, mint eddig.
Future<bool?> showRemoteConfirmDialog({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  var open = true;

  bool onButton(ButtonCommand command) {
    if (!open) return false;
    if (command == ButtonCommand.savePoint ||
        command == ButtonCommand.saveAndNewPoint) {
      open = false;
      navigator.pop(true);
      return true;
    }
    if (command == ButtonCommand.discardPoint) {
      open = false;
      navigator.pop(false);
      return true;
    }
    return false;
  }

  HardwareButtons.register(onButton);
  return showDialog<bool>(context: context, builder: builder).whenComplete(() {
    open = false;
    HardwareButtons.unregister(onButton);
  });
}
