#!/usr/bin/env python3
"""Generate studio-quality soundtrack WAV file for Balloon Fight:
- balloonfight_bgm.wav: Classic, bouncy, cheerful NES Balloon Fight / Balloon Trip theme with jaunty melody, staccato bass, light percussions, and arcade warmth.
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


def generate_balloonfight_bgm() -> list[float]:
    bpm = 142.0
    beat_dur = 60.0 / bpm
    total_beats = 32  # 8 bars (~13.52s)
    total_dur = total_beats * beat_dur
    total_samples = int(SAMPLE_RATE * total_dur)
    buffer = [0.0] * total_samples

    sixteenth_dur = beat_dur / 4.0
    total_steps = total_beats * 4

    # Authentic Balloon Trip / Balloon Fight theme
    lead_notes = [
        # Phrase 1: Iconic bouncy staccato melody
        "C5", "E5", "G5", "C6", "B5", "G5", "E5", "G5",
        "A5", "F5", "D5", "F5", "G5", "E5", "C5", "E5",
        "F5", "D5", "B4", "D5", "E5", "C5", "G4", "C5",
        "D5", "F5", "E5", "D5", "C5", "", "G4", "",
        # Phrase 2: Playful variation
        "C5", "E5", "G5", "C6", "D6", "C6", "B5", "A5",
        "G5", "E5", "C5", "E5", "F5", "D5", "B4", "G4",
        "A4", "C5", "E5", "A5", "G5", "E5", "C5", "E5",
        "D5", "F5", "B4", "D5", "C5", "", "", "",
    ]

    harmony_notes = [
        "E4", "G4", "C5", "E5", "D5", "B4", "G4", "B4",
        "C5", "A4", "F4", "A4", "B4", "G4", "E4", "G4",
        "A4", "F4", "D4", "F4", "G4", "E4", "C4", "E4",
        "F4", "A4", "G4", "F4", "E4", "", "E4", "",
        "E4", "G4", "C5", "E5", "F5", "E5", "D5", "C5",
        "B4", "G4", "E4", "G4", "A4", "F4", "D4", "B3",
        "C4", "E4", "A4", "C5", "B4", "G4", "E4", "G4",
        "F4", "A4", "D4", "F4", "E4", "", "", "",
    ]

    bass_notes = [
        "C3", "", "G2", "", "C3", "", "G2", "",
        "F2", "", "C3", "", "C3", "", "G2", "",
        "G2", "", "D3", "", "C3", "", "G2", "",
        "G2", "", "G2", "", "C3", "", "C3", "",
        "C3", "", "G2", "", "F2", "", "F2", "",
        "C3", "", "C3", "", "G2", "", "G2", "",
        "A2", "", "E3", "", "C3", "", "G2", "",
        "G2", "", "G2", "", "C3", "", "C2", "",
    ]

    for step_idx in range(total_steps):
        s_mod = step_idx % len(lead_notes)
        l_note = lead_notes[s_mod]
        h_note = harmony_notes[s_mod]
        b_note = bass_notes[s_mod]

        s_start = int(step_idx * sixteenth_dur * SAMPLE_RATE)
        s_len = int(sixteenth_dur * 1.2 * SAMPLE_RATE)

        # Pulse Lead
        if l_note != "":
            freq = note_to_freq(l_note)
            for i in range(s_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / s_len
                env = math.exp(-7.0 * prog)
                pulse = 1.0 if (math.sin(2.0 * math.pi * freq * t) > 0.5) else -1.0
                sig = pulse * env * 0.20
                buffer[idx] += sig

        # Harmony Pulse
        if h_note != "":
            freq = note_to_freq(h_note)
            for i in range(s_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / s_len
                env = math.exp(-7.0 * prog)
                pulse = 1.0 if (math.sin(2.0 * math.pi * freq * t) > 0.0) else -1.0
                sig = pulse * env * 0.12
                buffer[idx] += sig

        # Triangle Staccato Bass
        if b_note != "":
            freq = note_to_freq(b_note)
            b_len = int(sixteenth_dur * 1.8 * SAMPLE_RATE)
            for i in range(b_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / b_len
                env = math.exp(-5.0 * prog)
                sine = math.sin(2.0 * math.pi * freq * t)
                sub = math.sin(2.0 * math.pi * (freq * 0.5) * t) * 0.3
                sig = (sine * 0.7 + sub) * env * 0.25
                buffer[idx] += sig

    # Drum Track
    for b in range(total_beats):
        b_start = int(b * beat_dur * SAMPLE_RATE)

        # Light Kick
        k_len = int(beat_dur * 0.3 * SAMPLE_RATE)
        for i in range(k_len):
            idx = (b_start + i) % total_samples
            t = i / SAMPLE_RATE
            prog = i / k_len
            k_freq = 130.0 * math.exp(-20.0 * t) + 45.0
            kick = math.sin(2.0 * math.pi * k_freq * t) * math.exp(-6.0 * prog) * 0.26
            buffer[idx] += kick

        # Light Snare / Rimshot on Beats 2 & 4
        if b % 2 == 1:
            sn_len = int(beat_dur * 0.25 * SAMPLE_RATE)
            for i in range(sn_len):
                idx = (b_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / sn_len
                noise = (float((i * 1103515245 + 12345) & 0xFFFF) / 32768.0 - 1.0) * math.exp(-18.0 * prog)
                buffer[idx] += noise * 0.18

        # 16th hats
        for sub_h in range(4):
            h_start = b_start + int(sub_h * sixteenth_dur * SAMPLE_RATE)
            h_len = int(sixteenth_dur * 0.45 * SAMPLE_RATE)
            for i in range(h_len):
                idx = (h_start + i) % total_samples
                prog = i / h_len
                noise = (float((i * 987654321 + 54321) & 0xFFFF) / 32768.0 - 1.0) * math.exp(-24.0 * prog)
                buffer[idx] += noise * 0.05

    # Master Normalization
    peak = max(max(abs(s) for s in buffer), 1e-5)
    norm = 0.85 / peak
    return [s * norm for s in buffer]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    music_dir = root / "assets" / "music"
    music_dir.mkdir(parents=True, exist_ok=True)

    print("Composing Balloon Fight Arcade BGM...")
    bgm = generate_balloonfight_bgm()
    write_wav(music_dir / "balloonfight_bgm.wav", bgm)
    print("Balloon Fight soundtrack generated successfully!")


if __name__ == "__main__":
    main()
