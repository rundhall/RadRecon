import 'package:flutter/material.dart';

import '../models/distance_unit.dart';
import '../services/number_input.dart';
import 'quantity_field.dart';

/// A távolság méterben számított értékének visszajelzése, ha a bevitel nem
/// méterben történt. Így a rossz egység (pl. cm helyett m) mentés előtt látszik.
class DistanceEcho extends StatelessWidget {
  const DistanceEcho({super.key, required this.text, required this.unit});

  final String text;
  final DistanceUnit unit;

  /// A kiírandó szöveg, vagy `null`, ha nincs mit mutatni (méter a bevitel
  /// egysége, vagy nem értelmezhető a szám).
  static String? meterText(String text, DistanceUnit unit) {
    if (unit == DistanceUnit.m) return null;
    final v = parseDecimal(text);
    if (v == null || v < 0) return null;
    final meters = unit.toMeters(v);
    return '= ${QuantityField.formatNumber(meters)} ${DistanceUnit.m.symbol}';
  }

  @override
  Widget build(BuildContext context) {
    final s = meterText(text, unit);
    if (s == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(s, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
