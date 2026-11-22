## Cavaleiro sem Cabeça (45): mira (linha de aviso 0,7 s) e investe até bater; depois arremessa a
## cabeça, que persegue o jogador por 3 s. Fase 3: a investida deixa rastro de fogo.
extends Chefe

var _estado_c := "pausa"
var _dir_c := Vector2.ZERO
var _linha: Line2D
var _rastro := 0.0


func _preparar() -> void:
	_t = 0.4


func estado_atual() -> String:
	return _estado_c


func _agir(delta: float) -> void:
	match _estado_c:
		"pausa":
			velocity = _para_jogador() * 25.0
			if _t <= 0.0:
				_estado_c = "mirar"
				_t = 0.7
		"mirar":
			velocity = Vector2.ZERO
			_dir_c = _para_jogador()
			_mostrar_linha(true)
			if _t <= 0.0:
				_mostrar_linha(false)
				_estado_c = "investida"
				_t = 3.0
		"investida":
			velocity = _dir_c * 230.0
			if _fase == 3:
				_rastro -= delta
				if _rastro <= 0.0:
					_rastro = 0.06
					PocaFogo.criar(sala, position, 3.0)
			var bateu := get_slide_collision_count() > 0 or position.x <= 21.0 or position.x >= 299.0 \
				or position.y <= 21.0 or position.y >= 155.0
			if (bateu and _t < 2.9) or _t <= 0.0:
				velocity = Vector2.ZERO
				_estado_c = "arremesso"
				_t = 0.4
		"arremesso":
			velocity = Vector2.ZERO
			if _t <= 0.0:
				var cabeca := atirar(_para_jogador(), 70.0, 3.0)
				cabeca.guiado_jogador = jogador
				cabeca.scale = Vector2(1.6, 1.6)
				ultima_rajada = 1
				if _fase >= 2:
					for a: float in [-0.5, 0.5]:
						atirar(_para_jogador().rotated(a), 85.0)
				_estado_c = "pausa"
				_t = [0.0, 1.4, 1.1, 0.8][_fase]


func _mostrar_linha(sim: bool) -> void:
	if _linha == null:
		_linha = Line2D.new()
		_linha.width = 2.0
		_linha.default_color = Color(1, 0.45, 0.2, 0.6)
		_linha.z_index = -3
		add_child(_linha)
	_linha.visible = sim
	_linha.points = PackedVector2Array([Vector2.ZERO, _dir_c * 300.0])
