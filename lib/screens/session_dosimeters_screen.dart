import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/session_dosimeter.dart';
import '../models/session_person_link.dart';
import '../widgets/dose_widgets.dart';

/// Egy felmérés doziméterei: tetszőleges számú, típussal, azonosítóval és
/// viselővel. Az elektronikus (EPD) doziméternél a kezdő- és záróállás adja a
/// dózist, a passzív (TL) doziméternél a kiértékelt dózist kell megadni.
class SessionDosimetersScreen extends StatefulWidget {
  final int surveySessionId;

  const SessionDosimetersScreen({super.key, required this.surveySessionId});

  @override
  State<SessionDosimetersScreen> createState() =>
      _SessionDosimetersScreenState();
}

class _SessionDosimetersScreenState extends State<SessionDosimetersScreen> {
  List<SessionDosimeter> _items = [];
  List<AttachedPerson> _persons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final db = DatabaseHelper.instance;
    final snapshot = await db.getSessionDoseSnapshot(widget.surveySessionId);
    final persons = await db.getAttachedPersons(widget.surveySessionId);
    if (!mounted) return;
    setState(() {
      _items = snapshot.dosimeters;
      _persons = persons;
      _loading = false;
    });
  }

  Future<void> _edit({SessionDosimeter? existing}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _DosimeterEditDialog(
        surveySessionId: widget.surveySessionId,
        persons: _persons,
        existing: existing,
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _delete(SessionDosimeter dosimeter) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.dosimeterDeleteTitle),
        content: Text(loc.dosimeterDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.deleteButton),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.deleteSessionDosimeter(dosimeter.id!);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.dosimetersButton)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(loc.noDosimetersYet))
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final d = _items[index];
                    final dose = d.resolvedDoseUsv;
                    return ListTile(
                      onTap: () => _edit(existing: d),
                      leading: Icon(
                        d.kind.electronic ? Icons.sensors : Icons.badge_outlined,
                      ),
                      title: Text(
                        '${dosimeterKindLabel(loc, d.kind)} · ${d.identifier}',
                      ),
                      subtitle: Text(
                        [
                          d.personName ?? loc.dosimeterNobody,
                          dose == null
                              ? loc.dosimeterNoReading
                              : formatDose(context, dose),
                          if (!d.includeAnnual) loc.notCountedInAnnualLabel,
                        ].join(' · '),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(d),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: Text(loc.addDosimeterButton),
      ),
    );
  }
}

class _DosimeterEditDialog extends StatefulWidget {
  const _DosimeterEditDialog({
    required this.surveySessionId,
    required this.persons,
    this.existing,
  });

  final int surveySessionId;
  final List<AttachedPerson> persons;
  final SessionDosimeter? existing;

  @override
  State<_DosimeterEditDialog> createState() => _DosimeterEditDialogState();
}

class _DosimeterEditDialogState extends State<_DosimeterEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late DosimeterKind _kind = widget.existing?.kind ?? DosimeterKind.epdGamma;
  late final TextEditingController _identifier =
      TextEditingController(text: widget.existing?.identifier ?? '');
  late int? _personId = widget.existing?.personId;
  late bool _include = widget.existing?.includeAnnual ?? true;
  final _start = DoseFieldController();
  final _end = DoseFieldController();
  final _value = DoseFieldController();
  bool _initialized = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final locale = Localizations.localeOf(context).toString();
    final e = widget.existing;
    _start.setMicroSv(e?.startUsv, locale);
    _end.setMicroSv(e?.endUsv, locale);
    _value.setMicroSv(e?.doseUsv, locale);
  }

  @override
  void dispose() {
    _identifier.dispose();
    _start.dispose();
    _end.dispose();
    _value.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final electronic = _kind.electronic;
    final start = electronic ? _start.microSv : null;
    final end = electronic ? _end.microSv : null;
    if (start != null && end != null && end < start) {
      setState(() => _error = loc.dosimeterEndBeforeStartError);
      return;
    }
    final now = DateTime.now();
    final e = widget.existing;
    final dosimeter = SessionDosimeter(
      id: e?.id,
      surveySessionId: widget.surveySessionId,
      kind: _kind,
      identifier: _identifier.text.trim(),
      personId: _personId,
      startUsv: start,
      endUsv: end,
      doseUsv: electronic ? null : _value.microSv,
      includeAnnual: _include,
      notes: e?.notes,
      createdAt: e?.createdAt ?? now,
      updatedAt: now,
    );
    final db = DatabaseHelper.instance;
    if (e == null) {
      await db.insertSessionDosimeter(dosimeter);
    } else {
      await db.updateSessionDosimeter(dosimeter);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? loc.addDosimeterButton
            : loc.dosimeterEditTitle,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<DosimeterKind>(
                initialValue: _kind,
                decoration: InputDecoration(
                  labelText: loc.dosimeterTypeLabel,
                  isDense: true,
                ),
                items: [
                  for (final k in DosimeterKind.values)
                    DropdownMenuItem(
                      value: k,
                      child: Text(dosimeterKindLabel(loc, k)),
                    ),
                ],
                onChanged: (k) => setState(() => _kind = k ?? _kind),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _identifier,
                decoration: InputDecoration(
                  labelText: loc.dosimeterIdentifierLabel,
                  isDense: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? loc.requiredFieldError
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _personId,
                decoration: InputDecoration(
                  labelText: loc.dosimeterPersonLabel,
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(loc.dosimeterNobody),
                  ),
                  for (final a in widget.persons)
                    DropdownMenuItem<int?>(
                      value: a.person.id,
                      child: Text(a.person.name),
                    ),
                ],
                onChanged: (v) => setState(() => _personId = v),
              ),
              const SizedBox(height: 12),
              if (_kind.electronic) ...[
                DoseValueField(
                  controller: _start,
                  label: loc.dosimeterStartLabel,
                ),
                const SizedBox(height: 8),
                DoseValueField(
                  controller: _end,
                  label: loc.dosimeterEndLabel,
                ),
              ] else
                DoseValueField(
                  controller: _value,
                  label: loc.dosimeterValueLabel,
                ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _include,
                title: Text(loc.includeInAnnualLabel),
                onChanged: (v) => setState(() => _include = v ?? true),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(loc.cancelButton),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(loc.saveButton),
        ),
      ],
    );
  }
}
