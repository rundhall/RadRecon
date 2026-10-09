import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/survey_session.dart';
import 'instrument_list_screen.dart';
import 'measurement_list_screen.dart';
import 'person_list_screen.dart';
import 'radiation_source_list_screen.dart';
import 'settings_screen.dart';

/// Induló képernyő: meglévő felmérések listája, és új felmérés indítása.
class SurveySessionScreen extends StatefulWidget {
  const SurveySessionScreen({super.key});

  @override
  State<SurveySessionScreen> createState() => _SurveySessionScreenState();
}

class _SurveySessionScreenState extends State<SurveySessionScreen> {
  late Future<List<SurveySession>> _sessionsFuture;
  final _dateFormat = DateFormat('yyyy.MM.dd HH:mm');

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _sessionsFuture = DatabaseHelper.instance.getSurveySessions();
    });
  }

  Future<void> _createSession() async {
    final loc = AppLocalizations.of(context)!;
    final titleCtrl = TextEditingController(
      text: loc.surveyDefaultTitle(
        DateFormat('yyyy.MM.dd').format(DateTime.now()),
      ),
    );
    final locationCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.newSurveyDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(labelText: loc.surveyNameLabel),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationCtrl,
              decoration: InputDecoration(labelText: loc.surveyLocationLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.startButton),
          ),
        ],
      ),
    );

    if (confirmed != true || titleCtrl.text.trim().isEmpty) return;

    final session = SurveySession(
      title: titleCtrl.text.trim(),
      location:
          locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
      startedAt: DateTime.now(),
    );
    final id = await DatabaseHelper.instance.insertSurveySession(session);
    _reload();
    if (mounted) _openSession(id, session.title);
  }

  Future<void> _openSession(int id, String title) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            MeasurementListScreen(surveySessionId: id, surveyTitle: title),
      ),
    );
    // Session details (e.g. title) may have changed while on that screen.
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('RadRecon'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sensors),
            tooltip: loc.instrumentsTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InstrumentListScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sunny),
            tooltip: loc.sourcesTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RadiationSourceListScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: loc.personsTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PersonListScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: loc.alertThresholdsTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<SurveySession>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snapshot.data!;
          if (sessions.isEmpty) {
            return Center(child: Text(loc.noSurveysYet));
          }
          return ListView.separated(
            itemCount: sessions.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = sessions[index];
              return ListTile(
                leading: Icon(
                  s.isClosed ? Icons.check_circle_outline : Icons.radar,
                  color: s.isClosed ? Colors.grey : Colors.deepOrange,
                ),
                title: Text(s.title),
                subtitle: Text(
                  '${s.location ?? loc.noLocationPlaceholder} · '
                  '${_dateFormat.format(s.startedAt)}',
                ),
                onTap: () => _openSession(s.id!, s.title),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSession,
        icon: const Icon(Icons.add),
        label: Text(loc.newSurveyButton),
      ),
    );
  }
}