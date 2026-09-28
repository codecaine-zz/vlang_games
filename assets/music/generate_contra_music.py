#!/usr/bin/env python3
"""Generate 140 BPM legendary military jungle rock arcade theme for Contra."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 140
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    # Iconic Contra Jungle Theme (D minor / F Major driving riffs)
    bass_riff = [38, 38, 50, 48, 38, 38, 50, 48, 41, 41, 53, 52, 43, 43, 55, 53]
    lead_riff = [62, 65, 67, 69, 65, 62, 60, 62, 65, 69, 72, 74, 72, 69, 67, 65]

    sixteenth = BEAT_DUR / 4.0
    num_steps = total_beats * 4

    for i in range(num_steps):
        start_t = i * sixteenth
        start_idx = int(start_t * SAMPLE_RATE)
        dur = sixteenth * 0.8
        dur_samples = int(dur * SAMPLE_RATE)

        # Driving punchy bassline
        bn = bass_riff[i % len(bass_riff)]
        bfreq = midi_to_freq(bn)
        for s in range(dur_samples):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 9.0)
            phase = (t * bfreq) % 1.0
            pulse = (1.0 if phase < 0.3 else -0.35) * 0.4
            samples[idx] += pulse * env * 0.45

        # Hard-hitting lead guitar riff
        ln = lead_riff[i % len(lead_riff)]
        lfreq = midi_to_freq(ln)
        for s in range(dur_samples):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 7.0)
            phase = (t * lfreq) % 1.0
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
    out_path = out_dir / "contra_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "contra" / "assets" / "music" / "contra_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
