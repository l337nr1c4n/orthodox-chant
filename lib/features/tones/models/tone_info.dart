import 'hymn_ref.dart';

/// Metadata for one tone of the Octoechos, used to render its chapter page
/// and the tone selector. Replaces the old unused `Tone` model.
class ToneInfo {
  final String id; // "1".."8"
  final String name; // English, e.g. "First Tone"
  final String greekName; // e.g. "Ἦχος Πρῶτος"
  final String character; // prose: the mood/ethos of the tone
  final String usage; // prose: where it is sung liturgically
  final String sampleHymnId; // hymn used for the "Hear This Tone" preview
  final List<HymnRef> hymns;
  final bool isAvailable; // false => "Coming soon" (no content yet)

  const ToneInfo({
    required this.id,
    required this.name,
    required this.greekName,
    required this.character,
    required this.usage,
    required this.sampleHymnId,
    required this.hymns,
    required this.isAvailable,
  });
}
