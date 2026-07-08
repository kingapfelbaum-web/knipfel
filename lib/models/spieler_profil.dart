import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SpielerProfil {
  final String id;
  String name;

  SpielerProfil({required this.id, required this.name});

  SpielerProfil.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'];

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

Future<List<SpielerProfil>> alleProfileLaden() async {
  final prefs = await SharedPreferences.getInstance();
  final data = prefs.getString('spieler_profile');
  if (data == null) return [];
  return (jsonDecode(data) as List)
      .map((e) => SpielerProfil.fromJson(e))
      .toList();
}

Future<void> alleProfileSpeichern(List<SpielerProfil> profile) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
      'spieler_profile', jsonEncode(profile.map((p) => p.toJson()).toList()));
}