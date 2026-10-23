import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/map_area.dart';

/// A területek választható színei (ARGB).
const mapAreaPalette = <int>[
  0xFFE53935, // piros
  0xFFFB8C00, // narancs
  0xFFFDD835, // sárga
  0xFF43A047, // zöld
  0xFF1E88E5, // kék
  0xFF8E24AA, // lila
  0xFF757575, // szürke
  0xFF6D4C41, // barna
];

/// Az "Új terület" párbeszédpanel eredménye: név, szín és alakzat.
class MapAreaDraft {
  const MapAreaDraft({
    required this.name,
    required this.colorArgb,
    required this.shape,
  });

  final String name;
  final int colorArgb;
  final MapAreaShape shape;
}

Future<MapAreaDraft?> showMapAreaDraftDialog(BuildContext context) {
  return showDialog<MapAreaDraft>(
    context: context,
    builder: (_) => const _MapAreaDraftDialog(),
  );
}

class _MapAreaDraftDialog extends StatefulWidget {
  const _MapAreaDraftDialog();

  @override
  State<_MapAreaDraftDialog> createState() => _MapAreaDraftDialogState();
}

class _MapAreaDraftDialogState extends State<_MapAreaDraftDialog> {
  final _nameCtrl = TextEditingController();
  int _color = mapAreaPalette.first;
  MapAreaShape _shape = MapAreaShape.polygon;
  bool _nameMissing = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations loc) {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameMissing = true);
      return;
    }
    Navigator.of(context).pop(
      MapAreaDraft(name: name, colorArgb: _color, shape: _shape),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final labelStyle = Theme.of(context).textTheme.labelLarge;
    return AlertDialog(
      title: Text(loc.mapAreaNewTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: loc.mapAreaNameLabel,
                errorText: _nameMissing ? loc.mapAreaNameRequired : null,
              ),
              onChanged: (_) {
                if (_nameMissing) setState(() => _nameMissing = false);
              },
            ),
            const SizedBox(height: 16),
            Text(loc.mapAreaShapeLabel, style: labelStyle),
            const SizedBox(height: 6),
            SegmentedButton<MapAreaShape>(
              segments: [
                ButtonSegment(
                  value: MapAreaShape.polygon,
                  label: Text(loc.mapAreaPolygon),
                ),
                ButtonSegment(
                  value: MapAreaShape.circle,
                  label: Text(loc.mapAreaCircle),
                ),
              ],
              selected: {_shape},
              onSelectionChanged: (s) => setState(() => _shape = s.first),
            ),
            const SizedBox(height: 16),
            Text(loc.mapAreaColorLabel, style: labelStyle),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in mapAreaPalette)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == c ? Colors.black : Colors.grey,
                          width: _color == c ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancelButton),
        ),
        FilledButton(
          onPressed: () => _submit(loc),
          child: Text(loc.mapAreaStartDrawing),
        ),
      ],
    );
  }
}
