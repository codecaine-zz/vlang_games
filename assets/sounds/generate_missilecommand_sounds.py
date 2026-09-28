#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Missile Command."""
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


def gen_launch() -> list[float]:
    # Interceptor missile launch whistle
    dur = 0.2
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (300.0 + (i / count) * 900.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.75 for i in range(count)]


def gen_blast() -> list[float]:
    # Massive expanding flak explosion
    dur = 0.5
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 441.1) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 5.0) * 0.9 for i in range(count)]


def gen_cityhit() -> list[float]:
    # Skyscraper collapse explosion
    dur = 0.65
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        noise = (math.sin(i * 123.4) % 1.0) * 2.0 - 1.0
        low = math.sin(2.0 * math.pi * 65.0 * t)
        samples.append((noise * 0.7 + low * 0.3) * math.exp(-t * 4.5))
    return samples


def gen_silohit() -> list[float]:
    # Silo battery bunker destroyed
    dur = 0.55
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 888.2) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 6.0) * 0.85 for i in range(count)]


def gen_ufo() -> list[float]:
    # High altitude enemy bomber/satellite warble
    dur = 0.4
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (440.0 + math.sin(i / SAMPLE_RATE * 30.0) * 80.0) * (i / SAMPLE_RATE)) * 0.6 for i in range(count)]


def gen_warning() -> list[float]:
    # Incoming ICBM cluster alarm
    dur = 0.25
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 880.0 * (i / SAMPLE_RATE)) * (1.0 if (i // 1000) % 2 == 0 else 0.0) * 0.7 for i in range(count)]


def gen_roundclear() -> list[float]:
    # Wave defended fanfare
    dur = 0.6
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
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 9.0) * 0.65
    return samples


def gen_gameover() -> list[float]:
    # Nuclear annihilation sad tone
    dur = 0.8
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (300.0 - (i / count) * 180.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 3.0) * 0.8 for i in range(count)]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "missilecommand" / "assets" / "sounds"

    generators = {
        "missilecommand_launch.wav": gen_launch,
        "missilecommand_blast.wav": gen_blast,
        "missilecommand_cityhit.wav": gen_cityhit,
        "missilecommand_silohit.wav": gen_silohit,
        "missilecommand_ufo.wav": gen_ufo,
        "missilecommand_warning.wav": gen_warning,
        "missilecommand_roundclear.wav": gen_roundclear,
        "missilecommand_gameover.wav": gen_gameover,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
