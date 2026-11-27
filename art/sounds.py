"""Звуки BaphOS — синтез с нуля (только стандартная библиотека), никаких чужих сэмплов.
Тихие и короткие, 44.1 кГц, моно, 16 бит.

  bell.wav      уведомление: удар колокола (негармоничные обертоны, долгое затухание)
  login.wav     вход: органный минорный аккорд с гулом
  open.wav      Пуск/Алтарь открыт: 8-битный блип вверх
  close.wav     закрыт: блип вниз
  whisper.wav   послание культа: «дыхание» из отфильтрованного шума
  glitch.wav    глитч: рваный цифровой треск
  tick.wav      громкость/яркость: короткий щелчок
  lock.wav      блокировка: глухой удар

Запуск: python3 art/sounds.py   -> assets/sounds/
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path("assets/sounds")


def save(name, samples, gain=0.5):
    peak = max(1e-9, max(abs(s) for s in samples))
    k = gain / peak
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * k)) * 32767)) for s in samples))


def env(i, n, attack=0.005, release=0.05):
    t = i / RATE
    dur = n / RATE
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = min(1.0, (dur - t) / release) if release > 0 else 1.0
    return max(0.0, a * r)


def square(f, t):
    return 1.0 if math.sin(2 * math.pi * f * t) >= 0 else -1.0


def bell():
    n = int(RATE * 2.2)
    # колокол: основной тон и негармоничные обертоны, каждый со своим затуханием
    parts = [(196.0, 1.0, 1.6), (196 * 2.0, 0.6, 1.2), (196 * 2.4, 0.5, 0.9), (196 * 3.0, 0.3, 0.7),
             (196 * 4.2, 0.25, 0.5), (196 * 5.4, 0.15, 0.35), (98.0, 0.4, 2.0)]
    out = []
    for i in range(n):
        t = i / RATE
        s = sum(a * math.exp(-t / d) * math.sin(2 * math.pi * f * t) for f, a, d in parts)
        out.append(s * env(i, n, 0.002, 0.3))
    save("bell.wav", out, 0.45)


def login():
    n = int(RATE * 3.0)
    notes = [110.0, 130.81, 164.81, 220.0]           # ля минор: A2 C3 E3 A3
    out = []
    lp = 0.0
    for i in range(n):
        t = i / RATE
        s = 0.0
        for k, f in enumerate(notes):
            vib = 1 + 0.003 * math.sin(2 * math.pi * 5 * t + k)
            s += sum(math.sin(2 * math.pi * f * h * vib * t) / h for h in (1, 2, 3, 4)) * (0.9 if k else 1.2)
        s += 0.8 * math.sin(2 * math.pi * 55 * t)    # гул
        lp += 0.08 * (s - lp)                         # мягкий фильтр
        out.append(lp * env(i, n, 0.8, 1.2))
    save("login.wav", out, 0.4)


def blip(name, f0, f1, dur=0.07):
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        f = f0 + (f1 - f0) * (i / n)
        out.append(square(f, t) * 0.5 * env(i, n, 0.002, 0.03))
    save(name, out, 0.25)


def whisper():
    rnd = random.Random(666)
    n = int(RATE * 1.4)
    out = []
    lp = hp = 0.0
    for i in range(n):
        t = i / RATE
        x = rnd.uniform(-1, 1)
        lp += 0.15 * (x - lp)                          # полоса шёпота
        hp = lp - (hp * 0.995)
        breath = math.sin(math.pi * t / 1.4) ** 2      # вдох-выдох
        out.append((lp - hp * 0.3) * breath)
    save("whisper.wav", out, 0.3)


def glitch():
    rnd = random.Random(13)
    n = int(RATE * 0.35)
    out = []
    hold = 0.0
    for i in range(n):
        if i % rnd.choice((40, 80, 160, 320)) == 0:
            hold = rnd.uniform(-1, 1)
        s = round(hold * 4) / 4                        # «биткраш»
        if rnd.random() < 0.002:
            hold = 0.0
        out.append(s * env(i, n, 0.001, 0.05))
    save("glitch.wav", out, 0.3)


def tick():
    n = int(RATE * 0.03)
    save("tick.wav", [square(1400, i / RATE) * math.exp(-i / (RATE * 0.006)) for i in range(n)], 0.2)


def lock():
    n = int(RATE * 0.6)
    out = []
    for i in range(n):
        t = i / RATE
        f = 90 * math.exp(-t * 3)
        out.append(math.sin(2 * math.pi * f * t) * math.exp(-t * 6))
    save("lock.wav", out, 0.5)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    bell()
    login()
    blip("open.wav", 330, 880)
    blip("close.wav", 880, 330)
    whisper()
    glitch()
    tick()
    lock()
    print(f"sounds -> {OUT}")


if __name__ == "__main__":
    main()
