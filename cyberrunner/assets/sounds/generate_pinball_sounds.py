#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Pinball."""
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


def gen_flipper() -> list[float]:
    # Mechanical solenoid flipper click
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 320.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 20.0) * 0.75 for i in range(count)]


def gen_bumper() -> list[float]:
    # High power rubber bumper bell
    dur = 0.18
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 1200.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 12.0) * 0.8 for i in range(count)]


def gen_slingshot() -> list[float]:
    # Slingshot kicker twang
    dur = 0.1
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 480.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 18.0) * 0.7 for i in range(count)]


def gen_plunger() -> list[float]:
    # Plunger spring release whoosh
    dur = 0.22
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (200.0 + (i / count) * 400.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.7 for i in range(count)]


def gen_target() -> list[float]:
    # Drop card target click
    dur = 0.09
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 750.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 22.0) * 0.65 for i in range(count)]


def gen_drain() -> list[float]:
    # Ball lost drain descent
    dur = 0.55
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (350.0 - (i / count) * 200.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 3.5) * 0.75 for i in range(count)]


def gen_tilt() -> list[float]:
    # Tilt warning buzzer
    dur = 0.25
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 180.0) % 1.0) * 2.0 - 1.0) * 0.5 for i in range(count)]


def gen_score() -> list[float]:
    # High score jackpot fanfare
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


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "pinball" / "assets" / "sounds"

    generators = {
        "pinball_flipper.wav": gen_flipper,
        "pinball_bumper.wav": gen_bumper,
        "pinball_slingshot.wav": gen_slingshot,
        "pinball_plunger.wav": gen_plunger,
        "pinball_target.wav": gen_target,
        "pinball_drain.wav": gen_drain,
        "pinball_tilt.wav": gen_tilt,
        "pinball_score.wav": gen_score,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
