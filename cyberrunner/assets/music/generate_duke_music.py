#!/usr/bin/env python3
"""Generate 44.1kHz 16-bit PCM WAV soundtracks for Duke Nukem:
1. duke_theme.wav: 90s Apogee-style driving action platformer synthrock groove at 145 BPM
2. duke_boss.wav: Heavy mechanical Goliath boss battle groove at 155 BPM
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


def gen_duke_theme() -> list[float]:
    duration = 13.2
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    # 90s Action Riff in E minor (E, G, A, B, D, E)
    lead_riff = [
        164.81, 164.81, 196.0, 220.0, 246.94, 220.0, 196.0, 164.81,
        146.83, 146.83, 164.81, 196.0, 220.0, 196.0, 164.81, 146.83,
        164.81, 164.81, 196.0, 220.0, 293.66, 246.94, 220.0, 196.0,
        220.0, 246.94, 293.66, 329.63, 293.66, 246.94, 220.0, 196.0,
    ]
    bass_notes = [82.41, 73.42, 82.41, 98.0] # E1, D1, E1, G1
    samples_per_step = int(SAMPLE_RATE * 0.103)

    for total_sample in range(num_samples):
        step_idx = (total_sample // samples_per_step) % len(lead_riff)
        measure_idx = (total_sample // (samples_per_step * 8)) % len(bass_notes)

        freq_lead = lead_riff[step_idx]
        freq_bass = bass_notes[measure_idx]

        t = total_sample / SAMPLE_RATE
        env_lead = 1.0 - (float(total_sample % samples_per_step) / float(samples_per_step)) * 0.7

        # Distorted Square / Saw lead
        phase_lead = t * freq_lead
        saw_lead = (phase_lead - math.floor(phase_lead)) * 2.0 - 1.0
        sq_lead = 1.0 if math.sin(t * freq_lead * 2.0 * math.pi) > 0.0 else -1.0
        lead_mix = saw_lead * 0.6 + sq_lead * 0.4

        # Slap Bass
        phase_bass = t * freq_bass
        bass_mix = (phase_bass - math.floor(phase_bass)) * 2.0 - 1.0

        # Kick & Snare Beat
        beat_step = (total_sample // (samples_per_step * 2)) % 4
        beat_sample = total_sample % (samples_per_step * 2)
        kick = 0.0
        snare = 0.0
        if beat_step % 2 == 0:
            kt = float(beat_sample) / SAMPLE_RATE
            kick = math.sin(kt * (140.0 - kt * 400.0) * 2.0 * math.pi) * math.exp(-kt * 28.0)
        else:
            st = float(beat_sample) / SAMPLE_RATE
            noise = (math.sin(total_sample * 17.3) * 2.0 - 1.0)
            snare = noise * math.exp(-st * 22.0)

        mix = lead_mix * env_lead * 0.40 + bass_mix * 0.25 + kick * 0.45 + snare * 0.30
        samples.append(mix * 0.85)
    return samples


def gen_duke_boss() -> list[float]:
    duration = 12.4
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    # Heavy Mechanical Boss Riff in D minor
    lead_riff = [
        146.83, 146.83, 293.66, 146.83, 220.0, 146.83, 261.63, 146.83,
        138.59, 138.59, 277.18, 138.59, 207.65, 138.59, 246.94, 138.59,
        130.81, 130.81, 261.63, 130.81, 196.0, 130.81, 220.0, 130.81,
        146.83, 164.81, 174.61, 196.0, 220.0, 246.94, 261.63, 293.66,
    ]
    samples_per_step = int(SAMPLE_RATE * 0.0967)

    for total_sample in range(num_samples):
        step_idx = (total_sample // samples_per_step) % len(lead_riff)
        freq_lead = lead_riff[step_idx]

        t = total_sample / SAMPLE_RATE
        env_lead = 1.0 - (float(total_sample % samples_per_step) / float(samples_per_step)) * 0.6

        phase_lead = t * freq_lead
        saw_lead = (phase_lead - math.floor(phase_lead)) * 2.0 - 1.0
        dist_lead = max(-0.8, min(0.8, saw_lead * 2.0))

        beat_sample = total_sample % samples_per_step
        kt = float(beat_sample) / SAMPLE_RATE
        kick = math.sin(kt * (160.0 - kt * 500.0) * 2.0 * math.pi) * math.exp(-kt * 30.0)

        mix = dist_lead * env_lead * 0.45 + kick * 0.50
        samples.append(mix * 0.85)
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    music_dir = root / "assets" / "music"
    music_dir.mkdir(parents=True, exist_ok=True)

    tracks = {
        "duke_theme.wav": gen_duke_theme,
        "duke_boss.wav": gen_duke_boss,
    }

    for filename, fn in tracks.items():
        out_file = music_dir / filename
        samples = fn()
        write_wav(out_file, samples)
        print(f"Generated soundtrack: {out_file.name} ({len(samples)} samples)")

    print(f"Successfully generated {len(tracks)} Duke Nukem soundtracks!")


if __name__ == "__main__":
    main()
