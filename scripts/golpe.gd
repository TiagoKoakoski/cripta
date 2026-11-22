## Visual do golpe de lâmina: um arco que some em 0,12 s. Só enfeite.
class_name Golpe
extends Node2D

var _raio := 24.0
var _angulo := 100.0
var _dir := Vector2.RIGHT
var _t := 0.12


static func mostrar(pai: Node, pos: Vector2, dir: Vector2, raio: float, angulo: float) -> void:
	var g := Golpe.new()
	g.position = pos
	g._dir = dir
	g._raio = raio
	g._angulo = angulo
	g.z_index = 4
	pai.add_child(g)


func _process(delta: float) -> void:
	_t -= delta
	modulate.a = clampf(_t / 0.12, 0.0, 1.0)
	queue_redraw()
	if _t <= 0.0:
		queue_free()


func _draw() -> void:
	var meio := _dir.angle()
	var meia := deg_to_rad(_angulo) / 2.0
	draw_arc(Vector2.ZERO, _raio, meio - meia, meio + meia, 16, Color(1, 1, 1, 0.9), 3.0)
	draw_arc(Vector2.ZERO, _raio - 4.0, meio - meia * 0.8, meio + meia * 0.8, 12, Color(0.85, 0.9, 1, 0.5), 2.0)
