#!/usr/bin/env python3
"""Generate 135 BPM thrilling subterranean synth-rock exploration soundtrack for Boulder Dash."""
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

    # Subterranean C minor synth-rock arpeggios
    lead_notes = [
        60, 63, 67, 70, 72, 70, 67, 63,
        58, 62, 65, 68, 70, 68, 65, 62,
        56, 60, 63, 67, 68, 67, 63, 60,
        55, 59, 62, 65, 67, 65, 62, 59,
    ]

    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        start_idx = b * beat_samples

        # 16th-note Crystal Arpeggios
        for sub in range(4):
            note_idx = ((b * 4 + sub) % len(lead_notes))
            freq = midi_to_freq(lead_notes[note_idx] + 12)
            sub_st = start_idx + int(sub * (beat_samples / 4.0))

            for s in range(int(beat_samples / 4.0 * 0.8)):
                idx = sub_st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 22.0)
                sine = math.sin(2.0 * math.pi * freq * t)
                sine2 = math.sin(2.0 * math.pi * (freq * 2.0) * t) * 0.35
                samples[idx] += (sine + sine2) * env * 0.22

        # Driving Subterranean Bass
        root = (48 if (b % 16 < 4) else (46 if (b % 16 < 8) else (44 if (b % 16 < 12) else 43)))
        bfreq = midi_to_freq(root)
        for s in range(int(beat_samples * 0.7)):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 12.0)
            sq = 1.0 if ((t * bfreq) % 1.0) < 0.5 else -1.0
            samples[idx] += sq * env * 0.35

        # Subterranean Thump Kick (every beat)
        for s in range(int(0.08 * SAMPLE_RATE)):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            kfreq = 150.0 * math.exp(-t * 35.0)
            samples[idx] += math.sin(2.0 * math.pi * kfreq * t) * math.exp(-t * 25.0) * 0.4

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
    out_path = out_dir / "boulderdash_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "boulderdash" / "assets" / "music" / "boulderdash_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
