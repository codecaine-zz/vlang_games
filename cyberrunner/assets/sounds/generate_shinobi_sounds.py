#!/usr/bin/env python3
"""Generate 9 studio WAV sound effects for Shinobi."""
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


def gen_shuriken() -> list[float]:
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (1400.0 - (i / count) * 800.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 16.0) * 0.85 for i in range(count)]


def gen_slash() -> list[float]:
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    return [((((i * 5432) % 1000) / 500.0 - 1.0) * 0.6 + math.sin(2.0 * math.pi * (900.0 - (i / count) * 600.0) * (i / SAMPLE_RATE)) * 0.4) * math.exp(-i / count * 8.0) * 0.85 for i in range(count)]


def gen_jump() -> list[float]:
    dur = 0.1
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (260.0 + (i / count) * 450.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 12.0) * 0.8 for i in range(count)]


def gen_hit() -> list[float]:
    dur = 0.14
    count = int(dur * SAMPLE_RATE)
    return [((((i * 1234) % 1000) / 500.0 - 1.0) * 0.7 + math.sin(2.0 * math.pi * 320.0 * (i / SAMPLE_RATE)) * 0.3) * math.exp(-i / count * 10.0) * 0.85 for i in range(count)]


def gen_drone_shot() -> list[float]:
    dur = 0.09
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (800.0 - (i / count) * 500.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 14.0) * 0.75 for i in range(count)]


def gen_explode() -> list[float]:
    dur = 0.25
    count = int(dur * SAMPLE_RATE)
    return [((((i * 8765) % 1000) / 500.0 - 1.0) * 0.65 + math.sin(2.0 * math.pi * 180.0 * (i / SAMPLE_RATE)) * 0.35) * math.exp(-i / count * 6.0) * 0.9 for i in range(count)]


def gen_ninjutsu() -> list[float]:
    dur = 0.45
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (150.0 + math.sin(i * 0.04) * 400.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 4.0) * 0.9 for i in range(count)]


def gen_rescue() -> list[float]:
    dur = 0.28
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.08 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 12.0) * 0.75
    return samples


def gen_gameover() -> list[float]:
    dur = 0.4
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (400.0 - (i / count) * 300.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 5.0) * 0.8 for i in range(count)]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "shinobi" / "assets" / "sounds"

    generators = {
        "shinobi_shuriken.wav": gen_shuriken,
        "shinobi_slash.wav": gen_slash,
        "shinobi_jump.wav": gen_jump,
        "shinobi_hit.wav": gen_hit,
        "shinobi_drone_shot.wav": gen_drone_shot,
        "shinobi_explode.wav": gen_explode,
        "shinobi_ninjutsu.wav": gen_ninjutsu,
        "shinobi_rescue.wav": gen_rescue,
        "shinobi_gameover.wav": gen_gameover,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
