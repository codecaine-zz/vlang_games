#!/usr/bin/env python3
"""Generate studio WAV sound effects for Pool / Billiards."""
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


def gen_cue_strike() -> list[float]:
    dur = 0.1
    count = int(dur * SAMPLE_RATE)
    return [(((math.sin(2.0 * math.pi * 1200.0 * (i / SAMPLE_RATE)) * 0.6) + (((i * 4321) % 1000) / 500.0 - 1.0) * 0.4) * math.exp(-i / count * 22.0) * 0.85) for i in range(count)]


def gen_ball_collision() -> list[float]:
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    return [(math.sin(2.0 * math.pi * 3200.0 * (i / SAMPLE_RATE)) * 0.7 + math.sin(2.0 * math.pi * 4800.0 * (i / SAMPLE_RATE)) * 0.3) * math.exp(-i / count * 35.0) * 0.9 for i in range(count)]


def gen_cushion() -> list[float]:
    dur = 0.09
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 220.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 20.0) * 0.75 for i in range(count)]


def gen_pot() -> list[float]:
    dur = 0.22
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (400.0 - (i / count) * 200.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 10.0) * 0.85 for i in range(count)]


def gen_break() -> list[float]:
    dur = 0.28
    count = int(dur * SAMPLE_RATE)
    return [((((i * 9871) % 1000) / 500.0 - 1.0) * 0.6 + math.sin(2.0 * math.pi * 2800.0 * (i / SAMPLE_RATE)) * 0.4) * math.exp(-i / count * 8.0) * 0.95 for i in range(count)]


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
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 8.0) * 0.75
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "pool" / "assets" / "sounds"

    generators = {
        "pool_strike.wav": gen_cue_strike,
        "pool_ball_hit.wav": gen_ball_collision,
        "pool_cushion.wav": gen_cushion,
        "pool_pot.wav": gen_pot,
        "pool_break.wav": gen_break,
        "pool_win.wav": gen_win,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
