"""Sintetiza os efeitos sonoros da Cripta (nada de áudio de terceiros).

Uso: venv/bin/python ferramentas/gerar_sons.py
"""
import wave
from pathlib import Path

import numpy as np

SR = 22050
SONS = Path(__file__).resolve().parent.parent / "sons"
rng = np.random.default_rng(7)


def env(n, ataque=0.005, queda=4.0):
    t = np.arange(n) / SR
    a = np.minimum(1, t / ataque)
    return a * np.exp(-queda * t / max(t[-1], 1e-3))


def tom(freq0, freq1, dur, forma="quadrada", queda=4.0):
    n = int(SR * dur)
    f = np.linspace(freq0, freq1, n)
    fase = 2 * np.pi * np.cumsum(f) / SR
    onda = np.sign(np.sin(fase)) * 0.5 if forma == "quadrada" else np.sin(fase)
    return onda * env(n, queda=queda)


def ruido(dur, queda=6.0):
    n = int(SR * dur)
    return rng.uniform(-1, 1, n) * env(n, queda=queda)


def seq(*partes):
    return np.concatenate(partes)


def salvar(nome, x, vol=0.35):
    x = np.clip(x / max(1e-6, np.abs(x).max()) * vol, -1, 1)
    with wave.open(str(SONS / f"{nome}.wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())


def main():
    SONS.mkdir(exist_ok=True)
    salvar("tiro", tom(900, 500, 0.08), 0.18)
    salvar("acerto", ruido(0.06, 8) * 0.6 + tom(300, 200, 0.06) * 0.4, 0.25)
    salvar("morte_inimigo", seq(ruido(0.12, 5), tom(400, 80, 0.15)), 0.3)
    salvar("dano", seq(tom(220, 110, 0.18), ruido(0.08, 6)), 0.35)
    salvar("item", seq(*[tom(f, f, 0.08, "seno", 2) for f in (523, 659, 784, 1047)]), 0.35)
    salvar("porta", seq(ruido(0.05, 3), tom(150, 120, 0.15, "seno")), 0.3)
    salvar("fonte", seq(*[tom(f, f * 1.01, 0.12, "seno", 3) for f in (392, 523, 659)]), 0.3)
    salvar("vitoria", seq(*[tom(f, f, 0.15, "quadrada", 2) for f in (523, 659, 784, 1047, 784, 1047)]), 0.3)
    salvar("derrota", seq(*[tom(f, f * 0.97, 0.25, "quadrada", 2) for f in (392, 330, 262, 196)]), 0.3)


if __name__ == "__main__":
    main()
