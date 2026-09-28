#!/usr/bin/env python3
"""Generate studio WAV sound effects for Air Hockey."""
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


def gen_mallet_hit() -> list[float]:
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    return [(math.sin(2.0 * math.pi * 950.0 * (i / SAMPLE_RATE)) * 0.7 + (((i * 9431) % 1000) / 500.0 - 1.0) * 0.3) * math.exp(-i / count * 35.0) * 0.9 for i in range(count)]


def gen_rail_bounce() -> list[float]:
    dur = 0.06
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 420.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 40.0) * 0.75 for i in range(count)]


def gen_goal_horn() -> list[float]:
    dur = 0.75
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(2.0 * math.pi * 293.66 * (i / SAMPLE_RATE)) + math.sin(2.0 * math.pi * 349.23 * (i / SAMPLE_RATE)) + 0.8 * math.sin(2.0 * math.pi * 440.0 * (i / SAMPLE_RATE))) / 2.8) * (1.0 if (i / SAMPLE_RATE) < 0.1 else math.exp(-((i / SAMPLE_RATE) - 0.1) * 3.5)) * 0.85 for i in range(count)]


def gen_win() -> list[float]:
    dur = 0.60
    count = int(dur * SAMPLE_RATE)
    notes = [440.0, 554.37, 659.25, 880.0]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.14 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += (math.sin(2.0 * math.pi * freq * t) + 0.25 * math.sin(4.0 * math.pi * freq * t)) * math.exp(-t * 6.0) * 0.75
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "airhockey" / "assets" / "sounds"

    generators = {
        "airhockey_hit.wav": gen_mallet_hit,
        "airhockey_wall.wav": gen_rail_bounce,
        "airhockey_goal.wav": gen_goal_horn,
        "airhockey_win.wav": gen_win,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
