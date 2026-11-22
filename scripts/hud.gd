## HUD: corações (canto superior esquerdo) e minimapa (canto superior direito).
class_name Hud
extends CanvasLayer

const CORES_MAPA := {GeradorAndar.INICIO: Color(0.55, 0.5, 0.6), GeradorAndar.COMBATE: Color(0.45, 0.4, 0.5),
	GeradorAndar.TESOURO: Color(0.88, 0.7, 0.25), GeradorAndar.FONTE: Color(0.3, 0.6, 0.85),
	GeradorAndar.CHEFE: Color(0.85, 0.25, 0.3)}

var partida: Partida
var andar: Node
var _coracoes: Array[Sprite2D] = []
var _mapa: Node2D


func _init(p: Partida, a: Node) -> void:
	partida = p
	andar = a
	layer = 10
	for i in Partida.VIDA_MAXIMA:
		var s := Sprite2D.new()
		s.texture = load("res://arte/coracao.png")
		s.hframes = 2
		s.position = Vector2(10 + i * 11, 6)
		add_child(s)
		_coracoes.append(s)
	_mapa = Node2D.new()
	_mapa.position = Vector2(290, 14)
	_mapa.draw.connect(_desenhar_mapa)
	add_child(_mapa)


func _process(_d: float) -> void:
	for i in _coracoes.size():
		_coracoes[i].visible = i < partida.vida_max
		_coracoes[i].frame = 0 if i < partida.vida else 1
	_mapa.queue_redraw()


## [cheios, total] visíveis
func coracoes_visiveis() -> Array[int]:
	var cheios := 0
	var total := 0
	for i in _coracoes.size():
		if i < partida.vida_max:
			total += 1
			if i < partida.vida:
				cheios += 1
	return [cheios, total]


func _desenhar_mapa() -> void:
	var tam := Vector2(7, 5)
	var atual: Vector2i = andar.posicao
	for p: Vector2i in andar.salas_conhecidas():
		var r := Rect2(Vector2(p - atual) * (tam + Vector2(1, 1)) - tam / 2.0, tam)
		var tipo: int = andar.mapa["salas"][p]
		var cor: Color = CORES_MAPA[tipo]
		if not andar.visitadas.has(p) and tipo == GeradorAndar.COMBATE:
			cor = cor.darkened(0.5)
		_mapa.draw_rect(r, cor)
		if p == atual:
			_mapa.draw_rect(r, Color.WHITE, false, 1.0)
