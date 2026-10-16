import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/calibration_labels.dart';
import '../models/company_document.dart';
import '../models/instrument_calibration.dart';
import 'company_document_entry_screen.dart';

/// A cég dokumentumai és engedélyei — lejárat szerint rendezve, a lejárt
/// és hamarosan lejáró tételek jelölésével.
class CompanyDocumentListScreen extends StatefulWidget {
  const CompanyDocumentListScreen({super.key});

  @override
  State<CompanyDocumentListScreen> createState() =>
      _CompanyDocumentListScreenState();
}

class _CompanyDocumentListScreenState extends State<CompanyDocumentListScreen> {
  late Future<List<CompanyDocument>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = DatabaseHelper.instance.getCompanyDocuments();
    });
  }

  Future<void> _open({CompanyDocument? existing}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CompanyDocumentEntryScreen(existing: existing),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _delete(CompanyDocument d) async {
    final loc = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.companyDocumentDeleteTitle),
        content: Text(loc.companyDocumentDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.deleteButton),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseHelper.instance.deleteCompanyDocument(d.id!);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.companyDocumentsTooltip)),
      floatingActionButton: FloatingActionButton(
        tooltip: loc.companyDocumentNew,
        onPressed: () => _open(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<CompanyDocument>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!;
          if (docs.isEmpty) {
            return Center(child: Text(loc.companyDocumentsEmpty));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i];
              final st = calibrationStatusFor(d.validUntil);
              final color = switch (st) {
                CalibrationStatus.expired => Colors.red,
                CalibrationStatus.expiringSoon => Colors.orange,
                _ => null,
              };
              return ListTile(
                leading: Icon(
                  st == CalibrationStatus.expired
                      ? Icons.warning_amber
                      : Icons.description_outlined,
                  color: color,
                ),
                title: Text(d.title),
                subtitle: Text([
                  if (d.identifier != null) d.identifier!,
                  if (d.validUntil != null)
                    '${loc.companyDocumentValidUntilLabel}: '
                        '${calibrationDateText(d.validUntil!)}',
                  if (color != null) calibrationStatusLabel(loc, st),
                ].join(' · ')),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(d),
                ),
                onTap: () => _open(existing: d),
              );
            },
          );
        },
      ),
    );
  }
}
