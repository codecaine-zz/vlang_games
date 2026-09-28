#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Yoshi's Cookie."""
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


def gen_slide() -> list[float]:
    dur = 0.15
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (350.0 + (i / count) * 200.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.7 for i in range(count)]


def gen_match() -> list[float]:
    dur = 0.22
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (587.33 + (i / count) * 440.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 5.0) * 0.75 for i in range(count)]


def gen_clear() -> list[float]:
    dur = 0.35
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        freq = 659.25 if i < count // 2 else 987.77
        samples.append(math.sin(2.0 * math.pi * freq * t) * (1.0 - i / count) * 0.8)
    return samples


def gen_combo() -> list[float]:
    dur = 0.45
    count = int(dur * SAMPLE_RATE)
    samples = [0.0] * count
    notes = [523.25, 659.25, 783.99, 1046.50]
    step = int(dur / len(notes) * SAMPLE_RATE)
    for n_idx, freq in enumerate(notes):
        st = n_idx * step
        for s in range(int(0.18 * SAMPLE_RATE)):
            idx = st + s
            if idx >= count:
                break
            t = s / SAMPLE_RATE
            samples[idx] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 10.0) * 0.65
    return samples


def gen_yoshi() -> list[float]:
    # Cute Yoshi "Ba-dum!" chirp
    dur = 0.28
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (450.0 + math.sin(i / SAMPLE_RATE * 35.0) * 200.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.75 for i in range(count)]


def gen_warning() -> list[float]:
    dur = 0.18
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 880.0 * (i / SAMPLE_RATE)) * (1.0 if (i // 500) % 2 == 0 else 0.0) * 0.6 for i in range(count)]


def gen_win() -> list[float]:
    dur = 0.55
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (698.46 + (i / count) * 350.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.7 for i in range(count)]


def gen_gameover() -> list[float]:
    dur = 0.6
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (392.0 - (i / count) * 200.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.75 for i in range(count)]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "yoshicookie" / "assets" / "sounds"

    generators = {
        "yoshicookie_slide.wav": gen_slide,
        "yoshicookie_match.wav": gen_match,
        "yoshicookie_clear.wav": gen_clear,
        "yoshicookie_combo.wav": gen_combo,
        "yoshicookie_yoshi.wav": gen_yoshi,
        "yoshicookie_warning.wav": gen_warning,
        "yoshicookie_win.wav": gen_win,
        "yoshicookie_gameover.wav": gen_gameover,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
