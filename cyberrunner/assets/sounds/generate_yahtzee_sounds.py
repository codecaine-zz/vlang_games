#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Yahtzee."""
from __future__ import annotations

import math
import random
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


def gen_shake() -> list[float]:
    dur = 0.28
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        rattle = ((math.sin(i * 333.1) % 1.0) * 2.0 - 1.0) * 0.5
        thud = math.sin(2.0 * math.pi * 120.0 * t) * 0.4
        env = math.exp(-((t % 0.07) * 45.0))
        samples.append((rattle + thud) * env * 0.75)
    return samples


def gen_roll() -> list[float]:
    dur = 0.35
    count = int(dur * SAMPLE_RATE)
    samples = [0.0] * count
    # 5 clacks for 5 dice tumbling on felt
    for d in range(5):
        clack_start = int((d * 0.05 + 0.02) * SAMPLE_RATE)
        for s in range(int(0.06 * SAMPLE_RATE)):
            idx = clack_start + s
            if idx >= count:
                break
            t = s / SAMPLE_RATE
            freq = 300.0 + d * 60.0
            noise = ((math.sin(s * 777.3) % 1.0) * 2.0 - 1.0) * 0.4
            clack = math.sin(2.0 * math.pi * freq * t) * 0.5
            samples[idx] += (noise + clack) * math.exp(-t * 50.0) * 0.6
    return samples


def gen_select() -> list[float]:
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (520.0 + (i / count) * 280.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.7 for i in range(count)]


def gen_score() -> list[float]:
    dur = 0.25
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 659.25 * (i / SAMPLE_RATE)) * math.exp(-i / count * 6.0) * 0.7 for i in range(count)]


def gen_yahtzee() -> list[float]:
    # Glorious 5-note victory fanfare
    dur = 0.65
    count = int(dur * SAMPLE_RATE)
    samples = [0.0] * count
    notes = [523.25, 659.25, 783.99, 1046.50, 1318.51] # C5, E5, G5, C6, E6
    step = int(dur / len(notes) * SAMPLE_RATE)
    for n_idx, freq in enumerate(notes):
        st = n_idx * step
        for s in range(int(0.2 * SAMPLE_RATE)):
            idx = st + s
            if idx >= count:
                break
            t = s / SAMPLE_RATE
            samples[idx] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 8.0) * 0.6
    return samples


def gen_bonus() -> list[float]:
    dur = 0.3
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (440.0 + (i / count) * 600.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.75 for i in range(count)]


def gen_hover() -> list[float]:
    dur = 0.05
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 880.0 * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.35 for i in range(count)]


def gen_win() -> list[float]:
    dur = 0.5
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (587.33 + math.sin(i / SAMPLE_RATE * 20.0) * 80.0) * (i / SAMPLE_RATE)) * (1.0 - i / count) * 0.7 for i in range(count)]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "yahtzee" / "assets" / "sounds"

    generators = {
        "yahtzee_shake.wav": gen_shake,
        "yahtzee_roll.wav": gen_roll,
        "yahtzee_select.wav": gen_select,
        "yahtzee_score.wav": gen_score,
        "yahtzee_yahtzee.wav": gen_yahtzee,
        "yahtzee_bonus.wav": gen_bonus,
        "yahtzee_hover.wav": gen_hover,
        "yahtzee_win.wav": gen_win,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
