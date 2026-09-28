#!/usr/bin/env python3
"""Generate 8 studio WAV sound effects for Casino & Card Games (War, Texas Hold'em, Blackjack)."""
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


def gen_deal() -> list[float]:
    # Crisp card slide / deal across green felt
    dur = 0.09
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (800.0 - (i / count) * 400.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 16.0) * 0.7 for i in range(count)]


def gen_flip() -> list[float]:
    # Card flip snap
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (1200.0 - (i / count) * 800.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 20.0) * 0.8 for i in range(count)]


def gen_chips_bet() -> list[float]:
    # Clay poker chips sliding / clacking onto table
    dur = 0.14
    count = int(dur * SAMPLE_RATE)
    return [(math.sin(2.0 * math.pi * 1600.0 * (i / SAMPLE_RATE)) * 0.6 + math.sin(2.0 * math.pi * 2400.0 * (i / SAMPLE_RATE)) * 0.4) * math.exp(-i / count * 12.0) * 0.85 for i in range(count)]


def gen_chips_win() -> list[float]:
    # Big pot chip collection / stacking rattle
    dur = 0.35
    count = int(dur * SAMPLE_RATE)
    samples = [0.0] * count
    clack_times = [0, int(0.08 * SAMPLE_RATE), int(0.16 * SAMPLE_RATE), int(0.24 * SAMPLE_RATE)]
    for st in clack_times:
        for s in range(int(0.06 * SAMPLE_RATE)):
            idx = st + s
            if idx >= count:
                break
            t = s / SAMPLE_RATE
            samples[idx] += math.sin(2.0 * math.pi * 1800.0 * t) * math.exp(-t * 24.0) * 0.5
    return samples


def gen_war_trumpets() -> list[float]:
    # War declared fanfare trumpets
    dur = 0.5
    count = int(dur * SAMPLE_RATE)
    notes = [440.0, 554.37, 659.25, 880.0]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.14 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 8.0) * 0.7
    return samples


def gen_win() -> list[float]:
    # Victory celebratory chime
    dur = 0.4
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.12 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            samples[i] += math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 10.0) * 0.7
    return samples


def gen_lose() -> list[float]:
    # Bust / Fold downbeat
    dur = 0.35
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * (300.0 - (i / count) * 150.0) * (i / SAMPLE_RATE)) * math.exp(-i / count * 6.0) * 0.75 for i in range(count)]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"

    generators = {
        "card_deal.wav": gen_deal,
        "card_flip.wav": gen_flip,
        "chips_bet.wav": gen_chips_bet,
        "chips_win.wav": gen_chips_win,
        "war_trumpets.wav": gen_war_trumpets,
        "casino_win.wav": gen_win,
        "casino_lose.wav": gen_lose,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        for g in ["war", "texas", "blackjack"]:
            write_wav(root / g / "assets" / "sounds" / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
