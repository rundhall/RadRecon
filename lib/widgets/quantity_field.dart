import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/quantity_unit.dart';
import '../services/number_input.dart';

/// Egységváltáskor a mezőben lévő szám új szövege.
///
/// - Kézzel beírt számnál a szám marad: a felhasználó a számot már az új
///   egységben adta meg (beírta a 30-at, majd cm-t választott → 30 cm).
/// - Programmal kitöltött értéknél (pl. mentett pont) a fizikai mennyiség
///   marad, vagyis átszámolunk (0,3 m → 30 cm).
String unitChangeText({
  required String text,
  required bool typedByUser,
  required double fromBase,
  required double toBase,
}) {
  if (typedByUser) return text;
  final v = parseDecimal(text);
  if (v == null) return text;
  return QuantityField.formatNumber(v * fromBase / toBase);
}

/// Szám + mértékegység-választó (legördülő lista).
///
/// Egységváltáskor a kézzel beírt szám változatlan marad, mert a felhasználó
/// az új egységben gondolta. A programmal kitöltött érték (pl. mentett pont)
/// fizikai mennyisége viszont megmarad, a szám átszámolódik.
class QuantityField<U extends QuantityUnit> extends StatefulWidget {
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

  @override
  State<QuantityField<U>> createState() => _QuantityFieldState<U>();
}

class _QuantityFieldState<U extends QuantityUnit>
    extends State<QuantityField<U>> {
  /// Az utoljára kézzel beírt szöveg. Ha a mező szövege ettől eltér,
  /// a számot a program töltötte ki.
  String? _typedText;

  void _changeUnit(U next) {
    final unit = widget.unit;
    if (next == unit) return;
    final typedByUser =
        _typedText != null && widget.controller.text == _typedText;
    widget.controller.text = unitChangeText(
      text: widget.controller.text,
      typedByUser: typedByUser,
      fromBase: unit.baseFactor,
      toBase: next.baseFactor,
    );
    widget.onUnitChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final unit = widget.unit;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: widget.controller,
            autofocus: widget.autofocus,
            decoration: InputDecoration(
              labelText: widget.label,
              errorText: widget.errorText,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: widget.validator,
            onChanged: (v) {
              _typedText = v;
              widget.onChanged?.call();
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: widget.unitWidth,
          child: DropdownButtonFormField<U>(
            key: ValueKey('unit-${unit.symbol}'),
            initialValue: unit,
            isExpanded: true,
            decoration: InputDecoration(labelText: loc.unitLabel),
            items: [
              for (final u in widget.units)
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
