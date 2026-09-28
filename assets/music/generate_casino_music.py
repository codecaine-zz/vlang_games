#!/usr/bin/env python3
"""Generate smooth 120 BPM jazzy lounge / casino soundtrack for Card Games (War, Texas Hold'em, Blackjack)."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 120
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    # Jazz lounge progression: Cmaj7 - Am7 - Dm7 - G7 - Em7 - A7 - Dm7 - G7
    chords = [
        [60, 64, 67, 71],  # Cmaj7
        [57, 60, 64, 67],  # Am7
        [50, 53, 57, 60],  # Dm7
        [55, 59, 62, 65],  # G7
        [52, 55, 59, 62],  # Em7
        [57, 61, 64, 67],  # A7
        [50, 53, 57, 60],  # Dm7
        [55, 59, 62, 65],  # G7
    ]

    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        chord = chords[(b // 4) % len(chords)]
        start_idx = b * beat_samples

        # Electric Piano / Vibraphone Chords
        for note in chord:
            freq = midi_to_freq(note)
            for s in range(int(beat_samples * 0.85)):
                idx = start_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 4.0)
                sine = math.sin(2.0 * math.pi * freq * t)
                sine2 = math.sin(2.0 * math.pi * (freq * 2.0) * t) * 0.3
                samples[idx] += (sine + sine2) * env * 0.18

        # Walking Acoustic Bass
        bn = chord[0] - 12
        bfreq = midi_to_freq(bn)
        for s in range(int(beat_samples * 0.7)):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 6.0)
            bass = math.sin(2.0 * math.pi * bfreq * t)
            samples[idx] += bass * env * 0.35

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
    out_path = out_dir / "casino_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")

    for g in ["war", "texas", "blackjack"]:
        g_path = root / g / "assets" / "music" / "casino_bgm.wav"
        g_path.parent.mkdir(parents=True, exist_ok=True)
        with wave.open(str(g_path), "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(SAMPLE_RATE)
            wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
