import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../l10n/domain_labels.dart';
import '../models/person.dart';
import '../models/person_condition.dart';
import '../models/person_dose.dart';
import '../models/session_person_link.dart';
import '../services/session_person_list_fields.dart';
import '../widgets/dose_widgets.dart';
import '../widgets/field_picker_dialog.dart';
import 'person_entry_screen.dart';
import 'session_dosimeters_screen.dart';
import 'victim_details_screen.dart';

/// A személy-sor szűrése szerep szerint.
enum _RoleFilter { all, surveyor, victim }

/// A személy-sor szűrése triázs-besorolás szerint (a "none": nincs besorolva).
enum _TriageFilter { all, none, immediate, delayed, minor, expectant }

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
  SessionDoseSnapshot _doses = SessionDoseSnapshot.empty;
  final _dateFormat = DateFormat('yyyy.MM.dd');
  Set<SessionPersonListField> _fields = {...kDefaultSessionPersonListFields};
  Map<int, List<PersonCondition>> _conditions = const {};
  String _query = '';
  _RoleFilter _roleFilter = _RoleFilter.all;
  _TriageFilter _triageFilter = _TriageFilter.all;
  bool _onlyExpired = false;

  /// A választó-lista alján megjelenő "Személy hozzáadása" sor jelzőértéke —
  /// ezt adja vissza a `showModalBottomSheet`, ha a felhasználó nem egy
  /// meglévő személyt választott, hanem újat akar felvenni.
  static const _newPersonSentinel = '__new_person__';

  @override
  void initState() {
    super.initState();
    _reload();
    _loadFields();
  }

  void _reload() {
    setState(() {
      _attachedFuture =
          DatabaseHelper.instance.getAttachedPersons(widget.surveySessionId);
    });
    DatabaseHelper.instance
        .getSessionDoseSnapshot(widget.surveySessionId)
        .then((doses) {
      if (mounted) setState(() => _doses = doses);
    });
    DatabaseHelper.instance
        .getPersonConditions(widget.surveySessionId)
        .then((c) {
      if (mounted) setState(() => _conditions = c);
    });
  }

  Future<void> _loadFields() async {
    final fields = await sessionPersonListFieldsStore.load();
    if (mounted) setState(() => _fields = fields);
  }

  String _fieldLabel(AppLocalizations loc, SessionPersonListField f) =>
      switch (f) {
        SessionPersonListField.role => loc.rrRoleLabel,
        SessionPersonListField.triage => loc.rrTriageCategoryLabel,
        SessionPersonListField.injuries => loc.rrInjuriesAndIllnesses,
        SessionPersonListField.expiry => loc.personListFieldExpiry,
        SessionPersonListField.certificates => loc.personCertificatesTitle,
        SessionPersonListField.contact => loc.personListFieldContact,
        SessionPersonListField.identifier => loc.personIdentifierLabel,
        SessionPersonListField.address => loc.personAddressLabel,
        SessionPersonListField.physical => loc.personPhysicalHeading,
        SessionPersonListField.notes => loc.notesLabel,
        SessionPersonListField.doseTotal => loc.doseTotalLabel,
        SessionPersonListField.doseBreakdown =>
          loc.personListFieldDoseBreakdown,
      };

  /// Menü: a személy-sorokon megjelenő adatcsoportok kiválasztása (mentve).
  Future<void> _showFieldsDialog() async {
    final loc = AppLocalizations.of(context)!;
    final result = await showFieldPickerDialog<SessionPersonListField>(
      context: context,
      title: loc.personListFieldsTitle,
      values: SessionPersonListField.values,
      labelOf: (f) => _fieldLabel(loc, f),
      selected: _fields,
      cancelLabel: loc.cancelButton,
      saveLabel: loc.saveButton,
    );
    if (result == null) return;
    await sessionPersonListFieldsStore.save(result);
    if (mounted) setState(() => _fields = result);
  }

  bool _matches(AttachedPerson a, String query, DateTime now) {
    if (query.isNotEmpty && !a.person.name.toLowerCase().contains(query)) {
      return false;
    }
    final roleOk = switch (_roleFilter) {
      _RoleFilter.all => true,
      _RoleFilter.surveyor => a.link.role == SessionPersonRole.surveyor,
      _RoleFilter.victim => a.link.role == SessionPersonRole.victim,
    };
    final triage = a.link.triage;
    final triageOk = switch (_triageFilter) {
      _TriageFilter.all => true,
      _TriageFilter.none => triage == null,
      _TriageFilter.immediate => triage == TriageCategory.immediate,
      _TriageFilter.delayed => triage == TriageCategory.delayed,
      _TriageFilter.minor => triage == TriageCategory.minor,
      _TriageFilter.expectant => triage == TriageCategory.expectant,
    };
    final expiredOk = !_onlyExpired || a.person.isExpiredAt(now);
    return roleOk && triageOk && expiredOk;
  }

  String _roleFilterLabel(AppLocalizations loc, _RoleFilter r) => switch (r) {
        _RoleFilter.all => loc.personFilterAll,
        _RoleFilter.surveyor => SessionPersonRole.surveyor.localized(loc),
        _RoleFilter.victim => SessionPersonRole.victim.localized(loc),
      };

  String _triageFilterLabel(AppLocalizations loc, _TriageFilter t) =>
      switch (t) {
        _TriageFilter.all => loc.personFilterAll,
        _TriageFilter.none => loc.rrTriageNone,
        _TriageFilter.immediate => TriageCategory.immediate.localized(loc),
        _TriageFilter.delayed => TriageCategory.delayed.localized(loc),
        _TriageFilter.minor => TriageCategory.minor.localized(loc),
        _TriageFilter.expectant => TriageCategory.expectant.localized(loc),
      };

  /// Keresés (név), szerep-, triázs- és lejárat-szűrő, és a mezőválasztó.
  Widget _filterBar(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: loc.searchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final r in _RoleFilter.values)
                ChoiceChip(
                  label: Text(_roleFilterLabel(loc, r)),
                  selected: _roleFilter == r,
                  onSelected: (_) => setState(() => _roleFilter = r),
                ),
              FilterChip(
                label: Text(loc.personFilterExpired),
                selected: _onlyExpired,
                onSelected: (v) => setState(() => _onlyExpired = v),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<_TriageFilter>(
                  value: _triageFilter,
                  items: [
                    for (final t in _TriageFilter.values)
                      DropdownMenuItem(
                        value: t,
                        child: Text(_triageFilterLabel(loc, t)),
                      ),
                  ],
                  onChanged: (t) {
                    if (t != null) setState(() => _triageFilter = t);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(AppLocalizations loc, AttachedPerson a, DateTime now) {
    final expired = a.person.isExpiredAt(now);
    final personId = a.person.id!;
    final totals = DoseTotals(
      session: _doses.sessionDoseOf(personId)?.doseMicroSv ?? 0,
      dosimeter: _doses
          .dosimetersOf(personId)
          .fold<double>(0, (s, d) => s + (d.resolvedDoseUsv ?? 0)),
    );
    final isVictim = a.link.role == SessionPersonRole.victim;
    return ListTile(
      onTap: () => _editDose(a),
      leading: Icon(
        isVictim
            ? Icons.medical_services_outlined
            : (expired ? Icons.warning_amber : Icons.person_outline),
        color:
            isVictim ? Colors.red : (expired ? Colors.deepOrange : Colors.grey),
      ),
      title: Text(a.person.name),
      subtitle: _rowSubtitle(loc, a, totals),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: loc.editPersonTitle,
            icon: const Icon(Icons.person_outline),
            onPressed: () => _editPerson(a.person),
          ),
          IconButton(
            tooltip: loc.rrEditStatusTooltip,
            icon: const Icon(Icons.medical_services_outlined),
            onPressed: () => _editStatus(a),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _confirmDetach(a),
          ),
        ],
      ),
    );
  }

  /// A személy-sor alcíme: csak a menüben bekapcsolt adatcsoportok.
  Widget _rowSubtitle(
      AppLocalizations loc, AttachedPerson a, DoseTotals totals) {
    final f = _fields;
    final p = a.person;
    final isVictim = a.link.role == SessionPersonRole.victim;
    final conditions = _conditions[a.link.id] ?? const <PersonCondition>[];
    final injuryItems = {
      for (final c in conditions) '${c.kind.localized(loc)}: ${c.description}',
    };
    final lines = <Widget>[
      if (f.contains(SessionPersonListField.role))
        Text('${loc.rrRoleLabel}: ${a.link.role.localized(loc)}'),
      if (f.contains(SessionPersonListField.triage) && isVictim)
        Text(
          '${loc.rrAffectedPrefix} · '
          '${a.link.triage?.localized(loc) ?? loc.rrTriageNone}',
          style: const TextStyle(color: Colors.red),
        ),
      if (f.contains(SessionPersonListField.injuries) &&
          injuryItems.isNotEmpty)
        Text(
          '${loc.rrInjuriesAndIllnesses}: ${injuryItems.join(' · ')}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      if (f.contains(SessionPersonListField.expiry))
        Text(
          '${loc.medicalExamExpiryDateLabel}: '
          '${p.medicalExamExpiryDate == null ? loc.notSetLabel : _dateFormat.format(p.medicalExamExpiryDate!)}'
          ' · ${loc.trainingExpiryDateLabel}: '
          '${p.trainingExpiryDate == null ? loc.notSetLabel : _dateFormat.format(p.trainingExpiryDate!)}',
        ),
      if (f.contains(SessionPersonListField.certificates) &&
          p.certificates.isNotEmpty)
        Text(p.certificates
            .map((c) => c.validUntil == null
                ? c.name
                : '${c.name} (${_dateFormat.format(c.validUntil!)})')
            .join(' · ')),
      if (f.contains(SessionPersonListField.contact) &&
          (p.phone != null || p.emails.isNotEmpty))
        Text([if (p.phone != null) p.phone!, ...p.emails].join(' · ')),
      if (f.contains(SessionPersonListField.identifier) &&
          p.identifier != null)
        Text('${loc.personIdentifierLabel}: ${p.identifier}'),
      if (f.contains(SessionPersonListField.address) && p.address != null)
        Text('${loc.personAddressLabel}: ${p.address}'),
      if (f.contains(SessionPersonListField.physical) &&
          (p.sex != null ||
              p.ageYears != null ||
              p.weightKg != null ||
              p.heightCm != null))
        Text([
          if (p.sex != null) p.sex!.localized(loc),
          if (p.ageYears != null) '${loc.victimAgeLabel}: ${p.ageYears}',
          if (p.weightKg != null)
            '${loc.victimWeightLabel}: ${p.weightKg!.toStringAsFixed(1)}',
          if (p.heightCm != null)
            '${loc.victimHeightLabel}: ${p.heightCm!.toStringAsFixed(0)}',
        ].join(' · ')),
      if (f.contains(SessionPersonListField.notes) &&
          (p.notes ?? '').isNotEmpty)
        Text(p.notes!, maxLines: 2, overflow: TextOverflow.ellipsis),
      if (f.contains(SessionPersonListField.doseTotal))
        Text(
          '${loc.doseTotalLabel}: ${formatDose(context, totals.total)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      if (f.contains(SessionPersonListField.doseBreakdown))
        Text(
          '(${loc.sessionDoseLabel.toLowerCase()} ${formatDose(context, totals.session)}'
          ' · ${loc.dosimeterDoseLabel.toLowerCase()} ${formatDose(context, totals.dosimeter)})',
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: lines,
    );
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

    final lastRoles = <int, SessionPersonRole>{};
    for (final p in selectable) {
      final r = await DatabaseHelper.instance.getLastSessionRoleOf(p.id!);
      if (r != null) lastRoles[p.id!] = r;
    }
    if (!mounted) return;

    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
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
                      subtitle: lastRoles[p.id] == null
                          ? null
                          : Text('${loc.lastUsedRoleLabel}: ${lastRoles[p.id]!.localized(loc)}'),
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

    final lastRole =
        await DatabaseHelper.instance.getLastSessionRoleOf(picked.id!);
    await DatabaseHelper.instance.insertSessionPerson(
      surveySessionId: widget.surveySessionId,
      personId: picked.id!,
      role: lastRole ?? SessionPersonRole.surveyor,
    );
    _reload();
  }

  Future<void> _editPerson(Person person) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PersonEntryScreen(existing: person)),
    );
    _reload();
  }

  Future<void> _editStatus(AttachedPerson attached) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => VictimDetailsScreen(attached: attached)),
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
      appBar: AppBar(
        title: Text(loc.sessionPersonsTitle),
        actions: [
          PopupMenuButton<String>(
            tooltip: loc.personListFieldsTitle,
            onSelected: (_) => _showFieldsDialog(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'fields',
                child: Row(
                  children: [
                    const Icon(Icons.view_list_outlined),
                    const SizedBox(width: 8),
                    Text(loc.personListFieldsTitle),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: loc.dosimetersButton,
            icon: const Icon(Icons.sensors),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SessionDosimetersScreen(
                  surveySessionId: widget.surveySessionId,
                ),
              ));
              _reload();
            },
          ),
        ],
      ),
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
          final query = _query.trim().toLowerCase();
          final visible = [
            for (final a in attached)
              if (_matches(a, query, now)) a,
          ];
          return Column(
            children: [
              _filterBar(loc),
              Expanded(
                child: visible.isEmpty
                    ? Center(child: Text(loc.searchNoResults))
                    : ListView.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) =>
                            _buildRow(loc, visible[index], now),
                      ),
              ),
            ],
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
