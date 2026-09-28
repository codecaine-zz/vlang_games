#!/usr/bin/env python3
"""Generate 105 BPM ambient space synthesizer & telemetry soundtrack for Lunar Lander."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 105
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    # E minor ambient space arpeggios & warm pads
    pad_chords = [
        [52, 55, 59, 64], # Em
        [48, 52, 55, 60], # Cmaj
        [50, 53, 57, 62], # Dm
        [47, 50, 55, 59], # Gmaj
    ]

    chord_dur = BEAT_DUR * 16
    for c_idx, chord in enumerate(pad_chords):
        start_t = c_idx * chord_dur
        start_idx = int(start_t * SAMPLE_RATE)
        dur_samples = int(chord_dur * SAMPLE_RATE)

        for note in chord:
            freq = midi_to_freq(note)
            for s in range(dur_samples):
                idx = start_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.sin(math.pi * (s / dur_samples))
                # Warm slow detuned sine waves
                s1 = math.sin(2.0 * math.pi * freq * t)
                s2 = math.sin(2.0 * math.pi * (freq * 1.003) * t) * 0.5
                samples[idx] += (s1 + s2) * env * 0.18

    # Telemetry pulses every 2 beats
    for b in range(0, total_beats, 2):
        t_idx = int(b * BEAT_DUR * SAMPLE_RATE)
        for s in range(int(0.12 * SAMPLE_RATE)):
            idx = t_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            samples[idx] += math.sin(2.0 * math.pi * 1200.0 * t) * math.exp(-t * 25.0) * 0.15

    out = bytearray()
    for val in samples:
        clamped = max(-1.0, min(1.0, val * 0.75))
        ival = int(clamped * 32767.0)
        out.extend(struct.pack("<h", ival))
    return bytes(out)


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    pcm_data = generate_soundtrack()
    out_dir = root / "assets" / "music"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "lunarlander_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "lunarlander" / "assets" / "music" / "lunarlander_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
