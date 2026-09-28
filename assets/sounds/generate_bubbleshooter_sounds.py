#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Bubble Shooter."""
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
    # Bubble launch whoosh & pop
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (250.0 + (i / count) * 450.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.7 for i in range(count)]


def gen_pop() -> list[float]:
    # Crisp soapy bubble burst
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 333.3) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 20.0) * 0.75 for i in range(count)]


def gen_bounce() -> list[float]:
    # Rubber wall bounce tap
    dur = 0.06
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 520.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 25.0) * 0.6 for i in range(count)]


def gen_stick() -> list[float]:
    # Sticky cluster attachment thud
    dur = 0.09
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 320.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 15.0) * 0.65 for i in range(count)]


def gen_fall() -> list[float]:
    # Detached bubble cluster whistle drop
    dur = 0.35
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (800.0 - (i / count) * 500.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 4.0) * 0.6 for i in range(count)]


def gen_combo() -> list[float]:
    # Sparkling combo chime
    dur = 0.4
    count = int(dur * SAMPLE_RATE)
    notes = [587.33, 739.99, 880.0, 1174.66]
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


def gen_win() -> list[float]:
    # Stage clear victory fanfare
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


def gen_gameover() -> list[float]:
    # Descent game over tone
    dur = 0.6
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (400.0 - (i / count) * 280.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 3.0) * 0.7 for i in range(count)]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "bubbleshooter" / "assets" / "sounds"

    generators = {
        "bubble_launch.wav": gen_launch,
        "bubble_pop.wav": gen_pop,
        "bubble_bounce.wav": gen_bounce,
        "bubble_stick.wav": gen_stick,
        "bubble_fall.wav": gen_fall,
        "bubble_combo.wav": gen_combo,
        "bubble_win.wav": gen_win,
        "bubble_gameover.wav": gen_gameover,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
