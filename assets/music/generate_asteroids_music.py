#!/usr/bin/env python3
"""Generate 140 BPM intense deep-space synthwave soundtrack with accelerating arcade heartbeat pulse for Asteroids."""
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

    # Deep space darksynth minor arpeggio
    notes = [
        45, 48, 52, 55, 57, 55, 52, 48,
        43, 47, 50, 53, 55, 53, 50, 47,
        41, 45, 48, 52, 53, 52, 48, 45,
        40, 43, 47, 50, 52, 50, 47, 43,
    ]

    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        start_idx = b * beat_samples

        # 16th-note synth leads
        for sub in range(4):
            n_idx = (b * 4 + sub) % len(notes)
            freq = midi_to_freq(notes[n_idx] + 12)
            sub_st = start_idx + int(sub * (beat_samples / 4.0))

            for s in range(int(beat_samples / 4.0 * 0.8)):
                idx = sub_st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 24.0)
                saw = 2.0 * (t * freq - math.floor(t * freq + 0.5))
                samples[idx] += saw * env * 0.22

        # Arcade Heartbeat Sub-Bass Thump (every beat, alternating frequencies)
        hfreq = 90.0 if (b % 2 == 0) else 75.0
        for s in range(int(0.12 * SAMPLE_RATE)):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            sine = math.sin(2.0 * math.pi * hfreq * t)
            samples[idx] += sine * math.exp(-t * 18.0) * 0.45

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
    out_path = out_dir / "asteroids_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "asteroids" / "assets" / "music" / "asteroids_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
