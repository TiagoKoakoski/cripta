# godot --headless --path . --script res://tests/teste_assets.gd
extends SceneTree

const SPRITES := {"heroi": 8, "morcego": 2, "slime": 2, "slime_pequeno": 2, "esqueleto": 2, "rei": 2,
	"tiro": 1, "tiro_inimigo": 1, "coracao": 2, "fonte": 1, "pedestal": 1, "item_espada": 1, "item_raio": 1,
	"item_coracao_extra": 1, "item_botas": 1, "item_tiro_triplo": 1, "item_alcance": 1, "icone_combate": 1,
	"icone_tesouro": 1, "icone_fonte": 1, "icone_chefe": 1, "chao": 1, "chao2": 1, "parede": 1, "pilar": 1,
	"porta_fechada": 1, "porta_aberta": 1, "digitos": 10}
const OUTRAS := ["titulo", "texto_fim", "texto_vitoria", "texto_aperte"]
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
	print("Resultado: %d falhas" % falhou)
	quit(1 if falhou > 0 else 0)
