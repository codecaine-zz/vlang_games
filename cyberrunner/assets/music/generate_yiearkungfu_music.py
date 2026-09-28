#!/usr/bin/env python3
"""Generate 140 BPM Chinese pentatonic martial arts arcade theme for Yie Ar Kung-Fu."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 140
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    # Pentatonic Martial Arts Melody: D, F, G, A, C (Chinese Yu scale)
    melody = [
        62, 65, 67, 69, 72, 69, 67, 65,
        62, 62, 67, 67, 69, 72, 74, 72,
        69, 67, 65, 62, 60, 62, 65, 67,
        69, 72, 69, 67, 65, 62, 62, 62,
    ]

    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        note = melody[b % len(melody)]
        freq = midi_to_freq(note)
        start_idx = b * beat_samples

        # Yangqin / Pipa Plucked Strings
        for s in range(int(beat_samples * 0.8)):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 12.0)
            sine = math.sin(2.0 * math.pi * freq * t)
            sine2 = math.sin(2.0 * math.pi * (freq * 2.0) * t) * 0.4
            samples[idx] += (sine + sine2) * env * 0.4

        # Taiko / Chinese War Drum Beat
        for s in range(int(beat_samples * 0.45)):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 18.0)
            drum_freq = 80.0 if (b % 2 == 0) else 120.0
            drum = math.sin(2.0 * math.pi * drum_freq * t)
            samples[idx] += drum * env * 0.35

    out = bytearray()
    for val in samples:
        clamped = max(-1.0, min(1.0, val * 0.85))
        ival = int(clamped * 32767.0)
        out.extend(struct.pack("<h", ival))
    return bytes(out)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    pcm_data = generate_soundtrack()
    out_dir = root / "assets" / "music"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "yiearkungfu_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "yiearkungfu" / "assets" / "music" / "yiearkungfu_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
