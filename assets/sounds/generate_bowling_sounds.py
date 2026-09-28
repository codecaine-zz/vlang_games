#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Bowling."""
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


def gen_roll() -> list[float]:
    # Heavy ball rumbling along hardwood lane
    dur = 0.5
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 0.05) * math.sin(i * 0.12)) * 0.4 + math.sin(2.0 * math.pi * 90.0 * (i / SAMPLE_RATE)) * 0.3) * (1.0 - i / count * 0.3) for i in range(count)]


def gen_strike() -> list[float]:
    # Explosive 10-pin strike crash
    dur = 0.65
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 543.2) % 1.0) * 2.0 - 1.0) * math.exp(-i / count * 4.0) * 0.95 for i in range(count)]


def gen_hit() -> list[float]:
    # Single crisp pin impact clack
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 880.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 18.0) * 0.8 for i in range(count)]


def gen_gutter() -> list[float]:
    # Ball dropping into gutter channel
    dur = 0.4
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (220.0 - (i / count) * 80.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 5.0) * 0.7 for i in range(count)]


def gen_pinsetter() -> list[float]:
    # Mechanical rack sweep
    dur = 0.45
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 120.0) % 1.0) * 0.5 + math.sin(2.0 * math.pi * 150.0 * (i / SAMPLE_RATE)) * 0.5) * math.exp(-i / count * 3.0) * 0.6 for i in range(count)]


def gen_cheer() -> list[float]:
    # Crowd cheer / applause
    dur = 0.75
    count = int(dur * SAMPLE_RATE)
    return [((math.sin(i * 333.3) % 1.0) * 2.0 - 1.0) * math.sin(i / count * math.pi) * 0.6 for i in range(count)]


def gen_foul() -> list[float]:
    # Foul line buzzer
    dur = 0.3
    count = int(dur * SAMPLE_RATE)
    return [((1.0 if (i % 200) < 100 else -1.0) * 0.5) for i in range(count)]


def gen_win() -> list[float]:
    # Victory celebration fanfare
    dur = 0.8
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50, 1318.51]
    step = int(dur / len(notes) * SAMPLE_RATE)
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.2 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 8.0) * 0.65
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "bowling" / "assets" / "sounds"

    generators = {
        "bowling_roll.wav": gen_roll,
        "bowling_strike.wav": gen_strike,
        "bowling_hit.wav": gen_hit,
        "bowling_gutter.wav": gen_gutter,
        "bowling_pinsetter.wav": gen_pinsetter,
        "bowling_cheer.wav": gen_cheer,
        "bowling_foul.wav": gen_foul,
        "bowling_win.wav": gen_win,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
