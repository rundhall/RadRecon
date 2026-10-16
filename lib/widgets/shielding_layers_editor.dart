import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/distance_unit.dart';
import '../models/shielding.dart';
import '../models/shielding_labels.dart';
import 'quantity_field.dart';

/// Egy szerkesztés alatt álló árnyékoló réteg űrlap-állapota.
class ShieldingLayerEdit {
  ShieldingLayerEdit(this.material);
  ShieldingMaterial material;
  final TextEditingController ctrl = TextEditingController();
  DistanceUnit unit = DistanceUnit.cm;
}

/// Az érvényes (pozitív vastagságú) rétegek, cm-re átváltva.
List<ShieldingLayer> validShieldingLayers(List<ShieldingLayerEdit> edits) {
  final out = <ShieldingLayer>[];
  for (final e in edits) {
    final v = double.tryParse(e.ctrl.text.trim());
    if (v != null && v > 0) {
      out.add(ShieldingLayer(e.material, e.unit.toMeters(v) * 100));
    }
  }
  return out;
}

/// Többrétegű árnyékolás szerkesztője (anyag + vastagság rétegenként).
/// A lista kezelése (és a controllerek felszabadítása) a hívó dolga.
class ShieldingLayersEditor extends StatelessWidget {
  const ShieldingLayersEditor({
    super.key,
    required this.layers,
    required this.onChanged,
  });

  final List<ShieldingLayerEdit> layers;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < layers.length; i++) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ShieldingMaterial>(
                  key: ValueKey('calc-layer-$i-${layers[i].material.name}'),
                  initialValue: layers[i].material,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: '${loc.shieldingLayerLabel} ${i + 1}: '
                        '${loc.shieldingMaterialLabel}',
                  ),
                  items: [
                    for (final m in ShieldingMaterial.values)
                      DropdownMenuItem(
                        value: m,
                        child: Text(shieldingMaterialLabel(loc, m)),
                      ),
                  ],
                  onChanged: (m) {
                    if (m != null) {
                      layers[i].material = m;
                      onChanged();
                    }
                  },
                ),
              ),
              IconButton(
                tooltip: loc.shieldingRemoveLayer,
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  layers.removeAt(i).ctrl.dispose();
                  onChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          QuantityField<DistanceUnit>(
            key: ValueKey('calc-layer-th-${layers[i].hashCode}'),
            controller: layers[i].ctrl,
            label: loc.shieldingThicknessLabel,
            units: DistanceUnit.values,
            unit: layers[i].unit,
            onUnitChanged: (u) {
              layers[i].unit = u;
              onChanged();
            },
            onChanged: onChanged,
          ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text(loc.shieldingAddLayer),
            onPressed: () {
              layers.add(ShieldingLayerEdit(ShieldingMaterial.lead));
              onChanged();
            },
          ),
        ),
      ],
    );
  }
}
