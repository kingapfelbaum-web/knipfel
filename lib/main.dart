import 'package:flutter/material.dart';
import 'screens/uebersicht_seite.dart';
import 'screens/spieler_seite.dart';

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

  final List<Widget> _seiten = const [
    UebersichtSeite(),
    SpielerSeite(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Statistiken',
          ),
        ],
      ),
    );
  }
}