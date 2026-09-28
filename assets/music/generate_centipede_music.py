#!/usr/bin/env python3
"""Generate studio-quality soundtrack WAV file for Centipede:
- centipede_bgm.wav: High-tempo (134 BPM) arcade synthwave track with driving rolling bass, retro synth leads, danger alert sweeps, and tight electro-drums.
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


def generate_centipede_bgm() -> list[float]:
    bpm = 134.0
    beat_dur = 60.0 / bpm
    total_beats = 32  # 8 bars (~14.33s)
    total_dur = total_beats * beat_dur
    total_samples = int(SAMPLE_RATE * total_dur)
    buffer = [0.0] * total_samples

    sixteenth_dur = beat_dur / 4.0
    total_steps = total_beats * 4

    # High adrenaline arcade insect garden melody
    lead_notes = [
        # Phrase 1: Fast arcade synth arpeggio
        "E4", "G4", "B4", "E5", "G5", "E5", "B4", "G4",
        "D#4", "F#4", "A#4", "D#5", "F#5", "D#5", "A#4", "F#4",
        "D4", "F4", "A4", "D5", "F5", "D5", "A4", "F4",
        "C#4", "E4", "G#4", "C#5", "E5", "C#5", "G#4", "E4",
        # Phrase 2: Driving tension ascending rush
        "E4", "B4", "E5", "G5", "B5", "G5", "E5", "B4",
        "F4", "C5", "F5", "A5", "C6", "A5", "F5", "C5",
        "F#4", "C#5", "F#5", "A#5", "C#6", "A#5", "F#5", "C#5",
        "B4", "D#5", "F#5", "B5", "F#5", "D#5", "B4", "F#4",
    ]

    bass_notes = [
        "E2", "E2", "E3", "E2", "E2", "E3", "E2", "E2",
        "D#2", "D#2", "D#3", "D#2", "D#2", "D#3", "D#2", "D#2",
        "D2", "D2", "D3", "D2", "D2", "D3", "D2", "D2",
        "C#2", "C#2", "C#3", "C#2", "C#2", "C#3", "C#2", "C#2",
        "E2", "E2", "E3", "E2", "E2", "E3", "E2", "E2",
        "F2", "F2", "F3", "F2", "F2", "F3", "F2", "F2",
        "F#2", "F#2", "F#3", "F#2", "F#2", "F#3", "F#2", "F#2",
        "B1", "B1", "B2", "B1", "B1", "B2", "B1", "B1",
    ]

    for step_idx in range(total_steps):
        s_mod = step_idx % len(lead_notes)
        l_note = lead_notes[s_mod]
        b_note = bass_notes[s_mod]

        s_start = int(step_idx * sixteenth_dur * SAMPLE_RATE)
        s_len = int(sixteenth_dur * 1.6 * SAMPLE_RATE)

        # Crisp Pluck Lead Synth
        if l_note != "":
            freq = note_to_freq(l_note)
            for i in range(s_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / (sixteenth_dur * 1.6 * SAMPLE_RATE)
                env = math.exp(-8.0 * prog)
                pulse = 1.0 if (math.sin(2.0 * math.pi * freq * t) > 0.4) else -1.0
                sine = math.sin(2.0 * math.pi * freq * 2.0 * t) * 0.4
                sig = (pulse * 0.6 + sine * 0.4) * env * 0.17
                buffer[idx] += sig

        # Sawtooth Rolling Bass
        if b_note != "":
            freq = note_to_freq(b_note)
            b_len = int(sixteenth_dur * 1.1 * SAMPLE_RATE)
            for i in range(b_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / b_len
                env = math.exp(-6.0 * prog)
                saw = 2.0 * (t * freq - math.floor(t * freq + 0.5))
                sub = math.sin(2.0 * math.pi * (freq * 0.5) * t) * 0.45
                sig = (saw * 0.55 + sub) * env * 0.22
                buffer[idx] += sig

    # Drum Track
    for b in range(total_beats):
        b_start = int(b * beat_dur * SAMPLE_RATE)

        # Punchy 4-on-the-floor Kick
        k_len = int(beat_dur * 0.35 * SAMPLE_RATE)
        for i in range(k_len):
            idx = (b_start + i) % total_samples
            t = i / SAMPLE_RATE
            prog = i / k_len
            k_freq = 150.0 * math.exp(-24.0 * t) + 38.0
            kick = math.sin(2.0 * math.pi * k_freq * t) * math.exp(-6.5 * prog) * 0.32
            buffer[idx] += kick

        # Sharp Snare on Beats 2 & 4
        if b % 2 == 1:
            sn_len = int(beat_dur * 0.40 * SAMPLE_RATE)
            for i in range(sn_len):
                idx = (b_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / sn_len
                noise = math.sin(t * 89234.7) * math.exp(-14.0 * prog)
                tone = math.sin(2.0 * math.pi * 220.0 * t) * math.exp(-15.0 * prog)
                buffer[idx] += (noise * 0.75 + tone * 0.25) * 0.22

        # 16th Hi-hat groove
        for sub_h in range(4):
            h_start = b_start + int(sub_h * sixteenth_dur * SAMPLE_RATE)
            h_len = int(sixteenth_dur * 0.55 * SAMPLE_RATE)
            for i in range(h_len):
                idx = (h_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / h_len
                noise = math.sin(t * 192837.4) * math.exp(-25.0 * prog)
                buffer[idx] += noise * (0.07 if sub_h == 2 else 0.04)

    # Master Normalization
    peak = max(max(abs(s) for s in buffer), 1e-5)
    norm = 0.85 / peak
    return [s * norm for s in buffer]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    music_dir = root / "assets" / "music"
    music_dir.mkdir(parents=True, exist_ok=True)

    print("Composing Centipede Arcade Synthwave Theme...")
    bgm = generate_centipede_bgm()
    write_wav(music_dir / "centipede_bgm.wav", bgm)
    print("Centipede soundtrack generated successfully!")


if __name__ == "__main__":
    main()
