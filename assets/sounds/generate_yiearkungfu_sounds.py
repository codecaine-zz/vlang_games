#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Yie Ar Kung-Fu."""
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


def gen_punch() -> list[float]:
    # Quick punch whoosh
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (300.0 + (i / count) * 400.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 14.0) * 0.75 for i in range(count)]


def gen_kick() -> list[float]:
    # Heavy kick whoosh
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (180.0 + (i / count) * 320.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 10.0) * 0.8 for i in range(count)]


def gen_hit() -> list[float]:
    # Classic arcade impact slap
    dur = 0.15
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 120.0) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 12.0) * 0.9 for i in range(count)]


def gen_jump() -> list[float]:
    # Acrobatic leap whoosh
    dur = 0.14
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (250.0 + (i / count) * 500.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 6.0) * 0.75 for i in range(count)]


def gen_fire() -> list[float]:
    # Tao fireball whoosh
    dur = 0.22
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (450.0 - (i / count) * 250.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 5.0) * 0.8 for i in range(count)]


def gen_clash() -> list[float]:
    # Staff / Weapon parry metallic clink
    dur = 0.1
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 1800.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 20.0) * 0.85 for i in range(count)]


def gen_ko() -> list[float]:
    # Defeat knockout roar
    dur = 0.45
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (220.0 - (i / count) * 120.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 4.0) * 0.85 for i in range(count)]


def gen_win() -> list[float]:
    # Round clear celebratory gong fanfare
    dur = 0.65
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.18 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 8.0) * 0.7
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "yiearkungfu" / "assets" / "sounds"

    generators = {
        "kungfu_punch.wav": gen_punch,
        "kungfu_kick.wav": gen_kick,
        "kungfu_hit.wav": gen_hit,
        "kungfu_jump.wav": gen_jump,
        "kungfu_fire.wav": gen_fire,
        "kungfu_clash.wav": gen_clash,
        "kungfu_ko.wav": gen_ko,
        "kungfu_win.wav": gen_win,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
