## Caixa de madeira: sólida (como pilar), quebra com 2 de dano de qualquer arma do jogador.
## Às vezes (10%) deixa um coração.
class_name Caixa
extends StaticBody2D

const VIDA := 2

var hp := VIDA
var sala: Node2D
var _sprite: Sprite2D


static func criar(sala_: Node2D, centro: Vector2) -> Caixa:
	var c := Caixa.new()
	c.sala = sala_
	c.position = centro
	c.collision_layer = Camadas.PILAR
	c.collision_mask = 0
	c._sprite = Sprite2D.new()
	Visual.aplicar(c._sprite, "caixa")
	c._sprite.z_index = -8
	c.add_child(c._sprite)
	var forma := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(16, 16)
	forma.shape = r
	c.add_child(forma)
	c.add_to_group("caixa")
	return c


func levar_dano(n: int) -> void:
	if hp <= 0:
		return
	hp -= n
	_sprite.modulate = Color(1, 0.6, 0.5)
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.15)
	Sons.tocar("acerto")
	if hp <= 0:
		remove_from_group("caixa")
		Efeitos.morte(get_parent(), position, Color(0.7, 0.5, 0.3))
		var sorte := randf()
		if sala and sala.has_method("coracao_solto") and sorte < 0.14:   # 10% vermelho, 4% de alma
			sala.coracao_solto(position, sorte >= 0.10)
		queue_free()


## dano de área (explosões, frascos): toda caixa a até `raio` de `pos`
static func area(arvore: SceneTree, pos: Vector2, raio: float, dano: int) -> void:
	for n: Node in arvore.get_nodes_in_group("caixa"):
		var c := n as Caixa
		if c and c.position.distance_to(pos) <= raio + 8.0:
			c.levar_dano(dano)
