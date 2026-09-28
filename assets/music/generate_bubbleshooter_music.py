#!/usr/bin/env python3
"""Generate 128 BPM whimsical puzzle soundtrack for Bubble Shooter."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 128
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    # Upbeat bubbly puzzle theme (F Major pentatonic)
    melody_notes = [
        65, 69, 72, 77, 76, 72, 69, 65,
        67, 70, 74, 79, 77, 74, 70, 67,
        69, 72, 76, 81, 79, 76, 72, 69,
        65, 69, 72, 77, 72, 69, 65, 60,
    ]

    sixteenth = BEAT_DUR / 4.0
    num_steps = total_beats * 4

    for i in range(num_steps):
        start_t = i * sixteenth
        start_idx = int(start_t * SAMPLE_RATE)
        dur = sixteenth * 0.75
        dur_samples = int(dur * SAMPLE_RATE)

        note = melody_notes[i % len(melody_notes)]
        freq = midi_to_freq(note)

        for s in range(dur_samples):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 14.0)
            phase = (t * freq) % 1.0
            pulse = (1.0 if phase < 0.3 else -0.4) * 0.35
            samples[idx] += pulse * env * 0.4

        # Bouncy bass
        if i % 2 == 0:
            bn = note - 24
            bfreq = midi_to_freq(bn)
            for s in range(int(sixteenth * 1.6 * SAMPLE_RATE)):
                idx = start_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 6.0)
                phase = (t * bfreq) % 1.0
                saw = (phase * 2.0 - 1.0) * 0.35
                samples[idx] += saw * env * 0.4

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
    out_path = out_dir / "bubbleshooter_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "bubbleshooter" / "assets" / "music" / "bubbleshooter_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
