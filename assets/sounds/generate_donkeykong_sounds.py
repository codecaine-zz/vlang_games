#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Donkey Kong."""
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
    # Jumpman leap boing
    dur = 0.15
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (260.0 + (i / count) * 440.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.75 for i in range(count)]


def gen_walk() -> list[float]:
    # Footstep tap
    dur = 0.05
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 123.4) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 30.0) * 0.5 for i in range(count)]


def gen_hammer() -> list[float]:
    # Hammer swinging melody
    dur = 0.4
    count = int(dur * SAMPLE_RATE)
    notes = [659.25, 783.99, 659.25, 523.25]
    step = int(dur / len(notes) * SAMPLE_RATE)
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.12 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 12.0) * 0.65
    return samples


def gen_barrel() -> list[float]:
    # Barrel roll bounce thud
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 120.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 20.0) * 0.7 for i in range(count)]


def gen_climb() -> list[float]:
    # Ladder rung climb tap
    dur = 0.04
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 440.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 35.0) * 0.5 for i in range(count)]


def gen_roar() -> list[float]:
    # Donkey Kong chest thumping roar
    dur = 0.3
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 88.8) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 5.0) * 0.75 for i in range(count)]


def gen_win() -> list[float]:
    # Pauline rescue fanfare
    dur = 0.65
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50]
    step = int(dur / len(notes) * SAMPLE_RATE)
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.2 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 8.0) * 0.65
    return samples


def gen_die() -> list[float]:
    # Jumpman defeat death jingle
    dur = 0.7
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (500.0 - (i / count) * 350.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 3.5) * 0.8 for i in range(count)]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "donkeykong" / "assets" / "sounds"

    generators = {
        "donkeykong_jump.wav": gen_jump,
        "donkeykong_walk.wav": gen_walk,
        "donkeykong_hammer.wav": gen_hammer,
        "donkeykong_barrel.wav": gen_barrel,
        "donkeykong_climb.wav": gen_climb,
        "donkeykong_roar.wav": gen_roar,
        "donkeykong_win.wav": gen_win,
        "donkeykong_die.wav": gen_die,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
