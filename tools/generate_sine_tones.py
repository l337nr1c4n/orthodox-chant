"""
Generates sine wave reference audio for a chant hymn JSON asset.
Usage: python tools/generate_sine_tones.py assets/data/tone1_trisagion.json
Output: assets/audio/tone1/trisagion.wav
"""

import json
import math
import struct
import sys
import wave
from pathlib import Path

SAMPLE_RATE = 44100
FADE_MS = 20
SYLLABLE_MS = 750  # tone duration per syllable; 50ms silence gap follows naturally

NOTE_FREQS = {
    'C4': 261.63,
    'D4': 293.66,
    'E4': 329.63,
    'F4': 349.23,
    'G4': 392.00,
}


def sine_tone(freq: float, duration_ms: int) -> list[float]:
    n = int(SAMPLE_RATE * duration_ms / 1000)
    fade = int(SAMPLE_RATE * FADE_MS / 1000)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        s = math.sin(2 * math.pi * freq * t)
        if i < fade:
            s *= i / fade
        elif i > n - fade:
            s *= (n - i) / fade
        samples.append(s)
    return samples


def main(json_path: str) -> None:
    data = json.loads(Path(json_path).read_text(encoding='utf-8'))
    phrases = data['phrases']
    hymn = data['hymn']

    last_offset_ms = phrases[-1]['audio_offset_ms']
    total_ms = last_offset_ms + SYLLABLE_MS + 500
    total_samples = int(SAMPLE_RATE * total_ms / 1000)
    audio = [0.0] * total_samples

    for phrase in phrases:
        offset = int(SAMPLE_RATE * phrase['audio_offset_ms'] / 1000)
        freq = NOTE_FREQS[phrase['target_note']]
        tone = sine_tone(freq, SYLLABLE_MS)
        for i, s in enumerate(tone):
            if offset + i < total_samples:
                audio[offset + i] += s

    peak = max(abs(s) for s in audio) or 1.0
    audio = [s / peak * 0.85 for s in audio]

    out_path = Path(json_path).parent.parent / 'audio' / 'tone1' / f'{hymn}.wav'
    out_path.parent.mkdir(parents=True, exist_ok=True)

    with wave.open(str(out_path), 'w') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        for s in audio:
            wf.writeframes(struct.pack('<h', int(s * 32767)))

    print(f'Written: {out_path}  ({total_ms}ms, {len(phrases)} syllables)')


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print('Usage: python tools/generate_sine_tones.py <json_path>')
        sys.exit(1)
    main(sys.argv[1])
