#!/usr/bin/env python3
"""Generate 6 studio WAV sound effects for Sokoban."""
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
    dur = 0.05
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 320.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 20.0) * 0.5 for i in range(count)]


def gen_push() -> list[float]:
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    return [((((i * 4321) % 1000) / 500.0 - 1.0) * 0.6 + math.sin(2.0 * math.pi * 140.0 * (i / SAMPLE_RATE)) * 0.4) * math.exp(-i / count * 10.0) * 0.7 for i in range(count)]


def gen_goal() -> list[float]:
    dur = 0.22
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.07 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 16.0) * 0.7
    return samples


def gen_undo() -> list[float]:
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (500.0 - (i / count) * 300.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 15.0) * 0.6 for i in range(count)]


def gen_win() -> list[float]:
    dur = 0.45
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.12 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += (math.sin(2.0 * math.pi * freq * t) + 0.2 * math.sin(4.0 * math.pi * freq * t)) * math.exp(-t * 8.0) * 0.75
    return samples


def gen_reset() -> list[float]:
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (200.0 + (i / count) * 400.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 18.0) * 0.6 for i in range(count)]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "sokoban" / "assets" / "sounds"

    generators = {
        "sokoban_step.wav": gen_step,
        "sokoban_push.wav": gen_push,
        "sokoban_goal.wav": gen_goal,
        "sokoban_undo.wav": gen_undo,
        "sokoban_win.wav": gen_win,
        "sokoban_reset.wav": gen_reset,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
