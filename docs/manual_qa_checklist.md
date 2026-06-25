# Manual QA Checklist — On-Device Smoke Test

This covers what CI **can't**: the microphone, audio playback, and the full
Listen → Sing → score → result loop. CI already guarantees `flutter analyze` is
clean and the unit/widget tests pass on every PR; run this on a **physical
Android device** (the emulator mic is unreliable) after installing a fresh APK.

Reference pitches (Tone 1 Kyrie centre): **A3 ≈ 220 Hz**, B3 ≈ 247 Hz, G3 ≈ 196 Hz.
Mark each item ✅ / ❌ and note the device + build.

- Device / Android version: ______________________
- Build / commit: ______________________
- Tester / date: ______________________

---

## 1. Install & launch

- [ ] Fresh APK installs and the app opens **without crashing**
- [ ] First launch goes to **onboarding** (not straight to the library)

## 2. Onboarding & calibration (mic)

- [ ] Onboarding slides swipe through and finish
- [ ] Calibration screen requests the **microphone permission**
- [ ] Humming a steady note shows a live note letter that settles on your pitch
- [ ] "Find your voice" completes and reports a voice-centre note
- [ ] **Skip for now** also works (lands on the library)

## 3. Library (tone selector)

- [ ] Shows **8 tone cards** (the Octoechos)
- [ ] **Tone 1** (Ἦχος Πρῶτος) is gold/active and tappable
- [ ] **Tones 2–8** are dimmed with a **"Coming soon"** label and don't respond to taps
- [ ] The mic (pitch-test) icon is in the app bar

## 4. Tone overview (tap Tone 1)

- [ ] Greek name **Ἦχος Πρῶτος** + English **First Tone** render
- [ ] **"Hear This Tone"** plays the reference audio and **stops after ~5 seconds**
- [ ] Tapping it again mid-preview **stops** playback
- [ ] Character + usage prose are visible
- [ ] Hymn list shows **Κύριε ἐλέησον** and **Ἅγιος ὁ Θεός**
- [ ] Tapping a hymn opens its **lesson**

## 5. Lesson — Listen phase

- [ ] Opens in **Listen**: the scrolling pitch track is visible, **no mic prompt** on entry
- [ ] Play ▶ starts the reference audio; the gold note blocks scroll past the cursor
- [ ] Greek + transliteration are readable and roughly in sync with the audio
- [ ] Pause ⏸ works; audio loops back to start when it finishes
- [ ] A gold **"Sing It"** button is present beneath play/pause

## 6. Lesson — Sing phase (mic)

- [ ] **"Sing It"** requests the mic (first time) and switches to the Sing view
- [ ] App bar shows the **● SING** indicator; reference audio is **paused**
- [ ] Large Greek syllable (gold) + transliteration + **`target: <note>`** show
- [ ] The **countdown ring** fills smoothly over ~3 seconds per phrase
- [ ] Live voice indicator in the ring:
  - [ ] Sing **on pitch** (≈ target) → **✓ green**
  - [ ] Sing **too low** → **↑ blue**
  - [ ] Sing **too high** → **↓ red**
- [ ] **"Hear It"** replays the current phrase reference for ~1.5s, then pauses
- [ ] **"Back to Listen"** stops the mic and returns to the Listen view

## 7. Scoring & result screen

- [ ] Phrases **auto-advance** at the 3-second cadence through to the end
- [ ] After the last phrase, the **result screen** appears automatically
- [ ] **Star rating** looks right: all-correct → ★★★, mostly correct → ★★☆, attempted → ★☆☆
- [ ] "X of N phrases matched" headline matches the per-phrase rows
- [ ] Each phrase row shows ✓/✗ + transliteration + accuracy %
- [ ] **Try Again** returns to the lesson and restarts the Sing phase
- [ ] **Back to Hymns** returns to the tone overview / hymn list

## 8. Completion persistence

- [ ] Complete Tone 1 Kyrie with **≥ 2 stars**
- [ ] Return to the tone overview → that hymn now shows a **✓**
- [ ] Fully close and reopen the app → the ✓ **persists**

## 9. Voice calibration effect (optional)

- [ ] With a non-zero calibration, the lesson app bar shows **"♪ Adjusted for your voice"**
- [ ] The `target:` note and the pitch track are shifted to your range (you can match comfortably)

## 10. Diagnostics & edge cases

- [ ] **Pitch test** screen (mic icon) shows input level + Hz + detected note while singing
- [ ] **Deny** the mic permission when entering Sing → a clear message appears, app doesn't crash
- [ ] Android **back** from a lesson stops audio and the mic (no audio keeps playing)
- [ ] No audio glitches, stuck playback, or crashes across a full run

---

## Acceptance summary (POC criteria)

- [ ] Non-developer can complete a full lesson flow **without instructions**
- [ ] Sing A3 (≈220 Hz) on a D-class target → ✓; sing clearly higher → ↓; clearly lower → ↑
- [ ] Real-time feedback feels responsive (< ~200 ms lag)

> Found a bug? Capture the **phrase**, what you sang, the **on-screen feedback**,
> and the device — that's enough to reproduce most pitch/audio issues.
