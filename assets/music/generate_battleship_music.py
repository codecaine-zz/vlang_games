#!/usr/bin/env python3
"""Generate studio-quality soundtrack WAV file for Battleship Pro (Tactical Naval Warfare):
- battleship_bgm.wav: Epic, dramatic, tense naval warfare soundtrack featuring resonant sonar ping pulses, heavy military brass and sub-bass, marching snare rhythm, and radar hydrophone sweeps at 116 BPM (~16.5s loop).
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


def generate_battleship_bgm() -> list[float]:
    bpm = 116.0
    beat_dur = 60.0 / bpm
    total_beats = 32  # 8 bars (~16.55s)
    total_dur = total_beats * beat_dur
    total_samples = int(SAMPLE_RATE * total_dur)
    buffer = [0.0] * total_samples

    sixteenth_dur = beat_dur / 4.0
    total_steps = total_beats * 4

    # Tactical Naval Theme (D Minor / D Dorian military progression)
    brass_notes = [
        # Phrase 1: Tactical Radar Grid & Fleet Deployment
        "D3", "", "D3", "F3", "A3", "", "G3", "F3",
        "E3", "", "E3", "G3", "Bb3", "", "A3", "G3",
        "F3", "", "F3", "A3", "D4", "", "C4", "Bb3",
        "A3", "", "E3", "F3", "D3", "", "", "",
        # Phrase 2: Torpedo Launch & Heavy Artillery Barrage
        "D4", "", "A3", "F3", "D4", "F4", "E4", "D4",
        "C4", "", "G3", "E3", "C4", "E4", "D4", "C4",
        "Bb3", "", "F3", "D3", "Bb3", "D4", "C4", "Bb3",
        "A3", "", "C#4", "E4", "D4", "", "", "",
    ]

    bass_notes = [
        "D2", "D2", "A1", "D2", "D2", "D2", "A1", "D2",
        "Eb2", "Eb2", "Bb1", "Eb2", "Eb2", "Eb2", "Bb1", "Eb2",
        "F2", "F2", "C2", "F2", "F2", "F2", "C2", "F2",
        "A1", "A1", "E1", "A1", "D2", "D2", "A1", "D2",
        "D2", "D2", "A1", "D2", "D2", "D2", "A1", "D2",
        "C2", "C2", "G1", "C2", "C2", "C2", "G1", "C2",
        "Bb1", "Bb1", "F1", "Bb1", "Bb1", "Bb1", "F1", "Bb1",
        "A1", "A1", "E1", "A1", "D2", "D2", "A1", "D2",
    ]

    # 1. Heavy Brass / Horns Lead
    for step_idx in range(total_steps):
        s_mod = step_idx % len(brass_notes)
        l_note = brass_notes[s_mod]

        if l_note != "":
            freq = note_to_freq(l_note)
            s_start = int(step_idx * sixteenth_dur * SAMPLE_RATE)
            s_len = int(sixteenth_dur * 1.8 * SAMPLE_RATE)

            for i in range(s_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / s_len
                env = math.exp(-3.5 * prog)

                # Brass sawtooth with 2nd & 3rd harmonics
                saw1 = 2.0 * (t * freq - math.floor(t * freq + 0.5))
                saw2 = 2.0 * (t * (freq * 2.0) - math.floor(t * (freq * 2.0) + 0.5)) * 0.4
                saw3 = 2.0 * (t * (freq * 3.0) - math.floor(t * (freq * 3.0) + 0.5)) * 0.2
                sig = (saw1 + saw2 + saw3) * env * 0.22
                buffer[idx] += sig

    # 2. Resonant Naval Sub-Bass
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
                env = math.exp(-4.2 * prog)
                sub = math.sin(2.0 * math.pi * freq * t)
                dist = math.tanh(sub * 2.2)
                buffer[idx] += dist * env * 0.28

    # 3. Sonar Pings (Every 4 beats)
    for bar in range(total_beats // 4):
        ping_start = int(bar * 4 * beat_dur * SAMPLE_RATE)
        ping_len = int(beat_dur * 2.4 * SAMPLE_RATE)
        for i in range(ping_len):
            idx = (ping_start + i) % total_samples
            t = i / SAMPLE_RATE
            env = math.exp(-5.0 * t)
            ping_f = 1200.0
            ping_sin = math.sin(2.0 * math.pi * ping_f * t)
            echo_t = max(0.0, t - 0.2)
            echo_sin = math.sin(2.0 * math.pi * (ping_f * 0.8) * echo_t) * math.exp(-6.5 * echo_t) if t > 0.2 else 0.0
            buffer[idx] += (ping_sin + echo_sin * 0.45) * env * 0.18

    # 4. Military Marching Drum Section
    for b in range(total_beats):
        b_start = int(b * beat_dur * SAMPLE_RATE)

        # Cannon / Heavy Bass Drum
        k_len = int(beat_dur * 0.4 * SAMPLE_RATE)
        for i in range(k_len):
            idx = (b_start + i) % total_samples
            t = i / SAMPLE_RATE
            prog = i / k_len
            k_freq = 115.0 * math.exp(-20.0 * t) + 38.0
            kick = math.sin(2.0 * math.pi * k_freq * t) * math.exp(-5.0 * prog) * 0.34
            buffer[idx] += kick

        # Military Snare on Beats 2 & 4
        if b % 2 == 1:
            sn_len = int(beat_dur * 0.32 * SAMPLE_RATE)
            for i in range(sn_len):
                idx = (b_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / sn_len
                noise = (float((i * 1234567 + 98765) & 0xFFFF) / 32768.0 - 1.0) * math.exp(-15.0 * prog)
                body = math.sin(2.0 * math.pi * 190.0 * t) * math.exp(-12.0 * prog) * 0.4
                buffer[idx] += (noise * 0.75 + body) * 0.24

        # Hi-hats
        for sub_h in range(4):
            h_start = b_start + int(sub_h * sixteenth_dur * SAMPLE_RATE)
            h_len = int(sixteenth_dur * 0.35 * SAMPLE_RATE)
            for i in range(h_len):
                idx = (h_start + i) % total_samples
                prog = i / h_len
                noise = (float((i * 9876543 + 123) & 0xFFFF) / 32768.0 - 1.0) * math.exp(-28.0 * prog)
                buffer[idx] += noise * 0.06

    # Master Normalization
    peak = max(max(abs(s) for s in buffer), 1e-5)
    norm = 0.85 / peak
    return [s * norm for s in buffer]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    music_dir = root / "assets" / "music"
    music_dir.mkdir(parents=True, exist_ok=True)

    print("Composing Battleship Pro Naval Soundtrack...")
    bgm = generate_battleship_bgm()
    write_wav(music_dir / "battleship_bgm.wav", bgm)
    print("Battleship Pro soundtrack generated successfully!")


if __name__ == "__main__":
    main()
