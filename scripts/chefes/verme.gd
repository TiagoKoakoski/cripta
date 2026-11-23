## Verme de Ossos (55): cava (invulnerável, sem contato) indo para baixo do jogador; o chão treme por
## 0,8 s no ponto onde vai sair; sai com anel de 10 tiros e fica exposto. Fase 3: sai 2 vezes seguidas.
extends Chefe

var _estado_v := "exposto"
var _saidas := 0
var _tremor: Sprite2D


func _preparar() -> void:
	_t = 0.6


func estado_atual() -> String:
	return _estado_v


func invulneravel() -> bool:
	return _estado_v in ["enterrado", "tremor"]


func perigoso() -> bool:
	return super() and not invulneravel()


func aviso_ativo() -> bool:
	return _estado_v == "tremor"


func _agir(_delta: float) -> void:
	match _estado_v:
		"exposto":
			velocity = _para_jogador() * 22.0
			_sprite.visible = true
			if _t <= 0.0:
				_enterrar()
		"enterrado":
			velocity = (jogador.position - position).limit_length(1.0) * 90.0
			if _t <= 0.0:
				_estado_v = "tremor"
				_t = 0.8
				_mostrar_tremor(true)
		"tremor":
			velocity = Vector2.ZERO
			if _tremor:
				_tremor.position = position + Vector2(randf_range(-1.5, 1.5), 4.0)
			if _t <= 0.0:
				_mostrar_tremor(false)
				_estado_v = "emergir"
				_t = 0.3
				_sprite.visible = true
				collision_layer = Camadas.INIMIGO
				rajada(10, 80.0, _rng.randf() * TAU)
				_saidas += 1
		"emergir":
			velocity = Vector2.ZERO
			if _t <= 0.0:
				if _fase == 3 and _saidas < 2:
					_enterrar(0.6)
				else:
					_saidas = 0
					_estado_v = "exposto"
					_t = [0.0, 1.8, 1.5, 1.3][_fase]


func _enterrar(tempo := 1.2) -> void:
	_estado_v = "enterrado"
	_t = tempo
	_sprite.visible = false
	collision_layer = 0
	Efeitos.morte(get_parent(), position, Color(0.55, 0.45, 0.3))


func _mostrar_tremor(sim: bool) -> void:
	if _tremor == null or not is_instance_valid(_tremor):
		_tremor = Sprite2D.new()
		Visual.aplicar(_tremor, "sombra")
		_tremor.modulate = Color(0.6, 0.45, 0.25, 0.9)
		_tremor.scale = Vector2(2.4, 3.0)
		_tremor.z_index = -4
		sala.add_child(_tremor)
	_tremor.visible = sim


func _exit_tree() -> void:
	if _tremor and is_instance_valid(_tremor):
		_tremor.queue_free()
