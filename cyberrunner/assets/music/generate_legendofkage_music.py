#!/usr/bin/env python3
"""Generate 145 BPM authentic feudal Japanese ninja arcade soundtrack for The Legend of Kage."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 145
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    # 64 beats of driving Japanese Insen scale ninja rhythm
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    # Insen / Hirajoshi scale notes: A3(57), Bb3(58), D4(62), E4(64), F4(65), A4(69), Bb4(70), D5(74), E5(76)
    lead_melody = [
        69, 70, 74, 76, 74, 70, 69, 65,
        64, 65, 69, 70, 69, 65, 64, 58,
        57, 58, 62, 64, 65, 64, 62, 58,
        57, 62, 65, 69, 74, 70, 69, 0,
        74, 76, 81, 82, 81, 76, 74, 70,
        69, 70, 74, 76, 74, 70, 69, 65,
        64, 65, 69, 70, 74, 76, 81, 82,
        86, 82, 81, 76, 74, 69, 57, 0,
    ]

    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        start_idx = b * beat_samples
        note = lead_melody[b % len(lead_melody)]

        # Shakuhachi / Shinobue Flute Lead
        if note > 0:
            freq = midi_to_freq(note)
            for s in range(int(beat_samples * 0.9)):
                idx = start_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.sin((s / (beat_samples * 0.9)) * math.pi)
                # Overtones
                f1 = math.sin(2.0 * math.pi * freq * t)
                f2 = math.sin(2.0 * math.pi * (freq * 2.0) * t) * 0.35
                f3 = math.sin(2.0 * math.pi * (freq * 3.0) * t) * 0.15
                breath = (math.sin(s * 73.1) % 1.0 - 0.5) * 0.12
                samples[idx] += (f1 + f2 + f3 + breath) * env * 0.38

        # Shamisen pluck rhythm
        sham_note = 57 if (b % 4 < 2) else 58
        sham_freq = midi_to_freq(sham_note)
        for s in range(int(beat_samples * 0.45)):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 22.0)
            saw = ((t * sham_freq) % 1.0) * 2.0 - 1.0
            samples[idx] += saw * env * 0.3

        # Taiko Drum on beats 0 and 2
        if b % 2 == 0:
            for s in range(int(beat_samples * 0.8)):
                idx = start_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 9.0)
                taiko = math.sin(2.0 * math.pi * 75.0 * t) * 0.55
                samples[idx] += taiko * env * 0.45

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
    out_path = out_dir / "legendofkage_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "legendofkage" / "assets" / "music" / "legendofkage_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
