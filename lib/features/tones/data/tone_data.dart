import '../models/hymn_ref.dart';
import '../models/tone_info.dart';

/// Hardcoded tone metadata for the Octoechos. Tone 1 is fully populated;
/// Tones 2–8 are placeholders (`isAvailable: false`) until content is recorded.
///
/// NOTE: whether the current Tone 1 content (notes A3/B3/G3) is Authentic First
/// or Plagal First is unverified — confirm with Amy Hogg before relabeling.
final List<ToneInfo> toneData = [
  const ToneInfo(
    id: '1',
    name: 'First Tone',
    greekName: 'Ἦχος Πρῶτος',
    character:
        'The First Tone carries a bright, dignified character — confident and '
        'uplifting without losing its solemnity. It is among the most '
        'foundational tones of the Octoechos and a natural place to begin.',
    usage:
        'Sung during its week in the eight-week Octoechos cycle, including the '
        'Resurrectional hymns of Sunday and the setting of many beloved fixed '
        'hymns of the Church.',
    sampleHymnId: 'tone1_kyrie',
    hymns: [
      HymnRef(
        id: 'tone1_kyrie',
        title: 'Κύριε ἐλέησον',
        subtitle: 'Kyrie Eleison • 7 phrases',
      ),
      HymnRef(
        id: 'tone1_trisagion',
        title: 'Ἅγιος ὁ Θεός',
        subtitle: 'Trisagion • 25 phrases',
      ),
    ],
    isAvailable: true,
  ),
  _comingSoon('2', 'Second Tone', 'Ἦχος Δεύτερος'),
  _comingSoon('3', 'Third Tone', 'Ἦχος Τρίτος'),
  _comingSoon('4', 'Fourth Tone', 'Ἦχος Τέταρτος'),
  _comingSoon('5', 'Plagal First', 'Ἦχος Πλάγιος Αʹ'),
  _comingSoon('6', 'Plagal Second', 'Ἦχος Πλάγιος Βʹ'),
  _comingSoon('7', 'Grave Tone', 'Ἦχος Βαρύς'),
  _comingSoon('8', 'Plagal Fourth', 'Ἦχος Πλάγιος Δʹ'),
];

ToneInfo _comingSoon(String id, String name, String greekName) => ToneInfo(
      id: id,
      name: name,
      greekName: greekName,
      character: '',
      usage: '',
      sampleHymnId: '',
      hymns: const [],
      isAvailable: false,
    );
