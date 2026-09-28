#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Peggle."""
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
    # Cannon launch thud
    dur = 0.14
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (180.0 - (i / count) * 80.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.75 for i in range(count)]


def gen_hit() -> list[float]:
    # Crystal xylophone peg chime
    dur = 0.18
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 880.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 14.0) * 0.8 for i in range(count)]


def gen_orange() -> list[float]:
    # Bright high resonance chime
    dur = 0.25
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 1318.51 * (i / SAMPLE_RATE)) * math.exp(-i / count * 10.0) * 0.85 for i in range(count)]


def gen_bucket() -> list[float]:
    # Free ball bucket catch jingle
    dur = 0.45
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50]
    step = int(dur / len(notes) * SAMPLE_RATE)
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.18 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 9.0) * 0.65
    return samples


def gen_fall() -> list[float]:
    # Peg crumble dissolution pop
    dur = 0.1
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 555.5) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 18.0) * 0.7 for i in range(count)]


def gen_fever() -> list[float]:
    # Extreme Fever fanfare (Ode to Joy triumphant blast)
    dur = 0.8
    count = int(dur * SAMPLE_RATE)
    notes = [587.33, 587.33, 659.25, 739.99, 739.99, 659.25, 587.33]
    step = int(dur / len(notes) * SAMPLE_RATE)
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.18 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 6.0) * 0.65
    return samples


def gen_win() -> list[float]:
    # Victory stage clear
    dur = 0.7
    count = int(dur * SAMPLE_RATE)
    notes = [440.0, 554.37, 659.25, 880.0]
    step = int(dur / len(notes) * SAMPLE_RATE)
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.22 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 7.0) * 0.65
    return samples


def gen_lose() -> list[float]:
    # Ball lost descent
    dur = 0.6
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (380.0 - (i / count) * 240.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 3.2) * 0.75 for i in range(count)]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "peggle" / "assets" / "sounds"

    generators = {
        "peggle_launch.wav": gen_launch,
        "peggle_hit.wav": gen_hit,
        "peggle_orange.wav": gen_orange,
        "peggle_bucket.wav": gen_bucket,
        "peggle_fall.wav": gen_fall,
        "peggle_fever.wav": gen_fever,
        "peggle_win.wav": gen_win,
        "peggle_lose.wav": gen_lose,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
