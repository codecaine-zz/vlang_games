#!/usr/bin/env python3
"""Synthesize studio-quality 44.1kHz 16-bit mono WAV sound effects for Chip's Challenge Deluxe:
- chip_step.wav: Clean, crisp retro footstep click
- chip_collect.wav: Bright harmonic microchip pickup chime
- chip_key.wav: Antique brass key chime & rattle
- chip_door.wav: Heavy sliding vault door unlock
- chip_socket.wav: High-tech chip barrier unlock sequence
- chip_win.wav: Triumphant level complete fanfare & portal resonance
- chip_death.wav: Classic arcade "oops" loss jingle
- chip_push.wav: Stone boulder sliding scrape
- chip_boot.wav: Gear equipping chime
- chip_splash.wav: Ocean/water hazard splash
- chip_burn.wav: Sizzling flame trap burn
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


def gen_step() -> list[float]:
    duration = 0.035
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 110.0)
        s = math.sin(2.0 * math.pi * 620.0 * t)
        samples.append(s * env * 0.7)
    return samples


def gen_collect() -> list[float]:
    # Bright 2-note microchip chime (E6 -> B6)
    duration = 0.14
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 1318.51 if t < 0.07 else 1975.53
        local_t = t if t < 0.07 else (t - 0.07)
        env = math.exp(-local_t * 32.0)
        s = math.sin(2.0 * math.pi * freq * t)
        harm = math.sin(2.0 * math.pi * (freq * 2.0) * t) * 0.25
        samples.append((s + harm) * env * 0.85)
    return samples


def gen_key() -> list[float]:
    # Key pickup jingle (A5 -> D6)
    duration = 0.15
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 880.0 if t < 0.075 else 1174.66
        local_t = t if t < 0.075 else (t - 0.075)
        env = math.exp(-local_t * 26.0)
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.8)
    return samples


def gen_door() -> list[float]:
    # Heavy door unlock & sliding rumble
    duration = 0.22
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 14.0)
        freq = 280.0 * math.exp(-t * 8.0) + 90.0
        s = math.sin(2.0 * math.pi * freq * t)
        noise = (math.sin(i * 7.9) * 2.0 - 1.0) * 0.35
        samples.append((s * 0.65 + noise * 0.35) * env * 0.9)
    return samples


def gen_socket() -> list[float]:
    # Ascending 4-tone security deactivation arpeggio (C5 -> E5 -> G5 -> C6)
    notes = [523.25, 659.25, 783.99, 1046.50]
    duration = 0.28
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    note_dur = duration / len(notes)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        n_idx = min(len(notes) - 1, int(t / note_dur))
        freq = notes[n_idx]
        local_t = math.fmod(t, note_dur)
        env = math.exp(-local_t * 20.0)
        s = math.sin(2.0 * math.pi * freq * t)
        harm = math.sin(2.0 * math.pi * (freq * 1.5) * t) * 0.2
        samples.append((s + harm) * env * 0.85)
    return samples


def gen_win() -> list[float]:
    # Triumphant 5-note portal victory fanfare
    notes = [523.25, 659.25, 783.99, 1046.50, 1318.51]
    duration = 0.55
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    note_dur = duration / len(notes)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        n_idx = min(len(notes) - 1, int(t / note_dur))
        freq = notes[n_idx]
        local_t = math.fmod(t, note_dur)
        env = math.exp(-local_t * 9.0)
        s = math.sin(2.0 * math.pi * freq * t)
        harm = math.sin(2.0 * math.pi * (freq * 2.0) * t) * 0.25
        samples.append((s + harm) * env * 0.9)
    return samples


def gen_death() -> list[float]:
    # Classic descending arcade fail slide
    duration = 0.35
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 480.0 * math.exp(-t * 9.0) + 60.0
        env = math.exp(-t * 7.0)
        s = math.sin(2.0 * math.pi * freq * t)
        noise = (math.sin(i * 11.3) * 2.0 - 1.0) * 0.25
        samples.append((s * 0.75 + noise * 0.25) * env * 0.95)
    return samples


def gen_push() -> list[float]:
    # Heavy stone scraping friction
    duration = 0.16
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (t / duration))
        scrape = (math.sin(i * 14.3) * 2.0 - 1.0) * 0.5
        sub = math.sin(2.0 * math.pi * 120.0 * t) * 0.5
        samples.append((scrape + sub) * env * 0.8)
    return samples


def gen_boot() -> list[float]:
    # Power equipment equip fanfare (G5 -> C6)
    duration = 0.18
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 783.99 if t < 0.09 else 1046.50
        local_t = t if t < 0.09 else (t - 0.09)
        env = math.exp(-local_t * 22.0)
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.85)
    return samples


def gen_splash() -> list[float]:
    # Water splash
    duration = 0.22
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 14.0)
        noise = (math.sin(i * 5.7) * 2.0 - 1.0) * 0.7
        sweep = math.sin(2.0 * math.pi * (340.0 - 220.0 * (t / duration)) * t) * 0.3
        samples.append((noise + sweep) * env * 0.85)
    return samples


def gen_burn() -> list[float]:
    # Sizzling burn
    duration = 0.24
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 12.0)
        hiss = (math.sin(i * 17.1) * 2.0 - 1.0) * 0.8
        sub = math.sin(2.0 * math.pi * 180.0 * t) * 0.2
        samples.append((hiss + sub) * env * 0.9)
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sounds_dir = root / "assets" / "sounds"
    sounds_dir.mkdir(parents=True, exist_ok=True)

    generators = {
        "chip_step.wav": gen_step,
        "chip_collect.wav": gen_collect,
        "chip_key.wav": gen_key,
        "chip_door.wav": gen_door,
        "chip_socket.wav": gen_socket,
        "chip_win.wav": gen_win,
        "chip_death.wav": gen_death,
        "chip_push.wav": gen_push,
        "chip_boot.wav": gen_boot,
        "chip_splash.wav": gen_splash,
        "chip_burn.wav": gen_burn,
    }

    for filename, fn in generators.items():
        out_file = sounds_dir / filename
        samples = fn()
        write_wav(out_file, samples)
        print(f"Generated Chip's Challenge sound effect: {out_file.name} ({len(samples)} samples)")

    print(f"Successfully generated {len(generators)} Chip's Challenge sound effects!")


if __name__ == "__main__":
    main()
