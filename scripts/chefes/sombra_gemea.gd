## Sombra Gêmea (65): fica no ponto espelhado do jogador (reflexo pelo centro da sala) e atira de volta
## quando ele ataca. Fase 2: chama uma sombra menor (espelho horizontal). Fase 3: rajada de 8 a cada 3 s.
extends Chefe

const CENTRO2 := Vector2(320, 176)

var _recarga_s := 0.0
var _rajada_s := 3.0
var _ligada := false


func _preparar() -> void:
	_ajustar_escala(1.8)
	collision_mask = Camadas.PAREDE


func _agir(delta: float) -> void:
	if not _ligada and jogador.has_signal("atacou"):
		jogador.atacou.connect(_jogador_atacou)
		_ligada = true
	var alvo := (CENTRO2 - jogador.position).clamp(Vector2(24, 24), Vector2(296, 152))
	velocity = (alvo - position).limit_length(1.0) * 95.0 if position.distance_to(alvo) > 3.0 else Vector2.ZERO
	_sprite.modulate = Color(0.55, 0.45, 0.75, 0.9)
	_recarga_s -= delta
	if _fase == 3:
		_rajada_s -= delta
		if _rajada_s <= 0.0:
			_rajada_s = 3.0
			rajada(8, 80.0)


func _jogador_atacou(_dir: Vector2) -> void:
	if not vivo() or _espera > 0.0 or _recarga_s > 0.0:
		return
	_recarga_s = 0.45
	atirar(_para_jogador(), 95.0)
	ultima_rajada = 1


func _ao_mudar_fase(f: int) -> void:
	if f == 2:
		invocar("sombra_menor", Vector2(320.0 - jogador.position.x, jogador.position.y))
