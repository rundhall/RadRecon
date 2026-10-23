import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/app_update_service.dart';

/// Shows the update prompt. Optional updates can be postponed;
/// required updates cannot be dismissed.
Future<void> showAppUpdateDialog(BuildContext context, AppUpdateInfo info) {
  final t = AppLocalizations.of(context)!;
  final notes = info.releaseNotes?.trim();

  return showDialog<void>(
    context: context,
    barrierDismissible: !info.isRequired,
    builder: (dialogContext) => PopScope(
      canPop: !info.isRequired,
      child: AlertDialog(
        title: Text(t.appUpdateTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info.isRequired
                  ? t.appUpdateRequiredMessage(info.latestVersion)
                  : t.appUpdateAvailableMessage(info.latestVersion),
            ),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(notes),
            ],
          ],
        ),
        actions: [
          if (!info.isRequired)
            TextButton(
              onPressed: () {
                AppUpdateService.snooze();
                Navigator.of(dialogContext).pop();
              },
              child: Text(t.appUpdateLater),
            ),
          FilledButton(
            onPressed: () async {
              await launchUrl(
                info.downloadUrl,
                mode: LaunchMode.externalApplication,
              );
              if (!info.isRequired && dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: Text(t.appUpdateNow),
          ),
        ],
      ),
    ),
  );
}
