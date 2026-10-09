import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Kis "i" infó gomb a kalkulátor-panelekhez: kattintásra egy rövid
/// dialógusban jeleníti meg a tájékoztató szöveget (pl. hogy a számított
/// érték csak referencia jellegű), így az nem foglal helyet minden
/// panelen kiírva.
class DisclaimerInfoIcon extends StatelessWidget {
  final String text;

  const DisclaimerInfoIcon({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        icon: const Icon(Icons.info_outline, size: 18),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              content: Text(text),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.okButton),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
