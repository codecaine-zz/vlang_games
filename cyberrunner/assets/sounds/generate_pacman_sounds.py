#!/usr/bin/env python3
"""Generate authentic 1980 Namco Pac-Man arcade sound effects and audio tracks."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    out = bytearray()
    for s in samples:
        clamped = max(-1.0, min(1.0, s))
        ival = int(clamped * 32767.0)
        out.extend(struct.pack("<h", ival))
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(bytes(out))


def namco_wave(phase: float, wave_type: int = 0) -> float:
    """Simulate Namco custom 4-bit wavetable synthesis."""
    p = phase % 1.0
    if wave_type == 0:
        # Pac-man pulse-saw wave
        if p < 0.5:
            return 2.0 * p - 0.5 + 0.2 * math.sin(2.0 * math.pi * p)
        else:
            return 1.5 - 2.0 * p + 0.2 * math.sin(2.0 * math.pi * p)
    elif wave_type == 1:
        # Pac-man square wave
        return 0.85 if p < 0.5 else -0.85
    else:
        # Rounded triangle
        return math.sin(2.0 * math.pi * p) + 0.25 * math.sin(6.0 * math.pi * p)


def gen_waka() -> list[float]:
    """Authentic arcade Waka-Waka munch sound (high waka + low waka pair)."""
    dur = 0.14
    count = int(dur * SAMPLE_RATE)
    samples = [0.0] * count
    half = count // 2

    # High munch (0.00s -> 0.07s): sweeps 440Hz -> 680Hz
    phase = 0.0
    for i in range(half):
        t = i / SAMPLE_RATE
        norm = i / half
        freq = 430.0 + 260.0 * (norm ** 1.3)
        phase += freq / SAMPLE_RATE
        env = math.sin(math.pi * norm) ** 0.8
        samples[i] = namco_wave(phase, 0) * env * 0.85

    # Low munch (0.07s -> 0.14s): sweeps 310Hz -> 510Hz
    phase = 0.0
    for i in range(half, count):
        local_i = i - half
        t = local_i / SAMPLE_RATE
        norm = local_i / half
        freq = 300.0 + 220.0 * (norm ** 1.3)
        phase += freq / SAMPLE_RATE
        env = math.sin(math.pi * norm) ** 0.8
        samples[i] = namco_wave(phase, 0) * env * 0.85

    return samples


def gen_power() -> list[float]:
    """Authentic power pellet siren / energizer warble."""
    dur = 0.35
    count = int(dur * SAMPLE_RATE)
    samples = []
    phase = 0.0
    for i in range(count):
        t = i / SAMPLE_RATE
        # Rapid pitch modulation between 180Hz and 320Hz at 12Hz
        mod = 0.5 + 0.5 * math.sin(2.0 * math.pi * 12.0 * t)
        freq = 180.0 + 140.0 * mod
        phase += freq / SAMPLE_RATE
        env = min(1.0, t * 20.0) * min(1.0, (dur - t) * 15.0)
        s = namco_wave(phase, 0) * 0.8
        samples.append(s * env)
    return samples


def gen_fruit() -> list[float]:
    """Authentic fruit eat chimes (ascending 4-note bell bounce)."""
    dur = 0.28
    count = int(dur * SAMPLE_RATE)
    samples = [0.0] * count
    freqs = [659.25, 783.99, 987.77, 1318.51]  # E5, G5, B5, E6
    step = count // len(freqs)

    for idx, freq in enumerate(freqs):
        st = idx * step
        phase = 0.0
        for s in range(int(0.12 * SAMPLE_RATE)):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            phase += freq / SAMPLE_RATE
            env = math.exp(-t * 22.0)
            tone = (math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)) * env * 0.85
            samples[i] += tone

    return samples


def gen_ghost() -> list[float]:
    """Authentic eat ghost ascending whoop sweep (260Hz -> 1350Hz)."""
    dur = 0.42
    count = int(dur * SAMPLE_RATE)
    samples = []
    phase = 0.0
    for i in range(count):
        t = i / SAMPLE_RATE
        norm = t / dur
        freq = 240.0 + 1150.0 * (norm ** 1.8)
        # Vibrato warble
        freq += 35.0 * math.sin(2.0 * math.pi * 32.0 * t)
        phase += freq / SAMPLE_RATE
        env = math.exp(-t * 3.0)
        samples.append(namco_wave(phase, 1) * env * 0.88)
    return samples


def gen_death() -> list[float]:
    """Authentic original Pac-Man death sound (descending modulated wah-wah)."""
    dur = 1.35
    count = int(dur * SAMPLE_RATE)
    samples = []
    phase = 0.0
    for i in range(count):
        t = i / SAMPLE_RATE
        norm = t / dur
        # Descending frequency from 920Hz down to 95Hz
        base_freq = 920.0 * ((1.0 - norm) ** 1.4) + 95.0
        # Rapid 16Hz warble modulation
        warble = math.sin(2.0 * math.pi * 16.0 * t)
        freq = max(60.0, base_freq + 60.0 * warble)
        phase += freq / SAMPLE_RATE

        # Segmented wah-wah envelope
        wah_env = (0.6 + 0.4 * math.sin(2.0 * math.pi * 16.0 * t)) * (1.0 - norm * 0.7)
        s = namco_wave(phase, 0) * wah_env * 0.85

        # Final pop splat at the end (t > 1.25s)
        if t > 1.20:
            fade_norm = (t - 1.20) / 0.15
            pop_phase = 2.0 * math.pi * 70.0 * (t - 1.20)
            pop = math.sin(pop_phase) * math.exp(-fade_norm * 8.0) * 0.9
            s = pop

        samples.append(s)
    return samples


def gen_intro() -> list[float]:
    """Authentic 1980 Namco Pac-Man Ready / Game Start Fanfare."""
    bpm = 135
    beat = 60.0 / bpm
    sixteenth = beat / 4.0

    # Midi note numbers for authentic Pac-Man theme
    notes = [
        (71, sixteenth), (83, sixteenth), (78, sixteenth), (75, sixteenth), (83, sixteenth), (78, sixteenth), (75, sixteenth * 1.8),
        (72, sixteenth), (84, sixteenth), (79, sixteenth), (76, sixteenth), (84, sixteenth), (79, sixteenth), (76, sixteenth * 1.8),
        (71, sixteenth), (83, sixteenth), (78, sixteenth), (75, sixteenth), (83, sixteenth), (78, sixteenth), (75, sixteenth * 1.8),
        (75, sixteenth), (76, sixteenth), (77, sixteenth), (77, sixteenth), (78, sixteenth), (79, sixteenth), (80, sixteenth), (81, sixteenth), (82, sixteenth), (83, sixteenth * 3.0),
    ]

    total_dur = sum(dur for _, dur in notes) + 0.15
    count = int(total_dur * SAMPLE_RATE)
    samples = [0.0] * count

    cur_time = 0.0
    for note_num, dur in notes:
        freq = 440.0 * (2.0 ** ((note_num - 69) / 12.0))
        st = int(cur_time * SAMPLE_RATE)
        note_samples = int(dur * SAMPLE_RATE)
        phase = 0.0

        for s in range(note_samples):
            i = st + s
            if i >= count:
                break
            t = s / SAMPLE_RATE
            phase += freq / SAMPLE_RATE
            env = math.exp(-t * 9.0)
            tone = namco_wave(phase, 0) * env * 0.75
            samples[i] += tone

        cur_time += dur

    return samples


def main() -> None:
    out_dir = Path(__file__).resolve().parent
    sounds = {
        "pacman_waka.wav": gen_waka(),
        "pacman_power.wav": gen_power(),
        "pacman_fruit.wav": gen_fruit(),
        "pacman_ghost.wav": gen_ghost(),
        "pacman_death.wav": gen_death(),
        "pacman_intro.wav": gen_intro(),
    }
    for fname, smp in sounds.items():
        p = out_dir / fname
        write_wav(p, smp)
        print(f"Generated {p} ({len(smp)} samples)")


if __name__ == "__main__":
    main()
