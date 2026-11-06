import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

import '../utils/constants.dart';

class UpdateException implements Exception {
  UpdateException(this.message);
  final String message;
  @override
  String toString() => message;
}

class UpdateInfo {
  UpdateInfo({
    required this.version,
    required this.notes,
    required this.apkUrl,
  });
  final String version;
  final String notes;
  final String apkUrl;
}

/// Looks at the newest GitHub Release and says whether it is newer
/// than the installed app.
class UpdateService {
  String installedVersion = '';

  Future<String> currentVersion() async {
    if (installedVersion.isEmpty) {
      installedVersion = (await PackageInfo.fromPlatform()).version;
    }
    return installedVersion;
  }

  /// Returns null when the app is already up to date.
  Future<UpdateInfo?> checkForUpdate() async {
    final current = await currentVersion();
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(
        Uri.parse('https://api.github.com/repos/$githubRepo/releases/latest'),
      );
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );
      request.headers.set(HttpHeaders.userAgentHeader, 'taskly-app');
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );

      if (response.statusCode == 404) {
        throw UpdateException(
          'No published release was found. Make sure the GitHub repo is public and has a release.',
        );
      }
      if (response.statusCode != 200) {
        throw UpdateException(
          'GitHub answered with code ${response.statusCode}. Please try again later.',
        );
      }

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final latest = (json['tag_name'] as String).replaceFirst(
        RegExp(r'^[vV]'),
        '',
      );
      if (!_isNewer(latest, current)) return null;

      final assets = (json['assets'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final apk = assets.where((a) => (a['name'] as String).endsWith('.apk'));
      if (apk.isEmpty) {
        throw UpdateException(
          'The newest release has no APK file attached yet.',
        );
      }

      return UpdateInfo(
        version: latest,
        notes: ((json['body'] as String?) ?? '').trim(),
        apkUrl: apk.first['browser_download_url'] as String,
      );
    } finally {
      client.close();
    }
  }

  bool _isNewer(String latest, String current) {
    List<int> parse(String v) => v
        .split('+')
        .first
        .split('.')
        .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final a = parse(latest);
    final b = parse(current);
    for (var i = 0; i < 3; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }
}

final UpdateService updates = UpdateService();
