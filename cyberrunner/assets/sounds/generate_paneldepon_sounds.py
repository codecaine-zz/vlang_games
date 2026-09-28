#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Panel de Pon / Puzzle League."""
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


def gen_swap() -> list[float]:
    # Quick crisp tile swap click
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (800.0 + (i / count) * 400.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 18.0) * 0.8 for i in range(count)]


def gen_match() -> list[float]:
    # 3-panel match chime
    dur = 0.2
    count = int(dur * SAMPLE_RATE)
    return [(math.sin(2.0 * math.pi * 659.25 * (i / SAMPLE_RATE)) * 0.6 + math.sin(2.0 * math.pi * 1318.51 * (i / SAMPLE_RATE)) * 0.4) * math.exp(-i / count * 9.0) * 0.85 for i in range(count)]


def gen_combo() -> list[float]:
    # Sparkling chain combo fanfare
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
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 16.0) * 0.7
    return samples


def gen_raise() -> list[float]:
    # Stack manual lift whir
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (300.0 + (i / count) * 300.0) * (i / SAMPLE_RATE)) * 0.6 for i in range(count)]


def gen_garbage() -> list[float]:
    # Heavy garbage block drop thud
    dur = 0.3
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 90.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 12.0) * 0.9 for i in range(count)]


def gen_warning() -> list[float]:
    # Top-stack warning beep
    dur = 0.15
    count = int(dur * SAMPLE_RATE)
    return [(1.0 if ((i % 100) < 50) else -1.0) * math.exp(-i / count * 6.0) * 0.6 for i in range(count)]


def gen_win() -> list[float]:
    # Fairy victory celebration fanfare
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
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 10.0) * 0.7
    return samples


def gen_lose() -> list[float]:
    # Game over sigh
    dur = 0.5
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (400.0 - (i / count) * 200.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 5.0) * 0.7 for i in range(count)]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "paneldepon" / "assets" / "sounds"

    generators = {
        "paneldepon_swap.wav": gen_swap,
        "paneldepon_match.wav": gen_match,
        "paneldepon_combo.wav": gen_combo,
        "paneldepon_raise.wav": gen_raise,
        "paneldepon_garbage.wav": gen_garbage,
        "paneldepon_warning.wav": gen_warning,
        "paneldepon_win.wav": gen_win,
        "paneldepon_lose.wav": gen_lose,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
