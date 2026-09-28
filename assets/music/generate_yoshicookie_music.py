#!/usr/bin/env python3
"""Generate cheerful 136 BPM bakery ragtime music for Yoshi's Cookie."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 136
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    # Yoshi's Cookie melody in F Major
    melody_notes = [
        65, 69, 72, 77, 76, 72, 69, 65, # F, A, C, F, E, C, A, F
        67, 70, 74, 79, 77, 74, 70, 67, # G, Bb, D, G, F, D, Bb, G
        69, 72, 76, 81, 79, 76, 72, 69, # A, C, E, A, G, E, C, A
        70, 74, 77, 82, 81, 77, 74, 70, # Bb, D, F, Bb, A, F, D, Bb
    ]

    sixteenth_dur = BEAT_DUR / 4.0
    num_sixteenths = total_beats * 4

    for i in range(num_sixteenths):
        start_t = i * sixteenth_dur
        start_idx = int(start_t * SAMPLE_RATE)
        dur = sixteenth_dur * 0.85
        dur_samples = int(dur * SAMPLE_RATE)

        # Ragtime acoustic piano / marimba melody
        mn = melody_notes[i % len(melody_notes)]
        mfreq = midi_to_freq(mn)
        for s in range(dur_samples):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 11.0)
            # Marimba woody pluck + sine
            harm = math.sin(2.0 * math.pi * (mfreq * 2.0) * t) * 0.25
            fund = math.sin(2.0 * math.pi * mfreq * t) * 0.4
            samples[idx] += (fund + harm) * env * 0.5

        # Oom-pah Bass (roots on beats, chords on offbeats)
        beat_in_bar = (i // 4) % 4
        if i % 4 == 0:
            # Root bass note
            bn = 41 if beat_in_bar in (0, 2) else 48 # F1 or C2
            bfreq = midi_to_freq(bn)
            for s in range(int(0.18 * SAMPLE_RATE)):
                idx = start_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                samples[idx] += math.sin(2.0 * math.pi * bfreq * t) * math.exp(-t * 8.0) * 0.45
        elif i % 4 == 2:
            # Upbeat chord comping
            for cn in [57, 60, 65]:
                cfreq = midi_to_freq(cn)
                for s in range(int(0.12 * SAMPLE_RATE)):
                    idx = start_idx + s
                    if idx >= total_samples:
                        break
                    t = s / SAMPLE_RATE
                    samples[idx] += math.sin(2.0 * math.pi * cfreq * t) * math.exp(-t * 14.0) * 0.15

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
    out_path = out_dir / "yoshicookie_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "yoshicookie" / "assets" / "music" / "yoshicookie_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
