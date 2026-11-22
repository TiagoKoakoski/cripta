## Projétil (do jogador ou de inimigo). Some ao bater em parede/pilar ou acertar o alvo.
## Os itens de tiro mudam o comportamento: ricochete, perfurante, teleguiado, explosivo, gelo.
class_name Tiro
extends Area2D

const RAIO_EXPLOSAO := 22.0
const GIRO_GUIADO := 4.5     # rad/s que o teleguiado consegue curvar
const ALCANCE_GUIADO := 140.0

var direcao := Vector2.RIGHT
var velocidade := 180.0
var vida := 0.6
var dano := 1
var do_jogador := true
var ricochetes := 0
var perfura := false
var guiado := false
var explode := false
var gelo := false
var _acertados := {}
var _imune_parede := 0.0
var _ultimo_quique: Node


static func criar(pos: Vector2, dir: Vector2, jogador: bool, dano_: int, vel := 180.0, duracao := 0.6) -> Tiro:
	var t := Tiro.new()
	t.position = pos
	t.direcao = dir.normalized()
	t.do_jogador = jogador
	t.dano = dano_
	t.velocidade = vel
	t.vida = duracao
	var s := Sprite2D.new()
	s.texture = load("res://arte/%s.png" % ("tiro" if jogador else "tiro_inimigo"))
	t.add_child(s)
	var c := CollisionShape2D.new()
	var forma := CircleShape2D.new()
	forma.radius = 3.0
	c.shape = forma
	t.add_child(c)
	t.collision_layer = Camadas.TIRO_JOGADOR if jogador else Camadas.TIRO_INIMIGO
	t.collision_mask = Camadas.PAREDE | Camadas.PILAR | (Camadas.INIMIGO if jogador else Camadas.JOGADOR)
	t.add_to_group("tiro_jogador" if jogador else "tiro_inimigo")
	t.body_entered.connect(t._bateu)
	return t


## Copia os efeitos de tiro da build atual e pinta o tiro conforme eles.
func aplicar_build(p: Partida) -> void:
	ricochetes = 1 if p.ricochete else 0
	perfura = p.perfurante
	guiado = p.teleguiado
	explode = p.explosivo
	gelo = p.gelo
	modulate = cor_da_build(p)


static func cor_da_build(p: Partida) -> Color:
	if p.gelo:
		return Color(0.6, 0.85, 1.0)
	if p.explosivo:
		return Color(1.0, 0.6, 0.3)
	if p.teleguiado:
		return Color(0.85, 0.6, 1.0)
	if p.perfurante:
		return Color(0.75, 1.0, 0.7)
	return Color.WHITE


func _physics_process(delta: float) -> void:
	if guiado:
		var alvo := _alvo_mais_perto()
		if alvo:
			var desejada := (alvo.global_position - global_position).normalized()
			var ang := direcao.angle_to(desejada)
			direcao = direcao.rotated(clampf(ang, -GIRO_GUIADO * delta, GIRO_GUIADO * delta))
	position += direcao * velocidade * delta
	rotation = direcao.angle()
	_imune_parede = maxf(0.0, _imune_parede - delta)
	vida -= delta
	if vida <= 0.0:
		queue_free()


func _alvo_mais_perto() -> Node2D:
	var melhor: Node2D = null
	var d_melhor := ALCANCE_GUIADO
	for n: Node in get_tree().get_nodes_in_group("inimigo"):
		var e := n as Inimigo
		if e == null or not e.vivo() or _acertados.has(e.get_instance_id()):
			continue
		var d := global_position.distance_to(e.global_position)
		if d < d_melhor:
			melhor = e
			d_melhor = d
	return melhor


func _bateu(corpo: Node) -> void:
	if is_queued_for_deletion():
		return
	if corpo is StaticBody2D:
		if _imune_parede > 0.0 and corpo == _ultimo_quique:
			return
		if ricochetes > 0:
			ricochetes -= 1
			_ultimo_quique = corpo
			_quicar(corpo as StaticBody2D)
			return
		queue_free()
		return
	if do_jogador and corpo is Inimigo:
		var e := corpo as Inimigo
		if _acertados.has(e.get_instance_id()) or not e.vivo():
			return
		_acertados[e.get_instance_id()] = true
		e.levar_tiro(dano, direcao)
		if gelo:
			e.congelar(2.0)
		if explode:
			_explodir(e)
		if perfura:
			return
	elif not do_jogador and corpo is Jogador:
		(corpo as Jogador).ferir()
	queue_free()


func _quicar(b: StaticBody2D) -> void:
	var d := global_position - b.global_position
	if absf(d.x) > absf(d.y):
		direcao.x = absf(direcao.x) * signf(d.x)
	else:
		direcao.y = absf(direcao.y) * signf(d.y)
	_imune_parede = 0.08
	position += direcao * 3.0


func _explodir(atingido: Inimigo) -> void:
	Tiro.explodir_em(get_parent(), global_position, dano, atingido)


## explosão (metade do dano, mínimo 1) nos inimigos vivos a até RAIO_EXPLOSAO de `pos`
static func explodir_em(pai: Node, pos: Vector2, dano_: int, excluido: Inimigo) -> void:
	var dano_area := maxi(1, dano_ / 2)
	for n: Node in pai.get_tree().get_nodes_in_group("inimigo"):
		var e := n as Inimigo
		if e == null or e == excluido or not e.vivo():
			continue
		if e.global_position.distance_to(pos) <= RAIO_EXPLOSAO:
			e.levar_tiro(dano_area, (e.global_position - pos).normalized())
	Efeitos.explosao(pai, pos)
