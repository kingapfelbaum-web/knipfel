import 'package:flutter/material.dart';
import '../models/spiel.dart';
import '../models/spieler_profil.dart';

class SpielblockSeite extends StatefulWidget {
  final Spiel spiel;
  final VoidCallback onChanged;


  const SpielblockSeite({
    super.key,
    required this.spiel,
    required this.onChanged,
  });

  @override
  State<SpielblockSeite> createState() => _SpielblockSeiteState();
}

class _SpielblockSeiteState extends State<SpielblockSeite> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Großen Mittelwert damit in beide Richtungen gewischt werden kann
    final mitte = 500 * widget.spiel.spieler.length;
    _pageController = PageController(initialPage: mitte);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.spiel.beendet) _zeigeErgebnis();
    });
  }
  bool get _alleFelderBelegt =>
      widget.spiel.spieler.every((s) => s.istFertig);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _spielBeenden() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Spiel beenden?'),
        content: const Text(
            'Das Spiel wird als abgeschlossen markiert und kann danach nicht mehr bearbeitet werden.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen')),
          ElevatedButton.icon(
            onPressed: () {
              widget.spiel.beendet = true;
              widget.onChanged();
              Navigator.pop(context);
              _zeigeErgebnis();
            },
            icon: const Icon(Icons.flag),
            label: const Text('Spiel beenden'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _zumNaechstenSpieler() {
    if (widget.spiel.spieler.length <= 1) return;
    final aktuell = _pageController.page?.round() ?? 0;
    _pageController.animateToPage(
      aktuell + 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _eintragenUndWechseln(Spieler s, String kategorie, int wert, {bool kniffelZusatz = false}) {
    final warBelegt = s.punkte[kategorie] != null;
    setState(() => s.punkte[kategorie] = wert);
    widget.onChanged();
    if (!warBelegt && !kniffelZusatz) _zumNaechstenSpieler();
  }

  void _zeigeErgebnis() {
    final rangliste = widget.spiel.rangliste;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🏆 Ergebnis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: rangliste.asMap().entries.map((e) {
            final medal =
            e.key == 0 ? '🥇' : e.key == 1 ? '🥈' : e.key == 2 ? '🥉' : '  ';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$medal ${e.value.name}',
                      style: TextStyle(
                        fontWeight: e.key == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: e.key == 0 ? 16 : 14,
                      )),
                  Text('${e.value.gesamt} Pkt.',
                      style: TextStyle(
                          fontWeight: e.key == 0
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _spielerVerwalten() async {
    final profile = await alleProfileLaden();
    if (!mounted) return;

    List<Spieler> spieler = [...widget.spiel.spieler];
    final suchController = TextEditingController();

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
                  const Text('Spieler verwalten',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Neuen Spieler hinzufügen
              const Text('Spieler hinzufügen:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: suchController,
                      maxLength: 12,
                      decoration: InputDecoration(
                        hintText: 'Spieler suchen oder neu anlegen',
                        isDense: true,
                        counterText: '',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.search),
                        errorText: suchController.text.length == 12
                            ? 'Maximale Länge erreicht (12 Zeichen)'
                            : null,
                      ),
                      onChanged: (_) => setDialogState(() {}),
                      onSubmitted: (val) async {
                        await _spielerZuListeHinzufuegen(
                            val, profile, spieler, setDialogState);
                        suchController.clear();
                        setDialogState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () async {
                      await _spielerZuListeHinzufuegen(
                          suchController.text, profile, spieler, setDialogState);
                      suchController.clear();
                      setDialogState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Gespeicherte Spieler als Checkbox-Liste
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: profile
                        .where((p) =>
                    suchController.text.trim().isEmpty ||
                        p.name.toLowerCase().contains(
                            suchController.text.trim().toLowerCase()))
                        .map((p) {
                      final bereitsImSpiel =
                      spieler.any((s) => s.profilId == p.id);
                      return CheckboxListTile(
                        dense: true,
                        value: bereitsImSpiel,
                        onChanged: (val) => setDialogState(() {
                          if (val == true && !bereitsImSpiel) {
                            spieler.add(
                                Spieler(name: p.name, profilId: p.id));
                          } else if (val == false) {
                            spieler.removeWhere((s) => s.profilId == p.id);
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
                      );
                    })
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Reihenfolge – nur anzeigen wenn Tastatur zu
              if (MediaQuery.of(context).viewInsets.bottom == 0) ...[
                const Text('Reihenfolge:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: spieler.length * 52.0),
                  child: ReorderableListView(
                    shrinkWrap: true,
                    onReorder: (oldIndex, newIndex) {
                      setDialogState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final s = spieler.removeAt(oldIndex);
                        spieler.insert(newIndex, s);
                      });
                    },
                    children: spieler.asMap().entries.map((e) => ListTile(
                      key: ValueKey(e.key),
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.green.shade100,
                        child: Text(e.value.name[0].toUpperCase(),
                            style: const TextStyle(fontSize: 12)),
                      ),
                      title: Text(e.value.name),
                      trailing: const Icon(Icons.drag_handle),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Übernehmen-Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() => widget.spiel.spieler = spieler);
                      widget.onChanged();
                      Navigator.pop(context);
                    },
                    child: const Text('Übernehmen'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _spielerZuListeHinzufuegen(
      String name,
      List<SpielerProfil> profile,
      List<Spieler> spieler,
      StateSetter setDialogState,
      ) async {
    if (name.trim().isEmpty) return;
    SpielerProfil? profil = profile.firstWhere(
          (p) => p.name.toLowerCase() == name.trim().toLowerCase(),
      orElse: () => SpielerProfil(id: '', name: ''),
    );
    if (profil.id.isEmpty) {
      profil = SpielerProfil(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
      );
      profile.add(profil);
      await alleProfileSpeichern(profile);
    }
    setDialogState(() {
      spieler.add(Spieler(name: profil!.name, profilId: profil.id));
    });
  }

  void _zeigeKniffelDialog(Spieler spieler) {
    final aktuell = spieler.punkte['Kniffel'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kniffel'),
        content: Text(aktuell != null && aktuell > 0
            ? 'Aktuell: $aktuell Punkte\nNoch einen Kniffel gewürfelt?'
            : 'Kniffel gewürfelt?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen')),
          ElevatedButton.icon(
            onPressed: () {
              _eintragenUndWechseln(spieler, 'Kniffel', 0);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Streichen (0)'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade800),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final neuerWert = (aktuell ?? 0) + 50;
              final warBelegt = aktuell != null;
              setState(() => spieler.punkte['Kniffel'] = neuerWert);
              widget.onChanged();
              if (!warBelegt) _zumNaechstenSpieler();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('+50 Punkte'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade100,
                foregroundColor: Colors.green.shade800),
          ),
        ],
      ),
    );
  }

  void _zeigeEinfachDialog(Spieler spieler, String kategorie, int wert) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(kategorie),
        content: Text('Hast du $kategorie gewürfelt?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen')),
          ElevatedButton.icon(
            onPressed: () {
              _eintragenUndWechseln(spieler, kategorie, 0);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Streichen (0)'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade800),
          ),
          ElevatedButton.icon(
            onPressed: () {
              _eintragenUndWechseln(spieler, kategorie, wert);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check, size: 16),
            label: Text('$wert Punkte'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade100,
                foregroundColor: Colors.green.shade800),
          ),
        ],
      ),
    );
  }

  // Obere Kategorien – direkt als SegmentedButton in der Zeile
  Widget _obereZeile(Spieler s, String kategorie) {
    final index = obereKategorien.indexOf(kategorie) + 1;
    final werte = [0, for (int i = 1; i <= 5; i++) index * i];
    final aktuell = s.punkte[kategorie];

    return PopupMenuButton<int>(
      offset: const Offset(100, 48),
      enabled: !widget.spiel.beendet,
      onSelected: (val) => _eintragenUndWechseln(s, kategorie, val),
      itemBuilder: (_) => werte
          .map((w) => PopupMenuItem<int>(
        value: w,
        child: Text(
          '$w Punkte',
          style: TextStyle(
            fontSize: 15,
            color: w == 0 ? Colors.red : Colors.green.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ))
          .toList(),
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(kategorie, style: const TextStyle(fontSize: 15)),
              ),
              Text(
                aktuell != null ? '$aktuell Punkte' : '–',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: aktuell == null
                      ? Colors.grey
                      : aktuell == 0
                      ? Colors.red
                      : Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

// Päsche + Chance – Freitext-Eingabe
  void _zeigeFreitextDialog(Spieler spieler, String kategorie, int min, int max) {
    final controller = TextEditingController(
      text: (spieler.punkte[kategorie] ?? '') == 0
          ? ''
          : '${spieler.punkte[kategorie] ?? ''}',
    );
    String? fehler;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(kategorie),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Augensumme ($min–$max)',
              errorText: fehler,
              border: const OutlineInputBorder(),
            ),
            onChanged: (val) {
              final n = int.tryParse(val);
              setDialogState(() {
                fehler = n == null
                    ? 'Bitte eine Zahl eingeben'
                    : (n < min || n > max)
                    ? 'Nur $min–$max erlaubt'
                    : null;
              });
            },
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen')),
            ElevatedButton.icon(
              onPressed: () {
                _eintragenUndWechseln(spieler, kategorie, 0);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Streichen (0)'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red.shade800),
            ),
            ElevatedButton.icon(
              onPressed: fehler != null ? null : () {
                final n = int.tryParse(controller.text);
                if (n != null) {
                  _eintragenUndWechseln(spieler, kategorie, n);
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.check, size: 16),
              label: const Text('OK'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade100,
                  foregroundColor: Colors.green.shade800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _spielerBlock(Spieler s) {
    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('OBERER BLOCK',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            // Obere Kategorien → SegmentedButton direkt in Zeile
            ...obereKategorien.map((k) => _obereZeile(s, k)),
            _summenZeile('Summe oben', s.oberesSumme),
            _summenZeile('Bonus (ab 63 Pkt.)  ${s.oberesSumme}/63', s.bonus),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('UNTERER BLOCK',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            // Dreierpasch
            _zeile(s, 'Dreierpasch', [], onTap: () =>
                _zeigeFreitextDialog(s, 'Dreierpasch', 5, 30)),
            // Viererpasch
            _zeile(s, 'Viererpasch', [], onTap: () =>
                _zeigeFreitextDialog(s, 'Viererpasch', 5, 30)),
            // Full House
            _zeile(s, 'Full House', [], onTap: () =>
                _zeigeEinfachDialog(s, 'Full House', 25)),
            // Kleine Straße
            _zeile(s, 'Kleine Straße', [], onTap: () =>
                _zeigeEinfachDialog(s, 'Kleine Straße', 30)),
            // Große Straße
            _zeile(s, 'Große Straße', [], onTap: () =>
                _zeigeEinfachDialog(s, 'Große Straße', 40)),
            // Kniffel
            _kniffelZeile(s),
            // Chance
            _zeile(s, 'Chance', [], onTap: () =>
                _zeigeFreitextDialog(s, 'Chance', 5, 30)),
            const Divider(),
            _summenZeile('GESAMTPUNKTE', s.gesamt, fett: true),
            const SizedBox(height: 80),
          ]),
        ),
      ],
    );
  }

  Widget _zeile(Spieler s, String kategorie, List<int> werte,
      {VoidCallback? onTap}) {
    final punkte = s.punkte[kategorie];
    return ListTile(
      title: Text(kategorie),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            punkte != null ? '$punkte' : '–',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: punkte != null
                  ? (punkte == 0 ? Colors.red : Colors.green.shade700)
                  : Colors.grey,
            ),
          ),
          if (!widget.spiel.beendet)
            const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: widget.spiel.beendet ? null : onTap,
    );
  }

  Widget _kniffelZeile(Spieler s) {
    final punkte = s.punkte['Kniffel'];
    return ListTile(
      title: const Text('Kniffel'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            punkte != null ? '$punkte' : '–',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: punkte != null
                  ? (punkte == 0 ? Colors.red : Colors.green.shade700)
                  : Colors.grey,
            ),
          ),
          if (!widget.spiel.beendet)
            const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: widget.spiel.beendet ? null : () => _zeigeKniffelDialog(s),
    );
  }

  Widget _summenZeile(String label, int wert, {bool fett = false}) {
    return Container(
      color: Colors.green.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: fett ? FontWeight.bold : FontWeight.normal,
                  fontSize: fett ? 16 : 14)),
          Text('$wert',
              style: TextStyle(
                  fontWeight: fett ? FontWeight.bold : FontWeight.normal,
                  fontSize: fett ? 16 : 14,
                  color: Colors.green.shade800)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spiel = widget.spiel;
    return Scaffold(
      appBar: AppBar(
        title: Text(spiel.name),
        actions: [
          if (!widget.spiel.beendet)
            IconButton(
              icon: const Icon(Icons.people),
              tooltip: 'Spieler verwalten',
              onPressed: _spielerVerwalten,
            ),
          if (widget.spiel.beendet)
            IconButton(
              icon: const Icon(Icons.emoji_events),
              onPressed: _zeigeErgebnis,
              tooltip: 'Ergebnis',
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: _alleFelderBelegt ? _spielBeenden : null,
                icon: const Icon(Icons.flag, size: 18),
                label: const Text('Beenden'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _alleFelderBelegt
                      ? Colors.green.shade700
                      : Colors.grey.shade300,
                  foregroundColor: _alleFelderBelegt
                      ? Colors.white
                      : Colors.grey.shade500,
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Text(
            spiel.beendet
                ? '🔒 Spiel beendet – nur Ansicht'
                : '← wischen zum Wechseln →',
            style: TextStyle(color: Colors.green.shade100, fontSize: 12),
          ),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemBuilder: (context, index) {
          final i = index % widget.spiel.spieler.length;
          final s = widget.spiel.spieler[i];
          return Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${s.name}  (${i + 1}/${widget.spiel.spieler.length})',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(child: _spielerBlock(s)),
            ],
          );
        },
      ),
    );
  }
}