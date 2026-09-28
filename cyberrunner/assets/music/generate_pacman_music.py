#!/usr/bin/env python3
"""Generate authentic 1980 Namco Pac-Man Arcade Ambient Siren Background Audio."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100


def namco_wave(phase: float) -> float:
    p = phase % 1.0
    if p < 0.5:
        return 2.0 * p - 0.5 + 0.2 * math.sin(2.0 * math.pi * p)
    else:
        return 1.5 - 2.0 * p + 0.2 * math.sin(2.0 * math.pi * p)


def generate_arcade_siren() -> bytes:
    # 4 full siren cycles (~3.6 seconds looped)
    cycle_dur = 0.90
    total_cycles = 4
    total_dur = cycle_dur * total_cycles
    total_samples = int(total_dur * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    phase = 0.0
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        cycle_t = (t % cycle_dur) / cycle_dur
        # Authentic siren pitch modulation: rises smoothly from 260Hz to 480Hz
        siren_mod = 0.5 - 0.5 * math.cos(2.0 * math.pi * cycle_t)
        freq = 250.0 + 220.0 * siren_mod
        phase += freq / SAMPLE_RATE
        # Add subtle warmth harmonic
        tone = namco_wave(phase) * 0.28
        samples[i] = tone

    out = bytearray()
    for s in samples:
        clamped = max(-1.0, min(1.0, s))
        ival = int(clamped * 32767.0)
        out.extend(struct.pack("<h", ival))
    return bytes(out)


def main() -> None:
    raw_audio = generate_arcade_siren()
    out_dir = Path(__file__).resolve().parent
    out_path = out_dir / "pacman_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(raw_audio)

    print(f"Generated {out_path} ({len(raw_audio)} bytes)")


if __name__ == "__main__":
    main()
