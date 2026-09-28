#!/usr/bin/env python3
"""Generate authentic arcade WAV sound effects for Space Invaders."""
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
    # Iconic laser pulse zap (900Hz -> 200Hz descending rapidly)
    dur = 0.09
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        freq = 950.0 * math.exp(-t * 25.0)
        env = math.exp(-t * 18.0)
        s = math.sin(2.0 * math.pi * freq * t) + 0.2 * math.sin(3.0 * math.pi * freq * t)
        samples.append(s * env * 0.8)
    return samples


def gen_alien_exp() -> list[float]:
    # Alien pop explosion
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        noise = (((i * 87654) % 1000) / 500.0 - 1.0) * 0.7
        tone = math.sin(2.0 * math.pi * 320.0 * math.exp(-t * 20.0) * t) * 0.3
        env = math.exp(-t * 26.0)
        samples.append((noise + tone) * env * 0.85)
    return samples


def gen_player_exp() -> list[float]:
    # Heavy rumbling ship explosion
    dur = 0.45
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        noise = (((i * 45678) % 1000) / 500.0 - 1.0) * 0.8
        sub = math.sin(2.0 * math.pi * 80.0 * t) * 0.4
        env = math.exp(-t * 7.0)
        samples.append((noise + sub) * env * 0.9)
    return samples


def gen_ufo() -> list[float]:
    # UFO high-pitched warble siren
    dur = 0.30
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        freq = 450.0 + 90.0 * math.sin(2.0 * math.pi * 18.0 * t)
        s = math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(2.0 * math.pi * freq * 2.0 * t)
        env = min(1.0, t * 20.0) * min(1.0, (dur - t) * 15.0)
        samples.append(s * env * 0.6)
    return samples


def gen_march(step: int) -> list[float]:
    # 4-note descending alien march steps (55Hz, 50Hz, 45Hz, 40Hz)
    freqs = [65.0, 58.0, 52.0, 46.0]
    freq = freqs[step % 4]
    dur = 0.07
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 35.0)
        s = math.sin(2.0 * math.pi * freq * t) + 0.4 * math.sin(4.0 * math.pi * freq * t)
        samples.append(s * env * 0.85)
    return samples


def gen_win() -> list[float]:
    # Victory fanfare
    dur = 0.60
    count = int(dur * SAMPLE_RATE)
    notes = [440.0, 554.37, 659.25, 880.0]
    samples = [0.0] * count
    step = int(count / len(notes))

    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.16 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 7.0)
            tone = (math.sin(2.0 * math.pi * freq * t) + 0.25 * math.sin(4.0 * math.pi * freq * t)) * env * 0.75
            samples[i] += tone
    return samples


def main() -> None:
    out_dir = Path(__file__).resolve().parent

    sounds = {
        "spaceinvaders_laser.wav": gen_laser(),
        "spaceinvaders_alien_exp.wav": gen_alien_exp(),
        "spaceinvaders_player_exp.wav": gen_player_exp(),
        "spaceinvaders_ufo.wav": gen_ufo(),
        "spaceinvaders_march1.wav": gen_march(0),
        "spaceinvaders_march2.wav": gen_march(1),
        "spaceinvaders_march3.wav": gen_march(2),
        "spaceinvaders_march4.wav": gen_march(3),
        "spaceinvaders_win.wav": gen_win(),
    }

    for fname, smp in sounds.items():
        p = out_dir / fname
        write_wav(p, smp)
        print(f"Generated {p} ({len(smp)} samples)")


if __name__ == "__main__":
    main()
