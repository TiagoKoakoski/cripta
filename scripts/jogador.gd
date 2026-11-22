## Herói: anda em 8 direções e atira em 4 (twin-stick). O estado (vida, build) mora em Partida.
class_name Jogador
extends CharacterBody2D

signal ferido
signal morreu

var partida: Partida
var sala: Node2D
var _recarga := 0.0
var _passo := 0.0
var _olhar := Vector2.DOWN
var _sprite: Sprite2D
var _corpo: Area2D


static func criar(p: Partida, sala_: Node2D, pos: Vector2) -> Jogador:
	var j := Jogador.new()
	j.partida = p
	j.sala = sala_
	j.position = pos
	j.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	j.collision_layer = Camadas.JOGADOR
	j.collision_mask = Camadas.PAREDE | Camadas.PILAR
	j._sprite = Sprite2D.new()
	j._sprite.texture = load("res://arte/heroi.png")
	j._sprite.hframes = 8
	j.add_child(j._sprite)
	var c := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(10, 8)
	c.shape = r
	c.position = Vector2(0, 4)
	j.add_child(c)
	j._corpo = Area2D.new()
	j._corpo.collision_layer = 0
	j._corpo.collision_mask = Camadas.INIMIGO
	var c2 := CollisionShape2D.new()
	var r2 := RectangleShape2D.new()
	r2.size = Vector2(10, 12)
	c2.shape = r2
	c2.position = Vector2(0, 2)
	j._corpo.add_child(c2)
	j.add_child(j._corpo)
	j.add_to_group("jogador")
	return j


func _physics_process(delta: float) -> void:
	if partida.morto():
		return
	partida.avancar(delta)
	var mover := Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")
	velocity = mover * partida.velocidade
	move_and_slide()
	var mira := _direcao_tiro()
	if mira != Vector2.ZERO:
		_olhar = mira
	elif mover != Vector2.ZERO:
		_olhar = _cardinal(mover)
	_recarga = maxf(0.0, _recarga - delta)
	if mira != Vector2.ZERO and _recarga == 0.0:
		_atirar(mira)
	_passo += delta * (1.0 if mover != Vector2.ZERO else 0.0)
	_animar()
	for corpo: Node2D in _corpo.get_overlapping_bodies():
		if corpo is Inimigo and (corpo as Inimigo).vivo():
			ferir()
			break


func _direcao_tiro() -> Vector2:
	var v := Input.get_vector("atirar_esquerda", "atirar_direita", "atirar_cima", "atirar_baixo")
	return Vector2.ZERO if v.length() < 0.3 else _cardinal(v)


static func _cardinal(v: Vector2) -> Vector2:
	if absf(v.x) > absf(v.y):
		return Vector2(signf(v.x), 0)
	return Vector2(0, signf(v.y))


func _atirar(dir: Vector2) -> void:
	_recarga = partida.cadencia
	var vel := 240.0 if partida.alcance else 180.0
	var dur := 0.9 if partida.alcance else 0.6
	var dirs: Array[Vector2] = [dir]
	if partida.tiro_triplo:
		dirs.append(dir.rotated(deg_to_rad(15)))
		dirs.append(dir.rotated(deg_to_rad(-15)))
	for d: Vector2 in dirs:
		sala.add_child(Tiro.criar(position + dir * 8.0, d, true, partida.dano, vel, dur))
	Sons.tocar("tiro")


func ferir() -> void:
	if partida.levar_dano():
		Sons.tocar("dano")
		ferido.emit()
		if partida.morto():
			morreu.emit()


func _animar() -> void:
	var base := 0
	if _olhar == Vector2.RIGHT:
		base = 2
	elif _olhar == Vector2.UP:
		base = 4
	elif _olhar == Vector2.LEFT:
		base = 6
	_sprite.frame = base + (int(_passo * 6.0) % 2)
	visible = partida.invencivel <= 0.0 or int(partida.invencivel * 15.0) % 2 == 0
