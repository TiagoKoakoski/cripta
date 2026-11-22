## Olho do Abismo (65): vai para o centro e solta espirais de 16 tiros. Fase 2: 4 olhinhos orbitam e
## ele só leva dano depois que todos morrem. Fase 3: feixe giratório (aviso de 1 s piscando).
extends Chefe

const CENTRO := Vector2(160, 80)

var _estado_o := "espiral"
var _n := 0
var _giro := 0.0
var _olhinhos: Array = []
var _orbita := 0.0
var _linha: Line2D
var _dir_feixe := Vector2.RIGHT


func _preparar() -> void:
	_ajustar_escala(2.0)
	_t = 0.6


func estado_atual() -> String:
	return _estado_o


func invulneravel() -> bool:
	for o: Variant in _olhinhos:
		if is_instance_valid(o) and (o as Inimigo).vivo():
			return true
	return false


func _agir(delta: float) -> void:
	velocity = (CENTRO - position).limit_length(1.0) * 20.0 if position.distance_to(CENTRO) > 2.0 else Vector2.ZERO
	_orbita += delta * 1.5
	var vivos := _olhinhos.filter(func(o: Variant) -> bool: return is_instance_valid(o) and (o as Inimigo).vivo())
	for i in vivos.size():
		(vivos[i] as Node2D).position = position + Vector2(30, 0).rotated(_orbita + TAU * i / 4.0)
	_sprite.modulate = Color(0.7, 0.7, 1.0) if invulneravel() else _sprite.modulate
	match _estado_o:
		"pausa":
			if _t <= 0.0:
				if _fase == 3:
					_estado_o = "aviso_feixe"
					_t = 1.0
					_dir_feixe = _para_jogador().rotated(-0.8)
				else:
					_estado_o = "espiral"
					_n = 0
		"espiral":
			if _t <= 0.0:
				_giro += 0.42
				atirar(Vector2.RIGHT.rotated(_giro), 70.0)
				_n += 1
				_t = 0.12 if _fase == 1 else 0.16
				if _n >= 16:
					ultima_rajada = 16
					_estado_o = "pausa"
					_t = 1.2
		"aviso_feixe":
			_mostrar_linha(int(_t * 10.0) % 2 == 0)
			if _t <= 0.0:
				_mostrar_linha(false)
				_estado_o = "feixe"
				_t = 2.4
				_n = 0
		"feixe":
			_dir_feixe = _dir_feixe.rotated(0.9 * delta)
			_n += 1
			if _n % 4 == 0:
				atirar(_dir_feixe, 150.0, 2.0)
			if _t <= 0.0:
				_estado_o = "espiral"
				_n = 0
				_t = 0.8


func _ao_mudar_fase(f: int) -> void:
	if f == 2:
		for i in 4:
			var o_pos := position + Vector2(30, 0).rotated(TAU * i / 4.0)
			invocar("olhinho", o_pos)
		_olhinhos = sala._inimigos.filter(func(e: Variant) -> bool:
			return is_instance_valid(e) and (e as Inimigo).tipo == "olhinho")


func _mostrar_linha(sim: bool) -> void:
	if _linha == null:
		_linha = Line2D.new()
		_linha.width = 3.0
		_linha.default_color = Color(0.5, 0.9, 1.0, 0.7)
		_linha.z_index = -3
		add_child(_linha)
	_linha.visible = sim
	_linha.points = PackedVector2Array([Vector2.ZERO, _dir_feixe * 300.0])
