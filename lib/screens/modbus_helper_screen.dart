import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/decimal_separator.dart';
import '../models/instrument.dart';
import '../models/modbus_register.dart';
import '../services/dose_unit_controller.dart';
import '../services/modbus_tool_service.dart';
import '../services/number_input.dart';
import '../services/safe_file_name.dart';

/// Modbus segéd: a műszerhez elmentett, elnevezett regiszterek és bitek
/// kézi olvasása és írása (pl. baud rate, paritás, stop bit, Modbus ID,
/// státuszok). A regiszterkiosztás műszerenként külön tárolódik.
class ModbusHelperScreen extends StatefulWidget {
  const ModbusHelperScreen({super.key, required this.instrument});

  final Instrument instrument;

  @override
  State<ModbusHelperScreen> createState() => _ModbusHelperScreenState();
}

/// Egy regiszter legutóbbi kiolvasása: érték vagy hibaszöveg.
class _Reading {
  const _Reading({this.value, this.error});

  final Object? value;
  final String? error;
}

/// Az időzített lekérdezés egy köre: időpont és a kiolvasott nyers értékek
/// regiszter-azonosító szerint (hibánál nincs érték).
class _PollRow {
  const _PollRow(this.time, this.values);

  final DateTime time;
  final Map<String, Object?> values;
}

String _csvField(String v) =>
    v.contains(';') || v.contains('"') || v.contains('\n')
        ? '"${v.replaceAll('"', '""')}"'
        : v;

/// A mentett fájl formátumjelölője.
const _exchangeFormat = 'radrecon-modbus-registers';

String _formatNumber(double v, String decimalSeparator) {
  final a = v.abs();
  String s;
  if (a != 0 && (a < 1e-4 || a >= 1e9)) {
    s = v.toStringAsExponential(4);
  } else {
    s = v.toStringAsFixed(6);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    }
  }
  return s.replaceAll('.', decimalSeparator);
}

String _hex(int raw, ModbusDataType type) {
  final bits = type.is32Bit ? 32 : 16;
  final masked = raw & ((1 << bits) - 1);
  return '0x${masked.toRadixString(16).toUpperCase().padLeft(bits ~/ 4, '0')}';
}

class _ModbusHelperScreenState extends State<ModbusHelperScreen> {
  late final ModbusToolSession _session;
  List<ModbusRegisterDef> _registers = [];
  final Map<String, _Reading> _readings = {};
  bool _loading = true;
  bool _busy = false;

  // Időzített lekérdezés.
  final Set<String> _selected = {};
  final _intervalController = TextEditingController(text: '1');
  bool _polling = false;
  int _pollRun = 0;
  List<ModbusRegisterDef> _pollDefs = const [];
  final List<_PollRow> _pollLog = [];

  @override
  void initState() {
    super.initState();
    _session = ModbusToolSession(widget.instrument);
    _load();
  }

  @override
  void dispose() {
    if (_polling) unawaited(WakelockPlus.disable());
    _polling = false;
    _pollRun++;
    _intervalController.dispose();
    unawaited(_session.close());
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.instrument.id;
    final list = id == null
        ? const <ModbusRegisterDef>[]
        : await DatabaseHelper.instance.getModbusRegisters(id);
    if (!mounted) return;
    setState(() {
      _registers = List.of(list);
      _loading = false;
    });
  }

  Future<void> _persist() async {
    final id = widget.instrument.id;
    if (id == null) return;
    await DatabaseHelper.instance.saveModbusRegisters(id, _registers);
  }

  String _decimalSeparator(AppLocalizations loc) =>
      decimalSeparatorFor(DecimalSeparatorController.current, loc.protoDecimalSep);

  String _errorText(AppLocalizations loc, ModbusToolResult r,
      {required bool writing}) {
    final exception = r.exception;
    if (exception != null) return loc.connectionErrorWithDetails(exception);
    final code = r.errorCode ?? '?';
    return writing
        ? loc.modbusToolWriteError(code)
        : loc.modbusReadErrorWithCode(code);
  }

  Future<void> _readInto(ModbusRegisterDef d, AppLocalizations loc) async {
    final result = await _session.read(d);
    if (!mounted) return;
    setState(() {
      _readings[d.id] = result.ok
          ? _Reading(value: result.value)
          : _Reading(error: _errorText(loc, result, writing: false));
    });
  }

  /// A bejelölt sorok ismételt kiolvasása a megadott időközönként, amíg le
  /// nem állítják. Minden kör egy sort ad a menthető naplóhoz.
  Future<void> _startPolling() async {
    if (_polling || _busy || !_session.isConfigured) return;
    final loc = AppLocalizations.of(context)!;
    final defs = [
      for (final r in _registers)
        if (_selected.contains(r.id)) r,
    ];
    if (defs.isEmpty) return;
    final seconds = parseDecimal(_intervalController.text.trim());
    final interval = Duration(
      milliseconds:
          seconds == null || seconds < 0.1 ? 1000 : (seconds * 1000).round(),
    );
    final run = ++_pollRun;
    setState(() {
      _polling = true;
      _pollDefs = defs;
      _pollLog.clear();
    });
    unawaited(WakelockPlus.enable());
    while (mounted && _polling && run == _pollRun) {
      final started = DateTime.now();
      final values = <String, Object?>{};
      for (final d in defs) {
        if (!_polling || run != _pollRun) break;
        final result = await _session.read(d);
        if (!mounted) return;
        values[d.id] = result.value;
        _readings[d.id] = result.ok
            ? _Reading(value: result.value)
            : _Reading(error: _errorText(loc, result, writing: false));
      }
      if (!mounted || run != _pollRun) return;
      setState(() => _pollLog.add(_PollRow(started, values)));
      final rest = interval - DateTime.now().difference(started);
      if (_polling && rest > Duration.zero) await Future.delayed(rest);
    }
  }

  void _stopPolling() {
    if (!_polling) return;
    unawaited(WakelockPlus.disable());
    setState(() => _polling = false);
  }

  /// A leállított lekérdezés naplója CSV-be (pontosvessző, a beállított
  /// tizedesjel), majd megosztás.
  Future<void> _savePollLog() async {
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final sep = _decimalSeparator(loc);
    try {
      final buffer = StringBuffer('\uFEFF');
      buffer.writeln([
        loc.modbusToolTimeColumn,
        for (final d in _pollDefs)
          d.unit.isEmpty ? d.name : '${d.name} [${d.unit}]',
      ].map(_csvField).join(';'));
      final timeFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
      for (final row in _pollLog) {
        buffer.writeln([
          timeFormat.format(row.time),
          for (final d in _pollDefs)
            switch (row.values[d.id]) {
              final bool b => b ? '1' : '0',
              final int i when d.scale == 1 => '$i',
              final num n => _formatNumber(d.displayFromRaw(n), sep),
              _ => '',
            },
        ].join(';'));
      }
      final directory = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmmss')
          .format(_pollLog.isEmpty ? DateTime.now() : _pollLog.first.time);
      final file = File(p.join(
        directory.path,
        '${safeFileName(widget.instrument.name)}_modbus_$stamp.csv',
      ));
      await file.writeAsString(buffer.toString());
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        subject: '${loc.modbusToolPollTitle} – ${widget.instrument.name}',
      ));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(loc.exportErrorMessage('$error'))),
      );
    }
  }

  Widget _pollCard(AppLocalizations loc) {
    final theme = Theme.of(context);
    final canStart =
        _session.isConfigured && !_busy && _selected.isNotEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.modbusToolPollTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _intervalController,
                    enabled: !_polling,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      labelText: loc.modbusToolPollInterval,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (_polling)
                  FilledButton.icon(
                    onPressed: _stopPolling,
                    icon: const Icon(Icons.stop),
                    label: Text(loc.modbusToolPollStop),
                  )
                else
                  FilledButton.icon(
                    onPressed: canStart ? _startPolling : null,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(loc.modbusToolPollStart),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_selected.isEmpty && !_polling)
              Text(loc.modbusToolPollSelectHint,
                  style: theme.textTheme.bodySmall),
            if (_polling || _pollLog.isNotEmpty)
              Text(loc.modbusToolPollSamples(_pollLog.length)),
            if (!_polling && _pollLog.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _savePollLog,
                  icon: const Icon(Icons.save_alt),
                  label: Text(loc.modbusToolPollSave),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _readOne(ModbusRegisterDef d) async {
    if (_busy) return;
    final loc = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    await _readInto(d, loc);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _readAll() async {
    if (_busy) return;
    final loc = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    for (final d in List.of(_registers)) {
      if (!mounted) return;
      await _readInto(d, loc);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _write(ModbusRegisterDef d) async {
    if (_busy) return;
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final raw = await showDialog<Object>(
      context: context,
      builder: (_) => _WriteDialog(
        register: d,
        current: _readings[d.id]?.value,
        decimalSeparator: _decimalSeparator(loc),
      ),
    );
    if (raw == null || !mounted) return;
    setState(() => _busy = true);
    final result = await _session.write(d, raw);
    if (!mounted) return;
    if (result.ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(loc.modbusToolWriteOk(d.name))),
      );
      // Visszaolvasás: az látszik, amit a műszer ténylegesen tárol.
      await _readInto(d, loc);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(_errorText(loc, result, writing: true))),
      );
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _edit({ModbusRegisterDef? existing}) async {
    if (_polling) return;
    final outcome = await showDialog<_EditOutcome>(
      context: context,
      builder: (_) => _RegisterEditDialog(existing: existing),
    );
    if (outcome == null || !mounted) return;
    setState(() {
      final def = outcome.register;
      if (def == null) {
        _registers.removeWhere((r) => r.id == existing?.id);
        _selected.remove(existing?.id);
        _readings.remove(existing?.id);
      } else {
        final index = _registers.indexWhere((r) => r.id == def.id);
        if (index >= 0) {
          _registers[index] = def;
          // Más cím vagy típus: a régi érték már nem érvényes.
          _readings.remove(def.id);
        } else {
          _registers.add(def);
        }
      }
    });
    await _persist();
  }

  /// A regiszterlista megosztható JSON-fájlba írása.
  Future<void> _exportFile() async {
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final directory = await getTemporaryDirectory();
      final file = File(p.join(
        directory.path,
        '${safeFileName(widget.instrument.name)}_modbus.json',
      ));
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert({
        'format': _exchangeFormat,
        'version': 1,
        'instrument': widget.instrument.name,
        'registers': [for (final r in _registers) r.toJson()],
      }));
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        subject: '${loc.modbusToolTitle} – ${widget.instrument.name}',
      ));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(loc.exportErrorMessage('$error'))),
      );
    }
  }

  Future<void> _importFile() async {
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final selection = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (selection.isEmpty || !mounted) return;
      final bytes = await selection.single.readAsBytes();
      final Object? decoded = jsonDecode(utf8.decode(bytes));
      // A saját formátum mellett a puszta regiszterlistát is elfogadja.
      final list = ModbusRegisterDef.listFromJson(
        decoded is Map ? decoded['registers'] : decoded,
      );
      if (list.isEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text(loc.modbusToolImportInvalid)),
        );
        return;
      }
      if (!mounted) return;
      await _adopt(list);
    } on FormatException {
      messenger.showSnackBar(
        SnackBar(content: Text(loc.modbusToolImportInvalid)),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(loc.importErrorMessage('$error'))),
      );
    }
  }

  /// Egy másik műszer elmentett regisztereinek átvétele.
  Future<void> _copyFromInstrument() async {
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final candidates = <(Instrument, List<ModbusRegisterDef>)>[];
    for (final i in await DatabaseHelper.instance.getInstruments()) {
      final id = i.id;
      if (id == null || id == widget.instrument.id) continue;
      final list = await DatabaseHelper.instance.getModbusRegisters(id);
      if (list.isNotEmpty) candidates.add((i, list));
    }
    if (!mounted) return;
    if (candidates.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(loc.modbusToolNoOtherSource)),
      );
      return;
    }
    final picked = await showDialog<List<ModbusRegisterDef>>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(loc.modbusToolCopyFrom),
        children: [
          for (final (instrument, list) in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(list),
              child: Text('${instrument.name} (${list.length})'),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    await _adopt(picked);
  }

  /// Átvett regiszterek beillesztése: ha már van lista, megkérdezi, hogy
  /// hozzáadja-e vagy lecserélje. Az átvett sorok új azonosítót kapnak.
  Future<void> _adopt(List<ModbusRegisterDef> incoming) async {
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    var replace = false;
    if (_registers.isNotEmpty) {
      final choice = await showDialog<bool>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(loc.modbusToolImportModeTitle),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(loc.modbusToolImportAppend),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(loc.modbusToolImportReplace),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.cancelButton),
            ),
          ],
        ),
      );
      if (choice == null || !mounted) return;
      replace = choice;
    }
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final fresh = <ModbusRegisterDef>[
      for (var n = 0; n < incoming.length; n++)
        ModbusRegisterDef(
          id: '${stamp}_$n',
          name: incoming[n].name,
          kind: incoming[n].kind,
          address: incoming[n].address,
          dataType: incoming[n].dataType,
          byteOrder: incoming[n].byteOrder,
          scale: incoming[n].scale,
          unit: incoming[n].unit,
          note: incoming[n].note,
        ),
    ];
    setState(() {
      if (replace) {
        _registers.clear();
        _readings.clear();
        _selected.clear();
      }
      _registers.addAll(fresh);
    });
    await _persist();
    messenger.showSnackBar(
      SnackBar(content: Text(loc.modbusToolImported(fresh.length))),
    );
  }

  String _subtitle(ModbusRegisterDef d) {
    final parts = <String>['${d.kind.label} ${d.address}'];
    if (!d.isBit) {
      parts.add(d.dataType.is32Bit
          ? '${d.dataType.dbValue} ${d.byteOrder}'
          : d.dataType.dbValue);
      if (d.scale != 1) parts.add('× ${_formatNumber(d.scale, '.')}');
    }
    return parts.join(' · ');
  }

  /// A kiolvasott érték kijelzett szövege és (egész típusnál) a nyers érték.
  (String, String?) _valueTexts(
      AppLocalizations loc, ModbusRegisterDef d, Object value) {
    if (value is bool) {
      return (value ? loc.modbusToolOn : loc.modbusToolOff, null);
    }
    final raw = value as num;
    final sep = _decimalSeparator(loc);
    final unit = d.unit.isEmpty ? '' : ' ${d.unit}';
    final shown = raw is int && d.scale == 1
        ? '$raw'
        : _formatNumber(d.displayFromRaw(raw), sep);
    if (raw is! int) return ('$shown$unit', null);
    final hex = _hex(raw, d.dataType);
    return ('$shown$unit', d.scale == 1 ? hex : '$raw · $hex');
  }

  Widget _registerCard(AppLocalizations loc, ModbusRegisterDef d) {
    final theme = Theme.of(context);
    final reading = _readings[d.id];
    final error = reading?.error;
    final value = reading?.value;
    final canSend = _session.isConfigured && !_busy && !_polling;

    Widget valueWidget;
    if (error != null) {
      valueWidget = Text(error, style: TextStyle(color: theme.colorScheme.error));
    } else if (value != null) {
      final (shown, rawText) = _valueTexts(loc, d, value);
      valueWidget = Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: Text(
              shown,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (rawText != null) ...[
            const SizedBox(width: 12),
            Text(rawText, style: theme.textTheme.bodySmall),
          ],
        ],
      );
    } else {
      valueWidget = Text(
        loc.modbusToolNotRead,
        style: theme.textTheme.bodyMedium
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () => _edit(existing: d),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _selected.contains(d.id),
                    onChanged: _polling
                        ? null
                        : (v) => setState(() {
                              if (v == true) {
                                _selected.add(d.id);
                              } else {
                                _selected.remove(d.id);
                              }
                            }),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.name, style: theme.textTheme.titleMedium),
                        Text(_subtitle(d), style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_outlined, size: 18),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: valueWidget,
              ),
              if (d.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text(d.note, style: theme.textTheme.bodySmall),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: canSend ? () => _readOne(d) : null,
                    icon: const Icon(Icons.download),
                    label: Text(loc.modbusToolRead),
                  ),
                  if (d.isWritable) ...[
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: canSend ? () => _write(d) : null,
                      icon: const Icon(Icons.upload),
                      label: Text(loc.modbusToolWrite),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final i = widget.instrument;
    final configured = _session.isConfigured;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.modbusToolTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: loc.modbusToolReadAll,
            onPressed: configured &&
                    !_busy &&
                    !_polling &&
                    _registers.isNotEmpty
                ? _readAll
                : null,
          ),
          PopupMenuButton<String>(
            enabled: !_busy && !_loading && !_polling,
            onSelected: (action) => switch (action) {
              'export' => _exportFile(),
              'import' => _importFile(),
              _ => _copyFromInstrument(),
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'copy',
                child: Text(loc.modbusToolCopyFrom),
              ),
              PopupMenuItem(
                value: 'export',
                enabled: _registers.isNotEmpty,
                child: Text(loc.modbusToolExport),
              ),
              PopupMenuItem(
                value: 'import',
                child: Text(loc.modbusToolImport),
              ),
            ],
          ),
        ],
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 96),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(i.name, style: theme.textTheme.titleLarge),
                      if (configured)
                        Text(
                          '${i.modbusHost}:${i.modbusPort ?? 502} · '
                          'Unit ID ${i.modbusUnitId}',
                          style: theme.textTheme.bodyMedium,
                        )
                      else
                        Text(
                          loc.modbusAccessIncomplete,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                    ],
                  ),
                ),
                if (_registers.isNotEmpty) _pollCard(loc),
                if (_registers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      loc.modbusToolEmpty,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  for (final d in _registers) _registerCard(loc, d),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _polling ? null : () => _edit(),
        icon: const Icon(Icons.add),
        label: Text(loc.modbusToolAddRegister),
      ),
    );
  }
}

/// A szerkesztő párbeszédablak eredménye: mentett definíció, vagy törlés
/// (ekkor a [register] null).
class _EditOutcome {
  const _EditOutcome.saved(ModbusRegisterDef this.register);
  const _EditOutcome.deleted() : register = null;

  final ModbusRegisterDef? register;
}

class _RegisterEditDialog extends StatefulWidget {
  const _RegisterEditDialog({this.existing});

  final ModbusRegisterDef? existing;

  @override
  State<_RegisterEditDialog> createState() => _RegisterEditDialogState();
}

class _RegisterEditDialogState extends State<_RegisterEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _scale;
  late final TextEditingController _unit;
  late final TextEditingController _note;
  late ModbusRegisterKind _kind;
  late ModbusDataType _dataType;
  late String _byteOrder;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _address = TextEditingController(text: e == null ? '' : '${e.address}');
    _scale = TextEditingController(
        text: e == null ? '1' : _formatNumber(e.scale, '.'));
    _unit = TextEditingController(text: e?.unit ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _kind = e?.kind ?? ModbusRegisterKind.holding;
    _dataType = e?.dataType ?? ModbusDataType.uint16;
    _byteOrder = e?.byteOrder ?? 'ABCD';
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _scale.dispose();
    _unit.dispose();
    _note.dispose();
    super.dispose();
  }

  int? _parseAddress(String text) {
    final v = int.tryParse(text.trim());
    if (v == null || v < 0 || v > 65535) return null;
    return v;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final scale = parseDecimal(_scale.text.trim());
    final def = ModbusRegisterDef(
      id: widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      kind: _kind,
      address: _parseAddress(_address.text)!,
      dataType: _kind.isBit ? ModbusDataType.uint16 : _dataType,
      byteOrder: _byteOrder,
      scale: _kind.isBit || scale == null || scale == 0 ? 1 : scale,
      unit: _kind.isBit ? '' : _unit.text.trim(),
      note: _note.text.trim(),
    );
    Navigator.of(context).pop(_EditOutcome.saved(def));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isBit = _kind.isBit;
    return AlertDialog(
      title: Text(widget.existing == null
          ? loc.modbusToolAddRegister
          : loc.modbusToolEditRegister),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration:
                    InputDecoration(labelText: loc.modbusToolNameLabel),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? loc.requiredFieldError
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ModbusRegisterKind>(
                initialValue: _kind,
                isExpanded: true,
                decoration:
                    InputDecoration(labelText: loc.modbusToolKindLabel),
                items: [
                  for (final k in ModbusRegisterKind.values)
                    DropdownMenuItem(value: k, child: Text(k.label)),
                ],
                onChanged: (k) {
                  if (k != null) setState(() => _kind = k);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                decoration: InputDecoration(
                  labelText: loc.modbusToolAddressLabel,
                  helperText: loc.modbusToolAddressHint,
                  helperMaxLines: 2,
                ),
                validator: (v) => _parseAddress(v ?? '') == null
                    ? loc.modbusToolInvalidAddress
                    : null,
              ),
              if (!isBit) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<ModbusDataType>(
                  initialValue: _dataType,
                  isExpanded: true,
                  decoration:
                      InputDecoration(labelText: loc.modbusToolDataTypeLabel),
                  items: [
                    for (final t in ModbusDataType.values)
                      DropdownMenuItem(value: t, child: Text(t.dbValue)),
                  ],
                  onChanged: (t) {
                    if (t != null) setState(() => _dataType = t);
                  },
                ),
                if (_dataType.is32Bit) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _byteOrder,
                    isExpanded: true,
                    decoration: InputDecoration(
                        labelText: loc.modbusToolByteOrderLabel),
                    items: [
                      for (final o in kModbusByteOrders)
                        DropdownMenuItem(value: o, child: Text(o)),
                    ],
                    onChanged: (o) {
                      if (o != null) setState(() => _byteOrder = o);
                    },
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _scale,
                  decoration: InputDecoration(
                    labelText: loc.modbusToolScaleLabel,
                    helperText: loc.modbusToolScaleHint,
                    helperMaxLines: 2,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  validator: (v) {
                    final s = parseDecimal((v ?? '').trim());
                    return s == null || s == 0
                        ? loc.modbusToolInvalidValue
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _unit,
                  decoration: InputDecoration(labelText: loc.unitLabel),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                decoration: InputDecoration(
                  labelText: loc.notesLabel,
                  hintText: loc.modbusToolNoteHint,
                ),
                maxLines: null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.existing != null)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () =>
                Navigator.of(context).pop(const _EditOutcome.deleted()),
            child: Text(loc.deleteButton),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancelButton),
        ),
        FilledButton(onPressed: _save, child: Text(loc.saveButton)),
      ],
    );
  }
}

/// Érték bekérése íráshoz. Bitnél `bool`, egész típusnál `int`, float32-nél
/// `double` nyers értékkel tér vissza.
class _WriteDialog extends StatefulWidget {
  const _WriteDialog({
    required this.register,
    required this.current,
    required this.decimalSeparator,
  });

  final ModbusRegisterDef register;
  final Object? current;
  final String decimalSeparator;

  @override
  State<_WriteDialog> createState() => _WriteDialogState();
}

class _WriteDialogState extends State<_WriteDialog> {
  late final TextEditingController _controller;
  late bool _bit;
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = widget.register;
    final current = widget.current;
    _bit = current is bool ? current : false;
    _controller = TextEditingController(
      text: current is num
          ? (current is int && d.scale == 1
              ? '$current'
              : _formatNumber(d.displayFromRaw(current), widget.decimalSeparator))
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final d = widget.register;
    if (d.isBit) {
      Navigator.of(context).pop<Object>(_bit);
      return;
    }
    final loc = AppLocalizations.of(context)!;
    final text = _controller.text.trim();
    // Egész típusnál hexa is megadható (0x...), szorzó nélkül.
    final hex = text.toLowerCase().startsWith('0x') && !d.dataType.isFloat
        ? int.tryParse(text)
        : null;
    num? raw;
    if (hex != null) {
      final bits = d.dataType.is32Bit ? 32 : 16;
      raw = hex >= 0 && hex < (1 << bits) ? hex : null;
    } else {
      final value = parseDecimal(text);
      raw = value == null ? null : d.rawFromDisplay(value);
    }
    if (raw == null) {
      setState(() => _error = loc.modbusToolInvalidValue);
      return;
    }
    Navigator.of(context).pop<Object>(raw);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final d = widget.register;
    return AlertDialog(
      title: Text(d.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${d.kind.label} ${d.address}',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            if (d.isBit)
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(loc.modbusToolOff)),
                  ButtonSegment(value: true, label: Text(loc.modbusToolOn)),
                ],
                selected: {_bit},
                onSelectionChanged: (s) => setState(() => _bit = s.first),
              )
            else
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: loc.modbusToolValueLabel,
                  suffixText: d.unit.isEmpty ? null : d.unit,
                  errorText: _error,
                ),
                onSubmitted: (_) => _send(),
              ),
            if (d.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(d.note, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            Text(
              loc.modbusToolWriteWarning,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancelButton),
        ),
        FilledButton.icon(
          onPressed: _send,
          icon: const Icon(Icons.send),
          label: Text(loc.modbusToolSend),
        ),
      ],
    );
  }
}
