import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/activity_unit.dart';
import '../models/distance_unit.dart';
import '../models/dose_rate_unit.dart';
import '../models/isotope.dart';
import '../models/shielding.dart';
import '../services/dose_unit_controller.dart';
import '../services/unit_format.dart';
import '../widgets/quantity_field.dart';
import '../widgets/shielding_layers_editor.dart';

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

  DistanceUnit _distanceUnit = DistanceUnitController.current;
  ActivityUnit _activityUnit = ActivityUnitController.current;
  DoseRateUnit _doseUnit = DoseUnitController.current;

  final List<ShieldingLayerEdit> _layers = [];

  String? _resultText;
  String? _errorText;

  @override
  void dispose() {
    _distanceCtrl.dispose();
    _activityCtrl.dispose();
    _doseRateCtrl.dispose();
    for (final e in _layers) {
      e.ctrl.dispose();
    }
    super.dispose();
  }

  void _calculate() {
    final loc = AppLocalizations.of(context)!;
    setState(() {
      _resultText = null;
      _errorText = null;
    });

    final enteredDistance = double.tryParse(_distanceCtrl.text.trim());
    if (enteredDistance == null || enteredDistance <= 0) {
      setState(() => _errorText = loc.invalidDistancePlainError);
      return;
    }
    final distance = _distanceUnit.toMeters(enteredDistance);

    final layers = validShieldingLayers(_layers);
    final transmission = layers.isEmpty
        ? null
        : layersTransmission(_isotope.name, layers);

    try {
      if (_mode == _CalcMode.doseRateFromActivity) {
        final entered = double.tryParse(_activityCtrl.text.trim());
        if (entered == null || entered <= 0) {
          setState(() => _errorText = loc.invalidActivityPlainError);
          return;
        }
        final dose = _isotope.doseRateAt(
          activityMBq: _activityUnit.toMBq(entered),
          distanceM: distance,
        );
        setState(() {
          _resultText = transmission == null
              ? '${loc.calculatedDoseRateResultLabel}: '
                  '${formatDoseRateUSvH(dose)}'
              : '${loc.doseRateUnshieldedLabel}: '
                  '${formatDoseRateUSvH(dose)}\n'
                  '${loc.doseRateShieldedLabel}: '
                  '${formatDoseRateUSvH(dose * transmission)}';
        });
      } else {
        final entered = double.tryParse(_doseRateCtrl.text.trim());
        if (entered == null || entered <= 0) {
          setState(() => _errorText = loc.invalidDoseRatePlainError);
          return;
        }
        final activity = _isotope.activityFrom(
          doseRateUSvH: _doseUnit.toMicroSvPerHour(entered),
          distanceM: distance,
        );
        setState(() {
          _resultText = transmission == null || transmission <= 0
              ? '${loc.calculatedActivityResultLabel}: '
                  '${formatActivityMBq(activity)}'
              : '${loc.unshieldedActivityLabel}: '
                  '${formatActivityMBq(activity)}\n'
                  '${loc.shieldedActivityLabel}: '
                  '${formatActivityMBq(activity / transmission)}';
        });
      }
    } catch (e) {
      setState(() => _errorText = loc.calculationErrorMessage('$e'));
    }
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
          QuantityField<DistanceUnit>(
            controller: _distanceCtrl,
            label: loc.distanceFromSourcePlainLabel,
            units: DistanceUnit.values,
            unit: _distanceUnit,
            onUnitChanged: (u) => setState(() => _distanceUnit = u),
          ),
          const SizedBox(height: 12),
          if (_mode == _CalcMode.doseRateFromActivity)
            QuantityField<ActivityUnit>(
              controller: _activityCtrl,
              label: loc.activityPlainLabel,
              units: ActivityUnit.values,
              unit: _activityUnit,
              onUnitChanged: (u) => setState(() => _activityUnit = u),
            )
          else
            QuantityField<DoseRateUnit>(
              controller: _doseRateCtrl,
              label: loc.measuredDoseRatePlainLabel,
              units: DoseRateUnit.values,
              unit: _doseUnit,
              onUnitChanged: (u) => setState(() => _doseUnit = u),
            ),
          const SizedBox(height: 16),
          Text(loc.shieldingSectionTitle,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(loc.shieldingHint,
              style: Theme.of(context).textTheme.bodySmall),
          ShieldingLayersEditor(
            layers: _layers,
            onChanged: () => setState(() {}),
          ),
          if (_layers.isNotEmpty)
            Text(loc.shieldingDisclaimer,
                style: Theme.of(context).textTheme.bodySmall),
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