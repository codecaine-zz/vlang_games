#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for The Legend of Kage."""
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


def gen_jump() -> list[float]:
    # High soaring ninja leap whoosh
    dur = 0.22
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (250.0 + (i / count) * 450.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 3.5) * 0.75 for i in range(count)]


def gen_slash() -> list[float]:
    # Crisp razor katana blade slice
    dur = 0.14
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (1400.0 - (i / count) * 800.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 15.0) * 0.9 for i in range(count)]


def gen_shuriken() -> list[float]:
    # Metallic 4-point star whistle
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (1800.0 + math.sin(i * 0.08) * 300.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 14.0) * 0.7 for i in range(count)]


def gen_clash() -> list[float]:
    # Metallic blade deflection clash
    dur = 0.18
    count = int(dur * SAMPLE_RATE)
    return [(math.sin(2.0 * math.pi * 2400.0 * (i / SAMPLE_RATE)) * 0.6 + math.sin(2.0 * math.pi * 3600.0 * (i / SAMPLE_RATE)) * 0.4) * math.exp(-i / count * 18.0) * 0.85 for i in range(count)]


def gen_lightning() -> list[float]:
    # Screen-clearing thunderous lightning jutsu
    dur = 0.65
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 222.2) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 4.0) * 0.95 for i in range(count)]


def gen_fire() -> list[float]:
    # Fire monk fiery breath roar
    dur = 0.35
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 140.0 * (i / SAMPLE_RATE)) * ((math.sin(i * 90.0) % 1.0) * 0.6 + 0.4) * math.exp(-i / count * 3.5) * 0.75 for i in range(count)]


def gen_scroll() -> list[float]:
    # Mystical jutsu scroll pickup chime
    dur = 0.4
    count = int(dur * SAMPLE_RATE)
    notes = [587.33, 739.99, 880.00, 1174.66]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.12 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 18.0) * 0.65
    return samples


def gen_stage_clear() -> list[float]:
    # Feudal victory fanfare
    dur = 0.8
    count = int(dur * SAMPLE_RATE)
    notes = [440.00, 587.33, 659.25, 880.00, 932.33, 880.00]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.18 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 9.0) * 0.7
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "legendofkage" / "assets" / "sounds"

    generators = {
        "kage_jump.wav": gen_jump,
        "kage_slash.wav": gen_slash,
        "kage_shuriken.wav": gen_shuriken,
        "kage_clash.wav": gen_clash,
        "kage_lightning.wav": gen_lightning,
        "kage_fire.wav": gen_fire,
        "kage_scroll.wav": gen_scroll,
        "kage_stage_clear.wav": gen_stage_clear,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
