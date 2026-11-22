## Subchefe Fantasma Antigo (30): persegue atravessando pilares; a cada 4 s some por 1 s
## (invulnerável, sem contato) e pisca 0,4 s antes de reaparecer. Fase 2 mais rápido.
extends Chefe

var _estado_f := "perseguir"


func _preparar() -> void:
	_ajustar_escala(1.6)
	collision_mask = Camadas.PAREDE
	_t = 4.0


func estado_atual() -> String:
	return _estado_f


func invulneravel() -> bool:
	return _estado_f == "invisivel"


func perigoso() -> bool:
	return super() and _estado_f == "perseguir"


func _agir(_delta: float) -> void:
	match _estado_f:
		"perseguir":
			velocity = _para_jogador() * (35.0 if _fase == 1 else 48.0)
			_sprite.modulate.a = 0.8
			if _t <= 0.0:
				_estado_f = "invisivel"
				_t = 1.0
		"invisivel":
			velocity = _para_jogador() * 20.0
			_sprite.modulate.a = 0.0
			if _t <= 0.0:
				_estado_f = "reaparecer"
				_t = 0.4
		"reaparecer":
			velocity = Vector2.ZERO
			_sprite.modulate.a = 0.6 if int(_t * 20.0) % 2 == 0 else 0.15
			if _t <= 0.0:
				_estado_f = "perseguir"
				_t = 4.0
				if _fase == 2:
					rajada(6, 70.0)
