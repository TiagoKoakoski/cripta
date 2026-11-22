## Inimigos: morcego (mergulha e recua, voa por cima de pilares), slime (anda à toa; o grande se
## divide em 2 pequenos), esqueleto (parado, atira no jogador), rei (chefe).
class_name Inimigo
extends CharacterBody2D

signal morreu(inimigo: Inimigo, tipo: String, pos: Vector2)

const VIDA := {"morcego": 2, "slime": 3, "slime_pequeno": 1, "esqueleto": 3, "rei": 30}
const SPRITE := {"morcego": "morcego", "slime": "slime", "slime_pequeno": "slime_pequeno",
	"esqueleto": "esqueleto", "rei": "rei"}

var tipo := "morcego"
var hp := 1
var hp_max := 1
var jogador: Node2D
var sala: Node2D
var _estado := "pausa"
var _t := 0.0
var _dir := Vector2.ZERO
var _anim := 0.0
var _flash := 0.0
var _sprite: Sprite2D
var _rng := RandomNumberGenerator.new()
var _morto := false


static func criar(tipo_: String, pos: Vector2, jogador_: Node2D, sala_: Node2D, semente: int) -> Inimigo:
	var e := Inimigo.new()
	e.tipo = tipo_
	e.hp = VIDA[tipo_]
	e.hp_max = e.hp
	e.position = pos
	e.jogador = jogador_
	e.sala = sala_
	e._rng.seed = semente
	e._t = e._rng.randf_range(0.3, 0.9)  # cada um começa num ritmo
	e.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	e.collision_layer = Camadas.INIMIGO
	e.collision_mask = Camadas.PAREDE if tipo_ == "morcego" else Camadas.PAREDE | Camadas.PILAR
	e._sprite = Sprite2D.new()
	e._sprite.texture = load("res://arte/%s.png" % SPRITE[tipo_])
	e._sprite.hframes = 2
	e.add_child(e._sprite)
	var c := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 10) if tipo_ != "slime_pequeno" else Vector2(8, 7)
	c.shape = r
	c.position = Vector2(0, 2)
	e.add_child(c)
	e.add_to_group("inimigo")
	return e


func levar_tiro(dano: int) -> void:
	if _morto:
		return
	hp -= dano
	_flash = 0.12
	Sons.tocar("acerto")
	if hp <= 0:
		_morto = true
		Sons.tocar("morte_inimigo")
		morreu.emit(self, tipo, position)
		queue_free()


func vivo() -> bool:
	return not _morto


func _physics_process(delta: float) -> void:
	if _morto or jogador == null:
		return
	_t -= delta
	_anim += delta
	_sprite.frame = int(_anim * 5.0) % 2
	_flash = maxf(0.0, _flash - delta)
	_sprite.modulate = Color(1, 0.4, 0.4) if _flash > 0.0 else Color.WHITE
	match tipo:
		"morcego":
			_morcego()
		"slime", "slime_pequeno":
			_slime()
		"esqueleto":
			_esqueleto()
		"rei":
			_rei()
	move_and_slide()


func _para_jogador() -> Vector2:
	return (jogador.position - position).normalized()


func _morcego() -> void:
	match _estado:
		"pausa":
			velocity = Vector2.ZERO
			if _t <= 0.0:
				_estado = "mergulho"
				_t = 1.6
		"mergulho":
			velocity = _para_jogador() * 75.0
			if _t <= 0.0 or position.distance_to(jogador.position) < 12.0:
				_estado = "recuo"
				_t = 0.5
				_dir = -_para_jogador()
		"recuo":
			velocity = _dir * 90.0
			if _t <= 0.0:
				_estado = "pausa"
				_t = 0.4


func _slime() -> void:
	if _t <= 0.0:
		_t = _rng.randf_range(0.7, 1.3)
		_dir = Vector2.from_angle(_rng.randf() * TAU) if _rng.randf() < 0.75 else _para_jogador()
	velocity = _dir * (45.0 if tipo == "slime_pequeno" else 30.0)


func _esqueleto() -> void:
	velocity = Vector2.ZERO
	if _t <= 0.0:
		_t = _rng.randf_range(1.8, 2.4)
		sala.add_child(Tiro.criar(position + _para_jogador() * 8.0, _para_jogador(), false, 1, 90.0, 3.0))


func _rei() -> void:
	match _estado:
		"pausa", "perseguir":
			if _estado == "pausa":
				_estado = "perseguir"
				_t = 2.0
			velocity = _para_jogador() * (40.0 if hp > hp_max / 2 else 55.0)
			if _t <= 0.0:
				_estado = "rajada"
				_t = 0.6
		"rajada":
			velocity = Vector2.ZERO
			if _t <= 0.0:
				var n := 4 if hp > hp_max / 2 else 8
				for i in n:
					var d := Vector2.RIGHT.rotated(TAU * i / n)
					sala.add_child(Tiro.criar(position + d * 10.0, d, false, 1, 80.0, 3.0))
				Sons.tocar("acerto")
				_estado = "pausa"
