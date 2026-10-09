import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/measurement_point.dart';
import '../models/point_source_link.dart';
import '../models/radiation_source.dart';
import 'point_source_detail_screen.dart';
import 'radiation_source_entry_screen.dart';

/// Egy mérési ponthoz hozzárendelt sugárforrások — a globális
/// nyilvántartásból választva, ponton érvényes távolsággal.
class PointSourceLinkScreen extends StatefulWidget {
  final MeasurementPoint measurementPoint;

  /// A pont "Távolság a forrástól" mezőjének aktuális értéke, ha van —
  /// ezt ajánljuk fel alapértelmezett távolságként egy új hozzárendelésnél,
  /// hogy ne kelljen mindig újra beírni.
  final double? initialDistanceMeters;

  const PointSourceLinkScreen({
    super.key,
    required this.measurementPoint,
    this.initialDistanceMeters,
  });

  @override
  State<PointSourceLinkScreen> createState() => _PointSourceLinkScreenState();
}

class _PointSourceLinkScreenState extends State<PointSourceLinkScreen> {
  late Future<List<AttachedSource>> _attachedFuture;
  final _dateFormat = DateFormat('yyyy.MM.dd');

  /// A választó-lista alján megjelenő "Forrás hozzáadása" sor jelzőértéke —
  /// ezt adja vissza a `showModalBottomSheet`, ha a felhasználó nem egy
  /// meglévő forrást választott, hanem újat akar felvenni.
  static const _newSourceSentinel = '__new_source__';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _attachedFuture = DatabaseHelper.instance
          .getAttachedSources(widget.measurementPoint.id!);
    });
  }

  Future<void> _attachSource(List<AttachedSource> alreadyAttached) async {
    final loc = AppLocalizations.of(context)!;
    final allSources = await DatabaseHelper.instance.getRadiationSources();
    final attachedIds = alreadyAttached.map((a) => a.source.id).toSet();
    final selectable =
        allSources.where((s) => !attachedIds.contains(s.id)).toList();

    if (!mounted) return;

    final result = await showModalBottomSheet<Object>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                loc.pickSourceTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (selectable.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(loc.noSourcesToAttach),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: selectable.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final s = selectable[index];
                    return ListTile(
                      leading: const Icon(Icons.radio_button_checked),
                      title: Text('${s.identifier} · ${s.nuclideName}'),
                      onTap: () => Navigator.of(context).pop(s),
                    );
                  },
                ),
              ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(loc.newSourceButton),
              onTap: () => Navigator.of(context).pop(_newSourceSentinel),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;

    RadiationSource? picked;
    if (result is RadiationSource) {
      picked = result;
    } else if (result == _newSourceSentinel) {
      final priorIds = allSources.map((s) => s.id).toSet();
      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const RadiationSourceEntryScreen()),
      );
      if (created != true || !mounted) return;
      final refreshed = await DatabaseHelper.instance.getRadiationSources();
      for (final s in refreshed) {
        if (!priorIds.contains(s.id)) {
          picked = s;
          break;
        }
      }
    }
    if (picked == null || !mounted) return;

    final distance =
        await _promptDistance(loc, initialValue: widget.initialDistanceMeters);
    if (distance == null) return;

    await DatabaseHelper.instance.insertPointSource(
      measurementPointId: widget.measurementPoint.id!,
      radiationSourceId: picked.id!,
      distanceMeters: distance,
    );
    _reload();
  }

  Future<double?> _promptDistance(
    AppLocalizations loc, {
    double? initialValue,
  }) async {
    final ctrl = TextEditingController(
      text: initialValue == null ? '' : initialValue.toString(),
    );
    String? errorText;
    return showDialog<double>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(loc.enterDistanceDialogTitle),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: loc.sourceDistanceLabel,
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.cancelButton),
            ),
            FilledButton(
              onPressed: () {
                final parsed = double.tryParse(ctrl.text.trim());
                if (parsed == null || parsed <= 0) {
                  setState(() => errorText = loc.numberRequiredError);
                  return;
                }
                Navigator.of(context).pop(parsed);
              },
              child: Text(loc.saveButton),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDetach(AttachedSource attached) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.detachSourceConfirmTitle),
        content:
            Text(loc.detachSourceConfirmMessage(attached.source.identifier)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.detachButton),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.deletePointSource(attached.link.id!);
      _reload();
    }
  }

  Future<void> _openDetail(AttachedSource attached) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PointSourceDetailScreen(
          attached: attached,
          measurementPoint: widget.measurementPoint,
        ),
      ),
    );
    if (changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.pointSourcesTitle)),
      body: FutureBuilder<List<AttachedSource>>(
        future: _attachedFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final attached = snapshot.data!;
          if (attached.isEmpty) {
            return Center(child: Text(loc.noSourcesRecordedYet));
          }
          final now = DateTime.now();
          return ListView.separated(
            itemCount: attached.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final a = attached[index];
              final expired = a.source.isExpiredAt(now);
              return ListTile(
                leading: Icon(
                  expired ? Icons.warning_amber : Icons.radio_button_checked,
                  color: expired ? Colors.deepOrange : Colors.grey,
                ),
                title: Text('${a.source.identifier} · ${a.source.nuclideName}'),
                subtitle: Text(
                  '${double.parse(a.link.distanceMeters.toStringAsFixed(2))} m · '
                  '${loc.manufactureDateLabel}: '
                  '${_dateFormat.format(a.source.manufactureDate)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.link_off),
                  tooltip: loc.detachButton,
                  onPressed: () => _confirmDetach(a),
                ),
                onTap: () => _openDetail(a),
              );
            },
          );
        },
      ),
      floatingActionButton: FutureBuilder<List<AttachedSource>>(
        future: _attachedFuture,
        builder: (context, snapshot) {
          return FloatingActionButton.extended(
            onPressed: () => _attachSource(snapshot.data ?? const []),
            icon: const Icon(Icons.add_link),
            label: Text(loc.attachSourceButton),
          );
        },
      ),
    );
  }
}
