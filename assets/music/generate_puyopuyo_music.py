#!/usr/bin/env python3
"""Generate 140 BPM upbeat arcade combo soundtrack for Puyo Puyo."""
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

    # Energetic, melodic arcade combo theme
    lead_notes = [
        74, 76, 77, 81, 79, 77, 76, 72,
        74, 77, 81, 84, 81, 77, 76, 74,
        72, 74, 76, 79, 77, 76, 74, 71,
        72, 76, 79, 83, 81, 79, 77, 76,
    ]

    bass_notes = [
        50, 50, 62, 50, 48, 48, 60, 48,
        47, 47, 59, 47, 45, 45, 57, 45,
    ]
    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        start_idx = b * beat_samples

        # 16th-note Melodic Lead (Kawaii chiptune synth)
        for step in range(4):
            note_idx = (b * 4 + step) % len(lead_notes)
            freq = midi_to_freq(lead_notes[note_idx])
            step_st = start_idx + int(step * (beat_samples / 4.0))

            for s in range(int(beat_samples / 4.0 * 0.82)):
                idx = step_st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 20.0)
                # Pulse / Square wave with vibrato
                vib = math.sin(2.0 * math.pi * 5.5 * t) * 4.0
                tone = (1.0 if math.sin(2.0 * math.pi * (freq + vib) * t) >= 0 else -1.0) * 0.5
                tri = 2.0 * math.asin(math.sin(2.0 * math.pi * freq * t)) / math.pi * 0.5
                samples[idx] += (tone + tri) * env * 0.18

        # 8th-note Slap Bassline
        for sub in range(2):
            b_idx = (b * 2 + sub) % len(bass_notes)
            freq = midi_to_freq(bass_notes[b_idx])
            sub_st = start_idx + int(sub * (beat_samples / 2.0))

            for s in range(int(beat_samples / 2.0 * 0.85)):
                idx = sub_st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 12.0)
                saw = 2.0 * (t * freq - math.floor(t * freq + 0.5))
                tone = saw * env * 0.22
                samples[idx] += tone

        # Arcade Drum Beat (Kick on 1 & 3, Snare & Clack on 2 & 4)
        if b % 2 == 0:
            # Punchy Kick
            for s in range(int(0.08 * SAMPLE_RATE)):
                idx = start_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                k_freq = 140.0 * math.exp(-t * 35.0)
                k_env = math.exp(-t * 30.0)
                samples[idx] += math.sin(2.0 * math.pi * k_freq * t) * k_env * 0.35
        else:
            # Snare + Bubble Hi-Hat
            for s in range(int(0.06 * SAMPLE_RATE)):
                idx = start_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                noise = (((idx * 7919 + s * 13) % 1000) / 500.0 - 1.0)
                env = math.exp(-t * 45.0)
                samples[idx] += noise * env * 0.15

    out = bytearray()
    for s in samples:
        clamped = max(-1.0, min(1.0, s))
        ival = int(clamped * 32767.0)
        out.extend(struct.pack("<h", ival))
    return bytes(out)


def main() -> None:
    raw_audio = generate_soundtrack()
    out_dir = Path(__file__).resolve().parent
    out_path = out_dir / "puyopuyo_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(raw_audio)

    print(f"Generated {out_path} ({len(raw_audio)} bytes)")


if __name__ == "__main__":
    main()
