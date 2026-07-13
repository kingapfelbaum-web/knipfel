import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String version;
  final String url;
  final String hinweis;

  UpdateInfo({
    required this.version,
    required this.url,
    required this.hinweis,
  });
}

class UpdateService {
  // ← Dein GitHub-Benutzername und Repository-Name:
  static const String _githubUser = 'kingapfelbaum-web';
  static const String _githubRepo = 'knipfel';

  static Future<UpdateInfo?> pruefeAufUpdate() async {
    try {
      final response = await http
          .get(
        Uri.parse(
            'https://api.github.com/repos/$_githubUser/$_githubRepo/releases/latest'),
        headers: {'Accept': 'application/vnd.github+json'},
      )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);

      // Version aus Tag-Name lesen (z.B. "v1.0.1" → "1.0.1")
      final neueVersion =
      (data['tag_name'] as String).replaceFirst('v', '');
      final hinweis = data['body'] as String? ?? '';

      // APK-Asset-URL finden
      final assets = data['assets'] as List;
      final apkAsset = assets.firstWhere(
            (a) => (a['name'] as String).endsWith('.apk'),
        orElse: () => null,
      );
      if (apkAsset == null) return null;
      final apkUrl = apkAsset['browser_download_url'] as String;

      // Mit installierter Version vergleichen
      final info = await PackageInfo.fromPlatform();
      final aktuelleVersion = info.version;

      if (_istNeuer(neueVersion, aktuelleVersion)) {
        return UpdateInfo(
          version: neueVersion,
          url: apkUrl,
          hinweis: hinweis,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static bool _istNeuer(String neu, String aktuell) {
    final n = neu.split('.').map(int.parse).toList();
    final a = aktuell.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      final ni = i < n.length ? n[i] : 0;
      final ai = i < a.length ? a[i] : 0;
      if (ni > ai) return true;
      if (ni < ai) return false;
    }
    return false;
  }
}