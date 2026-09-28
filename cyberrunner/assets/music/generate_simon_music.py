#!/usr/bin/env python3
"""Generate 110 BPM synthwave ambient memory groove for Simon."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 110
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    # Simon quadrant tones: E4 (64), A4 (69), C#4 (61), E3 (52)
    quad_notes = [64, 69, 61, 52, 64, 61, 69, 64]
    sixteenth = BEAT_DUR / 4.0
    num_steps = total_beats * 4

    for i in range(num_steps):
        start_t = i * sixteenth
        start_idx = int(start_t * SAMPLE_RATE)
        dur = sixteenth * 0.65
        dur_samples = int(dur * SAMPLE_RATE)

        note = quad_notes[i % len(quad_notes)]
        freq = midi_to_freq(note)

        for s in range(dur_samples):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 8.0)
            phase = (t * freq) % 1.0
            sine = math.sin(2.0 * math.pi * freq * t)
            samples[idx] += sine * env * 0.35

        # Deep synthwave analog bass
        if i % 4 == 0:
            bn = note - 24
            bfreq = midi_to_freq(bn)
            for s in range(int(sixteenth * 3.5 * SAMPLE_RATE)):
                idx = start_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 4.0)
                saw = ((t * bfreq) % 1.0) * 2.0 - 1.0
                samples[idx] += saw * env * 0.3

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
    out_path = out_dir / "simon_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "simon" / "assets" / "music" / "simon_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
