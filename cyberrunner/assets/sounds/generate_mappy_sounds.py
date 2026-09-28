#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Mappy."""
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


def gen_bounce() -> list[float]:
    # Trampoline spring boing
    dur = 0.18
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (250.0 + (i / count) * 450.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 8.0) * 0.8 for i in range(count)]


def gen_door() -> list[float]:
    # Microwave door blast wave
    dur = 0.25
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (700.0 - (i / count) * 400.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 6.0) * 0.85 for i in range(count)]


def gen_loot() -> list[float]:
    # Treasure pickup chime
    dur = 0.15
    count = int(dur * SAMPLE_RATE)
    return [(math.sin(2.0 * math.pi * 880.0 * (i / SAMPLE_RATE)) * 0.6 + math.sin(2.0 * math.pi * 1760.0 * (i / SAMPLE_RATE)) * 0.4) * math.exp(-i / count * 10.0) * 0.85 for i in range(count)]


def gen_coin() -> list[float]:
    # Score ding
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 1318.51 * (i / SAMPLE_RATE)) * math.exp(-i / count * 14.0) * 0.75 for i in range(count)]


def gen_stun() -> list[float]:
    # Cat stun spinning bells
    dur = 0.35
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (1000.0 + math.sin(i * 0.05) * 300.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 5.0) * 0.75 for i in range(count)]


def gen_bonus() -> list[float]:
    # Balloon pop
    dur = 0.15
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 100.0) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 12.0) * 0.8 for i in range(count)]


def gen_die() -> list[float]:
    # Spinning whistle defeat
    dur = 0.45
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (600.0 - (i / count) * 400.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 4.0) * 0.85 for i in range(count)]


def gen_round() -> list[float]:
    # Round clear fanfare
    dur = 0.6
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.14 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 9.0) * 0.7
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "mappy" / "assets" / "sounds"

    generators = {
        "mappy_bounce.wav": gen_bounce,
        "mappy_door.wav": gen_door,
        "mappy_loot.wav": gen_loot,
        "mappy_coin.wav": gen_coin,
        "mappy_stun.wav": gen_stun,
        "mappy_bonus.wav": gen_bonus,
        "mappy_die.wav": gen_die,
        "mappy_round.wav": gen_round,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
