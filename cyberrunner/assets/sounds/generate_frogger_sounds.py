#!/usr/bin/env python3
"""Generate authentic studio WAV sound effects for Frogger."""
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


def gen_hop() -> list[float]:
    # Springy boing hop (280Hz -> 650Hz)
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        freq = 280.0 + 400.0 * (t / dur)
        env = math.sin(math.pi * (t / dur))
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.75)
    return samples


def gen_squish() -> list[float]:
    # Road squash crunch
    dur = 0.22
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        noise = (((i * 49231) % 1000) / 500.0 - 1.0) * 0.8
        thud = math.sin(2.0 * math.pi * 90.0 * t) * 0.5
        env = math.exp(-t * 14.0)
        samples.append((noise + thud) * env * 0.85)
    return samples


def gen_splash() -> list[float]:
    # Water splash gulp
    dur = 0.25
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        noise = (((i * 81237) % 1000) / 500.0 - 1.0) * 0.6
        bubble = math.sin(2.0 * math.pi * (300.0 + 200.0 * math.sin(t * 80.0)) * t) * 0.5
        env = math.exp(-t * 12.0)
        samples.append((noise + bubble) * env * 0.8)
    return samples


def gen_dock() -> list[float]:
    # Lilypad home reached fanfare note
    dur = 0.18
    count = int(dur * SAMPLE_RATE)
    notes = [587.33, 880.0]
    samples = [0.0] * count
    sub_dur = dur / 2.0
    for idx, freq in enumerate(notes):
        st = int(idx * sub_dur * SAMPLE_RATE)
        for s in range(int(sub_dur * 1.5 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 16.0)
            tone = math.sin(2.0 * math.pi * freq * t)
            samples[i] += tone * env * 0.7
    return samples


def gen_win() -> list[float]:
    # Stage clear victory fanfare
    dur = 0.70
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50]
    samples = [0.0] * count
    step = int(count / len(notes))
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.20 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 8.0)
            tone = (math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)) * env * 0.75
            samples[i] += tone
    return samples


def gen_die() -> list[float]:
    # Comical sad descending ribbit
    dur = 0.50
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        freq = 380.0 * (1.0 - t / dur) + 40.0 * math.sin(t * 30.0)
        env = math.exp(-t * 6.0)
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.8)
    return samples


def main() -> None:
    out_dir = Path(__file__).resolve().parent
    sounds = {
        "frogger_hop.wav": gen_hop(),
        "frogger_squish.wav": gen_squish(),
        "frogger_splash.wav": gen_splash(),
        "frogger_dock.wav": gen_dock(),
        "frogger_win.wav": gen_win(),
        "frogger_die.wav": gen_die(),
    }
    for fname, smp in sounds.items():
        p = out_dir / fname
        write_wav(p, smp)
        print(f"Generated {p} ({len(smp)} samples)")


if __name__ == "__main__":
    main()
