#!/usr/bin/env python3
"""Generate studio quality WAV sound effects for Rodent's Revenge."""
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


def gen_step() -> list[float]:
    # Quick mouse tiptoe step
    dur = 0.04
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 90.0)
        s = math.sin(2.0 * math.pi * (700.0 + t * 400.0) * t)
        samples.append(s * env * 0.5)
    return samples


def gen_push() -> list[float]:
    # Heavy wooden block sliding friction thud
    dur = 0.09
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 35.0)
        # Low frequency thump + noise rumble
        noise = (((i * 12345) % 1000) / 500.0 - 1.0) * 0.35
        tone = math.sin(2.0 * math.pi * 140.0 * t) * 0.65
        samples.append((tone + noise) * env * 0.8)
    return samples


def gen_cheese_spawn() -> list[float]:
    # Magical sparkle arpeggio (Cats transformed into cheese!)
    dur = 0.30
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.5]
    samples = [0.0] * count
    sub_dur = dur / len(notes)

    for idx, freq in enumerate(notes):
        st = int(idx * sub_dur * SAMPLE_RATE)
        for s in range(int(sub_dur * 1.5 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 16.0)
            tone = math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
            samples[i] += tone * env * 0.65
    return samples


def gen_eat() -> list[float]:
    # Mouse nibble / munch crunch sound
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 40.0)
        s1 = math.sin(2.0 * math.pi * (880.0 - t * 2000.0) * t) * 0.6
        noise = (((i * 98765) % 1000) / 500.0 - 1.0) * 0.4
        samples.append((s1 + noise) * env * 0.7)
    return samples


def gen_trap() -> list[float]:
    # Mousetrap snap! Sharp click + metal reverberation
    dur = 0.14
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        snap_env = math.exp(-t * 120.0)
        ring_env = math.exp(-t * 25.0)
        snap = (((i * 4567) % 1000) / 500.0 - 1.0) * snap_env * 0.9
        ring = math.sin(2.0 * math.pi * 1850.0 * t) * ring_env * 0.4
        samples.append(snap + ring)
    return samples


def gen_meow() -> list[float]:
    # Cat meow / hiss
    dur = 0.28
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (t / dur))
        # Frequency rises then falls
        freq = 420.0 + 380.0 * math.sin(math.pi * (t / dur))
        s = math.sin(2.0 * math.pi * freq * t) + 0.25 * math.sin(4.0 * math.pi * freq * t)
        samples.append(s * env * 0.7)
    return samples


def gen_win() -> list[float]:
    # Level Cleared Fanfare
    dur = 0.65
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.5, 1318.5]
    samples = [0.0] * count
    step = int(count / len(notes))

    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.18 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 7.0)
            tone = (math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)) * env * 0.7
            samples[i] += tone
    return samples


def gen_gameover() -> list[float]:
    # Defeat descending sad chime
    dur = 0.60
    count = int(dur * SAMPLE_RATE)
    notes = [440.0, 392.0, 349.23, 261.63]
    samples = [0.0] * count
    step = int(count / len(notes))

    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.18 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 6.0)
            tone = (math.sin(2.0 * math.pi * freq * t) + 0.2 * math.sin(2.0 * math.pi * (freq * 0.5) * t)) * env * 0.75
            samples[i] += tone
    return samples


def main() -> None:
    out_dir = Path(__file__).resolve().parent

    sounds = {
        "rodentsrevenge_step.wav": gen_step(),
        "rodentsrevenge_push.wav": gen_push(),
        "rodentsrevenge_cheese.wav": gen_cheese_spawn(),
        "rodentsrevenge_eat.wav": gen_eat(),
        "rodentsrevenge_trap.wav": gen_trap(),
        "rodentsrevenge_meow.wav": gen_meow(),
        "rodentsrevenge_win.wav": gen_win(),
        "rodentsrevenge_gameover.wav": gen_gameover(),
    }

    for fname, smp in sounds.items():
        p = out_dir / fname
        write_wav(p, smp)
        print(f"Generated {p} ({len(smp)} samples)")


if __name__ == "__main__":
    main()
