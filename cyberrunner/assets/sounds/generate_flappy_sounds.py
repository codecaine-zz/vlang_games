#!/usr/bin/env python3
"""Generate authentic WAV sound effects for Flappy Bird."""
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


def gen_flap() -> list[float]:
    # Crisp whoosh flap
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        norm = t / dur
        freq = 320.0 + 380.0 * norm
        noise = (((i * 31337) % 1000) / 500.0 - 1.0) * 0.35
        env = math.sin(math.pi * norm) ** 0.85
        s = (math.sin(2.0 * math.pi * freq * t) * 0.75 + noise) * env
        samples.append(s * 0.8)
    return samples


def gen_point() -> list[float]:
    # Iconic clean high score ding (two harmonized sine waves B5 / F#6)
    dur = 0.18
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 22.0)
        s1 = math.sin(2.0 * math.pi * 987.77 * t)
        s2 = math.sin(2.0 * math.pi * 1479.98 * t) * 0.5
        samples.append((s1 + s2) * env * 0.75)
    return samples


def gen_hit() -> list[float]:
    # Pipe impact punch
    dur = 0.16
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        noise = (((i * 59231) % 1000) / 500.0 - 1.0) * 0.8
        thud = math.sin(2.0 * math.pi * 120.0 * t) * 0.6
        env = math.exp(-t * 24.0)
        samples.append((noise + thud) * env * 0.9)
    return samples


def gen_die() -> list[float]:
    # Ground thud drop
    dur = 0.30
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        norm = t / dur
        freq = 280.0 * (1.0 - norm) + 50.0
        env = math.exp(-t * 10.0)
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.85)
    return samples


def gen_swoosh() -> list[float]:
    # UI menu swoosh
    dur = 0.14
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        norm = t / dur
        freq = 600.0 * (1.0 - norm) + 120.0
        noise = (((i * 71337) % 1000) / 500.0 - 1.0) * 0.3
        env = math.sin(math.pi * norm)
        samples.append((math.sin(2.0 * math.pi * freq * t) * 0.6 + noise) * env * 0.75)
    return samples


def main() -> None:
    out_dir = Path(__file__).resolve().parent
    sounds = {
        "flappy_flap.wav": gen_flap(),
        "flappy_point.wav": gen_point(),
        "flappy_hit.wav": gen_hit(),
        "flappy_die.wav": gen_die(),
        "flappy_swoosh.wav": gen_swoosh(),
    }
    for fname, smp in sounds.items():
        p = out_dir / fname
        write_wav(p, smp)
        print(f"Generated {p} ({len(smp)} samples)")


if __name__ == "__main__":
    main()
