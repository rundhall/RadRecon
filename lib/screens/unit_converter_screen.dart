import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/domain_labels.dart';
import '../models/gas_reading.dart';
import '../models/unit_catalog.dart';
import '../services/number_input.dart';

/// Mértékegység-váltó: a kiválasztott mennyiség összes egységére egyszerre
/// átszámolja a beírt értéket. Egy sorra koppintva az érték arra az egységre
/// íródik át, és az lesz a kiindulási egység.
class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  UnitCategory _category = UnitCategory.dose;
  int _fromIndex = 0;
  final _valueCtrl = TextEditingController();
  final _molarCtrl = TextEditingController();
  String? _gasName; // a gázlistából választott vegyület (tárolt, magyar név)

  @override
  void dispose() {
    _valueCtrl.dispose();
    _molarCtrl.dispose();
    super.dispose();
  }

  String _categoryName(AppLocalizations loc, UnitCategory c) => switch (c) {
        UnitCategory.dose => loc.unitCatDose,
        UnitCategory.doseRate => loc.unitCatDoseRate,
        UnitCategory.activity => loc.unitCatActivity,
        UnitCategory.activityConcentration => loc.unitCatActivityConcentration,
        UnitCategory.surfaceContamination => loc.unitCatSurfaceContamination,
        UnitCategory.countRate => loc.unitCatCountRate,
        UnitCategory.length => loc.unitCatLength,
        UnitCategory.area => loc.unitCatArea,
        UnitCategory.volume => loc.unitCatVolume,
        UnitCategory.mass => loc.unitCatMass,
        UnitCategory.temperature => loc.unitCatTemperature,
        UnitCategory.pressure => loc.unitCatPressure,
        UnitCategory.speed => loc.unitCatSpeed,
        UnitCategory.time => loc.unitCatTime,
        UnitCategory.irradiance => loc.unitCatIrradiance,
        UnitCategory.rainRate => loc.unitCatRainRate,
        UnitCategory.massConcentration => loc.unitCatMassConcentration,
        UnitCategory.gasConcentration => loc.unitCatGasConcentration,
      };

  /// Szám kiírása: normál tartományban 6 jegy, szélsőségesen exponenciálisan.
  String _fmt(double? v) {
    if (v == null) return '—';
    if (v == 0) return '0';
    final a = v.abs();
    var s = (a >= 1e6 || a < 1e-3)
        ? v.toStringAsExponential(4)
        : v.toStringAsPrecision(6);
    if (!s.contains('e') && s.contains('.')) {
      s = s.replaceFirst(RegExp(r'\.?0+$'), '');
    }
    return s;
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      );

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final units = UnitCatalog.unitsOf(_category);
    final from = units[_fromIndex];
    final value = parseDecimal(_valueCtrl.text);
    final molar = parseDecimal(_molarCtrl.text);
    final isGas = _category == UnitCategory.gasConcentration;

    double? convertTo(UnitDef to) => value == null
        ? null
        : UnitCatalog.convert(
            from: from,
            to: to,
            value: value,
            molarMass: molar,
          );

    return Scaffold(
      appBar: AppBar(title: Text(loc.unitConverterTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _label(loc.unitConverterCategoryLabel),
          DropdownButton<UnitCategory>(
            isExpanded: true,
            value: _category,
            items: [
              for (final c in UnitCategory.values)
                DropdownMenuItem(
                  value: c,
                  child: Text(_categoryName(loc, c),
                      overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (c) {
              if (c == null) return;
              setState(() {
                _category = c;
                _fromIndex = 0;
                _gasName = null;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: InputDecoration(labelText: loc.unitConverterValueLabel),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _label(loc.unitConverterFromLabel),
          DropdownButton<int>(
            isExpanded: true,
            value: _fromIndex,
            items: [
              for (var i = 0; i < units.length; i++)
                DropdownMenuItem(value: i, child: Text(units[i].symbol)),
            ],
            onChanged: (i) {
              if (i != null) setState(() => _fromIndex = i);
            },
          ),
          if (isGas) ...[
            const SizedBox(height: 12),
            _label(loc.unitConverterGasPick),
            DropdownButton<String>(
              isExpanded: true,
              hint: Text(loc.unitConverterGasPick),
              value: _gasName,
              items: [
                for (final s in gasSpecies)
                  DropdownMenuItem(
                    value: s.name,
                    child: Text(
                      '${localizedGasName(loc, s.name)} (${s.formula})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (name) {
                if (name == null) return;
                final m = molarMassOf(name);
                setState(() {
                  _gasName = name;
                  // A VOC és NOx nincs egyetlen moláris tömeggel: a mező üres marad.
                  _molarCtrl.text = m == null ? '' : m.toString();
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _molarCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: loc.unitConverterMolarMassLabel,
                helperText: loc.unitConverterMolarMassHint,
                helperMaxLines: 3,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 16),
          if (value == null)
            Text(loc.unitConverterEnterValue)
          else
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < units.length; i++)
                    ListTile(
                      dense: true,
                      selected: i == _fromIndex,
                      title: Text(units[i].symbol),
                      trailing: Text(
                        i == _fromIndex
                            ? _fmt(value)
                            : _fmt(convertTo(units[i])),
                        style: TextStyle(
                          fontWeight: i == _fromIndex
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        final converted = convertTo(units[i]);
                        setState(() {
                          if (converted != null) {
                            _valueCtrl.text = _fmt(converted);
                          }
                          _fromIndex = i;
                        });
                      },
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(loc.unitConverterTapHint,
              style: Theme.of(context).textTheme.bodySmall),
          if (isGas && molar == null && value != null) ...[
            const SizedBox(height: 8),
            Text(loc.unitConverterNeedsMolarMass,
                style: Theme.of(context).textTheme.bodySmall),
          ],
          if (isGas) ...[
            const SizedBox(height: 8),
            Text(loc.unitConverterGasNote,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
