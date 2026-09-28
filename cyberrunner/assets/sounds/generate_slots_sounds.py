#!/usr/bin/env python3
"""Generate rewarding and negative studio WAV sound effects for Slots."""
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


def gen_lever() -> list[float]:
    dur = 0.22
    count = int(dur * SAMPLE_RATE)
    return [(1.0 if math.sin(2.0 * math.pi * (160.0 + (i / count) * 200.0) * (i / SAMPLE_RATE)) > 0 else -1.0) * math.exp(-i / count * 8.0) * 0.75 for i in range(count)]


def gen_spin() -> list[float]:
    dur = 0.16
    count = int(dur * SAMPLE_RATE)
    return [(((i * 5431) % 1000) / 500.0 - 1.0) * math.sin(2.0 * math.pi * 180.0 * (i / SAMPLE_RATE)) * 0.4 for i in range(count)]


def gen_stop() -> list[float]:
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    return [(math.sin(2.0 * math.pi * 220.0 * (i / SAMPLE_RATE)) + (((i * 8765) % 1000) / 500.0 - 1.0) * 0.4) * math.exp(-i / count * 18.0) * 0.85 for i in range(count)]


def gen_win() -> list[float]:
    # Ultra-rewarding casino credit roll chime / ascending bright bell chords
    dur = 0.65
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50, 1318.51]  # C5, E5, G5, C6, E6
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.20 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            # Crystal bell harmonics (1x, 2x, 3x, 4.2x)
            bell = (math.sin(2.0 * math.pi * freq * t) * 0.6 +
                    math.sin(4.0 * math.pi * freq * t) * 0.3 +
                    math.sin(6.0 * math.pi * freq * t) * 0.15 +
                    math.sin(8.4 * math.pi * freq * t) * 0.1)
            samples[i] += bell * math.exp(-t * 7.5) * 0.80
    return samples


def gen_jackpot() -> list[float]:
    # Mega Jackpot celebratory casino fanfare with sparkling bells & victory sirens
    dur = 1.35
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98, 2093.00]
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.28 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            siren = math.sin(2.0 * math.pi * (freq + math.sin(35.0 * t) * 45.0) * t)
            harm = math.sin(4.0 * math.pi * freq * t) * 0.3
            samples[i] += (siren + harm) * math.exp(-t * 4.0) * 0.85
    return samples


def gen_lose() -> list[float]:
    # Negative low disappointment tone / "whomp-whomp" casino defeat buzzer
    dur = 0.45
    count = int(dur * SAMPLE_RATE)
    notes = [293.66, 261.63, 220.00]  # D4, C4, A3 (descending minor)
    step = int(count / len(notes))
    samples = [0.0] * count
    for idx, freq in enumerate(notes):
        st = idx * step
        for s in range(int(0.18 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            # Buzz tone with low square/sawtooth odd harmonics
            saw = (math.sin(2.0 * math.pi * freq * t) * 0.6 +
                   math.sin(4.0 * math.pi * freq * t) * 0.3 +
                   math.sin(6.0 * math.pi * freq * t) * 0.15)
            # Low vibrato wobble
            wobble = 1.0 + 0.15 * math.sin(2.0 * math.pi * 12.0 * t)
            samples[i] += saw * wobble * math.exp(-t * 6.0) * 0.75
    return samples


def gen_hold() -> list[float]:
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    return [math.sin(2.0 * math.pi * 880.0 * (i / SAMPLE_RATE)) * math.exp(-i / count * 22.0) * 0.75 for i in range(count)]


def gen_coin() -> list[float]:
    dur = 0.25
    count = int(dur * SAMPLE_RATE)
    samples = [0.0] * count
    # Multiple coin pings
    for p in range(4):
        offset = int(p * 0.05 * SAMPLE_RATE)
        f = 2200.0 + p * 350.0
        for s in range(int(0.08 * SAMPLE_RATE)):
            i = offset + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            ping = math.sin(2.0 * math.pi * f * t) + math.sin(2.0 * math.pi * (f * 1.5) * t) * 0.4
            samples[i] += ping * math.exp(-t * 28.0) * 0.55
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sfx_dir = root / "assets" / "sounds"
    local_sfx_dir = root / "slots" / "assets" / "sounds"

    generators = {
        "slots_lever.wav": gen_lever,
        "slots_spin.wav": gen_spin,
        "slots_stop.wav": gen_stop,
        "slots_win.wav": gen_win,
        "slots_jackpot.wav": gen_jackpot,
        "slots_lose.wav": gen_lose,
        "slots_hold.wav": gen_hold,
        "slots_coin.wav": gen_coin,
    }

    for name, gen in generators.items():
        data = gen()
        write_wav(sfx_dir / name, data)
        write_wav(local_sfx_dir / name, data)
        print(f"Generated {name}")


if __name__ == "__main__":
    main()
