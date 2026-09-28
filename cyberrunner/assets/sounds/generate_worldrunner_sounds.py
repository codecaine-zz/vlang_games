#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for WorldRunner."""
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
    dur = 0.22
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (180.0 + (i / count) * 420.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.7 for i in range(count)]


def gen_laser() -> list[float]:
    dur = 0.16
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (950.0 - (i / count) * 650.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 8.0) * 0.8 for i in range(count)]


def gen_collect() -> list[float]:
    dur = 0.25
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        freq = 660.0 if i < count // 2 else 990.0
        samples.append(math.sin(2.0 * math.pi * freq * t) * (1.0 - i / count) * 0.7)
    return samples


def gen_hit() -> list[float]:
    dur = 0.3
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 123.45) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 9.0) * 0.85 for i in range(count)]


def gen_boss() -> list[float]:
    dur = 0.5
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (85.0 + math.sin(i / SAMPLE_RATE * 30.0) * 25.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 4.0) * 0.8 for i in range(count)]


def gen_warp() -> list[float]:
    dur = 0.4
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (200.0 + math.sin(i / SAMPLE_RATE * 50.0) * 180.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.75 for i in range(count)]


def gen_explosion() -> list[float]:
    dur = 0.45
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 888.1) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 6.0) * 0.9 for i in range(count)]


def gen_boost() -> list[float]:
    dur = 0.28
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (320.0 + (i / count) * 380.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 4.0) * 0.75 for i in range(count)]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "worldrunner" / "assets" / "sounds"

    generators = {
        "worldrunner_jump.wav": gen_jump,
        "worldrunner_laser.wav": gen_laser,
        "worldrunner_collect.wav": gen_collect,
        "worldrunner_hit.wav": gen_hit,
        "worldrunner_boss.wav": gen_boss,
        "worldrunner_warp.wav": gen_warp,
        "worldrunner_explosion.wav": gen_explosion,
        "worldrunner_boost.wav": gen_boost,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
