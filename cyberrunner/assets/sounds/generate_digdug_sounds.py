#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Dig Dug."""
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


def gen_step() -> list[float]:
    # Digging dirt crunch
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 333.3) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 15.0) * 0.5 for i in range(count)]


def gen_pump() -> list[float]:
    # Air pump squeak/click
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (600.0 + (i / count) * 400.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.7 for i in range(count)]


def gen_pop() -> list[float]:
    # Enemy inflation pop explosion
    dur = 0.35
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 555.5) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 6.0) * 0.85 for i in range(count)]


def gen_rockfall() -> list[float]:
    # Heavy stone boulder crashing down
    dur = 0.45
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        thud = math.sin(2.0 * math.pi * 90.0 * t) * math.exp(-t * 10.0)
        noise = ((math.sin(i * 123.1) % 1.0) * 2.0 - 1.0) * math.exp(-t * 6.0) * 0.5
        samples.append(thud + noise)
    return samples


def gen_fire() -> list[float]:
    # Fygar horizontal dragon breath whoosh
    dur = 0.4
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 888.8) % 1.0) * 2.0 - 1.0) * math.sin(math.pi * (i / count)) * 0.65 for i in range(count)]


def gen_ghost() -> list[float]:
    # Ghost phase through dirt warble
    dur = 0.3
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (520.0 + math.sin(i / SAMPLE_RATE * 40.0) * 80.0) * (i / SAMPLE_RATE)) * 0.6 for i in range(count)]


def gen_bonus() -> list[float]:
    # Bonus vegetable item pickup jingle
    dur = 0.35
    count = int(dur * SAMPLE_RATE)
    notes = [659.25, 783.99, 1046.50]
    step = int(dur / len(notes) * SAMPLE_RATE)
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.15 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 10.0) * 0.65
    return samples


def gen_death() -> list[float]:
    # Taizo Hori squished defeat tone
    dur = 0.6
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (440.0 - (i / count) * 280.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 4.0) * 0.75 for i in range(count)]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "digdug" / "assets" / "sounds"

    generators = {
        "digdug_step.wav": gen_step,
        "digdug_pump.wav": gen_pump,
        "digdug_pop.wav": gen_pop,
        "digdug_rockfall.wav": gen_rockfall,
        "digdug_fire.wav": gen_fire,
        "digdug_ghost.wav": gen_ghost,
        "digdug_bonus.wav": gen_bonus,
        "digdug_death.wav": gen_death,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
