import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/person.dart';
import '../models/person_dose.dart';
import '../models/session_person_link.dart';
import '../widgets/dose_widgets.dart';
import 'person_entry_screen.dart';

/// Egy felméréshez hozzárendelt személyek — a globális nyilvántartásból
/// választva, tetszőleges létszámban.
class SessionPersonLinkScreen extends StatefulWidget {
  final int surveySessionId;

  const SessionPersonLinkScreen({super.key, required this.surveySessionId});

  @override
  State<SessionPersonLinkScreen> createState() =>
      _SessionPersonLinkScreenState();
}

class _SessionPersonLinkScreenState extends State<SessionPersonLinkScreen> {
  late Future<List<AttachedPerson>> _attachedFuture;
  Map<int, Map<DoseSource, double>> _doses = {};
  final _dateFormat = DateFormat('yyyy.MM.dd');

  /// A választó-lista alján megjelenő "Személy hozzáadása" sor jelzőértéke —
  /// ezt adja vissza a `showModalBottomSheet`, ha a felhasználó nem egy
  /// meglévő személyt választott, hanem újat akar felvenni.
  static const _newPersonSentinel = '__new_person__';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _attachedFuture =
          DatabaseHelper.instance.getAttachedPersons(widget.surveySessionId);
    });
    DatabaseHelper.instance
        .getSessionDoses(widget.surveySessionId)
        .then((doses) {
      if (mounted) setState(() => _doses = doses);
    });
  }

  /// A személy online és manuális dózisának szerkesztése ehhez a felméréshez.
  Future<void> _editDose(AttachedPerson attached) async {
    final loc = AppLocalizations.of(context)!;
    final editorKey = GlobalKey<SessionDosesEditorState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.sessionDoseDialogTitle(attached.person.name)),
        content: SingleChildScrollView(
          child: SessionDosesEditor(
            key: editorKey,
            surveySessionId: widget.surveySessionId,
            persons: [attached],
            doses: _doses,
            showNames: false,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            onPressed: () async {
              if (await editorKey.currentState!.save() && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text(loc.saveButton),
          ),
        ],
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _attachPerson(List<AttachedPerson> alreadyAttached) async {
    final loc = AppLocalizations.of(context)!;
    final allPersons = await DatabaseHelper.instance.getPersons();
    final attachedIds = alreadyAttached.map((a) => a.person.id).toSet();
    final selectable =
        allPersons.where((p) => !attachedIds.contains(p.id)).toList();

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
                loc.pickPersonTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (selectable.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(loc.noPersonsToAttach),
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
                    final p = selectable[index];
                    return ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(p.name),
                      onTap: () => Navigator.of(context).pop(p),
                    );
                  },
                ),
              ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(loc.newPersonButton),
              onTap: () => Navigator.of(context).pop(_newPersonSentinel),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;

    Person? picked;
    if (result is Person) {
      picked = result;
    } else if (result == _newPersonSentinel) {
      final priorIds = allPersons.map((p) => p.id).toSet();
      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const PersonEntryScreen()),
      );
      if (created != true || !mounted) return;
      final refreshed = await DatabaseHelper.instance.getPersons();
      for (final p in refreshed) {
        if (!priorIds.contains(p.id)) {
          picked = p;
          break;
        }
      }
    }
    if (picked == null) return;

    await DatabaseHelper.instance.insertSessionPerson(
      surveySessionId: widget.surveySessionId,
      personId: picked.id!,
    );
    _reload();
  }

  Future<void> _confirmDetach(AttachedPerson attached) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.detachPersonConfirmTitle),
        content: Text(loc.detachPersonConfirmMessage(attached.person.name)),
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
      await DatabaseHelper.instance.deleteSessionPerson(attached.link.id!);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.sessionPersonsTitle)),
      body: FutureBuilder<List<AttachedPerson>>(
        future: _attachedFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final attached = snapshot.data!;
          if (attached.isEmpty) {
            return Center(child: Text(loc.noPersonsAttachedYet));
          }
          final now = DateTime.now();
          return ListView.separated(
            itemCount: attached.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final a = attached[index];
              final expired = a.person.isExpiredAt(now);
              final d = _doses[a.person.id] ?? const <DoseSource, double>{};
              final totals = DoseTotals(
                online: d[DoseSource.online] ?? 0,
                manual: d[DoseSource.manual] ?? 0,
              );
              return ListTile(
                isThreeLine: true,
                onTap: () => _editDose(a),
                leading: Icon(
                  expired ? Icons.warning_amber : Icons.person_outline,
                  color: expired ? Colors.deepOrange : Colors.grey,
                ),
                title: Text(a.person.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${loc.medicalExamExpiryDateLabel}: '
                      '${a.person.medicalExamExpiryDate == null ? loc.notSetLabel : _dateFormat.format(a.person.medicalExamExpiryDate!)}'
                      ' · ${loc.trainingExpiryDateLabel}: '
                      '${a.person.trainingExpiryDate == null ? loc.notSetLabel : _dateFormat.format(a.person.trainingExpiryDate!)}',
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${loc.doseTotalLabel}: ${formatDose(context, totals.total)}'
                      ' (${loc.onlineDoseLabel.toLowerCase()} ${formatDose(context, totals.online)}'
                      ' · ${loc.manualDoseLabel.toLowerCase()} ${formatDose(context, totals.manual)})',
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _confirmDetach(a),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FutureBuilder<List<AttachedPerson>>(
        future: _attachedFuture,
        builder: (context, snapshot) {
          return FloatingActionButton.extended(
            onPressed: () => _attachPerson(snapshot.data ?? const []),
            icon: const Icon(Icons.add),
            label: Text(loc.attachPersonButton),
          );
        },
      ),
    );
  }
}
