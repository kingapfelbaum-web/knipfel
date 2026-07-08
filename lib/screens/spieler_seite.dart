import 'package:flutter/material.dart';
import '../models/spieler_profil.dart';
import '../models/spiel.dart';
import 'statistik_seite.dart';
import 'spielblock_seite.dart';
import 'dart:math';

class SpielerSeite extends StatefulWidget {
  const SpielerSeite({super.key});

  @override
  State<SpielerSeite> createState() => _SpielerSeiteState();
}

class _SpielerSeiteState extends State<SpielerSeite>
    with SingleTickerProviderStateMixin {
  List<SpielerProfil> profile = [];
  List<Spiel> spiele = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _laden();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _laden() async {
    final p = await alleProfileLaden();
    final s = await alleSpieleLaden();
    setState(() {
      profile = p;
      spiele = s;
    });
  }

  // ── Spieler-Hilfsfunktionen ─────────────────────────────
  int _anzahlSpiele(SpielerProfil profil) => spiele
      .where((s) =>
  s.beendet && s.spieler.any((sp) => sp.profilId == profil.id))
      .length;

  int _siege(SpielerProfil profil) => spiele
      .where((s) =>
  s.beendet &&
      s.rangliste.isNotEmpty &&
      s.rangliste.first.profilId == profil.id)
      .length;

  void _profilHinzufuegen() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Neuer Spieler'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 12,
            decoration: InputDecoration(
              hintText: 'Name',
              counterText: '',
              errorText: controller.text.length == 12
                  ? 'Maximale Länge erreicht'
                  : null,
            ),
            onChanged: (_) => setDialogState(() {}),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen')),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  final neuesProfil = SpielerProfil(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: controller.text.trim(),
                  );
                  profile.add(neuesProfil);
                  await alleProfileSpeichern(profile);
                  setState(() {});
                  Navigator.pop(context);
                }
              },
              child: const Text('Hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }

  void _profilUmbenennen(SpielerProfil profil) {
    final controller = TextEditingController(text: profil.name);
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Spieler umbenennen'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 12,
            decoration: InputDecoration(
              hintText: 'Name',
              counterText: '',
              errorText: controller.text.length == 12
                  ? 'Maximale Länge erreicht'
                  : null,
            ),
            onChanged: (_) => setDialogState(() {}), // StatefulBuilder nötig – siehe unten
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen')),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  profil.name = controller.text.trim();
                  await alleProfileSpeichern(profile);
                  setState(() {});
                  Navigator.pop(context);
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  void _profilLoeschen(SpielerProfil profil) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Spieler löschen?'),
        content: Text(
            '„${profil.name}" wird gelöscht. Alte Spiele bleiben erhalten.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () async {
              profile.remove(profil);
              await alleProfileSpeichern(profile);
              setState(() {});
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
            const Text('Löschen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Spiele-Hilfsfunktionen ──────────────────────────────
  void _spielOeffnen(Spiel spiel) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SpielblockSeite(
          spiel: spiel,
          onChanged: () async {
            if (spiel.spieler.isNotEmpty &&
                spiel.spieler.every((s) => s.istFertig)) {
              spiel.beendet = true;
            }
            await alleSpieleSpeichern(spiele);
            setState(() {});
          },
        ),
      ),
    );
    await _laden();
  }

  void _spielLoeschen(Spiel spiel) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Spiel löschen?'),
        content: Text('„${spiel.name}" wird dauerhaft gelöscht.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () async {
              spiele.remove(spiel);
              await alleSpieleSpeichern(spiele);
              setState(() {});
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
            const Text('Löschen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── UI ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Statistiken'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Spieler'),
            Tab(icon: Icon(Icons.history), text: 'Alte Spiele'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _spielerListe(),
          _spieleListe(),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) => _tabController.index == 0
            ? FloatingActionButton.extended(
          onPressed: _profilHinzufuegen,
          icon: const Icon(Icons.person_add),
          label: const Text('Spieler'),
        )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _spielerListe() {
    if (profile.isEmpty) {
      return const Center(child: Text('Noch keine Spieler angelegt.'));
    }
    return ListView.builder(
      itemCount: profile.length,
      itemBuilder: (context, index) {
        final p = profile[index];
        final siege = _siege(p);
        final spielAnzahl = _anzahlSpiele(p);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green.shade200,
            child: Text(p.name[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          title: Text(p.name,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('$spielAnzahl Spiele · $siege Siege'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.bar_chart),
                tooltip: 'Statistik',
                onPressed: spielAnzahl == 0
                    ? null
                    : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StatistikSeite(
                      profil: p,
                      spiele: spiele,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Umbenennen',
                onPressed: () => _profilUmbenennen(p),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Löschen',
                onPressed: () => _profilLoeschen(p),
              ),
            ],
          ),
        );
      },
      // Ganz am Ende der ListView in beiden Methoden:
      padding: const EdgeInsets.only(bottom: 80),
    );
  }

  Widget _spieleListe() {
    final beendeteSpiele = spiele.where((s) => s.beendet).toList();
    if (beendeteSpiele.isEmpty) {
      return const Center(child: Text('Noch keine abgeschlossenen Spiele.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: beendeteSpiele.length,
      itemBuilder: (context, index) {
        final spiel = beendeteSpiele[index];
        return GestureDetector(
          onTap: () => _spielOeffnen(spiel),
          onLongPress: () => _spielLoeschen(spiel),
          child: Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('✅ Beendet',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade800)),
                  ),
                  const SizedBox(height: 8),
                  Text(spiel.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    '${spiel.erstelltAm.day}.${spiel.erstelltAm.month}.${spiel.erstelltAm.year}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                  ),
                  const Divider(height: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: spiel.rangliste.take(4).toList()
                          .asMap()
                          .entries
                          .map((e) => Text(
                        '${e.key == 0 ? "🥇" : e.key == 1 ? "🥈" : e.key == 2 ? "🥉" : "🥴"} ${e.value.name}: ${e.value.gesamt}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: e.key == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ))
                          .toList(),
                    ),
                  ),
                  if (spiel.rangliste.length > 4)
                    Text(
                      '+ ${spiel.rangliste.length - 4} weitere',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}