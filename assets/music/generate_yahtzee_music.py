#!/usr/bin/env python3
"""Generate relaxing 110 BPM casino lounge jazz background music for Yahtzee."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 110
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    # Jazz chords (Cmaj7, Am7, Dm7, G7)
    chords = [
        [60, 64, 67, 71], # Cmaj7
        [57, 60, 64, 67], # Am7
        [62, 65, 69, 72], # Dm7
        [55, 59, 62, 65], # G7
    ]

    for b in range(total_beats):
        chord = chords[(b // 4) % len(chords)]
        b_idx = int(b * BEAT_DUR * SAMPLE_RATE)
        b_samples = int(BEAT_DUR * 0.9 * SAMPLE_RATE)

        # Electric piano chords
        for n in chord:
            freq = midi_to_freq(n)
            for s in range(b_samples):
                idx = b_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 2.8)
                # Rhodes bell tine + sine fundamental
                tine = math.sin(2.0 * math.pi * (freq * 4.0) * t) * 0.15 * math.exp(-t * 12.0)
                body = math.sin(2.0 * math.pi * freq * t) * 0.35
                samples[idx] += (tine + body) * env * 0.35

        # Walking bassline
        bass_note = chord[0] - 24
        bfreq = midi_to_freq(bass_note)
        for s in range(b_samples):
            idx = b_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 3.5)
            samples[idx] += math.sin(2.0 * math.pi * bfreq * t) * env * 0.45

        # Gentle brushed jazz cymbal
        for s in range(int(0.08 * SAMPLE_RATE)):
            idx = b_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            noise = (math.sin(s * 777.7) % 1.0) * 2.0 - 1.0
            samples[idx] += noise * math.exp(-t * 35.0) * 0.15

    out = bytearray()
    for val in samples:
        clamped = max(-1.0, min(1.0, val * 0.7))
        ival = int(clamped * 32767.0)
        out.extend(struct.pack("<h", ival))
    return bytes(out)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    pcm_data = generate_soundtrack()
    out_dir = root / "assets" / "music"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "yahtzee_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "yahtzee" / "assets" / "music" / "yahtzee_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
