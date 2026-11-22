## Subchefe Slime Rei (28): anda em saltos curtos; fase 2 solta anel de 6 a cada 2 s. Ao morrer,
## vira 2 slimes grandes; a chave só cai quando a sala fica limpa.
extends Chefe

var _anel := 2.0


func _preparar() -> void:
	_ajustar_escala(2.2)


func _agir(delta: float) -> void:
	if _t <= 0.0:
		_t = _rng.randf_range(0.6, 1.0)
		_dir = _para_jogador().rotated(_rng.randf_range(-0.6, 0.6))
	velocity = _dir * (35.0 if _fase == 1 else 50.0)
	if _fase == 2:
		_anel -= delta
		if _anel <= 0.0:
			_anel = 2.0
			rajada(6, 75.0, _rng.randf() * TAU)


func levar_tiro(dano: int, dir := Vector2.ZERO) -> void:
	var pos := position
	super(dano, dir)
	if not vivo():
		for d: Vector2 in [Vector2(-14, 0), Vector2(14, 0)]:
			invocar("slime", pos + d)
