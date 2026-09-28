#!/usr/bin/env python3
"""Generate 125 BPM vibrant Las Vegas casino floor soundtrack for Slots."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 125
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    # Electro-Swing / Vegas Jazz Progression (Bb7 - G7 - Cm7 - F7)
    chords = [
        [58, 62, 65, 68],  # Bb7
        [55, 59, 62, 65],  # G7
        [60, 63, 67, 70],  # Cm7
        [53, 57, 60, 63],  # F7
    ]

    bass_notes = [34, 38, 41, 38, 31, 35, 38, 35, 36, 40, 43, 40, 29, 33, 36, 33]
    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        start_idx = b * beat_samples

        # Staccato Swing Piano Chords on off-beats
        c_idx = (b // 2) % len(chords)
        chord = chords[c_idx]
        offbeat_st = start_idx + int(beat_samples * 0.45)
        for note in chord:
            freq = midi_to_freq(note)
            for s in range(int(beat_samples * 0.4)):
                idx = offbeat_st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 16.0)
                saw = (math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)) * env * 0.15
                samples[idx] += saw

        # Walking Acoustic Bass
        b_idx = b % len(bass_notes)
        freq = midi_to_freq(bass_notes[b_idx])
        for s in range(int(beat_samples * 0.85)):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 7.0)
            sine = (math.sin(2.0 * math.pi * freq * t) + 0.25 * math.sin(4.0 * math.pi * freq * t)) * env * 0.35
            samples[idx] += sine

        # Sparkling Casino Bell Chimes on bar starts
        if b % 8 == 0:
            for bell_note in [74, 77, 81, 86]:
                b_freq = midi_to_freq(bell_note)
                for s in range(int(beat_samples * 2.0)):
                    idx = start_idx + s
                    if idx >= total_samples:
                        break
                    t = s / SAMPLE_RATE
                    env = math.exp(-t * 4.0)
                    sine = math.sin(2.0 * math.pi * b_freq * t) * env * 0.10
                    samples[idx] += sine

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
    out_path = out_dir / "slots_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "slots" / "assets" / "music" / "slots_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
