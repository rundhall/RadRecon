import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/modbus_probe_service.dart';

enum _ScanPhase { input, scanning, done, noConnection }

/// Unit ID keresés: megadott tartomány végigpróbálása, majd a válaszoló
/// ID-k közül egy kiválasztása. A kiválasztott ID-t adja vissza.
class ModbusUnitScanDialog extends StatefulWidget {
  const ModbusUnitScanDialog({
    super.key,
    required this.host,
    required this.port,
  });

  final String host;
  final int port;

  @override
  State<ModbusUnitScanDialog> createState() => _ModbusUnitScanDialogState();
}

class _ModbusUnitScanDialogState extends State<ModbusUnitScanDialog> {
  late final ModbusUnitScanner _scanner;
  final _fromCtrl =
      TextEditingController(text: '${ModbusUnitScanner.minUnitId}');
  final _toCtrl = TextEditingController(text: '${ModbusUnitScanner.maxUnitId}');
  _ScanPhase _phase = _ScanPhase.input;
  final List<int> _found = [];
  int _done = 0;
  int _total = 0;
  bool _stopRequested = false;
  bool _stopped = false;
  bool _rangeInvalid = false;

  @override
  void initState() {
    super.initState();
    _scanner = ModbusUnitScanner(host: widget.host, port: widget.port);
  }

  @override
  void dispose() {
    _stopRequested = true;
    unawaited(_scanner.close());
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  (int, int)? _parseRange() {
    final from = int.tryParse(_fromCtrl.text.trim());
    final to = int.tryParse(_toCtrl.text.trim());
    if (from == null || to == null) return null;
    const minId = ModbusUnitScanner.minUnitId;
    const maxId = ModbusUnitScanner.maxUnitId;
    if (from < minId || to > maxId || from > to) return null;
    return (from, to);
  }

  Future<void> _start() async {
    final range = _parseRange();
    if (range == null) {
      setState(() => _rangeInvalid = true);
      return;
    }
    final (from, to) = range;
    setState(() {
      _rangeInvalid = false;
      _phase = _ScanPhase.scanning;
      _found.clear();
      _done = 0;
      _total = to - from + 1;
      _stopRequested = false;
      _stopped = false;
    });
    final result = await _scanner.scan(
      from: from,
      to: to,
      isCancelled: () => _stopRequested,
      onStep: (done, unitId, found) {
        if (!mounted) return;
        setState(() {
          _done = done;
          if (found) _found.add(unitId);
        });
      },
    );
    if (!mounted) return;
    setState(() {
      _stopped = result.cancelled;
      _phase = result.connectionFailed
          ? _ScanPhase.noConnection
          : _ScanPhase.done;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.scanDialogTitle),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _body(loc),
          ),
        ),
      ),
      actions: _actions(loc),
    );
  }

  List<Widget> _body(AppLocalizations loc) {
    final theme = Theme.of(context);
    return switch (_phase) {
      _ScanPhase.input => [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fromCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: loc.scanFromLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _toCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: loc.scanToLabel),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _rangeInvalid ? loc.scanRangeInvalid : loc.scanRangeHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _rangeInvalid ? theme.colorScheme.error : null,
            ),
          ),
        ],
      _ScanPhase.scanning => [
          LinearProgressIndicator(value: _total == 0 ? null : _done / _total),
          const SizedBox(height: 8),
          Text(loc.scanProgress(_done, _total)),
          if (_found.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_found.join(', ')),
          ],
        ],
      _ScanPhase.done => [
          if (_stopped) Text(loc.scanCancelled),
          if (_found.isEmpty) Text(loc.scanNoneFound),
          for (final id in _found)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.scanFoundItem(id)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pop(id),
            ),
          if (_found.length > 1) ...[
            const SizedBox(height: 8),
            Text(loc.scanMultipleHint, style: theme.textTheme.bodySmall),
          ],
        ],
      _ScanPhase.noConnection => [
          Text(
            loc.failedToConnectToInstrument,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
    };
  }

  List<Widget> _actions(AppLocalizations loc) {
    return switch (_phase) {
      _ScanPhase.input => [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cancelButton),
          ),
          FilledButton(onPressed: _start, child: Text(loc.scanStartButton)),
        ],
      _ScanPhase.scanning => [
          FilledButton.icon(
            onPressed: _stopRequested
                ? null
                : () => setState(() => _stopRequested = true),
            icon: const Icon(Icons.stop),
            label: Text(loc.scanStopButton),
          ),
        ],
      _ScanPhase.done || _ScanPhase.noConnection => [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            onPressed: () => setState(() => _phase = _ScanPhase.input),
            child: Text(loc.scanRestartButton),
          ),
        ],
    };
  }
}
