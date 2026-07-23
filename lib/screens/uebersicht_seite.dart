import 'package:flutter/material.dart';
import '../models/spiel.dart';
import '../services/update_service.dart';
import 'spielblock_seite.dart';
import '../models/spieler_profil.dart';

class UebersichtSeite extends StatefulWidget {
  final UpdateInfo? updateInfo;
  final VoidCallback? onUpdateTap;

  const UebersichtSeite({
    super.key,
    this.updateInfo,
    this.onUpdateTap,
  });

  @override
  State<UebersichtSeite> createState() => _UebersichtSeiteState();
}

class _UebersichtSeiteState extends State<UebersichtSeite> {
  List<Spiel> spiele = [];

  @override
  void initState() {
    super.initState();
    _laden();
  }

  Future<void> _laden() async {
    final geladen = await alleSpieleLaden();
    setState(() => spiele = geladen);
  }

  Future<void> _speichern() async {
    await alleSpieleSpeichern(spiele);
  }


  String _spielName() {
    final now = DateTime.now();
    return 'Spiel ${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _neuesSpiel() async {
    final profile = await alleProfileLaden();
    if (!mounted) return;

    Set<String> ausgewaehlt = {};
    List<String> reihenfolge = [];
    final suchController = TextEditingController();
    bool zeigeReihenfolge = false;

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
              // Titel + Schließen
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    zeigeReihenfolge ? 'Reihenfolge' : 'Neues Spiel',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Inhalt
              if (zeigeReihenfolge) ...[
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: reihenfolge.length * 52.0),
                  child: ReorderableListView(
                    shrinkWrap: true,
                    onReorder: (oldIndex, newIndex) {
                      setDialogState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final id = reihenfolge.removeAt(oldIndex);
                        reihenfolge.insert(newIndex, id);
                      });
                    },
                    children: reihenfolge.map((id) {
                      final p = profile.firstWhere((p) => p.id == id);
                      return ListTile(
                        key: ValueKey(id),
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(p.name[0].toUpperCase(),
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                        ),
                        title: Text(p.name),
                        trailing: const Icon(Icons.drag_handle),
                      );
                    }).toList(),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: suchController,
                  maxLength: 12,
                  decoration: InputDecoration(
                    hintText: 'Spieler suchen oder neu anlegen',
                    prefixIcon: const Icon(Icons.search),
                    counterText: '',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    errorText: suchController.text.length == 12
                        ? 'Maximale Länge erreicht (12 Zeichen)'
                        : null,
                    suffixIcon: suchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.green),
                      onPressed: () async {
                        await _spielerHinzufuegenAusDialog(
                          suchController.text,
                          profile,
                          ausgewaehlt,
                          reihenfolge,
                          setDialogState,
                        );
                        suchController.clear();
                        setDialogState(() {});
                      },
                    )
                        : null,
                  ),
                  onChanged: (_) => setDialogState(() {}),
                  onSubmitted: (val) async {
                    await _spielerHinzufuegenAusDialog(
                        val, profile, ausgewaehlt, reihenfolge, setDialogState);
                    suchController.clear();
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
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
                          .map((p) => CheckboxListTile(
                        dense: true,
                        value: ausgewaehlt.contains(p.id),
                        onChanged: (val) => setDialogState(() {
                          if (val == true) {
                            ausgewaehlt.add(p.id);
                            reihenfolge.add(p.id);
                          } else {
                            ausgewaehlt.remove(p.id);
                            reihenfolge.remove(p.id);
                          }
                        }),
                        secondary: CircleAvatar(
                          radius: 14,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
              ],

              const SizedBox(height: 12),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (zeigeReihenfolge)
                    TextButton(
                      onPressed: () =>
                          setDialogState(() => zeigeReihenfolge = false),
                      child: const Text('Zurück'),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: ausgewaehlt.isEmpty
                        ? null
                        : zeigeReihenfolge
                        ? () {
                      final spielerListe = reihenfolge
                          .map((id) => profile
                          .firstWhere((p) => p.id == id))
                          .map((p) => Spieler(
                          name: p.name, profilId: p.id))
                          .toList();
                      final neuesSpiel = Spiel(
                        id: DateTime.now()
                            .millisecondsSinceEpoch
                            .toString(),
                        name: _spielName(),
                        erstelltAm: DateTime.now(),
                        spieler: spielerListe,
                      );
                      setState(() => spiele.insert(0, neuesSpiel));
                      _speichern();
                      Navigator.pop(context);
                      _spielOeffnen(neuesSpiel);
                    }
                        : () => setDialogState(
                            () => zeigeReihenfolge = true),
                    child: Text(zeigeReihenfolge
                        ? 'Spiel starten'
                        : 'Weiter (${ausgewaehlt.length})'),
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

  Future<void> _spielerHinzufuegenAusDialog(
      String name,
      List<SpielerProfil> profile,
      Set<String> ausgewaehlt,
      List<String> reihenfolge,
      StateSetter setDialogState,
      ) async {
    if (name.trim().isEmpty) return;
    final vorhandenes = profile.firstWhere(
          (p) => p.name.toLowerCase() == name.trim().toLowerCase(),
      orElse: () => SpielerProfil(id: '', name: ''),
    );
    if (vorhandenes.id.isNotEmpty) {
      setDialogState(() {
        ausgewaehlt.add(vorhandenes.id);
        if (!reihenfolge.contains(vorhandenes.id)) {
          reihenfolge.add(vorhandenes.id);
        }
      });
    } else {
      final neuesProfil = SpielerProfil(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
      );
      profile.add(neuesProfil);
      await alleProfileSpeichern(profile);
      setDialogState(() {
        ausgewaehlt.add(neuesProfil.id);
        reihenfolge.add(neuesProfil.id);
      });
    }
  }

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
    setState(() {});
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
            onPressed: () {
              setState(() => spiele.remove(spiel));
              _speichern();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎲 Knipfel'),
        actions: [
          if (widget.updateInfo != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: widget.onUpdateTap,
                icon: Icon(Icons.system_update,
                    color: Theme.of(context).colorScheme.onPrimaryContainer, size: 18),
                label: Text('Update',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer, fontSize: 12)),
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                ),
              ),
            ),
        ],
      ),
      body: spiele.where((s) => !s.beendet).isEmpty
          ? const Center(
          child: Text('Noch keine Spiele – starte ein neues!'))
          : GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: spiele.where((s) => !s.beendet).length,
        itemBuilder: (context, index) {
          final laufendeSpiele = spiele.where((s) => !s.beendet).toList();
          final spiel = laufendeSpiele[index];
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
                    // Status-Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: spiel.beendet
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        spiel.beendet ? '✅ Beendet' : '🎲 Läuft',
                        style: TextStyle(
                          fontSize: 11,
                          color: spiel.beendet
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Spielname
                    Text(spiel.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    // Datum
                    Text(
                      '${spiel.erstelltAm.day}.${spiel.erstelltAm.month}.${spiel.erstelltAm.year}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey),
                    ),
                    const Divider(height: 16),
                    // Spieler
                    Expanded(
                      child: spiel.beendet
                          ? Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: spiel.rangliste
                            .asMap()
                            .entries
                            .map((e) => Text(
                          '${e.key == 0 ? "🥇" : e.key == 1 ? "🥈" : e.key == 2 ? "🥉" : "  "} ${e.value.name}: ${e.value.gesamt}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: e.key == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ))
                            .toList(),
                      )
                          : Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          ...spiel.spieler
                              .take(4)
                              .toList()
                              .asMap()
                              .entries
                              .map((e) => Text(
                            '👤 ${e.value.name}: ${e.value.gesamt}',
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: FloatingActionButton.extended(
          onPressed: _neuesSpiel,
          icon: const Icon(Icons.add),
          label: const Text('Neues Spiel'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}