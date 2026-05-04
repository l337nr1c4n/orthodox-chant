# Plan: Orthodox Chanting App — POC

**Project root:** `C:\Users\ramos\claudeworkspace\orthodox-chant\`
**Git init here** (this directory will be the Ultraplan repo root)
**Plan file location in project:** `orthodox-chant\PLAN.md`

## Context

Isaac and his partner (Orthodox, CS grad, Koine Greek-fluent) are building an Android app that teaches Byzantine Orthodox chanting using real-time pitch feedback — the same core mechanic as Simply Sing!, but applied to sacred liturgical music. No similar app exists: current Orthodox apps are passive playback/reference tools with no interactive learning loop.

The POC goal is a demonstrable, shareable Android app showing one complete learning flow: user listens to a reference chant, sings into the mic, receives real-time "too high / correct / too low" feedback. This de-risks the hardest technical question (real-time pitch detection in Flutter) and gives something concrete to show chanters, parishes, and potential supporters.

Budget: under $30/month. No mobile dev experience on Isaac's side; partner is CS grad but junior. Infrastructure will leverage free tiers aggressively.

---

## Tech Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Mobile framework | **Flutter (Dart)** | Single codebase (Android now, iOS later), mature audio ecosystem, strong CI/CD, typed language easy for systems engineers |
| Pitch detection | `pitch_detector_dart` | Pure Dart autocorrelation — no native bridge, works in-process |
| Audio playback | `just_audio` | Industry standard for Flutter; supports local assets, gapless, background playback |
| State management | `flutter_riverpod` | Lightweight, testable, no code generation required |
| Backend | **Firebase (Spark free tier)** | Firestore (50k reads/day free), Storage (5 GB free), Auth (10k/mo free) — zero cost for POC scale |
| Distribution | **Firebase App Distribution** | Free, no Play Store account needed for POC |
| CI/CD | **GitHub Actions + Fastlane** | Automated lint, test, build, sign, distribute on every merge to main |

### Key Flutter Packages

```yaml
dependencies:
  just_audio: ^0.9.40
  pitch_detector_dart: ^0.2.0
  permission_handler: ^11.3.0
  flutter_riverpod: ^2.5.1
  firebase_core: ^3.0.0
  cloud_firestore: ^5.0.0
  firebase_auth: ^5.0.0
  firebase_app_distribution: ^1.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

---

## Project Structure

```
orthodox-chant/
├── .github/
│   └── workflows/
│       ├── pr_check.yml          # lint + test + debug build on PR
│       └── deploy.yml            # release build + sign + distribute on main
├── android/
│   └── app/
│       └── google-services.json  # Firebase config (not in repo — injected via secret)
├── lib/
│   ├── main.dart
│   ├── app.dart                  # MaterialApp + Riverpod scope
│   ├── core/
│   │   ├── firebase_init.dart
│   │   └── theme.dart            # Byzantine-inspired dark theme
│   ├── features/
│   │   ├── lesson/               # Core learning loop
│   │   │   ├── models/
│   │   │   │   ├── chant_phrase.dart   # syllable, target_note, audio_offset_ms
│   │   │   │   └── tone.dart          # tone name, mode, phrases
│   │   │   ├── providers/
│   │   │   │   ├── audio_provider.dart
│   │   │   │   └── pitch_provider.dart
│   │   │   ├── screens/
│   │   │   │   └── lesson_screen.dart
│   │   │   └── widgets/
│   │   │       ├── pitch_feedback_widget.dart   # ↑ / ✓ / ↓ indicator
│   │   │       ├── phrase_display_widget.dart   # Greek + transliteration
│   │   │       └── waveform_widget.dart         # optional mic visualizer
│   │   └── library/              # Browse tones/hymns
│   │       ├── screens/
│   │       │   └── library_screen.dart
│   │       └── widgets/
│   │           └── hymn_card.dart
│   └── shared/
│       ├── audio_service.dart    # wraps just_audio player
│       └── pitch_service.dart    # wraps pitch_detector_dart
├── assets/
│   ├── audio/
│   │   └── tone1/
│   │       ├── kyrie_eleison.mp3
│   │       └── trisagion.mp3
│   └── fonts/                   # Byzantine neume font (optional, Phase 2+)
├── test/
│   ├── pitch_service_test.dart
│   └── lesson_screen_test.dart
├── fastlane/
│   └── Fastfile                 # Android sign + distribute lanes
└── pubspec.yaml
```

---

## Core Learning Loop Architecture

```
MIC STREAM
   │
   ▼
pitch_detector_dart
(autocorrelation, 20ms buffer)
   │
   ├── detected_hz → nearest_note
   │
   ▼
PitchProvider (Riverpod)
   │
   ├── compare: detected_note vs target_note (from current ChantPhrase)
   │
   ▼
PitchFeedbackWidget
   ├── detected < target - threshold → TOO LOW  ↑
   ├── within threshold            → CORRECT  ✓
   └── detected > target + threshold → TOO HIGH ↓

Simultaneously:
  AudioService → plays reference audio
  PhraseDisplayWidget → shows current syllable (Greek + transliteration)
```

### Note on Byzantine Microtones (POC Scope)

Byzantine chant uses quarter-tones that Western pitch detection cannot map 1:1. For the POC, target notes are approximated to the nearest 12-TET pitch. This is a known simplification — acceptable for demonstrating the interaction pattern. Microtone-aware pitch detection is a post-POC enhancement.

---

## POC Content Scope

**One complete tone, two hymns:**

| Hymn | Greek | Notes |
|------|-------|-------|
| Lord Have Mercy | Κύριε ἐλέησον | 3 syllables, universal, short — ideal first lesson |
| Trisagion | Ἅγιος ὁ Θεός... | Slightly longer, familiar to any parish attendee |

**Tone 1** (Πρῶτος Ἦχος) — First tone, plagal mode — most foundational.

**Audio format:** MP3, recorded by partner, ~60-90 seconds per hymn. Store in `assets/audio/` (bundled in APK) for POC — avoids Firebase Storage costs and works fully offline.

**Data model** (Firestore or local JSON for POC):
```json
{
  "tone": "1",
  "hymn": "kyrie_eleison",
  "phrases": [
    { "greek": "Κύ", "transliteration": "Ky", "target_note": "D4", "audio_offset_ms": 0 },
    { "greek": "ρι", "transliteration": "ri", "target_note": "E4", "audio_offset_ms": 800 },
    { "greek": "ε",  "transliteration": "e",  "target_note": "D4", "audio_offset_ms": 1600 },
    { "greek": "ε",  "transliteration": "e",  "target_note": "C4", "audio_offset_ms": 2400 },
    { "greek": "λέ", "transliteration": "lei", "target_note": "D4", "audio_offset_ms": 3200 },
    { "greek": "η",  "transliteration": "i",  "target_note": "E4", "audio_offset_ms": 4000 },
    { "greek": "σον","transliteration": "son", "target_note": "D4", "audio_offset_ms": 4800 }
  ]
}
```

---

## CI/CD Pipeline

### GitHub Actions — PR Check (`.github/workflows/pr_check.yml`)
```
Trigger: pull_request → main
Steps:
  1. Setup Java 17 + Flutter stable
  2. flutter pub get
  3. flutter analyze
  4. flutter test
  5. flutter build apk --debug
```

### GitHub Actions — Deploy (`.github/workflows/deploy.yml`)
```
Trigger: push → main
Steps:
  1. Setup Java 17 + Flutter stable
  2. flutter pub get
  3. flutter analyze
  4. flutter test
  5. Decode keystore from secret (base64) → android/app/keystore.jks
  6. Inject google-services.json from secret
  7. flutter build apk --release with signing config
  8. fastlane distribute (Firebase App Distribution)
  9. Delete keystore from runner
```

### GitHub Secrets Required
| Secret | Value |
|--------|-------|
| `KEYSTORE_BASE64` | Base64-encoded Android keystore file |
| `KEY_ALIAS` | Keystore alias |
| `KEY_PASSWORD` | Key password |
| `STORE_PASSWORD` | Keystore password |
| `GOOGLE_SERVICES_JSON` | Firebase config (base64) |
| `FIREBASE_APP_ID` | Firebase App Distribution app ID |
| `FIREBASE_TOKEN` | Firebase CI token |

---

## Implementation Phases

### Phase 1 — Infrastructure (Week 1)
- [ ] Create GitHub repo (`orthodox-chant` or similar)
- [ ] `flutter create` new project, commit skeleton
- [ ] Create Firebase project (free Spark), register Android app
- [ ] Configure GitHub Actions `pr_check.yml`
- [ ] Generate Android keystore, encode to base64, add all GitHub Secrets
- [ ] Configure `deploy.yml` + Fastfile
- [ ] Verify: push to main → APK lands in Firebase App Distribution

### Phase 2 — Core Pitch Loop (Weeks 2-3)
- [ ] Implement `PitchService`: mic stream → autocorrelation → detected Hz → nearest note
- [ ] Implement `AudioService`: load asset MP3, play, expose position stream
- [ ] Implement `PitchProvider` + `AudioProvider` (Riverpod)
- [ ] Build `PitchFeedbackWidget`: animated ↑/✓/↓ with color (red/green/red)
- [ ] Unit test pitch frequency → note name conversion
- [ ] Manual test: sing a known pitch, verify detection accuracy

### Phase 3 — Lesson Screen (Weeks 3-4)
- [ ] Build `ChantPhrase` model and JSON loader
- [ ] Build `PhraseDisplayWidget`: Greek text + transliteration, highlight current syllable
- [ ] `LessonScreen`: compose audio playback + phrase display + pitch feedback
- [ ] Sync syllable highlight to audio offset timestamps
- [ ] Handle mic permissions (request on first lesson)

### Phase 4 — Content Integration (Weeks 4-5, runs parallel to Phase 3)
- [ ] Partner records Kyrie Eleison reference audio (Tone 1)
- [ ] Partner records Trisagion reference audio (Tone 1)
- [ ] Map syllable timestamps from recordings
- [ ] Populate phrase JSON data files
- [ ] Integrate audio into lesson screen

### Phase 5 — Library + Polish (Week 5-6)
- [ ] `LibraryScreen`: list of available tones/hymns, navigate to LessonScreen
- [ ] Byzantine-inspired dark theme (gold on dark, minimal)
- [ ] Simple onboarding: microphone permission explanation screen
- [ ] Basic anonymous Firebase Auth (enables future progress tracking)
- [ ] Final demo APK via Firebase App Distribution

---

## Firebase Free Tier Budget

| Service | Free Allowance | POC Usage |
|---------|---------------|-----------|
| Firestore | 50k reads/day, 1 GiB storage | <100 reads/day, <1 MB data |
| Storage | 5 GB, 1 GB/day download | Audio bundled in APK — minimal |
| Auth | 10k anonymous/month | <100 users |
| App Distribution | Free, unlimited | Covers team + beta testers |

**Estimated monthly cost: $0** (Spark tier). Upgrade to Blaze (~$5-10/month) only when beta testers exceed free tier limits.

---

## Division of Labor

| Task | Isaac | Partner |
|------|-------|---------|
| GitHub/CI/CD setup | ✓ | |
| Firebase project setup | ✓ | |
| Flutter project structure + architecture | ✓ | |
| Pitch detection + audio services | ✓ | assist |
| Lesson screen UI | | ✓ |
| Library screen UI | | ✓ |
| Liturgical text accuracy | | ✓ (Koine Greek) |
| Reference audio recording | | ✓ (Orthodox) |
| Syllable timestamp mapping | | ✓ |
| Byzantine notation research | | ✓ |

---

## Verification

**The POC is successful when:**
1. A fresh APK install from Firebase App Distribution opens without crash
2. Library screen shows at least 2 hymns under Tone 1
3. Tapping a hymn navigates to lesson screen
4. Lesson screen plays reference audio, displays Greek + transliteration synchronized
5. Singing into the mic while audio plays shows ↑/✓/↓ feedback in near real-time
6. A non-developer (parish member) can complete a lesson flow without instructions

**Pitch detection acceptance test:**
- Sing a known reference pitch (e.g., D4) → app shows ✓
- Sing a half-step too high → app shows ↓
- Sing a half-step too low → app shows ↑
- Threshold: correct zone = ±50 cents (half semitone)

---

## Future Roadmap (Post-POC, not in scope now)
- Additional tones (2–8 of the octoechos)
- Stavros First Appalachian chant content (his existing recordings + sheet music)
- Byzantine neume rendering (Neanes-exported SVG/HTML in WebView)
- Progress tracking and lesson streaks
- iOS build (Flutter codebase already supports it)
- Microtone-aware pitch detection
- Gamification (accuracy scores, lesson completion badges)
