# Orthodox Chanting App

> Real-time pitch feedback for Byzantine liturgical chanting — built to help Orthodox Christians learn the ancient tones of the Church.

[![Flutter PR Check](https://github.com/l337nr1c4n/orthodox-chant/actions/workflows/pr_check.yml/badge.svg)](https://github.com/l337nr1c4n/orthodox-chant/actions/workflows/pr_check.yml)
[![Flutter](https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter)](https://flutter.dev)

---

## Why This Exists

No app teaches you to chant. Every Orthodox music app on the market is a passive reference tool — recordings you listen to, not interact with. A new chanter has no way to know whether they are singing the right pitch, whether their ear is calibrated to the mode, or where they are in the phrase. They depend entirely on a human teacher who may not be available.

This app changes that. Sing into your phone, receive instant feedback — too high, correct, too low — synced to the reference audio and the Greek text. It is the same core mechanic as Simply Sing!, applied to the Octoechos. The goal is to put a patient, always-available chanting tutor in every parishioner's pocket.

This is a mission, not a product. All code is public.

---

## POC Scope

One tone. Two hymns.

| Hymn | Greek | Why |
|------|-------|-----|
| Lord Have Mercy | Κύριε ἐλέησον | 3 syllables, universal — the perfect first lesson |
| Trisagion | Ἅγιος ὁ Θεός... | Slightly longer, familiar to any parish attendee |

**Tone 1** (Πρῶτος Ἦχος) — First tone, plagal mode. The most foundational.

The POC is complete when a non-developer (parish member) can install the APK, open the app, tap Kyrie Eleison, and receive real-time pitch feedback without any instructions.

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

## Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter (Dart) — single codebase, Android now, iOS later |
| Pitch detection | `pitch_detector_dart` — pure Dart autocorrelation, no native bridge |
| Audio playback | `just_audio` — industry standard, local assets, gapless |
| Mic stream | `record` — raw PCM stream fed to pitch detector |
| State management | `flutter_riverpod` — lightweight, testable |
| Backend | Firebase Spark (free tier) — Firestore, Auth, App Distribution |
| CI/CD | GitHub Actions + Fastlane |

---

## Getting Started

```bash
# 1. Clone the repo
git clone https://github.com/l337nr1c4n/orthodox-chant.git
cd orthodox-chant

# 2. Generate the standard Flutter project scaffold (first time only)
flutter create . --org com.orthodoxchant

# 3. Install dependencies
flutter pub get

# 4. Run on a connected Android device
flutter run
```

> `google-services.json` is not in the repo. Firebase features are stubbed out gracefully — the app runs fully offline without it.

> Audio files (`assets/audio/tone1/`) are placeholders. The app will not crash without them, but audio will not play. Your partner adds real recordings.

---

## Project Structure

```
orthodox-chant/
├── lib/
│   ├── main.dart
│   ├── app.dart                  # ProviderScope + MaterialApp routes
│   ├── core/
│   │   ├── firebase_init.dart
│   │   ├── theme.dart            # dark bg, gold #CFB53B, Cinzel font
│   │   └── tone_repository.dart  # JSON asset → List<ChantPhrase>
│   ├── features/
│   │   ├── lesson/               # Core learning loop
│   │   │   ├── models/
│   │   │   ├── providers/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   └── library/              # Browse tones and hymns
│   │       ├── screens/
│   │       └── widgets/
│   └── shared/
│       ├── audio_service.dart
│       └── pitch_service.dart
├── assets/
│   ├── audio/tone1/              # MP3s — added by partner
│   └── data/                    # Phrase JSON files
├── test/
│   ├── unit/                    # Pure Dart logic tests
│   └── widget/                  # Widget/functional tests
├── integration_test/            # On-device E2E tests
└── fastlane/
```

---

## Testing

Four layers. Each has a distinct purpose and a corresponding CI stage.

| Layer | Location | When it runs | Needs device? |
|-------|----------|-------------|--------------|
| Unit | `test/unit/` | Every PR | No |
| Widget | `test/widget/` | Every PR | No |
| Integration | `integration_test/` | Merge to `master` | Emulator (CI) |
| Physical device | Manual | Before release | Yes — mic required |

```bash
# Run unit tests
flutter test test/unit/

# Run widget tests
flutter test test/widget/

# Run integration tests (requires connected device or emulator)
flutter test integration_test/

# Run everything except integration
flutter test test/
```

**Pitch detection acceptance test (physical device only):**
- Sing D4 (293.66 Hz) → app shows ✓
- Sing E4 while targeting D4 → app shows ↓
- Sing C4 while targeting D4 → app shows ↑
- Correct zone: ±50 cents

---

## CI/CD

| Trigger | Pipeline | What it does |
|---------|----------|-------------|
| Pull request → `master` | `pr_check.yml` | analyze + unit + widget tests + debug APK build |
| Push → `master` | `deploy.yml` | All above + integration tests (emulator) + release APK + Firebase App Distribution |

### GitHub Secrets (Settings → Secrets and variables → Actions)

| Secret | How to get it |
|--------|--------------|
| `KEYSTORE_BASE64` | `base64 android/app/keystore.jks` |
| `KEY_ALIAS` | Your keytool alias |
| `KEY_PASSWORD` | Key password |
| `STORE_PASSWORD` | Store password |
| `GOOGLE_SERVICES_JSON` | `base64 android/app/google-services.json` |
| `FIREBASE_APP_ID` | Firebase console → App Distribution |
| `FIREBASE_TOKEN` | `firebase login:ci` |

---

## Contributing

### Backlog

We use **[Linear](https://linear.app)** for story tracking. Reach out to Isaac for workspace access.

Cycles map to implementation phases:
1. Infrastructure (repo, Firebase, CI/CD)
2. Pitch Loop (PitchService, AudioService, Riverpod)
3. Lesson Screen (ChantPhrase, PhraseDisplayWidget, LessonScreen)
4. Content Integration (audio recordings, JSON data, timestamps)
5. Library + Polish (LibraryScreen, theme, onboarding, demo APK)

### Branch Naming

```
CHT-{linear-id}/short-kebab-description

# Examples
CHT-12/pitch-feedback-widget
CHT-7/lesson-screen-layout
```

### Pull Requests

- Link your Linear issue in the PR description
- `flutter analyze` must be clean before opening PR
- All `test/unit/` and `test/widget/` tests must pass
- Never commit `google-services.json` or `keystore.jks`

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

---

## Roadmap (Post-POC)

- Tones 2–8 of the Octoechos
- Stavros First Appalachian chant content
- Byzantine neume rendering (SVG/WebView)
- Progress tracking and lesson streaks
- iOS build
- Microtone-aware pitch detection
- Gamification (accuracy scores, completion badges)

---

*Built for the glory of God and the life of the Church.*
