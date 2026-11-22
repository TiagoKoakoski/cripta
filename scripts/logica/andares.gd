## Tabela dos 3 andares: tema, tamanho, inimigos (perto/longe do início), vida e chefes possíveis.
class_name Andares
extends RefCounted

const TOTAL := 3
const DIST_LONGE := 3   # distância da sala de início a partir da qual entram os inimigos "longe"

const TABELA := {
	1: {"nome": "CRIPTA", "tema": "cripta", "salas": Vector2i(10, 12), "mult_vida": 1.0,
		"perto": ["morcego", "slime", "aranha"], "longe": ["esqueleto", "fantasma"],
		"chefes": ["rei", "slime_mae", "cavaleiro"], "subchefes": ["morcego_vampiro", "esqueleto_capitao"]},
	2: {"nome": "CATACUMBAS", "tema": "catacumbas", "salas": Vector2i(13, 15), "mult_vida": 1.3,
		"perto": ["esqueleto", "aranha", "slime", "morcego"], "longe": ["olho"],
		"chefes": ["aranha_rainha", "colosso", "verme"], "subchefes": ["aranha_tecela", "slime_rei"]},
	3: {"nome": "ABISMO", "tema": "abismo", "salas": Vector2i(16, 19), "mult_vida": 1.6,
		"perto": ["fantasma", "olho", "mago", "aranha"], "longe": [],
		"chefes": ["olho_abismo", "lich", "sombra_gemea"], "subchefes": ["mago_sombrio", "fantasma_antigo"]},
}


static func info(n: int) -> Dictionary:
	return TABELA[clampi(n, 1, TOTAL)]
