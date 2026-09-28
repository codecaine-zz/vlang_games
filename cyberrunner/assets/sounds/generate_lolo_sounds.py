#!/usr/bin/env python3
"""Synthesize studio-quality 44.1kHz 16-bit mono WAV sound effects for Adventures of Lolo:
- lolo_step.wav: Light crisp footstep click
- lolo_heart.wav: Harmonic heart frame collection chime (D5 -> A5 -> D6)
- lolo_shot.wav: Magic plasma orb zap
- lolo_egg.wav: Enemy transforming into egg
- lolo_push.wav: Heavy block push thud
- lolo_chest.wav: Jewel chest opening victory fanfare
- lolo_door.wav: Level exit portal open resonance
- lolo_victory.wav: Triumphant stage complete fanfare
- lolo_death.wav: Classic defeat fall slide
- lolo_medusa.wav: Medusa petrification laser beam
- lolo_warp.wav: Phase warp teleport whoosh
- lolo_slide.wav: Ice slippery sliding whoosh
- lolo_hammer.wav: Heavy hammer rock crushing smash
- lolo_badge.wav: Special achievement badge chime
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
        freq = 320.0 - 180.0 * (t / duration)
        env = math.exp(-35.0 * t)
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.7)
    return samples


def gen_heart() -> list[float]:
    notes = [587.33, 880.00, 1174.66]
    note_dur = 0.055
    duration = note_dur * len(notes)
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        n_idx = min(len(notes) - 1, int(t / note_dur))
        freq = notes[n_idx]
        local_t = math.fmod(t, note_dur)
        env = math.exp(-local_t * 18.0)
        s = math.sin(2.0 * math.pi * freq * t)
        harm = math.sin(2.0 * math.pi * (freq * 2.0) * t) * 0.3
        samples.append((s + harm) * env * 0.85)
    return samples


def gen_shot() -> list[float]:
    duration = 0.11
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 1400.0 - 1100.0 * (t / duration)
        env = math.exp(-12.0 * t)
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.9)
    return samples


def gen_egg() -> list[float]:
    duration = 0.15
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 300.0 + 700.0 * (t / duration)
        env = math.exp(-8.0 * t)
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.85)
    return samples


def gen_push() -> list[float]:
    duration = 0.08
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 140.0 - 60.0 * (t / duration)
        env = math.exp(-22.0 * t)
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.9)
    return samples


def gen_chest() -> list[float]:
    notes = [523.25, 659.25, 783.99, 1046.50, 1318.51]
    duration = 0.45
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    note_dur = duration / len(notes)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        n_idx = min(len(notes) - 1, int(t / note_dur))
        freq = notes[n_idx]
        local_t = math.fmod(t, note_dur)
        env = math.exp(-local_t * 12.0)
        s = math.sin(2.0 * math.pi * freq * t)
        harm = math.sin(2.0 * math.pi * (freq * 2.0) * t) * 0.25
        samples.append((s + harm) * env * 0.9)
    return samples


def gen_door() -> list[float]:
    duration = 0.35
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 440.0 + 440.0 * (t / duration)
        env = math.exp(-t * 6.0)
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.85)
    return samples


def gen_victory() -> list[float]:
    notes = [659.25, 783.99, 880.00, 1046.50, 1318.51]
    duration = 0.60
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    note_dur = duration / len(notes)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        n_idx = min(len(notes) - 1, int(t / note_dur))
        freq = notes[n_idx]
        local_t = math.fmod(t, note_dur)
        env = math.exp(-local_t * 8.0)
        s = math.sin(2.0 * math.pi * freq * t)
        harm = math.sin(2.0 * math.pi * (freq * 1.5) * t) * 0.25
        samples.append((s + harm) * env * 0.92)
    return samples


def gen_death() -> list[float]:
    duration = 0.40
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 520.0 * math.exp(-t * 8.0) + 70.0
        env = math.exp(-t * 6.5)
        s = math.sin(2.0 * math.pi * freq * t)
        noise = (math.sin(i * 11.7) * 2.0 - 1.0) * 0.25
        samples.append((s * 0.75 + noise * 0.25) * env * 0.95)
    return samples


def gen_medusa() -> list[float]:
    duration = 0.28
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 880.0 + math.sin(t * 140.0) * 320.0
        env = math.exp(-t * 8.0)
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.85)
    return samples


def gen_warp() -> list[float]:
    duration = 0.25
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 300.0 + 900.0 * (t / duration)
        env = math.sin(math.pi * (t / duration))
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.85)
    return samples


def gen_slide() -> list[float]:
    duration = 0.18
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 12.0)
        noise = (math.sin(i * 9.3) * 2.0 - 1.0) * 0.5
        sub = math.sin(2.0 * math.pi * 220.0 * t) * 0.5
        samples.append((noise + sub) * env * 0.8)
    return samples


def gen_hammer() -> list[float]:
    duration = 0.14
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 240.0 - 140.0 * (t / duration)
        env = math.exp(-t * 16.0)
        s = (1.0 if math.sin(2.0 * math.pi * freq * t) > 0.0 else -1.0) * 0.6
        noise = (math.sin(i * 15.3) * 2.0 - 1.0) * 0.4
        samples.append((s + noise) * env * 0.9)
    return samples


def gen_badge() -> list[float]:
    notes = [783.99, 987.77, 1174.66, 1567.98]
    duration = 0.35
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    note_dur = duration / len(notes)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        n_idx = min(len(notes) - 1, int(t / note_dur))
        freq = notes[n_idx]
        local_t = math.fmod(t, note_dur)
        env = math.exp(-local_t * 15.0)
        s = math.sin(2.0 * math.pi * freq * t)
        samples.append(s * env * 0.88)
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    sounds_dir = root / "assets" / "sounds"
    sounds_dir.mkdir(parents=True, exist_ok=True)

    generators = {
        "lolo_step.wav": gen_step,
        "lolo_heart.wav": gen_heart,
        "lolo_shot.wav": gen_shot,
        "lolo_egg.wav": gen_egg,
        "lolo_push.wav": gen_push,
        "lolo_chest.wav": gen_chest,
        "lolo_door.wav": gen_door,
        "lolo_victory.wav": gen_victory,
        "lolo_death.wav": gen_death,
        "lolo_medusa.wav": gen_medusa,
        "lolo_warp.wav": gen_warp,
        "lolo_slide.wav": gen_slide,
        "lolo_hammer.wav": gen_hammer,
        "lolo_badge.wav": gen_badge,
    }

    for filename, fn in generators.items():
        out_file = sounds_dir / filename
        samples = fn()
        write_wav(out_file, samples)
        print(f"Generated Lolo sound effect: {out_file.name} ({len(samples)} samples)")

    print(f"Successfully generated {len(generators)} Lolo sound effects!")


if __name__ == "__main__":
    main()
