#!/usr/bin/env python3
"""Generate studio quality WAV sound effects for Puyo Puyo."""
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


def gen_rotate() -> list[float]:
    # Cute squeaky jelly spin
    dur = 0.05
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        freq = 420.0 + 480.0 * (t / dur)
        env = math.exp(-t * 50.0)
        s = math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
        samples.append(s * env * 0.7)
    return samples


def gen_move() -> list[float]:
    # Soft tactile tap
    dur = 0.03
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 90.0)
        s = math.sin(2.0 * math.pi * 320.0 * t)
        samples.append(s * env * 0.5)
    return samples


def gen_drop() -> list[float]:
    # Squishy landing thud
    dur = 0.08
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        freq = 280.0 * math.exp(-t * 22.0)
        env = math.exp(-t * 28.0)
        s = math.sin(2.0 * math.pi * freq * t) + 0.35 * math.sin(math.pi * freq * t)
        samples.append(s * env * 0.8)
    return samples


def gen_pop() -> list[float]:
    # Juicy bubbly pop
    dur = 0.12
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        freq = 350.0 + 800.0 * math.exp(-t * 30.0)
        env = math.exp(-t * 22.0)
        s = math.sin(2.0 * math.pi * freq * t) + 0.25 * math.sin(3.0 * math.pi * freq * t)
        samples.append(s * env * 0.85)
    return samples


def gen_chain(level: int) -> list[float]:
    # Combo fanfares: 1=Fire(C5), 2=Ice Storm(E5), 3=Diacute(G5), 4=Brain Dumbed(C6), 5=Bayoen!(E6)
    base_freqs = [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98]
    freq = base_freqs[min(level - 1, len(base_freqs) - 1)]
    dur = 0.20 + level * 0.05
    count = int(dur * SAMPLE_RATE)
    samples = []

    for i in range(count):
        t = i / SAMPLE_RATE
        env = math.exp(-t * (10.0 - level * 0.8))
        harm1 = math.sin(2.0 * math.pi * freq * t) * 0.65
        harm2 = math.sin(4.0 * math.pi * freq * t) * 0.30
        harm3 = math.sin(6.0 * math.pi * freq * t) * 0.15
        # Soft chime vibrato
        vib = math.sin(2.0 * math.pi * 6.0 * t) * 12.0
        tone = math.sin(2.0 * math.pi * (freq + vib) * t) * 0.4
        samples.append((harm1 + harm2 + harm3 + tone) * env * 0.8)
    return samples


def gen_win() -> list[float]:
    # Victory ascending arpeggio
    dur = 0.65
    count = int(dur * SAMPLE_RATE)
    notes = [523.25, 659.25, 783.99, 1046.50, 1318.51]
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
            tone = (math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)) * env * 0.75
            samples[i] += tone
    return samples


def gen_gameover() -> list[float]:
    # Squishy defeat descending sigh
    dur = 0.55
    count = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(count):
        t = i / SAMPLE_RATE
        freq = 380.0 * math.exp(-t * 4.0)
        env = math.exp(-t * 4.5)
        s = math.sin(2.0 * math.pi * freq * t) + 0.25 * math.sin(2.0 * math.pi * (freq * 0.5) * t)
        samples.append(s * env * 0.75)
    return samples


def main() -> None:
    out_dir = Path(__file__).resolve().parent

    sounds = {
        "puyopuyo_rotate.wav": gen_rotate(),
        "puyopuyo_move.wav": gen_move(),
        "puyopuyo_drop.wav": gen_drop(),
        "puyopuyo_pop.wav": gen_pop(),
        "puyopuyo_chain1.wav": gen_chain(1),
        "puyopuyo_chain2.wav": gen_chain(2),
        "puyopuyo_chain3.wav": gen_chain(3),
        "puyopuyo_chain4.wav": gen_chain(4),
        "puyopuyo_chain5.wav": gen_chain(5),
        "puyopuyo_win.wav": gen_win(),
        "puyopuyo_gameover.wav": gen_gameover(),
    }

    for fname, smp in sounds.items():
        p = out_dir / fname
        write_wav(p, smp)
        print(f"Generated {p} ({len(smp)} samples)")


if __name__ == "__main__":
    main()
