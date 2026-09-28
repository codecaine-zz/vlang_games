#!/usr/bin/env python3
"""Generate 130 BPM tactical sci-fi defense soundtrack with driving synth arpeggios, punchy beats, and electronic bass."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 130
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    # E Minor Driving Synth Arp
    arp_notes = [52, 55, 59, 64, 67, 64, 59, 55, 48, 52, 55, 60, 64, 60, 55, 52]
    bass_notes = [28, 28, 40, 28, 24, 24, 36, 24, 26, 26, 38, 26, 23, 23, 35, 23]

    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        start_idx = b * beat_samples

        # 16th-note Synth Arpeggiator
        for step in range(4):
            note_idx = (b * 4 + step) % len(arp_notes)
            freq = midi_to_freq(arp_notes[note_idx])
            step_st = start_idx + int(step * (beat_samples / 4.0))

            for s in range(int(beat_samples / 4.0 * 0.8)):
                idx = step_st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 24.0)
                saw = 2.0 * (t * freq - math.floor(t * freq + 0.5))
                samples[idx] += saw * env * 0.22

        # 8th-note Driving Bass
        for sub in range(2):
            b_idx = (b * 2 + sub) % len(bass_notes)
            freq = midi_to_freq(bass_notes[b_idx])
            sub_st = start_idx + int(sub * (beat_samples / 2.0))

            for s in range(int(beat_samples / 2.0 * 0.85)):
                idx = sub_st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 14.0)
                sine = math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
                samples[idx] += sine * env * 0.32

        # Electronic Kick Drum
        for s in range(int(0.1 * SAMPLE_RATE)):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            k_freq = 150.0 * math.exp(-t * 28.0)
            samples[idx] += math.sin(2.0 * math.pi * k_freq * t) * math.exp(-t * 16.0) * 0.45

    out = bytearray()
    for val in samples:
        clamped = max(-1.0, min(1.0, val * 0.85))
        ival = int(clamped * 32767.0)
        out.extend(struct.pack("<h", ival))
    return bytes(out)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    pcm_data = generate_soundtrack()
    out_dir = root / "assets" / "music"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "towerdefense_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "towerdefense" / "assets" / "music" / "towerdefense_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
