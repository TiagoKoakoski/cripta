## Base dos chefes: vida da tabela, espera inicial de 1 s, fases a 2/3 e 1/3 da vida, invocações.
## (o contador _t já é decrementado por Inimigo._physics_process antes de _ia)
## Cada chefe é uma subclasse que implementa _agir(delta) e, se quiser, _ao_mudar_fase(f).
class_name Chefe
extends Inimigo

signal fase_mudou(n: int)

const VIDA_CHEFE := {"rei": 45, "slime_mae": 40, "aranha_rainha": 55, "colosso": 60, "olho_abismo": 65, "lich": 70}
const NOMES := {"rei": "REI ESQUELETO", "slime_mae": "SLIME MÃE", "aranha_rainha": "ARANHA RAINHA",
	"colosso": "COLOSSO DE OSSOS", "olho_abismo": "OLHO DO ABISMO", "lich": "LICH"}
const SCRIPTS := {"rei": "res://scripts/chefes/rei.gd", "slime_mae": "res://scripts/chefes/slime_mae.gd",
	"aranha_rainha": "res://scripts/chefes/aranha_rainha.gd", "colosso": "res://scripts/chefes/colosso.gd",
	"olho_abismo": "res://scripts/chefes/olho_abismo.gd", "lich": "res://scripts/chefes/lich.gd"}
const ESPERA := 1.0

var nome_exibido := ""
var ultima_rajada := 0      # quantos tiros saíram na última rajada (testes e robô)
var _fase := 1
var _espera := ESPERA
var _escala := 2.0


static func criar_chefe(nome: String, pos: Vector2, jogador_: Node2D, sala_: Node2D, semente: int) -> Chefe:
	var caminho: String = SCRIPTS.get(nome, SCRIPTS["rei"])
	if not ResourceLoader.exists(caminho):
		caminho = SCRIPTS["rei"]
	var c: Chefe = load(caminho).new()
	c._montar(nome, pos, jogador_, sala_, semente)
	c.hp = VIDA_CHEFE.get(nome, 45)
	c.hp_max = c.hp
	c.nome_exibido = NOMES.get(nome, nome.to_upper())
	c.add_to_group("chefe")
	c._ajustar_escala(c._escala)
	c._preparar()
	return c


func _ajustar_escala(e: float) -> void:
	_escala = e
	_sprite.scale = Vector2(e, e) * (0.5 if _sprite.texture.get_width() >= 64 else 1.0)
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
	var f := 1 if hp > hp_max * 2 / 3 else (2 if hp > hp_max / 3 else 3)
	if f > _fase:
		_fase = f
		fase_mudou.emit(f)
		_ao_mudar_fase(f)
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
