## Aranha Rainha (55): anda de lado e atira 3 teias lentas que viram poças (jogador lento);
## fase 2 invoca 2 aranhas (repõe a cada 7 s); fase 3 faz investidas curtas avisadas por 0,5 s.
extends Chefe

var _estado_r := "andar"
var _lado := 1.0
var _repor := 7.0
var _dir_investida := Vector2.ZERO


func estado_atual() -> String:
	return _estado_r


func _agir(delta: float) -> void:
	if _fase >= 2:
		_repor -= delta
		if _repor <= 0.0:
			_repor = 7.0
			_invocar_aranhas()
	match _estado_r:
		"andar":
			var para := _para_jogador()
			velocity = (para.orthogonal() * _lado * 45.0 + para * 15.0)
			if is_on_wall():
				_lado = -_lado
			if _t <= 0.0:
				_teias()
				if _fase == 3:
					_estado_r = "aviso"
					_t = 0.5
				else:
					_t = 1.8
		"aviso":
			velocity = Vector2.ZERO
			_sprite.modulate = Color(1, 0.3, 0.3) if int(_t * 16.0) % 2 == 0 else Color.WHITE
			if _t <= 0.0:
				_estado_r = "investida"
				_dir_investida = _para_jogador()
				_t = 0.35
		"investida":
			velocity = _dir_investida * 210.0
			if _t <= 0.0:
				_estado_r = "andar"
				_t = 1.4


func _teias() -> void:
	var alvo := _para_jogador()
	for a: float in [-0.35, 0.0, 0.35]:
		var t := atirar(alvo.rotated(a), 55.0, 1.0)
		t.vira_poca = true
		t.modulate = Color(0.9, 0.9, 1.0)
	ultima_rajada = 3


func _invocar_aranhas() -> void:
	for d: Vector2 in [Vector2(-28, 10), Vector2(28, 10)]:
		if invocados_vivos("aranha") < 2:
			invocar("aranha", position + d)


func _ao_mudar_fase(f: int) -> void:
	if f == 2:
		_invocar_aranhas()
		_repor = 7.0
