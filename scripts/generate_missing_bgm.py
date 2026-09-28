#!/usr/bin/env python3
"""Generate high-quality 44.1kHz 16-bit mono looping BGM for games missing soundtracks."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100

def midi_to_freq(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))

def generate_track(
    bpm: float,
    melody: list[int],
    bass: list[int],
    wave_type: str = "pulse",
    sub_octave: int = 24,
    total_beats: int = 32,
    lead_vol: float = 0.22,
    bass_vol: float = 0.28,
    decay: float = 12.0
) -> bytes:
    beat_dur = 60.0 / bpm
    total_samples = int(total_beats * beat_dur * SAMPLE_RATE)
    samples: list[float] = [0.0] * total_samples
    beat_samples = int(beat_dur * SAMPLE_RATE)

    # 16th-note steps
    sixteenth_samples = int(beat_samples / 4.0)
    total_steps = total_beats * 4

    for step in range(total_steps):
        start_idx = step * sixteenth_samples
        note = melody[step % len(melody)]
        if note > 0:
            freq = midi_to_freq(note)
            step_len = int(sixteenth_samples * 0.85)
            for s in range(step_len):
                idx = start_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * decay)
                phase = (t * freq) % 1.0

                if wave_type == "pulse":
                    val = (1.0 if phase < 0.3 else -0.4)
                elif wave_type == "saw":
                    val = (phase * 2.0 - 1.0)
                elif wave_type == "triangle":
                    val = (4.0 * abs(phase - 0.5) - 1.0)
                elif wave_type == "sine":
                    val = math.sin(2.0 * math.pi * phase)
                else:
                    val = (1.0 if phase < 0.5 else -1.0)

                samples[idx] += val * env * lead_vol

        # Bass line on 8th notes
        if step % 2 == 0:
            b_step = step // 2
            bn = bass[b_step % len(bass)]
            if bn > 0:
                bfreq = midi_to_freq(bn - sub_octave)
                blen = int(sixteenth_samples * 1.8)
                for s in range(blen):
                    idx = start_idx + s
                    if idx >= total_samples:
                        break
                    t = s / SAMPLE_RATE
                    env = math.exp(-t * 6.5)
                    phase = (t * bfreq) % 1.0
                    bval = (phase * 2.0 - 1.0) * 0.7 + math.sin(2.0 * math.pi * phase) * 0.3
                    samples[idx] += bval * env * bass_vol

        # Light hi-hat / percussion click on every 8th note, snare-like pop on backbeats
        if step % 4 == 2:  # snare / clap
            pop_len = int(SAMPLE_RATE * 0.04)
            for s in range(pop_len):
                idx = start_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 70.0)
                # pseudo-noise
                noise = (math.sin(s * 1337.1337) * 43758.5453) % 2.0 - 1.0
                samples[idx] += noise * env * 0.08
        elif step % 2 == 0:  # hi-hat
            hh_len = int(SAMPLE_RATE * 0.015)
            for s in range(hh_len):
                idx = start_idx + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-t * 150.0)
                noise = (math.sin(s * 2468.2468) * 12345.6789) % 2.0 - 1.0
                samples[idx] += noise * env * 0.04

    # Pack to 16-bit PCM with soft limiter
    out = bytearray()
    for val in samples:
        clamped = max(-0.95, min(0.95, val * 0.8))
        ival = int(clamped * 32767.0)
        out.extend(struct.pack("<h", ival))
    return bytes(out)

def save_wav(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(data)

def main() -> None:
    root = Path(__file__).resolve().parent.parent
    music_dir = root / "assets" / "music"
    music_dir.mkdir(parents=True, exist_ok=True)

    tracks: dict[str, dict] = {
        "blockdude": {
            "bpm": 115,
            "melody": [60, 64, 67, 71, 72, 71, 67, 64, 62, 65, 69, 72, 74, 72, 69, 65, 60, 64, 67, 72, 76, 72, 67, 64, 59, 62, 67, 71, 74, 71, 67, 62],
            "bass": [48, 48, 52, 52, 53, 53, 55, 55, 48, 48, 52, 52, 55, 55, 50, 50],
            "wave": "pulse", "sub": 12
        },
        "chimptest": {
            "bpm": 125,
            "melody": [72, 76, 79, 84, 79, 76, 84, 79, 74, 77, 81, 86, 81, 77, 86, 81, 76, 79, 83, 88, 83, 79, 88, 83, 72, 76, 79, 84, 88, 84, 79, 76],
            "bass": [60, 60, 67, 67, 62, 62, 69, 69, 64, 64, 71, 71, 60, 60, 67, 67],
            "wave": "triangle", "sub": 12
        },
        "clickarcade": {
            "bpm": 136,
            "melody": [65, 69, 72, 77, 72, 69, 77, 72, 67, 71, 74, 79, 74, 71, 79, 74, 69, 72, 76, 81, 76, 72, 81, 76, 67, 71, 74, 79, 74, 71, 67, 62],
            "bass": [53, 53, 60, 53, 55, 55, 62, 55, 57, 57, 64, 57, 55, 55, 62, 55],
            "wave": "saw", "sub": 12
        },
        "columns": {
            "bpm": 128,
            "melody": [69, 72, 76, 81, 79, 76, 74, 72, 69, 71, 72, 76, 74, 71, 68, 65, 69, 72, 76, 81, 84, 81, 79, 76, 74, 76, 77, 81, 79, 76, 74, 71],
            "bass": [57, 57, 64, 57, 53, 53, 60, 53, 57, 57, 64, 57, 52, 52, 59, 52],
            "wave": "pulse", "sub": 12
        },
        "cyberrunner": {
            "bpm": 140,
            "melody": [74, 74, 86, 74, 81, 74, 77, 74, 72, 72, 84, 72, 79, 72, 76, 72, 70, 70, 82, 70, 77, 70, 74, 70, 72, 72, 84, 72, 79, 72, 76, 72],
            "bass": [50, 50, 62, 50, 48, 48, 60, 48, 46, 46, 58, 46, 48, 48, 60, 48],
            "wave": "saw", "sub": 12
        },
        "dopewars": {
            "bpm": 96,
            "melody": [58, 61, 65, 70, 68, 65, 61, 58, 56, 60, 63, 68, 66, 63, 60, 56, 54, 58, 61, 66, 65, 61, 58, 54, 56, 60, 63, 68, 66, 63, 60, 58],
            "bass": [46, 46, 58, 46, 44, 44, 56, 44, 42, 42, 54, 42, 44, 44, 56, 44],
            "wave": "sine", "sub": 12
        },
        "downwell": {
            "bpm": 146,
            "melody": [60, 63, 67, 72, 70, 67, 65, 63, 58, 61, 65, 70, 68, 65, 63, 61, 56, 60, 63, 68, 67, 63, 60, 56, 58, 62, 65, 70, 68, 65, 62, 58],
            "bass": [48, 48, 60, 48, 46, 46, 58, 46, 44, 44, 56, 44, 46, 46, 58, 46],
            "wave": "saw", "sub": 12
        },
        "etchasketch": {
            "bpm": 108,
            "melody": [64, 67, 71, 76, 74, 71, 67, 64, 62, 66, 69, 74, 72, 69, 66, 62, 60, 64, 67, 72, 71, 67, 64, 60, 59, 63, 66, 71, 74, 71, 66, 62],
            "bass": [52, 52, 59, 52, 50, 50, 57, 50, 48, 48, 55, 48, 47, 47, 54, 47],
            "wave": "triangle", "sub": 12
        },
        "fire": {
            "bpm": 134,
            "melody": [67, 71, 74, 79, 74, 71, 67, 71, 69, 72, 76, 81, 76, 72, 69, 72, 71, 74, 78, 83, 78, 74, 71, 74, 72, 76, 79, 84, 79, 76, 72, 67],
            "bass": [55, 55, 62, 55, 57, 57, 64, 57, 59, 59, 66, 59, 60, 60, 67, 60],
            "wave": "pulse", "sub": 12
        },
        "game2048": {
            "bpm": 112,
            "melody": [60, 64, 67, 72, 74, 72, 67, 64, 65, 69, 72, 77, 76, 72, 69, 65, 67, 71, 74, 79, 77, 74, 71, 67, 65, 69, 72, 76, 74, 72, 69, 64],
            "bass": [48, 48, 55, 48, 53, 53, 60, 53, 55, 55, 62, 55, 53, 53, 60, 53],
            "wave": "sine", "sub": 12
        },
        "goldminer": {
            "bpm": 124,
            "melody": [62, 65, 69, 74, 72, 69, 65, 62, 67, 70, 74, 79, 77, 74, 70, 67, 60, 64, 67, 72, 71, 67, 64, 60, 62, 65, 69, 74, 72, 69, 65, 62],
            "bass": [50, 50, 57, 50, 55, 55, 62, 55, 48, 48, 55, 48, 50, 50, 57, 50],
            "wave": "pulse", "sub": 12
        },
        "jezzball": {
            "bpm": 126,
            "melody": [67, 70, 74, 79, 77, 74, 70, 67, 65, 68, 72, 77, 75, 72, 68, 65, 63, 67, 70, 75, 74, 70, 67, 63, 65, 68, 72, 77, 75, 72, 68, 65],
            "bass": [55, 55, 62, 55, 53, 53, 60, 53, 51, 51, 58, 51, 53, 53, 60, 53],
            "wave": "saw", "sub": 12
        },
        "klax": {
            "bpm": 132,
            "melody": [65, 68, 72, 77, 75, 72, 68, 65, 67, 70, 74, 79, 77, 74, 70, 67, 68, 72, 75, 80, 78, 75, 72, 68, 67, 70, 74, 79, 77, 74, 70, 67],
            "bass": [53, 53, 60, 53, 55, 55, 62, 55, 56, 56, 63, 56, 55, 55, 62, 55],
            "wave": "saw", "sub": 12
        },
        "lemmings": {
            "bpm": 120,
            "melody": [72, 72, 74, 76, 72, 76, 74, 71, 69, 71, 72, 74, 71, 74, 72, 67, 72, 72, 74, 76, 79, 76, 74, 72, 74, 74, 76, 77, 79, 77, 76, 74],
            "bass": [60, 60, 67, 60, 57, 57, 64, 57, 60, 60, 67, 60, 62, 62, 69, 62],
            "wave": "pulse", "sub": 12
        },
        "liarsdice": {
            "bpm": 106,
            "melody": [57, 60, 64, 69, 67, 64, 60, 57, 55, 59, 62, 67, 65, 62, 59, 55, 53, 57, 60, 65, 64, 60, 57, 53, 55, 59, 62, 67, 65, 62, 59, 57],
            "bass": [45, 45, 52, 45, 43, 43, 50, 43, 41, 41, 48, 41, 43, 43, 50, 43],
            "wave": "triangle", "sub": 12
        },
        "lightcycles": {
            "bpm": 138,
            "melody": [72, 75, 79, 84, 82, 79, 75, 72, 70, 74, 77, 82, 80, 77, 74, 70, 68, 72, 75, 80, 79, 75, 72, 68, 70, 74, 77, 82, 80, 77, 74, 72],
            "bass": [48, 48, 60, 48, 46, 46, 58, 46, 44, 44, 56, 44, 46, 46, 58, 46],
            "wave": "saw", "sub": 12
        },
        "marblemadness": {
            "bpm": 130,
            "melody": [62, 66, 69, 74, 73, 69, 66, 62, 64, 67, 71, 76, 74, 71, 67, 64, 65, 69, 72, 77, 76, 72, 69, 65, 67, 71, 74, 79, 78, 74, 71, 67],
            "bass": [50, 50, 57, 50, 52, 52, 59, 52, 53, 53, 60, 53, 55, 55, 62, 55],
            "wave": "pulse", "sub": 12
        },
        "mathmunchers": {
            "bpm": 125,
            "melody": [60, 64, 67, 72, 71, 67, 64, 60, 62, 65, 69, 74, 72, 69, 65, 62, 64, 67, 71, 76, 74, 71, 67, 64, 65, 69, 72, 77, 76, 72, 69, 65],
            "bass": [48, 48, 55, 48, 50, 50, 57, 50, 52, 52, 59, 52, 53, 53, 60, 53],
            "wave": "pulse", "sub": 12
        },
        "micromayhem": {
            "bpm": 150,
            "melody": [67, 70, 72, 75, 74, 72, 70, 67, 65, 68, 70, 73, 72, 70, 68, 65, 67, 70, 72, 75, 77, 75, 72, 70, 72, 75, 77, 82, 80, 77, 75, 72],
            "bass": [55, 55, 62, 55, 53, 53, 60, 53, 55, 55, 62, 55, 60, 60, 67, 60],
            "wave": "saw", "sub": 12
        },
        "nuclearthrone": {
            "bpm": 142,
            "melody": [58, 61, 65, 70, 69, 65, 61, 58, 56, 59, 63, 68, 67, 63, 59, 56, 54, 58, 61, 66, 65, 61, 58, 54, 56, 60, 63, 68, 67, 63, 60, 58],
            "bass": [46, 46, 58, 46, 44, 44, 56, 44, 42, 42, 54, 42, 44, 44, 56, 44],
            "wave": "saw", "sub": 12
        },
        "picross": {
            "bpm": 110,
            "melody": [64, 67, 71, 76, 74, 71, 67, 64, 62, 65, 69, 74, 72, 69, 65, 62, 60, 64, 67, 72, 71, 67, 64, 60, 59, 62, 67, 71, 74, 71, 67, 62],
            "bass": [52, 52, 59, 52, 50, 50, 57, 50, 48, 48, 55, 48, 47, 47, 54, 47],
            "wave": "triangle", "sub": 12
        },
        "puzzlefighter": {
            "bpm": 138,
            "melody": [60, 63, 67, 72, 75, 72, 67, 63, 62, 65, 68, 74, 77, 74, 68, 65, 63, 67, 70, 75, 79, 75, 70, 67, 65, 68, 72, 77, 80, 77, 72, 67],
            "bass": [48, 48, 55, 48, 50, 50, 57, 50, 51, 51, 58, 51, 53, 53, 60, 53],
            "wave": "saw", "sub": 12
        },
        "qbert": {
            "bpm": 122,
            "melody": [60, 63, 66, 69, 72, 69, 66, 63, 61, 64, 67, 70, 73, 70, 67, 64, 62, 65, 68, 71, 74, 71, 68, 65, 60, 63, 66, 69, 72, 69, 66, 63],
            "bass": [48, 48, 54, 48, 49, 49, 55, 49, 50, 50, 56, 50, 48, 48, 54, 48],
            "wave": "pulse", "sub": 12
        },
        "racer": {
            "bpm": 142,
            "melody": [69, 72, 76, 81, 83, 81, 76, 72, 67, 71, 74, 79, 81, 79, 74, 71, 65, 69, 72, 77, 79, 77, 72, 69, 67, 71, 74, 79, 81, 79, 74, 71],
            "bass": [57, 57, 64, 57, 55, 55, 62, 55, 53, 53, 60, 53, 55, 55, 62, 55],
            "wave": "saw", "sub": 12
        },
        "ragdoll": {
            "bpm": 114,
            "melody": [60, 64, 67, 72, 71, 67, 64, 60, 62, 65, 69, 74, 72, 69, 65, 62, 65, 69, 72, 77, 76, 72, 69, 65, 67, 71, 74, 79, 77, 74, 71, 67],
            "bass": [48, 48, 55, 48, 50, 50, 57, 50, 53, 53, 60, 53, 55, 55, 62, 55],
            "wave": "pulse", "sub": 12
        },
        "rain": {
            "bpm": 96,
            "melody": [60, 63, 67, 70, 72, 70, 67, 63, 58, 62, 65, 68, 70, 68, 65, 62, 56, 60, 63, 67, 68, 67, 63, 60, 58, 62, 65, 70, 72, 70, 65, 62],
            "bass": [48, 48, 55, 48, 46, 46, 53, 46, 44, 44, 51, 44, 46, 46, 53, 46],
            "wave": "sine", "sub": 12
        },
        "reversi": {
            "bpm": 108,
            "melody": [60, 64, 67, 71, 72, 71, 67, 64, 62, 65, 69, 72, 74, 72, 69, 65, 64, 67, 71, 74, 76, 74, 71, 67, 65, 69, 72, 76, 77, 76, 72, 67],
            "bass": [48, 48, 55, 48, 50, 50, 57, 50, 52, 52, 59, 52, 53, 53, 60, 53],
            "wave": "triangle", "sub": 12
        },
        "samegame": {
            "bpm": 116,
            "melody": [65, 69, 72, 77, 76, 72, 69, 65, 67, 71, 74, 79, 77, 74, 71, 67, 69, 72, 76, 81, 79, 76, 72, 69, 67, 71, 74, 79, 77, 74, 71, 67],
            "bass": [53, 53, 60, 53, 55, 55, 62, 55, 57, 57, 64, 57, 55, 55, 62, 55],
            "wave": "pulse", "sub": 12
        },
        "screensaver": {
            "bpm": 88,
            "melody": [60, 64, 67, 72, 76, 72, 67, 64, 62, 65, 69, 74, 77, 74, 69, 65, 64, 67, 71, 76, 79, 76, 71, 67, 65, 69, 72, 77, 81, 77, 72, 67],
            "bass": [48, 48, 55, 48, 50, 50, 57, 50, 52, 52, 59, 52, 53, 53, 60, 53],
            "wave": "sine", "sub": 12
        },
        "skifree": {
            "bpm": 130,
            "melody": [62, 66, 69, 74, 73, 69, 66, 62, 64, 67, 71, 76, 74, 71, 67, 64, 66, 69, 73, 78, 76, 73, 69, 66, 67, 71, 74, 79, 78, 74, 71, 67],
            "bass": [50, 50, 57, 50, 52, 52, 59, 52, 54, 54, 61, 54, 55, 55, 62, 55],
            "wave": "pulse", "sub": 12
        },
        "tamagotchi": {
            "bpm": 120,
            "melody": [72, 76, 79, 84, 83, 79, 76, 72, 74, 77, 81, 86, 84, 81, 77, 74, 76, 79, 83, 88, 86, 83, 79, 76, 77, 81, 84, 89, 88, 84, 81, 77],
            "bass": [60, 60, 67, 60, 62, 62, 69, 62, 64, 64, 71, 64, 65, 65, 72, 65],
            "wave": "pulse", "sub": 12
        },
        "towerfall": {
            "bpm": 134,
            "melody": [62, 65, 69, 74, 72, 69, 65, 62, 60, 63, 67, 72, 70, 67, 63, 60, 58, 62, 65, 70, 69, 65, 62, 58, 60, 64, 67, 72, 70, 67, 64, 62],
            "bass": [50, 50, 57, 50, 48, 48, 55, 48, 46, 46, 53, 46, 48, 48, 55, 48],
            "wave": "saw", "sub": 12
        },
        "trivia": {
            "bpm": 118,
            "melody": [60, 63, 67, 72, 70, 67, 63, 60, 62, 65, 68, 74, 72, 68, 65, 62, 63, 67, 70, 75, 74, 70, 67, 63, 65, 68, 72, 77, 75, 72, 68, 65],
            "bass": [48, 48, 55, 48, 50, 50, 57, 50, 51, 51, 58, 51, 53, 53, 60, 53],
            "wave": "triangle", "sub": 12
        },
        "typing": {
            "bpm": 128,
            "melody": [69, 72, 76, 81, 79, 76, 72, 69, 67, 71, 74, 79, 77, 74, 71, 67, 65, 69, 72, 77, 76, 72, 69, 65, 67, 71, 74, 79, 77, 74, 71, 67],
            "bass": [57, 57, 64, 57, 55, 55, 62, 55, 53, 53, 60, 53, 55, 55, 62, 55],
            "wave": "saw", "sub": 12
        },
        "war": {
            "bpm": 122,
            "melody": [60, 60, 64, 67, 72, 67, 64, 60, 62, 62, 65, 69, 74, 69, 65, 62, 64, 64, 67, 71, 76, 71, 67, 64, 65, 65, 69, 72, 77, 72, 69, 65],
            "bass": [48, 48, 55, 48, 50, 50, 57, 50, 52, 52, 59, 52, 53, 53, 60, 53],
            "wave": "pulse", "sub": 12
        },
    }

    print(f"Generating {len(tracks)} missing BGM tracks...")
    for game, cfg in tracks.items():
        data = generate_track(
            bpm=cfg["bpm"],
            melody=cfg["melody"],
            bass=cfg["bass"],
            wave_type=cfg.get("wave", "pulse"),
            sub_octave=cfg.get("sub", 12),
            total_beats=64, # ~30 seconds loop
        )
        wav_name = f"{game}_bgm.wav"
        out_file = music_dir / wav_name
        save_wav(out_file, data)
        print(f"  ✓ {wav_name} ({len(data)} bytes, ~{len(data)/SAMPLE_RATE/2:.1f}s)")

if __name__ == "__main__":
    main()
