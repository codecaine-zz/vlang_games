#!/usr/bin/env python3
"""Synthesize studio-quality 44.1kHz 16-bit mono WAV sound effects for GNUjump:
- gnujump_jump.wav: Quick ascending chirp
- gnujump_land.wav: Low solid platform contact thud
- gnujump_wall.wav: Crisp wall bounce click
- gnujump_spring.wav: Bouncy reverberant spring coil launch
- gnujump_crumbly.wav: Cracking stone platform fracture
- gnujump_lava.wav: Sizzling hot lava splash
- gnujump_combo.wav: Ascending cheerful combo chime
- gnujump_click.wav: UI menu selection click
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


def gen_jump() -> list[float]:
    duration = 0.08
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 300.0 + 500.0 * (t / duration)
        env = math.exp(-20.0 * t)
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.9)
    return samples


def gen_land() -> list[float]:
    duration = 0.035
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 180.0
        env = math.exp(-40.0 * t)
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.8)
    return samples


def gen_wall() -> list[float]:
    duration = 0.045
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 420.0 - 200.0 * (t / duration)
        env = math.exp(-35.0 * t)
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.85)
    return samples


def gen_spring() -> list[float]:
    duration = 0.16
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 400.0 + 700.0 * (t / duration)
        env = math.exp(-10.0 * t)
        s = math.sin(2.0 * math.pi * freq * t)
        harm = math.sin(2.0 * math.pi * (freq * 2.0) * t) * 0.3
        samples.append((s + harm) * env * 0.92)
    return samples


def gen_crumbly() -> list[float]:
    duration = 0.10
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        noise = (math.sin(i * 13.7) * 2.0 - 1.0)
        env = math.exp(-22.0 * t)
        samples.append(noise * env * 0.85)
    return samples


def gen_lava() -> list[float]:
    duration = 0.35
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 250.0 - 180.0 * (t / duration)
        noise = (math.sin(i * 8.3) * 2.0 - 1.0) * 0.4
        env = math.exp(-7.5 * t)
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append((s * 0.6 + noise) * env * 0.95)
    return samples


def gen_combo() -> list[float]:
    notes = [523.25, 659.25, 783.99, 1046.50]
    note_dur = 0.06
    duration = note_dur * len(notes)
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        n_idx = min(len(notes) - 1, int(t / note_dur))
        freq = notes[n_idx]
        local_t = math.fmod(t, note_dur)
        env = math.exp(-local_t * 15.0)
        s = math.sin(2.0 * math.pi * freq * t)
        harm = math.sin(2.0 * math.pi * (freq * 2.0) * t) * 0.25
        samples.append((s + harm) * env * 0.9)
    return samples


def gen_click() -> list[float]:
    duration = 0.03
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 700.0
        env = math.exp(-50.0 * t)
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.7)
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sounds_dir = root / "assets" / "sounds"
    sounds_dir.mkdir(parents=True, exist_ok=True)

    generators = {
        "gnujump_jump.wav": gen_jump,
        "gnujump_land.wav": gen_land,
        "gnujump_wall.wav": gen_wall,
        "gnujump_spring.wav": gen_spring,
        "gnujump_crumbly.wav": gen_crumbly,
        "gnujump_lava.wav": gen_lava,
        "gnujump_combo.wav": gen_combo,
        "gnujump_click.wav": gen_click,
    }

    for filename, fn in generators.items():
        out_file = sounds_dir / filename
        samples = fn()
        write_wav(out_file, samples)
        print(f"Generated GNUjump sound effect: {out_file.name} ({len(samples)} samples)")

    print(f"Successfully generated {len(generators)} GNUjump sound effects!")


if __name__ == "__main__":
    main()
