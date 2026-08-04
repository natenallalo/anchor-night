"""Generate calming looping WAV anchors for Anchor Night (offline, no copyrighted music)."""
import math
import os
import random
import struct
import wave

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
OUT = os.path.join(ROOT, 'assets', 'audio')
os.makedirs(OUT, exist_ok=True)
SR = 22050
DUR = 14


def write_wav(path, samples):
    with wave.open(path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b''.join(
            struct.pack('<h', max(-32767, min(32767, int(s * 32767))))
            for s in samples
        )
        w.writeframes(frames)


def soft_clip(x):
    return math.tanh(x)


def make_rain():
    rain = []
    state = 0.0
    for i in range(SR * DUR):
        n = random.uniform(-1, 1)
        state = 0.97 * state + 0.03 * n
        drip = 0.0
        if random.random() < 0.002:
            drip = random.uniform(0.2, 0.6)
        rain.append(0.22 * state + 0.08 * drip * math.sin(i * 0.05))
    write_wav(os.path.join(OUT, 'rain.wav'), rain)


def make_white_noise():
    wn = []
    b0 = b1 = b2 = 0.0
    for _ in range(SR * DUR):
        w = random.uniform(-1, 1)
        b0 = 0.99886 * b0 + w * 0.0555179
        b1 = 0.99332 * b1 + w * 0.0750759
        b2 = 0.96900 * b2 + w * 0.1538520
        pink = b0 + b1 + b2 + w * 0.076741
        wn.append(0.12 * pink)
    write_wav(os.path.join(OUT, 'white_noise.wav'), wn)


def make_soft_tone():
    tone = []
    for i in range(SR * DUR):
        t = i / SR
        s = 0.08 * math.sin(2 * math.pi * 110 * t) + 0.05 * math.sin(
            2 * math.pi * 164.8 * t
        )
        env = 0.55 + 0.45 * math.sin(2 * math.pi * t / 10)
        tone.append(s * env)
    write_wav(os.path.join(OUT, 'soft_tone.wav'), tone)


def make_ocean():
    samples = []
    phase = 0.0
    for i in range(SR * DUR):
        t = i / SR
        swell = 0.5 + 0.5 * math.sin(2 * math.pi * t / 7.5)
        noise = random.uniform(-1, 1)
        phase += 0.0008 + 0.0012 * swell
        surf = math.sin(phase * 40) * 0.15 * swell
        samples.append(soft_clip(0.14 * noise * swell + surf))
    write_wav(os.path.join(OUT, 'ocean.wav'), samples)


def make_forest():
    samples = []
    state = 0.0
    for i in range(SR * DUR):
        t = i / SR
        n = random.uniform(-1, 1)
        state = 0.995 * state + 0.005 * n
        rustle = 0.08 * state
        chirp = 0.0
        if random.random() < 0.0007:
            chirp = 0.12 * math.sin(2 * math.pi * random.uniform(1800, 3200) * t)
        samples.append(soft_clip(rustle + chirp * math.exp(-(i % (SR // 3)) / (SR * 0.08))))
    write_wav(os.path.join(OUT, 'forest.wav'), samples)


def make_stream():
    samples = []
    a = b = 0.0
    for i in range(SR * DUR):
        n = random.uniform(-1, 1)
        a = 0.98 * a + 0.02 * n
        b = 0.92 * b + 0.08 * n
        bubble = 0.0
        if random.random() < 0.004:
            bubble = random.uniform(0.05, 0.18) * math.sin(i * 0.11)
        samples.append(soft_clip(0.16 * a + 0.07 * b + bubble))
    write_wav(os.path.join(OUT, 'stream.wav'), samples)


def make_wind():
    samples = []
    state = 0.0
    for i in range(SR * DUR):
        t = i / SR
        n = random.uniform(-1, 1)
        state = 0.99 * state + 0.01 * n
        gust = 0.55 + 0.45 * math.sin(2 * math.pi * t / 9)
        samples.append(0.15 * state * gust)
    write_wav(os.path.join(OUT, 'wind.wav'), samples)


def make_brown_noise():
    samples = []
    last = 0.0
    for _ in range(SR * DUR):
        w = random.uniform(-1, 1)
        last = (last + 0.02 * w) * 0.996
        samples.append(0.22 * last)
    write_wav(os.path.join(OUT, 'brown_noise.wav'), samples)


def make_singing_bowl():
    samples = []
    freqs = [174.61, 220.0, 261.63]
    for i in range(SR * DUR):
        t = i / SR
        s = 0.0
        for f in freqs:
            beat = 0.5 + 0.5 * math.sin(2 * math.pi * 0.08 * t)
            s += (0.06 / len(freqs)) * math.sin(2 * math.pi * f * t) * beat
            s += (0.02 / len(freqs)) * math.sin(2 * math.pi * f * 2 * t) * beat
        samples.append(soft_clip(s))
    write_wav(os.path.join(OUT, 'singing_bowl.wav'), samples)


def make_ambient_pad():
    samples = []
    chords = [(130.81, 164.81, 196.0), (146.83, 174.61, 220.0)]
    for i in range(SR * DUR):
        t = i / SR
        chord = chords[int(t / 7) % 2]
        s = 0.0
        for f in chord:
            s += 0.045 * math.sin(2 * math.pi * f * t)
            s += 0.02 * math.sin(2 * math.pi * f * 0.5 * t)
        env = 0.65 + 0.35 * math.sin(2 * math.pi * t / 11)
        samples.append(soft_clip(s * env))
    write_wav(os.path.join(OUT, 'ambient_pad.wav'), samples)


def make_piano_lullaby():
    # Soft synthetic "piano-like" lullaby motif (not a copyrighted song).
    notes = [261.63, 293.66, 329.63, 293.66, 261.63, 246.94, 220.0, 246.94]
    note_len = SR * 1.2
    samples = []
    for i in range(SR * DUR):
        idx = int(i / note_len) % len(notes)
        local = i % int(note_len)
        t = local / SR
        f = notes[idx]
        env = math.exp(-t * 1.8) * (1 - math.exp(-t * 40))
        s = 0.12 * math.sin(2 * math.pi * f * t) * env
        s += 0.04 * math.sin(2 * math.pi * f * 2 * t) * env
        s += 0.015 * math.sin(2 * math.pi * f * 3 * t) * env
        samples.append(soft_clip(s))
    write_wav(os.path.join(OUT, 'piano_lullaby.wav'), samples)


def make_harp_drift():
    samples = []
    arpeggio = [196.0, 246.94, 293.66, 392.0, 293.66, 246.94]
    step = SR // 2
    for i in range(SR * DUR):
        idx = (i // step) % len(arpeggio)
        local = i % step
        t = local / SR
        f = arpeggio[idx]
        env = math.exp(-t * 2.4)
        s = 0.09 * math.sin(2 * math.pi * f * t) * env
        s += 0.03 * math.sin(2 * math.pi * f * 2.01 * t) * env
        samples.append(soft_clip(s))
    write_wav(os.path.join(OUT, 'harp_drift.wav'), samples)


def make_night_crickets():
    samples = []
    state = 0.0
    for i in range(SR * DUR):
        t = i / SR
        n = random.uniform(-1, 1)
        state = 0.997 * state + 0.003 * n
        chirp = 0.0
        # Sparse soft chirps
        if int(t * 2) % 5 == 0 and (i % (SR // 8)) < (SR // 40):
            chirp = 0.05 * math.sin(2 * math.pi * 4200 * t) * math.sin(
                2 * math.pi * 35 * t
            )
        samples.append(soft_clip(0.05 * state + chirp))
    write_wav(os.path.join(OUT, 'night_crickets.wav'), samples)


if __name__ == '__main__':
    makers = [
        make_rain,
        make_white_noise,
        make_soft_tone,
        make_ocean,
        make_forest,
        make_stream,
        make_wind,
        make_brown_noise,
        make_singing_bowl,
        make_ambient_pad,
        make_piano_lullaby,
        make_harp_drift,
        make_night_crickets,
    ]
    for fn in makers:
        fn()
        print('ok', fn.__name__)
    print('generated', sorted(os.listdir(OUT)))
