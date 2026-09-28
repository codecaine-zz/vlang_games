#!/usr/bin/env python3
"""Generate 6 studio WAV sound effects for Pong."""
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


def gen_paddle_hit() -> list[float]:
    dur = 0.06
    count = int(dur * SAMPLE_RATE)
    return [(1.0 if math.sin(2.0 * math.pi * 580.0 * (i / SAMPLE_RATE)) > 0 else -1.0) * math.exp(-i / count * 16.0) * 0.75 for i in range(count)]


def gen_wall_hit() -> list[float]:
    dur = 0.05
    count = int(dur * SAMPLE_RATE)
    return [(1.0 if math.sin(2.0 * math.pi * 420.0 * (i / SAMPLE_RATE)) > 0 else -1.0) * math.exp(-i / count * 18.0) * 0.7 for i in range(count)]


def gen_score() -> list[float]:
    dur = 0.28
    count = int(dur * SAMPLE_RATE)
    notes = [440.0, 554.37, 659.25]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.08 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            sq = 1.0 if math.sin(2.0 * math.pi * freq * t) > 0 else -1.0
            samples[i] += sq * math.exp(-t * 12.0) * 0.75
    return samples


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
            sq = 1.0 if math.sin(2.0 * math.pi * freq * t) > 0 else -1.0
            samples[i] += sq * math.exp(-t * 8.0) * 0.75
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "pong" / "assets" / "sounds"

    generators = {
        "hit.wav": gen_paddle_hit,
        "bounce.wav": gen_wall_hit,
        "score.wav": gen_score,
        "win.wav": gen_win,
        "click.wav": gen_wall_hit,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
