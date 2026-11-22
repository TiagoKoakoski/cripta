## Subchefe Mago Sombrio (32): teleporta 2 vezes seguidas e atira leque de 5; fase 2 mais rápido.
extends Chefe

var _estado_g := "pausa"
var _saltos := 0


func _preparar() -> void:
	_ajustar_escala(1.6)


func estado_atual() -> String:
	return _estado_g


func _agir(_delta: float) -> void:
	velocity = Vector2.ZERO
	var tempo := 0.3 if _fase == 1 else 0.22
	match _estado_g:
		"pausa":
			if _t <= 0.0:
				_estado_g = "sumir"
				_t = tempo
		"sumir":
			_sprite.modulate.a = clampf(_t / tempo, 0.0, 1.0)
			if _t <= 0.0:
				position = _ponto_de_teleporte()
				_estado_g = "aparecer"
				_t = tempo
		"aparecer":
			_sprite.modulate.a = clampf(1.0 - _t / tempo, 0.0, 1.0)
			if _t <= 0.0:
				_saltos += 1
				if _saltos < 2:
					_estado_g = "sumir"
					_t = tempo
				else:
					_saltos = 0
					var alvo := _para_jogador()
					for a: float in [-0.5, -0.25, 0.0, 0.25, 0.5]:
						atirar(alvo.rotated(a), 85.0)
					ultima_rajada = 5
					_estado_g = "pausa"
					_t = 1.4 if _fase == 1 else 1.0
