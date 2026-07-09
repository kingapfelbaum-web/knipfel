import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/spieler_profil.dart';
import '../models/spiel.dart';
import 'statistik_seite.dart';
import 'spielblock_seite.dart';
import 'dart:convert';
import 'dart:io';

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
  String _spielerSuche = '';
  String _spieleSuche = '';

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
              hintText: 'Neuer Name',
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

  // ── Export / Import ─────────────────────────────────────
  Future<void> _exportieren() async {
    try {
      final data = jsonEncode({
        'spieler': profile.map((p) => p.toJson()).toList(),
        'spiele': spiele.map((s) => s.toJson()).toList(),
      });
      final dir = await getApplicationDocumentsDirectory();
      final dateiname =
          'kniffel_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${dir.path}/$dateiname');
      await file.writeAsString(data);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Kniffel Export',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Export: $e')),
      );
    }
  }

  Future<void> _importieren() async {
    try {
      final dir = await getApplicationDocumentsDirectory();

      // Alle JSON-Dateien im Ordner finden
      final dateien = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => b.lastModifiedSync()
            .compareTo(a.lastModifiedSync())); // neueste zuerst

      if (!mounted) return;

      if (dateien.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Keine JSON-Dateien gefunden. Bitte Export-Datei in den Dokumenten-Ordner legen.')),
        );
        return;
      }

      // Datei auswählen
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Datei auswählen'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: dateien.length,
              itemBuilder: (context, index) {
                final datei = dateien[index];
                final name = datei.path.split('/').last;
                return ListTile(
                  leading: const Icon(Icons.file_present),
                  title: Text(name, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    datei.lastModifiedSync().toString().substring(0, 16),
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _importiereDatei(datei);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }

  Future<void> _importiereDatei(File datei) async {
    try {
      final inhalt = await datei.readAsString();
      final data = jsonDecode(inhalt);

      final neueProfile = (data['spieler'] as List)
          .map((e) => SpielerProfil.fromJson(e))
          .toList();
      final neueSpiele =
      (data['spiele'] as List).map((e) => Spiel.fromJson(e)).toList();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Import'),
          content: Text(
              '${neueProfile.length} Spieler und ${neueSpiele.length} Spiele gefunden.\n\nWie soll importiert werden?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen')),
            OutlinedButton(
              onPressed: () async {
                for (final p in neueProfile) {
                  if (!profile.any((e) => e.id == p.id)) profile.add(p);
                }
                for (final s in neueSpiele) {
                  if (!spiele.any((e) => e.id == s.id)) spiele.add(s);
                }
                await alleProfileSpeichern(profile);
                await alleSpieleSpeichern(spiele);
                setState(() {});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erfolgreich zusammengeführt')),
                );
              },
              child: const Text('Zusammenführen'),
            ),
            ElevatedButton(
              onPressed: () async {
                profile
                  ..clear()
                  ..addAll(neueProfile);
                spiele
                  ..clear()
                  ..addAll(neueSpiele);
                await alleProfileSpeichern(profile);
                await alleSpieleSpeichern(spiele);
                setState(() {});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erfolgreich importiert')),
                );
              },
              child: const Text('Überschreiben'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Import: $e')),
      );
    }
  }

  // ── UI ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Statistiken'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Exportieren',
            onPressed: _exportieren,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Importieren',
            onPressed: _importieren,
          ),
        ],
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
    final gefiltert = profile
        .where((p) =>
        p.name.toLowerCase().contains(_spielerSuche.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Spieler suchen...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (val) => setState(() => _spielerSuche = val),
          ),
        ),
        Expanded(
          child: gefiltert.isEmpty
              ? const Center(child: Text('Keine Spieler gefunden.'))
              : ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: gefiltert.length,
            itemBuilder: (context, index) {
              final p = gefiltert[index];
              final siege = _siege(p);
              final spielAnzahl = _anzahlSpiele(p);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade200,
                  child: Text(p.name[0].toUpperCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                ),
                title: Text(p.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
                subtitle:
                Text('$spielAnzahl Spiele · $siege Siege'),
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
          ),
        ),
      ],
    );
  }

  Widget _spieleListe() {
    final beendeteSpiele = spiele.where((s) => s.beendet).toList();
    final gefiltert = beendeteSpiele
        .where((s) =>
    s.name.toLowerCase().contains(_spieleSuche.toLowerCase()) ||
        s.spieler.any((sp) => sp.name
            .toLowerCase()
            .contains(_spieleSuche.toLowerCase())))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Spiel oder Spieler suchen...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (val) => setState(() => _spieleSuche = val),
          ),
        ),
        Expanded(
          child: gefiltert.isEmpty
              ? const Center(
              child: Text('Keine abgeschlossenen Spiele gefunden.'))
              : GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: gefiltert.length,
            itemBuilder: (context, index) {
              final spiel = gefiltert[index];
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
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          '${spiel.erstelltAm.day}.${spiel.erstelltAm.month}.${spiel.erstelltAm.year}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                        const Divider(height: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              ...spiel.rangliste
                                  .take(4)
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map((e) => Text(
                                '${e.key == 0 ? "🥇" : e.key == 1 ? "🥈" : e.key == 2 ? "🥉" : "🏅"} ${e.value.name}: ${e.value.gesamt}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: e.key == 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                overflow:
                                TextOverflow.ellipsis,
                              )),
                              if (spiel.rangliste.length > 4)
                                Text(
                                  '+ ${spiel.rangliste.length - 4} weitere',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}