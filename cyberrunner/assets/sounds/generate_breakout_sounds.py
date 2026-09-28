#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Breakout."""
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


def gen_paddle() -> list[float]:
    # Metallic paddle rebound click
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 880.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 15.0) * 0.7 for i in range(count)]


def gen_brick() -> list[float]:
    # Crystal jewel brick shatter
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 444.4) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 10.0) * 0.7 for i in range(count)]


def gen_steel() -> list[float]:
    # Indestructible steel ping
    dur = 0.15
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 1760.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 18.0) * 0.8 for i in range(count)]


def gen_laser() -> list[float]:
    # Dual laser blaster shot
    dur = 0.1
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (1200.0 - (i / count) * 800.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.75 for i in range(count)]


def gen_powerup() -> list[float]:
    # Powerup capsule catch chime
    dur = 0.35
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50]
    step = int(dur / len(notes) * SAMPLE_RATE)
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.12 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 12.0) * 0.65
    return samples


def gen_explosion() -> list[float]:
    # TNT explosive blast
    dur = 0.5
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 666.6) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 5.0) * 0.85 for i in range(count)]


def gen_win() -> list[float]:
    # Level clear fanfare
    dur = 0.65
    count = int(dur * SAMPLE_RATE)
    notes = [440.0, 554.37, 659.25, 880.0]
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


def gen_lose() -> list[float]:
    # Ball lost descent sound
    dur = 0.55
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (350.0 - (i / count) * 220.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 3.5) * 0.75 for i in range(count)]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "breakout" / "assets" / "sounds"

    generators = {
        "breakout_paddle.wav": gen_paddle,
        "breakout_brick.wav": gen_brick,
        "breakout_steel.wav": gen_steel,
        "breakout_laser.wav": gen_laser,
        "breakout_powerup.wav": gen_powerup,
        "breakout_explosion.wav": gen_explosion,
        "breakout_win.wav": gen_win,
        "breakout_lose.wav": gen_lose,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
