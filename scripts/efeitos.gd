## Efeitos visuais de uma vez só (partículas): somem sozinhos. Não interferem na lógica.
class_name Efeitos
extends RefCounted


static func _particulas(pai: Node, pos: Vector2, cor: Color, qtd: int, vel: float, vida: float) -> void:
	if pai == null or not is_instance_valid(pai):
		return
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.emitting = true
	p.amount = qtd
	p.lifetime = vida
	p.explosiveness = 1.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = vel * 0.4
	p.initial_velocity_max = vel
	p.damping_min = vel * 1.5
	p.damping_max = vel * 2.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = cor
	p.z_index = 5
	p.finished.connect(p.queue_free)
	pai.add_child.call_deferred(p)


static func faisca(pai: Node, pos: Vector2, cor := Color(1, 0.95, 0.7)) -> void:
	_particulas(pai, pos, cor, 6, 60.0, 0.25)


static func morte(pai: Node, pos: Vector2, cor: Color) -> void:
	_particulas(pai, pos, cor, 14, 80.0, 0.45)


static func explosao(pai: Node, pos: Vector2) -> void:
	_particulas(pai, pos, Color(1, 0.6, 0.25), 18, 110.0, 0.35)


static func sombra_para(no: Node2D, dy := 0.0) -> void:
	var s := Sprite2D.new()
	Visual.aplicar(s, "sombra")
	s.position = Vector2(0, dy)
	s.z_index = -1
	s.show_behind_parent = true
	no.add_child(s)
