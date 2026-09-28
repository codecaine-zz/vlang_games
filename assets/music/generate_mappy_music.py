#!/usr/bin/env python3
"""Generate 142 BPM iconic ragtime circus theme for Mappy (1983 Namco Arcade)."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 142
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    # Ragtime bouncy melody notes (C major / G7 bouncy stride)
    melody = [
        60, 64, 67, 72, 71, 69, 67, 64,
        62, 65, 69, 71, 72, 71, 69, 67,
        60, 64, 67, 72, 74, 72, 71, 69,
        67, 65, 64, 62, 60, 64, 60, 0,
    ]

    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        note = melody[b % len(melody)]
        start_idx = b * beat_samples

        # Ragtime Piano Lead
        if note > 0:
            freq = midi_to_freq(note)
            for s in range(int(beat_samples * 0.8)):
                idx = start_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 14.0)
                # Bouncy square wave whistle
                sq = 1.0 if ((t * freq) % 1.0) < 0.5 else -1.0
                samples[idx] += sq * env * 0.3

        # Stride Bass (Alternating Root & 5th)
        bn = (60 if (b % 4 == 0) else (55 if (b % 4 == 2) else 53)) - 12
        bfreq = midi_to_freq(bn)
        for s in range(int(beat_samples * 0.5)):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 16.0)
            sine = math.sin(2.0 * math.pi * bfreq * t)
            samples[idx] += sine * env * 0.35

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
    out_path = out_dir / "mappy_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "mappy" / "assets" / "music" / "mappy_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
