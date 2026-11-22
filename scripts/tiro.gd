## Projétil (do jogador ou de inimigo). Some ao bater em parede/pilar ou acertar o alvo.
class_name Tiro
extends Area2D

var direcao := Vector2.RIGHT
var velocidade := 180.0
var vida := 0.6
var dano := 1
var do_jogador := true


static func criar(pos: Vector2, dir: Vector2, jogador: bool, dano_: int, vel := 180.0, duracao := 0.6) -> Tiro:
	var t := Tiro.new()
	t.position = pos
	t.direcao = dir.normalized()
	t.do_jogador = jogador
	t.dano = dano_
	t.velocidade = vel
	t.vida = duracao
	var s := Sprite2D.new()
	s.texture = load("res://arte/%s.png" % ("tiro" if jogador else "tiro_inimigo"))
	t.add_child(s)
	var c := CollisionShape2D.new()
	var forma := CircleShape2D.new()
	forma.radius = 3.0
	c.shape = forma
	t.add_child(c)
	t.collision_layer = Camadas.TIRO_JOGADOR if jogador else Camadas.TIRO_INIMIGO
	t.collision_mask = Camadas.PAREDE | Camadas.PILAR | (Camadas.INIMIGO if jogador else Camadas.JOGADOR)
	t.add_to_group("tiro_jogador" if jogador else "tiro_inimigo")
	t.body_entered.connect(t._bateu)
	return t


func _physics_process(delta: float) -> void:
	position += direcao * velocidade * delta
	vida -= delta
	if vida <= 0.0:
		queue_free()


func _bateu(corpo: Node) -> void:
	if is_queued_for_deletion():
		return
	if do_jogador and corpo is Inimigo:
		(corpo as Inimigo).levar_tiro(dano)
	elif not do_jogador and corpo is Jogador:
		(corpo as Jogador).ferir()
	queue_free()
