#!/usr/bin/env python3
"""Generate catchy retro puzzle arcade background music soundtrack for Rodent's Revenge."""
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

    # Playful, bouncy puzzle melody
    melody = [
        72, 74, 76, 79, 76, 74, 72, 69,
        71, 72, 74, 76, 74, 72, 71, 67,
        69, 71, 72, 76, 74, 72, 69, 67,
        69, 72, 76, 79, 81, 79, 76, 72,
    ]

    bass_notes = [
        48, 48, 55, 48, 47, 47, 55, 47,
        45, 45, 52, 45, 43, 43, 50, 43,
    ]
    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        start_idx = b * beat_samples

        # 16th-note Chiptune Lead
        for step in range(4):
            note_idx = (b * 4 + step) % len(melody)
            freq = midi_to_freq(melody[note_idx])
            step_st = start_idx + int(step * (beat_samples / 4.0))

            for s in range(int(beat_samples / 4.0 * 0.8)):
                idx = step_st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 18.0)
                # Pulse / Square wave with soft triangle blend
                sqr = 1.0 if math.sin(2.0 * math.pi * freq * t) >= 0 else -1.0
                tri = 2.0 * math.asin(math.sin(2.0 * math.pi * freq * t)) / math.pi
                tone = (sqr * 0.6 + tri * 0.4) * env * 0.16
                samples[idx] += tone

        # 8th-note Walking Bassline
        for sub in range(2):
            b_idx = (b * 2 + sub) % len(bass_notes)
            freq = midi_to_freq(bass_notes[b_idx])
            sub_st = start_idx + int(sub * (beat_samples / 2.0))

            for s in range(int(beat_samples / 2.0 * 0.85)):
                idx = sub_st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 10.0)
                saw = 2.0 * (t * freq - math.floor(t * freq + 0.5))
                tone = saw * env * 0.22
                samples[idx] += tone

        # Snare / Hi-Hat Percussion on 2 & 4
        if b % 2 == 1:
            for s in range(int(0.06 * SAMPLE_RATE)):
                idx = start_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                noise = (((idx * 9431 + s * 17) % 1000) / 500.0 - 1.0)
                env = math.exp(-t * 55.0)
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
    out_path = out_dir / "rodentsrevenge_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(raw_audio)

    print(f"Generated {out_path} ({len(raw_audio)} bytes)")


if __name__ == "__main__":
    main()
