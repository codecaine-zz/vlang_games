#!/usr/bin/env python3
"""Generate cheerful 120 BPM sunny arcade background theme for Flappy Bird."""
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

    # Cheerful ascending melody
    lead_notes = [
        60, 64, 67, 72, 74, 72, 67, 64,
        65, 69, 72, 77, 76, 72, 69, 65,
        67, 71, 74, 79, 77, 74, 71, 67,
        65, 69, 72, 76, 74, 72, 69, 67,
    ]
    bass_notes = [
        48, 48, 60, 48, 53, 53, 65, 53,
        55, 55, 67, 55, 53, 53, 65, 53,
    ]
    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        start_idx = b * beat_samples

        # 16th Note Melody
        for step in range(4):
            note_idx = (b * 4 + step) % len(lead_notes)
            freq = midi_to_freq(lead_notes[note_idx])
            step_st = start_idx + int(step * (beat_samples / 4.0))

            for s in range(int(beat_samples / 4.0 * 0.78)):
                idx = step_st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 16.0)
                sqr = 1.0 if math.sin(2.0 * math.pi * freq * t) >= 0 else -1.0
                samples[idx] += sqr * env * 0.16

        # Bouncy Bass
        for sub in range(2):
            b_idx = (b * 2 + sub) % len(bass_notes)
            freq = midi_to_freq(bass_notes[b_idx])
            sub_st = start_idx + int(sub * (beat_samples / 2.0))

            for s in range(int(beat_samples / 2.0 * 0.8)):
                idx = sub_st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 12.0)
                tone = math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
                samples[idx] += tone * env * 0.22

    out = bytearray()
    for s in samples:
        clamped = max(-1.0, min(1.0, s))
        ival = int(clamped * 32767.0)
        out.extend(struct.pack("<h", ival))
    return bytes(out)


def main() -> None:
    raw_audio = generate_soundtrack()
    out_dir = Path(__file__).resolve().parent
    out_path = out_dir / "flappy_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(raw_audio)

    print(f"Generated {out_path} ({len(raw_audio)} bytes)")


if __name__ == "__main__":
    main()
