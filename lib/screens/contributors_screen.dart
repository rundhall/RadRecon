import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/contributors.dart';

/// Köszönet a közreműködőknek. Az adatforrás a weboldallal közös
/// `landingpage/contributors.json`, ami az appba asset-ként van csomagolva,
/// ezért a lista offline is látszik, és kiadásonként frissül.
class ContributorsScreen extends StatefulWidget {
  const ContributorsScreen({super.key});

  static const assetPath = 'landingpage/contributors.json';
  static const volunteerFormUrl = 'https://forms.gle/7EgHLe6yQr8pV5Qt9';

  @override
  State<ContributorsScreen> createState() => _ContributorsScreenState();
}

class _ContributorsScreenState extends State<ContributorsScreen> {
  late final Future<ContributorList> _future = _load();

  Future<ContributorList> _load() async {
    final raw = await rootBundle.loadString(ContributorsScreen.assetPath);
    return ContributorList.fromJson(jsonDecode(raw));
  }

  String _roleLabel(AppLocalizations loc, String role) {
    switch (role) {
      case 'testing':
        return loc.contributorRoleTesting;
      case 'development':
        return loc.contributorRoleDevelopment;
      case 'review':
        return loc.contributorRoleReview;
      case 'translation':
        return loc.contributorRoleTranslation;
      case 'other':
        return loc.contributorRoleOther;
      default:
        return role;
    }
  }

  Widget _tile(AppLocalizations loc, Contributor c, IconData icon) {
    final parts = <String>[
      if (c.organization != null) c.organization!,
      ...c.roles.map((r) => _roleLabel(loc, r)),
    ];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(c.name),
      subtitle: parts.isEmpty ? null : Text(parts.join(' \u00b7 ')),
    );
  }

  Future<void> _copyLink() async {
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
      const ClipboardData(text: ContributorsScreen.volunteerFormUrl),
    );
    messenger.showSnackBar(SnackBar(content: Text(loc.contributorsLinkCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.contributorsTitle)),
      body: FutureBuilder<ContributorList>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(loc.contributorsThanks),
              const SizedBox(height: 16),
              if (snapshot.hasError)
                Text(loc.contributorsLoadError)
              else if (data == null)
                const Center(child: CircularProgressIndicator())
              else if (data.isEmpty)
                Text(loc.contributorsEmpty)
              else ...[
                if (data.organizations.isNotEmpty) ...[
                  Text(
                    loc.contributorsOrganizationsTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  for (final c in data.organizations)
                    _tile(loc, c, Icons.business),
                  const SizedBox(height: 16),
                ],
                if (data.people.isNotEmpty) ...[
                  Text(
                    loc.contributorsPeopleTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  for (final c in data.people) _tile(loc, c, Icons.person),
                ],
              ],
              const Divider(height: 32),
              Text(loc.contributorsJoinHint),
              const SizedBox(height: 8),
              const SelectableText(ContributorsScreen.volunteerFormUrl),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _copyLink,
                  icon: const Icon(Icons.copy),
                  label: Text(loc.contributorsCopyLink),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
