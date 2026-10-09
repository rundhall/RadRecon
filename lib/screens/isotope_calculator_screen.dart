import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/isotope.dart';

enum _CalcMode { doseRateFromActivity, activityFromDoseRate }

/// Izotóp aktivitás ⇄ dózisteljesítmény átszámoló, adott távolságra.
class IsotopeCalculatorScreen extends StatefulWidget {
  const IsotopeCalculatorScreen({super.key});

  @override
  State<IsotopeCalculatorScreen> createState() =>
      _IsotopeCalculatorScreenState();
}

class _IsotopeCalculatorScreenState extends State<IsotopeCalculatorScreen> {
  Isotope _isotope = kKnownIsotopes.first;
  _CalcMode _mode = _CalcMode.doseRateFromActivity;

  final _distanceCtrl = TextEditingController();
  final _activityCtrl = TextEditingController();
  final _doseRateCtrl = TextEditingController();

  String? _resultText;
  String? _errorText;

  @override
  void dispose() {
    _distanceCtrl.dispose();
    _activityCtrl.dispose();
    _doseRateCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final loc = AppLocalizations.of(context)!;
    setState(() {
      _resultText = null;
      _errorText = null;
    });

    final distance = double.tryParse(_distanceCtrl.text.trim());
    if (distance == null || distance <= 0) {
      setState(() => _errorText = loc.invalidDistanceError);
      return;
    }

    try {
      if (_mode == _CalcMode.doseRateFromActivity) {
        final activity = double.tryParse(_activityCtrl.text.trim());
        if (activity == null || activity <= 0) {
          setState(() => _errorText = loc.invalidActivityError);
          return;
        }
        final dose = _isotope.doseRateAt(activityMBq: activity, distanceM: distance);
        setState(() {
          _resultText = loc.calculatedDoseRateResult(
            _formatValue(dose),
            _formatValue(dose * 1000),
          );
        });
      } else {
        final dose = double.tryParse(_doseRateCtrl.text.trim());
        if (dose == null || dose <= 0) {
          setState(() => _errorText = loc.invalidDoseRateError);
          return;
        }
        final activity = _isotope.activityFrom(doseRateUSvH: dose, distanceM: distance);
        setState(() {
          _resultText = loc.calculatedActivityResult(
            _formatValue(activity),
            _formatValue(activity / 1000),
          );
        });
      }
    } catch (e) {
      setState(() => _errorText = loc.calculationErrorMessage('$e'));
    }
  }

  String _formatValue(double v) {
    if (v >= 1000 || v < 0.01) return v.toStringAsExponential(3);
    return v.toStringAsFixed(3);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.isotopeCalculatorTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                loc.gammaConstantsDisclaimer,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Isotope>(
            initialValue: _isotope,
            decoration: InputDecoration(labelText: loc.isotopeLabel),
            items: kKnownIsotopes
                .map((i) => DropdownMenuItem(
                      value: i,
                      child: Text('${i.name}  (Γ = ${i.gammaConstant})'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _isotope = v!),
          ),
          const SizedBox(height: 16),
          SegmentedButton<_CalcMode>(
            segments: [
              ButtonSegment(
                value: _CalcMode.doseRateFromActivity,
                label: Text(loc.modeDoseFromActivity),
              ),
              ButtonSegment(
                value: _CalcMode.activityFromDoseRate,
                label: Text(loc.modeActivityFromDose),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _distanceCtrl,
            decoration: InputDecoration(labelText: loc.distanceFromSourceLabel),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          if (_mode == _CalcMode.doseRateFromActivity)
            TextField(
              controller: _activityCtrl,
              decoration: InputDecoration(labelText: loc.activityLabel),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            )
          else
            TextField(
              controller: _doseRateCtrl,
              decoration: InputDecoration(labelText: loc.measuredDoseRateLabel),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _calculate, child: Text(loc.calculateButton)),
          const SizedBox(height: 20),
          if (_errorText != null)
            Text(_errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          if (_resultText != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _resultText!,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}