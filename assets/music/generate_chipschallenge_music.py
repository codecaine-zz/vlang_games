#!/usr/bin/env python3
"""Generate studio-quality soundtrack WAV file for Chip's Challenge Deluxe:
- chipschallenge_bgm.wav: Upbeat, quirky, nostalgic retro puzzle adventure theme featuring catchy melodic synth arpeggios, bouncy bass, FM bells, and rhythmic percussion at 128 BPM (~15.0s loop).
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


def generate_chipschallenge_bgm() -> list[float]:
    bpm = 128.0
    beat_dur = 60.0 / bpm
    total_beats = 32  # 8 bars (15.0s)
    total_dur = total_beats * beat_dur
    total_samples = int(SAMPLE_RATE * total_dur)
    buffer = [0.0] * total_samples

    sixteenth_dur = beat_dur / 4.0
    total_steps = total_beats * 4

    # Catchy Chip's Challenge Puzzle Melody (C Major / G Major playful motif)
    lead_notes = [
        # Bar 1-2: Playful chip discovery
        "C5", "E5", "G5", "C6", "B5", "G5", "E5", "G5",
        "A5", "F5", "D5", "F5", "G5", "E5", "C5", "E5",
        "F5", "D5", "B4", "D5", "E5", "C5", "A4", "C5",
        "D5", "B4", "G4", "B4", "C5", "", "C5", "",
        # Bar 3-4: Puzzle thinking variation
        "E5", "G5", "C6", "E6", "D6", "B5", "G5", "B5",
        "C6", "A5", "F5", "A5", "B5", "G5", "E5", "G5",
        "A5", "F#5", "D5", "F#5", "G5", "D5", "B4", "D5",
        "G5", "B5", "D6", "B5", "C6", "", "", "",
    ]

    # Bouncy Walking Bassline
    bass_notes = [
        # Bar 1-2
        "C3", "G3", "C3", "G3", "F2", "C3", "F2", "C3",
        "D3", "A3", "D3", "A3", "G2", "D3", "G2", "D3",
        "A2", "E3", "A2", "E3", "F2", "C3", "F2", "C3",
        "G2", "D3", "G2", "D3", "C3", "G3", "C3", "G3",
        # Bar 3-4
        "C3", "G3", "C3", "G3", "B2", "F#3", "B2", "F#3",
        "A2", "E3", "A2", "E3", "E2", "B2", "E2", "B2",
        "D3", "A3", "D3", "A3", "G2", "D3", "G2", "D3",
        "G2", "D3", "B2", "D3", "C3", "G3", "C3", "",
    ]

    # 1. Lead Melody Synthesis (Square + Pulse FM with slight vibrato)
    for step_idx in range(total_steps):
        s_mod = step_idx % len(lead_notes)
        l_note = lead_notes[s_mod]

        if l_note != "":
            freq = note_to_freq(l_note)
            s_start = int(step_idx * sixteenth_dur * SAMPLE_RATE)
            s_len = int(sixteenth_dur * 1.4 * SAMPLE_RATE)

            for i in range(s_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / s_len
                env = math.exp(-4.5 * prog)

                # Vibrant chiptune pulse wave (duty cycle 25%)
                vib = math.sin(2.0 * math.pi * 6.0 * t) * 4.0 if t > 0.05 else 0.0
                f_cur = freq + vib
                phase = math.fmod(t * f_cur, 1.0)
                pulse = 0.8 if phase < 0.25 else -0.8

                # Bell chime overtone
                chime = math.sin(2.0 * math.pi * (freq * 2.0) * t) * math.exp(-12.0 * prog) * 0.3
                sig = (pulse * 0.7 + chime) * env * 0.24
                buffer[idx] += sig

    # 2. Bass Synthesis (Round synth bass with punchy decay)
    for step_idx in range(total_steps):
        s_mod = step_idx % len(bass_notes)
        b_note = bass_notes[s_mod]

        if b_note != "":
            freq = note_to_freq(b_note)
            s_start = int(step_idx * sixteenth_dur * SAMPLE_RATE)
            b_len = int(sixteenth_dur * 1.6 * SAMPLE_RATE)

            for i in range(b_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / b_len
                env = math.exp(-5.0 * prog)

                sine = math.sin(2.0 * math.pi * freq * t)
                saw = 2.0 * (t * freq - math.floor(t * freq + 0.5)) * 0.3
                dist = math.tanh((sine + saw) * 1.5)
                sig = dist * env * 0.28
                buffer[idx] += sig

    # 3. Upbeat Arcade Drums & Shaker Groove
    for b in range(total_beats):
        b_start = int(b * beat_dur * SAMPLE_RATE)

        # Punchy Kick on Beats 0, 1, 2, 3 (Four-on-the-floor)
        k_len = int(beat_dur * 0.35 * SAMPLE_RATE)
        for i in range(k_len):
            idx = (b_start + i) % total_samples
            t = i / SAMPLE_RATE
            prog = i / k_len
            k_freq = 130.0 * math.exp(-22.0 * t) + 42.0
            kick = math.sin(2.0 * math.pi * k_freq * t) * math.exp(-6.0 * prog) * 0.30
            buffer[idx] += kick

        # Crisp Snare on Beats 1 & 3 (Backbeat)
        if b % 2 == 1:
            sn_len = int(beat_dur * 0.28 * SAMPLE_RATE)
            for i in range(sn_len):
                idx = (b_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / sn_len
                noise = (float((i * 1664525 + 1013904223) & 0xFFFF) / 32768.0 - 1.0) * math.exp(-18.0 * prog)
                body = math.sin(2.0 * math.pi * 240.0 * t) * math.exp(-14.0 * prog) * 0.4
                buffer[idx] += (noise * 0.7 + body) * 0.22

        # 16th-note Shaker / Hi-Hat
        for sub_h in range(4):
            h_start = b_start + int(sub_h * sixteenth_dur * SAMPLE_RATE)
            h_len = int(sixteenth_dur * 0.35 * SAMPLE_RATE)
            for i in range(h_len):
                idx = (h_start + i) % total_samples
                prog = i / h_len
                noise = (float((i * 22695477 + 1) & 0xFFFF) / 32768.0 - 1.0) * math.exp(-30.0 * prog)
                h_vol = 0.08 if sub_h % 2 == 1 else 0.05
                buffer[idx] += noise * h_vol

    # Master Normalization
    peak = max(max(abs(s) for s in buffer), 1e-5)
    norm = 0.85 / peak
    return [s * norm for s in buffer]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    music_dir = root / "assets" / "music"
    music_dir.mkdir(parents=True, exist_ok=True)

    print("Composing Chip's Challenge Soundtrack...")
    bgm = generate_chipschallenge_bgm()
    write_wav(music_dir / "chipschallenge_bgm.wav", bgm)
    print("Chip's Challenge soundtrack generated successfully!")


if __name__ == "__main__":
    main()
