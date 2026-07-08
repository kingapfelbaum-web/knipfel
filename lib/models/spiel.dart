import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const List<String> obereKategorien = [
  'Einser', 'Zweier', 'Dreier', 'Vierer', 'Fünfer', 'Sechser'
];
const List<String> untereKategorien = [
  'Dreierpasch', 'Viererpasch', 'Full House',
  'Kleine Straße', 'Große Straße', 'Kniffel', 'Chance'
];

List<int> dropdownWerte(String kategorie) {
  final index = obereKategorien.indexOf(kategorie) + 1;
  return [0, for (int i = 1; i <= 5; i++) index * i];
}

const Map<String, List<int>> untereWerte = {
  'Dreierpasch':   [0, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30],
  'Viererpasch':   [0, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30],
  'Full House':    [0, 25],
  'Kleine Straße': [0, 30],
  'Große Straße':  [0, 40],
  'Kniffel':       [0, 50],
  'Chance':        [0, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30],
};

class Spieler {
  String name;
  String? profilId; // Verknüpfung zum SpielerProfil
  Map<String, int?> punkte;

  Spieler({required this.name, this.profilId})
      : punkte = {
    for (var k in [...obereKategorien, ...untereKategorien]) k: null
  };

  Spieler.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        profilId = json['profilId'],
        punkte = (json['punkte'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as int?));

  Map<String, dynamic> toJson() =>
      {'name': name, 'profilId': profilId, 'punkte': punkte};

  int get oberesSumme =>
      obereKategorien.fold(0, (s, k) => s + (punkte[k] ?? 0));
  int get bonus => oberesSumme >= 63 ? 35 : 0;
  int get untereSumme =>
      untereKategorien.fold(0, (s, k) => s + (punkte[k] ?? 0));
  int get gesamt => oberesSumme + bonus + untereSumme;

  bool get istFertig =>
      [...obereKategorien, ...untereKategorien].every((k) => punkte[k] != null);
}

class Spiel {
  final String id;
  final String name;
  final DateTime erstelltAm;
  List<Spieler> spieler;
  bool beendet;

  Spiel({
    required this.id,
    required this.name,
    required this.erstelltAm,
    required this.spieler,
    this.beendet = false,
  });

  Spiel.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        erstelltAm = DateTime.parse(json['erstelltAm']),
        spieler = (json['spieler'] as List)
            .map((e) => Spieler.fromJson(e))
            .toList(),
        beendet = json['beendet'] ?? false;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'erstelltAm': erstelltAm.toIso8601String(),
    'spieler': spieler.map((s) => s.toJson()).toList(),
    'beendet': beendet,
  };

  Spieler? get gewinner => beendet && spieler.isNotEmpty
      ? ([...spieler]..sort((a, b) => b.gesamt.compareTo(a.gesamt))).first
      : null;

  List<Spieler> get rangliste =>
      [...spieler]..sort((a, b) => b.gesamt.compareTo(a.gesamt));
}

Future<List<Spiel>> alleSpieleLaden() async {
  final prefs = await SharedPreferences.getInstance();
  final data = prefs.getString('alle_spiele');
  if (data == null) return [];
  return (jsonDecode(data) as List).map((e) => Spiel.fromJson(e)).toList();
}

Future<void> alleSpieleSpeichern(List<Spiel> spiele) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
      'alle_spiele', jsonEncode(spiele.map((s) => s.toJson()).toList()));
}