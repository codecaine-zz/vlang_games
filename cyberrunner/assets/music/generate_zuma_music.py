#!/usr/bin/env python3
"""Generate 130 BPM exotic tribal Aztec jungle percussion soundtrack for Zuma Deluxe."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 130
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    # Exotic Aztec Mayan pentatonic progression: Dm - Gm - Bb - A7
    chords = [
        [62, 65, 69, 74],  # Dm
        [67, 70, 74, 79],  # Gm
        [58, 62, 65, 70],  # Bb
        [57, 61, 64, 69],  # A7
    ]

    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        chord = chords[(b // 4) % len(chords)]
        start_idx = b * beat_samples

        # Wooden Marimba / Pan Flute arpeggios
        for note_idx, note in enumerate(chord):
            freq = midi_to_freq(note)
            st = start_idx + int(note_idx * (beat_samples / 4.0))

            for s in range(int(beat_samples * 0.75)):
                idx = st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 10.0)
                sine = math.sin(2.0 * math.pi * freq * t)
                sine2 = math.sin(2.0 * math.pi * (freq * 2.0) * t) * 0.4
                samples[idx] += (sine + sine2) * env * 0.35

        # Tribal Log Drum / Bongo Percussion
        for s in range(int(beat_samples * 0.5)):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 16.0)
            drum_freq = 90.0 if (b % 2 == 0) else 135.0
            log = math.sin(2.0 * math.pi * drum_freq * t)
            samples[idx] += log * env * 0.4

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
    out_path = out_dir / "zuma_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "zuma" / "assets" / "music" / "zuma_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
