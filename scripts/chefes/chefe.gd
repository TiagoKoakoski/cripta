## Base dos chefes: vida da tabela, espera inicial de 1 s, fases a 2/3 e 1/3 da vida, invocações.
## (o contador _t já é decrementado por Inimigo._physics_process antes de _ia)
## Cada chefe é uma subclasse que implementa _agir(delta) e, se quiser, _ao_mudar_fase(f).
class_name Chefe
extends Inimigo

signal fase_mudou(n: int)

const VIDA_CHEFE := {"rei": 45, "slime_mae": 40, "aranha_rainha": 55, "colosso": 60, "olho_abismo": 65, "lich": 70,
	"cavaleiro": 45, "verme": 55, "sombra_gemea": 65,
	"morcego_vampiro": 18, "esqueleto_capitao": 20, "aranha_tecela": 26, "slime_rei": 28, "mago_sombrio": 32,
	"fantasma_antigo": 30}
const SUBCHEFES := ["morcego_vampiro", "esqueleto_capitao", "aranha_tecela", "slime_rei", "mago_sombrio", "fantasma_antigo"]
const NOMES := {"rei": "REI ESQUELETO", "slime_mae": "SLIME MÃE", "aranha_rainha": "ARANHA RAINHA",
	"colosso": "COLOSSO DE OSSOS", "olho_abismo": "OLHO DO ABISMO", "lich": "VESPER, O LICH",
	"cavaleiro": "CAVALEIRO SEM CABEÇA", "verme": "VERME DE OSSOS", "sombra_gemea": "SOMBRA GÊMEA",
	"morcego_vampiro": "MORCEGO VAMPIRO", "esqueleto_capitao": "ESQUELETO CAPITÃO", "aranha_tecela": "ARANHA TECELÃ",
	"slime_rei": "SLIME REI", "mago_sombrio": "MAGO SOMBRIO", "fantasma_antigo": "FANTASMA ANTIGO"}
const SCRIPTS := {"rei": "res://scripts/chefes/rei.gd", "slime_mae": "res://scripts/chefes/slime_mae.gd",
	"aranha_rainha": "res://scripts/chefes/aranha_rainha.gd", "colosso": "res://scripts/chefes/colosso.gd",
	"olho_abismo": "res://scripts/chefes/olho_abismo.gd", "lich": "res://scripts/chefes/lich.gd",
	"cavaleiro": "res://scripts/chefes/cavaleiro.gd", "verme": "res://scripts/chefes/verme.gd",
	"sombra_gemea": "res://scripts/chefes/sombra_gemea.gd",
	"morcego_vampiro": "res://scripts/chefes/sub_morcego_vampiro.gd", "esqueleto_capitao": "res://scripts/chefes/sub_esqueleto_capitao.gd",
	"aranha_tecela": "res://scripts/chefes/sub_aranha_tecela.gd", "slime_rei": "res://scripts/chefes/sub_slime_rei.gd",
	"mago_sombrio": "res://scripts/chefes/sub_mago_sombrio.gd", "fantasma_antigo": "res://scripts/chefes/sub_fantasma_antigo.gd"}
const ESPERA := 1.0

var nome_exibido := ""
var fases := 3               # subchefes têm 2 (fase 2 na metade da vida)
var ultima_rajada := 0      # quantos tiros saíram na última rajada (testes e robô)
var _fase := 1
var _espera := ESPERA
var _escala := 2.0


static func criar_chefe(nome: String, pos: Vector2, jogador_: Node2D, sala_: Node2D, semente: int) -> Chefe:
	var caminho: String = SCRIPTS.get(nome, SCRIPTS["rei"])
	if not ResourceLoader.exists(caminho):
		caminho = SCRIPTS["rei"]
	var script: Variant = load(caminho)
	var c: Chefe = script.new() if script else null
	if c == null:   # script com erro: não derruba o jogo
		c = load(SCRIPTS["rei"]).new()
	c._montar(nome, pos, jogador_, sala_, semente)
	c.hp = VIDA_CHEFE.get(nome, 45)
	c.hp_max = c.hp
	c.nome_exibido = NOMES.get(nome, nome.to_upper())
	c.add_to_group("chefe")
	if nome in SUBCHEFES:
		c.fases = 2
	c._ajustar_escala(c._escala)
	c._preparar()
	return c


func _ajustar_escala(e: float) -> void:
	_escala = e
	Visual.aplicar(_sprite, _sprite.get_meta("visual_nome", "rei"), e, 2)
	var r := (get_node("Corpo") as CollisionShape2D).shape as RectangleShape2D
	r.size = Vector2(11, 10) * e


func escala() -> float:
	return _escala


func fase() -> int:
	return _fase


func _forca_empurrao() -> float:
	return 0.0


func _ia(delta: float) -> void:
	if _espera > 0.0:
		_espera -= delta
		velocity = Vector2.ZERO
		return
	var f := (1 if hp > hp_max * 2 / 3 else (2 if hp > hp_max / 3 else 3)) if fases == 3 \
		else (1 if hp > hp_max / 2 else 2)
	while _fase < f:   # dano grande de uma vez não pula fase (cada uma tem seu efeito)
		_fase += 1
		fase_mudou.emit(_fase)
		_ao_mudar_fase(_fase)
	_agir(delta)


func _preparar() -> void:
	pass


func _agir(_delta: float) -> void:
	velocity = Vector2.ZERO


func _ao_mudar_fase(_f: int) -> void:
	pass


func invocar(t: String, pos: Vector2) -> void:
	if sala.has_method("invocar"):
		sala.call("invocar", t, pos)


func atirar(dir: Vector2, vel := 80.0, dur := 3.0, de := Vector2.INF) -> Tiro:
	var origem := position + dir * 12.0 if de == Vector2.INF else de
	var t := Tiro.criar(origem, dir, false, 1, vel, dur)
	sala.add_child(t)
	return t


func rajada(n: int, vel := 80.0, giro := 0.0) -> void:
	for i in n:
		atirar(Vector2.RIGHT.rotated(giro + TAU * i / n), vel)
	ultima_rajada = n
	Sons.tocar("acerto")


func invocados_vivos(t: String) -> int:
	return sala.call("invocados_vivos", t) if sala.has_method("invocados_vivos") else 0
