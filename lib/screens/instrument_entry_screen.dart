import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../services/number_input.dart';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/calibration_labels.dart';
import '../models/instrument.dart';
import '../models/instrument_calibration.dart';
import '../models/measurement_type.dart';
import '../models/modbus_reading.dart';
import '../l10n/modbus_quantity_labels.dart';
import '../l10n/domain_labels.dart';
import '../models/gas_reading.dart';
import '../services/modbus_reader_service.dart';
import '../widgets/calibration_record_dialog.dart';

/// Egy műszer felvétele/szerkesztése: alapadatok, kalibráció, opcionális
/// Modbus/TCP elérhetőség.
class InstrumentEntryScreen extends StatefulWidget {
  final Instrument? existing;

  const InstrumentEntryScreen({super.key, this.existing});

  @override
  State<InstrumentEntryScreen> createState() => _InstrumentEntryScreenState();
}

class _InstrumentEntryScreenState extends State<InstrumentEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('yyyy.MM.dd');

  final _nameCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  final _calibrationFactorCtrl = TextEditingController();
  final _modbusHostCtrl = TextEditingController();
  final _modbusPortCtrl = TextEditingController();
  final _modbusUnitIdCtrl = TextEditingController();
  final _modbusGpsLatCtrl = TextEditingController(text: '426');
  final _modbusGpsLonCtrl = TextEditingController(text: '428');

  DateTime? _nextCalibrationDate;
  List<InstrumentCalibration> _records = [];
  bool _isModbusConnected = false;
  bool _isModbusGpsEnabled = false;
  bool _isTestingModbus = false;
  // A szerkesztett Modbus-regiszterek (mérési típusonként egy).
  final List<_ChannelDraft> _channels = [];
  // A törölt sorok: a controllerüket a dispose() szabadítja fel.
  final List<_ChannelDraft> _removedChannels = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _serialCtrl.text = e.serialNumber ?? '';
      _calibrationFactorCtrl.text = e.calibrationFactor?.toString() ?? '';
      _nextCalibrationDate = e.nextCalibrationDate;
      _isModbusConnected = e.isModbusConnected;
      _modbusHostCtrl.text = e.modbusHost ?? '';
      _modbusPortCtrl.text = e.modbusPort?.toString() ?? '';
      _modbusUnitIdCtrl.text = e.modbusUnitId?.toString() ?? '';
      _isModbusGpsEnabled = e.isModbusGpsEnabled;
      _modbusGpsLatCtrl.text = e.modbusGpsLatAddress.toString();
      _modbusGpsLonCtrl.text = e.modbusGpsLonAddress.toString();
      for (final c in e.effectiveModbusChannels) {
        _channels.add(_ChannelDraft(
          type: c.type,
          quantity: c.quantity,
          address: c.address.toString(),
          unit: modbusUnitsFor(c.type, c.quantity).contains(c.unit)
              ? c.unit
              : defaultModbusUnitFor(c.type, c.quantity),
        ));
      }
      _loadRecords(e.id);
    }
  }

  Future<void> _loadRecords(int? id) async {
    if (id == null) return;
    final list = await DatabaseHelper.instance.getCalibrations(id);
    if (!mounted) return;
    setState(() {
      _records = list;
      _syncNextDate();
    });
  }

  /// A következő határidő a bejegyzésekből származik (ha van lejáratuk).
  void _syncNextDate() {
    final v = effectiveValidUntil(_records);
    if (v != null) _nextCalibrationDate = v;
  }

  Future<void> _addRecord({int? editIndex}) async {
    final result = await showCalibrationRecordDialog(
      context,
      existing: editIndex == null ? null : _records[editIndex],
    );
    if (result == null || !mounted) return;
    setState(() {
      final list = [..._records];
      if (editIndex == null) {
        list.add(result);
      } else {
        list[editIndex] = result;
      }
      list.sort((a, b) => b.performedOn.compareTo(a.performedOn));
      _records = list;
      _syncNextDate();
    });
  }

  void _removeRecord(int index) {
    setState(() {
      _records = [..._records]..removeAt(index);
      _syncNextDate();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _serialCtrl.dispose();
    _calibrationFactorCtrl.dispose();
    _modbusHostCtrl.dispose();
    _modbusPortCtrl.dispose();
    _modbusUnitIdCtrl.dispose();
    for (final d in [..._channels, ..._removedChannels]) {
      d.addressCtrl.dispose();
    }
    _modbusGpsLatCtrl.dispose();
    _modbusGpsLonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickNextCalibrationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextCalibrationDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _nextCalibrationDate = picked);
  }

  /// Teszteli a beállított Modbus-regisztereket, mindegyiket külön olvassa.
  /// Az eredményt egy párbeszédablakban mutatja.
  Future<void> _testModbusConnection() async {
    final loc = AppLocalizations.of(context)!;
    if (_modbusHostCtrl.text.trim().isEmpty) {
      _showError(loc.modbusHostLabel);
      return;
    }
    if (_modbusPortCtrl.text.trim().isEmpty) {
      _showError(loc.modbusPortLabel);
      return;
    }
    final channels = _collectChannels(loc);
    if (channels == null) return;
    if (channels.isEmpty) {
      _showMessage(loc.modbusChannelsRequired);
      return;
    }

    setState(() => _isTestingModbus = true);
    try {
      // Ideiglenes műszer-objektum a jelenlegi beállításokkal.
      final testInstrument = Instrument(
        id: widget.existing?.id,
        name: _nameCtrl.text.trim().isEmpty ? 'Test' : _nameCtrl.text.trim(),
        serialNumber: null,
        calibrationDate: null,
        calibrationFactor: null,
        isModbusConnected: true,
        modbusHost: _modbusHostCtrl.text.trim(),
        modbusPort: int.tryParse(_modbusPortCtrl.text.trim()),
        modbusUnitId: int.tryParse(_modbusUnitIdCtrl.text.trim()),
        isModbusGpsEnabled: _isModbusGpsEnabled,
        modbusGpsLatAddress: int.tryParse(_modbusGpsLatCtrl.text.trim()) ?? 426,
        modbusGpsLonAddress: int.tryParse(_modbusGpsLonCtrl.text.trim()) ?? 428,
        modbusChannels: channels,
      );

      final lines = <String>[];
      final failures = <String>[];
      String? gpsInfo;
      for (final channel in channels) {
        final result = await ModbusReaderService.readFloatRegister(
          testInstrument,
          channel,
          loc,
        );
        if (!mounted) return;
        final label = modbusChannelLabel(loc, channel, channel.type.label(context));
        if (result.success) {
          final valueText = result.value == null
              ? 'N/A'
              : '${result.value!.toStringAsFixed(4)} ${channel.unit}';
          lines.add('$label: ${loc.modbusTestValue(valueText)}');
          if (result.hasGps && gpsInfo == null) {
            gpsInfo = loc.modbusTestPosition(
              result.latitude?.toStringAsFixed(6) ?? 'N/A',
              result.longitude?.toStringAsFixed(6) ?? 'N/A',
            );
          }
        } else {
          failures.add('$label: ${result.errorMessage ?? loc.unknownModbusError}');
        }
      }
      if (!mounted) return;

      final ok = failures.isEmpty;
      final content = [
        ...lines,
        ...failures,
        ?gpsInfo,
      ].join('\n');
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(
            ok ? Icons.check_circle : Icons.error,
            color: ok ? Colors.green : Colors.red,
            size: 40,
          ),
          title: Text(
            ok ? loc.modbusTestSuccessTitle : loc.modbusTestFailureTitle,
          ),
          content: Text(content),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.okButton),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.error,
            color: Colors.red,
            size: 40,
          ),
          title: Text(loc.errorTitle),
          content: Text('$e'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.okButton),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isTestingModbus = false);
    }
  }

  /// A szerkesztett sorokból csatornalista. Hibánál üzenetet mutat és null-t ad.
  List<ModbusChannel>? _collectChannels(AppLocalizations loc) {
    final result = <ModbusChannel>[];
    final seen = <String>{};
    for (final d in _channels) {
      final address = int.tryParse(d.addressCtrl.text.trim());
      if (address == null) {
        _showError(loc.modbusRegisterAddressLabel);
        return null;
      }
      if (!seen.add(_slotKey(d.type, d.quantity))) {
        _showMessage(loc.modbusDuplicateChannelType);
        return null;
      }
      result.add(ModbusChannel(
        type: d.type,
        address: address,
        unit: d.unit,
        quantity: d.quantity,
      ));
    }
    return result;
  }

  String _slotKey(MeasurementType type, String? quantity) =>
      '${type.dbValue}|${quantity ?? ''}';

  /// Egy mennyiség alapértelmezett "mennyiség" értéke (típusonként).
  String? _defaultQuantityFor(MeasurementType t) {
    if (t == MeasurementType.meteorology) return kModbusMeteoUnits.keys.first;
    if (t == MeasurementType.gasMeasurement) return gasSpecies.first.name;
    return null;
  }

  /// Az összes lehetséges (típus, mennyiség) páros, a felsorolás sorrendjében.
  List<(MeasurementType, String?)> _allSlots() {
    final slots = <(MeasurementType, String?)>[];
    for (final t in kModbusMeasurableTypes) {
      if (t == MeasurementType.meteorology) {
        for (final k in kModbusMeteoUnits.keys) {
          slots.add((t, k));
        }
      } else if (t == MeasurementType.gasMeasurement) {
        for (final g in gasSpecies) {
          slots.add((t, g.name));
        }
      } else {
        slots.add((t, null));
      }
    }
    return slots;
  }

  /// Első, még nem használt (típus, mennyiség) páros, vagy null, ha mind foglalt.
  (MeasurementType, String?)? _firstFreeSlot() {
    final used = {for (final d in _channels) _slotKey(d.type, d.quantity)};
    for (final slot in _allSlots()) {
      if (!used.contains(_slotKey(slot.$1, slot.$2))) return slot;
    }
    return null;
  }

  void _addChannel() {
    final slot = _firstFreeSlot();
    if (slot == null) return;
    setState(() {
      _channels.add(_ChannelDraft(
        type: slot.$1,
        quantity: slot.$2,
        address: '',
        unit: defaultModbusUnitFor(slot.$1, slot.$2),
      ));
    });
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Egy Modbus-csatorna sora: típus, mennyiség (meteorológia, gáz), cím,
  /// egység és törlés.
  Widget _buildChannelRow(_ChannelDraft d, AppLocalizations loc) {
    final needsQuantity = d.type == MeasurementType.meteorology ||
        d.type == MeasurementType.gasMeasurement;
    final quantityItems = <String>[
      if (d.type == MeasurementType.meteorology) ...kModbusMeteoUnits.keys,
      if (d.type == MeasurementType.gasMeasurement)
        for (final g in gasSpecies) g.name,
    ];
    String quantityLabel(String q) => d.type == MeasurementType.meteorology
        ? modbusMeteoLabel(loc, q)
        : localizedGasName(loc, q);

    return Padding(
      key: ObjectKey(d),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<MeasurementType>(
                  key: ValueKey('modbus-type-${d.type.name}'),
                  initialValue: d.type,
                  isExpanded: true,
                  decoration:
                      InputDecoration(labelText: loc.modbusQuantityLabel),
                  items: [
                    for (final t in kModbusMeasurableTypes)
                      DropdownMenuItem(value: t, child: Text(t.label(context))),
                  ],
                  onChanged: (t) {
                    if (t == null) return;
                    setState(() {
                      d.type = t;
                      d.quantity = _defaultQuantityFor(t);
                      d.unit = defaultModbusUnitFor(t, d.quantity);
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: d.addressCtrl,
                  decoration: InputDecoration(
                    labelText: loc.modbusRegisterAddressLabel,
                    helperText: loc.modbusRegisterAddressHelper,
                    helperMaxLines: 2,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          if (needsQuantity)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: DropdownButtonFormField<String>(
                key: ValueKey('modbus-quantity-${d.type.name}-${d.quantity}'),
                initialValue: d.quantity,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: loc.modbusChannelQuantityLabel,
                ),
                items: [
                  for (final q in quantityItems)
                    DropdownMenuItem(value: q, child: Text(quantityLabel(q))),
                ],
                onChanged: (q) {
                  if (q == null) return;
                  setState(() {
                    d.quantity = q;
                    d.unit = defaultModbusUnitFor(d.type, q);
                  });
                },
              ),
            ),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(
                      'modbus-unit-${d.type.name}-${d.quantity}-${d.unit}'),
                  initialValue: d.unit,
                  isExpanded: true,
                  decoration:
                      InputDecoration(labelText: loc.modbusRegisterUnitLabel),
                  items: [
                    for (final u in modbusUnitsFor(d.type, d.quantity))
                      DropdownMenuItem(value: u, child: Text(u)),
                  ],
                  onChanged: (u) {
                    if (u != null) setState(() => d.unit = u);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() {
                  _channels.remove(d);
                  _removedChannels.add(d);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showError(String fieldLabel) {
    final loc = AppLocalizations.of(context)!;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.missingFieldMessage(fieldLabel))),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final modbusLoc = AppLocalizations.of(context)!;
    var channels = <ModbusChannel>[];
    if (_isModbusConnected) {
      final collected = _collectChannels(modbusLoc);
      if (collected == null) return;
      if (collected.isEmpty) {
        _showMessage(modbusLoc.modbusChannelsRequired);
        return;
      }
      channels = collected;
    }
    // A régi, egy regiszteres mezők az első csatornát tükrözik.
    final firstChannel = channels.isEmpty ? null : channels.first;

    final instrument = Instrument(
      id: widget.existing?.id,
      name: _nameCtrl.text.trim(),
      serialNumber:
          _serialCtrl.text.trim().isEmpty ? null : _serialCtrl.text.trim(),
      calibrationDate: latestPerformedOn(_records),
      nextCalibrationDate: _nextCalibrationDate,
      calibrationFactor: _calibrationFactorCtrl.text.trim().isEmpty
          ? null
          : parseDecimal(_calibrationFactorCtrl.text),
      isModbusConnected: _isModbusConnected,
      modbusHost: _isModbusConnected && _modbusHostCtrl.text.trim().isNotEmpty
          ? _modbusHostCtrl.text.trim()
          : null,
      modbusPort: _isModbusConnected && _modbusPortCtrl.text.trim().isNotEmpty
          ? int.tryParse(_modbusPortCtrl.text.trim())
          : null,
      modbusUnitId:
          _isModbusConnected && _modbusUnitIdCtrl.text.trim().isNotEmpty
              ? int.tryParse(_modbusUnitIdCtrl.text.trim())
              : null,
      modbusRegisterAddress: firstChannel?.address,
      isModbusGpsEnabled: _isModbusConnected && _isModbusGpsEnabled,
      modbusGpsLatAddress:
          int.tryParse(_modbusGpsLatCtrl.text.trim()) ?? 426,
      modbusGpsLonAddress:
          int.tryParse(_modbusGpsLonCtrl.text.trim()) ?? 428,
      modbusMeasurementType: firstChannel?.type ?? MeasurementType.doseRate,
      modbusUnit: firstChannel?.unit ??
          defaultModbusUnitFor(MeasurementType.doseRate),
      modbusChannels: channels,
    );

    final int instrumentId;
    if (widget.existing == null) {
      instrumentId = await DatabaseHelper.instance.insertInstrument(instrument);
    } else {
      await DatabaseHelper.instance.updateInstrument(instrument);
      instrumentId = widget.existing!.id!;
    }
    await DatabaseHelper.instance.replaceCalibrations(instrumentId, _records);

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? loc.newInstrumentButton
              : loc.editInstrumentTitle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: loc.saveButton,
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: loc.instrumentNameLabel),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? loc.requiredFieldError : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _serialCtrl,
              decoration: InputDecoration(labelText: loc.serialNumberLabel),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.nextCalibrationLabel),
              subtitle: Text(
                _nextCalibrationDate == null
                    ? loc.notSetLabel
                    : _dateFormat.format(_nextCalibrationDate!),
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickNextCalibrationDate,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _calibrationFactorCtrl,
              decoration: InputDecoration(labelText: loc.calibrationFactorLabel),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(loc.calibrationSectionTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(loc.calibrationAddButton),
                  onPressed: () => _addRecord(),
                ),
              ],
            ),
            if (_records.isEmpty)
              Text(loc.calibrationEmptyList,
                  style: Theme.of(context).textTheme.bodySmall),
            for (var i = 0; i < _records.length; i++)
              Card(
                child: ListTile(
                  title: Text(
                    '${calibrationKindLabel(loc, _records[i].kind)} · '
                    '${_dateFormat.format(_records[i].performedOn)}',
                  ),
                  subtitle: Text([
                    if (_records[i].validUntil != null)
                      '${loc.calibrationValidUntilLabel}: '
                          '${_dateFormat.format(_records[i].validUntil!)}',
                    if (_records[i].certificateNumber != null)
                      _records[i].certificateNumber!,
                    if (_records[i].performedBy != null)
                      _records[i].performedBy!,
                  ].join('\n')),
                  onTap: () => _addRecord(editIndex: i),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_records[i].filePath != null)
                        IconButton(
                          tooltip: loc.calibrationOpenFile,
                          icon: const Icon(Icons.attach_file),
                          onPressed: () => SharePlus.instance.share(
                            ShareParams(files: [XFile(_records[i].filePath!)]),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removeRecord(i),
                      ),
                    ],
                  ),
                ),
              ),
            const Divider(height: 32),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.modbusConnectedLabel),
              value: _isModbusConnected,
              onChanged: (v) => setState(() => _isModbusConnected = v),
            ),
            if (_isModbusConnected) ...[
              TextFormField(
                controller: _modbusHostCtrl,
                decoration: InputDecoration(labelText: loc.modbusHostLabel),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modbusPortCtrl,
                decoration: InputDecoration(labelText: loc.modbusPortLabel),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modbusUnitIdCtrl,
                decoration: InputDecoration(
                  labelText: loc.modbusUnitIdLabel,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Text(
                loc.modbusChannelsTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                loc.modbusChannelsHelper,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final d in _channels) _buildChannelRow(d, loc),
              OutlinedButton.icon(
                onPressed: _firstFreeSlot() == null ? null : _addChannel,
                icon: const Icon(Icons.add),
                label: Text(loc.modbusAddChannelButton),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isTestingModbus ? null : _testModbusConnection,
                  icon: _isTestingModbus
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.router),
                  label: Text(
                    _isTestingModbus
                        ? loc.modbusTestingLabel
                        : loc.modbusTestConnectionButton,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(loc.modbusGpsEnabledLabel),
                value: _isModbusGpsEnabled,
                onChanged: (v) => setState(() => _isModbusGpsEnabled = v),
              ),
              if (_isModbusGpsEnabled) ...[
                TextFormField(
                  controller: _modbusGpsLatCtrl,
                  decoration:
                      InputDecoration(labelText: loc.modbusGpsLatAddressLabel),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _modbusGpsLonCtrl,
                  decoration:
                      InputDecoration(labelText: loc.modbusGpsLonAddressLabel),
                  keyboardType: TextInputType.number,
                ),
              ],
            ],
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(loc.saveButton)),
          ],
        ),
      ),
    );
  }
}

/// Egy Modbus-regiszter a műszer szerkesztőjében (még nem mentett állapot).
class _ChannelDraft {
  _ChannelDraft({
    required this.type,
    required String address,
    required this.unit,
    this.quantity,
  }) : addressCtrl = TextEditingController(text: address);

  MeasurementType type;
  String? quantity;
  String unit;
  final TextEditingController addressCtrl;
}
