import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/quantity_unit.dart';

/// Szám + mértékegység-választó (legördülő lista). A felhasználó csak számot
/// gépel, az egységet listából választja, így az átváltás nem rontható el.
///
/// Egységváltáskor a mezőben lévő szám automatikusan átváltódik az új
/// egységre, hogy a megjelenített érték fizikailag ugyanaz maradjon.
class QuantityField<U extends QuantityUnit> extends StatelessWidget {
  const QuantityField({
    super.key,
    required this.controller,
    required this.label,
    required this.units,
    required this.unit,
    required this.onUnitChanged,
    this.validator,
    this.onChanged,
    this.autofocus = false,
    this.errorText,
    this.unitWidth = 118,
  });

  final TextEditingController controller;
  final String label;
  final List<U> units;
  final U unit;
  final ValueChanged<U> onUnitChanged;
  final String? Function(String?)? validator;
  final VoidCallback? onChanged;
  final bool autofocus;
  final String? errorText;
  final double unitWidth;

  /// Szám szöveggé alakítása: ne maradjanak lebegőpontos farkak.
  static String formatNumber(double v) =>
      double.parse(v.toStringAsPrecision(8)).toString();

  void _changeUnit(U next) {
    if (next == unit) return;
    final current = double.tryParse(controller.text.trim());
    if (current != null) {
      final converted = current * unit.baseFactor / next.baseFactor;
      controller.text = formatNumber(converted);
    }
    onUnitChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            autofocus: autofocus,
            decoration: InputDecoration(labelText: label, errorText: errorText),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: validator,
            onChanged: (_) => onChanged?.call(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: unitWidth,
          child: DropdownButtonFormField<U>(
            key: ValueKey('unit-${unit.symbol}'),
            initialValue: unit,
            isExpanded: true,
            decoration: InputDecoration(labelText: loc.unitLabel),
            items: [
              for (final u in units)
                DropdownMenuItem<U>(value: u, child: Text(u.symbol)),
            ],
            onChanged: (u) {
              if (u != null) _changeUnit(u);
            },
          ),
        ),
      ],
    );
  }
}
