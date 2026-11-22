## Subchefe Esqueleto Capitão (20): parado, leque de 3 a cada 1,5 s; fase 2 intercala investidas
## curtas avisadas por 0,5 s.
extends Chefe

var _estado_e := "mirar"
var _dir_e := Vector2.ZERO


func _preparar() -> void:
	_ajustar_escala(1.6)


func estado_atual() -> String:
	return _estado_e


func _agir(_delta: float) -> void:
	match _estado_e:
		"mirar":
			velocity = Vector2.ZERO
			if _t <= 0.0:
				var p := _para_jogador()
				for a: float in [-0.3, 0.0, 0.3]:
					atirar(p.rotated(a), 85.0)
				ultima_rajada = 3
				if _fase == 2:
					_estado_e = "aviso"
					_t = 0.5
				else:
					_t = 1.5
		"aviso":
			velocity = Vector2.ZERO
			_sprite.modulate = Color(1, 0.3, 0.3) if int(_t * 16.0) % 2 == 0 else Color.WHITE
			if _t <= 0.0:
				_estado_e = "investida"
				_dir_e = _para_jogador()
				_t = 0.3
		"investida":
			velocity = _dir_e * 190.0
			if _t <= 0.0:
				_estado_e = "mirar"
				_t = 1.2
