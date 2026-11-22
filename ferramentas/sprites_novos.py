"""Sprites novos da v2 (texto, 1 letra por pixel: k contorno, g médio, w claro, . transparente)."""

ARANHA = [
    "................", "................", "................", "................",
    "...k...kk...k...", "....k.kggk.k....", ".kk..kggggk..kk.", "k..kkgwggwgkk..k",
    "...kgkggggkgk...", ".kkkggggggggkkk.", "k..kggggggggk..k", "..k.kggggggk.k..",
    ".k...kkkkkk...k.", "k..............k", "................", "................",
]
ARANHA_2 = ARANHA[:4] + ["....k..kk..k...."] + ARANHA[5:12] + [".k..kkkkkk..k...", "..k..........k..",
                                                                 "................", "................"]
FANTASMA = [
    "................", "......kkkk......", "....kkwwwwkk....", "...kwwwwwwwwk...",
    "..kwwwwwwwwwwk..", "..kwwkkwwkkwwk..", "..kwwkkwwkkwwk..", "..kwwwwwwwwwwk..",
    "..kwwwwkkwwwwk..", "..kwwwwkkwwwwk..", "..kgwwwwwwwwgk..", "..kggwwwwwwggk..",
    "..kgggwggwgggk..", "..kgkggkkggkgk..", "..k.k..kk..k.k..", "................",
]
FANTASMA_2 = FANTASMA[:13] + ["..kgkkggggkkgk..", "...k..kkkk..k...", "................"]
OLHO = [
    "................", "................", ".....kkkkkk.....", "...kkwwwwwwkk...",
    "..kwwwwwwwwwwk..", ".kwwwwggggwwwwk.", ".kwwwgkkkkgwwwk.", "kwwwgkkwwkkgwwwk",
    "kwwwgkkwkkkgwwwk", ".kwwwgkkkkgwwwk.", ".kwwwwggggwwwwk.", "..kwwwwwwwwwwk..",
    "...kkwwwwwwkk...", ".....kkkkkk.....", "....k..kk..k....", "...k...kk...k...",
]
OLHO_2 = OLHO[:6] + [".kwwwwggggwwwwk.", "kwwwwgkkkkgwwwwk", "kwwwwgkkkkgwwwwk", ".kwwwwggggwwwwk."] \
    + OLHO[10:14] + ["...k..kkkk..k...", "....k......k...."]
MAGO = [
    "......kk........", ".....kggk.......", "....kggggk...kk.", "...kggggggk.kwwk",
    "...kgkkkkgk.kwwk", "...kkwkkwkk..kk.", "...kgkkkkgk...k.", "..kggggggggk..k.",
    "..kgwggggwgkkk..", ".kggwggggwggk.k.", ".kggwggggwggk.k.", ".kgggwwwwgggk.k.",
    "kggggggggggggkk.", "kggggggggggggk..", "kkkkkkkkkkkkkk..", "................",
]
MAGO_2 = MAGO[:3] + ["...kggggggk.kggk", "...kgkkkkgk.kggk"] + MAGO[5:]

ITEM_EXPLOSIVO = [
    "................", "...........kw...", "..........k.w...", ".........k......",
    "......kkkk......", "....kkggggkk....", "...kggggggggk...", "..kgwwggggggk...",
    "..kgwgggggggk...", "..kgggggggggk...", "..kgggggggggk...", "...kgggggggk....",
    "....kkgggkk.....", "......kkk.......", "................", "................",
]
ITEM_GELO = [
    "................", ".......kk.......", "....k..kk..k....", ".....k.kk.k.....",
    "..k...kwwk...k..", "...kkkwwwwkkk...", "....kwwggwwk....", ".kkkwwgwwgwwkkk.",
    ".kkkwwgwwgwwkkk.", "....kwwggwwk....", "...kkkwwwwkkk...", "..k...kwwk...k..",
    ".....k.kk.k.....", "....k..kk..k....", ".......kk.......", "................",
]
ITEM_RICOCHETE = [
    "................", "................", ".kk.........kk..", ".kwk.......kwk..",
    "..kwk.....kwk...", "...kwk...kwk....", "....kwk.kwk.....", ".....kwkwk......",
    "......kwk.......", ".......k........", "....kkkkkkkk....", "....kggggggk....",
    "....kkkkkkkk....", "................", "................", "................",
]
ITEM_PERFURANTE = [
    "................", "................", "................", "....kkkk........",
    "...kggggk..k....", "...kg..gk..kk...", "...kg..gk..kwk..", "kkkkkkkkkkkkwwk.",
    "kwwwwwwwwwwwwwwk", "kkkkkkkkkkkkwwk.", "...kg..gk..kwk..", "...kg..gk..kk...",
    "...kggggk..k....", "....kkkk........", "................", "................",
]
ITEM_TELEGUIADO = [
    "................", "................", "........kkkk....", "......kkwwwwk...",
    ".....kwwkkkwwk..", "....kwk....kwk..", "....kwk.....kwk.", "....kwk...kkkwkk",
    "....kwk....kwwk.", "....kwk.....kk..", "....kwk.........", "...kwwwk........",
    "...kgggk........", "....kkk.........", "................", "................",
]
ITEM_RETAGUARDA = [
    "................", "................", "................", "................",
    "................", "...k........k...", "..kk........kk..", ".kwkkkkkkkkkkwk.",
    "kwwwwwwwwwwwwwwk", ".kwkkkkkkkkkkwk.", "..kk........kk..", "...k........k...",
    "................", "................", "................", "................",
]
TOCHA = [
    "................", ".......k........", "......kwk.......", "......kwwk......",
    ".....kwwwk......", ".....kwgwwk.....", "......kggk......", "......kkkk......",
    ".....kggggk.....", "......kggk......", "......kggk......", "......kggk......",
    ".......kk.......", "................", "................", "................",
]
TOCHA_2 = [
    "................", "........k.......", ".......kwk......", "......kwwk......",
    "......kwwwk.....", ".....kwwgwk.....", "......kggk......", "......kkkk......",
] + TOCHA[8:]
