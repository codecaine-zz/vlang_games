#!/usr/bin/env python3
"""Generate 115 BPM smooth VIP lounge jazz soundtrack with electric piano, acoustic upright bass, and brushed drums for Pool."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 115
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    # Smooth Jazz Chord Progression (Dm9 - G13 - Cmaj9 - Am9)
    chords = [
        [62, 65, 69, 72, 76],  # Dm9
        [55, 59, 64, 69, 71],  # G13
        [60, 64, 67, 71, 74],  # Cmaj9
        [57, 60, 64, 69, 72],  # Am9
    ]

    bass_notes = [38, 41, 45, 41, 31, 35, 38, 35, 36, 40, 43, 40, 33, 36, 40, 36]
    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        start_idx = b * beat_samples

        # Rhodes Electric Piano Chords (every 4 beats)
        if b % 4 == 0:
            c_idx = (b // 4) % len(chords)
            chord = chords[c_idx]
            for note in chord:
                freq = midi_to_freq(note)
                for s in range(int(beat_samples * 3.5)):
                    idx = start_idx + s
                    if idx >= total_samples:
                        break
                    t = s / SAMPLE_RATE
                    env = math.exp(-t * 2.2)
                    vibrato = math.sin(2.0 * math.pi * 4.5 * t) * 0.008
                    sine = math.sin(2.0 * math.pi * freq * (1.0 + vibrato) * t) + 0.25 * math.sin(4.0 * math.pi * freq * t)
                    samples[idx] += sine * env * 0.12

        # Walking Upright Bass (Quarter notes)
        b_idx = b % len(bass_notes)
        freq = midi_to_freq(bass_notes[b_idx])
        for s in range(int(beat_samples * 0.85)):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 5.0)
            sine = math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
            samples[idx] += sine * env * 0.35

        # Brushed Hi-Hat & Snare Tap
        for s in range(int(0.06 * SAMPLE_RATE)):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            noise = (((s * 3141) % 1000) / 500.0 - 1.0) * math.exp(-t * 40.0) * 0.15
            samples[idx] += noise

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
    out_path = out_dir / "pool_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "pool" / "assets" / "music" / "pool_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
