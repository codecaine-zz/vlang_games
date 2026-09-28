#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Mario Bros."""
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


def gen_jump() -> list[float]:
    dur = 0.16
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (240.0 + (i / count) * 480.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.75 for i in range(count)]


def gen_bump() -> list[float]:
    # Hitting floor platform from underneath (dull thud)
    dur = 0.18
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (160.0 - (i / count) * 80.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 10.0) * 0.85 for i in range(count)]


def gen_flip() -> list[float]:
    # Stunned enemy flipped upside down
    dur = 0.22
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (380.0 + math.sin(i / SAMPLE_RATE * 60.0) * 120.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.75 for i in range(count)]


def gen_kick() -> list[float]:
    # Kicking flipped turtle / crab off stage
    dur = 0.28
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        thud = math.sin(2.0 * math.pi * 120.0 * t) * math.exp(-t * 20.0)
        whistle = math.sin(2.0 * math.pi * (300.0 + (i / count) * 600.0) * t) * (1.0 - i / count) * 0.5
        samples.append((thud + whistle) * 0.8)
    return samples


def gen_coin() -> list[float]:
    # Classic two-tone high ding (B5 -> E6)
    dur = 0.3
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        freq = 987.77 if i < count // 4 else 1318.51
        samples.append(math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 8.0) * 0.8)
    return samples


def gen_pow() -> list[float]:
    # Massive POW screen shake boom
    dur = 0.45
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 321.1) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 5.0) * 0.9 for i in range(count)]


def gen_pipe() -> list[float]:
    # Enemy descending / popping out of pipe
    dur = 0.24
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (500.0 - (i / count) * 250.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.7 for i in range(count)]


def gen_death() -> list[float]:
    # Plumber defeat sad jingle
    dur = 0.6
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 493.88, 466.16, 440.00]
    step = int(dur / len(notes) * SAMPLE_RATE)
    samples = [0.0] * count
    for n_idx, freq in enumerate(notes):
        st = n_idx * step
        for s in range(int(0.2 * SAMPLE_RATE)):
            idx = st + s
            if idx >= count:
                break
            t = s / SAMPLE_RATE
            samples[idx] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 8.0) * 0.65
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "mariobros" / "assets" / "sounds"

    generators = {
        "mariobros_jump.wav": gen_jump,
        "mariobros_bump.wav": gen_bump,
        "mariobros_flip.wav": gen_flip,
        "mariobros_kick.wav": gen_kick,
        "mariobros_coin.wav": gen_coin,
        "mariobros_pow.wav": gen_pow,
        "mariobros_pipe.wav": gen_pipe,
        "mariobros_death.wav": gen_death,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
