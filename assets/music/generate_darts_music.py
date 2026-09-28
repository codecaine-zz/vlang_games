#!/usr/bin/env python3
"""Generate studio-quality soundtrack WAV file for Championship Darts Pro:
- darts_bgm.wav: Warm, relaxed British pub lounge acoustic jazz theme featuring smooth upright bass, acoustic guitar rhythm, piano chords, and brushed drums at 112 BPM (~17.1s loop).
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


def generate_darts_bgm() -> list[float]:
    bpm = 112.0
    beat_dur = 60.0 / bpm
    total_beats = 32  # 8 bars (~17.14s)
    total_dur = total_beats * beat_dur
    total_samples = int(SAMPLE_RATE * total_dur)
    buffer = [0.0] * total_samples

    sixteenth_dur = beat_dur / 4.0
    total_steps = total_beats * 4

    # Relaxed Tavern Jazz Melody (G Major / E Minor progression)
    lead_notes = [
        "G4", "", "B4", "D5", "E5", "", "D5", "B4",
        "A4", "", "C5", "E5", "G5", "", "F#5", "E5",
        "D5", "", "F#5", "A5", "B5", "", "A5", "G5",
        "E5", "", "D5", "B4", "G4", "", "", "",
        "B4", "", "D5", "G5", "F#5", "", "E5", "D5",
        "C5", "", "E5", "G5", "A5", "", "G5", "E5",
        "D5", "", "B4", "G4", "A4", "", "B4", "D5",
        "G4", "", "B4", "D5", "G5", "", "", "",
    ]

    bass_notes = [
        "G2", "D3", "G2", "D3", "C3", "G3", "C3", "G3",
        "D3", "A3", "D3", "A3", "G2", "D3", "G2", "D3",
        "E2", "B2", "E2", "B2", "C3", "G3", "C3", "G3",
        "D3", "A3", "D3", "A3", "G2", "D3", "G2", "D3",
        "G2", "D3", "B2", "D3", "C3", "G3", "E3", "G3",
        "D3", "A3", "F#2", "A3", "G2", "D3", "B2", "D3",
        "E2", "B2", "G2", "B2", "A2", "E3", "C3", "E3",
        "D3", "A3", "D3", "A3", "G2", "D3", "G2", "",
    ]

    # 1. Warm Acoustic / Piano Lead
    for step_idx in range(total_steps):
        s_mod = step_idx % len(lead_notes)
        l_note = lead_notes[s_mod]

        if l_note != "":
            freq = note_to_freq(l_note)
            s_start = int(step_idx * sixteenth_dur * SAMPLE_RATE)
            s_len = int(sixteenth_dur * 1.5 * SAMPLE_RATE)

            for i in range(s_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / s_len
                env = math.exp(-3.8 * prog)

                sine = math.sin(2.0 * math.pi * freq * t)
                harm = math.sin(2.0 * math.pi * (freq * 2.0) * t) * 0.25
                sig = (sine + harm) * env * 0.25
                buffer[idx] += sig

    # 2. Warm Upright Bass
    for step_idx in range(total_steps):
        s_mod = step_idx % len(bass_notes)
        b_note = bass_notes[s_mod]

        if b_note != "":
            freq = note_to_freq(b_note)
            s_start = int(step_idx * sixteenth_dur * SAMPLE_RATE)
            b_len = int(sixteenth_dur * 1.8 * SAMPLE_RATE)

            for i in range(b_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / b_len
                env = math.exp(-4.0 * prog)

                sub = math.sin(2.0 * math.pi * freq * t)
                sig = sub * env * 0.32
                buffer[idx] += sig

    # 3. Soft Tavern Brushed Drums
    for b in range(total_beats):
        b_start = int(b * beat_dur * SAMPLE_RATE)

        # Soft Bass Drum
        k_len = int(beat_dur * 0.3 * SAMPLE_RATE)
        for i in range(k_len):
            idx = (b_start + i) % total_samples
            t = i / SAMPLE_RATE
            prog = i / k_len
            kick = math.sin(2.0 * math.pi * (95.0 * math.exp(-18.0 * t) + 35.0) * t) * math.exp(-6.0 * prog) * 0.25
            buffer[idx] += kick

        # Brush Snare on Beats 2 & 4
        if b % 2 == 1:
            sn_len = int(beat_dur * 0.35 * SAMPLE_RATE)
            for i in range(sn_len):
                idx = (b_start + i) % total_samples
                prog = i / sn_len
                noise = (float((i * 12345 + 6789) & 0xFFFF) / 32768.0 - 1.0) * math.exp(-12.0 * prog)
                buffer[idx] += noise * 0.14

        # Ride Cymbal / Shaker
        for sub_h in range(2):
            h_start = b_start + int(sub_h * (beat_dur / 2.0) * SAMPLE_RATE)
            h_len = int(beat_dur * 0.4 * SAMPLE_RATE)
            for i in range(h_len):
                idx = (h_start + i) % total_samples
                prog = i / h_len
                noise = (float((i * 54321 + 987) & 0xFFFF) / 32768.0 - 1.0) * math.exp(-22.0 * prog)
                buffer[idx] += noise * 0.05

    # Master Normalization
    peak = max(max(abs(s) for s in buffer), 1e-5)
    norm = 0.85 / peak
    return [s * norm for s in buffer]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    music_dir = root / "assets" / "music"
    music_dir.mkdir(parents=True, exist_ok=True)

    print("Composing Championship Darts Tavern Soundtrack...")
    bgm = generate_darts_bgm()
    write_wav(music_dir / "darts_bgm.wav", bgm)
    print("Darts soundtrack generated successfully!")


if __name__ == "__main__":
    main()
