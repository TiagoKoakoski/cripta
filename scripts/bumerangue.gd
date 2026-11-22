## Bumerangue do Caçador: vai até `alcance` (ou até bater) e volta para o jogador, acertando cada
## inimigo uma vez na ida e uma na volta. Na volta atravessa paredes. Some ao chegar na mão.
class_name Bumerangue
extends Area2D

const VIDA_MAX := 4.0

var dono: Jogador
var direcao := Vector2.RIGHT
var alcance := 90.0
var vel_volta := 220.0
var atravessa := false
var guiado := false
var explode_na_volta := false
var _percorrido := 0.0
var _voltando := false
var _ida := {}
var _volta := {}
var _t := 0.0


static func lancar(j: Jogador, dir: Vector2) -> Bumerangue:
	var p := j.partida
	var b := Bumerangue.new()
	b.dono = j
	b.position = j.position
	b.direcao = dir.normalized()
	b.alcance = 135.0 if p.alcance else 90.0
	b.vel_volta = 320.0 if p.ricochete else 220.0
	b.atravessa = p.perfurante
	b.guiado = p.teleguiado
	b.explode_na_volta = p.explosivo
	b.collision_layer = Camadas.TIRO_JOGADOR
	b.collision_mask = Camadas.INIMIGO | Camadas.PAREDE | Camadas.PILAR
	var s := Sprite2D.new()
	s.texture = load("res://arte/bumerangue.png") if ResourceLoader.exists("res://arte/bumerangue.png") else load("res://arte/tiro.png")
	s.name = "Sprite"
	b.add_child(s)
	var c := CollisionShape2D.new()
	var r := CircleShape2D.new()
	r.radius = 5.0
	c.shape = r
	b.add_child(c)
	b.add_to_group("bumerangue")
	b.body_entered.connect(b._tocou)
	j.sala.add_child(b)
	return b


func voltando() -> bool:
	return _voltando


func _physics_process(delta: float) -> void:
	_t += delta
	(get_node("Sprite") as Sprite2D).rotation += delta * 18.0
	if dono == null or not is_instance_valid(dono) or _t > VIDA_MAX:
		queue_free()
		return
	if not _voltando:
		if guiado:
			var alvo := _alvo()
			if alvo:
				var quer := (alvo.position - position).normalized()
				direcao = direcao.rotated(clampf(direcao.angle_to(quer), -4.0 * delta, 4.0 * delta))
		var passo := 200.0 * delta
		position += direcao * passo
		_percorrido += passo
		if _percorrido >= alcance:
			_virar()
	else:
		var para := dono.position - position
		if para.length() < 8.0:
			queue_free()
			return
		position += para.normalized() * minf(vel_volta * delta, para.length())


func _virar() -> void:
	if _voltando:
		return
	_voltando = true
	collision_mask = Camadas.INIMIGO   # na volta atravessa paredes
	if explode_na_volta:
		Tiro.explodir_em(get_parent(), position, dono.partida.dano * 2, null)


func _alvo() -> Inimigo:
	var melhor: Inimigo = null
	for n: Node in get_tree().get_nodes_in_group("inimigo"):
		var e := n as Inimigo
		if e and e.vivo() and not _ida.has(e.get_instance_id()) and e.position.distance_to(position) < 120.0:
			if melhor == null or e.position.distance_to(position) < melhor.position.distance_to(position):
				melhor = e
	return melhor


func _tocou(corpo: Node) -> void:
	if corpo is StaticBody2D:
		if not _voltando and not atravessa:
			_virar()
		return
	var e := corpo as Inimigo
	if e == null or not e.vivo():
		return
	var marcas := _volta if _voltando else _ida
	if marcas.has(e.get_instance_id()):
		return
	marcas[e.get_instance_id()] = true
	var p := dono.partida
	e.levar_tiro(p.dano, direcao if not _voltando else (dono.position - position).normalized())
	if p.gelo and e.vivo():
		e.congelar(2.0)
