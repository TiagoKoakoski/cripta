# godot --headless --path . --script res://tests/teste_assets.gd
extends SceneTree

const SPRITES := {"heroi": 8, "morcego": 2, "slime": 2, "slime_pequeno": 2, "esqueleto": 2, "rei": 2,
	"tiro": 1, "tiro_inimigo": 1, "coracao": 2, "fonte": 1, "pedestal": 1, "item_espada": 1, "item_raio": 1,
	"item_coracao_extra": 1, "item_botas": 1, "item_tiro_triplo": 1, "item_alcance": 1, "icone_combate": 1,
	"icone_tesouro": 1, "icone_fonte": 1, "icone_chefe": 1, "chao": 1, "chao2": 1, "parede": 1, "pilar": 1,
	"porta_fechada": 1, "porta_aberta": 1, "digitos": 10, "chao3": 1, "aranha": 2, "fantasma": 2, "olho": 2,
	"mago": 2, "tocha": 2, "sombra": 1, "coracao_chao": 1, "item_ricochete": 1, "item_perfurante": 1,
	"item_teleguiado": 1, "item_explosivo": 1, "item_gelo": 1, "item_retaguarda": 1, "escada": 1,
	"slime_mae": 2, "aranha_rainha": 2, "colosso": 2, "olho_abismo": 2, "lich": 2, "poca_teia": 1, "espadachim": 8,
	"chao_cripta": 1, "chao2_cripta": 1, "chao3_cripta": 1, "parede_cripta": 1, "pilar_cripta": 1,
	"chao_catacumbas": 1, "chao2_catacumbas": 1, "chao3_catacumbas": 1, "parede_catacumbas": 1, "pilar_catacumbas": 1,
	"porta_inicio": 1, "porta_combate": 1, "porta_tesouro": 1, "porta_fonte": 1, "porta_subchefe": 1,
	"porta_chefe": 1, "porta_chefe_trancada": 1, "chave": 1, "pedra": 1, "caixa": 1, "buraco": 1, "espinhos": 1, "alquimista": 8, "cacador": 8, "frasco": 1, "bumerangue": 1, "cavaleiro": 2, "verme": 2, "sombra_gemea": 2, "fogo": 2, "morcego_vampiro": 2, "esqueleto_capitao": 2, "aranha_tecela": 2,
	"slime_rei": 2, "mago_sombrio": 2, "fantasma_antigo": 2,
	"chao_abismo": 1, "chao2_abismo": 1, "chao3_abismo": 1, "parede_abismo": 1, "pilar_abismo": 1}
const HD := ["heroi", "espadachim", "alquimista", "cacador", "morcego", "slime", "slime_pequeno", "esqueleto",
	"aranha", "fantasma", "olho", "mago", "rei", "slime_mae", "cavaleiro", "aranha_rainha", "colosso", "verme",
	"olho_abismo", "lich", "sombra_gemea", "olhinho", "lich_copia", "morcego_vampiro", "esqueleto_capitao",
	"aranha_tecela", "slime_rei", "mago_sombrio", "fantasma_antigo", "item_espada", "item_raio", "item_coracao_extra",
	"item_botas", "item_tiro_triplo", "item_alcance", "item_ricochete", "item_perfurante", "item_teleguiado",
	"item_explosivo", "item_gelo", "item_retaguarda", "chave", "coracao", "coracao_chao", "pedestal", "fonte",
	"escada", "tocha", "frasco", "pedra", "caixa", "buraco", "espinhos", "porta_combate", "porta_tesouro",
	"porta_fonte", "porta_subchefe", "porta_chefe", "porta_chefe_trancada", "porta_inicio", "porta_fechada",
	"tiro", "tiro_inimigo", "chao_cripta", "chao2_cripta", "chao3_cripta", "parede_cripta", "pilar_cripta",
	"chao_catacumbas", "chao2_catacumbas", "chao3_catacumbas", "parede_catacumbas", "pilar_catacumbas",
	"chao_abismo", "chao2_abismo", "chao3_abismo", "parede_abismo", "pilar_abismo", "cartao_abertura1",
	"cartao_abertura2", "cartao_abertura3", "cartao_catacumbas", "cartao_abismo", "cartao_final1", "cartao_final2",
	"cartao_fim", "titulo"]
const OUTRAS := ["titulo", "texto_fim", "texto_vitoria", "texto_aperte", "brilho", "vinheta"]
const SONS := ["tiro", "acerto", "morte_inimigo", "dano", "item", "porta", "vitoria", "derrota", "fonte"]

var falhou := 0


func _initialize() -> void:
	for n: String in SPRITES:
		var img := Image.load_from_file("res://arte/%s.png" % n)
		if img == null or img.get_width() != 16 * int(SPRITES[n]) or img.get_height() != 16:
			falhou += 1
			push_error("FALHOU sprite %s" % n)
	for n: String in OUTRAS:
		if Image.load_from_file("res://arte/%s.png" % n) == null:
			falhou += 1
			push_error("FALHOU imagem %s" % n)
	for n: String in SONS:
		if not FileAccess.file_exists("res://sons/%s.wav" % n):
			falhou += 1
			push_error("FALHOU som %s" % n)
	# visual Detalhado: arte gerada (Nano Banana) reduzida para pixel art em arte/hd
	for n: String in HD:
		var img := Image.load_from_file("res://arte/hd/%s.png" % n)
		if img == null:
			falhou += 1
			push_error("FALHOU arte HD %s" % n)
		elif n in ["heroi", "espadachim", "alquimista", "cacador"] and img.get_width() % 4 != 0:
			falhou += 1
			push_error("FALHOU %s: 4 quadros" % n)
	print("Resultado: %d falhas" % falhou)
	quit(1 if falhou > 0 else 0)
