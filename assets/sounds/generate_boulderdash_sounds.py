#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Boulder Dash."""
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


def gen_dig() -> list[float]:
    # Granular crunch digging
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    return [(((i * 12345) % 1000) / 500.0 - 1.0) * math.exp(-i / count * 12.0) * 0.7 for i in range(count)]


def gen_diamond() -> list[float]:
    # Crystal chime
    dur = 0.16
    count = int(dur * SAMPLE_RATE)
    return [(math.sin(2.0 * math.pi * 1760.0 * (i / SAMPLE_RATE)) * 0.6 + math.sin(2.0 * math.pi * 2349.32 * (i / SAMPLE_RATE)) * 0.4) * math.exp(-i / count * 8.0) * 0.85 for i in range(count)]


def gen_boulder() -> list[float]:
    # Deep rock roll & heavy impact
    dur = 0.18
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (140.0 - (i / count) * 80.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 6.0) * 0.85 for i in range(count)]


def gen_explode() -> list[float]:
    # Cavern explosion
    dur = 0.45
    count = int(dur * SAMPLE_RATE)
    return [((((i * 54321) % 1000) / 500.0 - 1.0) * 0.6 + math.sin(2.0 * math.pi * (180.0 - (i / count) * 140.0) * (i / SAMPLE_RATE)) * 0.4) * math.exp(-i / count * 4.5) * 0.9 for i in range(count)]


def gen_door() -> list[float]:
    # Exit unlocked portal chime
    dur = 0.35
    count = int(dur * SAMPLE_RATE)
    notes = [587.33, 739.99, 880.0, 1174.66]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.12 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 10.0) * 0.7
    return samples


def gen_amoeba() -> list[float]:
    # Bubbling slime squelch
    dur = 0.22
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (350.0 + math.sin(i * 0.08) * 150.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 6.0) * 0.75 for i in range(count)]


def gen_die() -> list[float]:
    # Defeat descent
    dur = 0.45
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (450.0 - (i / count) * 350.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 4.0) * 0.85 for i in range(count)]


def gen_win() -> list[float]:
    # Level complete victory fanfare
    dur = 0.65
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50, 1318.51]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.16 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 8.0) * 0.75
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "boulderdash" / "assets" / "sounds"

    generators = {
        "boulderdash_dig.wav": gen_dig,
        "boulderdash_diamond.wav": gen_diamond,
        "boulderdash_boulder.wav": gen_boulder,
        "boulderdash_explode.wav": gen_explode,
        "boulderdash_door.wav": gen_door,
        "boulderdash_amoeba.wav": gen_amoeba,
        "boulderdash_die.wav": gen_die,
        "boulderdash_win.wav": gen_win,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
