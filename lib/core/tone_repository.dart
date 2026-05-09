import '../features/lesson/models/chant_phrase.dart';

List<ChantPhrase> parsePhrases(Map<String, dynamic> json) {
  final phrases = json['phrases'] as List<dynamic>;
  return phrases
      .map((p) => ChantPhrase.fromJson(p as Map<String, dynamic>))
      .toList();
}
