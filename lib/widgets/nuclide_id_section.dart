import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/nuclide_id.dart';

/// Nuklid-azonosítás űrlaprész egy mérési ponthoz: állapot (azonosított /
/// ismeretlen / egyéb / keverék) és az azonosított nuklidok.
///
/// Választás közben a teljes lista látszik; a "Kész" gomb után csak a
/// kiválasztott nuklidok maradnak a képernyőn (a "Nuklidok módosítása" gomb
/// újra megnyitja a listát). A felette lévő képernyő tartja az állapotot, ez
/// csak megjelenít.
class NuclideIdSection extends StatefulWidget {
  const NuclideIdSection({
    super.key,
    required this.status,
    required this.nuclides,
    required this.onStatusChanged,
    required this.onNuclidesChanged,
  });

  final NuclideIdStatus status;
  final List<String> nuclides;
  final ValueChanged<NuclideIdStatus> onStatusChanged;
  final ValueChanged<List<String>> onNuclidesChanged;

  @override
  State<NuclideIdSection> createState() => _NuclideIdSectionState();
}

class _NuclideIdSectionState extends State<NuclideIdSection> {
  final _customCtrl = TextEditingController();

  /// true: a választás kész, csak a kiválasztott nuklidok látszanak.
  /// Meglévő pont megnyitásakor, ha már vannak nuklidok, eleve összecsukva indul.
  late bool _collapsed = widget.nuclides.isNotEmpty;

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _toggle(String name, bool selected) {
    final next = [...widget.nuclides];
    if (selected) {
      if (!next.contains(name)) next.add(name);
    } else {
      next.remove(name);
    }
    widget.onNuclidesChanged(next);
  }

  void _addCustom() {
    final name = _customCtrl.text.trim();
    if (name.isEmpty) return;
    if (!widget.nuclides.contains(name)) {
      widget.onNuclidesChanged([...widget.nuclides, name]);
    }
    _customCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<NuclideIdStatus>(
          initialValue: widget.status,
          isExpanded: true,
          decoration: InputDecoration(labelText: loc.nuclideIdSectionTitle),
          items: [
            for (final s in NuclideIdStatus.values)
              DropdownMenuItem(value: s, child: Text(s.label(loc))),
          ],
          onChanged: (s) {
            if (s == null) return;
            // Új, még üres választásnál a lista megnyílik.
            if (s.hasNuclideList && widget.nuclides.isEmpty) {
              setState(() => _collapsed = false);
            }
            widget.onStatusChanged(s);
          },
        ),
        if (widget.status.hasNuclideList) ...[
          const SizedBox(height: 12),
          if (_collapsed)
            _buildSelectedOnly(loc)
          else
            _buildPicker(loc),
        ],
      ],
    );
  }

  /// Összecsukott nézet: csak a kiválasztott nuklidok, törölhető chipekkel.
  Widget _buildSelectedOnly(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.nuclides.isNotEmpty)
          Wrap(
            spacing: 6,
            children: [
              for (final name in widget.nuclides)
                InputChip(
                  label: Text(name),
                  onDeleted: () => _toggle(name, false),
                ),
            ],
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _collapsed = false),
            icon: const Icon(Icons.edit_outlined),
            label: Text(loc.nuclideEditButton),
          ),
        ),
      ],
    );
  }

  /// Választó nézet: a teljes lista (kijelölhető), plusz egyéb nuklid megadása.
  Widget _buildPicker(AppLocalizations loc) {
    final customNames = widget.nuclides
        .where((n) => !kIdentifiableNuclideNames.contains(n))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.nuclideKnownListLabel,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 0,
          children: [
            for (final name in kIdentifiableNuclideNames)
              FilterChip(
                label: Text(name),
                selected: widget.nuclides.contains(name),
                onSelected: (v) => _toggle(name, v),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customCtrl,
                decoration: InputDecoration(labelText: loc.nuclideCustomLabel),
                onSubmitted: (_) => _addCustom(),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _addCustom,
              child: Text(loc.nuclideAddButton),
            ),
          ],
        ),
        if (customNames.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (final name in customNames)
                InputChip(
                  label: Text(name),
                  onDeleted: () => _toggle(name, false),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonal(
            onPressed: () {
              // Ha a név mezőben maradt be nem küldött szöveg, azt is felvesszük.
              _addCustom();
              setState(() => _collapsed = true);
            },
            child: Text(loc.nuclideDoneButton),
          ),
        ),
      ],
    );
  }
}
