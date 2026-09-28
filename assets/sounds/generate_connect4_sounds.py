#!/usr/bin/env python3
"""Generate studio WAV sound effects for Connect 4."""
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


def gen_drop() -> list[float]:
    # Plastic disc slide & drop whoosh
    dur = 0.14
    count = int(dur * SAMPLE_RATE)
    return [(((math.sin(2.0 * math.pi * (650.0 - (i / count) * 350.0) * (i / SAMPLE_RATE)) * 0.7) + (((i * 3217) % 1000) / 500.0 - 1.0) * 0.3) * math.exp(-i / count * 8.0) * 0.85) for i in range(count)]


def gen_bounce() -> list[float]:
    # Heavy plastic clack / bottom settle impact
    dur = 0.09
    count = int(dur * SAMPLE_RATE)
    return [(math.sin(2.0 * math.pi * 1400.0 * (i / SAMPLE_RATE)) * 0.6 + math.sin(2.0 * math.pi * 920.0 * (i / SAMPLE_RATE)) * 0.4 + (((i * 8761) % 1000) / 500.0 - 1.0) * 0.3) * math.exp(-i / count * 26.0) * 0.95 for i in range(count)]


def gen_hover() -> list[float]:
    # Subtle column cursor tick
    dur = 0.04
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 1400.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 35.0) * 0.6 for i in range(count)]


def gen_win() -> list[float]:
    # Connect 4 celebratory victory fanfare
    dur = 0.75
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50, 1318.51]  # C5, E5, G5, C6, E6
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.18 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += (math.sin(2.0 * math.pi * freq * t) + 0.35 * math.sin(4.0 * math.pi * freq * t)) * math.exp(-t * 8.0) * 0.75
    return samples


def gen_lose() -> list[float]:
    # Defeat sad descending wah-wah chord
    dur = 0.70
    count = int(dur * SAMPLE_RATE)
    notes = [440.0, 415.30, 392.0, 349.23]  # A4, Ab4, G4, F4
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.18 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += (math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(2.0 * math.pi * (freq * 0.5) * t)) * math.exp(-t * 6.0) * 0.75
    return samples


def gen_draw() -> list[float]:
    # Stalemate / draw chord
    dur = 0.50
    count = int(dur * SAMPLE_RATE)
    notes = [392.0, 440.0, 392.0]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.18 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += (math.sin(2.0 * math.pi * freq * t) + 0.25 * math.sin(3.0 * math.pi * freq * t)) * math.exp(-t * 7.0) * 0.7
    return samples


def gen_undo() -> list[float]:
    # Disc rewind slide
    dur = 0.1
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (250.0 + (i / count) * 450.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 12.0) * 0.7 for i in range(count)]


def gen_btn() -> list[float]:
    # UI Click
    dur = 0.05
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 900.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 28.0) * 0.7 for i in range(count)]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "connect4" / "assets" / "sounds"

    generators = {
        "connect4_drop.wav": gen_drop,
        "connect4_bounce.wav": gen_bounce,
        "connect4_hover.wav": gen_hover,
        "connect4_win.wav": gen_win,
        "connect4_lose.wav": gen_lose,
        "connect4_draw.wav": gen_draw,
        "connect4_undo.wav": gen_undo,
        "connect4_btn.wav": gen_btn,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
