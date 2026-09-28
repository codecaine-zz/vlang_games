#!/usr/bin/env python3
"""Generate 128 BPM cold war tactical radar soundtrack for Missile Command."""
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

    # D minor suspense tactical radar arpeggio
    arp_notes = [50, 53, 57, 62, 57, 53, 50, 53, 49, 53, 57, 61, 57, 53, 49, 53]
    step_dur = BEAT_DUR / 4.0
    num_steps = total_beats * 4

    for i in range(num_steps):
        start_t = i * step_dur
        start_idx = int(start_t * SAMPLE_RATE)
        dur = step_dur * 0.75
        dur_samples = int(dur * SAMPLE_RATE)

        note = arp_notes[i % len(arp_notes)]
        freq = midi_to_freq(note)

        for s in range(dur_samples):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 14.0)
            phase = (t * freq) % 1.0
            sq = (1.0 if phase < 0.3 else -1.0) * 0.3
            samples[idx] += sq * env * 0.45

        # Sub bass drone
        if i % 8 == 0:
            bfreq = midi_to_freq(note - 24)
            for s in range(int(step_dur * 6.0 * SAMPLE_RATE)):
                idx = start_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 3.0)
                samples[idx] += math.sin(2.0 * math.pi * bfreq * t) * env * 0.4

    # Radar sonar ping every 4 beats
    for b in range(0, total_beats, 4):
        ping_idx = int(b * BEAT_DUR * SAMPLE_RATE)
        for s in range(int(0.6 * SAMPLE_RATE)):
            idx = ping_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            samples[idx] += math.sin(2.0 * math.pi * 1760.0 * t) * math.exp(-t * 6.0) * 0.25

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
    out_path = out_dir / "missilecommand_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "missilecommand" / "assets" / "music" / "missilecommand_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
