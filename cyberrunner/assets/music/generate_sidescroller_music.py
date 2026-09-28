#!/usr/bin/env python3
"""Generate 138 BPM high-octane Cyberpunk / Synthwave action metal soundtrack for Sidescroller."""
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

    # Cyberpunk Synthwave D-minor Progression
    bassline = [
        38, 38, 50, 38, 41, 38, 43, 41,
        36, 36, 48, 36, 39, 36, 41, 39,
        34, 34, 46, 34, 38, 34, 41, 38,
        33, 33, 45, 33, 36, 33, 38, 36,
    ]

    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        start_idx = b * beat_samples

        # 8th-note Driving Saw Bassline
        for sub in range(2):
            b_idx = (b * 2 + sub) % len(bassline)
            freq = midi_to_freq(bassline[b_idx])
            sub_st = start_idx + int(sub * (beat_samples / 2.0))

            for s in range(int(beat_samples / 2.0 * 0.9)):
                idx = sub_st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 14.0)
                saw = 2.0 * (t * freq - math.floor(t * freq + 0.5))
                samples[idx] += saw * env * 0.28

        # 16th-note Synth Lead Arpeggio
        for sub in range(4):
            lead_note = bassline[(b * 4 + sub) % len(bassline)] + 24
            freq = midi_to_freq(lead_note)
            sub_st = start_idx + int(sub * (beat_samples / 4.0))

            for s in range(int(beat_samples / 4.0 * 0.75)):
                idx = sub_st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 22.0)
                pulse = 1.0 if (math.sin(2.0 * math.pi * freq * t) > 0.1) else -1.0
                samples[idx] += pulse * env * 0.16

        # Punchy Cyber Kick Drum
        for s in range(int(0.08 * SAMPLE_RATE)):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            k_freq = 150.0 * math.exp(-t * 30.0)
            samples[idx] += math.sin(2.0 * math.pi * k_freq * t) * math.exp(-t * 18.0) * 0.45

        # Snare / Clap on beats 2 & 4
        if b % 2 == 1:
            for s in range(int(0.12 * SAMPLE_RATE)):
                idx = start_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                noise = ((s * 4321) % 1000) / 500.0 - 1.0
                samples[idx] += noise * math.exp(-t * 24.0) * 0.35

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
    out_path = out_dir / "sidescroller_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "sidescroller" / "assets" / "music" / "sidescroller_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
