#!/usr/bin/env python3
"""Generate 135 BPM classic SEGA Shinobi theme with Japanese flute synths, slap bass, and driving taiko drums."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 135
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    # Traditional Japanese Insen Scale / Minor Pentatonic
    # D, Eb, G, A, C (Midi: 50, 51, 55, 57, 60)
    melody = [
        62, 63, 67, 69, 70, 69, 67, 63,
        62, 65, 67, 69, 72, 69, 67, 65,
        60, 62, 65, 67, 69, 67, 65, 62,
        58, 60, 62, 65, 67, 65, 62, 60,
    ]

    bass_notes = [38, 38, 50, 38, 41, 38, 43, 41, 36, 36, 48, 36, 39, 36, 41, 39]

    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        start_idx = b * beat_samples

        # 8th-note Slap Bass
        for sub in range(2):
            b_idx = (b * 2 + sub) % len(bass_notes)
            freq = midi_to_freq(bass_notes[b_idx])
            sub_st = start_idx + int(sub * (beat_samples / 2.0))

            for s in range(int(beat_samples / 2.0 * 0.85)):
                idx = sub_st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 16.0)
                saw = 2.0 * (t * freq - math.floor(t * freq + 0.5))
                samples[idx] += saw * env * 0.25

        # Japanese Shakuhachi / Flute Lead Synth
        m_idx = b % len(melody)
        freq = midi_to_freq(melody[m_idx])
        for s in range(int(beat_samples * 0.9)):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.sin(math.pi * (s / (beat_samples * 0.9)))
            vibrato = math.sin(2.0 * math.pi * 5.5 * t) * 0.02
            sine = math.sin(2.0 * math.pi * freq * (1.0 + vibrato) * t)
            samples[idx] += sine * env * 0.28

        # Taiko Kick Drum Thump
        for s in range(int(0.12 * SAMPLE_RATE)):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            k_freq = 160.0 * math.exp(-t * 22.0)
            samples[idx] += math.sin(2.0 * math.pi * k_freq * t) * math.exp(-t * 14.0) * 0.45

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
    out_path = out_dir / "shinobi_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "shinobi" / "assets" / "music" / "shinobi_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
