#!/usr/bin/env python3
"""Synthesize studio-quality 44.1kHz 16-bit mono WAV sound effects for Duke Nukem:
- duke_laser.wav: Standard blaster plasma shot
- duke_dual_laser.wav: Heavy twin laser cannon blast
- duke_flame.wav: Roaring flamethrower combustion
- duke_missile.wav: High-velocity micro rocket launch
- duke_explosion.wav: Heavy mechanical / crate explosion crunch
- duke_jump.wav: Springy acrobatic somersault jump
- duke_pickup.wav: Item collection chime (soda, turkey, disks)
- duke_keycard.wav: Security keycard access chime
- duke_win.wav: Triumphant mission cleared fanfare
- duke_hurt.wav: Player damage impact warning
- duke_camera.wav: Surveillance camera short-circuit pop
- duke_elevator.wav: Mechanical elevator motor hum
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


def gen_laser() -> list[float]:
    duration = 0.09
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 920.0 - 620.0 * (t / duration)
        sine = math.sin(2.0 * math.pi * freq * t)
        env = 1.0 - (t / duration)
        samples.append(sine * env * 0.85)
    return samples


def gen_dual_laser() -> list[float]:
    duration = 0.12
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        f1 = 1200.0 - 750.0 * (t / duration)
        f2 = 900.0 - 550.0 * (t / duration)
        sine = math.sin(2.0 * math.pi * f1 * t) * 0.6 + math.sin(2.0 * math.pi * f2 * t) * 0.4
        env = 1.0 - (t / duration)
        samples.append(sine * env * 0.9)
    return samples


def gen_flame() -> list[float]:
    duration = 0.14
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        noise = (math.sin(i * 3.3) * 2.0 - 1.0)
        freq = 200.0 + 80.0 * math.sin(t * 50.0)
        sub = math.sin(2.0 * math.pi * freq * t)
        env = 1.0 - (t / duration)
        samples.append((noise * 0.6 + sub * 0.4) * env * 0.85)
    return samples


def gen_missile() -> list[float]:
    duration = 0.18
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 260.0 + 420.0 * (t / duration)
        sine = math.sin(2.0 * math.pi * freq * t)
        noise = (math.sin(i * 7.1) * 2.0 - 1.0) * 0.35
        env = (1.0 - (t / duration) * 0.5) * math.exp(-t * 8.0)
        samples.append((sine + noise) * env * 0.9)
    return samples


def gen_explosion() -> list[float]:
    duration = 0.32
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        noise = (math.sin(i * 11.7) * 2.0 - 1.0)
        sub = math.sin(2.0 * math.pi * 90.0 * t) * math.exp(-t * 4.0)
        env = math.exp(-t * 8.0)
        samples.append((noise * 0.7 + sub * 0.4) * env * 0.95)
    return samples


def gen_jump() -> list[float]:
    duration = 0.10
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 220.0 + 340.0 * (t / duration)
        sine = math.sin(2.0 * math.pi * freq * t)
        env = 1.0 - (t / duration)
        samples.append(sine * env * 0.75)
    return samples


def gen_pickup() -> list[float]:
    notes = [523.25, 659.25, 783.99] # C5, E5, G5
    note_dur = 0.05
    samples = []
    for freq in notes:
        n_samples = int(SAMPLE_RATE * note_dur)
        for i in range(n_samples):
            t = i / SAMPLE_RATE
            sine = math.sin(2.0 * math.pi * freq * t)
            env = math.exp(-t * 15.0)
            samples.append(sine * env * 0.75)
    return samples


def gen_keycard() -> list[float]:
    notes = [880.0, 1174.66, 1760.0] # A5, D6, A6
    note_dur = 0.06
    samples = []
    for freq in notes:
        n_samples = int(SAMPLE_RATE * note_dur)
        for i in range(n_samples):
            t = i / SAMPLE_RATE
            sine = math.sin(2.0 * math.pi * freq * t)
            harm = math.sin(2.0 * math.pi * freq * 2.0 * t) * 0.25
            env = math.exp(-t * 12.0)
            samples.append((sine + harm) * env * 0.8)
    return samples


def gen_win() -> list[float]:
    notes = [440.0, 554.37, 659.25, 880.0, 1108.73] # A major triumphant fanfare
    note_dur = 0.10
    samples = []
    for freq in notes:
        n_samples = int(SAMPLE_RATE * note_dur)
        for i in range(n_samples):
            t = i / SAMPLE_RATE
            sine = math.sin(2.0 * math.pi * freq * t)
            harm = math.sin(2.0 * math.pi * freq * 3.0 * t) * 0.3
            env = 1.0 - (i / n_samples) * 0.4
            samples.append((sine + harm) * env * 0.8)
    return samples


def gen_hurt() -> list[float]:
    duration = 0.14
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 150.0 * math.exp(-t * 15.0) + 50.0
        sub = math.sin(2.0 * math.pi * freq * t)
        noise = (math.sin(i * 5.7) * 2.0 - 1.0) * 0.35
        env = math.exp(-t * 20.0)
        samples.append((sub + noise) * env * 0.85)
    return samples


def gen_camera() -> list[float]:
    duration = 0.12
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        noise = (math.sin(i * 13.1) * 2.0 - 1.0)
        freq = 1400.0 * math.exp(-t * 30.0)
        sine = math.sin(2.0 * math.pi * freq * t)
        env = math.exp(-t * 25.0)
        samples.append((noise * 0.6 + sine * 0.4) * env * 0.8)
    return samples


def gen_elevator() -> list[float]:
    duration = 0.15
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 120.0 + math.sin(t * 30.0) * 15.0
        wave_val = math.sin(2.0 * math.pi * freq * t)
        env = math.sin(math.pi * (t / duration))
        samples.append(wave_val * env * 0.6)
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sounds_dir = root / "assets" / "sounds"
    sounds_dir.mkdir(parents=True, exist_ok=True)

    generators = {
        "duke_laser.wav": gen_laser,
        "duke_dual_laser.wav": gen_dual_laser,
        "duke_flame.wav": gen_flame,
        "duke_missile.wav": gen_missile,
        "duke_explosion.wav": gen_explosion,
        "duke_jump.wav": gen_jump,
        "duke_pickup.wav": gen_pickup,
        "duke_keycard.wav": gen_keycard,
        "duke_win.wav": gen_win,
        "duke_hurt.wav": gen_hurt,
        "duke_camera.wav": gen_camera,
        "duke_elevator.wav": gen_elevator,
    }

    for filename, fn in generators.items():
        out_file = sounds_dir / filename
        samples = fn()
        write_wav(out_file, samples)
        print(f"Generated Duke sound effect: {out_file.name} ({len(samples)} samples)")

    print(f"Successfully generated {len(generators)} Duke Nukem sound effects!")


if __name__ == "__main__":
    main()
