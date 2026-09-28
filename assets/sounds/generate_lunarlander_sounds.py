#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Lunar Lander."""
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


def gen_thrust() -> list[float]:
    # Rocket main thruster deep rumble
    dur = 0.35
    count = int(dur * SAMPLE_RATE)
    return [(((math.sin(i * 123.4) % 1.0) * 2.0 - 1.0) * 0.7 + math.sin(2.0 * math.pi * 55.0 * (i / SAMPLE_RATE)) * 0.3) * (1.0 - i / count * 0.3) * 0.8 for i in range(count)]


def gen_rcs() -> list[float]:
    # RCS attitude steering gas hiss
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 999.3) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 10.0) * 0.5 for i in range(count)]


def gen_beep() -> list[float]:
    # Radar altimeter proximity beep
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 1760.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 12.0) * 0.6 for i in range(count)]


def gen_touchdown() -> list[float]:
    # Successful gentle landing fanfare
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


def gen_crash() -> list[float]:
    # Violent hard impact explosion
    dur = 0.7
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 555.2) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 4.0) * 0.9 for i in range(count)]


def gen_fuelwarning() -> list[float]:
    # Low fuel critical alert
    dur = 0.3
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (880.0 if (i // 2000) % 2 == 0 else 660.0) * (i / SAMPLE_RATE)) * 0.65 for i in range(count)]


def gen_flag() -> list[float]:
    # Planting American flag chime
    dur = 0.4
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 880.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 6.0) * 0.7 for i in range(count)]


def gen_ambient() -> list[float]:
    # Deep space silence & radio static
    dur = 0.5
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 77.1) % 1.0) * 2.0 - 1.0) * 0.15 for i in range(count)]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "lunarlander" / "assets" / "sounds"

    generators = {
        "lunarlander_thrust.wav": gen_thrust,
        "lunarlander_rcs.wav": gen_rcs,
        "lunarlander_beep.wav": gen_beep,
        "lunarlander_touchdown.wav": gen_touchdown,
        "lunarlander_crash.wav": gen_crash,
        "lunarlander_fuelwarning.wav": gen_fuelwarning,
        "lunarlander_flag.wav": gen_flag,
        "lunarlander_ambient.wav": gen_ambient,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
