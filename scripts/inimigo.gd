## Inimigos: morcego (mergulha e recua, voa por cima de pilares), slime (anda à toa; o grande se
## divide em 2 pequenos), esqueleto (parado, atira no jogador), aranha (saltos curtos), fantasma
## (persegue atravessando pilares), olho (rajadas em cruz e em X), mago (teletransporta e atira
## leque), rei (chefe). Todo inimigo leva SURGIMENTO s para aparecer, sem agir nem ferir.
class_name Inimigo
extends CharacterBody2D

signal morreu(inimigo: Inimigo, tipo: String, pos: Vector2)

const VIDA := {"morcego": 2, "slime": 3, "slime_pequeno": 1, "esqueleto": 3, "rei": 30,
	"aranha": 2, "fantasma": 3, "olho": 4, "mago": 4, "olhinho": 3, "lich_copia": 1, "sombra_menor": 8}
const SURGIMENTO := 0.5
const VOADORES := ["morcego", "fantasma", "olhinho"]   # passam por cima dos pilares
const COR_MORTE := {"morcego": Color(0.6, 0.4, 0.8), "slime": Color(0.4, 0.8, 0.4),
	"slime_pequeno": Color(0.5, 0.9, 0.5), "esqueleto": Color(0.9, 0.88, 0.8), "rei": Color(1, 0.8, 0.3),
	"aranha": Color(1, 0.6, 0.35), "fantasma": Color(0.85, 0.92, 1), "olho": Color(1, 0.4, 0.5),
	"mago": Color(0.5, 1, 0.8)}
const SPRITE := {"morcego": "morcego", "slime": "slime", "slime_pequeno": "slime_pequeno",
	"esqueleto": "esqueleto", "rei": "rei", "aranha": "aranha", "fantasma": "fantasma", "olho": "olho",
	"mago": "mago", "olhinho": "olho", "lich_copia": "lich", "sombra_menor": "sombra_gemea"}

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
var lento := 0.0          # segundos de lentidão (gelo)
var _empurrao := Vector2.ZERO
var _surgindo := SURGIMENTO
var _volta := 0           # olho: alterna cruz / X


static func criar(tipo_: String, pos: Vector2, jogador_: Node2D, sala_: Node2D, semente: int) -> Inimigo:
	var e := Inimigo.new()
	e._montar(tipo_, pos, jogador_, sala_, semente)
	return e


## nome da arte de um tipo (sem arte própria, usa a do Rei)
static func nome_sprite(tipo_: String) -> String:
	var nome: String = SPRITE.get(tipo_, tipo_)
	return nome if ResourceLoader.exists("res://arte/%s.png" % nome) else "rei"


func _montar(tipo_: String, pos: Vector2, jogador_: Node2D, sala_: Node2D, semente: int) -> void:
	tipo = tipo_
	hp = VIDA.get(tipo_, 1)
	hp_max = hp
	position = pos
	jogador = jogador_
	sala = sala_
	_rng.seed = semente
	_t = _rng.randf_range(0.3, 0.9)  # cada um começa num ritmo
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = Camadas.INIMIGO
	collision_mask = Camadas.PAREDE if tipo_ in VOADORES else Camadas.PAREDE | Camadas.PILAR | Camadas.BURACO
	Efeitos.sombra_para(self, 6.0 if tipo_ in VOADORES else 0.0)
	_sprite = Sprite2D.new()
	Visual.aplicar(_sprite, Inimigo.nome_sprite(tipo_), 1.0, 2)
	add_child(_sprite)
	var c := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 10) if tipo_ != "slime_pequeno" else Vector2(8, 7)
	c.shape = r
	c.position = Vector2(0, 2)
	c.name = "Corpo"
	add_child(c)
	add_to_group("inimigo")


## chefes sobrescrevem: invulnerável não leva dano; fator multiplica o dano; empurrão recebido
func invulneravel() -> bool:
	return false


func _fator_dano() -> float:
	return 1.0


func _forca_empurrao() -> float:
	return 130.0


## some sem "morrer" (sem sinal, sem dividir): usado quando o chefe cai e leva os invocados junto
func sumir() -> void:
	if _morto:
		return
	_morto = true
	Efeitos.morte(get_parent(), position, COR_MORTE.get(tipo, Color.WHITE))
	queue_free()


func levar_tiro(dano: int, dir := Vector2.ZERO) -> void:
	if _morto:
		return
	if invulneravel():
		Efeitos.faisca(get_parent(), position, Color(0.6, 0.6, 0.7))
		return
	hp -= ceili(dano * _fator_dano())
	_flash = 0.12
	if not surgindo():
		_empurrao = dir.normalized() * _forca_empurrao()
	Sons.tocar("acerto")
	Efeitos.faisca(get_parent(), position)
	if hp <= 0:
		_morto = true
		Sons.tocar("morte_inimigo")
		Efeitos.morte(get_parent(), position, COR_MORTE.get(tipo, Color.WHITE))
		morreu.emit(self, tipo, position)
		queue_free()


func congelar(segundos: float) -> void:
	lento = maxf(lento, segundos)


func vivo() -> bool:
	return not _morto


func surgindo() -> bool:
	return _surgindo > 0.0


## pode ferir o jogador por contato
func perigoso() -> bool:
	return vivo() and not surgindo()


func _physics_process(delta: float) -> void:
	if _morto or jogador == null:
		return
	if _surgindo > 0.0:
		_surgindo = maxf(0.0, _surgindo - delta)
		_sprite.modulate = Color(1, 1, 1, 0.3 + 0.7 * float(int(_surgindo * 20.0) % 2))
		velocity = Vector2.ZERO
		return
	_t -= delta
	_anim += delta
	_sprite.frame = int(_anim * 5.0) % _sprite.hframes
	if _sprite.hframes == 1:   # detalhado: 1 quadro, respira
		_sprite.offset.y = sin(_anim * 6.0) * 1.5
	else:
		_sprite.offset.y = 0.0
	_flash = maxf(0.0, _flash - delta)
	lento = maxf(0.0, lento - delta)
	if _flash > 0.0:
		_sprite.modulate = Color(1, 0.4, 0.4)
	elif lento > 0.0:
		_sprite.modulate = Color(0.6, 0.8, 1.0)
	else:
		_sprite.modulate = Color.WHITE
	if tipo == "fantasma":
		_sprite.modulate.a = 0.55 + 0.2 * sin(_anim * 4.0)
	_ia(delta)
	if lento > 0.0:
		velocity *= 0.5
	velocity += _empurrao
	_empurrao = _empurrao.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()
	position = position.clamp(Vector2(20, 20), Vector2(300, 156))  # nunca fora da área jogável


func _ia(_delta: float) -> void:
	match tipo:
		"morcego":
			_morcego()
		"slime", "slime_pequeno":
			_slime()
		"esqueleto":
			_esqueleto()
		"aranha":
			_aranha()
		"fantasma":
			velocity = _para_jogador() * 28.0
		"olho":
			_olho()
		"mago", "lich_copia":
			_mago()
		"olhinho":
			velocity = Vector2.ZERO   # quem move é o Olho do Abismo
		"sombra_menor":
			_sombra_menor()


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


func _aranha() -> void:
	match _estado:
		"pausa":
			velocity = Vector2.ZERO
			if _t <= 0.0:
				_estado = "salto"
				_t = 0.22
				_dir = _para_jogador().rotated(_rng.randf_range(-0.5, 0.5))
		"salto":
			velocity = _dir * 170.0
			if _t <= 0.0:
				_estado = "pausa"
				_t = _rng.randf_range(0.45, 0.8)


func _olho() -> void:
	velocity = Vector2.ZERO
	if _t <= 0.0:
		_t = 1.4
		var base := 0.0 if _volta % 2 == 0 else PI / 4.0
		_volta += 1
		for i in 4:
			var d := Vector2.RIGHT.rotated(base + PI / 2.0 * i)
			sala.add_child(Tiro.criar(position + d * 9.0, d, false, 1, 75.0, 3.0))


func _mago() -> void:
	velocity = Vector2.ZERO
	match _estado:
		"pausa":
			if _t <= 0.0:
				_estado = "sumir"
				_t = 0.35
		"sumir":
			_sprite.modulate.a = clampf(_t / 0.35, 0.0, 1.0)
			if _t <= 0.0:
				position = _ponto_de_teleporte()
				_estado = "aparecer"
				_t = 0.35
		"aparecer":
			_sprite.modulate.a = clampf(1.0 - _t / 0.35, 0.0, 1.0)
			if _t <= 0.0:
				var alvo := _para_jogador()
				for a: float in [-0.32, 0.0, 0.32]:
					var d := alvo.rotated(a)
					sala.add_child(Tiro.criar(position + d * 9.0, d, false, 1, 85.0, 3.0))
				_estado = "pausa"
				_t = 1.6


func _ponto_de_teleporte() -> Vector2:
	var pontos: Array = sala.call("pontos_livres") if sala.has_method("pontos_livres") else [position]
	var bons: Array = pontos.filter(func(p: Vector2) -> bool:
		return p.distance_to(jogador.position) >= 80.0 and p.distance_to(position) >= 40.0)
	if bons.is_empty():
		var longe: Vector2 = position
		for p: Vector2 in pontos:
			if p.distance_to(jogador.position) > longe.distance_to(jogador.position):
				longe = p
		return longe
	return bons[_rng.randi_range(0, bons.size() - 1)]


## sombra menor (fase 2 da Sombra Gêmea): espelha o jogador só na horizontal e atira a cada 1,6 s
func _sombra_menor() -> void:
	var alvo := Vector2(320.0 - jogador.position.x, jogador.position.y)
	velocity = (alvo - position).limit_length(1.0) * 80.0 if position.distance_to(alvo) > 3.0 else Vector2.ZERO
	_sprite.modulate.a = 0.75
	if _t <= 0.0:
		_t = 1.6
		var d := _para_jogador()
		sala.add_child(Tiro.criar(position + d * 9.0, d, false, 1, 90.0, 3.0))
