import 'package:flutter/material.dart';
import 'screens/uebersicht_seite.dart';
import 'screens/spieler_seite.dart';
import 'services/update_service.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KniffelApp());
}

class KniffelApp extends StatelessWidget {
  const KniffelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kniffel',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const HauptSeite(),
    );
  }
}

class HauptSeite extends StatefulWidget {
  const HauptSeite({super.key});

  @override
  State<HauptSeite> createState() => _HauptSeiteState();
}

class _HauptSeiteState extends State<HauptSeite> {
  int _tabIndex = 0;
  UpdateInfo? _updateInfo;

  final List<Widget> _seiten = const [
    UebersichtSeite(),
    SpielerSeite(),
  ];

  @override
  void initState() {
    super.initState();
    _updatePruefen();
  }

  Future<void> _updatePruefen() async {
    debugPrint('Update-Check gestartet...');
    final info = await UpdateService.pruefeAufUpdate();
    debugPrint('UpdateInfo: ${info?.version ?? "null"}');
    if (info != null && mounted) {
      setState(() => _updateInfo = info);
      // Dialog nur zeigen wenn nicht ignoriert
      if (!info.ignoriert) {
        _zeigeUpdateDialog(info);
      }
    }
  }

  void _zeigeUpdateDialog(UpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🎲 Update verfügbar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version ${info.version} ist verfügbar.'),
            if (info.hinweis.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(info.hinweis,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await UpdateService.versionsIgnorieren(info.version);
              setState(() => _updateInfo = info);
              Navigator.pop(context);
            },
            child: const Text('Ignorieren'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final uri = Uri.parse(info.url);
                await launchUrl(uri,
                    mode: LaunchMode.externalApplication);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Download-Link konnte nicht geöffnet werden: $e')),
                );
              }
            },
            icon: const Icon(Icons.system_update),
            label: const Text('Installieren'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _updateInfo != null
          ? AppBar(
        title: const Text('🎲 Kniffel'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _zeigeUpdateDialog(_updateInfo!),
              icon: const Icon(Icons.system_update,
                  color: Colors.orange, size: 18),
              label: const Text('Update',
                  style: TextStyle(
                      color: Colors.orange, fontSize: 12)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange.shade50,
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
              ),
            ),
          ),
        ],
      )
          : null,
      body: _seiten[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.casino_outlined),
            selectedIcon: Icon(Icons.casino),
            label: 'Spiele',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistiken',
          ),
        ],
      ),
    );
  }
}