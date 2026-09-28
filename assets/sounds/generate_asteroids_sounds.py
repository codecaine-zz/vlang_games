#!/usr/bin/env python3
"""Generate 9 studio WAV sound effects for Asteroids."""
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


def gen_shoot() -> list[float]:
    # Crisp arcade photon blaster
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (1100.0 - (i / count) * 750.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 12.0) * 0.85 for i in range(count)]


def gen_thrust() -> list[float]:
    # Rocket thrust flame whoosh
    dur = 0.15
    count = int(dur * SAMPLE_RATE)
    return [(((i * 12345) % 1000) / 500.0 - 1.0) * (0.6 + 0.4 * math.sin(i * 0.05)) * math.exp(-i / count * 5.0) * 0.65 for i in range(count)]


def gen_explode_lg() -> list[float]:
    # Massive asteroid blast
    dur = 0.45
    count = int(dur * SAMPLE_RATE)
    return [((((i * 65432) % 1000) / 500.0 - 1.0) * 0.6 + math.sin(2.0 * math.pi * (160.0 - (i / count) * 120.0) * (i / SAMPLE_RATE)) * 0.4) * math.exp(-i / count * 4.0) * 0.9 for i in range(count)]


def gen_explode_sm() -> list[float]:
    # Small rock fragmentation
    dur = 0.2
    count = int(dur * SAMPLE_RATE)
    return [((((i * 43210) % 1000) / 500.0 - 1.0) * 0.7 + math.sin(2.0 * math.pi * 350.0 * (i / SAMPLE_RATE)) * 0.3) * math.exp(-i / count * 8.0) * 0.8 for i in range(count)]


def gen_ufo_spawn() -> list[float]:
    # Warbling alien saucer alert
    dur = 0.35
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (600.0 + math.sin(i * 0.04) * 250.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 3.5) * 0.75 for i in range(count)]


def gen_ufo_fire() -> list[float]:
    # Alien plasma shot
    dur = 0.1
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (800.0 + (i / count) * 400.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 14.0) * 0.8 for i in range(count)]


def gen_powerup() -> list[float]:
    # Power-up chime
    dur = 0.28
    count = int(dur * SAMPLE_RATE)
    notes = [659.25, 880.0, 1174.66, 1567.98]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.09 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 12.0) * 0.7
    return samples


def gen_shield() -> list[float]:
    # Forcefield deflection zap
    dur = 0.18
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (450.0 + math.sin(i * 0.1) * 350.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 8.0) * 0.85 for i in range(count)]


def gen_hyperspace() -> list[float]:
    # Dimensional warp whoosh
    dur = 0.35
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (200.0 + (i / count) * 1200.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 4.0) * 0.8 for i in range(count)]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "asteroids" / "assets" / "sounds"

    generators = {
        "asteroids_shoot.wav": gen_shoot,
        "asteroids_thrust.wav": gen_thrust,
        "asteroids_explode_lg.wav": gen_explode_lg,
        "asteroids_explode_sm.wav": gen_explode_sm,
        "asteroids_ufo_spawn.wav": gen_ufo_spawn,
        "asteroids_ufo_fire.wav": gen_ufo_fire,
        "asteroids_powerup.wav": gen_powerup,
        "asteroids_shield.wav": gen_shield,
        "asteroids_hyperspace.wav": gen_hyperspace,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
