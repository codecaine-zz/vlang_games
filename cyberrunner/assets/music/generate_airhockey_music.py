#!/usr/bin/env python3
"""Generate 135 BPM fast-paced arcade electronic sports soundtrack for Air Hockey."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 135
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    melody = [
        65, 68, 72, 75, 77, 75, 72, 68,
        63, 67, 70, 74, 75, 74, 70, 67,
        61, 65, 68, 72, 73, 72, 68, 65,
        63, 67, 70, 74, 75, 77, 80, 82,
    ]

    bass_notes = [41, 41, 53, 41, 39, 39, 51, 39, 37, 37, 49, 37, 39, 39, 51, 39]
    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        start_idx = b * beat_samples

        # 16th-note Synth Lead
        for step in range(4):
            note_idx = (b * 4 + step) % len(melody)
            freq = midi_to_freq(melody[note_idx])
            step_st = start_idx + int(step * (beat_samples / 4.0))

            for s in range(int(beat_samples / 4.0 * 0.82)):
                idx = step_st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 22.0)
                saw = 2.0 * (t * freq - math.floor(t * freq + 0.5))
                samples[idx] += saw * env * 0.18

        # 8th-note Driving Bassline
        for sub in range(2):
            b_idx = (b * 2 + sub) % len(bass_notes)
            freq = midi_to_freq(bass_notes[b_idx])
            sub_st = start_idx + int(sub * (beat_samples / 2.0))

            for s in range(int(beat_samples / 2.0 * 0.85)):
                idx = sub_st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 14.0)
                sine = (math.sin(2.0 * math.pi * freq * t) + 0.35 * math.sin(4.0 * math.pi * freq * t)) * env * 0.30
                samples[idx] += sine

        # 909 Kick & Snare Beat
        for s in range(int(0.09 * SAMPLE_RATE)):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            k_freq = 150.0 * math.exp(-t * 30.0)
            samples[idx] += math.sin(2.0 * math.pi * k_freq * t) * math.exp(-t * 18.0) * 0.45

        if b % 2 == 1:
            for s in range(int(0.12 * SAMPLE_RATE)):
                idx = start_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                noise = (((s * 7919) % 1000) / 500.0 - 1.0) * math.exp(-t * 24.0) * 0.25
                samples[idx] += noise

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
    out_path = out_dir / "airhockey_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "airhockey" / "assets" / "music" / "airhockey_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
