#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Contra."""
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


def gen_rifle() -> list[float]:
    # Normal commando rifle gun shot
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (800.0 - (i / count) * 400.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 18.0) * 0.75 for i in range(count)]


def gen_spread() -> list[float]:
    # Spread gun blast
    dur = 0.14
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (600.0 + math.sin(i * 0.1) * 300.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 12.0) * 0.8 for i in range(count)]


def gen_laser() -> list[float]:
    # High energy laser pulse
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (1400.0 - (i / count) * 800.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 10.0) * 0.7 for i in range(count)]


def gen_fireball() -> list[float]:
    # Rotating fireball flame shot
    dur = 0.16
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 450.0) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 8.0) * 0.7 for i in range(count)]


def gen_explode() -> list[float]:
    # Heavy explosion blast
    dur = 0.5
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 666.6) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 4.0) * 0.9 for i in range(count)]


def gen_powerup() -> list[float]:
    # Falcon powerup pickup chime
    dur = 0.25
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99]
    step = int(dur / len(notes) * SAMPLE_RATE)
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.09 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 15.0) * 0.6
    return samples


def gen_boss_hit() -> list[float]:
    # Heavy metal boss impact
    dur = 0.1
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 180.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 20.0) * 0.8 for i in range(count)]


def gen_stage_clear() -> list[float]:
    # Iconic military stage clear fanfare
    dur = 0.75
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50, 1318.51]
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
    local_sfx_dir = root / "contra" / "assets" / "sounds"

    generators = {
        "contra_rifle.wav": gen_rifle,
        "contra_spread.wav": gen_spread,
        "contra_laser.wav": gen_laser,
        "contra_fireball.wav": gen_fireball,
        "contra_explode.wav": gen_explode,
        "contra_powerup.wav": gen_powerup,
        "contra_boss_hit.wav": gen_boss_hit,
        "contra_stage_clear.wav": gen_stage_clear,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
