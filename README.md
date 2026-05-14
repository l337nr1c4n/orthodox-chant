# Orthodox Chanting App

> Real-time pitch feedback for Byzantine liturgical chanting — built to help Orthodox Christians learn the ancient tones of the Church.

[![Flutter PR Check](https://github.com/l337nr1c4n/orthodox-chant/actions/workflows/pr_check.yml/badge.svg)](https://github.com/l337nr1c4n/orthodox-chant/actions/workflows/pr_check.yml)
[![Flutter](https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter)](https://flutter.dev)

---

## What This App Does

No app teaches you to chant. Every Orthodox music app on the market is a passive reference tool — recordings you listen to, not interact with. A new chanter has no way to know whether they are singing the right pitch, whether their ear is calibrated to the mode, or where they are in the phrase.

This app changes that. Open a hymn, press play, sing into your phone — the app tells you instantly whether you are too high, correct, or too low, synced to the Greek text on screen. The goal is a patient, always-available chanting tutor in every parishioner's pocket.

**Current POC includes:**

| Hymn             | Greek              | Notes                                   |
|------------------|--------------------|-----------------------------------------|
| Lord Have Mercy  | Κύριε ἐλέησον      | 7 syllables — the perfect first lesson  |
| Trisagion        | Ἅγιος ὁ Θεός...    | Familiar to any parish attendee         |

Both are Tone 1 (Πρῶτος Ἦχος). Reference audio is a synthesized sine-tone — not a real chant recording yet. That comes in the next phase.

---

## Installing on Android (Sideload APK)

This is the fastest way to get the app. No app store, no account required.

### Step 1 — Get the APK

**Option A — Download from GitHub Actions (recommended):**

1. Go to [github.com/l337nr1c4n/orthodox-chant/actions](https://github.com/l337nr1c4n/orthodox-chant/actions)
2. Click the most recent passing run on the branch `ORT-34/fix-lesson-audio-and-pitch`
3. Scroll to the bottom of the run page and find **Artifacts**
4. Download `app-debug.apk`

**Option B — Get it from Isaac directly:**

Isaac can share the `app-debug.apk` file over Signal, email, or Google Drive. Just ask.

---

### Step 2 — Allow installing apps from outside the Play Store

Android blocks unknown sources by default. You only need to do this once.

**Android 8.0 and newer (most phones):**

1. Open **Settings**
2. Go to **Apps** (or **Apps & notifications**)
3. Tap **Special app access** (may be under Advanced)
4. Tap **Install unknown apps**
5. Find your file manager or browser (whichever you will use to open the APK) and toggle **Allow from this source** on

**Android 7 and older:**

1. Open **Settings**
2. Go to **Security**
3. Turn on **Unknown sources**

---

### Step 3 — Install the APK

1. Open the APK file you downloaded (tap it in your Downloads folder or file manager)
2. Android will ask if you want to install it — tap **Install**
3. When it finishes, tap **Open**

---

### Step 4 — Grant the microphone permission

The first time you open a hymn lesson, the app will ask for microphone access. Tap **Allow** — this is how the app hears you sing and gives pitch feedback. The mic is never used outside the lesson screen.

**Requirements:** Android 5.0 or newer (almost any phone from 2014 onward works).

---

## Building on iOS (macOS — for developers)

**Prerequisites:** macOS, Xcode 15+, Flutter stable, CocoaPods (`sudo gem install cocoapods`)

```bash
git clone https://github.com/l337nr1c4n/orthodox-chant.git
cd orthodox-chant
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace   # select your device in Xcode, then Run
```

Firebase is optional — the app runs fully offline without `GoogleService-Info.plist`. If you want Firebase features, add the file to `ios/Runner/` from the Firebase console (Project settings → iOS app).

**Note:** TestFlight distribution is not set up yet. Use Xcode direct install for now.

---

## How to Test the App

Once installed, here is what to try:

### 1. Open the Library

The app opens to the Library screen showing Tone 1 with two hymns listed — **Lord Have Mercy** and **Trisagion**.

### 2. Tap a hymn

Tap **Lord Have Mercy** (Kyrie Eleison) to open the lesson. It is shorter, so it is a good first test.

### 3. Press Play

Tap the play button. A reference tone will play — this is a synthesized pitch (sine wave), not a real chant recording yet. The Greek text and transliteration on screen will highlight each syllable as the audio progresses.

### 4. Sing along and watch the feedback

While the reference tone plays, sing the syllable shown on screen. Watch the pitch indicator:

| Indicator | Meaning                                          |
|-----------|--------------------------------------------------|
| **↑**     | You are singing too low — bring your pitch up    |
| **✓**     | You are on the right note — hold it              |
| **↓**     | You are singing too high — bring your pitch down |

The indicator updates in near real-time (under 200ms). Try deliberately singing flat or sharp to see it respond.

### 5. What to check for

- Does the Greek text highlight syllable by syllable as audio plays?
- Does the pitch indicator respond when you sing?
- Does it correctly show ✓ when you match the pitch and ↑/↓ when you are off?
- Does the app stay stable through the full hymn (no crashes)?

---

## A Note on the Current Audio

The reference audio right now is a **synthesized sine tone**, not a real Byzantine chant recording. It plays the correct pitches for each syllable, but it sounds like a tuning fork — not a human chanter. Real recorded audio is being prepared for the next phase. The pitch feedback logic is fully functional regardless.

---

## Developer Setup

If you are a developer and want to run from source:

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

> `google-services.json` is not in the repo. Firebase features fail gracefully — the app runs fully offline without it.

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
      plays reference tone               mic stream → Hz → note name
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

| Layer            | Choice                                                               |
|------------------|----------------------------------------------------------------------|
| Framework        | Flutter (Dart) — single codebase, Android now, iOS later            |
| Pitch detection  | `pitch_detector_dart` — pure Dart autocorrelation, no native bridge  |
| Audio playback   | `just_audio` — industry standard, local assets, gapless              |
| Mic stream       | `flutter_sound` — raw PCM stream; survives simultaneous playback on Samsung HAL |
| State management | `flutter_riverpod` — lightweight, testable                           |
| Backend          | Firebase Spark (free tier) — Firestore, Auth, App Distribution       |
| CI/CD            | GitHub Actions + Fastlane                                            |

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

## Testing (Developers)

| Layer | Location | When it runs | Needs device? |
|-------|----------|-------------|--------------|
| Unit | `test/unit/` | Every PR | No |
| Widget | `test/widget/` | Every PR | No |
| Integration | `integration_test/` | Merge to `master` | Emulator (CI) |
| Physical device | Manual | Before release | Yes — mic required |

```bash
flutter test test/unit/
flutter test test/widget/
flutter test integration_test/
```

**Pitch detection acceptance test (physical device only):**
- Sing A3 (220 Hz) while targeting A3 → app shows ✓
- Sing B3 while targeting A3 → app shows ↓
- Sing G3 while targeting A3 → app shows ↑
- Correct zone: ±50 cents (one semitone)

---

## CI/CD

| Trigger | Pipeline | What it does |
|---------|----------|-------------|
| Pull request → `master` | `pr_check.yml` | analyze + unit + widget tests + debug APK build |
| Push → `master` | `deploy.yml` | All above + integration tests (emulator) + release APK + Firebase App Distribution |

### GitHub Secrets Required

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

### Branch Naming

```
ORT-{linear-id}/short-kebab-description

# Examples
ORT-12/pitch-feedback-widget
ORT-7/lesson-screen-layout
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
