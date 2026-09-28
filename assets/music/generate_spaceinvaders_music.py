#!/usr/bin/env python3
"""Generate 120 BPM dark arcade space combat soundtrack for Space Invaders."""
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

    # Ominous space synth progression
    synth_notes = [
        48, 51, 55, 58, 60, 58, 55, 51,
        46, 49, 53, 56, 58, 56, 53, 49,
        44, 48, 51, 55, 56, 55, 51, 48,
        43, 46, 50, 53, 55, 53, 50, 46,
    ]

    bass_notes = [
        36, 36, 48, 36, 34, 34, 46, 34,
        32, 32, 44, 32, 31, 31, 43, 31,
    ]
    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        start_idx = b * beat_samples

        # 16th-note Arpeggiated Space Synth
        for step in range(4):
            note_idx = (b * 4 + step) % len(synth_notes)
            freq = midi_to_freq(synth_notes[note_idx])
            step_st = start_idx + int(step * (beat_samples / 4.0))

            for s in range(int(beat_samples / 4.0 * 0.78)):
                idx = step_st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 16.0)
                saw = 2.0 * (t * freq - math.floor(t * freq + 0.5))
                pulse = 1.0 if math.sin(2.0 * math.pi * freq * t) >= 0.2 else -1.0
                samples[idx] += (saw * 0.4 + pulse * 0.6) * env * 0.16

        # 8th-note Sub Bass
        for sub in range(2):
            b_idx = (b * 2 + sub) % len(bass_notes)
            freq = midi_to_freq(bass_notes[b_idx])
            sub_st = start_idx + int(sub * (beat_samples / 2.0))

            for s in range(int(beat_samples / 2.0 * 0.85)):
                idx = sub_st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 9.0)
                tone = math.sin(2.0 * math.pi * freq * t) * env * 0.28
                samples[idx] += tone

        # Cyber Kick on beat
        if b % 2 == 0:
            for s in range(int(0.08 * SAMPLE_RATE)):
                idx = start_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                k_freq = 120.0 * math.exp(-t * 30.0)
                k_env = math.exp(-t * 24.0)
                samples[idx] += math.sin(2.0 * math.pi * k_freq * t) * k_env * 0.32
        else:
            for s in range(int(0.05 * SAMPLE_RATE)):
                idx = start_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                noise = (((idx * 6547 + s * 19) % 1000) / 500.0 - 1.0)
                env = math.exp(-t * 50.0)
                samples[idx] += noise * env * 0.12

    out = bytearray()
    for s in samples:
        clamped = max(-1.0, min(1.0, s))
        ival = int(clamped * 32767.0)
        out.extend(struct.pack("<h", ival))
    return bytes(out)


def main() -> None:
    raw_audio = generate_soundtrack()
    out_dir = Path(__file__).resolve().parent
    out_path = out_dir / "spaceinvaders_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(raw_audio)

    print(f"Generated {out_path} ({len(raw_audio)} bytes)")


if __name__ == "__main__":
    main()
