"""Transforma as imagens geradas pelo Nano Banana (originais/) na arte do visual Detalhado (arte/hd/).

- Folhas com figuras sobre magenta: acha cada figura (componentes conexos), recorta, tira o fundo,
  reduz para a altura pedida (pixel art, 2x a resolução lógica do jogo) e reduz a paleta.
- Texturas (chão, parede): reduz a imagem inteira e recorta tiles de 32x32.
- Cartões e título: reduz para 640x360.

Uso: ~/Projetos/jogos/_ferramentas/venv/bin/python ferramentas/arte_ia/pixelizar.py
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

AQUI = Path(__file__).resolve().parent
ORIG = AQUI / "originais"
HD = AQUI.parent.parent / "arte" / "hd"

# folha -> [(nome, altura em px HD)] na ordem das figuras (esquerda->direita, de cima p/ baixo)
FOLHAS = {
    "inimigos_a": [("morcego", 26), ("slime", 26), ("slime_pequeno", 18), ("esqueleto", 32)],
    "inimigos_b": [("aranha", 24), ("fantasma", 30), ("olho", 26), ("mago", 32)],
    "chefes_a": [("rei", 36), ("slime_mae", 30), ("cavaleiro", 36), ("aranha_rainha", 32)],
    "chefes_b": [("colosso", 36), ("verme", 36), ("olho_abismo", 34), ("lich", 36)],
    "chefes_c": [("sombra_gemea", 36), ("olhinho", 22), ("lich_copia", 34)],
    "subchefes_a": [("morcego_vampiro", 30), ("esqueleto_capitao", 34), ("aranha_tecela", 30), ("slime_rei", 30)],
    "subchefes_b": [("mago_sombrio", 34), ("fantasma_antigo", 34)],
    "itens_a": [("item_espada", 26), ("item_raio", 26), ("item_coracao_extra", 24), ("item_botas", 24),
                ("item_tiro_triplo", 26), ("item_alcance", 26)],
    "itens_b": [("item_ricochete", 24), ("item_perfurante", 26), ("item_teleguiado", 26), ("item_explosivo", 26),
                ("item_gelo", 26), ("item_retaguarda", 26)],
    "itens_c": [("chave", 24), ("coracao_chao", 18), ("pedestal", 24), ("fonte", 28), ("escada", 30),
                ("tocha", 28), ("frasco", 20)],
    "obstaculos": [("pilar", 32), ("pedra", 30), ("caixa", 32), ("buraco", 32), ("espinhos", 32), ("ossos", 28)],
    "portas": [("porta_combate", 32), ("porta_tesouro", 32), ("porta_fonte", 32), ("porta_subchefe", 32),
               ("porta_chefe", 32), ("porta_chefe_trancada", 32)],
}
# personagens: 4 vistas (baixo, direita, cima, esquerda) -> 1 folha de 4 quadros
HEROIS = {"heroi_iara": "heroi", "heroi_bento": "espadachim", "heroi_lucio": "alquimista", "heroi_caua": "cacador"}
ALTURA_HEROI = 40
# objetos que viram tile exato de 32x32 (centralizados)
QUADRADOS = {"pilar", "pedra", "caixa", "buraco", "espinhos"}
TEMAS = {"cripta": (1.0, 1.0, 1.0), "catacumbas": (1.15, 0.95, 0.75), "abismo": (0.7, 0.95, 1.1)}
CARTOES = ["cartao_abertura1", "cartao_abertura2", "cartao_abertura3", "cartao_catacumbas", "cartao_abismo",
           "cartao_final1", "cartao_final2", "cartao_fim", "titulo"]  # "titulo" sai como fundo_titulo


def mascara(a):
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    fundo = (r > 150) & (b > 150) & (g < 120) & (np.abs(r - b) < 90)
    return ~fundo


def figuras(im, minimo_area=1500):
    a = np.asarray(im.convert("RGB"))
    m = mascara(a)
    m = ndimage.binary_closing(m, iterations=4)
    rot, n = ndimage.label(m)
    caixas = []
    for i, sl in enumerate(ndimage.find_objects(rot), start=1):
        area = int((rot[sl] == i).sum())
        if area < minimo_area:
            continue
        caixas.append((sl[1].start, sl[0].start, sl[1].stop, sl[0].stop, area))
    # junta pedaços sobrepostos na horizontal (ex.: chama separada do corpo)
    caixas.sort(key=lambda c: c[0])
    juntas = []
    for c in caixas:
        if juntas and _sobrepoe(juntas[-1], c):
            j = juntas[-1]
            juntas[-1] = (min(j[0], c[0]), min(j[1], c[1]), max(j[2], c[2]), max(j[3], c[3]), j[4] + c[4])
        else:
            juntas.append(c)
    return sorted(juntas, key=lambda c: c[0])   # folhas de 1 linha: esquerda -> direita


def _sobrepoe(a, b):
    """Mesmo objeto partido (ex.: chama solta): sobrepõe na horizontal e quase encosta na vertical."""
    largura = min(a[2], b[2]) - max(a[0], b[0])
    folga_v = max(a[1], b[1]) - min(a[3], b[3])
    return largura > 0.5 * min(a[2] - a[0], b[2] - b[0]) and folga_v < 25


def recortar(im, caixa, folga=6):
    x0, y0, x1, y1 = caixa[:4]
    x0, y0 = max(0, x0 - folga), max(0, y0 - folga)
    x1, y1 = min(im.width, x1 + folga), min(im.height, y1 + folga)
    rec = im.crop((x0, y0, x1, y1)).convert("RGBA")
    a = np.asarray(rec).copy()
    a[..., 3] = np.where(mascara(a), 255, 0)
    return Image.fromarray(a)


def reduzir(rec, altura=None, tamanho=None, cores=24):
    if tamanho:
        peq = rec.resize(tamanho, Image.BOX)
    else:
        larg = max(1, round(rec.width * altura / rec.height))
        peq = rec.resize((larg, altura), Image.BOX)
    a = np.asarray(peq).copy()
    alfa = np.where(a[..., 3] > 128, 255, 0).astype(np.uint8)
    rgb = Image.fromarray(a[..., :3]).quantize(colors=cores, method=Image.Quantize.MEDIANCUT).convert("RGB")
    out = rgb.convert("RGBA")
    out.putalpha(Image.fromarray(alfa))
    return out


def contorno(im):
    """Contorno escuro de 1 px em volta da figura (lê melhor sobre o chão)."""
    a = np.asarray(im).copy()
    dentro = a[..., 3] > 0
    viz = ndimage.binary_dilation(dentro) & ~dentro
    a[viz] = (16, 10, 22, 255)
    return Image.fromarray(a)


def quadro(im, larg, alt):
    """Centraliza `im` numa tela larg x alt, apoiada embaixo."""
    tela = Image.new("RGBA", (larg, alt), (0, 0, 0, 0))
    tela.alpha_composite(im, ((larg - im.width) // 2, alt - im.height))
    return tela


def tingir(im, mult):
    a = np.asarray(im).astype(float)
    for c in range(3):
        a[..., c] = np.clip(a[..., c] * mult[c], 0, 255)
    return Image.fromarray(a.astype(np.uint8))


def folhas():
    for folha, alvos in FOLHAS.items():
        im = Image.open(ORIG / f"{folha}.jpg")
        if folha == "itens_b":   # veio em 2 linhas repetidas: usa só a de baixo (cores mais firmes)
            im = im.crop((0, int(im.height * 0.47), im.width, im.height))
        figs = figuras(im)
        if len(figs) != len(alvos):   # nomes casam por posição: contagem errada trocaria as artes
            raise SystemExit(f"{folha}: achei {len(figs)} figuras, esperava {len(alvos)}; ajuste a folha ou o prompt")
        for alvo, cx in zip(alvos, figs):
            if alvo is None:   # figura pulada (ex.: 1ª linha repetida de itens_b)
                continue
            nome, alt = alvo
            rec = recortar(im, cx)
            if nome in QUADRADOS or nome.startswith("porta"):
                peq = reduzir(rec, tamanho=(32, 32))
                if nome == "buraco":
                    peq = peq.convert("RGBA")
            else:
                peq = contorno(reduzir(rec, alt))
            if nome == "pilar":
                for tema, mult in TEMAS.items():
                    tingir(peq, mult).save(HD / f"pilar_{tema}.png")
                continue
            peq.save(HD / f"{nome}.png")
    # extras derivados
    Image.open(HD / "coracao_chao.png").save(HD / "coracao.png")
    combate = Image.open(HD / "porta_combate.png")
    tingir(combate, (0.8, 0.8, 0.9)).save(HD / "porta_inicio.png")
    fechada = combate.copy()
    d = ImageDraw.Draw(fechada)
    for x in range(5, 30, 6):
        d.line([(x, 6), (x, 31)], fill=(120, 110, 90, 255), width=2)
    fechada.save(HD / "porta_fechada.png")


def herois():
    for arq, nome in HEROIS.items():
        im = Image.open(ORIG / f"{arq}.jpg")
        figs = figuras(im)[:4]
        quadros = [contorno(reduzir(recortar(im, c), ALTURA_HEROI)) for c in figs]
        larg = max(q.width for q in quadros) + 2
        folha = Image.new("RGBA", (larg * 4, ALTURA_HEROI + 2), (0, 0, 0, 0))
        for i, q in enumerate(quadros):
            folha.alpha_composite(quadro(q, larg, ALTURA_HEROI + 2), (i * larg, 0))
        folha.save(HD / f"{nome}.png")


def texturas():
    for tema in TEMAS:
        for tipo in ("chao", "parede"):
            im = Image.open(ORIG / f"{tipo}_{tema}.jpg").convert("RGB")
            larg = 256 if tipo == "chao" else 224
            peq = im.resize((larg, round(im.height * larg / im.width)), Image.BOX)
            peq = peq.quantize(colors=32, method=Image.Quantize.MEDIANCUT).convert("RGBA")
            if tipo == "chao":
                peq = tingir(peq, (0.72, 0.72, 0.76))   # chão mais escuro: personagens se destacam
                for i, (x, y) in enumerate([(32, 32), (96, 64), (160, 32)]):
                    nome = ["chao", "chao2", "chao3"][i]
                    peq.crop((x, y, x + 32, y + 32)).save(HD / f"{nome}_{tema}.png")
            else:
                peq.crop((32, 32, 64, 64)).save(HD / f"parede_{tema}.png")


def tiros():
    for nome, nucleo, borda in (("tiro", (255, 250, 210), (255, 170, 60)), ("tiro_inimigo", (255, 200, 200), (200, 40, 60))):
        im = Image.new("RGBA", (14, 14), (0, 0, 0, 0))
        for y in range(14):
            for x in range(14):
                d = ((x - 6.5) ** 2 + (y - 6.5) ** 2) ** 0.5
                if d <= 3.2:
                    im.putpixel((x, y), nucleo + (255,))
                elif d <= 5.2:
                    im.putpixel((x, y), borda + (255,))
                elif d <= 6.4:
                    im.putpixel((x, y), borda + (110,))
        im.save(HD / f"{nome}.png")


def cartoes():
    for nome in CARTOES:
        im = Image.open(ORIG / f"{nome}.jpg").convert("RGB")
        w, h = im.size
        alvo_h = round(w * 9 / 16)
        if alvo_h <= h:
            im = im.crop((0, (h - alvo_h) // 2, w, (h - alvo_h) // 2 + alvo_h))
        im = im.resize((640, 360), Image.BOX).quantize(colors=64, method=Image.Quantize.MEDIANCUT).convert("RGB")
        im.save(HD / ("fundo_titulo.png" if nome == "titulo" else f"{nome}.png"))   # "titulo" é o logo clássico


if __name__ == "__main__":
    HD.mkdir(parents=True, exist_ok=True)
    folhas()
    herois()
    texturas()
    tiros()
    cartoes()
    print("ok:", len(list(HD.glob("*.png"))), "imagens em", HD)
