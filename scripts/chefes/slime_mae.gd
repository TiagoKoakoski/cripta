## Slime Mãe (40): salta no jogador (sombra no chão avisa onde cai), anel de 8 tiros ao pousar;
## a cada fase solta 2 slimes pequenos e fica menor e mais rápida.
extends Chefe

var pousos := 0
var _estado_s := "pausa"
var _de := Vector2.ZERO
var _alvo := Vector2.ZERO
var _aviso: Sprite2D
var _no_ar := false


func _preparar() -> void:
	_t = 0.4
	_ajustar_escala(3.0)


func aviso_ativo() -> bool:
	return _aviso != null and is_instance_valid(_aviso) and _aviso.visible


func perigoso() -> bool:
	return super() and not _no_ar


func _agir(delta: float) -> void:
	velocity = Vector2.ZERO
	match _estado_s:
		"pausa":
			if _t <= 0.0:
				_estado_s = "mirar"
				_t = 0.5
				_alvo = jogador.position.clamp(Vector2(40, 40), Vector2(280, 136))
				_mostrar_aviso(true)
		"mirar":
			_sprite.scale.y = (_escala * (0.85 + 0.1 * sin(_t * 30.0))) * Visual.fator(_sprite)
			if _t <= 0.0:
				_estado_s = "salto"
				_t = 0.6
				_de = position
				_no_ar = true
				collision_mask = 0
		"salto":
			var k := 1.0 - clampf(_t / 0.6, 0.0, 1.0)
			position = _de.lerp(_alvo, k)
			_sprite.position.y = -sin(k * PI) * 24.0
			if _t <= 0.0:
				_pousar()


func _pousar() -> void:
	position = _alvo
	_sprite.position.y = 0.0
	_no_ar = false
	collision_mask = Camadas.PAREDE | Camadas.PILAR
	_mostrar_aviso(false)
	pousos += 1
	rajada(8, 85.0, 0.0 if pousos % 2 else PI / 8.0)
	_estado_s = "pausa"
	_t = [0.0, 1.1, 0.8, 0.55][_fase]


func _mostrar_aviso(sim: bool) -> void:
	if _aviso == null or not is_instance_valid(_aviso):
		_aviso = Sprite2D.new()
		Visual.aplicar(_aviso, "sombra")
		_aviso.modulate = Color(1, 0.3, 0.3, 0.8)
		_aviso.z_index = -4
		sala.add_child(_aviso)
	_aviso.scale = Vector2(_escala * 1.5, _escala * 2.0)
	_aviso.position = _alvo + Vector2(0, -6)
	_aviso.visible = sim


func _ao_mudar_fase(_f: int) -> void:
	for d: Vector2 in [Vector2(-22, 0), Vector2(22, 0)]:
		invocar("slime_pequeno", position + d)
	_ajustar_escala(_escala * 0.8)


func _exit_tree() -> void:
	if _aviso and is_instance_valid(_aviso):
		_aviso.queue_free()
