#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Simon."""
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


def gen_tone(freq: float) -> list[float]:
    dur = 0.35
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (i / count)) if i < count * 0.1 else math.exp(-(i - count * 0.1) / count * 4.0)
        s1 = math.sin(2.0 * math.pi * freq * t)
        s2 = math.sin(2.0 * math.pi * (freq * 2.0) * t) * 0.25
        samples.append((s1 + s2) * env * 0.75)
    return samples


def gen_green() -> list[float]:
    return gen_tone(329.63) # E4


def gen_red() -> list[float]:
    return gen_tone(440.0) # A4


def gen_yellow() -> list[float]:
    return gen_tone(277.18) # C#4


def gen_blue() -> list[float]:
    return gen_tone(164.81) # E3


def gen_error() -> list[float]:
    # 42 Hz saw wave fail buzzer
    dur = 0.5
    count = int(dur * SAMPLE_RATE)
    return [(((i * 42.0 / SAMPLE_RATE) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 3.0) * 0.8 for i in range(count)]


def gen_win() -> list[float]:
    # Sequence complete victory chime
    dur = 0.6
    count = int(dur * SAMPLE_RATE)
    notes = [277.18, 329.63, 440.0, 554.37]
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


def gen_click() -> list[float]:
    # Mechanical tactile switch click
    dur = 0.04
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 2200.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 25.0) * 0.6 for i in range(count)]


def gen_speedup() -> list[float]:
    # Speedup tempo sweep
    dur = 0.25
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (300.0 + (i / count) * 600.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.65 for i in range(count)]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "simon" / "assets" / "sounds"

    generators = {
        "simon_tone_green.wav": gen_green,
        "simon_tone_red.wav": gen_red,
        "simon_tone_yellow.wav": gen_yellow,
        "simon_tone_blue.wav": gen_blue,
        "simon_error.wav": gen_error,
        "simon_win.wav": gen_win,
        "simon_click.wav": gen_click,
        "simon_speedup.wav": gen_speedup,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
