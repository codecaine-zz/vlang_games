#!/usr/bin/env python3
"""Generate studio WAV sound effects for Bejeweled Classic HD."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    out = bytearray()
    for s in samples:
        clamped = max(-1.0, min(1.0, s))
        ival = int(clamped * 32767.0)
        out.extend(struct.pack("<h", ival))
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(bytes(out))


def gen_swap() -> list[float]:
    # Smooth crystal tile slide click
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (750.0 + (i / count) * 450.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 15.0) * 0.75 for i in range(count)]


def gen_badswap() -> list[float]:
    # Rejection spring click
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (320.0 - math.sin(i * 0.05) * 80.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 10.0) * 0.7 for i in range(count)]


def gen_match() -> list[float]:
    # Crisp crystal shattering chime
    dur = 0.2
    count = int(dur * SAMPLE_RATE)
    return [(math.sin(2.0 * math.pi * 1046.50 * (i / SAMPLE_RATE)) * 0.6 + math.sin(2.0 * math.pi * 2093.0 * (i / SAMPLE_RATE)) * 0.4) * math.exp(-i / count * 7.0) * 0.85 for i in range(count)]


def gen_combo() -> list[float]:
    # Rising cascade harmonic chime
    dur = 0.35
    count = int(dur * SAMPLE_RATE)
    notes = [659.25, 830.61, 1046.50, 1318.51]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.12 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 9.0) * 0.7
    return samples


def gen_flame() -> list[float]:
    # Flame gem explosion roar
    dur = 0.45
    count = int(dur * SAMPLE_RATE)
    return [((((i * 4321) % 1000) / 500.0 - 1.0) * 0.5 + math.sin(2.0 * math.pi * (250.0 - (i / count) * 180.0) * (i / SAMPLE_RATE)) * 0.5) * math.exp(-i / count * 5.0) * 0.9 for i in range(count)]


def gen_star() -> list[float]:
    # Star gem hyper laser beam
    dur = 0.5
    count = int(dur * SAMPLE_RATE)
    return [(math.sin(2.0 * math.pi * (1400.0 - (i / count) * 800.0) * (i / SAMPLE_RATE)) * 0.6 + math.sin(2.0 * math.pi * (700.0 + math.sin(i * 0.08) * 300.0) * (i / SAMPLE_RATE)) * 0.4) * math.exp(-i / count * 4.0) * 0.85 for i in range(count)]


def gen_hypercube() -> list[float]:
    # Hypercube lightning disintegration
    dur = 0.65
    count = int(dur * SAMPLE_RATE)
    return [(math.sin(2.0 * math.pi * (880.0 + math.sin(i * 0.15) * 440.0) * (i / SAMPLE_RATE)) * 0.6 + (((i * 8765) % 1000) / 500.0 - 1.0) * 0.4) * math.exp(-i / count * 3.5) * 0.9 for i in range(count)]


def gen_levelup() -> list[float]:
    # Level Up celebratory fanfare
    dur = 0.75
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.18 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 7.0) * 0.75
    return samples


def gen_nomoves() -> list[float]:
    # No more moves dramatic warning
    dur = 0.55
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (300.0 - (i / count) * 200.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 4.0) * 0.8 for i in range(count)]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "bejeweled" / "assets" / "sounds"

    generators = {
        "bejeweled_swap.wav": gen_swap,
        "bejeweled_badswap.wav": gen_badswap,
        "bejeweled_match.wav": gen_match,
        "bejeweled_combo.wav": gen_combo,
        "bejeweled_flame.wav": gen_flame,
        "bejeweled_star.wav": gen_star,
        "bejeweled_hypercube.wav": gen_hypercube,
        "bejeweled_levelup.wav": gen_levelup,
        "bejeweled_nomoves.wav": gen_nomoves,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
