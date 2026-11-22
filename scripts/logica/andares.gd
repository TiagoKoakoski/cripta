## Tabela dos 3 andares: tema, tamanho, inimigos (perto/longe do início), vida e chefes possíveis.
class_name Andares
extends RefCounted

const TOTAL := 3
const DIST_LONGE := 3   # distância da sala de início a partir da qual entram os inimigos "longe"

const TABELA := {
	1: {"nome": "CRIPTA", "tema": "cripta", "salas": Vector2i(9, 12), "mult_vida": 1.0,
		"perto": ["morcego", "slime", "aranha"], "longe": ["esqueleto", "fantasma"],
		"chefes": ["rei", "slime_mae"]},
	2: {"nome": "CATACUMBAS", "tema": "catacumbas", "salas": Vector2i(10, 13), "mult_vida": 1.3,
		"perto": ["esqueleto", "aranha", "slime", "morcego"], "longe": ["olho"],
		"chefes": ["aranha_rainha", "colosso"]},
	3: {"nome": "ABISMO", "tema": "abismo", "salas": Vector2i(11, 14), "mult_vida": 1.6,
		"perto": ["fantasma", "olho", "mago", "aranha"], "longe": [],
		"chefes": ["olho_abismo", "lich"]},
}


static func info(n: int) -> Dictionary:
	return TABELA[clampi(n, 1, TOTAL)]
