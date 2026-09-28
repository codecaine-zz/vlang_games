#!/usr/bin/env python3
"""Synthesize studio-quality 44.1kHz 16-bit mono WAV sound effects for Battleship Pro:
- battleship_sonar.wav: Authentic echoing naval sonar ping
- battleship_launch.wav: Heavy 16-inch artillery whistle & torpedo rocket launch
- battleship_splash.wav: Ocean water geyser splash report (miss)
- battleship_hit.wav: Fiery explosive shell blast report (hit)
- battleship_sunk.wav: Ship hull fracture siren & catastrophic magazine blast
- battleship_victory.wav: Triumphant match victory fanfare
- battleship_place.wav: Metallic warship dock placement latch
- battleship_radar.wav: Reconnaissance radar sweep chirp
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


def gen_sonar() -> list[float]:
    duration = 0.55
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        ping = math.sin(2.0 * math.pi * 1150.0 * t) * math.exp(-6.0 * t)
        echo_t = max(0.0, t - 0.16)
        echo = math.sin(2.0 * math.pi * 920.0 * echo_t) * math.exp(-7.5 * echo_t) * 0.4 if t > 0.16 else 0.0
        samples.append((ping + echo) * 0.85)
    return samples


def gen_launch() -> list[float]:
    duration = 0.26
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 820.0 * math.exp(-t * 6.0) + 120.0
        env = math.exp(-t * 8.0)
        s = math.sin(2.0 * math.pi * freq * t)
        noise = (math.sin(i * 9.1) * 2.0 - 1.0) * 0.25
        samples.append((s + noise) * env * 0.85)
    return samples


def gen_splash() -> list[float]:
    duration = 0.35
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 9.0)
        noise = (math.sin(i * 7.3) * 2.0 - 1.0)
        sweep = math.sin(2.0 * math.pi * (260.0 - 140.0 * (t / duration)) * t) * 0.35
        samples.append((noise * 0.65 + sweep) * env * 0.9)
    return samples


def gen_hit() -> list[float]:
    duration = 0.42
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 7.5)
        noise = (math.sin(i * 13.7) * 2.0 - 1.0)
        sub = math.sin(2.0 * math.pi * 80.0 * t)
        samples.append((noise * 0.65 + sub * 0.45) * env * 0.95)
    return samples


def gen_sunk() -> list[float]:
    duration = 0.75
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 280.0 + math.sin(t * 16.0) * 110.0
        env = math.exp(-t * 2.8)
        s = math.sin(2.0 * math.pi * freq * t)
        noise = (math.sin(i * 5.1) * 2.0 - 1.0) * 0.3
        samples.append((s + noise) * env * 0.9)
    return samples


def gen_victory() -> list[float]:
    notes = [523.25, 659.25, 783.99, 1046.50]
    duration = 0.65
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    note_dur = duration / len(notes)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        n_idx = min(len(notes) - 1, int(t / note_dur))
        freq = notes[n_idx]
        local_t = math.fmod(t, note_dur)
        env = math.exp(-local_t * 7.0)
        s = math.sin(2.0 * math.pi * freq * t)
        harm = math.sin(2.0 * math.pi * (freq * 2.0) * t) * 0.2
        samples.append((s + harm) * env * 0.9)
    return samples


def gen_place() -> list[float]:
    duration = 0.12
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 28.0)
        freq = 440.0 if t < 0.05 else 660.0
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.8)
    return samples


def gen_radar() -> list[float]:
    duration = 0.22
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 1400.0 + 600.0 * (t / duration)
        env = math.sin(math.pi * (t / duration))
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.75)
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sounds_dir = root / "assets" / "sounds"
    sounds_dir.mkdir(parents=True, exist_ok=True)

    generators = {
        "battleship_sonar.wav": gen_sonar,
        "battleship_launch.wav": gen_launch,
        "battleship_splash.wav": gen_splash,
        "battleship_hit.wav": gen_hit,
        "battleship_sunk.wav": gen_sunk,
        "battleship_victory.wav": gen_victory,
        "battleship_place.wav": gen_place,
        "battleship_radar.wav": gen_radar,
    }

    for filename, fn in generators.items():
        out_file = sounds_dir / filename
        samples = fn()
        write_wav(out_file, samples)
        print(f"Generated Battleship sound effect: {out_file.name} ({len(samples)} samples)")

    print(f"Successfully generated {len(generators)} Battleship sound effects!")


if __name__ == "__main__":
    main()
