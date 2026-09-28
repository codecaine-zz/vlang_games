#!/usr/bin/env python3
"""Generate 44.1kHz 16-bit PCM WAV soundtracks for Scorched Earth:
1. scorched_theme.wav: Driving 90s military artillery march & synth brass at 130 BPM
2. scorched_shop.wav: Tactical planning & arms dealer shop theme at 115 BPM
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


def gen_scorched_theme() -> list[float]:
    duration = 14.76
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    # Military Brass Lead (C Minor: C, Eb, G, Ab, G, F, Eb, D)
    brass_riff = [
        130.81, 130.81, 155.56, 196.0, 207.65, 196.0, 174.61, 155.56,
        146.83, 146.83, 174.61, 196.0, 207.65, 196.0, 174.61, 146.83,
        130.81, 130.81, 196.0, 261.63, 233.08, 207.65, 196.0, 174.61,
        155.56, 174.61, 196.0, 233.08, 261.63, 233.08, 196.0, 155.56,
    ]
    bass_notes = [65.41, 58.27, 65.41, 77.78] # C1, Bb0, C1, Eb1
    samples_per_step = int(SAMPLE_RATE * 0.115)

    for total_sample in range(num_samples):
        step_idx = (total_sample // samples_per_step) % len(brass_riff)
        measure_idx = (total_sample // (samples_per_step * 8)) % len(bass_notes)

        freq_lead = brass_riff[step_idx]
        freq_bass = bass_notes[measure_idx]

        t = total_sample / SAMPLE_RATE
        env_lead = 1.0 - (float(total_sample % samples_per_step) / float(samples_per_step)) * 0.65

        # Brass saw wave
        phase_lead = t * freq_lead
        saw_lead = (phase_lead - math.floor(phase_lead)) * 2.0 - 1.0
        harm_lead = math.sin(2.0 * math.pi * freq_lead * 2.0 * t) * 0.35
        lead_mix = saw_lead * 0.65 + harm_lead

        # Bass pulse
        phase_bass = t * freq_bass
        bass_mix = 1.0 if math.sin(2.0 * math.pi * freq_bass * t) > 0.0 else -1.0

        # Military snare & bass drum
        beat_step = (total_sample // (samples_per_step * 2)) % 4
        beat_sample = total_sample % (samples_per_step * 2)
        kick = 0.0
        snare = 0.0
        if beat_step % 2 == 0:
            kt = float(beat_sample) / SAMPLE_RATE
            kick = math.sin(kt * (150.0 - kt * 450.0) * 2.0 * math.pi) * math.exp(-kt * 25.0)
        else:
            st = float(beat_sample) / SAMPLE_RATE
            noise = (math.sin(total_sample * 19.1) * 2.0 - 1.0)
            snare = noise * math.exp(-st * 24.0)

        mix = lead_mix * env_lead * 0.40 + bass_mix * 0.20 + kick * 0.45 + snare * 0.30
        samples.append(mix * 0.85)
    return samples


def gen_scorched_shop() -> list[float]:
    duration = 12.52
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    # Relaxed tactical vibes in F minor
    lead_riff = [
        174.61, 207.65, 261.63, 311.13, 261.63, 207.65, 174.61, 130.81,
        155.56, 174.61, 207.65, 261.63, 207.65, 174.61, 155.56, 116.54,
    ]
    samples_per_step = int(SAMPLE_RATE * 0.195)

    for total_sample in range(num_samples):
        step_idx = (total_sample // samples_per_step) % len(lead_riff)
        freq_lead = lead_riff[step_idx]

        t = total_sample / SAMPLE_RATE
        env_lead = math.exp(-float(total_sample % samples_per_step) / (SAMPLE_RATE * 0.12))

        sine_lead = math.sin(2.0 * math.pi * freq_lead * t)
        harm = math.sin(2.0 * math.pi * freq_lead * 3.0 * t) * 0.2

        beat_sample = total_sample % samples_per_step
        kt = float(beat_sample) / SAMPLE_RATE
        kick = math.sin(kt * (120.0 - kt * 300.0) * 2.0 * math.pi) * math.exp(-kt * 18.0) * 0.4

        mix = (sine_lead + harm) * env_lead * 0.50 + kick
        samples.append(mix * 0.8)
    return samples


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    music_dir = root / "assets" / "music"
    music_dir.mkdir(parents=True, exist_ok=True)

    tracks = {
        "scorched_theme.wav": gen_scorched_theme,
        "scorched_shop.wav": gen_scorched_shop,
    }

    for filename, fn in tracks.items():
        out_file = music_dir / filename
        samples = fn()
        write_wav(out_file, samples)
        print(f"Generated soundtrack: {out_file.name} ({len(samples)} samples)")

    print(f"Successfully generated {len(tracks)} Scorched Earth soundtracks!")


if __name__ == "__main__":
    main()
