import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/activity_unit.dart';
import '../models/radiation_source.dart';
import '../services/dose_unit_controller.dart';
import '../services/regulatory_profile.dart';
import '../services/source_classification.dart';

/// Sugárforrások besorolása: D, R, fizikai védelmi kategória, mentességi
/// értékek, magyar profilnál az I./II./III. sugárvédelmi kategória is.
class SourceClassificationScreen extends StatefulWidget {
  const SourceClassificationScreen({super.key});

  @override
  State<SourceClassificationScreen> createState() =>
      _SourceClassificationScreenState();
}

class _SourceClassificationScreenState
    extends State<SourceClassificationScreen> {
  late Future<List<RadiationSource>> _future;
  final Set<int> _excluded = {};
  bool _unsealed = false;
  bool _outside = false;

  @override
  void initState() {
    super.initState();
    _future = DatabaseHelper.instance.getRadiationSources();
  }

  static String _fmt(double v) {
    if (v == 0) return '0';
    final a = v.abs();
    if (a >= 1e5 || a < 1e-3) return v.toStringAsExponential(2);
    return v.toStringAsPrecision(3);
  }

  static String _catName(RadiationProtectionCategory c) => switch (c) {
        RadiationProtectionCategory.i => 'I.',
        RadiationProtectionCategory.ii => 'II.',
        RadiationProtectionCategory.iii => 'III.',
      };

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.classificationTitle)),
      body: FutureBuilder<List<RadiationSource>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sources = snapshot.data!;
          if (sources.isEmpty) {
            return Center(child: Text(loc.noSourcesYet));
          }
          return ValueListenableBuilder<RegulatoryProfile>(
            valueListenable: RegulatoryProfileController.profile,
            builder: (context, profile, _) =>
                _buildBody(context, loc, sources, profile),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations loc,
      List<RadiationSource> sources, RegulatoryProfile profile) {
    final hu = profile == RegulatoryProfile.hungary;
    final now = DateTime.now();
    final unit = ActivityUnitController.current;
    final ctx = ClassificationContext(
        unsealedRegularWork: _unsealed, outsideWorkplace: _outside);

    final items = <RadiationSource, SourceClassification>{
      for (final s in sources) s: classifySource(s, now),
    };
    final included = [
      for (final e in items.entries)
        if (!_excluded.contains(e.key.id)) e.value,
    ];
    final agg = aggregateR(included);

    String protText(int physCat) => hu
        ? ' · ${loc.classificationProtCat}: '
            '${_catName(protectionCategoryFor(physCat, ctx))}'
            ' · ${loc.classificationProtLevel}: ${physicalProtectionLevel(physCat)}'
        : '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(loc.classificationDisclaimer,
            style: Theme.of(context).textTheme.bodySmall),
        if (hu) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(loc.classificationUnsealedWork),
            value: _unsealed,
            onChanged: (v) => setState(() => _unsealed = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(loc.classificationOutsideWorkplace),
            value: _outside,
            onChanged: (v) => setState(() => _outside = v),
          ),
        ],
        const SizedBox(height: 8),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.classificationTotal,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('R = ${_fmt(agg.sum)}'),
                Text('${loc.classificationPhysCat}: ${agg.category}'
                    '${protText(agg.category)}'),
                if (agg.unknown > 0)
                  Text(
                    '${loc.classificationUnknownCount}: ${agg.unknown}',
                    style: const TextStyle(color: Colors.deepOrange),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final e in items.entries)
          _sourceCard(context, loc, e.key, e.value, unit, hu, ctx),
      ],
    );
  }

  Widget _sourceCard(
      BuildContext context,
      AppLocalizations loc,
      RadiationSource s,
      SourceClassification c,
      ActivityUnit unit,
      bool hu,
      ClassificationContext ctx) {
    final lines = <String>[];
    if (c.activityMBq != null) {
      lines.add('${loc.classificationActivity}: '
          '${_fmt(unit.fromMBq(c.activityMBq!))} ${unit.symbol}'
          '${c.activityDecayCorrected ? '' : ' (${loc.classificationNotDecayCorrected})'}');
    }
    if (c.dInfinite) {
      lines.add(loc.classificationDInfinite);
    } else if (c.dTBq == null) {
      lines.add(loc.classificationDUnknown);
    } else {
      lines.add('D = ${_fmt(c.dTBq!)} TBq');
    }
    if (c.rValue != null && !c.dInfinite) {
      final pc = c.physicalCategory!;
      lines.add('R = ${_fmt(c.rValue!)} · ${loc.classificationPhysCat}: $pc'
          '${hu ? ' · ${loc.classificationProtCat}: ${_catName(protectionCategoryFor(pc, ctx))} · ${loc.classificationProtLevel}: ${physicalProtectionLevel(pc)}' : ''}');
    }
    final ex = c.exemption;
    if (ex == null) {
      lines.add(loc.classificationExemptUnknown);
    } else {
      lines.add('${hu ? 'MEA' : loc.classificationExemptActivity}: '
          '${_fmt(ex.exemptBq)} Bq');
      lines.add('${hu ? 'SMEAK' : loc.classificationSpecificConc}: '
          '${_fmt(ex.specificBqPerG)} Bq/g'
          '${ex.generalBqPerG != null ? ' · ${hu ? 'ÁMEAK' : loc.classificationGeneralConc}: ${_fmt(ex.generalBqPerG!)} Bq/g' : ''}');
      final below = c.belowExemptActivity;
      if (below != null) {
        lines.add(below
            ? loc.classificationBelowExempt
            : loc.classificationAboveExempt);
      }
    }
    final adr = c.adr;
    if (adr != null) {
      final r1 = adrRatioA1(c), r2 = adrRatioA2(c);
      lines.add('ADR: A1 = ${adr.a1TBq == null ? '∞' : _fmt(adr.a1TBq!)} TBq · '
          'A2 = ${adr.a2TBq == null ? '∞' : _fmt(adr.a2TBq!)} TBq'
          '${r1 != null ? ' · A/A1 = ${_fmt(r1)}' : ''}'
          '${r2 != null ? ' · A/A2 = ${_fmt(r2)}' : ''}');
      final below = adrBelowConsignmentLimit(c);
      lines.add('ADR: ${loc.classificationAdrConsignmentLimit} '
          '${_fmt(adr.exemptConsignmentBq)} Bq'
          '${below == null ? '' : below ? ' – ${loc.classificationAdrBelow}' : ' – ${loc.classificationAdrAbove}'}');
    }
    final lab = c.lab;
    if (hu && lab != null) {
      lines.add('MSZ 62-7: AM = ${_fmt(lab.amMBq)} MBq · A/AM = ${_fmt(lab.ratio)}');
      lines.add('${loc.classificationLabIndustrial}: ${lab.industrial} · '
          '${loc.classificationLabMedical}: '
          '${lab.medical ?? loc.classificationLabAboveIII}');
      lines.add('${loc.classificationLabOps}: '
          '${lab.allowedOperations.isEmpty ? '–' : lab.allowedOperations.join(', ')}');
    } else if (hu) {
      lines.add(loc.classificationLabUnknown);
    }
    final sel = !_excluded.contains(s.id);
    return Card(
      child: CheckboxListTile(
        value: sel,
        onChanged: (v) => setState(() {
          if (s.id == null) return;
          v == true ? _excluded.remove(s.id) : _excluded.add(s.id!);
        }),
        title: Text('${s.identifier} · ${c.nuclide}'),
        subtitle: Text(lines.join('\n')),
        isThreeLine: lines.length > 2,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
