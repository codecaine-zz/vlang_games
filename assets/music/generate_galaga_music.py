#!/usr/bin/env python3
"""Generate studio-quality soundtrack WAV file for Galaga:
- galaga_bgm.wav: Iconic arcade space theme with opening fanfare, space sirens, pulsing bass, and driving cosmic rhythm
"""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100


def note_to_freq(note_name: str) -> float:
    flat_map = {"Db": "C#", "Eb": "D#", "Gb": "F#", "Ab": "G#", "Bb": "A#"}
    notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    name = note_name[:-1]
    octave = int(note_name[-1])
    if name in flat_map:
        name = flat_map[name]
    semitone = notes.index(name)
    midi = 12 * (octave + 1) + semitone
    return 440.0 * (2.0 ** ((midi - 69) / 12.0))


def clamp_s16(val: float) -> int:
    return int(max(-32767.0, min(32767.0, val)))


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    raw = bytearray()
    for s in samples:
        raw.extend(struct.pack("<h", clamp_s16(s * 32767.0)))
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(raw)
    print(f"Generated {path.name}: {len(samples) / SAMPLE_RATE:.2f}s ({len(samples)} samples)")


def generate_galaga_bgm() -> list[float]:
    bpm = 130.0
    beat_dur = 60.0 / bpm
    total_beats = 32  # 8 bars of 4/4 (~14.76s)
    total_dur = total_beats * beat_dur
    total_samples = int(SAMPLE_RATE * total_dur)
    buffer = [0.0] * total_samples

    # Galaga Iconic Theme Melody (Arpeggiated space fanfare)
    sixteenth_dur = beat_dur / 4.0
    total_steps = total_beats * 4

    lead_notes = [
        # Phrase 1: The famous opening rising fanfare
        "G4", "C5", "E5", "G5", "C6", "G5", "E5", "G5",
        "A#4", "D5", "F5", "A#5", "D6", "A#5", "F5", "A#5",
        "A4", "C5", "F5", "A5", "C6", "A5", "F5", "A5",
        "G4", "B4", "D5", "G5", "B5", "G5", "D5", "B4",
        # Phrase 2: Diving insect tension battle theme
        "C5", "D#5", "G5", "C6", "D#6", "C6", "G5", "D#5",
        "G#4", "C5", "D#5", "G#5", "C6", "G#5", "D#5", "C5",
        "A#4", "D5", "F5", "A#5", "D6", "A#5", "F5", "D5",
        "G4", "B4", "D5", "G5", "D5", "B4", "G4", "D4",
    ]

    bass_notes = [
        "C2", "C3", "G2", "C3", "C2", "C3", "G2", "C3",
        "A#1", "A#2", "F2", "A#2", "A#1", "A#2", "F2", "A#2",
        "F1", "F2", "C2", "F2", "F1", "F2", "C2", "F2",
        "G1", "G2", "D2", "G2", "G1", "G2", "D2", "G2",
        "C2", "C3", "G2", "C3", "C2", "C3", "G2", "C3",
        "G#1", "G#2", "D#2", "G#2", "G#1", "G#2", "D#2", "G#2",
        "A#1", "A#2", "F2", "A#2", "A#1", "A#2", "F2", "A#2",
        "G1", "G2", "D2", "G2", "G1", "G2", "D2", "G2",
    ]

    for step_idx in range(total_steps):
        s_mod = step_idx % len(lead_notes)
        l_note = lead_notes[s_mod]
        b_note = bass_notes[s_mod]

        s_start = int(step_idx * sixteenth_dur * SAMPLE_RATE)
        s_len = int(sixteenth_dur * 1.5 * SAMPLE_RATE)

        # Space Lead Synth (Chirping pulse with resonant brightness)
        if l_note != "":
            freq = note_to_freq(l_note)
            for i in range(s_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / (sixteenth_dur * 1.5 * SAMPLE_RATE)
                env = math.exp(-7.5 * prog)
                p1 = 1.0 if (math.sin(2.0 * math.pi * freq * t) > 0.3) else -1.0
                harm = math.sin(2.0 * math.pi * freq * 2.0 * t) * 0.35
                sig = (p1 * 0.7 + harm * 0.3) * env * 0.18
                buffer[idx] += sig

        # Driving 8th/16th Bass Synth
        if b_note != "":
            freq = note_to_freq(b_note)
            b_len = int(sixteenth_dur * 1.0 * SAMPLE_RATE)
            for i in range(b_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / b_len
                env = math.exp(-5.5 * prog)
                saw = 2.0 * (t * freq - math.floor(t * freq + 0.5))
                sub = math.sin(2.0 * math.pi * (freq * 0.5) * t) * 0.4
                sig = (saw * 0.6 + sub) * env * 0.22
                buffer[idx] += sig

    # Drum Track
    for b in range(total_beats):
        b_start = int(b * beat_dur * SAMPLE_RATE)

        # Arcade Kick
        k_len = int(beat_dur * 0.32 * SAMPLE_RATE)
        for i in range(k_len):
            idx = (b_start + i) % total_samples
            t = i / SAMPLE_RATE
            prog = i / k_len
            k_freq = 140.0 * math.exp(-22.0 * t) + 40.0
            kick = math.sin(2.0 * math.pi * k_freq * t) * math.exp(-7.0 * prog) * 0.30
            buffer[idx] += kick

        # Snare on 2 & 4
        if b % 2 == 1:
            sn_len = int(beat_dur * 0.38 * SAMPLE_RATE)
            for i in range(sn_len):
                idx = (b_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / sn_len
                noise = math.sin(t * 78921.3) * math.exp(-12.0 * prog)
                body = math.sin(2.0 * math.pi * 190.0 * t) * math.exp(-14.0 * prog)
                buffer[idx] += (noise * 0.7 + body * 0.3) * 0.20

        # High-hats
        for sub_h in range(4):
            h_start = b_start + int(sub_h * sixteenth_dur * SAMPLE_RATE)
            h_len = int(sixteenth_dur * 0.6 * SAMPLE_RATE)
            for i in range(h_len):
                idx = (h_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / h_len
                noise = math.sin(t * 174829.1) * math.exp(-22.0 * prog)
                buffer[idx] += noise * (0.07 if sub_h == 2 else 0.04)

    # Master Normalization
    peak = max(max(abs(s) for s in buffer), 1e-5)
    norm = 0.85 / peak
    return [s * norm for s in buffer]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    music_dir = root / "assets" / "music"
    music_dir.mkdir(parents=True, exist_ok=True)

    print("Composing Galaga Space Arcade Theme...")
    bgm = generate_galaga_bgm()
    write_wav(music_dir / "galaga_bgm.wav", bgm)
    print("Galaga soundtrack generated successfully!")


if __name__ == "__main__":
    main()
