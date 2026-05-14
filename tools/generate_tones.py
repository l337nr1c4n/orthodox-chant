"""
Generate bass-range sine tone WAV files for Orthodox Chant app.
Reads shifted JSON phrase data and writes timed tones to assets/audio/tone1/.

Usage: python tools/generate_tones.py
No external dependencies — standard library only.
"""

import json
import math
import struct
import wave
import os

SAMPLE_RATE = 44100
AMPLITUDE = 0.7       # 70% of full scale — leaves headroom
FADE_MS = 50          # fade in/out to eliminate clicks between tones
LAST_TONE_MS = 1200   # duration of final phrase tone

NOTE_HZ = {
    'G3': 196.00,
    'A3': 220.00,
    'B3': 246.94,
}

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
DATA_DIR = os.path.join(REPO_ROOT, 'assets', 'data')
AUDIO_DIR = os.path.join(REPO_ROOT, 'assets', 'audio', 'tone1')

HYMNS = ['tone1_kyrie', 'tone1_trisagion']


def sine_tone(freq_hz: float, duration_ms: int) -> list[int]:
    num_samples = int(SAMPLE_RATE * duration_ms / 1000)
    fade_samples = int(SAMPLE_RATE * FADE_MS / 1000)
    frames = []
    for i in range(num_samples):
        raw = math.sin(2 * math.pi * freq_hz * i / SAMPLE_RATE)
        amp = AMPLITUDE
        if i < fade_samples:
            amp *= i / fade_samples
        elif i > num_samples - fade_samples:
            amp *= (num_samples - i) / fade_samples
        frames.append(int(raw * amp * 32767))
    return frames


def generate_hymn(hymn_id: str) -> None:
    json_path = os.path.join(DATA_DIR, f'{hymn_id}.json')
    with open(json_path, encoding='utf-8') as f:
        data = json.load(f)

    hymn_name = data['hymn']
    phrases = data['phrases']

    all_frames: list[int] = []
    for i, phrase in enumerate(phrases):
        note = phrase['target_note']
        offset_ms = phrase['audio_offset_ms']
        if i + 1 < len(phrases):
            duration_ms = phrases[i + 1]['audio_offset_ms'] - offset_ms
        else:
            duration_ms = LAST_TONE_MS

        if note not in NOTE_HZ:
            raise ValueError(f'Unknown note {note!r} in {hymn_id} phrase {i}')

        all_frames.extend(sine_tone(NOTE_HZ[note], duration_ms))

    out_path = os.path.join(AUDIO_DIR, f'{hymn_name}.wav')
    with wave.open(out_path, 'w') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)  # 16-bit
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(struct.pack(f'<{len(all_frames)}h', *all_frames))

    duration_s = len(all_frames) / SAMPLE_RATE
    print(f'  {hymn_name}.wav  —  {len(phrases)} phrases, {duration_s:.1f}s')


if __name__ == '__main__':
    os.makedirs(AUDIO_DIR, exist_ok=True)
    print('Generating bass-range sine tones (G3=196Hz, A3=220Hz, B3=247Hz)...')
    for hymn_id in HYMNS:
        generate_hymn(hymn_id)
    print('Done.')
