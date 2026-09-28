#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Bomberman."""
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


def gen_place() -> list[float]:
    # Bomb placement thud
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (180.0 - (i / count) * 80.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.7 for i in range(count)]


def gen_explode() -> list[float]:
    # Massive fiery detonation blast
    dur = 0.55
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 777.7) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 5.0) * 0.9 for i in range(count)]


def gen_powerup() -> list[float]:
    # Item pickup ascending chime
    dur = 0.3
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50]
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


def gen_walk() -> list[float]:
    # Footstep tap
    dur = 0.05
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 123.4) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 30.0) * 0.4 for i in range(count)]


def gen_kick() -> list[float]:
    # Sliding bomb kick whoosh
    dur = 0.2
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (300.0 + (i / count) * 300.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.6 for i in range(count)]


def gen_win() -> list[float]:
    # Victory jingle
    dur = 0.65
    count = int(dur * SAMPLE_RATE)
    notes = [440.0, 554.37, 659.25, 880.0]
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
    # Player caught in explosion sound
    dur = 0.7
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (500.0 - (i / count) * 350.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 3.5) * 0.8 for i in range(count)]


def gen_fuse() -> list[float]:
    # Hissing fuse spark
    dur = 0.15
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 999.9) % 1.0) * 2.0 - 1.0) * 0.3 for i in range(count)]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "bomberman" / "assets" / "sounds"

    generators = {
        "bomberman_place.wav": gen_place,
        "bomberman_explode.wav": gen_explode,
        "bomberman_powerup.wav": gen_powerup,
        "bomberman_walk.wav": gen_walk,
        "bomberman_kick.wav": gen_kick,
        "bomberman_win.wav": gen_win,
        "bomberman_die.wav": gen_die,
        "bomberman_fuse.wav": gen_fuse,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
