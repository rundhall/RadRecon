import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Update information for the current platform, read from version.json.
class AppUpdateInfo {
  final int currentBuild;
  final int latestBuild;
  final int minBuild;
  final String latestVersion;
  final Uri downloadUrl;
  final String? releaseNotes;

  const AppUpdateInfo({
    required this.currentBuild,
    required this.latestBuild,
    required this.minBuild,
    required this.latestVersion,
    required this.downloadUrl,
    this.releaseNotes,
  });

  /// Current build is below the minimum supported build: block the app.
  bool get isRequired => currentBuild < minBuild;

  /// A newer build exists.
  bool get isAvailable => currentBuild < latestBuild;

  static AppUpdateInfo? fromJson(
    Map<String, dynamic> json, {
    required int currentBuild,
  }) {
    final url = Uri.tryParse(json['download_url']?.toString() ?? '');
    if (url == null || url.scheme != 'https') return null;

    return AppUpdateInfo(
      currentBuild: currentBuild,
      latestBuild: (json['latest_build'] as num?)?.toInt() ?? 0,
      minBuild: (json['min_build'] as num?)?.toInt() ?? 0,
      latestVersion: json['latest_version']?.toString() ?? '',
      downloadUrl: url,
      releaseNotes: json['release_notes']?.toString(),
    );
  }
}

/// Checks https://radrecon.hu/version.json for a newer build.
///
/// Expected shape, keyed by platform (android, ios, macos, windows, linux):
/// { "windows": { "latest_build": 10, "min_build": 0,
///   "latest_version": "1.1.1", "download_url": "https://...",
///   "release_notes": "..." } }
///
/// Fetches at most once per 24 hours and caches the platform entry, so the
/// comparison against the running build happens on every launch without
/// network access. Any failure is silent: the app keeps working offline,
/// which matters for field measurements.
class AppUpdateService {
  AppUpdateService._();

  static final Uri versionUri = Uri.parse('https://radrecon.hu/version.json');

  static const _lastFetchKey = 'app_update_last_fetch_ms';
  static const _cacheKey = 'app_update_cache';
  static const _snoozeUntilKey = 'app_update_snooze_until_ms';

  static const _fetchInterval = Duration(hours: 24);
  static const _snoozeDuration = Duration(days: 7);

  static String? get _platformKey {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return null;
  }

  /// Returns the update to show, or null if nothing should be shown now.
  static Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final platform = _platformKey;
      if (platform == null) return null;

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastFetch = prefs.getInt(_lastFetchKey) ?? 0;

      if (now - lastFetch >= _fetchInterval.inMilliseconds) {
        final remote = await _fetchVersionFile();
        final entry = remote?[platform];
        if (entry is Map<String, dynamic>) {
          await prefs.setString(_cacheKey, jsonEncode(entry));
          await prefs.setInt(_lastFetchKey, now);
        }
      }

      final cached = prefs.getString(_cacheKey);
      if (cached == null) return null;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      final info = AppUpdateInfo.fromJson(
        jsonDecode(cached) as Map<String, dynamic>,
        currentBuild: currentBuild,
      );
      if (info == null) return null;

      // A required update ignores the "later" snooze.
      if (info.isRequired) return info;
      if (!info.isAvailable) return null;

      final snoozeUntil = prefs.getInt(_snoozeUntilKey) ?? 0;
      if (now < snoozeUntil) return null;

      return info;
    } catch (e) {
      debugPrint('App update check failed: $e');
      return null;
    }
  }

  /// Hides optional update prompts for a week.
  static Future<void> snooze() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _snoozeUntilKey,
      DateTime.now().add(_snoozeDuration).millisecondsSinceEpoch,
    );
  }

  static Future<Map<String, dynamic>?> _fetchVersionFile() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client
          .getUrl(versionUri)
          .timeout(const Duration(seconds: 5));
      final response =
          await request.close().timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 5));
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      debugPrint('Version file fetch failed: $e');
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
