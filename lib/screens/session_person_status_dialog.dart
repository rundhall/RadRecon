import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../l10n/domain_labels.dart';
import '../models/person_condition.dart';
import '../models/session_person_link.dart';

/// Egy felméréshez rendelt személy szerepe, triázs-besorolása, valamint az
/// érintettek sérülései és betegségei.
class SessionPersonStatusDialog extends StatefulWidget {
  final AttachedPerson attached;

  const SessionPersonStatusDialog({super.key, required this.attached});

  @override
  State<SessionPersonStatusDialog> createState() =>
      _SessionPersonStatusDialogState();
}

/// Egy szerkesztés alatti sérülés/betegség-sor.
class _ConditionRow {
  _ConditionRow(this.kind, String description)
      : controller = TextEditingController(text: description);

  ConditionKind kind;
  final TextEditingController controller;
}

class _SessionPersonStatusDialogState
    extends State<SessionPersonStatusDialog> {
  late SessionPersonRole _role;
  TriageCategory? _triage;
  final List<_ConditionRow> _rows = [];
  // Törölt sorok vezérlői: a dispose-t a widget megszűnéséig halasztjuk.
  final List<TextEditingController> _discarded = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _role = widget.attached.link.role;
    _triage = widget.attached.link.triage;
    _load();
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.controller.dispose();
    }
    for (final c in _discarded) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final all = await DatabaseHelper.instance
        .getPersonConditions(widget.attached.link.surveySessionId);
    final mine = all[widget.attached.link.id] ?? const <PersonCondition>[];
    if (!mounted) return;
    setState(() {
      for (final c in mine) {
        _rows.add(_ConditionRow(c.kind, c.description));
      }
      _loading = false;
    });
  }

  void _addRow() {
    setState(() => _rows.add(_ConditionRow(ConditionKind.injury, '')));
  }

  void _removeRow(_ConditionRow row) {
    setState(() {
      _rows.remove(row);
      _discarded.add(row.controller);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final db = DatabaseHelper.instance;
    final linkId = widget.attached.link.id!;
    final isVictim = _role == SessionPersonRole.victim;

    await db.updateSessionPersonStatus(
      linkId: linkId,
      role: _role,
      triage: _triage,
    );
    // Felmérőnél a sérülés-lista üres marad (a szerep váltásakor törlődik).
    await db.replacePersonConditions(linkId, [
      if (isVictim)
        for (final r in _rows)
          if (r.controller.text.trim().isNotEmpty)
            PersonCondition(
              linkId: linkId,
              kind: r.kind,
              description: r.controller.text.trim(),
            ),
    ]);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isVictim = _role == SessionPersonRole.victim;
    final labelStyle = Theme.of(context).textTheme.labelLarge;

    return AlertDialog(
      title: Text(widget.attached.person.name),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.rrRoleLabel, style: labelStyle),
                    const SizedBox(height: 6),
                    SegmentedButton<SessionPersonRole>(
                      segments: [
                        for (final r in SessionPersonRole.values)
                          ButtonSegment(
                            value: r,
                            label: Text(r.localized(loc)),
                          ),
                      ],
                      selected: {_role},
                      onSelectionChanged: (s) =>
                          setState(() => _role = s.first),
                    ),
                    if (isVictim) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<TriageCategory?>(
                        isExpanded: true,
                        initialValue: _triage,
                        decoration: InputDecoration(
                          labelText: loc.rrTriageCategoryLabel,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<TriageCategory?>(
                            value: null,
                            child: Text(
                              loc.rrTriageNone,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          for (final t in TriageCategory.values)
                            DropdownMenuItem<TriageCategory?>(
                              value: t,
                              child: Text(
                                t.localized(loc),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => _triage = v),
                      ),
                      const SizedBox(height: 16),
                      Text(loc.rrInjuriesAndIllnesses, style: labelStyle),
                      const SizedBox(height: 6),
                      for (final row in _rows)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              DropdownButton<ConditionKind>(
                                value: row.kind,
                                items: [
                                  for (final k in ConditionKind.values)
                                    DropdownMenuItem(
                                      value: k,
                                      child: Text(k.localized(loc)),
                                    ),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => row.kind = v);
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: row.controller,
                                  decoration: InputDecoration(
                                    hintText: loc.rrDescriptionHint,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: loc.rrDeleteTooltip,
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeRow(row),
                              ),
                            ],
                          ),
                        ),
                      TextButton.icon(
                        onPressed: _addRow,
                        icon: const Icon(Icons.add),
                        label: Text(loc.rrAddItem),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(loc.cancelButton),
        ),
        FilledButton(
          onPressed: (_saving || _loading) ? null : _save,
          child: Text(loc.saveButton),
        ),
      ],
    );
  }
}
