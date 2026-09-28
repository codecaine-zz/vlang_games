#!/usr/bin/env python3
"""Synthesize studio-quality 44.1kHz 16-bit mono WAV sound effects for Championship Darts Pro:
- darts_thud.wav: Solid sisal fiber dartboard impact thud
- darts_double.wav: Clean double ring chime
- darts_triple.wav: High resonant triple ring chime
- darts_bullseye.wav: Double bullseye bell chime & resonance
- darts_180.wav: Triumphant brass victory / 180 fanfare
- darts_throw.wav: Swift dart aerodynamic flight whoosh
- darts_bust.wav: Classic buzzer / groan for bust
- darts_chalk.wav: Chalkboard write click
"""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        raw_bytes = bytearray()
        for s in samples:
            clamped = max(-1.0, min(1.0, s))
            val = int(clamped * 32767.0)
            raw_bytes.extend(struct.pack("<h", val))
        wav_file.writeframes(raw_bytes)


def gen_thud() -> list[float]:
    duration = 0.12
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        noise = (math.sin(i * 11.3) * 2.0 - 1.0) * math.exp(-35.0 * t) * 0.7
        tone = math.sin(2.0 * math.pi * 140.0 * t) * math.exp(-22.0 * t) * 0.8
        samples.append((noise + tone) * 0.85)
    return samples


def gen_double() -> list[float]:
    duration = 0.25
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        decay = math.exp(-10.0 * t)
        s = math.sin(2.0 * math.pi * 880.0 * t) * decay * 0.8
        samples.append(s)
    return samples


def gen_triple() -> list[float]:
    duration = 0.30
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        decay = math.exp(-8.0 * t)
        s = (math.sin(2.0 * math.pi * 1174.66 * t) + math.sin(2.0 * math.pi * 1760.0 * t) * 0.3) * decay * 0.85
        samples.append(s)
    return samples


def gen_bullseye() -> list[float]:
    duration = 0.45
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        decay = math.exp(-6.0 * t)
        s = (math.sin(2.0 * math.pi * 1046.50 * t) + math.sin(2.0 * math.pi * 1318.51 * t) + math.sin(2.0 * math.pi * 2093.0 * t) * 0.25) * decay * 0.75
        samples.append(s)
    return samples


def gen_180() -> list[float]:
    notes = [523.25, 659.25, 783.99, 1046.50, 1318.51]
    duration = 0.80
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    note_dur = duration / len(notes)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        n_idx = min(len(notes) - 1, int(t / note_dur))
        freq = notes[n_idx]
        local_t = math.fmod(t, note_dur)
        env = math.exp(-local_t * 6.0)
        s = math.sin(2.0 * math.pi * freq * t)
        harm = math.sin(2.0 * math.pi * (freq * 2.0) * t) * 0.25
        samples.append((s + harm) * env * 0.9)
    return samples


def gen_throw() -> list[float]:
    duration = 0.14
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (t / duration))
        sweep = math.sin(2.0 * math.pi * (400.0 - 200.0 * (t / duration)) * t) * 0.4
        noise = (math.sin(i * 7.7) * 2.0 - 1.0) * 0.6
        samples.append((sweep + noise) * env * 0.7)
    return samples


def gen_bust() -> list[float]:
    duration = 0.35
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        sq = 0.4 if math.sin(2.0 * math.pi * 110.0 * t) > 0 else -0.4
        samples.append(sq * math.exp(-3.5 * t) * 0.85)
    return samples


def gen_chalk() -> list[float]:
    duration = 0.04
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 90.0)
        s = math.sin(2.0 * math.pi * 750.0 * t)
        samples.append(s * env * 0.7)
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sounds_dir = root / "assets" / "sounds"
    sounds_dir.mkdir(parents=True, exist_ok=True)

    generators = {
        "darts_thud.wav": gen_thud,
        "darts_double.wav": gen_double,
        "darts_triple.wav": gen_triple,
        "darts_bullseye.wav": gen_bullseye,
        "darts_180.wav": gen_180,
        "darts_throw.wav": gen_throw,
        "darts_bust.wav": gen_bust,
        "darts_chalk.wav": gen_chalk,
    }

    for filename, fn in generators.items():
        out_file = sounds_dir / filename
        samples = fn()
        write_wav(out_file, samples)
        print(f"Generated Darts sound effect: {out_file.name} ({len(samples)} samples)")

    print(f"Successfully generated {len(generators)} Darts sound effects!")


if __name__ == "__main__":
    main()
