"""Gera a arte da Cripta (Godot): sprites 16x16 recoloridos a partir dos desenhos da versão
Game Boy (sprites_base.py) + tiles de sala, portas, ícones, itens novos, HUD e minimapa.
Tudo próprio, nada de terceiros.

Uso: venv/bin/python ferramentas/gerar_arte.py
"""
from pathlib import Path
from PIL import Image

import sprites_base as B

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
    "morcego": ("#e8d0ff", "#7a4a9a"),
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
}


def pintar(frames, paleta):
    w, g = paleta
    cores = {".": TRANSP, "w": rgba(w), "g": rgba(g), "k": rgba(CONTORNO)}
    im = Image.new("RGBA", (16 * len(frames), 16), TRANSP)
    for i, f in enumerate(frames):
        assert len(f) == 16 and all(len(l) == 16 for l in f), f
        for y, l in enumerate(f):
            for x, c in enumerate(l):
                im.putpixel((16 * i + x, y), cores[c])
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
    itens = {"espada": h.ITEM_FORTE, "raio": h.ITEM_GATILHO, "coracao_extra": h.ITEM_CORACAO,
             "botas": h.ITEM_BOTAS, "tiro_triplo": TRIPLO, "alcance": ALCANCE}
    for n, f in itens.items():
        salvar(pintar([f], PALETAS["item"]), f"item_{n}")
    salvar(icone(h.CAVEIRA12, ("#ece6d8", "#a89c8a")), "icone_combate")
    salvar(icone(h.cheio12(h.BAU12), ("#fff2b0", "#c8a040")), "icone_tesouro")
    salvar(icone(h.cheio12(h.CORACAO12), ("#ffd0d6", "#d43a4a")), "icone_fonte")
    salvar(icone(COROA12, ("#fff2b0", "#e0b040")), "icone_chefe")
    salvar(tile(CHAO, CORES_SALA), "chao")
    salvar(tile(CHAO2, CORES_SALA), "chao2")
    salvar(tile(PAREDE, CORES_SALA), "parede")
    salvar(tile(PILAR, CORES_SALA), "pilar")
    salvar(porta(True), "porta_fechada")
    salvar(porta(False), "porta_aberta")
    salvar(tela_texto("CRIPTA", 4, "#e0b040"), "titulo")
    salvar(tela_texto("FIM", 4, "#d43a4a"), "texto_fim")
    salvar(tela_texto("VITORIA", 4, "#e0b040"), "texto_vitoria")
    salvar(tela_texto("APERTE UM BOTAO", 1, "#d8c8b0"), "texto_aperte")
    salvar(pintar([h.digito16(d) for d in range(10)], ("#f2e6c9", "#f2e6c9")), "digitos")


if __name__ == "__main__":
    main()
