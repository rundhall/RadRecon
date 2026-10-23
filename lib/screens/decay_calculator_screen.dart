import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/activity_unit.dart';
import '../models/decay.dart';
import '../models/isotope.dart';
import '../models/unit_catalog.dart';
import '../services/number_input.dart';
import '../services/unit_format.dart';

enum _Mode { forward, backward }

/// Bomlás-számító: aktivitás t idő után, vagy az idő, amíg egy célaktivitásig
/// csökken. Ismert izotópnál a felezési idő és a gamma-állandó a
/// törzsadatokból jön; egyéb nuklidnál a felezési időt kézzel kell megadni.
class DecayCalculatorScreen extends StatefulWidget {
  const DecayCalculatorScreen({super.key});

  @override
  State<DecayCalculatorScreen> createState() => _DecayCalculatorScreenState();
}

class _DecayCalculatorScreenState extends State<DecayCalculatorScreen> {
  static const _customKey = '__custom__';
  static final _timeUnits = UnitCatalog.unitsOf(UnitCategory.time);

  String _isotopeKey = kKnownIsotopes.first.name;
  _Mode _mode = _Mode.forward;
  ActivityUnit _actUnit = ActivityUnit.megaBq;
  int _halfUnitIndex = 3; // nap
  int _timeUnitIndex = 3; // nap

  final _halfCtrl = TextEditingController();
  final _a0Ctrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _distCtrl = TextEditingController();

  @override
  void dispose() {
    _halfCtrl.dispose();
    _a0Ctrl.dispose();
    _timeCtrl.dispose();
    _targetCtrl.dispose();
    _distCtrl.dispose();
    super.dispose();
  }

  Isotope? get _isotope =>
      _isotopeKey == _customKey ? null : Isotope.findByName(_isotopeKey);

  /// Felezési idő másodpercben, ha ismert.
  double? _halfLifeSeconds() {
    final iso = _isotope;
    if (iso != null) {
      final d = iso.halfLifeDays;
      return d == null ? null : d * 86400;
    }
    final v = parseDecimal(_halfCtrl.text);
    return v == null ? null : v * _timeUnits[_halfUnitIndex].factor;
  }

  String _fmtNum(double v) {
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

  Widget _results(
    AppLocalizations loc,
    Isotope? iso,
    double? half,
    double? a0,
    double? timeVal,
    double? target,
    double? dist,
  ) {
    final body = Theme.of(context).textTheme.bodyLarge;
    if (half == null) return Text(loc.decayCalcNoHalfLife);
    if (a0 == null || a0 < 0) return Text(loc.decayCalcNeedsInput);
    final unit = _actUnit;

    if (_mode == _Mode.forward) {
      if (timeVal == null || timeVal < 0) return Text(loc.decayCalcNeedsInput);
      final tSec = timeVal * _timeUnits[_timeUnitIndex].factor;
      final frac = remainingFraction(elapsedSeconds: tSec, halfLifeSeconds: half);
      final aMBq = a0 * unit.mbqFactor * frac;
      final lines = <String>[
        '${loc.decayCalcResultActivity}: ${_fmtNum(unit.fromMBq(aMBq))} ${unit.symbol}',
        '${loc.decayCalcResultRemaining}: ${_fmtNum(frac * 100)} %',
        '${loc.decayCalcResultHalfLives}: ${_fmtNum(tSec / half)}',
      ];
      if (iso != null && dist != null && dist > 0) {
        final rate = iso.doseRateAt(activityMBq: aMBq, distanceM: dist);
        lines.add('${loc.decayCalcResultDoseRate}: ${formatDoseRateUSvH(rate)}');
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final l in lines)
            Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(l, style: body)),
        ],
      );
    }

    if (target == null) return Text(loc.decayCalcNeedsInput);
    final sec = timeToReachSeconds(halfLifeSeconds: half, a0: a0, target: target);
    if (sec == null) return Text(loc.decayCalcErrorTarget);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${loc.decayCalcResultTime}:', style: body),
        for (final u in _timeUnits)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('${_fmtNum(sec / u.factor)} ${u.symbol}', style: body),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final iso = _isotope;
    final half = _halfLifeSeconds();
    final a0 = parseDecimal(_a0Ctrl.text);
    final timeVal = parseDecimal(_timeCtrl.text);
    final target = parseDecimal(_targetCtrl.text);
    final dist = parseDecimal(_distCtrl.text);
    const numKeyboard = TextInputType.numberWithOptions(decimal: true, signed: true);

    return Scaffold(
      appBar: AppBar(title: Text(loc.decayCalcTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _label(loc.decayCalcIsotope),
          DropdownButton<String>(
            isExpanded: true,
            value: _isotopeKey,
            items: [
              for (final i in kKnownIsotopes)
                DropdownMenuItem(value: i.name, child: Text(i.name)),
              DropdownMenuItem(value: _customKey, child: Text(loc.decayCalcCustom)),
            ],
            onChanged: (k) {
              if (k != null) setState(() => _isotopeKey = k);
            },
          ),
          if (iso == null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _halfCtrl,
                    keyboardType: numKeyboard,
                    decoration: InputDecoration(labelText: loc.decayCalcHalfLife),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _halfUnitIndex,
                  items: [
                    for (var i = 0; i < _timeUnits.length; i++)
                      DropdownMenuItem(value: i, child: Text(_timeUnits[i].symbol)),
                  ],
                  onChanged: (i) {
                    if (i != null) setState(() => _halfUnitIndex = i);
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SegmentedButton<_Mode>(
            segments: [
              ButtonSegment(value: _Mode.forward, label: Text(loc.decayCalcModeForward)),
              ButtonSegment(value: _Mode.backward, label: Text(loc.decayCalcModeBackward)),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _a0Ctrl,
                  keyboardType: numKeyboard,
                  decoration: InputDecoration(labelText: loc.decayCalcInitialActivity),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<ActivityUnit>(
                value: _actUnit,
                items: [
                  for (final u in ActivityUnit.values)
                    DropdownMenuItem(value: u, child: Text(u.symbol)),
                ],
                onChanged: (u) {
                  if (u != null) setState(() => _actUnit = u);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_mode == _Mode.forward)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _timeCtrl,
                    keyboardType: numKeyboard,
                    decoration: InputDecoration(labelText: loc.decayCalcElapsed),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _timeUnitIndex,
                  items: [
                    for (var i = 0; i < _timeUnits.length; i++)
                      DropdownMenuItem(value: i, child: Text(_timeUnits[i].symbol)),
                  ],
                  onChanged: (i) {
                    if (i != null) setState(() => _timeUnitIndex = i);
                  },
                ),
              ],
            )
          else
            TextField(
              controller: _targetCtrl,
              keyboardType: numKeyboard,
              decoration: InputDecoration(
                labelText: '${loc.decayCalcTargetActivity} (${_actUnit.symbol})',
              ),
              onChanged: (_) => setState(() {}),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _distCtrl,
            keyboardType: numKeyboard,
            decoration: InputDecoration(labelText: loc.decayCalcDistance),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _results(loc, iso, half, a0, timeVal, target, dist),
            ),
          ),
          const SizedBox(height: 12),
          Text(loc.decayCalcNote, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
