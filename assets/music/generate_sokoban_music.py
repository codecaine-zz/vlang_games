#!/usr/bin/env python3
"""Generate 120 BPM cozy Japanese puzzle soundtrack with acoustic guitar, marimba, and warm bass for Sokoban."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 120
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    # C Major / A Minor Cozy Pentatonic Melody
    melody = [
        60, 64, 67, 72, 71, 67, 64, 62,
        60, 65, 69, 72, 74, 72, 69, 65,
        57, 60, 64, 69, 67, 64, 60, 57,
        55, 59, 62, 67, 69, 67, 62, 59,
    ]

    bass_notes = [36, 48, 43, 48, 41, 48, 45, 48, 33, 45, 40, 45, 35, 47, 43, 47]

    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        start_idx = b * beat_samples

        # Acoustic Bass
        b_idx = (b * 2) % len(bass_notes)
        freq = midi_to_freq(bass_notes[b_idx])
        for s in range(int(beat_samples * 0.9)):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 8.0)
            sine = math.sin(2.0 * math.pi * freq * t) + 0.25 * math.sin(4.0 * math.pi * freq * t)
            samples[idx] += sine * env * 0.35

        # Marimba / Acoustic Pluck Lead
        m_idx = (b * 2) % len(melody)
        m_freq = midi_to_freq(melody[m_idx] + 12)
        for s in range(int(beat_samples * 0.45)):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 16.0)
            sine = math.sin(2.0 * math.pi * m_freq * t) + 0.3 * math.sin(6.0 * math.pi * m_freq * t)
            samples[idx] += sine * env * 0.25

        # Second pluck on off-beat
        m_idx2 = (b * 2 + 1) % len(melody)
        m_freq2 = midi_to_freq(melody[m_idx2] + 12)
        sub_st = start_idx + int(beat_samples / 2)
        for s in range(int(beat_samples * 0.45)):
            idx = sub_st + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 16.0)
            sine = math.sin(2.0 * math.pi * m_freq2 * t) + 0.3 * math.sin(6.0 * math.pi * m_freq2 * t)
            samples[idx] += sine * env * 0.25

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
    out_path = out_dir / "sokoban_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "sokoban" / "assets" / "music" / "sokoban_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
