import 'package:flutter/material.dart';
import '../models/spieler_profil.dart';
import '../models/spiel.dart';
import 'statistik_seite.dart';
import 'spielblock_seite.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

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
    Set<String> ausgewaehlteProfile = {};
    Set<String> ausgewaehlteSpiele = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Export',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Spieler auswählen
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Spieler:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  TextButton(
                    onPressed: () => setDialogState(() {
                      if (ausgewaehlteProfile.length == profile.length) {
                        ausgewaehlteProfile.clear();
                      } else {
                        ausgewaehlteProfile =
                            profile.map((p) => p.id).toSet();
                      }
                    }),
                    child: Text(
                        ausgewaehlteProfile.length == profile.length
                            ? 'Alle abwählen'
                            : 'Alle auswählen'),
                  ),
                ],
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: profile
                          .map((p) => CheckboxListTile(
                        dense: true,
                        value: ausgewaehlteProfile.contains(p.id),
                        onChanged: (val) => setDialogState(() {
                          if (val == true) {
                            ausgewaehlteProfile.add(p.id);
                          } else {
                            ausgewaehlteProfile.remove(p.id);
                          }
                        }),
                        secondary: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.green.shade100,
                          child: Text(p.name[0].toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                        title: Text(p.name),
                      ))
                          .toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Spiele auswählen
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Alte Spiele:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  TextButton(
                    onPressed: () => setDialogState(() {
                      final beendete =
                      spiele.where((s) => s.beendet).toList();
                      if (ausgewaehlteSpiele.length == beendete.length) {
                        ausgewaehlteSpiele.clear();
                      } else {
                        ausgewaehlteSpiele =
                            beendete.map((s) => s.id).toSet();
                      }
                    }),
                    child: Text(
                        ausgewaehlteSpiele.length ==
                            spiele.where((s) => s.beendet).length
                            ? 'Alle abwählen'
                            : 'Alle auswählen'),
                  ),
                ],
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: spiele
                          .where((s) => s.beendet)
                          .map((s) => CheckboxListTile(
                        dense: true,
                        value: ausgewaehlteSpiele.contains(s.id),
                        onChanged: (val) => setDialogState(() {
                          if (val == true) {
                            ausgewaehlteSpiele.add(s.id);
                          } else {
                            ausgewaehlteSpiele.remove(s.id);
                          }
                        }),
                        title: Text(s.name,
                            style: const TextStyle(fontSize: 13)),
                        subtitle: Text(
                          '${s.erstelltAm.day}.${s.erstelltAm.month}.${s.erstelltAm.year} · ${s.rangliste.isNotEmpty ? "🥇 ${s.rangliste.first.name}" : ""}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ))
                          .toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Export-Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${ausgewaehlteProfile.length} Spieler, ${ausgewaehlteSpiele.length} Spiele',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: (ausgewaehlteProfile.isEmpty &&
                        ausgewaehlteSpiele.isEmpty)
                        ? null
                        : () async {
                      Navigator.pop(context);
                      await _exportiereAuswahl(
                        ausgewaehlteProfile,
                        ausgewaehlteSpiele,
                      );
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Exportieren'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportiereAuswahl(
      Set<String> profilIds,
      Set<String> spielIds,
      ) async {
    try {
      final ausgewaehlteSpiele =
      spiele.where((s) => spielIds.contains(s.id)).toList();

      // Spieler aus ausgewählten Spielen automatisch hinzufügen
      final alleProfilIds = {...profilIds};
      for (final spiel in ausgewaehlteSpiele) {
        for (final spieler in spiel.spieler) {
          if (spieler.profilId != null) {
            alleProfilIds.add(spieler.profilId!);
          }
        }
      }

      final ausgewaehlteProfile =
      profile.where((p) => alleProfilIds.contains(p.id)).toList();

      final data = jsonEncode({
        'spieler': ausgewaehlteProfile.map((p) => p.toJson()).toList(),
        'spiele': ausgewaehlteSpiele.map((s) => s.toJson()).toList(),
      });

      await Clipboard.setData(ClipboardData(text: data));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${ausgewaehlteProfile.length} Spieler und '
                '${ausgewaehlteSpiele.length} Spiele in Zwischenablage kopiert',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Export: $e')),
      );
    }
  }

  Future<void> _importieren() async {
    final controller = TextEditingController();

    // Zwischenablage prüfen ob gültiger Kniffel-Export
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    bool istGueltig = false;
    if (clip?.text != null) {
      try {
        final data = jsonDecode(clip!.text!);
        istGueltig = data is Map &&
            data.containsKey('spieler') &&
            data.containsKey('spiele');
      } catch (_) {
        istGueltig = false;
      }
      if (istGueltig) controller.text = clip!.text!;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Import',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Hinweis ob gültiger Export erkannt
              if (istGueltig)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Text('Gültiger Kniffel-Export erkannt',
                          style: TextStyle(color: Colors.green)),
                    ],
                  ),
                )
              else if (clip?.text != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber,
                          color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Zwischenablage enthält keinen gültigen Export',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.grey, size: 18),
                      SizedBox(width: 8),
                      Text('Zwischenablage ist leer',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),

              const SizedBox(height: 12),
              const Text(
                'Exportierten Text hier einfügen:',
                style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Hier einfügen...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste),
                    tooltip: 'Aus Zwischenablage einfügen',
                    onPressed: () async {
                      final clip =
                      await Clipboard.getData(Clipboard.kTextPlain);
                      if (clip?.text != null) {
                        setDialogState(() {
                          controller.text = clip!.text!;
                          // Gültigkeit neu prüfen
                          try {
                            final data = jsonDecode(clip.text!);
                            istGueltig = data is Map &&
                                data.containsKey('spieler') &&
                                data.containsKey('spiele');
                          } catch (_) {
                            istGueltig = false;
                          }
                        });
                      }
                    },
                  ),
                ),
                onChanged: (_) => setDialogState(() {
                  // Gültigkeit bei manueller Eingabe prüfen
                  try {
                    final data = jsonDecode(controller.text);
                    istGueltig = data is Map &&
                        data.containsKey('spieler') &&
                        data.containsKey('spiele');
                  } catch (_) {
                    istGueltig = false;
                  }
                }),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: controller.text.trim().isEmpty || !istGueltig
                        ? null
                        : () {
                      Navigator.pop(context);
                      _verarbeiteImport(controller.text.trim());
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Importieren'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verarbeiteImport(String text) async {
    try {
      final data = jsonDecode(text);
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
                  const SnackBar(
                      content: Text('Erfolgreich zusammengeführt')),
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
        const SnackBar(
            content: Text(
                'Fehler: Kein gültiger Kniffel-Export')),
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