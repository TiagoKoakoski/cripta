## Herói: anda em 8 direções e atira em 4 (twin-stick). O estado (vida, build) mora em Partida.
class_name Jogador
extends CharacterBody2D

signal ferido
signal morreu
signal atacou(dir: Vector2)

var partida: Partida
var sala: Node2D
var _recarga := 0.0
var _passo := 0.0
var _olhar := Vector2.DOWN
var _sprite: Sprite2D
var _corpo: Area2D
var _andando := false
var arma: RefCounted   # ArmaTiro ou ArmaLamina


static func criar(p: Partida, sala_: Node2D, pos: Vector2) -> Jogador:
	var j := Jogador.new()
	j.partida = p
	j.sala = sala_
	match p.personagem:
		"espadachim": j.arma = ArmaLamina.new()
		"alquimista": j.arma = ArmaFrasco.new()
		"cacador": j.arma = ArmaBumerangue.new()
		_: j.arma = ArmaTiro.new()
	j.position = pos
	j.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	j.collision_layer = Camadas.JOGADOR
	j.collision_mask = Camadas.PAREDE | Camadas.PILAR
	Efeitos.sombra_para(j, 1.0)
	j._sprite = Sprite2D.new()
	Visual.aplicar(j._sprite, Jogador.sprite_de(p.personagem), 1.0, 8)
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


static func sprite_de(quem: String) -> String:
	return "heroi" if quem == "atirador" else quem


func _physics_process(delta: float) -> void:
	if partida.morto():
		return
	partida.avancar(delta)
	var mover := Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")
	velocity = mover * partida.velocidade * (0.5 if partida.lentidao_jogador > 0.0 else 1.0)
	move_and_slide()
	var mira := _direcao_tiro()
	if mira != Vector2.ZERO:
		_olhar = mira
	elif mover != Vector2.ZERO:
		_olhar = _cardinal(mover)
	_recarga = maxf(0.0, _recarga - delta)
	if mira != Vector2.ZERO and _recarga == 0.0:
		_atirar(mira)
	_andando = mover != Vector2.ZERO
	_passo += delta * (1.0 if _andando else 0.0)
	_animar()
	for corpo: Node2D in _corpo.get_overlapping_bodies():
		if corpo is Inimigo and (corpo as Inimigo).perigoso():
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
	if arma.atacar(self, dir):
		atacou.emit(dir)


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
	if _sprite.hframes == 4:   # detalhado: 1 quadro por direção e um balanço ao andar
		_sprite.frame = base / 2
		_sprite.offset.y = -absf(sin(_passo * 10.0)) * 3.0 if _andando else 0.0
	else:
		_sprite.frame = base + (int(_passo * 6.0) % 2)
		_sprite.offset.y = 0.0
	visible = partida.invencivel <= 0.0 or int(partida.invencivel * 15.0) % 2 == 0
