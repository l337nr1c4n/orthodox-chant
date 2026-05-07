# Orthodox Chanting App — Project Context

## Identity

Flutter Android app that teaches Byzantine Orthodox chanting using real-time pitch feedback. The same core mechanic as Simply Sing!, applied to sacred liturgical music. No similar app exists: current Orthodox apps are passive playback/reference tools with no interactive learning loop.

**POC goal:** One complete learning flow — user listens to a reference chant, sings into the mic, receives real-time "too high / correct / too low" feedback. De-risks the hardest technical question (real-time pitch detection in Flutter) and produces a demonstrable APK for chanters, parishes, and supporters.

**Budget:** Under $30/month. Leverage free tiers aggressively.

---

## Tech Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Mobile framework | Flutter (Dart) | Single codebase (Android now, iOS later), mature audio ecosystem, typed language easy for CS grads |
| Pitch detection | `pitch_detector_dart` | Pure Dart autocorrelation — no native bridge, works in-process |
| Audio playback | `just_audio` | Industry standard for Flutter; supports local assets, gapless, background |
| Mic stream | `record` | `audio_stream` provides raw PCM bytes for `pitch_detector_dart` |
| State management | `flutter_riverpod` | Lightweight, testable, no code generation required |
| Backend | Firebase (Spark free tier) | Firestore, Storage, Auth, App Distribution — $0 at POC scale |
| CI/CD | GitHub Actions + Fastlane | Lint, test, build, sign, distribute on every merge to main |

### pubspec.yaml dependencies

```yaml
dependencies:
  just_audio: ^0.9.40
  pitch_detector_dart: ^0.0.7
  record: ^5.0.0
  permission_handler: ^11.3.0
  flutter_riverpod: ^2.5.1
  firebase_core: ^3.0.0
  cloud_firestore: ^5.0.0
  firebase_auth: ^5.0.0
  firebase_app_distribution: ^1.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  integration_test:
    sdk: flutter
```

---

## Architecture

```
assets/data/tone1_kyrie.json
assets/data/tone1_trisagion.json
        │
        ▼
  ToneRepository ──────────────────────────────┐
  (loads JSON, parses ChantPhrase list)        │
        │                                      │
        ▼                                      ▼
  AudioProvider (Riverpod)          PitchProvider (Riverpod)
  └─ AudioService (just_audio)      └─ PitchService (pitch_detector_dart)
      plays reference MP3               mic stream → Hz → note name
      exposes positionStream            emits detected note name
        │                                      │
        └──────────────┬───────────────────────┘
                       ▼
               LessonScreen
               ├── PhraseDisplayWidget  (Greek + transliteration, current syllable highlighted)
               └── PitchFeedbackWidget  (↑ / ✓ / ↓  animated indicator)

LibraryScreen ──nav──► LessonScreen(hymnId)
```

---

## Project Directory Tree

```
orthodox-chant/
├── .github/
│   ├── workflows/
│   │   ├── pr_check.yml          # lint + test + debug APK on PR
│   │   └── deploy.yml            # release APK + sign + distribute on main
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   ├── pull_request_template.md
│   ├── CODEOWNERS
│   └── dependabot.yml
├── android/
│   └── app/
│       └── google-services.json  # NOT in repo — injected via GitHub Secret
├── lib/
│   ├── main.dart
│   ├── app.dart                  # ProviderScope + MaterialApp with routes
│   ├── core/
│   │   ├── firebase_init.dart    # try/catch Firebase.initializeApp()
│   │   ├── theme.dart            # dark bg, gold #CFB53B primary, Cinzel/Roboto Serif
│   │   └── tone_repository.dart  # rootBundle.loadString → JSON → List<ChantPhrase>
│   ├── features/
│   │   ├── lesson/
│   │   │   ├── models/
│   │   │   │   ├── chant_phrase.dart   # greek, transliteration, targetNote, audioOffsetMs
│   │   │   │   └── tone.dart          # id, name, mode, hymns list
│   │   │   ├── providers/
│   │   │   │   ├── audio_provider.dart    # audioServiceProvider, positionProvider
│   │   │   │   └── pitch_provider.dart   # pitchServiceProvider, detectedNoteProvider, pitchFeedbackProvider
│   │   │   ├── screens/
│   │   │   │   └── lesson_screen.dart
│   │   │   └── widgets/
│   │   │       ├── pitch_feedback_widget.dart   # ↑/✓/↓ AnimatedSwitcher
│   │   │       └── phrase_display_widget.dart   # Greek + transliteration, gold highlight
│   │   └── library/
│   │       ├── screens/
│   │       │   └── library_screen.dart    # hardcoded 2 hymns for POC
│   │       └── widgets/
│   │           └── hymn_card.dart
│   └── shared/
│       ├── audio_service.dart    # wraps just_audio AudioPlayer
│       └── pitch_service.dart    # wraps pitch_detector_dart + hzToNoteName
├── assets/
│   ├── audio/
│   │   └── tone1/
│   │       ├── kyrie_eleison.mp3   # recorded by partner; placeholder OK for POC
│   │       └── trisagion.mp3
│   └── data/
│       ├── tone1_kyrie.json
│       └── tone1_trisagion.json
├── test/
│   ├── unit/
│   │   ├── pitch_service_test.dart
│   │   ├── chant_phrase_test.dart
│   │   └── tone_repository_test.dart
│   └── widget/
│       ├── lesson_screen_test.dart
│       ├── library_screen_test.dart
│       └── pitch_feedback_widget_test.dart
├── integration_test/
│   └── lesson_flow_test.dart
├── fastlane/
│   └── Fastfile
├── CLAUDE.md
├── README.md
└── pubspec.yaml
```

---

## Data Models

### ChantPhrase (JSON schema)

```json
{
  "greek": "Κύ",
  "transliteration": "Ky",
  "target_note": "D4",
  "audio_offset_ms": 0
}
```

### Full Kyrie Eleison phrase set (Tone 1)

```json
{
  "tone": "1",
  "hymn": "kyrie_eleison",
  "phrases": [
    { "greek": "Κύ",   "transliteration": "Ky",  "target_note": "D4", "audio_offset_ms": 0    },
    { "greek": "ρι",   "transliteration": "ri",  "target_note": "E4", "audio_offset_ms": 800  },
    { "greek": "ε",    "transliteration": "e",   "target_note": "D4", "audio_offset_ms": 1600 },
    { "greek": "ε",    "transliteration": "e",   "target_note": "C4", "audio_offset_ms": 2400 },
    { "greek": "λέ",   "transliteration": "lei", "target_note": "D4", "audio_offset_ms": 3200 },
    { "greek": "η",    "transliteration": "i",   "target_note": "E4", "audio_offset_ms": 4000 },
    { "greek": "σον",  "transliteration": "son", "target_note": "D4", "audio_offset_ms": 4800 }
  ]
}
```

Trisagion: 3-phrase placeholder; partner maps timestamps from recording.

---

## Key Algorithms

### Pitch → note name (pitch_service.dart)

```dart
String? hzToNoteName(double hz) {
  if (hz <= 0) return null;
  final midiNote = (12 * (log(hz / 440.0) / log(2)) + 69).round();
  const names = ['C','C#','D','D#','E','F','F#','G','G#','A','A#','B'];
  final octave = (midiNote ~/ 12) - 1;
  return '${names[midiNote % 12]}$octave';
}
```

Reference values: A4=440Hz, D4=293.66Hz, E4=329.63Hz, C4=261.63Hz

### Feedback derivation (pitch_provider.dart)

Convert both target and detected note to MIDI number, compare:
- `|detectedMidi - targetMidi| == 0` → correct (within ±50 cents = same semitone in 12-TET)
- `detected < target` → tooLow (user must sing higher → show ↑)
- `detected > target` → tooHigh (user must sing lower → show ↓)

PitchFeedback enum: `tooLow | correct | tooHigh | inactive`

### Phrase synchronization (phrase_display_widget.dart)

```dart
final currentIdx = phrases.lastIndexWhere(
  (p) => position.inMilliseconds >= p.audioOffsetMs,
);
```

### Mic stream approach

`record` package (`audio_stream`) provides raw PCM bytes → feed into `pitch_detector_dart`'s `PitchDetector`. `pitch_detector_dart` expects raw PCM; this avoids any native bridge.

---

## POC Content Scope

**One tone, two hymns:**
- Tone 1 (Πρῶτος Ἦχος) — First tone, plagal mode, most foundational
- Kyrie Eleison (Κύριε ἐλέησον) — 7 phrases, universal, short
- Trisagion (Ἅγιος ὁ Θεός) — 3-phrase placeholder

Audio: MP3, recorded by partner, bundled in APK assets (offline, avoids Firebase Storage cost).

---

## CI/CD Pipeline

### PR Check (.github/workflows/pr_check.yml)
Trigger: `pull_request` → `main`
Steps: Java 17 + Flutter stable → pub get → analyze → test unit/ + widget/ → build apk --debug

### Deploy (.github/workflows/deploy.yml)
Trigger: `push` → `main`
Steps: same → integration_test/ on Android emulator (API 29) → decode keystore → inject google-services.json → build apk --release with signing → fastlane distribute → shred keystore

### GitHub Secrets Required

| Secret | Value |
|--------|-------|
| `KEYSTORE_BASE64` | Base64-encoded Android keystore |
| `KEY_ALIAS` | Keystore alias |
| `KEY_PASSWORD` | Key password |
| `STORE_PASSWORD` | Keystore store password |
| `GOOGLE_SERVICES_JSON` | Firebase config JSON (base64) |
| `FIREBASE_APP_ID` | Firebase App Distribution app ID |
| `FIREBASE_TOKEN` | Firebase CI token |

---

## Firebase Free Tier Budget

| Service | Free Allowance | POC Usage |
|---------|---------------|-----------|
| Firestore | 50k reads/day, 1 GiB | <100 reads/day, <1 MB |
| Storage | 5 GB, 1 GB/day download | Audio bundled in APK |
| Auth | 10k anonymous/month | <100 users |
| App Distribution | Free, unlimited | Team + beta testers |

Estimated monthly cost: **$0** (Spark tier).

---

## Known Constraints & Tradeoffs

- **Byzantine microtones:** 12-TET approximation only. Byzantine chant uses quarter-tones that Western pitch detection cannot map 1:1. Documented tradeoff; post-POC enhancement.
- **`google-services.json` absent:** Firebase init wrapped in try/catch; app functions fully offline for POC.
- **Audio files absent:** `assets/audio/tone1/` placeholders only; partner adds real MP3s. Audio errors handled gracefully (no crash).
- **No `flutter create` needed for repo:** Hand-write source files; run `flutter create .` locally after cloning to generate standard boilerplate (`android/`, `ios/` scaffolding).
- **Mic not testable in CI emulator:** Integration test verifies navigation and UI only. Physical device required for pitch detection acceptance test.

---

## Division of Labor

| Task | Isaac | Partner |
|------|-------|---------|
| GitHub / CI/CD setup | ✓ | |
| Firebase project setup | ✓ | |
| Flutter architecture + services | ✓ | assist |
| Lesson screen UI | | ✓ |
| Library screen UI | | ✓ |
| Liturgical text accuracy | | ✓ (Koine Greek) |
| Reference audio recording | | ✓ (Orthodox) |
| Syllable timestamp mapping | | ✓ |
| Byzantine notation research | | ✓ |

Backlog: **Linear** (free ≤ 2 members). Branch naming: `CHT-{id}/short-kebab-description`.

---

## Implementation Phases

| Phase | Focus | Weeks |
|-------|-------|-------|
| 1 | Infrastructure: repo, Firebase, CI/CD, keystore | 1 |
| 2 | Core pitch loop: PitchService, AudioService, providers | 2–3 |
| 3 | Lesson screen: ChantPhrase, PhraseDisplayWidget, LessonScreen | 3–4 |
| 4 | Content: partner records audio, maps timestamps, populates JSON | 4–5 |
| 5 | Library + polish: LibraryScreen, theme, onboarding, demo APK | 5–6 |

---

## POC Verification Criteria

1. Fresh APK install from Firebase App Distribution opens without crash
2. Library screen shows at least 2 hymns under Tone 1
3. Tapping a hymn navigates to lesson screen
4. Lesson screen plays reference audio with synchronized Greek + transliteration
5. Singing into mic shows ↑/✓/↓ feedback in near real-time (<200ms)
6. Non-developer (parish member) completes a lesson flow without instructions

**Pitch detection acceptance test:**
- Sing D4 (293.66 Hz) → ✓ correct
- Sing E4 (329.63 Hz) while targeting D4 → ↓ too high
- Sing C4 (261.63 Hz) while targeting D4 → ↑ too low
- Correct zone: ±50 cents (half semitone)

---

## Future Roadmap (Post-POC)

- Additional tones 2–8 of the Octoechos
- Stavros First Appalachian chant content
- Byzantine neume rendering (SVG/WebView)
- Progress tracking and lesson streaks
- iOS build
- Microtone-aware pitch detection
- Gamification (accuracy scores, badges)
