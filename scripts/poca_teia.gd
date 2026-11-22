## Poça de teia deixada pela Aranha Rainha: 4 s no chão; o jogador dentro fica lento.
class_name PocaTeia
extends Area2D

const DURACAO := 4.0

var _t := DURACAO


static func criar(pai: Node, pos: Vector2) -> void:
	if pai == null or not is_instance_valid(pai):
		return
	var p := PocaTeia.new()
	p.position = pos.clamp(Vector2(24, 24), Vector2(296, 152))
	p.collision_layer = 0
	p.collision_mask = Camadas.JOGADOR
	var s := Sprite2D.new()
	s.texture = Inimigo.textura("poca_teia") if ResourceLoader.exists("res://arte/poca_teia.png") else load("res://arte/sombra.png")
	s.scale = Vector2(1.6, 1.6)
	s.z_index = -5
	p.add_child(s)
	var c := CollisionShape2D.new()
	var r := CircleShape2D.new()
	r.radius = 11.0
	c.shape = r
	p.add_child(c)
	pai.add_child.call_deferred(p)


func _physics_process(delta: float) -> void:
	_t -= delta
	modulate.a = clampf(_t / 0.6, 0.0, 1.0)
	for corpo: Node in get_overlapping_bodies():
		if corpo is Jogador:
			(corpo as Jogador).partida.lentidao_jogador = 0.15
	if _t <= 0.0:
		queue_free()
