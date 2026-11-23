## Frasco do Alquimista: voa em arco até `alvo` (0,45 s) e explode em área ao cair.
class_name Frasco
extends Node2D

const VOO := 0.45

var partida: Partida
var alvo := Vector2.ZERO
var raio := 20.0
var quiques := 0          # ricochete: quica uma vez e explode de novo
var _de := Vector2.ZERO
var _t := 0.0
var _dir := Vector2.RIGHT
var _sprite: Sprite2D


static func lancar(pai: Node, p: Partida, de: Vector2, alvo_: Vector2, raio_: float) -> Frasco:
	var f := Frasco.new()
	f.partida = p
	f.position = de
	f._de = de
	f.alvo = alvo_.clamp(Vector2(24, 24), Vector2(296, 152))
	f._dir = (f.alvo - de).normalized()
	f.raio = raio_
	f.quiques = 1 if p.ricochete else 0
	f.z_index = 3
	f._sprite = Sprite2D.new()
	Visual.aplicar(f._sprite, "frasco")
	f.add_child(f._sprite)
	pai.add_child(f)
	return f


func _physics_process(delta: float) -> void:
	_t += delta
	var k := clampf(_t / VOO, 0.0, 1.0)
	position = _de.lerp(alvo, k)
	_sprite.position.y = -sin(k * PI) * 14.0
	_sprite.rotation += delta * 12.0
	if k >= 1.0:
		_explodir()


func _explodir() -> void:
	for n: Node in get_tree().get_nodes_in_group("inimigo"):
		var e := n as Inimigo
		if e == null or not e.vivo():
			continue
		if e.position.distance_to(position) <= raio + 4.0:
			e.levar_tiro(partida.dano, (e.position - position).normalized())
			if partida.gelo and e.vivo():
				e.congelar(2.0)
	if partida.perfurante:
		PocaFogo.criar(get_parent(), position, 2.0, true, 12.0)
	Efeitos.explosao(get_parent(), position)
	Sons.tocar("acerto")
	if quiques > 0:
		quiques -= 1
		_de = position
		alvo = (position + _dir * 40.0).clamp(Vector2(24, 24), Vector2(296, 152))
		_t = VOO * 0.4
		return
	queue_free()
