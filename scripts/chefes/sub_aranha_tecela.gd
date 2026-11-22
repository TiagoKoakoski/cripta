## Subchefe Aranha Tecelã (26): anda de lado e atira teias em cruz que viram poças; fase 2 em 8 direções.
extends Chefe

var _lado := 1.0


func _preparar() -> void:
	_ajustar_escala(1.6)


func _agir(_delta: float) -> void:
	var para := _para_jogador()
	velocity = para.orthogonal() * _lado * 35.0
	if is_on_wall():
		_lado = -_lado
	if _t <= 0.0:
		_t = 2.0
		var n := 4 if _fase == 1 else 8
		for i in n:
			var t := atirar(Vector2.RIGHT.rotated(TAU * i / n), 60.0, 1.1)
			t.vira_poca = true
			t.modulate = Color(0.9, 0.9, 1.0)
		ultima_rajada = n
