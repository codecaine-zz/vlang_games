#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Zuma Deluxe."""
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


def gen_fire() -> list[float]:
    # Frog idol mouth orb shot thwap
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (350.0 + (i / count) * 450.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 10.0) * 0.8 for i in range(count)]


def gen_match() -> list[float]:
    # 3-marble match pop chime
    dur = 0.18
    count = int(dur * SAMPLE_RATE)
    return [(math.sin(2.0 * math.pi * 523.25 * (i / SAMPLE_RATE)) * 0.6 + math.sin(2.0 * math.pi * 1046.50 * (i / SAMPLE_RATE)) * 0.4) * math.exp(-i / count * 9.0) * 0.85 for i in range(count)]


def gen_combo() -> list[float]:
    # Multi-chain combo Aztec chime
    dur = 0.35
    count = int(dur * SAMPLE_RATE)
    notes = [659.25, 783.99, 1046.50, 1318.51]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.12 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 14.0) * 0.7
    return samples


def gen_bomb() -> list[float]:
    # Explosive bomb marble blast
    dur = 0.45
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 180.0) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 5.0) * 0.95 for i in range(count)]


def gen_slow() -> list[float]:
    # Time warp slowdown whoosh
    dur = 0.3
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (600.0 - (i / count) * 350.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 3.5) * 0.75 for i in range(count)]


def gen_reverse() -> list[float]:
    # Reverse roll magnetic pull
    dur = 0.25
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (200.0 + (i / count) * 400.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 4.0) * 0.75 for i in range(count)]


def gen_skull() -> list[float]:
    # Skull warning roar
    dur = 0.5
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 80.0 * (i / SAMPLE_RATE)) * ((math.sin(i * 45.0) % 1.0) * 0.5 + 0.5) * math.exp(-i / count * 3.0) * 0.85 for i in range(count)]


def gen_win() -> list[float]:
    # Temple cleared Aztec celebration fanfare
    dur = 0.7
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.16 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 9.0) * 0.7
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "zuma" / "assets" / "sounds"

    generators = {
        "zuma_fire.wav": gen_fire,
        "zuma_match.wav": gen_match,
        "zuma_combo.wav": gen_combo,
        "zuma_bomb.wav": gen_bomb,
        "zuma_slow.wav": gen_slow,
        "zuma_reverse.wav": gen_reverse,
        "zuma_skull.wav": gen_skull,
        "zuma_win.wav": gen_win,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
