#!/usr/bin/env python3
"""Synthesize studio-quality 44.1kHz 16-bit mono WAV sound effects for Vampire Survivors:
- vs_whip.wav: Crack and snap of a heavy leather whip
- vs_wand.wav: Mystic magical spark bolt shot
- vs_knife.wav: Swift throwing dagger zip and whoosh
- vs_axe.wav: Heavy spinning iron battleaxe whoosh
- vs_bible.wav: Resonant sacred choral chime / orbital hum
- vs_lightning.wav: Sharp crackling thunderclap strike
- vs_fire.wav: Combustion explosion whoosh
- vs_nuke.wav: Apocalyptic seismic detonation and low rumble
- vs_laser.wav: Sci-fi prismatic laser beam zap
- vs_hit.wav: Meaty combat impact punch
- vs_kill.wav: Satisfying enemy splat crunch
- vs_smash.wav: Ceramic urn / candelabra shattering crash
- vs_gem.wav: High crystal sapphire ding
- vs_gem_big.wav: Deep emerald/ruby jewel resonance
- vs_item.wav: Pleasant item pickup chime
- vs_heal.wav: Radiant healing chime
- vs_freeze.wav: Glacial crystallization freeze
- vs_hurt.wav: Player damage impact warning
- vs_levelup.wav: Triumphant ascending 4-note arpeggio chime
- vs_chest.wav: Glorious celebratory fanfare
- vs_evolve.wav: Legendary weapon evolution orchestral fanfare
- vs_ultimate.wav: Screen-shaking catastrophic ultimate sonic boom
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


def gen_whip() -> list[float]:
    duration = 0.18
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Fast exponential pitch drop + noise snap
        freq = 1200.0 * math.exp(-t * 35.0) + 120.0
        wave_val = math.sin(2.0 * math.pi * freq * t)
        noise = (math.sin(i * 3.7) * 2.0 - 1.0) * 0.5
        env = math.exp(-t * 22.0)
        # Whip tip snap transient
        snap = math.sin(2.0 * math.pi * 3200.0 * t) * math.exp(-t * 90.0) * 0.8 if t < 0.05 else 0.0
        mix = (wave_val * 0.5 + noise + snap) * env
        samples.append(mix * 0.9)
    return samples


def gen_wand() -> list[float]:
    duration = 0.16
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 480.0 + 900.0 * (t / duration)
        sine = math.sin(2.0 * math.pi * freq * t)
        harmonic = math.sin(2.0 * math.pi * freq * 2.0 * t) * 0.35
        env = math.exp(-t * 16.0)
        samples.append((sine + harmonic) * env * 0.8)
    return samples


def gen_knife() -> list[float]:
    duration = 0.12
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 1800.0 - 1100.0 * (t / duration)
        tri = (math.asin(math.sin(2.0 * math.pi * freq * t)) * (2.0 / math.pi))
        env = (1.0 - t / duration) * math.exp(-t * 15.0)
        samples.append(tri * env * 0.75)
    return samples


def gen_axe() -> list[float]:
    duration = 0.22
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Low whoosh modulated
        mod = math.sin(2.0 * math.pi * 18.0 * t) * 40.0
        freq = 220.0 + mod
        wave_val = math.sin(2.0 * math.pi * freq * t)
        noise = (math.sin(i * 1.9) * 2.0 - 1.0) * 0.3
        env = math.sin(math.pi * (t / duration)) ** 1.5
        samples.append((wave_val * 0.7 + noise) * env * 0.85)
    return samples


def gen_bible() -> list[float]:
    duration = 0.25
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq1 = 523.25 # C5
        freq2 = 783.99 # G5
        sine1 = math.sin(2.0 * math.pi * freq1 * t)
        sine2 = math.sin(2.0 * math.pi * freq2 * t) * 0.5
        env = math.exp(-t * 10.0)
        samples.append((sine1 + sine2) * env * 0.75)
    return samples


def gen_lightning() -> list[float]:
    duration = 0.30
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        noise = (math.sin(i * 9.1) * 2.0 - 1.0)
        low = math.sin(2.0 * math.pi * 90.0 * t) * math.exp(-t * 8.0)
        env = math.exp(-t * 12.0)
        samples.append((noise * 0.65 + low * 0.45) * env * 0.9)
    return samples


def gen_fire() -> list[float]:
    duration = 0.24
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        noise = (math.sin(i * 4.3) * 2.0 - 1.0)
        freq = 320.0 * math.exp(-t * 12.0) + 60.0
        sub = math.sin(2.0 * math.pi * freq * t)
        env = math.exp(-t * 9.0)
        samples.append((noise * 0.55 + sub * 0.45) * env * 0.85)
    return samples


def gen_nuke() -> list[float]:
    duration = 0.65
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        sub = math.sin(2.0 * math.pi * (70.0 - t * 45.0) * t) * math.exp(-t * 3.0)
        noise = (math.sin(i * 11.3) * 2.0 - 1.0) * math.exp(-t * 6.0)
        samples.append((sub * 0.65 + noise * 0.45) * 0.95)
    return samples


def gen_laser() -> list[float]:
    duration = 0.20
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 1600.0 * math.exp(-t * 18.0) + 400.0
        saw = (t * freq - math.floor(t * freq)) * 2.0 - 1.0
        env = math.exp(-t * 14.0)
        samples.append(saw * env * 0.75)
    return samples


def gen_hit() -> list[float]:
    duration = 0.10
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        noise = (math.sin(i * 7.7) * 2.0 - 1.0)
        sub = math.sin(2.0 * math.pi * 140.0 * t)
        env = math.exp(-t * 38.0)
        samples.append((noise * 0.6 + sub * 0.4) * env * 0.85)
    return samples


def gen_kill() -> list[float]:
    duration = 0.14
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        noise = (math.sin(i * 13.5) * 2.0 - 1.0)
        freq = 260.0 * math.exp(-t * 25.0)
        sub = math.sin(2.0 * math.pi * freq * t)
        env = math.exp(-t * 22.0)
        samples.append((noise * 0.7 + sub * 0.3) * env * 0.8)
    return samples


def gen_smash() -> list[float]:
    duration = 0.16
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        noise = (math.sin(i * 17.1) * 2.0 - 1.0)
        env = math.exp(-t * 30.0)
        samples.append(noise * env * 0.8)
    return samples


def gen_gem(high: bool = False) -> list[float]:
    duration = 0.18
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    base_freq = 1318.51 if high else 880.0 # E6 or A5
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = base_freq + 200.0 * t
        sine = math.sin(2.0 * math.pi * freq * t)
        harmonic = math.sin(2.0 * math.pi * freq * 2.0 * t) * 0.3
        env = math.exp(-t * 20.0)
        samples.append((sine + harmonic) * env * 0.75)
    return samples


def gen_item() -> list[float]:
    duration = 0.22
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    notes = [659.25, 880.0, 1174.66] # E5, A5, D6
    note_samples = num_samples // len(notes)
    for n_i, freq in enumerate(notes):
        for i in range(note_samples):
            t = i / SAMPLE_RATE
            sine = math.sin(2.0 * math.pi * freq * t)
            env = 1.0 - i / note_samples
            samples.append(sine * env * 0.7)
    return samples


def gen_heal() -> list[float]:
    duration = 0.28
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 587.33 + math.sin(t * 70.0) * 120.0
        sine = math.sin(2.0 * math.pi * freq * t)
        env = math.exp(-t * 12.0)
        samples.append(sine * env * 0.75)
    return samples


def gen_freeze() -> list[float]:
    duration = 0.35
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 1800.0 - 1200.0 * (t / duration)
        sine = math.sin(2.0 * math.pi * freq * t)
        noise = (math.sin(i * 8.7) * 2.0 - 1.0) * 0.25
        env = (1.0 - t / duration)
        samples.append((sine + noise) * env * 0.7)
    return samples


def gen_hurt() -> list[float]:
    duration = 0.15
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 180.0 * math.exp(-t * 20.0) + 40.0
        sub = math.sin(2.0 * math.pi * freq * t)
        noise = (math.sin(i * 5.2) * 2.0 - 1.0) * 0.4
        env = math.exp(-t * 25.0)
        samples.append((sub + noise) * env * 0.85)
    return samples


def gen_levelup() -> list[float]:
    # 4-note ascending chord arpeggio
    notes = [523.25, 659.25, 783.99, 1046.50] # C5, E5, G5, C6
    note_dur = 0.08
    samples = []
    for freq in notes:
        n_samples = int(SAMPLE_RATE * note_dur)
        for i in range(n_samples):
            t = i / SAMPLE_RATE
            sine = math.sin(2.0 * math.pi * freq * t)
            harm = math.sin(2.0 * math.pi * freq * 2.0 * t) * 0.3
            env = 1.0 - (i / n_samples) * 0.6
            samples.append((sine + harm) * env * 0.75)
    return samples


def gen_chest() -> list[float]:
    # Gilded treasure fanfare
    notes = [440.0, 554.37, 659.25, 880.0, 1108.73, 1318.51]
    note_dur = 0.09
    samples = []
    for freq in notes:
        n_samples = int(SAMPLE_RATE * note_dur)
        for i in range(n_samples):
            t = i / SAMPLE_RATE
            sq = 1.0 if math.sin(2.0 * math.pi * freq * t) > 0.0 else -1.0
            sine = math.sin(2.0 * math.pi * freq * t)
            env = 1.0 - (i / n_samples) * 0.5
            samples.append((sq * 0.3 + sine * 0.6) * env * 0.75)
    return samples


def gen_evolve() -> list[float]:
    # Legendary weapon evolution fanfare
    notes = [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98, 2093.00]
    note_dur = 0.10
    samples = []
    for freq in notes:
        n_samples = int(SAMPLE_RATE * note_dur)
        for i in range(n_samples):
            t = i / SAMPLE_RATE
            sine = math.sin(2.0 * math.pi * freq * t)
            harm = math.sin(2.0 * math.pi * freq * 3.0 * t) * 0.35
            env = 1.0 - (i / n_samples) * 0.4
            samples.append((sine + harm) * env * 0.8)
    return samples


def gen_ultimate() -> list[float]:
    duration = 0.75
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        boom = math.sin(2.0 * math.pi * (240.0 - t * 280.0) * t) * math.exp(-t * 3.5)
        noise = (math.sin(i * 12.1) * 2.0 - 1.0) * math.exp(-t * 6.0)
        lead = math.sin(2.0 * math.pi * 880.0 * t) * math.exp(-t * 10.0)
        samples.append((boom * 0.55 + noise * 0.35 + lead * 0.2) * 0.95)
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sounds_dir = root / "assets" / "sounds"
    sounds_dir.mkdir(parents=True, exist_ok=True)

    generators = {
        "vs_whip.wav": gen_whip,
        "vs_wand.wav": gen_wand,
        "vs_knife.wav": gen_knife,
        "vs_axe.wav": gen_axe,
        "vs_bible.wav": gen_bible,
        "vs_lightning.wav": gen_lightning,
        "vs_fire.wav": gen_fire,
        "vs_nuke.wav": gen_nuke,
        "vs_laser.wav": gen_laser,
        "vs_hit.wav": gen_hit,
        "vs_kill.wav": gen_kill,
        "vs_smash.wav": gen_smash,
        "vs_gem.wav": lambda: gen_gem(False),
        "vs_gem_big.wav": lambda: gen_gem(True),
        "vs_item.wav": gen_item,
        "vs_heal.wav": gen_heal,
        "vs_freeze.wav": gen_freeze,
        "vs_hurt.wav": gen_hurt,
        "vs_levelup.wav": gen_levelup,
        "vs_chest.wav": gen_chest,
        "vs_evolve.wav": gen_evolve,
        "vs_ultimate.wav": gen_ultimate,
    }

    for filename, fn in generators.items():
        out_file = sounds_dir / filename
        samples = fn()
        write_wav(out_file, samples)
        print(f"Generated sound effect: {out_file.name} ({len(samples)} samples)")

    print(f"Successfully generated {len(generators)} Vampire Survivors sound effects!")


if __name__ == "__main__":
    main()
