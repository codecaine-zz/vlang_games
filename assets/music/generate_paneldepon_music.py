#!/usr/bin/env python3
"""Generate 138 BPM energetic fairy pop soundtrack for Panel de Pon / Puzzle League."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 138
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    # Upbeat Japanese Puzzle pop progression: C - G/B - Am - F - G
    chords = [
        [60, 64, 67, 72],  # C
        [59, 62, 67, 71],  # G/B
        [57, 60, 64, 69],  # Am
        [53, 57, 60, 65],  # F
        [55, 59, 62, 67],  # G
        [57, 60, 64, 69],  # Am
        [53, 57, 60, 65],  # F
        [55, 59, 62, 67],  # G
    ]

    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        chord = chords[(b // 4) % len(chords)]
        start_idx = b * beat_samples

        # Bell Arpeggio
        for note_idx, note in enumerate(chord):
            freq = midi_to_freq(note + 12)
            st = start_idx + int(note_idx * (beat_samples / 4.0))

            for s in range(int(beat_samples * 0.7)):
                idx = st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 12.0)
                sine = math.sin(2.0 * math.pi * freq * t)
                sine2 = math.sin(2.0 * math.pi * (freq * 2.0) * t) * 0.3
                samples[idx] += (sine + sine2) * env * 0.3

        # Bouncy Synth Bassline
        bn = chord[0] - 12
        bfreq = midi_to_freq(bn)
        for s in range(int(beat_samples * 0.5)):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 14.0)
            sq = 1.0 if ((t * bfreq) % 1.0) < 0.5 else -1.0
            samples[idx] += sq * env * 0.35

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
    out_path = out_dir / "paneldepon_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "paneldepon" / "assets" / "music" / "paneldepon_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
