#!/usr/bin/env python3
"""Generate 128 BPM retro synthwave chiptune background theme for Snake."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 128
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    lead_notes = [
        57, 60, 64, 69, 67, 64, 60, 57,
        53, 57, 60, 65, 64, 60, 57, 53,
        55, 59, 62, 67, 65, 62, 59, 55,
        52, 55, 59, 64, 62, 59, 55, 52,
    ]
    bass_notes = [
        45, 45, 57, 45, 41, 41, 53, 41,
        43, 43, 55, 43, 40, 40, 52, 40,
    ]
    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        start_idx = b * beat_samples

        # 16th Note Lead
        for step in range(4):
            note_idx = (b * 4 + step) % len(lead_notes)
            freq = midi_to_freq(lead_notes[note_idx])
            step_st = start_idx + int(step * (beat_samples / 4.0))

            for s in range(int(beat_samples / 4.0 * 0.78)):
                idx = step_st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 15.0)
                sqr = 1.0 if math.sin(2.0 * math.pi * freq * t) >= 0 else -1.0
                samples[idx] += sqr * env * 0.16

        # Rolling Bass
        for sub in range(2):
            b_idx = (b * 2 + sub) % len(bass_notes)
            freq = midi_to_freq(bass_notes[b_idx])
            sub_st = start_idx + int(sub * (beat_samples / 2.0))

            for s in range(int(beat_samples / 2.0 * 0.82)):
                idx = sub_st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 11.0)
                saw = 2.0 * (t * freq - math.floor(t * freq + 0.5))
                samples[idx] += saw * env * 0.20

    out = bytearray()
    for s in samples:
        clamped = max(-1.0, min(1.0, s))
        ival = int(clamped * 32767.0)
        out.extend(struct.pack("<h", ival))
    return bytes(out)


def main() -> None:
    raw_audio = generate_soundtrack()
    out_dir = Path(__file__).resolve().parent
    out_path = out_dir / "snake_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(raw_audio)

    print(f"Generated {out_path} ({len(raw_audio)} bytes)")


if __name__ == "__main__":
    main()
