#!/usr/bin/env python3
"""Generate studio-quality soundtrack WAV files for Dr. Mario:
- drmario_fever.wav: High-energy syncopated funk Fever theme
- drmario_chill.wav: Smooth lounge bossa-nova Chill theme
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


def osc_saw(phase: float) -> float:
    p = phase - math.floor(phase)
    return 2.0 * p - 1.0


def osc_tri(phase: float) -> float:
    p = phase - math.floor(phase)
    return 2.0 * abs(2.0 * p - 1.0) - 1.0


def osc_square(phase: float, duty: float = 0.5) -> float:
    p = phase - math.floor(phase)
    return 1.0 if p < duty else -1.0


def osc_sine(phase: float) -> float:
    return math.sin(2.0 * math.pi * phase)


def generate_fever_theme() -> list[float]:
    # 64-step Fever Theme (16 bars of 4/4 at ~128 BPM -> ~15.0s)
    bpm = 128.0
    step_dur = (60.0 / bpm) / 4.0  # 16th note steps
    total_steps = 128  # 32 beats = 8 bars
    total_dur = total_steps * step_dur
    total_samples = int(SAMPLE_RATE * total_dur)
    buffer = [0.0] * total_samples

    # Iconic 64-step Fever melody pattern
    lead_notes = [
        # Phrase 1
        "C5", "C5", "D#5", "F5", "F#5", "G5", "C6", "",
        "A#5", "G5", "F5", "D#5", "F5", "F#5", "G5", "",
        # Phrase 2
        "C5", "C5", "D#5", "F5", "F#5", "G5", "D#6", "",
        "D6", "C6", "A5", "A#5", "B5", "C6", "", "",
        # Phrase 3
        "G5", "G5", "A#5", "C6", "C#6", "D6", "G6", "",
        "F6", "D6", "C6", "A#5", "C6", "C#6", "D6", "",
        # Phrase 4
        "D#6", "D6", "C6", "A#5", "G5", "F5", "D#5", "",
        "C5", "D#5", "F5", "F#5", "G5", "A#5", "C6", "",
    ]

    harm_notes = [
        "G4", "G4", "A#4", "C5", "C#5", "D5", "G5", "",
        "F5", "D5", "C5", "A#4", "C5", "C#5", "D5", "",
        "G4", "G4", "A#4", "C5", "C#5", "D5", "A#5", "",
        "A5", "G5", "E5", "F5", "F#5", "G5", "", "",
        "D5", "D5", "F5", "G5", "G#5", "A5", "D6", "",
        "C6", "A5", "G5", "F5", "G5", "G#5", "A5", "",
        "A#5", "A5", "G5", "F5", "D5", "C5", "A#4", "",
        "G4", "A#4", "C5", "C#5", "D5", "F5", "G5", "",
    ]

    bass_notes = [
        "C2", "C3", "G2", "C3", "D#2", "C3", "F2", "F#2",
        "G2", "G3", "D3", "G3", "A#2", "G3", "B2", "G3",
        "C2", "C3", "G2", "C3", "D#2", "C3", "F2", "F#2",
        "G2", "G3", "A2", "A#2", "B2", "C3", "C2", "G2",
        "G2", "G3", "D3", "G3", "A#2", "G3", "C3", "C#3",
        "D3", "D4", "A3", "D4", "F3", "D4", "F#3", "D4",
        "C3", "C4", "G3", "F3", "D3", "C3", "A#2", "G2",
        "C2", "D#2", "F2", "F#2", "G2", "A#2", "C3", "C2",
    ]

    # Render Lead & Harmony
    for step_idx in range(total_steps):
        s_mod = step_idx % len(lead_notes)
        l_note = lead_notes[s_mod]
        h_note = harm_notes[s_mod]
        b_note = bass_notes[s_mod]

        s_start = int(step_idx * step_dur * SAMPLE_RATE)
        s_len = int(step_dur * 1.6 * SAMPLE_RATE)

        # Lead Pulse Wave
        if l_note != "":
            freq = note_to_freq(l_note)
            for i in range(s_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / (step_dur * 1.6 * SAMPLE_RATE)
                env = math.exp(-7.5 * prog)
                # 25% duty pulse with vibrato
                vib = 1.0 + 0.012 * math.sin(2.0 * math.pi * 6.0 * t)
                sig = osc_square(t * (freq * vib), duty=0.28) * env * 0.18
                buffer[idx] += sig

        # Harmony Pulse Wave
        if h_note != "":
            freq = note_to_freq(h_note)
            for i in range(s_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / (step_dur * 1.6 * SAMPLE_RATE)
                env = math.exp(-8.0 * prog)
                sig = osc_square(t * freq, duty=0.5) * env * 0.10
                buffer[idx] += sig

        # Funky Slap Bass
        if b_note != "":
            freq = note_to_freq(b_note)
            b_len = int(step_dur * 1.0 * SAMPLE_RATE)
            for i in range(b_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / b_len
                env = math.exp(-5.5 * prog)
                saw = osc_saw(t * freq)
                tri = osc_tri(t * freq)
                sig = (saw * 0.6 + tri * 0.4) * env * 0.22
                buffer[idx] += sig

    # Drum Track
    beat_dur = step_dur * 4.0
    total_beats = total_steps // 4
    for b in range(total_beats):
        b_start = int(b * beat_dur * SAMPLE_RATE)

        # Kick on 1 & 3
        k_len = int(beat_dur * 0.32 * SAMPLE_RATE)
        for i in range(k_len):
            idx = (b_start + i) % total_samples
            t = i / SAMPLE_RATE
            prog = i / k_len
            k_freq = 135.0 * math.exp(-20.0 * t) + 42.0
            kick = math.sin(2.0 * math.pi * k_freq * t) * math.exp(-6.5 * prog) * 0.30
            buffer[idx] += kick

        # Snappy Snare on 2 & 4
        if b % 2 == 1:
            sn_len = int(beat_dur * 0.38 * SAMPLE_RATE)
            for i in range(sn_len):
                idx = (b_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / sn_len
                noise = math.sin(t * 89234.1) * math.exp(-11.0 * prog)
                body = math.sin(2.0 * math.pi * 200.0 * t) * math.exp(-12.0 * prog)
                buffer[idx] += (noise * 0.7 + body * 0.3) * 0.18

        # Shimmer Hi-hats
        for sub_h in range(4):
            h_start = b_start + int(sub_h * step_dur * SAMPLE_RATE)
            h_len = int(step_dur * 0.65 * SAMPLE_RATE)
            for i in range(h_len):
                idx = (h_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / h_len
                noise = math.sin(t * 192841.5) * math.exp(-22.0 * prog)
                buffer[idx] += noise * (0.07 if sub_h == 2 else 0.04)

    # Master Normalization
    peak = max(max(abs(s) for s in buffer), 1e-5)
    norm = 0.85 / peak
    return [s * norm for s in buffer]


def generate_chill_theme() -> list[float]:
    # 64-step Chill Theme (16 bars of 4/4 at ~98 BPM -> ~19.6s)
    bpm = 98.0
    step_dur = (60.0 / bpm) / 4.0  # 16th note steps
    total_steps = 128
    total_dur = total_steps * step_dur
    total_samples = int(SAMPLE_RATE * total_dur)
    buffer = [0.0] * total_samples

    # Chill iconic melody (swinging bossa nova)
    lead_notes = [
        "G4", "A4", "C5", "E5", "D5", "C5", "A4", "G4",
        "E4", "", "G4", "C5", "A4", "", "", "",
        "G4", "A4", "C5", "E5", "G5", "E5", "D5", "C5",
        "D5", "", "E5", "D5", "C5", "", "", "",
        "E5", "E5", "F5", "G5", "A5", "G5", "F5", "E5",
        "D5", "", "C5", "A4", "C5", "D5", "", "",
        "E5", "G5", "A5", "C6", "B5", "A5", "G5", "E5",
        "C5", "D5", "E5", "C5", "A4", "G4", "", "",
    ]

    bass_notes = [
        "C2", "C3", "G2", "C3", "F2", "C3", "G2", "C2",
        "E2", "E3", "A2", "E3", "F2", "C3", "G2", "C2",
        "C2", "C3", "G2", "C3", "F2", "C3", "G2", "C2",
        "D2", "D3", "A2", "D3", "G2", "C3", "G2", "C2",
        "F2", "F3", "C3", "F3", "E2", "E3", "B2", "E3",
        "D2", "D3", "A2", "D3", "C2", "C3", "G2", "C3",
        "F2", "F3", "C3", "F3", "G2", "G3", "D3", "G3",
        "C2", "G2", "C3", "G2", "F2", "G2", "C3", "C2",
    ]

    # Vibraphone / Electric Piano Lead
    for step_idx in range(total_steps):
        s_mod = step_idx % len(lead_notes)
        l_note = lead_notes[s_mod]
        b_note = bass_notes[s_mod]

        s_start = int(step_idx * step_dur * SAMPLE_RATE)
        s_len = int(step_dur * 2.2 * SAMPLE_RATE)

        if l_note != "":
            freq = note_to_freq(l_note)
            for i in range(s_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / (step_dur * 2.2 * SAMPLE_RATE)
                env = math.exp(-4.5 * prog)
                # Vibraphone sine + subtle warm tremolo
                trem = 1.0 + 0.15 * math.sin(2.0 * math.pi * 5.0 * t)
                f0 = osc_sine(t * freq)
                f1 = osc_sine(t * freq * 2.0) * 0.25
                f2 = osc_sine(t * freq * 3.0) * 0.10
                sig = (f0 + f1 + f2) * env * trem * 0.20
                buffer[idx] += sig

        # Warm Acoustic Walking Bass
        if b_note != "":
            freq = note_to_freq(b_note)
            b_len = int(step_dur * 1.5 * SAMPLE_RATE)
            for i in range(b_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / b_len
                env = math.exp(-4.5 * prog)
                tri = osc_tri(t * freq)
                sine = osc_sine(t * freq)
                sig = (tri * 0.5 + sine * 0.5) * env * 0.24
                buffer[idx] += sig

    # Latin Bossa Shaker & Rim Groove
    beat_dur = step_dur * 4.0
    total_beats = total_steps // 4
    for b in range(total_beats):
        b_start = int(b * beat_dur * SAMPLE_RATE)

        # Soft Bass drum
        k_len = int(beat_dur * 0.25 * SAMPLE_RATE)
        for i in range(k_len):
            idx = (b_start + i) % total_samples
            t = i / SAMPLE_RATE
            prog = i / k_len
            kick = math.sin(2.0 * math.pi * 85.0 * math.exp(-12.0 * t) * t) * math.exp(-6.0 * prog) * 0.20
            buffer[idx] += kick

        # Bossa Rimshot on beat 2 & 4
        if b % 2 == 1:
            r_len = int(beat_dur * 0.20 * SAMPLE_RATE)
            for i in range(r_len):
                idx = (b_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / r_len
                rim = math.sin(2.0 * math.pi * 850.0 * t) * math.exp(-25.0 * prog) * 0.16
                buffer[idx] += rim

        # Latin 16th Shaker Pattern
        for sub_s in range(4):
            sh_start = b_start + int(sub_s * step_dur * SAMPLE_RATE)
            sh_len = int(step_dur * 0.8 * SAMPLE_RATE)
            vol = 0.08 if sub_s in (1, 3) else 0.04
            for i in range(sh_len):
                idx = (sh_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / sh_len
                noise = math.sin(t * 148293.7) * math.exp(-16.0 * prog)
                buffer[idx] += noise * vol

    # Master Normalization
    peak = max(max(abs(s) for s in buffer), 1e-5)
    norm = 0.84 / peak
    return [s * norm for s in buffer]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    music_dir = root / "assets" / "music"
    music_dir.mkdir(parents=True, exist_ok=True)

    print("Composing Dr. Mario Fever Theme...")
    fever = generate_fever_theme()
    write_wav(music_dir / "drmario_fever.wav", fever)

    print("Composing Dr. Mario Chill Theme...")
    chill = generate_chill_theme()
    write_wav(music_dir / "drmario_chill.wav", chill)

    print("Dr. Mario soundtracks generated successfully!")


if __name__ == "__main__":
    main()
