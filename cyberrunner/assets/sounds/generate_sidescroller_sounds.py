#!/usr/bin/env python3
"""Generate 12 studio WAV sound effects for Cyberpunk Sidescroller."""
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


def gen_laser() -> list[float]:
    dur = 0.09
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (1200.0 - (i / count) * 900.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 14.0) * 0.85 for i in range(count)]


def gen_spread() -> list[float]:
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    return [((((i * 1234) % 1000) / 500.0 - 1.0) * 0.4 + math.sin(2.0 * math.pi * (500.0 - (i / count) * 350.0) * (i / SAMPLE_RATE)) * 0.6) * math.exp(-i / count * 10.0) * 0.8 for i in range(count)]


def gen_plasma() -> list[float]:
    dur = 0.18
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (350.0 + math.sin(i * 0.08) * 150.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 8.0) * 0.9 for i in range(count)]


def gen_missile() -> list[float]:
    dur = 0.22
    count = int(dur * SAMPLE_RATE)
    return [((((i * 4321) % 1000) / 500.0 - 1.0) * 0.6 + math.sin(2.0 * math.pi * (250.0 + (i / count) * 400.0) * (i / SAMPLE_RATE)) * 0.4) * math.exp(-i / count * 6.0) * 0.85 for i in range(count)]


def gen_beam() -> list[float]:
    dur = 0.25
    count = int(dur * SAMPLE_RATE)
    return [(1.0 if math.sin(2.0 * math.pi * 750.0 * (i / SAMPLE_RATE)) > 0 else -1.0) * math.exp(-i / count * 5.0) * 0.75 for i in range(count)]


def gen_explode_sm() -> list[float]:
    dur = 0.18
    count = int(dur * SAMPLE_RATE)
    return [((((i * 6543) % 1000) / 500.0 - 1.0) * 0.7 + math.sin(2.0 * math.pi * 280.0 * (i / SAMPLE_RATE)) * 0.3) * math.exp(-i / count * 9.0) * 0.85 for i in range(count)]


def gen_explode_lg() -> list[float]:
    dur = 0.45
    count = int(dur * SAMPLE_RATE)
    return [((((i * 9876) % 1000) / 500.0 - 1.0) * 0.6 + math.sin(2.0 * math.pi * (180.0 - (i / count) * 140.0) * (i / SAMPLE_RATE)) * 0.4) * math.exp(-i / count * 4.5) * 0.95 for i in range(count)]


def gen_powerup() -> list[float]:
    dur = 0.25
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.08 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 14.0) * 0.7
    return samples


def gen_dash() -> list[float]:
    dur = 0.14
    count = int(dur * SAMPLE_RATE)
    return [((((i * 3210) % 1000) / 500.0 - 1.0) * 0.5 + math.sin(2.0 * math.pi * (600.0 - (i / count) * 400.0) * (i / SAMPLE_RATE)) * 0.5) * math.exp(-i / count * 10.0) * 0.8 for i in range(count)]


def gen_jump() -> list[float]:
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (220.0 + (i / count) * 550.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 12.0) * 0.8 for i in range(count)]


def gen_boss_alert() -> list[float]:
    dur = 0.4
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (300.0 + math.sin(i * 0.05) * 200.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 3.0) * 0.85 for i in range(count)]


def gen_victory() -> list[float]:
    dur = 0.55
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.12 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += (math.sin(2.0 * math.pi * freq * t) + 0.25 * math.sin(4.0 * math.pi * freq * t)) * math.exp(-t * 8.0) * 0.65
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "sidescroller" / "assets" / "sounds"

    generators = {
        "sidescroller_laser.wav": gen_laser,
        "sidescroller_spread.wav": gen_spread,
        "sidescroller_plasma.wav": gen_plasma,
        "sidescroller_missile.wav": gen_missile,
        "sidescroller_beam.wav": gen_beam,
        "sidescroller_explode_sm.wav": gen_explode_sm,
        "sidescroller_explode_lg.wav": gen_explode_lg,
        "sidescroller_powerup.wav": gen_powerup,
        "sidescroller_dash.wav": gen_dash,
        "sidescroller_jump.wav": gen_jump,
        "sidescroller_boss_alert.wav": gen_boss_alert,
        "sidescroller_victory.wav": gen_victory,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
