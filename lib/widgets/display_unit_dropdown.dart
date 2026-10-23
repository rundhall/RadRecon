import 'package:flutter/material.dart';

import '../models/unit_catalog.dart';

/// Megjelenítési egység választó: zárt lista, az egységek a katalógusból.
/// Azonnal érvénybe lép (a `notifier` értéke változik).
class DisplayUnitDropdown extends StatelessWidget {
  const DisplayUnitDropdown({
    super.key,
    required this.label,
    required this.notifier,
    required this.category,
    required this.onChanged,
    this.autoLabel,
  });

  final String label;
  final ValueNotifier<String> notifier;
  final UnitCategory category;
  final void Function(String symbol) onChanged;

  /// Ha meg van adva, az első elem az automatikus (üres) választás.
  final String? autoLabel;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: notifier,
      builder: (context, current, _) {
        return DropdownButtonFormField<String>(
          key: ValueKey('$label-$current'),
          initialValue: current,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [
            if (autoLabel != null)
              DropdownMenuItem(value: '', child: Text(autoLabel!)),
            for (final u in UnitCatalog.unitsOf(category))
              DropdownMenuItem(value: u.symbol, child: Text(u.symbol)),
          ],
          onChanged: (s) {
            if (s != null) onChanged(s);
          },
        );
      },
    );
  }
}
