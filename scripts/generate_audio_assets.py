import math
import os
import random
import struct
import wave

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
OUT = os.path.join(ROOT, 'assets', 'audio')
os.makedirs(OUT, exist_ok=True)
SR = 22050
DUR = 12


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


if __name__ == '__main__':
    make_rain()
    make_white_noise()
    make_soft_tone()
    print('generated', os.listdir(OUT))
