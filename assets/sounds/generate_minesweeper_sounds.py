#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Minesweeper."""
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


def gen_click() -> list[float]:
    # Tactile mechanical tile click
    dur = 0.05
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 950.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 35.0) * 0.7 for i in range(count)]


def gen_reveal() -> list[float]:
    # Clean tile reveal chime
    dur = 0.1
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 659.25 * (i / SAMPLE_RATE)) * math.exp(-i / count * 15.0) * 0.65 for i in range(count)]


def gen_flag() -> list[float]:
    # Flag plant snap
    dur = 0.07
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 420.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 22.0) * 0.75 for i in range(count)]


def gen_chord() -> list[float]:
    # Fast multi-tile auto reveal whoosh
    dur = 0.2
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99]
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = int(idx * 0.04 * SAMPLE_RATE)
        for s in range(int(0.12 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 14.0) * 0.5
    return samples


def gen_explode() -> list[float]:
    # Booming mine detonation explosion
    dur = 0.6
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 777.7) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 4.5) * 0.9 for i in range(count)]


def gen_win() -> list[float]:
    # Victory fanfare jingle
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


def gen_lose() -> list[float]:
    # Defeat descent sound
    dur = 0.55
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (440.0 - (i / count) * 260.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 3.5) * 0.75 for i in range(count)]


def gen_tick() -> list[float]:
    # Clock second tick
    dur = 0.03
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 1200.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 40.0) * 0.5 for i in range(count)]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "minesweeper" / "assets" / "sounds"

    generators = {
        "minesweeper_click.wav": gen_click,
        "minesweeper_reveal.wav": gen_reveal,
        "minesweeper_flag.wav": gen_flag,
        "minesweeper_chord.wav": gen_chord,
        "minesweeper_explode.wav": gen_explode,
        "minesweeper_win.wav": gen_win,
        "minesweeper_lose.wav": gen_lose,
        "minesweeper_tick.wav": gen_tick,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
