#!/usr/bin/env python3
"""Generate 120 BPM retro 90s bowling alley lounge synth jazz funk soundtrack for Bowling."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 120
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    # Upbeat funk / jazz chord progression: Fmaj7 - G7 - Em7 - Am7
    chords = [
        [53, 57, 60, 64],  # Fmaj7
        [55, 59, 62, 65],  # G7
        [52, 55, 59, 62],  # Em7
        [57, 60, 64, 67],  # Am7
    ]

    beat_samples = int(BEAT_DUR * SAMPLE_RATE)

    for b in range(total_beats):
        chord = chords[(b // 4) % len(chords)]
        start_idx = b * beat_samples

        for note_idx, note in enumerate(chord):
            freq = midi_to_freq(note)
            st = start_idx + int(note_idx * (beat_samples / 4.0))

            for s in range(int(beat_samples * 0.85)):
                idx = st + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 8.0)
                phase = (t * freq) % 1.0
                pulse = (1.0 if phase < 0.3 else -0.35) * 0.3
                samples[idx] += pulse * env * 0.35

        # Slap bassline
        bn = chord[0] - 12
        bfreq = midi_to_freq(bn)
        for s in range(int(beat_samples * 0.6)):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 12.0)
            phase = (t * bfreq) % 1.0
            saw = (phase * 2.0 - 1.0) * 0.35
            samples[idx] += saw * env * 0.45

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
    out_path = out_dir / "bowling_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "bowling" / "assets" / "music" / "bowling_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
