#!/usr/bin/env python3
"""Generate studio-quality soundtrack WAV file for Memory Match:
- memorymatch_bgm.wav: Whimsical, relaxing, crystalline memory lounge soundtrack
  with acoustic music box marimba, gentle harp chimes, soft pizzicato bass,
  and warm ambience at 116 BPM (~16.55s seamless loop).
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


def generate_memorymatch_bgm() -> list[float]:
    bpm = 116.0
    beat_dur = 60.0 / bpm
    total_beats = 32  # 8 bars (~16.55s)
    total_dur = total_beats * beat_dur
    total_samples = int(SAMPLE_RATE * total_dur)
    buffer = [0.0] * total_samples

    sixteenth_dur = beat_dur / 4.0
    total_steps = total_beats * 4

    # Whimsical Pentatonic Harp / Music Box Melody in C Major / G Major
    lead_notes = [
        # Measure 1-2: C5 E5 G5 B5 A5 G5 E5 D5 C5
        "C5", "E5", "G5", "B5", "A5", "G5", "E5", "D5",
        "C5", "D5", "E5", "G5", "A5", "G5", "E5", "D5",
        # Measure 3-4: F5 A5 C6 E6 D6 C6 A5 G5 E5
        "F5", "A5", "C6", "E6", "D6", "C6", "A5", "G5",
        "E5", "G5", "A5", "B5", "C6", "", "", "",
        # Measure 5-6: G5 B5 D6 F6 E6 D6 B5 A5 G5
        "G5", "B5", "D6", "F6", "E6", "D6", "B5", "A5",
        "G5", "A5", "B5", "D6", "C6", "B5", "A5", "G5",
        # Measure 7-8: A5 C6 E6 D6 C6 B5 A5 G5 C5
        "A5", "C6", "E6", "D6", "C6", "B5", "A5", "G5",
        "F5", "E5", "D5", "E5", "C5", "", "", "",
    ]

    counter_notes = [
        "E4", "G4", "C5", "E5", "D5", "C5", "G4", "F4",
        "E4", "G4", "C5", "E5", "F5", "E5", "C5", "G4",
        "A4", "C5", "F5", "A5", "G5", "F5", "C5", "B4",
        "G4", "B4", "C5", "D5", "E5", "", "", "",
        "B4", "D5", "G5", "B5", "A5", "G5", "D5", "C5",
        "B4", "D5", "G5", "B5", "C6", "B5", "G5", "D5",
        "C5", "E5", "A5", "C6", "B5", "A5", "E5", "D5",
        "C5", "G4", "F4", "G4", "E4", "", "", "",
    ]

    bass_notes = [
        "C3", "C3", "G2", "C3", "C3", "C3", "G2", "C3",
        "A2", "A2", "E2", "A2", "A2", "A2", "E2", "A2",
        "F2", "F2", "C2", "F2", "F2", "F2", "C2", "F2",
        "G2", "G2", "D2", "G2", "G2", "G2", "D2", "G2",
        "E2", "E2", "B1", "E2", "E2", "E2", "B1", "E2",
        "A2", "A2", "E2", "A2", "A2", "A2", "E2", "A2",
        "F2", "F2", "C2", "F2", "G2", "G2", "D2", "G2",
        "C3", "C3", "G2", "C3", "C3", "C3", "G2", "C3",
    ]

    for step_idx in range(total_steps):
        s_mod = step_idx % len(lead_notes)
        l_note = lead_notes[s_mod]
        c_note = counter_notes[s_mod]
        b_note = bass_notes[s_mod]

        s_start = int(step_idx * sixteenth_dur * SAMPLE_RATE)
        s_len = int(sixteenth_dur * 1.8 * SAMPLE_RATE)

        # Crystalline Glockenspiel / Marimba Lead
        if l_note != "":
            freq = note_to_freq(l_note)
            for i in range(s_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / s_len
                env = math.exp(-7.0 * prog)
                bell = math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(2.0 * math.pi * freq * 2.0 * t) * math.exp(-12.0 * prog)
                sparkle = math.sin(2.0 * math.pi * freq * 4.0 * t) * math.exp(-20.0 * prog) * 0.15
                buffer[idx] += (bell + sparkle) * env * 0.26

        # Soft Acoustic Harp Countermelody
        if c_note != "":
            freq = note_to_freq(c_note)
            for i in range(s_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / s_len
                env = math.exp(-6.0 * prog)
                harp = math.sin(2.0 * math.pi * freq * t) + 0.25 * math.sin(2.0 * math.pi * freq * 3.0 * t)
                buffer[idx] += harp * env * 0.18

        # Mellow Acoustic Pizzicato Upright Bass
        if b_note != "":
            freq = note_to_freq(b_note)
            b_len = int(sixteenth_dur * 2.2 * SAMPLE_RATE)
            for i in range(b_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / b_len
                env = math.exp(-5.0 * prog)
                body = math.sin(2.0 * math.pi * freq * t) + 0.4 * math.sin(2.0 * math.pi * freq * 2.0 * t) * math.exp(-8.0 * prog)
                buffer[idx] += body * env * 0.3

    # Gentle Shaker & Triangle Percussion
    for b in range(total_beats):
        b_start = int(b * beat_dur * SAMPLE_RATE)
        # Soft Triangle chime on downbeats
        if b % 4 == 0:
            tr_len = int(beat_dur * 1.5 * SAMPLE_RATE)
            for i in range(tr_len):
                idx = (b_start + i) % total_samples
                t = i / SAMPLE_RATE
                tri_tone = math.sin(2.0 * math.pi * 2093.0 * t) * math.exp(-8.0 * t) * 0.12
                buffer[idx] += tri_tone

        # Gentle Egg Shaker on each 16th note
        for sub_s in range(4):
            sh_start = b_start + int(sub_s * sixteenth_dur * SAMPLE_RATE)
            sh_len = int(sixteenth_dur * 0.35 * SAMPLE_RATE)
            for i in range(sh_len):
                idx = (sh_start + i) % total_samples
                prog = i / sh_len
                noise = (float((i * 1103515245 + 54321) & 0xFFFF) / 32768.0 - 1.0) * math.exp(-24.0 * prog)
                buffer[idx] += noise * 0.04

    peak = max(max(abs(s) for s in buffer), 1e-5)
    norm = 0.85 / peak
    return [s * norm for s in buffer]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    music_dir = root / "assets" / "music"
    music_dir.mkdir(parents=True, exist_ok=True)

    print("Composing Memory Match Soundtrack...")
    bgm = generate_memorymatch_bgm()
    write_wav(music_dir / "memorymatch_bgm.wav", bgm)

    local_music = root / "memorymatch" / "assets" / "music"
    local_music.mkdir(parents=True, exist_ok=True)
    write_wav(local_music / "memorymatch_bgm.wav", bgm)

    print("Memory Match soundtrack generated successfully!")


if __name__ == "__main__":
    main()
