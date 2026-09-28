#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for UNO."""
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


def gen_play() -> list[float]:
    # Crisp card discard snap
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (900.0 - (i / count) * 400.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 18.0) * 0.8 for i in range(count)]


def gen_draw() -> list[float]:
    # Card draw whoosh
    dur = 0.1
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (400.0 + (i / count) * 500.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 12.0) * 0.75 for i in range(count)]


def gen_wild() -> list[float]:
    # Wild card color wheel magic chime
    dur = 0.35
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
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 14.0) * 0.7
    return samples


def gen_skip() -> list[float]:
    # Skip block thud
    dur = 0.16
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (600.0 - (i / count) * 350.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 10.0) * 0.8 for i in range(count)]


def gen_reverse() -> list[float]:
    # Reverse arrow swoosh
    dur = 0.2
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (300.0 + (i / count) * 500.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 8.0) * 0.75 for i in range(count)]


def gen_shout() -> list[float]:
    # "UNO!" shout fanfare
    dur = 0.4
    count = int(dur * SAMPLE_RATE)
    notes = [659.25, 880.0, 1046.50]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.16 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 8.0) * 0.8
    return samples


def gen_win() -> list[float]:
    # Victory celebratory party fanfare
    dur = 0.6
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50, 1318.51]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.15 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 8.0) * 0.75
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "uno" / "assets" / "sounds"

    generators = {
        "uno_play.wav": gen_play,
        "uno_draw.wav": gen_draw,
        "uno_wild.wav": gen_wild,
        "uno_skip.wav": gen_skip,
        "uno_reverse.wav": gen_reverse,
        "uno_shout.wav": gen_shout,
        "uno_win.wav": gen_win,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
