import 'dart:convert';
import 'package:flutter/services.dart';
import '../features/lesson/models/chant_phrase.dart';

Future<List<ChantPhrase>> loadHymn(String hymnId) async {
  final raw = await rootBundle.loadString('assets/data/$hymnId.json');
  return parsePhrases(jsonDecode(raw) as Map<String, dynamic>);
}

List<ChantPhrase> parsePhrases(Map<String, dynamic> json) {
  final phrases = json['phrases'] as List<dynamic>;
  return phrases
      .map((p) => ChantPhrase.fromJson(p as Map<String, dynamic>))
      .toList();
}
