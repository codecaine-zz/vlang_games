#!/usr/bin/env python3
"""Generate 44.1kHz 16-bit PCM WAV soundtracks for Vampire Survivors:
1. vampiresurvivors_rondo.wav: Castlevania-inspired Gothic minor arpeggios at 140 BPM
2. vampiresurvivors_eclipse.wav: High-intensity Dark Electro Synthmetal at 155 BPM
3. vampiresurvivors_symphony.wav: Epic Galloping Gothic Power Synth at 160 BPM
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


def gen_gothic_rondo() -> list[float]:
    duration = 14.0
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    notes_arpeggio = [
        220.0, 261.63, 329.63, 440.0, 523.25, 440.0, 329.63, 261.63,  # Am
        174.61, 220.0, 261.63, 349.23, 440.0, 349.23, 261.63, 220.0,  # F
        196.0, 246.94, 293.66, 392.0, 493.88, 392.0, 293.66, 246.94,  # G
        164.81, 207.65, 246.94, 329.63, 415.30, 329.63, 246.94, 207.65 # E7
    ]
    bass_notes = [110.0, 87.31, 98.0, 82.41]
    samples_per_step = int(SAMPLE_RATE * 0.107)

    for total_sample in range(num_samples):
        step_idx = (total_sample // samples_per_step) % len(notes_arpeggio)
        measure_idx = (total_sample // (samples_per_step * 8)) % len(bass_notes)

        freq_lead = notes_arpeggio[step_idx]
        freq_bass = bass_notes[measure_idx]

        t = total_sample / SAMPLE_RATE
        env_lead = 1.0 - (float(total_sample % samples_per_step) / float(samples_per_step))

        wave_lead = 1.0 if math.sin(t * freq_lead * 2.0 * math.pi) > 0.0 else -1.0
        wave_bass = (t * freq_bass - math.floor(t * freq_bass)) * 2.0 - 1.0

        beat_step = (total_sample // (samples_per_step * 2)) % 4
        beat_sample = total_sample % (samples_per_step * 2)
        kick = 0.0
        if beat_step % 2 == 0:
            kt = float(beat_sample) / SAMPLE_RATE
            kick = math.sin(kt * (120.0 - kt * 300.0) * 2.0 * math.pi) * math.exp(-kt * 25.0)

        mix = wave_lead * env_lead * 0.35 + wave_bass * 0.25 + kick * 0.40
        samples.append(mix * 0.85)
    return samples


def gen_vampires_eclipse() -> list[float]:
    duration = 12.0
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    notes_riff = [
        146.83, 146.83, 293.66, 146.83, 220.0, 146.83, 261.63, 146.83,  # Dm
        130.81, 130.81, 261.63, 130.81, 196.0, 130.81, 220.0, 130.81,  # C
        116.54, 116.54, 233.08, 116.54, 174.61, 116.54, 196.0, 116.54,  # Bb
        130.81, 130.81, 261.63, 130.81, 220.0, 246.94, 261.63, 293.66  # C -> Dm
    ]
    samples_per_step = int(SAMPLE_RATE * 0.0967)

    for total_sample in range(num_samples):
        step_idx = (total_sample // samples_per_step) % len(notes_riff)
        freq_riff = notes_riff[step_idx]

        t = total_sample / SAMPLE_RATE
        env = 1.0 - (float(total_sample % samples_per_step) / float(samples_per_step)) * 0.6

        phase = t * freq_riff
        saw = (phase - math.floor(phase)) * 2.0 - 1.0
        distorted_saw = max(-0.8, min(0.8, saw * 2.2))

        kick_sample = total_sample % samples_per_step
        kt = float(kick_sample) / SAMPLE_RATE
        kick = math.sin(kt * (160.0 - kt * 500.0) * 2.0 * math.pi) * math.exp(-kt * 30.0)

        mix = distorted_saw * env * 0.45 + kick * 0.50
        samples.append(mix * 0.85)
    return samples


def gen_bloodlust_symphony() -> list[float]:
    duration = 12.0
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    notes_melody = [
        440.0, 493.88, 523.25, 659.25, 587.33, 523.25, 493.88, 440.0,
        392.0, 440.0, 493.88, 587.33, 523.25, 493.88, 440.0, 392.0,
        349.23, 392.0, 440.0, 523.25, 493.88, 440.0, 392.0, 349.23,
        329.63, 415.30, 493.88, 659.25, 783.99, 659.25, 493.88, 415.30
    ]
    samples_per_step = int(SAMPLE_RATE * 0.0937)

    for total_sample in range(num_samples):
        step_idx = (total_sample // samples_per_step) % len(notes_melody)
        freq = notes_melody[step_idx]

        t = total_sample / SAMPLE_RATE
        env = 1.0 - (float(total_sample % samples_per_step) / float(samples_per_step)) * 0.5

        sq = 1.0 if math.sin(t * freq * 2.0 * math.pi) > 0.0 else -1.0
        sub = math.sin(t * (freq * 0.5) * 2.0 * math.pi)

        gallop_sample = total_sample % samples_per_step
        gt = float(gallop_sample) / SAMPLE_RATE
        gallop_kick = math.sin(gt * 110.0 * 2.0 * math.pi) * math.exp(-gt * 32.0)

        mix = sq * env * 0.35 + sub * 0.25 + gallop_kick * 0.40
        samples.append(mix * 0.85)
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    music_dir = root / "assets" / "music"
    music_dir.mkdir(parents=True, exist_ok=True)

    tracks = {
        "vampiresurvivors_rondo.wav": gen_gothic_rondo,
        "vampiresurvivors_eclipse.wav": gen_vampires_eclipse,
        "vampiresurvivors_symphony.wav": gen_bloodlust_symphony,
    }

    for filename, fn in tracks.items():
        out_file = music_dir / filename
        samples = fn()
        write_wav(out_file, samples)
        print(f"Generated soundtrack: {out_file.name} ({len(samples)} samples)")

    print(f"Successfully generated {len(tracks)} Vampire Survivors soundtracks!")


if __name__ == "__main__":
    main()
