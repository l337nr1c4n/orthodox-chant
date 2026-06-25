/// A reference to a hymn within a tone's chapter list.
///
/// [iconAsset] is a hook for sacred icon artwork (e.g. Christ Pantocrator for
/// the Kyrie); it stays null until artwork is added, so icons can be dropped
/// in later without a schema change.
class HymnRef {
  final String id; // e.g. "tone1_kyrie" — matches the hymn JSON / lesson route
  final String title; // Greek, e.g. "Κύριε ἐλέησον"
  final String subtitle; // e.g. "Kyrie Eleison • 7 phrases"
  final String? iconAsset; // e.g. "assets/icons/hymns/kyrie.png", or null

  const HymnRef({
    required this.id,
    required this.title,
    required this.subtitle,
    this.iconAsset,
  });
}
