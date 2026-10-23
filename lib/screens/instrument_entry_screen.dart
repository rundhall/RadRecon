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
  final _modbusRegisterAddressCtrl = TextEditingController();
  final _modbusGpsLatCtrl = TextEditingController(text: '426');
  final _modbusGpsLonCtrl = TextEditingController(text: '428');

  DateTime? _nextCalibrationDate;
  List<InstrumentCalibration> _records = [];
  bool _isModbusConnected = false;
  bool _isModbusGpsEnabled = false;
  bool _isTestingModbus = false;
  MeasurementType _modbusType = MeasurementType.doseRate;
  String _modbusUnit = defaultModbusUnitFor(MeasurementType.doseRate);

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
      _modbusRegisterAddressCtrl.text =
          e.modbusRegisterAddress?.toString() ?? '';
      _isModbusGpsEnabled = e.isModbusGpsEnabled;
      _modbusGpsLatCtrl.text = e.modbusGpsLatAddress.toString();
      _modbusGpsLonCtrl.text = e.modbusGpsLonAddress.toString();
      _modbusType = e.modbusMeasurementType;
      _modbusUnit = modbusUnitsFor(_modbusType).contains(e.modbusUnit)
          ? e.modbusUnit
          : defaultModbusUnitFor(_modbusType);
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
    _modbusRegisterAddressCtrl.dispose();
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

  /// Testet die Modbus/TCP-Verbindung anhand der aktuellen Einstellungen.
  /// Zeigt das Ergebnis in einem Dialog an.
  Future<void> _testModbusConnection() async {
    final loc = AppLocalizations.of(context)!;
    // Validiere die erforderlichen Felder
    if (_modbusHostCtrl.text.trim().isEmpty) {
      _showError(loc.modbusHostLabel);
      return;
    }
    if (_modbusPortCtrl.text.trim().isEmpty) {
      _showError(loc.modbusPortLabel);
      return;
    }
    if (_modbusRegisterAddressCtrl.text.trim().isEmpty) {
      _showError(loc.modbusRegisterAddressLabel);
      return;
    }

    setState(() => _isTestingModbus = true);
    try {
      // Erstelle ein temporäres Instrument-Objekt mit den aktuellen Einstellungen
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
        modbusRegisterAddress: int.tryParse(_modbusRegisterAddressCtrl.text.trim()),
        isModbusGpsEnabled: _isModbusGpsEnabled,
        modbusGpsLatAddress: int.tryParse(_modbusGpsLatCtrl.text.trim()) ?? 426,
        modbusGpsLonAddress: int.tryParse(_modbusGpsLonCtrl.text.trim()) ?? 428,
        modbusMeasurementType: _modbusType,
        modbusUnit: _modbusUnit,
      );

      final result = await ModbusReaderService.readFloatRegister(testInstrument, loc);
      if (!mounted) return;

      if (result.success) {
        String content = loc.modbusTestValue(
          result.value == null
              ? 'N/A'
              : '${result.value!.toStringAsFixed(4)} $_modbusUnit',
        );
        if (result.hasGps) {
          final gpsInfo = loc.modbusTestPosition(
            result.latitude?.toStringAsFixed(6) ?? 'N/A',
            result.longitude?.toStringAsFixed(6) ?? 'N/A',
          );
          content = '$content\n$gpsInfo';
        }
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 40,
            ),
            title: Text(loc.modbusTestSuccessTitle),
            content: Text(content),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(loc.okButton),
              ),
            ],
          ),
        );
      } else {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.error,
              color: Colors.red,
              size: 40,
            ),
            title: Text(loc.modbusTestFailureTitle),
            content: Text(
              result.errorMessage ?? loc.unknownModbusError,
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(loc.okButton),
              ),
            ],
          ),
        );
      }
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

  void _showError(String fieldLabel) {
    final loc = AppLocalizations.of(context)!;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.missingFieldMessage(fieldLabel))),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

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
      modbusRegisterAddress: _isModbusConnected &&
              _modbusRegisterAddressCtrl.text.trim().isNotEmpty
          ? int.tryParse(_modbusRegisterAddressCtrl.text.trim())
          : null,
      isModbusGpsEnabled: _isModbusConnected && _isModbusGpsEnabled,
      modbusGpsLatAddress:
          int.tryParse(_modbusGpsLatCtrl.text.trim()) ?? 426,
      modbusGpsLonAddress:
          int.tryParse(_modbusGpsLonCtrl.text.trim()) ?? 428,
      modbusMeasurementType: _modbusType,
      modbusUnit: _modbusUnit,
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
              TextFormField(
                controller: _modbusRegisterAddressCtrl,
                decoration: InputDecoration(
                  labelText: loc.modbusRegisterAddressLabel,
                  helperText: loc.modbusRegisterAddressHelper,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              // Mit mér a műszer, és milyen egységben adja a regiszterben.
              // Zárt listák, így nem lehet elgépelni.
              DropdownButtonFormField<MeasurementType>(
                key: ValueKey('modbus-type-${_modbusType.name}'),
                initialValue: _modbusType,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: loc.modbusQuantityLabel,
                  helperText: loc.modbusQuantityHelper,
                  helperMaxLines: 3,
                ),
                items: [
                  for (final t in kModbusMeasurableTypes)
                    DropdownMenuItem(value: t, child: Text(t.label(context))),
                ],
                onChanged: (t) {
                  if (t == null) return;
                  setState(() {
                    _modbusType = t;
                    _modbusUnit = defaultModbusUnitFor(t);
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('modbus-unit-${_modbusType.name}-$_modbusUnit'),
                initialValue: _modbusUnit,
                isExpanded: true,
                decoration:
                    InputDecoration(labelText: loc.modbusRegisterUnitLabel),
                items: [
                  for (final u in modbusUnitsFor(_modbusType))
                    DropdownMenuItem(value: u, child: Text(u)),
                ],
                onChanged: (u) {
                  if (u != null) setState(() => _modbusUnit = u);
                },
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