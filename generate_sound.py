#!/usr/bin/env python3
"""
DragonToast Sound Synthesis Script
===================================

Generates short notification sounds for the DragonToast WoW addon.
All sounds are dragon-themed with distinct character, designed to be
satisfying loot notification chimes at ~0.3-0.5 seconds.

Sound Design Overview:
    DragonToast.ogg  - Bright bell chime with subtle dragon rumble and fire sparkle.
                       The default, balanced between clarity and atmosphere.
    DragonRoar.ogg   - Bold, aggressive variant with heavier low-frequency growl
                       and a punchy metallic hit. For players who want impact.
    EmberChime.ogg   - Soft, warm, crystalline chime with a gentle pad underneath.
                       Quieter and lingering, for players who prefer subtlety.
    TreasureDrop.ogg - Two quick ascending metallic tones (coin clink feel) with
                       bright harmonics and a shimmer tail. Loot-acquisition reward.

Technical specs:
    - 44100 Hz sample rate, mono, float32
    - OGG Vorbis output
    - Normalized to -1 dB headroom (peak * 0.891)
    - 5 ms attack ramp, 10 ms fade-out to avoid clicks
    - Fixed random seed for reproducibility

Usage:
    python3 generate_sound.py

Dependencies:
    pip install numpy soundfile
"""

import os
import numpy as np
import soundfile as sf

SAMPLE_RATE = 44100
RANDOM_SEED = 42
OUTPUT_DIR = os.path.join("DragonToast", "Sounds")
HEADROOM_DB = -1.0
HEADROOM_LINEAR = 10 ** (HEADROOM_DB / 20)  # ~0.891

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

def time_array(duration_s):
    """Create a time axis array for the given duration."""
    return np.linspace(0, duration_s, int(SAMPLE_RATE * duration_s), endpoint=False)


def sine_wave(freq_hz, duration_s, phase=0.0):
    """Generate a pure sine wave."""
    t = time_array(duration_s)
    return np.sin(2 * np.pi * freq_hz * t + phase)


def exponential_decay(duration_s, decay_rate):
    """Generate an exponential decay envelope (1.0 -> ~0).

    Higher decay_rate = faster decay.
    """
    t = time_array(duration_s)
    return np.exp(-decay_rate * t)


def linear_ramp(duration_s, start=0.0, end=1.0):
    """Generate a linear ramp from start to end over duration."""
    n_samples = int(SAMPLE_RATE * duration_s)
    return np.linspace(start, end, n_samples)


def apply_attack_ramp(signal, attack_ms=5.0):
    """Apply a short linear attack ramp to avoid initial clicks."""
    attack_samples = int(SAMPLE_RATE * attack_ms / 1000)
    if attack_samples <= 0 or attack_samples >= len(signal):
        return signal
    ramp = np.linspace(0.0, 1.0, attack_samples)
    signal = signal.copy()
    signal[:attack_samples] *= ramp
    return signal


def apply_fadeout(signal, fadeout_ms=10.0):
    """Apply a short linear fade-out to avoid end-clicks."""
    fadeout_samples = int(SAMPLE_RATE * fadeout_ms / 1000)
    if fadeout_samples <= 0 or fadeout_samples >= len(signal):
        return signal
    ramp = np.linspace(1.0, 0.0, fadeout_samples)
    signal = signal.copy()
    signal[-fadeout_samples:] *= ramp
    return signal


def bandpass_noise(duration_s, low_hz, high_hz, rng):
    """Generate band-limited noise using spectral filtering.

    Creates white noise, FFTs it, zeros out frequencies outside the
    band, then IFFTs back. Simple but effective for short sounds.
    """
    n_samples = int(SAMPLE_RATE * duration_s)
    noise = rng.standard_normal(n_samples)

    spectrum = np.fft.rfft(noise)
    freqs = np.fft.rfftfreq(n_samples, d=1.0 / SAMPLE_RATE)

    mask = (freqs >= low_hz) & (freqs <= high_hz)
    spectrum[~mask] = 0.0

    filtered = np.fft.irfft(spectrum, n=n_samples)
    # Normalize filtered noise to unit peak
    peak = np.max(np.abs(filtered))
    if peak > 0:
        filtered /= peak
    return filtered


def normalize_to_headroom(signal):
    """Normalize signal so peak equals HEADROOM_LINEAR (~-1 dB)."""
    peak = np.max(np.abs(signal))
    if peak == 0:
        return signal
    return signal * (HEADROOM_LINEAR / peak)


def finalize(signal):
    """Apply attack ramp, fade-out, and normalize. Common final step."""
    signal = apply_attack_ramp(signal, attack_ms=5.0)
    signal = apply_fadeout(signal, fadeout_ms=10.0)
    return normalize_to_headroom(signal)


def pad_to_length(signal, target_samples):
    """Zero-pad or truncate signal to exact target length."""
    if len(signal) >= target_samples:
        return signal[:target_samples]
    return np.concatenate([signal, np.zeros(target_samples - len(signal))])


def write_ogg(filename, signal):
    """Write a mono float32 signal to OGG Vorbis."""
    filepath = os.path.join(OUTPUT_DIR, filename)
    sf.write(filepath, signal.astype(np.float32), SAMPLE_RATE, format="OGG", subtype="VORBIS")
    return filepath


# ---------------------------------------------------------------------------
# Sound generators
# ---------------------------------------------------------------------------

def generate_dragon_toast(rng):
    """DragonToast.ogg - Bright bell chime with dragon rumble and fire sparkle.

    Layers:
        1. Bell chime: A5 (880Hz) + E6 (1320Hz) fifth + A6 (1760Hz) shimmer
        2. Dragon rumble: 90-110Hz low sine blend + filtered noise growl
        3. Fire sparkle: 4-8kHz noise burst with ~8ms exponential decay
    """
    duration = 0.4
    n_samples = int(SAMPLE_RATE * duration)

    # Layer 1: Bell chime (harmonic fifth + octave shimmer)
    decay_bell = exponential_decay(duration, decay_rate=8.0)
    bell_a5 = sine_wave(880, duration) * 0.5
    bell_e6 = sine_wave(1320, duration) * 0.35
    bell_a6 = sine_wave(1760, duration) * 0.2
    bell = (bell_a5 + bell_e6 + bell_a6) * decay_bell

    # Layer 2: Dragon rumble (subtle low-frequency blend)
    decay_rumble = exponential_decay(duration, decay_rate=5.0)
    rumble_low = sine_wave(90, duration) * 0.15
    rumble_mid = sine_wave(110, duration) * 0.10
    growl_noise = bandpass_noise(duration, 80, 200, rng) * 0.06
    rumble = (rumble_low + rumble_mid + growl_noise) * decay_rumble

    # Layer 3: Fire sparkle attack transient (very short noise burst)
    sparkle_duration = 0.04  # 40ms window, but decays in ~8ms
    sparkle_decay = exponential_decay(sparkle_duration, decay_rate=120.0)
    sparkle_noise = bandpass_noise(sparkle_duration, 4000, 8000, rng) * 0.25
    sparkle = sparkle_noise * sparkle_decay
    sparkle = pad_to_length(sparkle, n_samples)

    signal = bell + rumble + sparkle
    return finalize(signal)


def generate_dragon_roar(rng):
    """DragonRoar.ogg - Bold, aggressive variant with heavy dragon growl.

    Layers:
        1. Dragon growl: 60-100Hz heavy sine blend with downward pitch sweep
        2. Mid-range rumble body: slight pitch sweep downward for drama
        3. Sharp metallic hit: high-freq very short transient
    """
    duration = 0.35
    n_samples = int(SAMPLE_RATE * duration)
    t = time_array(duration)

    # Layer 1: Heavy dragon growl with downward pitch sweep (100Hz -> 60Hz)
    growl_freq = 100 - 40 * (t / duration)  # sweep down
    growl_phase = 2 * np.pi * np.cumsum(growl_freq) / SAMPLE_RATE
    growl_sine = np.sin(growl_phase) * 0.35
    growl_noise = bandpass_noise(duration, 50, 150, rng) * 0.15
    decay_growl = exponential_decay(duration, decay_rate=5.0)
    growl = (growl_sine + growl_noise) * decay_growl

    # Layer 2: Mid-range rumble body (200Hz -> 150Hz sweep)
    mid_freq = 200 - 50 * (t / duration)
    mid_phase = 2 * np.pi * np.cumsum(mid_freq) / SAMPLE_RATE
    mid_rumble = np.sin(mid_phase) * 0.20
    decay_mid = exponential_decay(duration, decay_rate=7.0)
    mid_rumble *= decay_mid

    # Layer 3: Sharp metallic hit transient
    hit_duration = 0.02  # 20ms
    hit_decay = exponential_decay(hit_duration, decay_rate=200.0)
    hit_tone = sine_wave(2500, hit_duration) * 0.3
    hit_harmonic = sine_wave(5000, hit_duration) * 0.15
    hit_noise = bandpass_noise(hit_duration, 3000, 8000, rng) * 0.12
    hit = (hit_tone + hit_harmonic + hit_noise) * hit_decay
    hit = pad_to_length(hit, n_samples)

    # Punchier envelope: faster overall attack, snappier shape
    punch_env = exponential_decay(duration, decay_rate=4.0)
    signal = (growl + mid_rumble + hit) * punch_env
    # Re-add some hit on top so it cuts through the envelope
    signal += hit * 0.5

    return finalize(signal)


def generate_ember_chime(rng):
    """EmberChime.ogg - Soft, warm, crystalline chime with gentle pad.

    Layers:
        1. Crystalline chime: C6 (~1047Hz) + G6 (~1568Hz) gentle fifth
        2. Warm pad: 200-300Hz soft sine blend
        3. Delicate high sparkle: lighter than DragonToast's fire sparkle
    """
    duration = 0.45
    n_samples = int(SAMPLE_RATE * duration)

    # Layer 1: Crystalline chime (slower decay for lingering warmth)
    decay_chime = exponential_decay(duration, decay_rate=5.5)
    chime_c6 = sine_wave(1047, duration) * 0.40
    chime_g6 = sine_wave(1568, duration) * 0.30
    # Add a soft sub-harmonic for warmth
    chime_c5 = sine_wave(523.5, duration) * 0.10
    chime = (chime_c6 + chime_g6 + chime_c5) * decay_chime

    # Layer 2: Warm pad (very gentle low sine blend)
    decay_pad = exponential_decay(duration, decay_rate=4.0)
    pad_low = sine_wave(220, duration) * 0.08
    pad_mid = sine_wave(280, duration) * 0.06
    pad = (pad_low + pad_mid) * decay_pad

    # Layer 3: Delicate high sparkle (softer, longer than DragonToast's burst)
    sparkle_duration = 0.06
    sparkle_decay = exponential_decay(sparkle_duration, decay_rate=60.0)
    sparkle_noise = bandpass_noise(sparkle_duration, 5000, 10000, rng) * 0.10
    sparkle = sparkle_noise * sparkle_decay
    sparkle = pad_to_length(sparkle, n_samples)

    # Overall softer character - scale down before normalize
    signal = (chime + pad + sparkle) * 0.7
    return finalize(signal)


def generate_treasure_drop(rng):
    """TreasureDrop.ogg - Two ascending metallic tones with shimmer tail.

    Layers:
        1. First metallic tone (lower): rich harmonics, starts at t=0
        2. Second metallic tone (higher): ~40ms delayed, ascending reward feel
        3. Bright shimmer tail: high-frequency sparkle after the tones
    """
    duration = 0.4
    n_samples = int(SAMPLE_RATE * duration)

    # Tone parameters: metallic = fundamental + many inharmonic partials
    def metallic_tone(base_freq, tone_duration):
        """Create a metallic-sounding tone with upper partials."""
        t_tone = time_array(tone_duration)
        # Fundamental + partials at non-integer ratios for metallic character
        fundamental = np.sin(2 * np.pi * base_freq * t_tone) * 0.30
        partial_2 = np.sin(2 * np.pi * base_freq * 2.3 * t_tone) * 0.18
        partial_3 = np.sin(2 * np.pi * base_freq * 3.1 * t_tone) * 0.12
        partial_4 = np.sin(2 * np.pi * base_freq * 4.7 * t_tone) * 0.08
        partial_5 = np.sin(2 * np.pi * base_freq * 6.2 * t_tone) * 0.05
        tone = fundamental + partial_2 + partial_3 + partial_4 + partial_5
        decay = exponential_decay(tone_duration, decay_rate=15.0)
        return tone * decay

    # Tone 1: lower pitch, starts at t=0
    tone1_freq = 1200
    tone1_dur = 0.15
    tone1 = metallic_tone(tone1_freq, tone1_dur)
    tone1 = pad_to_length(tone1, n_samples)

    # Tone 2: higher pitch, starts ~40ms later (ascending = rewarding)
    tone2_freq = 1600
    tone2_dur = 0.15
    tone2 = metallic_tone(tone2_freq, tone2_dur)
    delay_samples = int(SAMPLE_RATE * 0.04)  # 40ms delay
    tone2_padded = np.concatenate([np.zeros(delay_samples), tone2])
    tone2_padded = pad_to_length(tone2_padded, n_samples)

    # Layer 3: Shimmer tail starting after both tones (~80ms in)
    shimmer_start_ms = 80
    shimmer_start_samples = int(SAMPLE_RATE * shimmer_start_ms / 1000)
    shimmer_duration = duration - shimmer_start_ms / 1000
    shimmer_decay = exponential_decay(shimmer_duration, decay_rate=10.0)
    shimmer_noise = bandpass_noise(shimmer_duration, 6000, 12000, rng) * 0.12
    shimmer_high = sine_wave(8000, shimmer_duration) * 0.05
    shimmer = (shimmer_noise + shimmer_high) * shimmer_decay
    shimmer_full = np.concatenate([np.zeros(shimmer_start_samples), shimmer])
    shimmer_full = pad_to_length(shimmer_full, n_samples)

    signal = tone1 + tone2_padded + shimmer_full
    return finalize(signal)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    """Generate all four DragonToast sound variants."""
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    rng = np.random.default_rng(RANDOM_SEED)

    sounds = [
        ("DragonToast.ogg", generate_dragon_toast),
        ("DragonRoar.ogg", generate_dragon_roar),
        ("EmberChime.ogg", generate_ember_chime),
        ("TreasureDrop.ogg", generate_treasure_drop),
    ]

    print(f"Generating {len(sounds)} sounds to {OUTPUT_DIR}/")
    print(f"  Sample rate: {SAMPLE_RATE} Hz | Format: OGG Vorbis | Headroom: {HEADROOM_DB} dB")
    print()

    for filename, generator_fn in sounds:
        signal = generator_fn(rng)
        filepath = write_ogg(filename, signal)
        file_size = os.path.getsize(filepath)
        duration_ms = len(signal) / SAMPLE_RATE * 1000
        print(f"  {filename:<20s}  {duration_ms:6.0f}ms  {file_size:>6,} bytes  -> {filepath}")

    print()
    print("Done.")


if __name__ == "__main__":
    main()
