# Implementation Plan: Orthodox Chanting App POC

## Context

Scaffolding a Flutter Android app that teaches Byzantine chanting via real-time pitch feedback. The repo is empty (only PLAN.md). Goal: full project skeleton with working pitch-detection loop, lesson UI, CI/CD pipeline — everything needed to build and distribute a demonstrable APK.

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

## Files to Create (ordered by dependency)

### 1. Project Bootstrap
- **`pubspec.yaml`** — all deps (just_audio, pitch_detector_dart, permission_handler, flutter_riverpod, firebase_core, cloud_firestore, firebase_auth, firebase_app_distribution)
- **`android/app/src/main/AndroidManifest.xml`** — mic + internet permissions; label, theme
- **`android/app/build.gradle`** — signing config (reads env vars for CI), minSdk 21

### 2. Data Layer
- **`assets/data/tone1_kyrie.json`** — 7-phrase Kyrie Eleison data (as specified in PLAN.md)
- **`assets/data/tone1_trisagion.json`** — Trisagion data (3-phrase placeholder; partner fills timestamps)
- **`lib/features/lesson/models/chant_phrase.dart`** — `ChantPhrase` with `greek`, `transliteration`, `targetNote` (String e.g. "D4"), `audioOffsetMs` (int)
- **`lib/features/lesson/models/tone.dart`** — `Tone` with `id`, `name`, `mode`, `hymns` list
- **`lib/core/tone_repository.dart`** — `rootBundle.loadString` → JSON decode → `List<ChantPhrase>`

### 3. Services
- **`lib/shared/pitch_service.dart`**
  - Requests mic via `permission_handler`
  - Feeds `pitch_detector_dart`'s `PitchDetector` a raw PCM stream from `record` package (or built-in mic access)
  - `hzToNoteName(double hz)`: implements `n = round(12 * log2(hz/440)) + 69` → MIDI note → "D4" etc.
  - Returns `Stream<String?>` of detected note names

- **`lib/shared/audio_service.dart`**
  - Wraps `AudioPlayer` (just_audio)
  - `loadAsset(String path)`, `play()`, `pause()`, `stop()`
  - Exposes `positionStream` (pass-through from just_audio)

### 4. Riverpod Providers
- **`lib/features/lesson/providers/audio_provider.dart`**
  - `audioServiceProvider` — `Provider<AudioService>`
  - `positionProvider` — `StreamProvider<Duration>` from `audioService.positionStream`

- **`lib/features/lesson/providers/pitch_provider.dart`**
  - `pitchServiceProvider` — `Provider<PitchService>`
  - `detectedNoteProvider` — `StreamProvider<String?>` from `pitchService.noteStream`
  - `pitchFeedbackProvider` — `Provider<PitchFeedback>` (enum: tooLow, correct, tooHigh, inactive); derived by comparing `detectedNote` vs `currentPhrase.targetNote` ±50 cents

### 5. Widgets
- **`lib/features/lesson/widgets/pitch_feedback_widget.dart`**
  - `ConsumerWidget` watching `pitchFeedbackProvider`
  - Animated icon: ↑ (red), ✓ (green), ↓ (red), — (grey when inactive)
  - `AnimatedSwitcher` for smooth transitions

- **`lib/features/lesson/widgets/phrase_display_widget.dart`**
  - `ConsumerWidget` watching `positionProvider` + receives `List<ChantPhrase>`
  - Finds current phrase index from position vs `audioOffsetMs`
  - Bold/gold highlight on current syllable; others dimmed

### 6. Screens
- **`lib/features/lesson/screens/lesson_screen.dart`**
  - Accepts `hymnId` route param
  - Loads phrases from `ToneRepository`
  - Orchestrates: `AudioService.loadAsset` → `play()` on tap
  - Renders `PhraseDisplayWidget` + `PitchFeedbackWidget` + play/stop controls

- **`lib/features/library/screens/library_screen.dart`**
  - Hardcoded list of 2 hymns (Kyrie, Trisagion) under Tone 1 for POC
  - Taps navigate to `LessonScreen`

- **`lib/features/library/widgets/hymn_card.dart`**
  - Card with hymn title, Greek name, duration; tappable

### 7. App Shell
- **`lib/core/theme.dart`** — Dark theme: `Colors.black` bg, gold `#CFB53B` primary, `Cinzel` or `Roboto Serif` font
- **`lib/core/firebase_init.dart`** — `Firebase.initializeApp()` (no-op if `google-services.json` absent)
- **`lib/app.dart`** — `ProviderScope` + `MaterialApp` with routes `/` → LibraryScreen, `/lesson` → LessonScreen
- **`lib/main.dart`** — `runApp(const App())`

### 8. Tests
- **`test/pitch_service_test.dart`**
  - `hzToNoteName(440.0) == 'A4'`
  - `hzToNoteName(293.66) == 'D4'`
  - `hzToNoteName(329.63) == 'E4'`
  - `hzToNoteName(261.63) == 'C4'`

- **`test/lesson_screen_test.dart`**
  - Pumps mocked `LessonScreen`, verifies Greek text renders, play button present

### 9. CI/CD
- **`.github/workflows/pr_check.yml`** — trigger: PR → main; steps: Java 17 + Flutter stable → pub get → analyze → test → build apk --debug
- **`.github/workflows/deploy.yml`** — trigger: push → main; steps: same + decode keystore secret → inject google-services.json → build apk --release with signing → fastlane distribute
- **`fastlane/Fastfile`** — `firebase_app_distribution` lane using `$FIREBASE_APP_ID` + `$FIREBASE_TOKEN`

---

## Key Implementation Details

**Pitch → note conversion** (`pitch_service.dart`):
```dart
String? hzToNoteName(double hz) {
  if (hz <= 0) return null;
  final midiNote = (12 * (log(hz / 440.0) / log(2)) + 69).round();
  const names = ['C','C#','D','D#','E','F','F#','G','G#','A','A#','B'];
  final octave = (midiNote ~/ 12) - 1;
  return '${names[midiNote % 12]}$octave';
}
```

**Feedback derivation** — convert both target and detected note to MIDI number, compare:
```dart
// correct = |detectedMidi - targetMidi| == 0 (within ±50 cents = same semitone for 12-TET)
// tooLow  = detected < target
// tooHigh = detected > target
```

**Phrase synchronization** — in `phrase_display_widget.dart`, derive current index:
```dart
final currentIdx = phrases.lastIndexWhere(
  (p) => position.inMilliseconds >= p.audioOffsetMs,
);
```

**Mic stream approach** — `pitch_detector_dart` expects raw PCM. Use `record` package (`audio_stream`) to get PCM bytes, feed into `PitchDetector`:
```yaml
# add to pubspec.yaml
record: ^5.0.0
```

---

## Verification Steps

1. `flutter analyze` — zero warnings
2. `flutter test` — 4 pitch conversion tests pass, lesson screen smoke test passes
3. `flutter build apk --debug` — APK builds without error
4. On physical Android device: install APK, grant mic permission, tap Kyrie, audio plays, sing → ↑/✓/↓ responds in <200ms
5. Pitch acceptance: D4 (293.66 Hz) → ✓; E4 (329.63 Hz) while targeting D4 → ↓ (too high); C4 while targeting D4 → ↑
6. Non-developer (no instructions) can complete Kyrie lesson flow

---

## Notes / Constraints

- **No `flutter create` needed** — I'll hand-write all source files; the `android/` boilerplate only needs `AndroidManifest.xml` and `build.gradle` customizations; standard Flutter scaffolding files can be generated locally via `flutter create .` after the repo is cloned.
- **`google-services.json` absent** — Firebase init wrapped in try/catch; app functions fully offline for POC.
- **Audio files absent** — `assets/audio/tone1/` placeholders created; partner adds real MP3s and app won't crash (audio error handled gracefully).
- **Byzantine microtones** — 12-TET approximation only; documented in code comment, post-POC item.