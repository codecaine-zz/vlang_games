#!/usr/bin/env python3
"""Generate high-fidelity, authentic soundtrack WAV files for Bejeweled:
- bejeweled_bgm.wav: Cosmic Trance Suite (Classic Mode)
- bejeweled_zen.wav: Ethereal Zen Meditation (Zen Mode)
- bejeweled_blitz.wav: High-Energy Electro Rush (Lightning Mode)
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
    # A4 = 440 Hz -> midi 69
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


# Synth primitives
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


def generate_cosmic_trance() -> list[float]:
    bpm = 124.0
    beat_dur = 60.0 / bpm
    beats_per_bar = 4
    num_bars = 8
    total_beats = num_bars * beats_per_bar
    total_dur = total_beats * beat_dur
    total_samples = int(SAMPLE_RATE * total_dur)
    buffer = [0.0] * total_samples

    # Chord progression: Cm -> Ab -> Eb -> Bb (2 bars each = 8 bars total)
    chords = [
        # Bar 0-1: Cm
        {"bass": "C2", "pad": ["C3", "Eb3", "G3", "C4", "Eb4"], "arp": ["C4", "Eb4", "G4", "C5", "Eb5", "G5", "D5", "Bb4"]},
        # Bar 2-3: Ab
        {"bass": "Ab1", "pad": ["Ab2", "C3", "Eb3", "Ab3", "C4"], "arp": ["Ab3", "C4", "Eb4", "Ab4", "C5", "Eb5", "Bb4", "G4"]},
        # Bar 4-5: Eb
        {"bass": "Eb2", "pad": ["Eb2", "Bb2", "Eb3", "G3", "Bb3"], "arp": ["Eb4", "G4", "Bb4", "Eb5", "G5", "F5", "D5", "Bb4"]},
        # Bar 6-7: Bb / G7
        {"bass": "Bb1", "pad": ["Bb2", "D3", "F3", "Bb3", "D4"], "arp": ["D4", "F4", "Bb4", "D5", "F5", "D5", "B4", "G4"]},
    ]

    # Render Pad Swells
    for bar_pair in range(4):
        chord = chords[bar_pair]
        start_t = bar_pair * 2 * beats_per_bar * beat_dur
        dur = 2 * beats_per_bar * beat_dur
        start_sample = int(start_t * SAMPLE_RATE)
        chord_samples = int(dur * SAMPLE_RATE)

        for note_name in chord["pad"]:
            freq = note_to_freq(note_name)
            for i in range(chord_samples):
                idx = (start_sample + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / chord_samples
                # smooth swell envelope
                env = math.sin(math.pi * prog) ** 1.2
                # detuned lush saw pad
                s1 = osc_saw(t * (freq * 0.998))
                s2 = osc_saw(t * (freq * 1.002))
                sine = osc_sine(t * freq)
                sig = (s1 * 0.25 + s2 * 0.25 + sine * 0.5) * env * 0.08
                buffer[idx] += sig

    # Render Bassline (8th notes driving bass with punchy decay)
    eighth_dur = beat_dur / 2.0
    total_eighths = total_beats * 2
    for e in range(total_eighths):
        bar_pair = (e // 16) % 4
        chord = chords[bar_pair]
        b_root = note_to_freq(chord["bass"])
        # Octave pattern
        is_high = (e % 2 == 1)
        freq = b_root * (2.0 if is_high else 1.0)
        e_start = int(e * eighth_dur * SAMPLE_RATE)
        e_len = int(eighth_dur * SAMPLE_RATE)

        for i in range(e_len):
            idx = (e_start + i) % total_samples
            t = i / SAMPLE_RATE
            prog = i / e_len
            env = math.exp(-6.0 * prog)
            saw = osc_saw(t * freq)
            sub = osc_sine(t * (b_root))
            sig = (saw * 0.5 + sub * 0.5) * env * 0.18
            buffer[idx] += sig

    # Render Crystal Arpeggio Lead (16th notes)
    sixteenth_dur = beat_dur / 4.0
    total_sixteenths = total_beats * 4
    for s in range(total_sixteenths):
        bar_pair = (s // 32) % 4
        chord = chords[bar_pair]
        arp_pat = chord["arp"]
        note_name = arp_pat[s % len(arp_pat)]
        freq = note_to_freq(note_name)
        s_start = int(s * sixteenth_dur * SAMPLE_RATE)
        s_len = int(sixteenth_dur * 1.8 * SAMPLE_RATE)  # slight overlap with delay

        for i in range(s_len):
            idx = (s_start + i) % total_samples
            t = i / SAMPLE_RATE
            prog = i / (sixteenth_dur * 1.8 * SAMPLE_RATE)
            # Crystal bell attack
            env = math.exp(-7.5 * prog)
            # Bell harmonics
            f1 = osc_sine(t * freq)
            f2 = osc_sine(t * freq * 2.0) * 0.35
            f3 = osc_sine(t * freq * 4.0) * 0.15
            sig = (f1 + f2 + f3) * env * 0.14
            buffer[idx] += sig

    # Render Cosmic Drums (Kick, Hi-hat, Snare)
    for b in range(total_beats):
        b_start = int(b * beat_dur * SAMPLE_RATE)

        # 4-on-the-floor Trance Kick
        k_len = int(beat_dur * 0.35 * SAMPLE_RATE)
        for i in range(k_len):
            idx = (b_start + i) % total_samples
            t = i / SAMPLE_RATE
            prog = i / k_len
            k_freq = 130.0 * math.exp(-18.0 * t) + 40.0
            k_env = math.exp(-7.0 * prog)
            kick = math.sin(2.0 * math.pi * k_freq * t) * k_env * 0.28
            buffer[idx] += kick

        # Snare / Clap on beats 2 & 4
        if b % 2 == 1:
            sn_len = int(beat_dur * 0.40 * SAMPLE_RATE)
            for i in range(sn_len):
                idx = (b_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / sn_len
                noise = (math.sin(t * 84932.1) + math.sin(t * 12349.7)) * 0.5
                body = math.sin(2.0 * math.pi * 180.0 * math.exp(-12.0 * t) * t)
                sn_env = math.exp(-8.0 * prog)
                snare = (noise * 0.7 + body * 0.3) * sn_env * 0.16
                buffer[idx] += snare

        # 16th-note Shimmer Hi-hats
        for sub_h in range(4):
            h_start = b_start + int(sub_h * sixteenth_dur * SAMPLE_RATE)
            h_len = int(sixteenth_dur * 0.7 * SAMPLE_RATE)
            vol = 0.08 if sub_h == 2 else 0.04  # accented offbeat open hat
            for i in range(h_len):
                idx = (h_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / h_len
                noise = math.sin(t * 192841.3) * math.cos(t * 31415.9)
                h_env = math.exp(-18.0 * prog)
                buffer[idx] += noise * h_env * vol

    # Master Normalization
    peak = max(max(abs(s) for s in buffer), 1e-5)
    target = 0.85
    norm_factor = target / peak
    return [s * norm_factor for s in buffer]


def generate_zen_ambient() -> list[float]:
    bpm = 72.0
    beat_dur = 60.0 / bpm
    total_beats = 16  # 4 bars of slow ambient
    total_dur = total_beats * beat_dur  # ~13.33s
    total_samples = int(SAMPLE_RATE * total_dur)
    buffer = [0.0] * total_samples

    # Pentatonic chords: Fmaj9 -> Dm9 -> Bbmaj7 -> Csus4
    zen_sections = [
        {"root": "F2", "pad": ["F3", "A3", "C4", "E4", "G4"], "bells": ["C5", "E5", "G5", "A5", "C6"]},
        {"root": "D2", "pad": ["D3", "F3", "A3", "C4", "E4"], "bells": ["A4", "C5", "D5", "E5", "A5"]},
        {"root": "Bb1", "pad": ["Bb2", "D3", "F3", "A3", "D4"], "bells": ["F4", "A4", "Bb4", "D5", "F5"]},
        {"root": "C2", "pad": ["C3", "G3", "C4", "D4", "G4"], "bells": ["G4", "C5", "D5", "G5", "D6"]},
    ]

    sec_dur = total_dur / 4.0
    sec_samples = int(sec_dur * SAMPLE_RATE)

    # Warm ocean pad layers
    for s_idx, sec in enumerate(zen_sections):
        start_sample = int(s_idx * sec_dur * SAMPLE_RATE)

        # Deep warm sub drone
        drone_freq = note_to_freq(sec["root"])
        for i in range(sec_samples):
            idx = (start_sample + i) % total_samples
            t = i / SAMPLE_RATE
            prog = i / sec_samples
            env = math.sin(math.pi * prog) ** 1.5
            drone = osc_sine(t * drone_freq) * 0.16 * env
            buffer[idx] += drone

        # Lush chord pad
        for note_name in sec["pad"]:
            freq = note_to_freq(note_name)
            for i in range(sec_samples):
                idx = (start_sample + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / sec_samples
                env = math.sin(math.pi * prog) ** 1.3
                sine = osc_sine(t * freq)
                chorus = osc_sine(t * freq * 1.003) * 0.5 + osc_sine(t * freq * 0.997) * 0.5
                sig = (sine * 0.6 + chorus * 0.4) * env * 0.08
                buffer[idx] += sig

        # Crystal Singing Bowls / Meditation Bell Chimes
        for b_i, bell_note in enumerate(sec["bells"]):
            b_time = (b_i * 0.6 + 0.2) * sec_dur / 4.0
            b_sample = start_sample + int(b_time * SAMPLE_RATE)
            b_dur = sec_dur * 0.8
            b_len = int(b_dur * SAMPLE_RATE)
            freq = note_to_freq(bell_note)

            for i in range(b_len):
                idx = (b_sample + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / b_len
                env = math.exp(-3.5 * prog)
                # Metallic overtones for authentic Tibetan singing bowl / crystal chime
                f0 = osc_sine(t * freq)
                f1 = osc_sine(t * freq * 2.756) * 0.35 * math.exp(-5.0 * prog)
                f2 = osc_sine(t * freq * 5.404) * 0.15 * math.exp(-8.0 * prog)
                bell = (f0 + f1 + f2) * env * 0.14
                buffer[idx] += bell

    # Master Normalization
    peak = max(max(abs(s) for s in buffer), 1e-5)
    norm_factor = 0.82 / peak
    return [s * norm_factor for s in buffer]


def generate_electro_rush() -> list[float]:
    bpm = 136.0
    beat_dur = 60.0 / bpm
    total_beats = 32  # 8 bars at high tempo (~14.1s)
    total_dur = total_beats * beat_dur
    total_samples = int(SAMPLE_RATE * total_dur)
    buffer = [0.0] * total_samples

    # Chord structure: Am -> F -> C -> G (2 bars each)
    chords = [
        {"root": "A1", "lead": ["A4", "C5", "E5", "A5", "G5", "E5", "C5", "E5"]},
        {"root": "F1", "lead": ["F4", "A4", "C5", "F5", "E5", "C5", "A4", "C5"]},
        {"root": "C2", "lead": ["G4", "C5", "E5", "G5", "F5", "D5", "B4", "D5"]},
        {"root": "G1", "lead": ["G4", "B4", "D5", "G5", "F#5", "D5", "B4", "G4"]},
    ]

    sixteenth_dur = beat_dur / 4.0
    total_sixteenths = total_beats * 4

    # High-Energy Acid Bassline
    for s in range(total_sixteenths):
        bar_pair = (s // 32) % 4
        chord = chords[bar_pair]
        root_freq = note_to_freq(chord["root"])
        s_start = int(s * sixteenth_dur * SAMPLE_RATE)
        s_len = int(sixteenth_dur * SAMPLE_RATE)

        # 16th rolling synth bass
        octave_mult = 2.0 if (s % 4 in (1, 3)) else 1.0
        freq = root_freq * octave_mult

        for i in range(s_len):
            idx = (s_start + i) % total_samples
            t = i / SAMPLE_RATE
            prog = i / s_len
            env = math.exp(-7.0 * prog)
            saw = osc_saw(t * freq)
            sq = osc_square(t * freq, duty=0.35)
            bass = (saw * 0.6 + sq * 0.4) * env * 0.22
            buffer[idx] += bass

    # Energetic Lead Arpeggio
    for s in range(total_sixteenths):
        bar_pair = (s // 32) % 4
        chord = chords[bar_pair]
        pat = chord["lead"]
        note_name = pat[s % len(pat)]
        freq = note_to_freq(note_name)
        s_start = int(s * sixteenth_dur * SAMPLE_RATE)
        s_len = int(sixteenth_dur * 1.5 * SAMPLE_RATE)

        for i in range(s_len):
            idx = (s_start + i) % total_samples
            t = i / SAMPLE_RATE
            prog = i / (sixteenth_dur * 1.5 * SAMPLE_RATE)
            env = math.exp(-8.0 * prog)
            sq = osc_square(t * freq, duty=0.5)
            saw = osc_saw(t * freq * 1.002)
            lead = (sq * 0.6 + saw * 0.4) * env * 0.15
            buffer[idx] += lead

    # Hard-hitting dance drums
    for b in range(total_beats):
        b_start = int(b * beat_dur * SAMPLE_RATE)

        # Punchy Kick
        k_len = int(beat_dur * 0.30 * SAMPLE_RATE)
        for i in range(k_len):
            idx = (b_start + i) % total_samples
            t = i / SAMPLE_RATE
            prog = i / k_len
            k_freq = 150.0 * math.exp(-22.0 * t) + 45.0
            kick = math.sin(2.0 * math.pi * k_freq * t) * math.exp(-6.5 * prog) * 0.32
            buffer[idx] += kick

        # Snappy Snare
        if b % 2 == 1:
            sn_len = int(beat_dur * 0.35 * SAMPLE_RATE)
            for i in range(sn_len):
                idx = (b_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / sn_len
                noise = math.sin(t * 99281.3) * math.exp(-10.0 * prog)
                body = math.sin(2.0 * math.pi * 210.0 * t) * math.exp(-12.0 * prog)
                buffer[idx] += (noise * 0.75 + body * 0.25) * 0.20

        # Hi-hats
        for sub_h in range(4):
            h_start = b_start + int(sub_h * sixteenth_dur * SAMPLE_RATE)
            h_len = int(sixteenth_dur * 0.6 * SAMPLE_RATE)
            for i in range(h_len):
                idx = (h_start + i) % total_samples
                t = i / SAMPLE_RATE
                prog = i / h_len
                noise = math.sin(t * 184912.4) * math.exp(-20.0 * prog)
                buffer[idx] += noise * 0.06

    # Master Normalization
    peak = max(max(abs(s) for s in buffer), 1e-5)
    norm_factor = 0.85 / peak
    return [s * norm_factor for s in buffer]


def main() -> None:
    root = Path(__file__).resolve().parent.parent.parent
    music_dir = root / "assets" / "music"
    music_dir.mkdir(parents=True, exist_ok=True)

    print("Composing Bejeweled Cosmic Trance Suite...")
    trance = generate_cosmic_trance()
    write_wav(music_dir / "bejeweled_bgm.wav", trance)

    print("Composing Bejeweled Ethereal Zen Ambient...")
    zen = generate_zen_ambient()
    write_wav(music_dir / "bejeweled_zen.wav", zen)

    print("Composing Bejeweled Electro Rush Blitz...")
    blitz = generate_electro_rush()
    write_wav(music_dir / "bejeweled_blitz.wav", blitz)

    print("All soundtracks successfully generated!")


if __name__ == "__main__":
    main()
