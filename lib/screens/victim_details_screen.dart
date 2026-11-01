import '../widgets/phantom_painter.dart';
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../l10n/domain_labels.dart';
import '../models/isotope.dart';
import '../models/person.dart';
import '../models/person_condition.dart';
import 'person_entry_screen.dart';
import '../models/session_person_link.dart';
import '../models/victim_details.dart';

/// Egy felméréshez rendelt személy egy ablakban: szerep, triázs, sérülések és
/// betegségek, valamint a fantomrajz jelölései (sérülés, és opcionálisan
/// izotóp, vegyi és biológiai szennyező). A nem, kor, súly és magasság a
/// személy adatlapján szerkeszthető, itt csak megjelenik.
class VictimDetailsScreen extends StatefulWidget {
  const VictimDetailsScreen({super.key, required this.attached});

  final AttachedPerson attached;

  @override
  State<VictimDetailsScreen> createState() => _VictimDetailsScreenState();
}

/// Egy szerkesztés alatti sérülés/betegség-sor.
class _ConditionRow {
  _ConditionRow(this.kind, String description)
      : controller = TextEditingController(text: description);

  ConditionKind kind;
  final TextEditingController controller;
}

class _VictimDetailsScreenState extends State<VictimDetailsScreen> {
  static const _hitRadius = 0.06;

  late Person _person;
  late SessionPersonRole _role;
  TriageCategory? _triage;
  final List<_ConditionRow> _rows = [];
  // Törölt sorok vezérlői: a dispose-t a widget megszűnéséig halasztjuk.
  final List<TextEditingController> _discarded = [];
  late List<BodyMarker> _markers;
  BodySide _side = BodySide.front;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final link = widget.attached.link;
    _person = widget.attached.person;
    _role = link.role;
    _triage = link.triage;
    _markers = List.of(link.bodyMarkers);
    _loadConditions();
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

  Future<void> _loadConditions() async {
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

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  String _sexLabel(AppLocalizations loc, VictimSex s) => switch (s) {
        VictimSex.female => loc.victimSexFemale,
        VictimSex.male => loc.victimSexMale,
        VictimSex.unknown => loc.victimSexUnknown,
      };

  String _sideLabel(AppLocalizations loc, BodySide s) =>
      s == BodySide.front ? loc.victimPhantomFront : loc.victimPhantomBack;

  String _kindLabel(AppLocalizations loc, MarkerKind k) =>
      k == MarkerKind.injury
          ? loc.victimMarkerKindInjury
          : loc.victimMarkerKindContamination;

  String _markerTitle(AppLocalizations loc, BodyMarker m) => [
        _sideLabel(loc, m.side),
        _kindLabel(loc, m.kind),
        if (m.hasContaminant) m.contaminantText,
      ].join(' · ');

  /// A személy adatlapjáról: nem, kor, súly, magasság (csak megjelenítés).
  String _personSummary(AppLocalizations loc) {
    final p = _person;
    return [
      '${loc.personNameLabel}: ${p.name}',
      '${loc.personIdentifierLabel}: ${p.identifier ?? '—'}',
      '${loc.victimSexLabel}: ${p.sex == null ? '—' : _sexLabel(loc, p.sex!)}',
      '${loc.victimAgeLabel}: ${p.ageYears?.toString() ?? '—'}',
      '${loc.victimWeightLabel}: ${p.weightKg == null ? '—' : _fmt(p.weightKg!)}',
      '${loc.victimHeightLabel}: ${p.heightCm == null ? '—' : _fmt(p.heightCm!)}',
    ].join(' · ');
  }

  /// Koppintás a rajzra: a közeli jelölés szerkesztése, különben új jelölés.
  void _onFigureTap(Offset local, Size size) {
    final x = (local.dx / size.width).clamp(0.0, 1.0).toDouble();
    final y = (local.dy / size.height).clamp(0.0, 1.0).toDouble();
    int? hit;
    var best = _hitRadius * _hitRadius;
    for (var i = 0; i < _markers.length; i++) {
      final m = _markers[i];
      if (m.side != _side) continue;
      final dx = m.x - x;
      final dy = m.y - y;
      final d2 = dx * dx + dy * dy;
      if (d2 <= best) {
        best = d2;
        hit = i;
      }
    }
    if (hit != null) {
      _editMarker(hit);
    } else {
      _addMarkerAt(x, y);
    }
  }

  Future<void> _addMarkerAt(double x, double y) async {
    final result = await showDialog<_MarkerResult>(
      context: context,
      builder: (_) => const _MarkerDialog(existing: null),
    );
    if (!mounted || result == null) return;
    setState(() => _markers.add(BodyMarker(
          side: _side,
          x: x,
          y: y,
          kind: result.kind,
          isotope: result.isotope,
          chemical: result.chemical,
          biological: result.biological,
          note: result.note,
        )));
  }

  Future<void> _editMarker(int index) async {
    final current = _markers[index];
    final result = await showDialog<_MarkerResult>(
      context: context,
      builder: (_) => _MarkerDialog(existing: current),
    );
    if (!mounted || result == null) return;
    setState(() {
      if (result.delete) {
        _markers.removeAt(index);
      } else {
        _markers[index] = BodyMarker(
          side: current.side,
          x: current.x,
          y: current.y,
          kind: result.kind,
          isotope: result.isotope,
          chemical: result.chemical,
          biological: result.biological,
          note: result.note,
        );
      }
    });
  }

  /// A személy adatlapjának szerkesztése; visszatéréskor a friss adatokat tölti be.
  Future<void> _editPerson() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PersonEntryScreen(existing: _person)),
    );
    if (saved != true || !mounted) return;
    final all = await DatabaseHelper.instance.getPersons();
    for (final p in all) {
      if (p.id == _person.id) {
        setState(() => _person = p);
        break;
      }
    }
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
    await db.updateBodyMarkers(linkId: linkId, markers: _markers);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelLarge;
    final isVictim = _role == SessionPersonRole.victim;

    return Scaffold(
      appBar: AppBar(
        title: Text(_person.name),
        actions: [
          IconButton(
            tooltip: loc.editPersonTitle,
            icon: const Icon(Icons.person_outline),
            onPressed: _loading ? null : _editPerson,
          ),
          IconButton(
            tooltip: loc.saveButton,
            icon: const Icon(Icons.save),
            onPressed: (_saving || _loading) ? null : _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    onSelectionChanged: (s) => setState(() => _role = s.first),
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
                    Text(loc.victimPersonDataHeading, style: labelStyle),
                    const SizedBox(height: 6),
                    Text(_personSummary(loc)),
                    const SizedBox(height: 4),
                    Text(loc.victimPersonDataHint,
                        style: theme.textTheme.bodySmall),
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
                    const SizedBox(height: 16),
                    Text(loc.victimMarkersHeading, style: labelStyle),
                    const SizedBox(height: 6),
                    SegmentedButton<BodySide>(
                      segments: [
                        ButtonSegment(
                            value: BodySide.front,
                            label: Text(loc.victimPhantomFront)),
                        ButtonSegment(
                            value: BodySide.back,
                            label: Text(loc.victimPhantomBack)),
                      ],
                      selected: {_side},
                      onSelectionChanged: (s) => setState(() => _side = s.first),
                    ),
                    const SizedBox(height: 8),
                    Text(loc.victimPhantomHint,
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Center(
                      child: SizedBox(
                        width: 200,
                        child: AspectRatio(
                          aspectRatio: 0.6,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final size = Size(
                                  constraints.maxWidth, constraints.maxHeight);
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapUp: (d) =>
                                    _onFigureTap(d.localPosition, size),
                                child: CustomPaint(
                                  size: size,
                                  painter: PhantomPainter(
                                      side: _side, markers: _markers),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_markers.isEmpty)
                      Text(loc.victimNoMarkers)
                    else
                      for (var i = 0; i < _markers.length; i++)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 12,
                            child: Text('${i + 1}',
                                style: const TextStyle(fontSize: 11)),
                          ),
                          title: Text(_markerTitle(loc, _markers[i])),
                          subtitle: _markers[i].note.isEmpty
                              ? null
                              : Text(_markers[i].note),
                          onTap: () => _editMarker(i),
                        ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: (_saving || _loading) ? null : _save,
                    child: Text(loc.saveButton),
                  ),
                ],
              ),
            ),
    );
  }
}

/// A jelölő-párbeszédpanel eredménye. A `delete` a törlést jelöli.
class _MarkerResult {
  const _MarkerResult({
    required this.kind,
    this.isotope,
    this.chemical,
    this.biological,
    this.note = '',
    this.delete = false,
  });

  final MarkerKind kind;
  final String? isotope;
  final String? chemical;
  final String? biological;
  final String note;
  final bool delete;
}

class _MarkerDialog extends StatefulWidget {
  const _MarkerDialog({required this.existing});

  final BodyMarker? existing;

  @override
  State<_MarkerDialog> createState() => _MarkerDialogState();
}

class _MarkerDialogState extends State<_MarkerDialog> {
  late MarkerKind _kind;
  String? _isotope;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _chemCtrl;
  late final TextEditingController _bioCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _kind = e?.kind ?? MarkerKind.injury;
    _isotope = e?.isotope;
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _chemCtrl = TextEditingController(text: e?.chemical ?? '');
    _bioCtrl = TextEditingController(text: e?.biological ?? '');
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _chemCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_MarkerResult(
      kind: _kind,
      isotope: _isotope,
      chemical: _nullIfEmpty(_chemCtrl.text),
      biological: _nullIfEmpty(_bioCtrl.text),
      note: _noteCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.existing == null
          ? loc.victimMarkerTitleNew
          : loc.victimMarkerTitleEdit),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<MarkerKind>(
              initialValue: _kind,
              decoration: InputDecoration(labelText: loc.victimMarkerKindLabel),
              items: [
                for (final k in MarkerKind.values)
                  DropdownMenuItem(
                    value: k,
                    child: Text(k == MarkerKind.injury
                        ? loc.victimMarkerKindInjury
                        : loc.victimMarkerKindContamination),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _kind = v);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(labelText: loc.victimMarkerNoteLabel),
            ),
            const SizedBox(height: 12),
            Text(loc.victimContaminantHeading,
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            DropdownButtonFormField<String?>(
              initialValue: _isotope,
              decoration: InputDecoration(labelText: loc.victimMarkerIsotopeLabel),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('—')),
                for (final i in kKnownIsotopes)
                  DropdownMenuItem<String?>(value: i.name, child: Text(i.name)),
              ],
              onChanged: (v) => setState(() => _isotope = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _chemCtrl,
              decoration: InputDecoration(labelText: loc.victimMarkerChemicalLabel),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bioCtrl,
              decoration: InputDecoration(labelText: loc.victimMarkerBioLabel),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.existing != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              const _MarkerResult(kind: MarkerKind.injury, delete: true),
            ),
            child: Text(loc.victimMarkerDelete),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancelButton),
        ),
        FilledButton(onPressed: _submit, child: Text(loc.saveButton)),
      ],
    );
  }
}

String? _nullIfEmpty(String s) {
  final v = s.trim();
  return v.isEmpty ? null : v;
}
