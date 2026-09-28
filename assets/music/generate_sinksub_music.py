#!/usr/bin/env python3
"""Generate studio-quality soundtrack WAV file for SinkSub (Submarine Hunter):
- sinksub_bgm.wav: Dramatic, tense, tactical naval warfare theme featuring deep sonar ping pulses, driving military bass, pulsing industrial rhythm, and sonar sweep atmospheres at 128 BPM (~15.0s loop).
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


def generate_sinksub_bgm() -> list[float]:
    bpm = 128.0
    beat_dur = 60.0 / bpm
    total_beats = 32  # 8 bars (15.0s)
    total_dur = total_beats * beat_dur
    total_samples = int(SAMPLE_RATE * total_dur)
    buffer = [0.0] * total_samples

    sixteenth_dur = beat_dur / 4.0
    total_steps = total_beats * 4

    # Tactical Cold War Naval Motifs (D minor / D Phrygian tension)
    lead_notes = [
        # Phrase 1: Threat Detection & Sonar sweep
        "D4", "F4", "A4", "D5", "C#5", "A4", "F4", "D4",
        "Eb4", "G4", "Bb4", "Eb5", "D5", "Bb4", "G4", "Eb4",
        "D4", "F4", "A4", "D5", "F5", "E5", "D5", "C5",
        "Bb4", "A4", "G4", "F4", "E4", "F4", "D4", "",
        # Phrase 2: Depth Charge Barrage Assault
        "D5", "A4", "F4", "A4", "D5", "F5", "E5", "D5",
        "C5", "G4", "E4", "G4", "C5", "E5", "D5", "C5",
        "Bb4", "F4", "D4", "F4", "Bb4", "D5", "C5", "Bb4",
        "A4", "E4", "C#4", "E4", "A4", "C#5", "D5", "",
    ]

    bass_notes = [
        "D2", "D2", "A1", "D2", "D2", "D2", "A1", "D2",
        "Eb2", "Eb2", "Bb1", "Eb2", "Eb2", "Eb2", "Bb1", "Eb2",
        "D2", "D2", "A1", "D2", "D2", "D2", "A1", "D2",
        "Bb1", "Bb1", "F1", "Bb1", "A1", "A1", "D2", "D2",
        "D2", "D2", "A1", "D2", "D2", "D2", "A1", "D2",
        "C2", "C2", "G1", "C2", "C2", "C2", "G1", "C2",
        "Bb1", "Bb1", "F1", "Bb1", "Bb1", "Bb1", "F1", "Bb1",
        "A1", "A1", "E1", "A1", "A1", "A1", "D2", "D2",
    ]

    for step_idx in range(total_steps):
        s_mod = step_idx % len(lead_notes)
        l_note = lead_notes[s_mod]
        b_note = bass_notes[s_mod]

        s_start = int(step_idx * sixteenth_dur * SAMPLE_RATE)
        s_len = int(sixteenth_dur * 1.3 * SAMPLE_RATE)

        # Pulse Saw Lead with Filter Decay
        if l_note != "":
            freq = note_to_freq(l_note)
            for i in range(s_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / s_len
                env = math.exp(-6.0 * prog)
                # Resonant band
                saw = 2.0 * (t * freq - math.floor(t * freq + 0.5))
                sub = math.sin(2.0 * math.pi * (freq * 0.5) * t) * 0.3
                sig = (saw * 0.7 + sub) * env * 0.22
                buffer[idx] += sig

        # Heavy Industrial Sub-Bass
        if b_note != "":
            freq = note_to_freq(b_note)
            b_len = int(sixteenth_dur * 2.0 * SAMPLE_RATE)
            for i in range(b_len):
                idx = (s_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / b_len
                env = math.exp(-4.0 * prog)
                sub_bass = math.sin(2.0 * math.pi * freq * t)
                dist = math.tanh(sub_bass * 2.0)
                sig = dist * env * 0.28
                buffer[idx] += sig

    # Atmospheric Sonar Pings Every 4 Beats (1 Bar)
    for bar in range(total_beats // 4):
        ping_start = int(bar * 4 * beat_dur * SAMPLE_RATE)
        ping_len = int(beat_dur * 2.5 * SAMPLE_RATE)
        for i in range(ping_len):
            idx = (ping_start + i) % total_samples
            t = i / SAMPLE_RATE
            env = math.exp(-5.0 * t)
            # High 1567.98Hz (G6) / 1046.5Hz (C6) Sonar Ping
            ping_f = 1480.0
            ping_sin = math.sin(2.0 * math.pi * ping_f * t)
            echo_t = max(0.0, t - 0.22)
            echo_sin = math.sin(2.0 * math.pi * (ping_f * 0.75) * echo_t) * math.exp(-7.0 * echo_t) if t > 0.22 else 0.0
            buffer[idx] += (ping_sin + echo_sin * 0.4) * env * 0.16

    # Military Marching Drums & Hydrophone Noise
    for b in range(total_beats):
        b_start = int(b * beat_dur * SAMPLE_RATE)

        # Deep Depth-Charge Kick
        k_len = int(beat_dur * 0.4 * SAMPLE_RATE)
        for i in range(k_len):
            idx = (b_start + i) % total_samples
            t = i / SAMPLE_RATE
            prog = i / k_len
            k_freq = 110.0 * math.exp(-18.0 * t) + 38.0
            kick = math.sin(2.0 * math.pi * k_freq * t) * math.exp(-5.0 * prog) * 0.32
            buffer[idx] += kick

        # Sharp Naval Snare on Beats 2 & 4
        if b % 2 == 1:
            sn_len = int(beat_dur * 0.3 * SAMPLE_RATE)
            for i in range(sn_len):
                idx = (b_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / sn_len
                noise = (float((i * 1103515245 + 12345) & 0xFFFF) / 32768.0 - 1.0) * math.exp(-16.0 * prog)
                body = math.sin(2.0 * math.pi * 210.0 * t) * math.exp(-12.0 * prog) * 0.4
                buffer[idx] += (noise * 0.7 + body) * 0.22

        # Rhythmic high hats
        for sub_h in range(4):
            h_start = b_start + int(sub_h * sixteenth_dur * SAMPLE_RATE)
            h_len = int(sixteenth_dur * 0.4 * SAMPLE_RATE)
            for i in range(h_len):
                idx = (h_start + i) % total_samples
                prog = i / h_len
                noise = (float((i * 987654321 + 54321) & 0xFFFF) / 32768.0 - 1.0) * math.exp(-26.0 * prog)
                buffer[idx] += noise * 0.06

    # Master Normalization
    peak = max(max(abs(s) for s in buffer), 1e-5)
    norm = 0.85 / peak
    return [s * norm for s in buffer]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    music_dir = root / "assets" / "music"
    music_dir.mkdir(parents=True, exist_ok=True)

    print("Composing SinkSub Naval Soundtrack...")
    bgm = generate_sinksub_bgm()
    write_wav(music_dir / "sinksub_bgm.wav", bgm)
    print("SinkSub soundtrack generated successfully!")


if __name__ == "__main__":
    main()
