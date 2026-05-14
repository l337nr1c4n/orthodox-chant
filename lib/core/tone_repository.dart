import 'dart:convert';
import 'package:flutter/services.dart';
import '../features/lesson/models/chant_phrase.dart';

typedef HymnData = ({String hymn, List<ChantPhrase> phrases});

Future<HymnData> loadHymn(String hymnId) async {
  final raw = await rootBundle.loadString('assets/data/$hymnId.json');
  final data = jsonDecode(raw) as Map<String, dynamic>;
  return (hymn: data['hymn'] as String, phrases: parsePhrases(data));
}

List<ChantPhrase> parsePhrases(Map<String, dynamic> json) {
  final phrases = json['phrases'] as List<dynamic>;
  return phrases
      .map((p) => ChantPhrase.fromJson(p as Map<String, dynamic>))
      .toList();
}
