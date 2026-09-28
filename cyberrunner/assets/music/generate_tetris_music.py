#!/usr/bin/env python3
"""Generate studio-quality soundtrack WAV files for all classic NES / Game Boy Tetris tracks:
- tetris_type_a.wav (and tetris_bgm.wav): Iconic Korobeiniki (Theme A) - 144 BPM
- tetris_type_b.wav: Energetic Troika Russian Folk Dance (Theme B) - 152 BPM
- tetris_type_c.wav: Elegant Bach Menuet in B minor (Theme C) - 126 BPM
"""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100


def note_to_freq(note_name: str) -> float:
    if not note_name:
        return 0.0
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


# =========================================================================
# TYPE A: Iconic Korobeiniki (144 BPM)
# =========================================================================
def generate_tetris_type_a() -> list[float]:
    bpm = 144.0
    beat_dur = 60.0 / bpm
    total_beats = 32  # 8 bars (13.333s)
    total_dur = total_beats * beat_dur
    total_samples = int(SAMPLE_RATE * total_dur)
    buffer = [0.0] * total_samples

    sixteenth_dur = beat_dur / 4.0
    total_steps = total_beats * 4

    lead_notes = [
        # Bar 1: E5 B4 C5 D5 C5 B4 A4
        "E5", "E5", "B4", "C5", "D5", "D5", "C5", "B4",
        "A4", "A4", "A4", "C5", "E5", "E5", "D5", "C5",
        # Bar 2: B4 C5 D5 E5 C5 A4 A4
        "B4", "B4", "B4", "C5", "D5", "D5", "E5", "E5",
        "C5", "C5", "A4", "A4", "A4", "", "", "",
        # Bar 3: D5 F5 A5 G5 F5 E5 C5 E5
        "D5", "D5", "D5", "F5", "A5", "A5", "G5", "F5",
        "E5", "E5", "E5", "C5", "E5", "E5", "D5", "C5",
        # Bar 4: B4 C5 D5 E5 C5 A4 A4
        "B4", "B4", "B4", "C5", "D5", "D5", "E5", "E5",
        "C5", "C5", "A4", "A4", "A4", "", "", "",
        # Bar 5: Repeat A with flourish
        "E5", "E5", "B4", "C5", "D5", "D5", "C5", "B4",
        "A4", "A4", "A4", "C5", "E5", "E5", "D5", "C5",
        # Bar 6:
        "B4", "B4", "B4", "C5", "D5", "D5", "E5", "E5",
        "C5", "C5", "A4", "A4", "A4", "", "", "",
        # Bar 7:
        "D5", "D5", "D5", "F5", "A5", "A5", "G5", "F5",
        "E5", "E5", "E5", "C5", "E5", "E5", "D5", "C5",
        # Bar 8:
        "B4", "B4", "B4", "C5", "D5", "D5", "E5", "E5",
        "C5", "C5", "A4", "A4", "A4", "", "", "",
    ]

    harmony_notes = [
        "G#4", "G#4", "G#4", "A4", "B4", "B4", "A4", "G#4",
        "E4", "E4", "E4", "A4", "C5", "C5", "B4", "A4",
        "G#4", "G#4", "G#4", "A4", "B4", "B4", "C5", "C5",
        "A4", "A4", "E4", "E4", "E4", "", "", "",
        "F4", "F4", "F4", "A4", "C5", "C5", "B4", "A4",
        "G#4", "G#4", "G#4", "A4", "C5", "C5", "B4", "A4",
        "G#4", "G#4", "G#4", "A4", "B4", "B4", "C5", "C5",
        "A4", "A4", "E4", "E4", "E4", "", "", "",
        "G#4", "G#4", "G#4", "A4", "B4", "B4", "A4", "G#4",
        "E4", "E4", "E4", "A4", "C5", "C5", "B4", "A4",
        "G#4", "G#4", "G#4", "A4", "B4", "B4", "C5", "C5",
        "A4", "A4", "E4", "E4", "E4", "", "", "",
        "F4", "F4", "F4", "A4", "C5", "C5", "B4", "A4",
        "G#4", "G#4", "G#4", "A4", "C5", "C5", "B4", "A4",
        "G#4", "G#4", "G#4", "A4", "B4", "B4", "C5", "C5",
        "A4", "A4", "E4", "E4", "E4", "", "", "",
    ]

    bass_notes = [
        "E2", "E2", "B2", "E2", "A2", "A2", "E2", "A2",
        "E2", "E2", "B2", "E2", "A2", "A2", "E2", "A2",
        "E2", "E2", "B2", "E2", "E2", "E2", "B2", "E2",
        "A2", "A2", "E2", "A2", "A2", "A2", "E2", "A2",
        "D2", "D2", "A2", "D2", "D2", "D2", "A2", "D2",
        "A2", "A2", "E2", "A2", "A2", "A2", "E2", "A2",
        "E2", "E2", "B2", "E2", "E2", "E2", "B2", "E2",
        "A2", "A2", "E2", "A2", "A2", "A2", "E2", "A2",
        "E2", "E2", "B2", "E2", "A2", "A2", "E2", "A2",
        "E2", "E2", "B2", "E2", "A2", "A2", "E2", "A2",
        "E2", "E2", "B2", "E2", "E2", "E2", "B2", "E2",
        "A2", "A2", "E2", "A2", "A2", "A2", "E2", "A2",
        "D2", "D2", "A2", "D2", "D2", "D2", "A2", "D2",
        "A2", "A2", "E2", "A2", "A2", "A2", "E2", "A2",
        "E2", "E2", "B2", "E2", "E2", "E2", "B2", "E2",
        "A2", "A2", "E2", "A2", "A2", "A2", "E2", "A2",
    ]

    for step_idx in range(total_steps):
        s_mod = step_idx % len(lead_notes)
        l_note = lead_notes[s_mod]
        h_note = harmony_notes[s_mod]
        b_note = bass_notes[s_mod]

        s_start = int(step_idx * sixteenth_dur * SAMPLE_RATE)
        s_len = int(sixteenth_dur * 0.95 * SAMPLE_RATE)

        if l_note != "":
            freq = note_to_freq(l_note)
            for i in range(s_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / s_len
                env = math.exp(-3.5 * prog)
                phase = (t * freq) % 1.0
                pulse = 1.0 if phase < 0.35 else -1.0
                buffer[idx] += pulse * env * 0.24

        if h_note != "":
            freq = note_to_freq(h_note)
            for i in range(s_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / s_len
                env = math.exp(-4.5 * prog)
                phase = (t * freq) % 1.0
                tri = 4.0 * abs(phase - 0.5) - 1.0
                buffer[idx] += tri * env * 0.14

        if b_note != "":
            freq = note_to_freq(b_note)
            b_len = int(sixteenth_dur * 1.5 * SAMPLE_RATE)
            for i in range(b_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / b_len
                env = math.exp(-5.0 * prog)
                phase = (t * freq) % 1.0
                tri = 4.0 * abs(phase - 0.5) - 1.0
                sub = math.sin(2.0 * math.pi * freq * t) * 0.5
                buffer[idx] += (tri * 0.7 + sub * 0.3) * env * 0.28

    # Snappy 8-bit Noise Percussion
    for b in range(total_beats):
        b_start = int(b * beat_dur * SAMPLE_RATE)
        if b % 2 == 0:
            k_len = int(beat_dur * 0.3 * SAMPLE_RATE)
            for i in range(k_len):
                idx = (b_start + i) % total_samples
                t = i / SAMPLE_RATE
                k_freq = 140.0 * math.exp(-22.0 * t) + 45.0
                buffer[idx] += math.sin(2.0 * math.pi * k_freq * t) * math.exp(-12.0 * t) * 0.32
        if b % 2 == 1:
            sn_len = int(beat_dur * 0.25 * SAMPLE_RATE)
            for i in range(sn_len):
                idx = (b_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / sn_len
                noise = (float((i * 1103515245 + 12345) & 0xFFFF) / 32768.0 - 1.0) * math.exp(-18.0 * prog)
                tone = math.sin(2.0 * math.pi * 220.0 * t) * math.exp(-20.0 * prog) * 0.3
                buffer[idx] += (noise * 0.7 + tone) * 0.22
        for sub_h in range(4):
            h_start = b_start + int(sub_h * sixteenth_dur * SAMPLE_RATE)
            h_len = int(sixteenth_dur * 0.3 * SAMPLE_RATE)
            for i in range(h_len):
                idx = (h_start + i) % total_samples
                prog = i / h_len
                noise = (float((i * 987654321 + 54321) & 0xFFFF) / 32768.0 - 1.0) * math.exp(-30.0 * prog)
                buffer[idx] += noise * 0.05

    peak = max(max(abs(s) for s in buffer), 1e-5)
    norm = 0.85 / peak
    return [s * norm for s in buffer]


# =========================================================================
# TYPE B: Troika / Russian Folk Dance (152 BPM)
# =========================================================================
def generate_tetris_type_b() -> list[float]:
    bpm = 152.0
    beat_dur = 60.0 / bpm
    total_beats = 32  # 8 bars (12.631s)
    total_dur = total_beats * beat_dur
    total_samples = int(SAMPLE_RATE * total_dur)
    buffer = [0.0] * total_samples

    sixteenth_dur = beat_dur / 4.0
    total_steps = total_beats * 4

    # Troika energetic polka / dance motifs
    lead_notes = [
        # Phrase 1: D5 D5 Eb5 D5 C5 Bb4 A4 G4
        "D5", "D5", "D5", "D5", "Eb5", "D5", "C5", "Bb4",
        "A4", "A4", "Bb4", "C5", "D5", "D5", "G4", "",
        "D5", "D5", "D5", "D5", "Eb5", "D5", "C5", "Bb4",
        "A4", "A4", "Bb4", "A4", "G4", "", "G4", "",
        # Phrase 2: Bb4 C5 D5 G5 F5 Eb5 D5 C5
        "Bb4", "Bb4", "C5", "D5", "G5", "G5", "F5", "Eb5",
        "D5", "D5", "C5", "Bb4", "A4", "A4", "D5", "",
        "Bb4", "Bb4", "C5", "D5", "G5", "G5", "F5", "Eb5",
        "D5", "C5", "Bb4", "A4", "G4", "", "", "",
    ]

    harmony_notes = [
        "Bb4", "Bb4", "Bb4", "Bb4", "C5", "Bb4", "A4", "G4",
        "F#4", "F#4", "G4", "A4", "Bb4", "Bb4", "D4", "",
        "Bb4", "Bb4", "Bb4", "Bb4", "C5", "Bb4", "A4", "G4",
        "F#4", "F#4", "G4", "F#4", "D4", "", "D4", "",
        "G4", "G4", "A4", "Bb4", "D5", "D5", "C5", "C5",
        "Bb4", "Bb4", "A4", "G4", "F#4", "F#4", "Bb4", "",
        "G4", "G4", "A4", "Bb4", "D5", "D5", "C5", "C5",
        "Bb4", "A4", "G4", "F#4", "D4", "", "", "",
    ]

    bass_notes = [
        "G2", "G2", "D2", "G2", "C2", "C2", "G2", "C2",
        "D2", "D2", "A1", "D2", "G2", "G2", "D2", "G2",
        "G2", "G2", "D2", "G2", "C2", "C2", "G2", "C2",
        "D2", "D2", "A1", "D2", "G2", "G2", "G2", "G2",
        "G2", "G2", "D2", "G2", "C2", "C2", "G2", "C2",
        "D2", "D2", "A1", "D2", "D2", "D2", "A1", "D2",
        "G2", "G2", "D2", "G2", "C2", "C2", "G2", "C2",
        "D2", "D2", "A1", "D2", "G2", "D2", "G2", "G2",
    ]

    for step_idx in range(total_steps):
        s_mod = step_idx % len(lead_notes)
        l_note = lead_notes[s_mod]
        h_note = harmony_notes[s_mod]
        b_note = bass_notes[s_mod]

        s_start = int(step_idx * sixteenth_dur * SAMPLE_RATE)
        s_len = int(sixteenth_dur * 0.9 * SAMPLE_RATE)

        if l_note != "":
            freq = note_to_freq(l_note)
            for i in range(s_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / s_len
                env = math.exp(-4.0 * prog)
                phase = (t * freq) % 1.0
                pulse = 1.0 if phase < 0.4 else -1.0
                buffer[idx] += pulse * env * 0.25

        if h_note != "":
            freq = note_to_freq(h_note)
            for i in range(s_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / s_len
                env = math.exp(-4.5 * prog)
                phase = (t * freq) % 1.0
                tri = 4.0 * abs(phase - 0.5) - 1.0
                buffer[idx] += tri * env * 0.15

        if b_note != "":
            freq = note_to_freq(b_note)
            b_len = int(sixteenth_dur * 1.6 * SAMPLE_RATE)
            for i in range(b_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / b_len
                env = math.exp(-5.0 * prog)
                phase = (t * freq) % 1.0
                tri = 4.0 * abs(phase - 0.5) - 1.0
                buffer[idx] += tri * env * 0.28

    # Upbeat Polka Percussion
    for b in range(total_beats):
        b_start = int(b * beat_dur * SAMPLE_RATE)
        # Staccato kick on downbeats
        k_len = int(beat_dur * 0.25 * SAMPLE_RATE)
        for i in range(k_len):
            idx = (b_start + i) % total_samples
            t = i / SAMPLE_RATE
            k_freq = 150.0 * math.exp(-25.0 * t) + 40.0
            buffer[idx] += math.sin(2.0 * math.pi * k_freq * t) * math.exp(-14.0 * t) * 0.3

        # Snappy tambourine / snare on offbeats
        if b % 2 == 1:
            sn_len = int(beat_dur * 0.2 * SAMPLE_RATE)
            for i in range(sn_len):
                idx = (b_start + i) % total_samples
                prog = i / sn_len
                noise = (float((i * 987654321 + 12345) & 0xFFFF) / 32768.0 - 1.0) * math.exp(-22.0 * prog)
                buffer[idx] += noise * 0.18

    peak = max(max(abs(s) for s in buffer), 1e-5)
    norm = 0.85 / peak
    return [s * norm for s in buffer]


# =========================================================================
# TYPE C: Bach French Suite No. 3 in B Minor - Menuet (126 BPM)
# =========================================================================
def generate_tetris_type_c() -> list[float]:
    bpm = 126.0
    beat_dur = 60.0 / bpm
    total_beats = 36  # 12 bars of 3/4 time (~17.14s)
    total_dur = total_beats * beat_dur
    total_samples = int(SAMPLE_RATE * total_dur)
    buffer = [0.0] * total_samples

    sixteenth_dur = beat_dur / 4.0
    total_steps = total_beats * 4

    # Classical Baroque Bach Menuet Melody (B minor)
    lead_notes = [
        # Measure 1: B4 D5 F#5
        "B4", "B4", "C#5", "D5", "E5", "F#5", "G5", "F#5", "E5", "D5", "C#5", "B4",
        # Measure 2: F#5 A#4 C#5
        "F#5", "F#5", "F#5", "F#5", "A#4", "A#4", "C#5", "C#5", "F#4", "F#4", "A#4", "C#5",
        # Measure 3: D5 E5 F#5 G5 F#5 E5
        "D5", "D5", "E5", "F#5", "G5", "G5", "F#5", "E5", "D5", "D5", "C#5", "B4",
        # Measure 4: C#5 E5 G5 F#5
        "C#5", "C#5", "D5", "E5", "F#5", "F#5", "E5", "D5", "C#5", "B4", "A#4", "G#4",
        # Measure 5: F#4 A#4 C#5 F#5
        "F#4", "F#4", "A#4", "C#5", "F#5", "F#5", "F#5", "F#5", "E5", "D5", "C#5", "B4",
        # Measure 6: B4 D5 F#5 B5
        "B4", "B4", "D5", "F#5", "B5", "B5", "B5", "B5", "A5", "G5", "F#5", "E5",
        # Measure 7: D5 F#5 A5 D6
        "D5", "D5", "F#5", "A5", "D6", "D6", "C#6", "B5", "A5", "G5", "F#5", "E5",
        # Measure 8: F#5 E5 D5 C#5 B4
        "F#5", "F#5", "E5", "D5", "C#5", "C#5", "B4", "A#4", "B4", "", "", "",
    ]

    bass_notes = [
        "B2", "B2", "F#2", "B2", "B2", "B2", "F#2", "B2", "B2", "B2", "F#2", "B2",
        "F#2", "F#2", "C#2", "F#2", "F#2", "F#2", "C#2", "F#2", "F#2", "F#2", "C#2", "F#2",
        "B2", "B2", "F#2", "B2", "G2", "G2", "D2", "G2", "B2", "B2", "F#2", "B2",
        "A#1", "A#1", "F#1", "A#1", "A#1", "A#1", "F#1", "A#1", "F#1", "F#1", "C#1", "F#1",
        "F#2", "F#2", "C#2", "F#2", "F#2", "F#2", "C#2", "F#2", "F#2", "F#2", "C#2", "F#2",
        "B2", "B2", "F#2", "B2", "B2", "B2", "F#2", "B2", "E2", "E2", "B1", "E2",
        "D2", "D2", "A1", "D2", "D2", "D2", "A1", "D2", "A1", "A1", "E1", "A1",
        "D2", "D2", "A1", "D2", "F#2", "F#2", "C#2", "F#2", "B2", "B2", "F#2", "B2",
    ]

    for step_idx in range(total_steps):
        s_mod = step_idx % len(lead_notes)
        l_note = lead_notes[s_mod]
        b_note = bass_notes[s_mod]

        s_start = int(step_idx * sixteenth_dur * SAMPLE_RATE)
        s_len = int(sixteenth_dur * 0.92 * SAMPLE_RATE)

        # Baroque Flute / Harpsichord Lead
        if l_note != "":
            freq = note_to_freq(l_note)
            for i in range(s_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / s_len
                env = math.exp(-3.2 * prog)
                saw = 2.0 * (t * freq - math.floor(t * freq + 0.5))
                pulse = 1.0 if (t * freq) % 1.0 < 0.25 else -1.0
                buffer[idx] += (saw * 0.4 + pulse * 0.6) * env * 0.24

        # Walking Cello / Viola Bass
        if b_note != "":
            freq = note_to_freq(b_note)
            b_len = int(sixteenth_dur * 1.8 * SAMPLE_RATE)
            for i in range(b_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / b_len
                env = math.exp(-4.0 * prog)
                tri = 4.0 * abs(((t * freq) % 1.0) - 0.5) - 1.0
                sub = math.sin(2.0 * math.pi * freq * t) * 0.4
                buffer[idx] += (tri * 0.7 + sub * 0.3) * env * 0.3

    # Gentle Classical Menuet Pulse
    for b in range(total_beats):
        if b % 3 == 0:
            b_start = int(b * beat_dur * SAMPLE_RATE)
            k_len = int(beat_dur * 0.3 * SAMPLE_RATE)
            for i in range(k_len):
                idx = (b_start + i) % total_samples
                t = i / SAMPLE_RATE
                buffer[idx] += math.sin(2.0 * math.pi * 90.0 * t) * math.exp(-16.0 * t) * 0.18

    peak = max(max(abs(s) for s in buffer), 1e-5)
    norm = 0.85 / peak
    return [s * norm for s in buffer]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    music_dir = root / "assets" / "music"
    music_dir.mkdir(parents=True, exist_ok=True)

    print("Composing Classic Tetris Soundtrack Suite...")

    print("1. Generating Type A (Korobeiniki)...")
    bgm_a = generate_tetris_type_a()
    write_wav(music_dir / "tetris_type_a.wav", bgm_a)
    write_wav(music_dir / "tetris_bgm.wav", bgm_a)

    print("2. Generating Type B (Troika)...")
    bgm_b = generate_tetris_type_b()
    write_wav(music_dir / "tetris_type_b.wav", bgm_b)

    print("3. Generating Type C (Bach Menuet)...")
    bgm_c = generate_tetris_type_c()
    write_wav(music_dir / "tetris_type_c.wav", bgm_c)

    print("All Classic Tetris music tracks generated successfully!")


if __name__ == "__main__":
    main()
