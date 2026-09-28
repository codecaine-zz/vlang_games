#!/usr/bin/env python3
"""Generate 118 BPM calm cerebral ambient puzzle soundtrack for Minesweeper."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 118
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    # Chill, contemplative chord progression in A minor
    chords = [
        [57, 60, 64, 69],  # Am
        [53, 57, 60, 65],  # F
        [55, 59, 62, 67],  # G
        [52, 55, 59, 64],  # Em
    ]

    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        chord = chords[(b // 4) % len(chords)]
        start_idx = b * beat_samples

        for note_idx, note in enumerate(chord):
            freq = midi_to_freq(note)
            st = start_idx + int(note_idx * (beat_samples / 4.0))

            for s in range(int(beat_samples * 0.9)):
                idx = st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 3.5)
                phase = (t * freq) % 1.0
                sine = math.sin(2.0 * math.pi * freq * t)
                samples[idx] += sine * env * 0.25

        # Warm sub bass
        if b % 4 == 0:
            bn = chord[0] - 24
            bfreq = midi_to_freq(bn)
            for s in range(int(beat_samples * 3.8)):
                idx = start_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 1.5)
                phase = (t * bfreq) % 1.0
                sine = math.sin(2.0 * math.pi * bfreq * t)
                samples[idx] += sine * env * 0.35

    out = bytearray()
    for val in samples:
        clamped = max(-1.0, min(1.0, val * 0.75))
        ival = int(clamped * 32767.0)
        out.extend(struct.pack("<h", ival))
    return bytes(out)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    pcm_data = generate_soundtrack()
    out_dir = root / "assets" / "music"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "minesweeper_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "minesweeper" / "assets" / "music" / "minesweeper_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
