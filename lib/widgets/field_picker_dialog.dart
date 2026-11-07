import 'package:flutter/material.dart';

/// Jelölőnégyzetes ablak a megjelenítendő adatcsoportok kiválasztásához.
/// A "Mégse" nem ment; a mentés a kiválasztott készletet adja vissza.
Future<Set<T>?> showFieldPickerDialog<T extends Enum>({
  required BuildContext context,
  required String title,
  required List<T> values,
  required String Function(T) labelOf,
  required Set<T> selected,
  required String cancelLabel,
  required String saveLabel,
}) {
  final chosen = <T>{...selected};
  return showDialog<Set<T>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (ctx, setDialog) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final f in values)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(labelOf(f)),
                  value: chosen.contains(f),
                  onChanged: (v) => setDialog(() {
                    if (v == true) {
                      chosen.add(f);
                    } else {
                      chosen.remove(f);
                    }
                  }),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(chosen),
            child: Text(saveLabel),
          ),
        ],
      ),
    ),
  );
}
