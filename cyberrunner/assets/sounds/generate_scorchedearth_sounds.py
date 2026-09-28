#!/usr/bin/env python3
"""Synthesize studio-quality 44.1kHz 16-bit mono WAV sound effects for Scorched Earth:
- scorched_shot.wav: Cannon blast report
- scorched_nuke_launch.wav: Heavy missile rocket launch whoosh
- scorched_mirv_split.wav: Warhead cluster separation pop
- scorched_drill.wav: Digger underground high-speed drill whir
- scorched_napalm.wav: Roaring liquid fire chemical flame cascade
- scorched_dirt.wav: Earthen mountain mover thud
- scorched_explosion.wav: Standard artillery explosion crunch
- scorched_nuke_detonate.wav: Massive apocalyptic thermonuclear explosion rumble
- scorched_cash.wav: Cash register purchase chime
- scorched_select.wav: Weapon selection click
- scorched_win.wav: Triumphant match victory fanfare
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


def gen_shot() -> list[float]:
    duration = 0.22
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 22.0)
        freq = 240.0 * math.exp(-t * 16.0) + 45.0
        s = math.sin(2.0 * math.pi * freq * t)
        noise = (math.sin(i * 9.1) * 2.0 - 1.0) * math.exp(-t * 35.0)
        samples.append((s * 0.7 + noise * 0.5) * env * 0.9)
    return samples


def gen_nuke_launch() -> list[float]:
    duration = 0.28
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 120.0 + 320.0 * (t / duration)
        sub = math.sin(2.0 * math.pi * freq * t)
        noise = (math.sin(i * 4.3) * 2.0 - 1.0) * 0.4
        env = (1.0 - (t / duration) * 0.3) * math.exp(-t * 6.0)
        samples.append((sub + noise) * env * 0.9)
    return samples


def gen_mirv_split() -> list[float]:
    duration = 0.12
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 35.0)
        freq = 920.0 * math.exp(-t * 20.0)
        s = math.sin(2.0 * math.pi * freq * t)
        noise = (math.sin(i * 12.1) * 2.0 - 1.0) * 0.3
        samples.append((s + noise) * env * 0.85)
    return samples


def gen_drill() -> list[float]:
    duration = 0.25
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 600.0 + math.sin(t * 120.0) * 180.0
        wave_val = math.sin(2.0 * math.pi * freq * t)
        grind = (math.sin(i * 18.7) * 2.0 - 1.0) * 0.4
        env = math.sin(math.pi * (t / duration))
        samples.append((wave_val * 0.6 + grind * 0.4) * env * 0.8)
    return samples


def gen_napalm() -> list[float]:
    duration = 0.26
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        noise = (math.sin(i * 3.7) * 2.0 - 1.0)
        freq = 160.0 + 80.0 * math.sin(t * 40.0)
        sub = math.sin(2.0 * math.pi * freq * t)
        env = math.exp(-t * 7.0)
        samples.append((noise * 0.65 + sub * 0.35) * env * 0.85)
    return samples


def gen_dirt() -> list[float]:
    duration = 0.24
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 110.0 * math.exp(-t * 12.0) + 40.0
        sub = math.sin(2.0 * math.pi * freq * t)
        noise = (math.sin(i * 7.7) * 2.0 - 1.0) * 0.5
        env = math.exp(-t * 10.0)
        samples.append((sub * 0.7 + noise * 0.4) * env * 0.9)
    return samples


def gen_explosion() -> list[float]:
    duration = 0.38
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        noise = (math.sin(i * 11.3) * 2.0 - 1.0)
        sub = math.sin(2.0 * math.pi * 85.0 * t)
        env = math.exp(-t * 9.0)
        samples.append((noise * 0.7 + sub * 0.4) * env * 0.95)
    return samples


def gen_nuke_detonate() -> list[float]:
    duration = 0.75
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        noise = (math.sin(i * 13.9) * 2.0 - 1.0)
        sub = math.sin(2.0 * math.pi * 45.0 * t) + math.sin(2.0 * math.pi * 30.0 * t) * 0.5
        env = math.exp(-t * 3.8)
        samples.append((noise * 0.6 + sub * 0.5) * env * 0.98)
    return samples


def gen_cash() -> list[float]:
    duration = 0.20
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 1318.51 if t < 0.08 else 1760.00 # E6 -> A6
        env = math.exp(-math.fmod(t, 0.08) * 25.0)
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.8)
    return samples


def gen_select() -> list[float]:
    duration = 0.06
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 660.0 + 440.0 * (t / duration)
        s = math.sin(2.0 * math.pi * freq * t)
        env = 1.0 - (t / duration)
        samples.append(s * env * 0.75)
    return samples


def gen_win() -> list[float]:
    notes = [523.25, 659.25, 783.99, 1046.50] # C major fanfare
    note_dur = 0.12
    samples = []
    for freq in notes:
        n_samples = int(SAMPLE_RATE * note_dur)
        for i in range(n_samples):
            t = i / SAMPLE_RATE
            sine = math.sin(2.0 * math.pi * freq * t)
            harm = math.sin(2.0 * math.pi * freq * 2.0 * t) * 0.25
            env = 1.0 - (i / n_samples) * 0.3
            samples.append((sine + harm) * env * 0.8)
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sounds_dir = root / "assets" / "sounds"
    sounds_dir.mkdir(parents=True, exist_ok=True)

    generators = {
        "scorched_shot.wav": gen_shot,
        "scorched_nuke_launch.wav": gen_nuke_launch,
        "scorched_mirv_split.wav": gen_mirv_split,
        "scorched_drill.wav": gen_drill,
        "scorched_napalm.wav": gen_napalm,
        "scorched_dirt.wav": gen_dirt,
        "scorched_explosion.wav": gen_explosion,
        "scorched_nuke_detonate.wav": gen_nuke_detonate,
        "scorched_cash.wav": gen_cash,
        "scorched_select.wav": gen_select,
        "scorched_win.wav": gen_win,
    }

    for filename, fn in generators.items():
        out_file = sounds_dir / filename
        samples = fn()
        write_wav(out_file, samples)
        print(f"Generated Scorched sound effect: {out_file.name} ({len(samples)} samples)")

    print(f"Successfully generated {len(generators)} Scorched Earth sound effects!")


if __name__ == "__main__":
    main()
