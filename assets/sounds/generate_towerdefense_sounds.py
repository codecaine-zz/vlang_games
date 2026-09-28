#!/usr/bin/env python3
"""Generate 10 studio WAV sound effects for Tower Defense."""
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
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (1600.0 - (i / count) * 1100.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 12.0) * 0.75 for i in range(count)]


def gen_cannon() -> list[float]:
    dur = 0.22
    count = int(dur * SAMPLE_RATE)
    return [((((i * 4567) % 1000) / 500.0 - 1.0) * 0.6 + math.sin(2.0 * math.pi * (180.0 - (i / count) * 120.0) * (i / SAMPLE_RATE)) * 0.4) * math.exp(-i / count * 8.0) * 0.9 for i in range(count)]


def gen_frost() -> list[float]:
    dur = 0.15
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (2400.0 + math.sin(i * 0.08) * 600.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 10.0) * 0.7 for i in range(count)]


def gen_build() -> list[float]:
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    return [((((i * 8899) % 1000) / 500.0 - 1.0) * 0.4 + math.sin(2.0 * math.pi * 580.0 * (i / SAMPLE_RATE)) * 0.6) * math.exp(-i / count * 14.0) * 0.8 for i in range(count)]


def gen_creep_hit() -> list[float]:
    dur = 0.06
    count = int(dur * SAMPLE_RATE)
    return [((((i * 2233) % 1000) / 500.0 - 1.0) * 0.8) * math.exp(-i / count * 18.0) * 0.7 for i in range(count)]


def gen_creep_death() -> list[float]:
    dur = 0.18
    count = int(dur * SAMPLE_RATE)
    return [((((i * 7711) % 1000) / 500.0 - 1.0) * 0.65 + math.sin(2.0 * math.pi * 120.0 * (i / SAMPLE_RATE)) * 0.35) * math.exp(-i / count * 9.0) * 0.85 for i in range(count)]


def gen_wave() -> list[float]:
    dur = 0.35
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (350.0 + math.sin(i * 0.03) * 150.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 4.0) * 0.8 for i in range(count)]


def gen_base_hit() -> list[float]:
    dur = 0.25
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (220.0 - (i / count) * 140.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 7.0) * 0.85 for i in range(count)]


def gen_victory() -> list[float]:
    dur = 0.5
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
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 8.0) * 0.8
    return samples


def gen_gameover() -> list[float]:
    dur = 0.4
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (300.0 - (i / count) * 200.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 5.0) * 0.8 for i in range(count)]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "towerdefense" / "assets" / "sounds"

    generators = {
        "td_laser.wav": gen_laser,
        "td_cannon.wav": gen_cannon,
        "td_frost.wav": gen_frost,
        "td_build.wav": gen_build,
        "td_creep_hit.wav": gen_creep_hit,
        "td_creep_death.wav": gen_creep_death,
        "td_wave.wav": gen_wave,
        "td_base_hit.wav": gen_base_hit,
        "td_victory.wav": gen_victory,
        "td_gameover.wav": gen_gameover,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
