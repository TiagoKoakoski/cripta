"""Gera a arte da Cripta (Godot): sprites 16x16 recoloridos a partir dos desenhos da versão
Game Boy (sprites_base.py) + tiles de sala, portas, ícones, itens novos, HUD e minimapa.
Tudo próprio, nada de terceiros.

Uso: venv/bin/python ferramentas/gerar_arte.py
"""
from pathlib import Path
from PIL import Image

import sprites_base as B
import sprites_novos as N

RAIZ = Path(__file__).resolve().parent.parent
ARTE = RAIZ / "arte"
TRANSP = (0, 0, 0, 0)
CONTORNO = "#120e17"


def rgba(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


# paleta por sprite: 'w' claro, 'g' médio ('k' é sempre o contorno)
PALETAS = {
    "heroi": ("#f2e6c9", "#4a7fbf"),
    "morcego": ("#f4e2ff", "#a274d6"),
    "slime": ("#bff2a8", "#3fa34d"),
    "slime_p": ("#d8ffc8", "#5cc46a"),
    "esqueleto": ("#ece6d8", "#a89c8a"),
    "rei": ("#ece6d8", "#e0b040"),
    "tiro": ("#fff6c2", "#ffb347"),
    "tiro_inimigo": ("#ff9a9a", "#c04040"),
    "coracao": ("#ff9aa5", "#d43a4a"),
    "item": ("#fff2b0", "#c8a040"),
    "fonte": ("#bfe8ff", "#4a8fc0"),
    "porta": ("#d8c8b0", "#6a5040"),
    "aranha": ("#ffb070", "#7a3a2a"),
    "fantasma": ("#e8f4ff", "#8aa8c8"),
    "olho": ("#fff0f0", "#c03050"),
    "mago": ("#a0ffd0", "#3a5a8a"),
    "tocha": ("#ffe080", "#a06030"),
}


def misturar(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3)) + (255,)


def pintar(frames, paleta, sombrear=True):
    """Pinta sprites em texto. Com sombrear: contorno escuro na cor do sprite, sombra no 'g' que
    encosta em borda embaixo/à direita e brilho no 'w' que encosta em borda em cima/à esquerda."""
    w, g = paleta
    cw, cg = rgba(w), rgba(g)
    preto = rgba(CONTORNO)
    cores = {".": TRANSP, "w": cw, "g": cg, "k": misturar(preto, cg, 0.25) if sombrear else preto}
    sombra = misturar(cg, preto, 0.38)
    brilho = misturar(cw, (255, 255, 255), 0.45)
    im = Image.new("RGBA", (16 * len(frames), 16), TRANSP)
    for i, f in enumerate(frames):
        assert len(f) == 16 and all(len(l) == 16 for l in f), f
        px = lambda x, y: f[y][x] if 0 <= x < 16 and 0 <= y < 16 else "."
        for y, l in enumerate(f):
            for x, c in enumerate(l):
                cor = cores[c]
                if sombrear and c == "g" and (px(x, y + 1) in "k." or px(x + 1, y) in "k."):
                    cor = sombra
                elif sombrear and c == "w" and (px(x, y - 1) in "k." or px(x - 1, y) in "k."):
                    cor = brilho
                im.putpixel((16 * i + x, y), cor)
    return im


def pequeno(f):
    """Versão 2/3 do sprite (slime pequeno): reamostra 16->11 e centraliza."""
    src = [[c for c in l] for l in f]
    out = [["."] * 16 for _ in range(16)]
    for y in range(11):
        for x in range(11):
            out[5 + y][2 + x] = src[int(y * 16 / 11)][int(x * 16 / 11)]
    return ["".join(l) for l in out]


# ------------------------------------------------------------------ itens novos (16x16)
TRIPLO = [
    "................", "................", "...kk..kk..kk...", "..kwwkkwwkkwwk..", "..kwgk.kgk.kgwk.",
    "..kkk..kgk..kkk.", "...k...kgk...k..", "....k..kgk..k...", ".....k.kgk.k....", "......kkgkk.....",
    ".......kgk......", ".......kgk......", ".......kkk......", "................", "................", "................",
]
ALCANCE = [
    "................", "................", "........kk......", "........kwk.....", "..kkkkkkkwwk....",
    "..kgggggggwwk...", "..kgggggggggwk..", "..kgggggggwwk...", "..kkkkkkkwwk....", "........kwk.....",
    "........kk......", "................", "................", "................", "................", "................",
]
PEDESTAL = [
    "................", "................", "................", "................", "................",
    "................", "................", "................", "................", "...kkkkkkkkkk...",
    "...kwwwwwwwwk...", "....kggggggk....", "....kggggggk....", "...kkkkkkkkkk...", "...kgggggggggk..", "...kkkkkkkkkkk..",
]
COROA12 = ["wwwwwwwwwwww", "wkwwkwwkwwkw", "wkkwkkkkwkkw", "wkgkggggkgkw", "wkggggggggkw", "wkggggggggkw",
           "wkkkkkkkkkkw", "wwwwwwwwwwww", "wwwwwwwwwwww", "wwwwwwwwwwww", "wwwwwwwwwwww", "wwwwwwwwwwww"]


# ------------------------------------------------------------------ tiles da sala (16x16, opacos)
def tile(linhas, cores):
    im = Image.new("RGBA", (16, 16))
    for y, l in enumerate(linhas):
        for x, c in enumerate(l):
            im.putpixel((x, y), rgba(cores[c]))
    return im


CHAO = ["0000000000000000", "0000000000000000", "0001000000000000", "0000000000000100", "0000000000000000",
        "0000000000000000", "0000000010000000", "0000000000000000", "0000000000000000", "0100000000000000",
        "0000000000001000", "0000000000000000", "0000010000000000", "0000000000000000", "0000000000000010", "0000000000000000"]
CHAO2 = [l[8:] + l[:8] for l in CHAO[8:] + CHAO[:8]]
PAREDE = ["2222222222222222", "3333333233333332", "3333333233333332", "3333333233333332", "2222222222222222",
          "3332333333323333", "3332333333323333", "3332333333323333", "2222222222222222", "3333333233333332",
          "3333333233333332", "3333333233333332", "2222222222222222", "3332333333323333", "3332333333323333", "1111111111111111"]
PILAR = ["1111111111111111", "1222222222222221", "1233333333333321", "1232222222222321", "1232333333332321",
         "1232333333332321", "1232333333332321", "1232333333332321", "1232333333332321", "1232333333332321",
         "1232333333332321", "1232333333332321", "1232222222222321", "1233333333333321", "1222222222222221", "1111111111111111"]
CORES_SALA = {"0": "#2b2433", "1": "#3b3245", "2": "#5a4a6a", "3": "#1a1520"}


import random


TEMAS = {
    "cripta": {"chao": ("#3a3044", "#241d2b", "#4a3f55", "#30283a"),
               "parede": ("#1f1926", "#4d4060", "#65577a", "#3a3049"),
               "pilar": ("#140f19", "#7a6a90", "#9585aa", "#4a3d5c", "#382d47"), "brilho": None},
    "catacumbas": {"chao": ("#3d3226", "#251d15", "#4f4232", "#33291f"),
                   "parede": ("#21180f", "#6a5440", "#85694f", "#4f3d2d"),
                   "pilar": ("#150f09", "#9a8468", "#b39b7c", "#5e4a36", "#47382a"), "brilho": "#d8c8a8"},
    "abismo": {"chao": ("#1f2a33", "#121a20", "#2b3a46", "#18222a"),
               "parede": ("#0e151a", "#2f4250", "#3f5a6c", "#22313c"),
               "pilar": ("#0a1014", "#4a7a8c", "#6aa8b8", "#2a4654", "#1f3540"), "brilho": "#7fe8ff"},
}


def chao(semente, tema="cripta"):
    """Laje de pedra 16x16: rejunte escuro em cima/à esquerda, pontos claros e escuros.
    Catacumbas ganham lascas de osso; abismo, pontos de cristal."""
    r = random.Random(semente)
    base, rej, claro, escuro = (rgba(c) for c in TEMAS[tema]["chao"])
    extra = TEMAS[tema]["brilho"]
    im = Image.new("RGBA", (16, 16), base)
    for y in range(16):
        for x in range(16):
            if y == 0 or x == 0:
                im.putpixel((x, y), rej)
            elif y == 1 or x == 1:
                im.putpixel((x, y), claro)
            elif r.random() < 0.07:
                im.putpixel((x, y), r.choice([claro, escuro, escuro]))
    if semente % 2:   # rachadura
        x, y = r.randint(4, 10), r.randint(4, 10)
        for _ in range(5):
            im.putpixel((x, y), rej)
            x, y = x + r.choice([0, 1]), y + 1
    if extra and semente % 3 == 2:
        x, y = r.randint(3, 11), r.randint(3, 11)
        for dx, dy in ((0, 0), (1, 0), (2, 1)) if tema == "catacumbas" else ((0, 0), (0, 1), (1, 1)):
            im.putpixel((x + dx, y + dy), rgba(extra))
    return im


def parede(tema="cripta"):
    """Tijolos com rejunte, brilho em cima de cada tijolo e base em sombra."""
    rej, tij, luz, somb = (rgba(c) for c in TEMAS[tema]["parede"])
    im = Image.new("RGBA", (16, 16), tij)
    for y in range(16):
        linha = y // 4
        desloc = 4 if linha % 2 else 0
        for x in range(16):
            yy = y % 4
            junta = (x + desloc) % 8 == 0
            if yy == 0 or junta:
                cor = rej
            elif yy == 1:
                cor = luz
            elif yy == 3:
                cor = somb
            else:
                cor = tij
            im.putpixel((x, y), cor)
    return im


def pilar(tema="cripta"):
    """Bloco em perspectiva: topo claro (6 px) e frente escura com tijolos."""
    cont, topo, topo_b, frente, frente_e = (rgba(c) for c in TEMAS[tema]["pilar"])
    im = Image.new("RGBA", (16, 16), frente)
    for y in range(16):
        for x in range(16):
            if x in (0, 15) or y in (0, 15):
                cor = cont
            elif y <= 5:
                cor = topo_b if y == 1 or x == 1 else topo
            elif y == 6:
                cor = cont
            elif (y - 7) % 4 == 3 or (x + (4 if ((y - 7) // 4) % 2 else 0)) % 8 == 0:
                cor = frente_e
            else:
                cor = frente
            im.putpixel((x, y), cor)
    return im


def sombra():
    im = Image.new("RGBA", (16, 16), TRANSP)
    for y in range(16):
        for x in range(16):
            dx, dy = (x - 7.5) / 6.0, (y - 14.0) / 2.2
            if dx * dx + dy * dy <= 1.0:
                im.putpixel((x, y), (0, 0, 0, 90))
    return im


def brilho_tocha(n=48):
    im = Image.new("RGBA", (n, n), TRANSP)
    c = (n - 1) / 2
    for y in range(n):
        for x in range(n):
            d = ((x - c) ** 2 + (y - c) ** 2) ** 0.5 / c
            if d < 1:
                im.putpixel((x, y), (255, 170, 80, int(70 * (1 - d) ** 2)))
    return im


def vinheta(w=320, h=176):
    im = Image.new("RGBA", (w, h), TRANSP)
    for y in range(h):
        for x in range(w):
            dx, dy = (x - w / 2) / (w / 2), (y - h / 2) / (h / 2)
            d = (dx * dx + dy * dy) ** 0.5
            if d > 0.75:
                im.putpixel((x, y), (8, 4, 12, min(150, int((d - 0.75) * 260))))
    return im


def escada():
    """Escada de pedra subindo (degraus claros em cima, sombra embaixo) com moldura."""
    cont, degrau, borda, somb = rgba("#140f19"), rgba("#9a8cb0"), rgba("#c8bcd8"), rgba("#4a3f5a")
    im = Image.new("RGBA", (16, 16), TRANSP)
    for y in range(16):
        for x in range(16):
            if x in (0, 15) or y in (0, 15):
                cor = cont
            elif (y - 1) % 3 == 0:
                cor = borda
            elif (y - 1) % 3 == 1:
                cor = degrau
            else:
                cor = somb
            if 1 <= y <= 14 and x in (1, 14):
                cor = cont
            im.putpixel((x, y), cor)
    return im


CHAVE = [
    "................", "................", "....kkkk........", "...kwwwwk.......",
    "..kwk..kwk......", "..kwk..kwk......", "...kwwwwkkkkkkk.", "....kkkkwwwwwwwk",
    "........kkkkgkgk", "...........k.k.k", "................", "................",
    "................", "................", "................", "................",
]


def porta(fechada):
    linhas = []
    for y in range(16):
        if y < 2:
            linhas.append("2222222222222222")
        elif fechada:
            linhas.append("2" + ("3" + "1") * 7 + "2")
        else:
            linhas.append("2" + "0" * 14 + "2")
    return tile(linhas, {"0": "#0a080d", "1": "#8a7a5a", "2": "#5a4a6a", "3": "#2a2030"})


def icone(miolo12, paleta):
    f = ["." * 16, "." * 16] + ["..%s.." % l for l in miolo12] + ["." * 16, "." * 16]
    return pintar([f], paleta)


def tela_texto(texto, escala, cor):
    larg = len(texto) * 6 * escala
    im = Image.new("RGBA", (larg, 7 * escala), TRANSP)
    for i, ch in enumerate(texto):
        for y, l in enumerate(B.FONTE5[ch]):
            for x, c in enumerate(l):
                if c == "k":
                    for dy in range(escala):
                        for dx in range(escala):
                            im.putpixel(((i * 6 + x) * escala + dx, y * escala + dy), rgba(cor))
    return im


def main():
    ARTE.mkdir(exist_ok=True)
    salvar = lambda im, n: im.save(ARTE / f"{n}.png")
    h = B
    salvar(pintar([h.HEROI_BAIXO, h.HEROI_BAIXO_2, h.HEROI_DIR, h.HEROI_DIR_2, h.HEROI_CIMA, h.HEROI_CIMA_2,
                   h.espelhar(h.HEROI_DIR), h.espelhar(h.HEROI_DIR_2)], PALETAS["heroi"]), "heroi")
    salvar(pintar([h.MORCEGO, h.MORCEGO_2], PALETAS["morcego"]), "morcego")
    salvar(pintar([h.SLIME, h.SLIME_2], PALETAS["slime"]), "slime")
    salvar(pintar([pequeno(h.SLIME), pequeno(h.SLIME_2)], PALETAS["slime_p"]), "slime_pequeno")
    salvar(pintar([h.ESQUELETO, h.ESQUELETO_2], PALETAS["esqueleto"]), "esqueleto")
    salvar(pintar([h.REI, h.REI_2], PALETAS["rei"]), "rei")
    salvar(pintar([h.TIRO], PALETAS["tiro"]), "tiro")
    salvar(pintar([h.TIRO_INIMIGO], PALETAS["tiro_inimigo"]), "tiro_inimigo")
    salvar(pintar([h.CORACAO_CHEIO, h.CORACAO_VAZIO], PALETAS["coracao"]), "coracao")
    salvar(pintar([h.FONTE], PALETAS["fonte"]), "fonte")
    salvar(pintar([PEDESTAL], PALETAS["porta"]), "pedestal")
    salvar(pintar([N.ARANHA, N.ARANHA_2], PALETAS["aranha"]), "aranha")
    salvar(pintar([N.FANTASMA, N.FANTASMA_2], PALETAS["fantasma"]), "fantasma")
    salvar(pintar([N.OLHO, N.OLHO_2], PALETAS["olho"]), "olho")
    salvar(pintar([N.MAGO, N.MAGO_2], PALETAS["mago"]), "mago")
    salvar(pintar([N.TOCHA, N.TOCHA_2], PALETAS["tocha"]), "tocha")
    salvar(pintar([h.CORACAO_CHEIO], PALETAS["coracao"]), "coracao_chao")
    itens = {"espada": h.ITEM_FORTE, "raio": h.ITEM_GATILHO, "coracao_extra": h.ITEM_CORACAO,
             "botas": h.ITEM_BOTAS, "tiro_triplo": TRIPLO, "alcance": ALCANCE,
             "ricochete": N.ITEM_RICOCHETE, "perfurante": N.ITEM_PERFURANTE, "teleguiado": N.ITEM_TELEGUIADO,
             "explosivo": N.ITEM_EXPLOSIVO, "gelo": N.ITEM_GELO, "retaguarda": N.ITEM_RETAGUARDA}
    cor_item = {"explosivo": ("#ffb060", "#505060"), "gelo": ("#e0f6ff", "#5aa8e0"),
                "teleguiado": ("#f0d0ff", "#9a5ad0"), "perfurante": ("#e0ffd0", "#5aa060"),
                "ricochete": ("#d0fff6", "#3a9a9a"), "retaguarda": ("#fff2b0", "#c87a40")}
    for n, f in itens.items():
        salvar(pintar([f], cor_item.get(n, PALETAS["item"])), f"item_{n}")
    salvar(icone(h.CAVEIRA12, ("#ece6d8", "#a89c8a")), "icone_combate")
    salvar(icone(h.cheio12(h.BAU12), ("#fff2b0", "#c8a040")), "icone_tesouro")
    salvar(icone(h.cheio12(h.CORACAO12), ("#ffd0d6", "#d43a4a")), "icone_fonte")
    salvar(icone(COROA12, ("#fff2b0", "#e0b040")), "icone_chefe")
    salvar(chao(1), "chao")
    salvar(chao(2), "chao2")
    salvar(chao(5), "chao3")
    salvar(parede(), "parede")
    salvar(pilar(), "pilar")
    for tema in TEMAS:
        salvar(chao(1, tema), f"chao_{tema}")
        salvar(chao(2, tema), f"chao2_{tema}")
        salvar(chao(5, tema), f"chao3_{tema}")
        salvar(parede(tema), f"parede_{tema}")
        salvar(pilar(tema), f"pilar_{tema}")
    salvar(pintar([N.SLIME_MAE, N.SLIME_MAE_2], ("#c8ffb0", "#2f8a3d")), "slime_mae")
    salvar(pintar([N.ARANHA_RAINHA, N.ARANHA_RAINHA_2], ("#ffd070", "#6a2a6a")), "aranha_rainha")
    salvar(pintar([N.COLOSSO, N.COLOSSO_2], ("#f0e6cc", "#8a7a5a")), "colosso")
    salvar(pintar([N.OLHO, N.OLHO_2], ("#d0f6ff", "#2a6a9a")), "olho_abismo")
    salvar(pintar([N.LICH, N.LICH_2], ("#e0c8ff", "#4a2a7a")), "lich")
    salvar(pintar([N.TEIA], ("#ffffff", "#c8c8d8")), "poca_teia")
    salvar(pintar([h.HEROI_BAIXO, h.HEROI_BAIXO_2, h.HEROI_DIR, h.HEROI_DIR_2, h.HEROI_CIMA, h.HEROI_CIMA_2,
                   h.espelhar(h.HEROI_DIR), h.espelhar(h.HEROI_DIR_2)], ("#ffd8c8", "#c0392b")), "espadachim")
    salvar(sombra(), "sombra")
    salvar(escada(), "escada")
    salvar(pintar([CHAVE], ("#fff0a0", "#c89a30")), "chave")
    salvar(brilho_tocha(), "brilho")
    salvar(vinheta(), "vinheta")
    salvar(porta(True), "porta_fechada")
    salvar(porta(False), "porta_aberta")
    salvar(tela_texto("CRIPTA", 4, "#e0b040"), "titulo")
    salvar(tela_texto("FIM", 4, "#d43a4a"), "texto_fim")
    salvar(tela_texto("VITORIA", 4, "#e0b040"), "texto_vitoria")
    salvar(tela_texto("APERTE UM BOTAO", 1, "#d8c8b0"), "texto_aperte")
    salvar(pintar([h.digito16(d) for d in range(10)], ("#f2e6c9", "#f2e6c9"), sombrear=False), "digitos")


if __name__ == "__main__":
    main()
