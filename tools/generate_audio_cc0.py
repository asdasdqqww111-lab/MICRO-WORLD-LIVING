#!/usr/bin/env python3
"""
Deterministic original CC0 procedural audio generator for MICRO WORLD: LIVING.
Produces lightweight mono 22050 Hz 16-bit PCM .wav SFX and seamless loops
with zero third-party copyright dependencies.
"""
import math
import os
import random
import struct
import wave

SR = 22050


def write_wav(path: str, samples: list[float]) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    peak = max((abs(s) for s in samples), default=1.0)
    scale = 0.88 / max(peak, 1e-4)
    raw = bytearray()
    for s in samples:
        v = max(-32767, min(32767, int(s * scale * 32767.0)))
        raw += struct.pack("<h", v)
    with wave.open(path, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(bytes(raw))


def env_adsr(t: float, dur: float, a: float = 0.01, d: float = 0.08, s: float = 0.4, r: float = 0.1) -> float:
    if t < 0.0 or t > dur:
        return 0.0
    if t < a:
        return t / max(a, 1e-5)
    if t < a + d:
        return 1.0 - (1.0 - s) * ((t - a) / max(d, 1e-5))
    if t < dur - r:
        return s
    return s * max(0.0, (dur - t) / max(r, 1e-5))


def karplus_pluck(freq: float, dur: float, seed: int = 1, brightness: float = 0.496) -> list[float]:
    rng = random.Random(seed)
    n = int(SR * dur)
    delay = max(2, int(SR / freq))
    buf = [rng.uniform(-1.0, 1.0) for _ in range(delay)]
    out = []
    idx = 0
    for i in range(n):
        out.append(buf[idx])
        nxt = (idx + 1) % delay
        buf[idx] = brightness * (buf[idx] + buf[nxt])
        idx = nxt
    return out


def gen_sfx() -> None:
    rng = random.Random(20261112)
    snd = "assets/sounds"

    # 1. Sword swing (band-swept filtered noise)
    n = int(SR * 0.24)
    s = []
    lp = 0.0
    for i in range(n):
        t = i / SR
        alpha = 0.12 + 0.55 * math.sin(math.pi * t / 0.24)
        lp = lp + alpha * (rng.uniform(-1, 1) - lp)
        s.append(lp * math.sin(math.pi * t / 0.24) ** 1.4)
    write_wav(f"{snd}/sword_swing.wav", s)

    # 2. Heavy swing (deeper + resonant)
    n = int(SR * 0.38)
    s = []
    lp = 0.0
    for i in range(n):
        t = i / SR
        alpha = 0.08 + 0.35 * math.sin(math.pi * t / 0.38)
        lp = lp + alpha * (rng.uniform(-1, 1) - lp)
        sub = 0.5 * math.sin(2 * math.pi * (140 - 70 * (t / 0.38)) * t)
        s.append((lp + sub) * math.sin(math.pi * t / 0.38) ** 1.2)
    write_wav(f"{snd}/heavy_swing.wav", s)

    # 3. Hit impact (punchy thud + metallic transient)
    n = int(SR * 0.22)
    s = []
    for i in range(n):
        t = i / SR
        e = math.exp(-t * 22.0)
        body = math.sin(2 * math.pi * (150 * math.exp(-t * 14.0) + 48.0) * t)
        clang = 0.35 * math.sin(2 * math.pi * 890 * t) * math.exp(-t * 38.0)
        grit = 0.35 * rng.uniform(-1, 1) * math.exp(-t * 45.0)
        s.append((body + clang + grit) * e)
    write_wav(f"{snd}/hit_impact.wav", s)

    # 4. Shield block (metallic ring)
    n = int(SR * 0.32)
    s = []
    for i in range(n):
        t = i / SR
        ring = (
            0.6 * math.sin(2 * math.pi * 620 * t)
            + 0.4 * math.sin(2 * math.pi * 985 * t)
            + 0.3 * math.sin(2 * math.pi * 1470 * t)
        ) * math.exp(-t * 14.0)
        thud = 0.5 * rng.uniform(-1, 1) * math.exp(-t * 50.0)
        s.append(ring + thud)
    write_wav(f"{snd}/shield_block.wav", s)

    # 5. Dodge whoosh
    n = int(SR * 0.20)
    s = []
    lp = 0.0
    for i in range(n):
        t = i / SR
        lp += 0.22 * (rng.uniform(-1, 1) - lp)
        s.append(lp * math.sin(math.pi * t / 0.20))
    write_wav(f"{snd}/dodge_whoosh.wav", s)

    # 6. Spell Fire (roaring crackle)
    n = int(SR * 0.48)
    s = []
    lp = 0.0
    for i in range(n):
        t = i / SR
        lp += 0.16 * (rng.uniform(-1, 1) - lp)
        sweep = 0.45 * math.sin(2 * math.pi * (220 + 180 * t) * t) * math.exp(-t * 5.5)
        s.append((lp * 0.8 + sweep) * env_adsr(t, 0.48, 0.03, 0.12, 0.55, 0.18))
    write_wav(f"{snd}/spell_fire.wav", s)

    # 7. Spell Ice (crystalline shimmer)
    n = int(SR * 0.45)
    s = []
    freqs = [1046.5, 1318.5, 1568.0, 2093.0]
    for i in range(n):
        t = i / SR
        val = sum(math.sin(2 * math.pi * f * (1.0 + 0.01 * math.sin(30 * t)) * t) for f in freqs) * 0.25
        val += 0.2 * rng.uniform(-1, 1) * math.exp(-t * 16.0)
        s.append(val * math.exp(-t * 6.0))
    write_wav(f"{snd}/spell_ice.wav", s)

    # 8. Spell Lightning (sharp crack + electric buzz)
    n = int(SR * 0.42)
    s = []
    for i in range(n):
        t = i / SR
        crack = rng.uniform(-1, 1) * math.exp(-t * 18.0)
        buzz = 0.4 * (1.0 if math.sin(2 * math.pi * 145 * t + 3 * math.sin(90 * t)) > 0 else -1.0) * math.exp(-t * 9.0)
        s.append(crack + buzz)
    write_wav(f"{snd}/spell_lightning.wav", s)

    # 9. Footsteps (grass & stone)
    n = int(SR * 0.11)
    s_grass = [rng.uniform(-1, 1) * math.exp(-(i / SR) * 35.0) * 0.6 for i in range(n)]
    write_wav(f"{snd}/footstep_grass.wav", s_grass)
    s_stone = [
        (0.5 * rng.uniform(-1, 1) + 0.5 * math.sin(2 * math.pi * 240 * (i / SR))) * math.exp(-(i / SR) * 48.0)
        for i in range(n)
    ]
    write_wav(f"{snd}/footstep_stone.wav", s_stone)

    # 10. Item pickup / UI / Chest / Quest / Level Up / Anvil
    write_wav(f"{snd}/ui_click.wav", [math.sin(2 * math.pi * 740 * (i / SR)) * math.exp(-(i / SR) * 55.0) for i in range(int(SR * 0.06))])
    p1 = karplus_pluck(587.33, 0.16, 3, 0.498)
    p2 = karplus_pluck(880.0, 0.24, 4, 0.498)
    pickup = p1[: int(SR * 0.08)] + [a + b for a, b in zip(p1[int(SR * 0.08) :], p2)] + p2[len(p1) - int(SR * 0.08) :]
    write_wav(f"{snd}/pickup_item.wav", pickup)

    # Craft anvil hammer ring
    n = int(SR * 0.45)
    anvil = [
        (0.6 * math.sin(2 * math.pi * 1180 * (i / SR)) + 0.4 * math.sin(2 * math.pi * 1790 * (i / SR)))
        * math.exp(-(i / SR) * 10.5)
        for i in range(n)
    ]
    write_wav(f"{snd}/craft_anvil.wav", anvil)

    # Chest open & Quest complete & Level up fanfares (plucked harp chords)
    def arp(notes: list[float], step: float, tail: float) -> list[float]:
        total = int(SR * (step * len(notes) + tail))
        buf = [0.0] * total
        for idx, f in enumerate(notes):
            pl = karplus_pluck(f, tail + 0.2, seed=10 + idx, brightness=0.4985)
            start = int(idx * step * SR)
            for j, v in enumerate(pl):
                if start + j < total:
                    buf[start + j] += v * 0.5
        return buf

    write_wav(f"{snd}/chest_open.wav", arp([392.0, 493.88, 587.33, 783.99], 0.09, 0.45))
    write_wav(f"{snd}/quest_complete.wav", arp([293.66, 369.99, 440.0, 587.33, 739.99], 0.11, 0.65))
    write_wav(f"{snd}/level_up.wav", arp([261.63, 329.63, 392.0, 523.25, 659.25, 783.99], 0.09, 0.75))


def gen_music() -> None:
    mus = "assets/music"
    # 1. Eldoria Village Lute/Harp Dorian progression (seamless 8-second loop)
    dur = 8.0
    total = int(SR * dur)
    buf = [0.0] * total
    # D Dorian: Dm - C - G/B - Am
    pattern = [
        (0.0, 146.83), (0.0, 293.66), (0.5, 349.23), (1.0, 440.0), (1.5, 392.0),
        (2.0, 130.81), (2.0, 261.63), (2.5, 329.63), (3.0, 392.0), (3.5, 440.0),
        (4.0, 196.00), (4.0, 293.66), (4.5, 392.00), (5.0, 493.88), (5.5, 440.0),
        (6.0, 220.00), (6.0, 329.63), (6.5, 392.00), (7.0, 349.23), (7.5, 329.63),
    ]
    for onset, freq in pattern:
        pl = karplus_pluck(freq, 1.8, seed=int(freq), brightness=0.4988)
        start = int(onset * SR)
        for j, v in enumerate(pl):
            pos = (start + j) % total
            buf[pos] += v * 0.35
    write_wav(f"{mus}/music_eldoria_village.wav", buf)

    # 2. Dungeon Crypt atmospheric drone (6-second seamless loop)
    dur_d = 6.0
    total_d = int(SR * dur_d)
    drone = []
    for i in range(total_d):
        t = i / SR
        phase = 2 * math.pi * t / dur_d
        mod = 0.7 + 0.3 * math.sin(phase)
        v = (
            0.45 * math.sin(2 * math.pi * 73.5 * t)
            + 0.30 * math.sin(2 * math.pi * 110.0 * t + math.sin(phase))
            + 0.18 * math.sin(2 * math.pi * 220.5 * t) * (0.5 + 0.5 * math.cos(phase * 2))
        ) * mod
        drone.append(v)
    write_wav(f"{mus}/music_dungeon_crypt.wav", drone)

    # 3. Gentle forest wind & river stream loop (4-second seamless loop)
    rng = random.Random(777)
    total_a = int(SR * 4.0)
    raw_noise = [rng.uniform(-1, 1) for _ in range(total_a)]
    amb = []
    lp = 0.0
    for i in range(total_a):
        phase = 2 * math.pi * (i / total_a)
        alpha = 0.045 + 0.02 * math.sin(phase)
        lp += alpha * (raw_noise[i] - lp)
        amb.append(lp * (0.65 + 0.25 * math.cos(phase)))
    write_wav(f"{mus}/ambient_wind_river.wav", amb)


if __name__ == "__main__":
    gen_sfx()
    gen_music()
    print("Generated CC0 SFX & Music successfully.")
