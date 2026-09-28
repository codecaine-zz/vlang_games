#!/usr/bin/env python3
"""Generate iconic 138 BPM arcade sewer soundtrack for Mario Bros."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 138
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    # Mario Bros Arcade intro & sewer theme in C Major
    lead_notes = [
        60, 64, 67, 72, 71, 67, 64, 60, # C4, E4, G4, C5, B4, G4, E4, C4
        65, 69, 72, 77, 76, 72, 69, 65, # F4, A4, C5, F5, E5, C5, A4, F4
        67, 71, 74, 79, 77, 74, 71, 67, # G4, B4, D5, G5, F5, D5, B4, G4
        60, 64, 67, 72, 76, 72, 67, 60, # C4, E4, G4, C5, E5, C5, G4, C4
    ]

    sixteenth_dur = BEAT_DUR / 4.0
    num_sixteenths = total_beats * 4

    for i in range(num_sixteenths):
        start_t = i * sixteenth_dur
        start_idx = int(start_t * SAMPLE_RATE)
        dur = sixteenth_dur * 0.8
        dur_samples = int(dur * SAMPLE_RATE)

        # Pulse Lead synth
        ln = lead_notes[i % len(lead_notes)]
        lfreq = midi_to_freq(ln)
        for s in range(dur_samples):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 9.0)
            # Classic 12.5% duty pulse wave
            phase = (t * lfreq) % 1.0
            pulse = (1.0 if phase < 0.25 else -0.33) * 0.35
            samples[idx] += pulse * env * 0.5

        # Bouncy Plumber Bassline (Triangle wave)
        if i % 2 == 0:
            bn = lead_notes[i % len(lead_notes)] - 24
            bfreq = midi_to_freq(bn)
            for s in range(int(sixteenth_dur * 1.8 * SAMPLE_RATE)):
                idx = start_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 6.0)
                phase = (t * bfreq) % 1.0
                tri = (4.0 * phase - 1.0 if phase < 0.5 else 3.0 - 4.0 * phase) * 0.4
                samples[idx] += tri * env * 0.5

    # Snappy arcade noise percussion
    for b in range(total_beats):
        b_idx = int(b * BEAT_DUR * SAMPLE_RATE)
        for s in range(int(0.08 * SAMPLE_RATE)):
            idx = b_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            noise = (math.sin(s * 999.1) % 1.0) * 2.0 - 1.0
            samples[idx] += noise * math.exp(-t * 30.0) * 0.2

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
    out_path = out_dir / "mariobros_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "mariobros" / "assets" / "music" / "mariobros_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
