import 'package:flutter/material.dart';
import '../models/spieler_profil.dart';
import '../models/spiel.dart';

class StatistikSeite extends StatelessWidget {
  final SpielerProfil profil;
  final List<Spiel> spiele;

  const StatistikSeite({
    super.key,
    required this.profil,
    required this.spiele,
  });

  List<Spieler> _meineSpielRunden() => spiele
      .where((s) =>
  s.beendet && s.spieler.any((sp) => sp.profilId == profil.id))
      .map((s) => s.spieler.firstWhere((sp) => sp.profilId == profil.id))
      .toList();

  @override
  Widget build(BuildContext context) {
    final runden = _meineSpielRunden();
    if (runden.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(profil.name)),
        body: const Center(child: Text('Noch keine abgeschlossenen Spiele.')),
      );
    }

    final anzahl = runden.length;
    final siege = spiele
        .where((s) =>
    s.beendet &&
        s.rangliste.isNotEmpty &&
        s.rangliste.first.profilId == profil.id)
        .length;
    final gesamtpunkte = runden.map((r) => r.gesamt).toList();
    final durchschnitt = gesamtpunkte.reduce((a, b) => a + b) / anzahl;
    final beste = gesamtpunkte.reduce((a, b) => a > b ? a : b);
    final schlechteste = gesamtpunkte.reduce((a, b) => a < b ? a : b);

    // Kategorien-Durchschnitt
    final alleKategorien = [...obereKategorien, ...untereKategorien];
    final kategorieSchnitt = <String, double>{};
    for (final k in alleKategorien) {
      final werte = runden
          .map((r) => r.punkte[k])
          .whereType<int>()
          .toList();
      if (werte.isNotEmpty) {
        kategorieSchnitt[k] = werte.reduce((a, b) => a + b) / werte.length;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('📊 ${profil.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Übersicht-Karten
          Row(
            children: [
              _statKarte('Spiele', '$anzahl', Icons.sports_esports),
              const SizedBox(width: 12),
              _statKarte('Siege', '$siege', Icons.emoji_events),
              const SizedBox(width: 12),
              _statKarte('Siegrate',
                  '${(siege / anzahl * 100).toStringAsFixed(0)}%', Icons.percent),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statKarte('Ø Punkte', durchschnitt.toStringAsFixed(1),
                  Icons.calculate),
              const SizedBox(width: 12),
              _statKarte('Beste Runde', '$beste', Icons.trending_up,
                  farbe: Colors.green),
              const SizedBox(width: 12),
              _statKarte('Schlechteste', '$schlechteste', Icons.trending_down,
                  farbe: Colors.red),
            ],
          ),
          const SizedBox(height: 24),

          // Kategorie-Statistik
          const Text('Ø Punkte pro Kategorie',
              style:
              TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('OBERER BLOCK',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 12)),
          const SizedBox(height: 4),
          ...obereKategorien.map((k) => _kategorieZeile(
              k, kategorieSchnitt[k], dropdownWerte(k).last.toDouble())),
          const Divider(height: 24),
          const Text('UNTERER BLOCK',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 12)),
          const SizedBox(height: 4),
          ...untereKategorien.map((k) => _kategorieZeile(
              k,
              kategorieSchnitt[k],
              (untereWerte[k]?.last ?? 30).toDouble())),
          Divider(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _statKarte(String label, String wert, IconData icon,
      {Color farbe = Colors.green}) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: farbe, size: 22),
              const SizedBox(height: 4),
              Text(wert,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: farbe)),
              Text(label,
                  style:
                  const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kategorieZeile(String name, double? schnitt, double maximum) {
    final wert = schnitt ?? 0.0;
    final prozent = maximum > 0 ? (wert / maximum).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontSize: 13)),
              Text(
                schnitt != null ? schnitt.toStringAsFixed(1) : '–',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: prozent,
              minHeight: 7,
              backgroundColor: Colors.grey.shade200,
              valueColor:
              AlwaysStoppedAnimation<Color>(Colors.green.shade400),
            ),
          ),
        ],
      ),
    );
  }
}