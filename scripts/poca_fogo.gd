## Fogo no chão (rastro do Cavaleiro, frasco do Alquimista com perfurante): fere quem pisa por `duracao` s.
## Do inimigo fere o jogador; do jogador fere inimigos (1 de dano a cada 0,5 s).
class_name PocaFogo
extends Area2D

var duracao := 3.0
var do_jogador := false
var _t := 0.0
var _tique := 0.0


static func criar(pai: Node, pos: Vector2, duracao_ := 3.0, jogador := false, raio := 7.0) -> void:
	if pai == null or not is_instance_valid(pai):
		return
	var f := PocaFogo.new()
	f.position = pos.clamp(Vector2(20, 20), Vector2(300, 156))
	f.duracao = duracao_
	f._t = duracao_
	f.do_jogador = jogador
	f.collision_layer = 0
	f.collision_mask = Camadas.INIMIGO if jogador else Camadas.JOGADOR
	var s := Sprite2D.new()
	Visual.aplicar(s, "fogo", 1.0, 2)
	s.z_index = -4
	f.add_child(s)
	var c := CollisionShape2D.new()
	var r := CircleShape2D.new()
	r.radius = raio
	c.shape = r
	f.add_child(c)
	pai.add_child.call_deferred(f)


func _physics_process(delta: float) -> void:
	_t -= delta
	_tique -= delta
	var s := get_child(0) as Sprite2D
	s.frame = int(_t * 8.0) % s.hframes
	modulate.a = clampf(_t / 0.5, 0.0, 1.0)
	for corpo: Node in get_overlapping_bodies():
		if not do_jogador and corpo is Jogador:
			(corpo as Jogador).ferir()
		elif do_jogador and corpo is Inimigo and _tique <= 0.0 and (corpo as Inimigo).vivo():
			(corpo as Inimigo).levar_tiro(1)
	if _tique <= 0.0:
		_tique = 0.5
	if _t <= 0.0:
		queue_free()
