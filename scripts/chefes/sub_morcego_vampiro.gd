## Subchefe Morcego Vampiro (18): mergulhos em sequência; fase 2 chama 2 morcegos e fica mais rápido.
extends Chefe

var _estado_m := "pausa"
var _dir_m := Vector2.ZERO


func _preparar() -> void:
	_ajustar_escala(1.6)
	collision_mask = Camadas.PAREDE   # voa por cima dos pilares


func estado_atual() -> String:
	return _estado_m


func _agir(_delta: float) -> void:
	var rapido := 1.25 if _fase == 2 else 1.0
	match _estado_m:
		"pausa":
			velocity = Vector2.ZERO
			if _t <= 0.0:
				_estado_m = "mergulho"
				_t = 0.8
		"mergulho":
			velocity = _para_jogador() * 110.0 * rapido
			if _t <= 0.0 or position.distance_to(jogador.position) < 14.0:
				_estado_m = "recuo"
				_t = 0.4
				_dir_m = -_para_jogador()
		"recuo":
			velocity = _dir_m * 100.0
			if _t <= 0.0:
				_estado_m = "pausa"
				_t = 0.6 / rapido


func _ao_mudar_fase(_f: int) -> void:
	for d: Vector2 in [Vector2(-30, 0), Vector2(30, 0)]:
		invocar("morcego", position + d)
