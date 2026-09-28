#!/usr/bin/env python3
"""Generate high-energy 150 BPM arcade synthwave soundtrack for WorldRunner."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
BPM = 150
BEAT_DUR = 60.0 / BPM


def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def generate_soundtrack() -> bytes:
    total_beats = 64
    total_samples = int(total_beats * BEAT_DUR * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples

    # Bassline in D minor (D2, F2, G2, A2, C3, etc.)
    bass_notes = [38, 38, 41, 38, 43, 38, 45, 43, 38, 38, 41, 38, 40, 38, 36, 38]
    # Arpeggio Lead
    lead_notes = [62, 65, 69, 74, 72, 69, 65, 62, 60, 64, 67, 72, 70, 67, 64, 60]

    sixteenth_dur = BEAT_DUR / 4.0
    num_sixteenths = total_beats * 4

    for i in range(num_sixteenths):
        start_t = i * sixteenth_dur
        start_idx = int(start_t * SAMPLE_RATE)
        dur = sixteenth_dur * 0.9
        dur_samples = int(dur * SAMPLE_RATE)

        # Bass synth
        bn = bass_notes[i % len(bass_notes)]
        bfreq = midi_to_freq(bn)
        for s in range(dur_samples):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 9.0)
            # Sawtooth + sub-oscillator
            saw = (2.0 * ((t * bfreq) % 1.0) - 1.0) * 0.3
            sub = math.sin(2.0 * math.pi * (bfreq * 0.5) * t) * 0.25
            samples[idx] += (saw + sub) * env * 0.55

        # Lead synth
        ln = lead_notes[i % len(lead_notes)]
        lfreq = midi_to_freq(ln)
        for s in range(dur_samples):
            idx = start_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = math.exp(-t * 6.0)
            # Square wave + vibrato
            vib = math.sin(2.0 * math.pi * 5.0 * t) * 3.0
            phase = (t * (lfreq + vib)) % 1.0
            sq = (1.0 if phase < 0.5 else -1.0) * 0.25
            samples[idx] += sq * env * 0.45

    # Drums: Kick & Hi-hat
    for b in range(total_beats):
        kick_idx = int(b * BEAT_DUR * SAMPLE_RATE)
        for s in range(int(0.12 * SAMPLE_RATE)):
            idx = kick_idx + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            k_freq = 140.0 * math.exp(-t * 28.0)
            samples[idx] += math.sin(2.0 * math.pi * k_freq * t) * math.exp(-t * 20.0) * 0.65

        # Snare on beats 2 & 4
        if b % 2 == 1:
            snare_idx = kick_idx
            for s in range(int(0.15 * SAMPLE_RATE)):
                idx = snare_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                noise = (math.sin(s * 1337.1) % 1.0) * 2.0 - 1.0
                samples[idx] += noise * math.exp(-t * 22.0) * 0.4

    # Convert to 16-bit PCM mono
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
    out_path = out_dir / "worldrunner_bgm.wav"

    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)

    print(f"Generated {out_path} ({len(pcm_data)} bytes)")
    local_path = root / "worldrunner" / "assets" / "music" / "worldrunner_bgm.wav"
    local_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(local_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)


if __name__ == "__main__":
    main()
