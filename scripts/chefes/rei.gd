## Rei Esqueleto (45): persegue e solta rajada em cruz; fase 2 em 8 direções; fase 3 invoca até 2
## esqueletos e solta espiral de 12 tiros.
extends Chefe

var _estado_rei := "perseguir"
var _espiral := 0
var _giro := 0.0


func _agir(delta: float) -> void:
	_t -= delta
	match _estado_rei:
		"perseguir":
			velocity = _para_jogador() * [0.0, 40.0, 50.0, 55.0][_fase]
			if _t <= 0.0:
				_estado_rei = "rajada"
				_t = 0.5
		"rajada":
			velocity = Vector2.ZERO
			_sprite.modulate = Color(1, 0.8, 0.5) if int(_t * 12.0) % 2 == 0 else Color.WHITE  # aviso
			if _t <= 0.0:
				if _fase == 1:
					rajada(4)
				elif _fase == 2:
					rajada(8)
				else:
					if invocados_vivos("esqueleto") < 2:
						for d: Vector2 in [Vector2(-40, 0), Vector2(40, 0)]:
							if invocados_vivos("esqueleto") < 2:
								invocar("esqueleto", position + d)
					_estado_rei = "espiral"
					_espiral = 0
					_t = 0.0
					return
				_estado_rei = "perseguir"
				_t = 2.0
		"espiral":
			velocity = Vector2.ZERO
			if _t <= 0.0:
				_giro += TAU / 12.0 + 0.15
				atirar(Vector2.RIGHT.rotated(_giro), 75.0)
				_espiral += 1
				_t = 0.05
				if _espiral >= 12:
					ultima_rajada = 12
					_estado_rei = "perseguir"
					_t = 2.2
