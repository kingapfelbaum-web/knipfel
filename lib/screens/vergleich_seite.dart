import 'package:flutter/material.dart';
import '../models/spieler_profil.dart';
import '../models/spiel.dart';

class VergleichSeite extends StatelessWidget {
  final List<SpielerProfil> profile;
  final List<Spiel> spiele;

  const VergleichSeite({
    super.key,
    required this.profile,
    required this.spiele,
  });

  // Nur Spiele bei denen ALLE ausgewählten Spieler dabei waren
  List<Spiel> _gemeinsameSpiele() => spiele
      .where((s) =>
  s.beendet &&
      profile.every((p) =>
          s.spieler.any((sp) => sp.profilId == p.id)))
      .toList();

  List<Spieler> _rundenVonSpieler(SpielerProfil profil, List<Spiel> spiele) =>
      spiele
          .map((s) =>
          s.spieler.firstWhere((sp) => sp.profilId == profil.id))
          .toList();

  int _siege(SpielerProfil profil, List<Spiel> gemeinsam) => gemeinsam
      .where((s) {
      // Nur die ausgewählten Spieler berücksichtigen
      final ausgewaehlteImSpiel = s.spieler
          .where((sp) => profile.any((p) => p.id == sp.profilId))
      .toList()
  ..sort((a, b) => b.gesamt.compareTo(a.gesamt));
  return ausgewaehlteImSpiel.isNotEmpty &&
  ausgewaehlteImSpiel.first.profilId == profil.id;
})
.length;

  @override
  Widget build(BuildContext context) {
    final gemeinsam = _gemeinsameSpiele();
    final farben = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.green.shade100,
      Colors.blue.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.red.shade100,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('⚔️ Vergleich')),
      body: gemeinsam.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Keine gemeinsamen abgeschlossenen Spiele gefunden.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.primaryFixed),
          ),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.primary),
            ),
            child: Text(
              '${gemeinsam.length} gemeinsame Spiele mit '
                  '${profile.map((p) => p.name).join(', ')}',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),

          // ── Übersichtstabelle ──────────────────────
          const Text('Übersicht',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _uebersichtsTabelle(context, gemeinsam, farben),
          const SizedBox(height: 24),

          // ── Balkendiagramme ────────────────────────
          const Text('Ø Gesamtpunkte',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _balkenDiagramm(context, gemeinsam, 'gesamt', farben),
          const SizedBox(height: 24),

          const Text('Siege',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _siegeBalken(context, gemeinsam, farben),
          const SizedBox(height: 24),

          const Text('Beste Runde',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _balkenDiagramm(context, gemeinsam, 'beste', farben),
          const SizedBox(height: 24),

          const Text('Schlechteste Runde',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _balkenDiagramm(context, gemeinsam, 'schlechteste', farben),
          const SizedBox(height: 24),

          // ── Kategorien-Vergleich ───────────────────
          const Text('Ø Punkte pro Kategorie',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _kategorienVergleich(context, gemeinsam, farben),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Übersichtstabelle ──────────────────────────────────
  Widget _uebersichtsTabelle(BuildContext context, List<Spiel> gemeinsam, List<Color> farben) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Table(
          columnWidths: const {0: FlexColumnWidth(2)},
          border: TableBorder(
            horizontalInside: BorderSide(),
          ),
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(),
              children: [
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...profile.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    e.value.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: farben[e.key % farben.length],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
              ],
            ),
            _tabellenZeile(context, 'Spiele', gemeinsam, farben,
                    (p, s) => s.length.toString()),
            _tabellenZeile(context, 'Siege', gemeinsam, farben,
                    (p, s) => _siege(p, s).toString()),
            _tabellenZeile(context, 'Ø Punkte', gemeinsam, farben, (p, s) {
              final r = _rundenVonSpieler(p, s);
              final avg =
                  r.fold(0, (a, b) => a + b.gesamt) / r.length;
              return avg.toStringAsFixed(1);
            }),
            _tabellenZeile(context, 'Beste', gemeinsam, farben, (p, s) {
              final r = _rundenVonSpieler(p, s);
              return r
                  .map((x) => x.gesamt)
                  .reduce((a, b) => a > b ? a : b)
                  .toString();
            }),
            _tabellenZeile(context, 'Schlechteste', gemeinsam, farben, (p, s) {
              final r = _rundenVonSpieler(p, s);
              return r
                  .map((x) => x.gesamt)
                  .reduce((a, b) => a < b ? a : b)
                  .toString();
            }),
          ],
        ),
      ),
    );
  }

  TableRow _tabellenZeile(
      BuildContext context,
      String label,
      List<Spiel> gemeinsam,
      List<Color> farben,
      String Function(SpielerProfil, List<Spiel>) wertFn,
      ) {
    final werte = profile.map((p) => wertFn(p, gemeinsam)).toList();
    // Höchsten Wert finden für Hervorhebung
    double? hoechster;
    try {
      hoechster = werte.map((w) => double.parse(w)).reduce((a, b) => a > b ? a : b);
    } catch (_) {}

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(label,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimaryContainer)),
        ),
        ...profile.asMap().entries.map((e) {
          final wert = werte[e.key];
          double? wertNum;
          try { wertNum = double.parse(wert); } catch (_) {}
          final istBester = hoechster != null &&
              wertNum != null &&
              wertNum == hoechster;
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              wert,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                istBester ? FontWeight.bold : FontWeight.normal,
                color: istBester
                    ? farben[e.key % farben.length]
                    : Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }),
      ],
    );
  }

  // ── Balkendiagramm ─────────────────────────────────────
  Widget _balkenDiagramm(BuildContext context, List<Spiel> gemeinsam, String typ, List<Color> farben) {
    final werte = profile.map((p) {
      final runden = _rundenVonSpieler(p, gemeinsam);
      switch (typ) {
        case 'gesamt':
          return runden.fold(0, (a, b) => a + b.gesamt) / runden.length;
        case 'beste':
          return runden
              .map((r) => r.gesamt)
              .reduce((a, b) => a > b ? a : b)
              .toDouble();
        case 'schlechteste':
          return runden
              .map((r) => r.gesamt)
              .reduce((a, b) => a < b ? a : b)
              .toDouble();
        default:
          return 0.0;
      }
    }).toList();

    final maximum = werte.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: profile.asMap().entries.map((e) {
            final wert = werte[e.key];
            final prozent = maximum > 0 ? wert / maximum : 0.0;
            final farbe = farben[e.key % farben.length];
            final hintergrundFarbe = farben[(e.key % farben.length) +5];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      e.value.name,
                      style: TextStyle(
                          fontSize: 12,
                          color: farbe,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: prozent,
                        minHeight: 20,
                        backgroundColor: hintergrundFarbe,
                        valueColor: AlwaysStoppedAnimation<Color>(farbe),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 45,
                    child: Text(
                      wert == wert.roundToDouble()
                          ? wert.toInt().toString()
                          : wert.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: farbe),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _siegeBalken(BuildContext context, List<Spiel> gemeinsam, List<Color> farben) {
    final werte =
    profile.map((p) => _siege(p, gemeinsam).toDouble()).toList();
    final maximum =
    werte.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: profile.asMap().entries.map((e) {
            final wert = werte[e.key];
            final farbe = farben[e.key % farben.length];
            final hintergrundFarbe = farben[(e.key % farben.length)+5];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      e.value.name,
                      style: TextStyle(
                          fontSize: 12,
                          color: farbe,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: wert / maximum,
                        minHeight: 20,
                        backgroundColor: hintergrundFarbe,
                        valueColor: AlwaysStoppedAnimation<Color>(farbe),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 45,
                    child: Text(
                      '${wert.toInt()}x',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: farbe),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Kategorien-Vergleich ───────────────────────────────
  Widget _kategorienVergleich(BuildContext context, List<Spiel> gemeinsam, List<Color> farben) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Legende
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: profile.asMap().entries.map((e) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: farben[e.key % farben.length],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(e.value.name,
                      style: const TextStyle(fontSize: 12)),
                ],
              )).toList(),
            ),
            const SizedBox(height: 12),
            Text('OBERER BLOCK',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 11)),
            const SizedBox(height: 4),
            ...obereKategorien.map((k) =>
                _kategorieZeile(context, k, gemeinsam, farben,
                    dropdownWerte(k).last.toDouble())),
            const Divider(height: 24),
            Text('UNTERER BLOCK',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 11)),
            const SizedBox(height: 4),
            ...untereKategorien.map((k) =>
                _kategorieZeile(context, k, gemeinsam, farben,
                    (untereWerte[k]?.last ?? 30).toDouble())),
          ],
        ),
      ),
    );
  }

  Widget _kategorieZeile(
      BuildContext context,
      String kategorie,
      List<Spiel> gemeinsam,
      List<Color> farben,
      double maximum,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kategorie,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          ...profile.asMap().entries.map((e) {
            final runden = _rundenVonSpieler(e.value, gemeinsam);
            final werte = runden
                .map((r) => r.punkte[kategorie])
                .whereType<int>()
                .toList();
            final avg = werte.isEmpty
                ? 0.0
                : werte.fold(0, (a, b) => a + b) / werte.length;
            final prozent =
            maximum > 0 ? (avg / maximum).clamp(0.0, 1.0) : 0.0;
            final farbe = farben[e.key % farben.length];
            final hintergrundFarbe = farben[(e.key % farben.length)+5];

            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(e.value.name,
                        style: TextStyle(fontSize: 11, color: farbe),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: prozent,
                        minHeight: 14,
                        backgroundColor: hintergrundFarbe,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(farbe),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 35,
                    child: Text(
                      avg.toStringAsFixed(1),
                      style: TextStyle(fontSize: 11, color: farbe),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}