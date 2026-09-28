#!/usr/bin/env python3
"""Generate authentic WAV sound effects for Snake."""
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


def gen_eat() -> list[float]:
    # Crisp crunchy bite (320Hz -> 640Hz)
    dur = 0.09
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        norm = t / dur
        freq = 300.0 + 380.0 * norm
        env = math.sin(math.pi * norm) ** 0.85
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.8)
    return samples


def gen_gold() -> list[float]:
    # Golden apple sparkling chime (arpeggio C6 / E6 / G6)
    dur = 0.22
    count = int(dur * SAMPLE_RATE)
    notes = [1046.50, 1318.51, 1567.98]
    samples = [0.0] * count
    step = count // len(notes)
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.10 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 24.0)
            tone = math.sin(2.0 * math.pi * freq * t) * env * 0.75
            samples[i] += tone
    return samples


def gen_die() -> list[float]:
    # Descending game over thud
    dur = 0.40
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        norm = t / dur
        freq = 420.0 * (1.0 - norm) + 50.0
        env = math.exp(-t * 8.0)
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.85)
    return samples


def gen_click() -> list[float]:
    # UI navigation click
    dur = 0.04
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 90.0)
        s = math.sin(2.0 * math.pi * 880.0 * t)
        samples.append(s * env * 0.7)
    return samples


def gen_turn() -> list[float]:
    # Subtle whoosh turn tick
    dur = 0.05
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (t / dur))
        s = math.sin(2.0 * math.pi * 520.0 * t)
        samples.append(s * env * 0.5)
    return samples


def main() -> None:
    out_dir = Path(__file__).resolve().parent
    sounds = {
        "snake_eat.wav": gen_eat(),
        "snake_gold.wav": gen_gold(),
        "snake_die.wav": gen_die(),
        "snake_click.wav": gen_click(),
        "snake_turn.wav": gen_turn(),
    }
    for fname, smp in sounds.items():
        p = out_dir / fname
        write_wav(p, smp)
        print(f"Generated {p} ({len(smp)} samples)")


if __name__ == "__main__":
    main()
