import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/spieler_profil.dart';
import '../models/spiel.dart';

class ExportSeite extends StatefulWidget {
  final List<SpielerProfil> profile;
  final List<Spiel> spiele;

  const ExportSeite({
    super.key,
    required this.profile,
    required this.spiele,
  });

  @override
  State<ExportSeite> createState() => _ExportSeiteState();
}

class _ExportSeiteState extends State<ExportSeite> {
  Set<String> ausgewaehlteProfile = {};
  Set<String> ausgewaehlteSpiele = {};
  final suchSpielerController = TextEditingController();
  final suchSpielController = TextEditingController();

  @override
  void dispose() {
    suchSpielerController.dispose();
    suchSpielController.dispose();
    super.dispose();
  }

  Future<void> _exportiereAuswahl() async {
    try {
      final ausgewaehlteSpieleListe = widget.spiele
          .where((s) => ausgewaehlteSpiele.contains(s.id))
          .toList();

      final alleProfilIds = {...ausgewaehlteProfile};
      for (final spiel in ausgewaehlteSpieleListe) {
        for (final spieler in spiel.spieler) {
          if (spieler.profilId != null) {
            alleProfilIds.add(spieler.profilId!);
          }
        }
      }

      final ausgewaehlteProfileListe = widget.profile
          .where((p) => alleProfilIds.contains(p.id))
          .toList();

      final data = jsonEncode({
        'spieler': ausgewaehlteProfileListe.map((p) => p.toJson()).toList(),
        'spiele': ausgewaehlteSpieleListe.map((s) => s.toJson()).toList(),
      });

      await Clipboard.setData(ClipboardData(text: data));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${ausgewaehlteProfileListe.length} Spieler und '
                '${ausgewaehlteSpieleListe.length} Spiele kopiert',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Export: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gefilterteSpiele = widget.spiele
        .where((s) =>
    s.beendet &&
        (suchSpielController.text.trim().isEmpty ||
            s.name.toLowerCase().contains(
                suchSpielController.text.trim().toLowerCase()) ||
            s.spieler.any((sp) => sp.name.toLowerCase().contains(
                suchSpielController.text.trim().toLowerCase()))))
        .toList();

    final gefilterteProfile = widget.profile
        .where((p) =>
    suchSpielerController.text.trim().isEmpty ||
        p.name.toLowerCase().contains(
            suchSpielerController.text.trim().toLowerCase()))
        .toList();

    final exportierbar = ausgewaehlteProfile.isNotEmpty ||
        ausgewaehlteSpiele.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📤 Export'),
        notificationPredicate: (notification) => false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: exportierbar ? _exportiereAuswahl : null,
              icon: const Icon(Icons.copy, size: 16),
              label: Text(
                'Kopieren (${ausgewaehlteProfile.length + ausgewaehlteSpiele.length})',
                style: const TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: exportierbar
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary,
                foregroundColor:
                exportierbar ? Theme.of(context).colorScheme.onPrimary : Colors.grey.shade500,
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Obere Hälfte: Spiele ──────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Alte Spiele',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton(
                        onPressed: () => setState(() {
                          final beendete = widget.spiele
                              .where((s) => s.beendet)
                              .toList();
                          if (ausgewaehlteSpiele.length ==
                              beendete.length) {
                            ausgewaehlteSpiele.clear();
                          } else {
                            ausgewaehlteSpiele =
                                beendete.map((s) => s.id).toSet();
                          }
                        }),
                        child: Text(
                          ausgewaehlteSpiele.length ==
                              widget.spiele
                                  .where((s) => s.beendet)
                                  .length
                              ? 'Alle abwählen'
                              : 'Alle auswählen',
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: suchSpielController,
                    decoration: const InputDecoration(
                      hintText: 'Spiel oder Spieler suchen...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: gefilterteSpiele.isEmpty
                      ? const Center(
                      child: Text('Keine Spiele gefunden',
                          style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: gefilterteSpiele.length,
                    itemBuilder: (context, index) {
                      final s = gefilterteSpiele[index];
                      return CheckboxListTile(
                        dense: true,
                        value: ausgewaehlteSpiele.contains(s.id),
                        onChanged: (val) => setState(() {
                          if (val == true) {
                            ausgewaehlteSpiele.add(s.id);
                          } else {
                            ausgewaehlteSpiele.remove(s.id);
                          }
                        }),
                        title: Text(s.name,
                            style: const TextStyle(fontSize: 13)),
                        subtitle: Text(
                          '${s.erstelltAm.day}.${s.erstelltAm.month}.${s.erstelltAm.year}'
                              '${s.rangliste.isNotEmpty ? " · 🥇 ${s.rangliste.first.name}" : ""}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Untere Hälfte: Spieler ────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Spieler',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton(
                        onPressed: () => setState(() {
                          if (ausgewaehlteProfile.length ==
                              widget.profile.length) {
                            ausgewaehlteProfile.clear();
                          } else {
                            ausgewaehlteProfile =
                                widget.profile.map((p) => p.id).toSet();
                          }
                        }),
                        child: Text(
                          ausgewaehlteProfile.length ==
                              widget.profile.length
                              ? 'Alle abwählen'
                              : 'Alle auswählen',
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: suchSpielerController,
                    decoration: const InputDecoration(
                      hintText: 'Spieler suchen...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: gefilterteProfile.isEmpty
                      ? const Center(
                      child: Text('Keine Spieler gefunden',
                          style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: gefilterteProfile.length,
                    itemBuilder: (context, index) {
                      final p = gefilterteProfile[index];
                      return CheckboxListTile(
                        dense: true,
                        value:
                        ausgewaehlteProfile.contains(p.id),
                        onChanged: (val) => setState(() {
                          if (val == true) {
                            ausgewaehlteProfile.add(p.id);
                          } else {
                            ausgewaehlteProfile.remove(p.id);
                          }
                        }),
                        secondary: CircleAvatar(
                          radius: 14,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(p.name[0].toUpperCase(),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer
                              )),
                        ),
                        title: Text(p.name),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Divider(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}