## HUD: corações (canto superior esquerdo) e minimapa (canto superior direito).
class_name Hud
extends CanvasLayer

const CORES_MAPA := {GeradorAndar.INICIO: Color(0.55, 0.5, 0.6), GeradorAndar.COMBATE: Color(0.45, 0.4, 0.5),
	GeradorAndar.TESOURO: Color(0.88, 0.7, 0.25), GeradorAndar.FONTE: Color(0.3, 0.6, 0.85),
	GeradorAndar.CHEFE: Color(0.85, 0.25, 0.3)}

const NOMES := {"espada": "ESPADA", "raio": "RAIO", "coracao_extra": "CORAÇÃO", "botas": "BOTAS",
	"tiro_triplo": "TIRO TRIPLO", "alcance": "ALCANCE", "ricochete": "RICOCHETE", "perfurante": "PERFURANTE",
	"teleguiado": "TELEGUIADO", "explosivo": "EXPLOSIVO", "gelo": "GELO", "retaguarda": "RETAGUARDA"}
const DESCRICOES := {"espada": "dano +1", "raio": "atira mais rápido", "coracao_extra": "+1 coração",
	"botas": "anda mais rápido", "tiro_triplo": "3 tiros em leque", "alcance": "tiro vai mais longe",
	"ricochete": "o tiro quica na parede", "perfurante": "o tiro atravessa inimigos",
	"teleguiado": "o tiro persegue inimigos", "explosivo": "o tiro explode", "gelo": "o tiro congela",
	"retaguarda": "atira também para trás"}

var partida: Partida
var andar: Node
var _coracoes: Array[Sprite2D] = []
var _mapa: Node2D
var _icones: Node2D
var _aviso: Label
var _aviso_t := 0.0


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
	_icones = Node2D.new()
	_icones.position = Vector2(8, 168)
	add_child(_icones)
	_aviso = Label.new()
	_aviso.position = Vector2(0, 24)
	_aviso.size = Vector2(320, 30)
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.add_theme_font_size_override("font_size", 8)
	_aviso.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	_aviso.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.1))
	_aviso.add_theme_constant_override("outline_size", 3)
	_aviso.visible = false
	add_child(_aviso)
	_mapa = Node2D.new()
	_mapa.position = origem_mapa()
	_mapa.draw.connect(_desenhar_mapa)
	add_child(_mapa)


## mostra o nome e o efeito do item por 2,5 s
func anunciar(item: String) -> void:
	if not NOMES.has(item):
		return
	_aviso.text = "%s\n%s" % [NOMES[item], DESCRICOES[item]]
	_aviso.visible = true
	_aviso.modulate.a = 1.0
	_aviso_t = 2.5


func mensagem() -> String:
	return _aviso.text if _aviso.visible else ""


func icones_itens() -> int:
	return _icones.get_child_count()


func _atualizar_icones() -> void:
	if _icones.get_child_count() == partida.itens_pegos.size():
		return
	for c: Node in _icones.get_children():
		_icones.remove_child(c)
		c.queue_free()
	for i in partida.itens_pegos.size():
		var s := Sprite2D.new()
		s.texture = load("res://arte/item_%s.png" % partida.itens_pegos[i])
		s.scale = Vector2(0.75, 0.75)
		s.position = Vector2(i * 12, 0)
		_icones.add_child(s)


func _process(d: float) -> void:
	_atualizar_icones()
	if _aviso_t > 0.0:
		_aviso_t -= d
		_aviso.modulate.a = clampf(_aviso_t / 0.6, 0.0, 1.0)
		if _aviso_t <= 0.0:
			_aviso.visible = false
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


const ALCANCE_MAPA := Vector2i(3, 2)  # salas mostradas em volta da atual (cabe no canto)


func origem_mapa() -> Vector2:
	return Vector2(290, 18)


## retângulos do minimapa (relativos à origem) com a cor de cada sala conhecida perto da atual
func retangulos_mapa() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for item: Array in _itens_mapa():
		out.append(item[0])
	return out


func _itens_mapa() -> Array:
	var tam := Vector2(7, 5)
	var atual: Vector2i = andar.posicao
	var out := []
	for p: Vector2i in andar.salas_conhecidas():
		var d := p - atual
		if absi(d.x) > ALCANCE_MAPA.x or absi(d.y) > ALCANCE_MAPA.y:
			continue
		var r := Rect2(Vector2(d) * (tam + Vector2(1, 1)) - tam / 2.0, tam)
		var tipo: int = andar.mapa["salas"][p]
		var cor: Color = CORES_MAPA[tipo]
		if not andar.visitadas.has(p) and tipo == GeradorAndar.COMBATE:
			cor = cor.darkened(0.5)
		out.append([r, cor, p == atual])
	return out


func _desenhar_mapa() -> void:
	for item: Array in _itens_mapa():
		_mapa.draw_rect(item[0], item[1])
		if item[2]:
			_mapa.draw_rect(item[0], Color.WHITE, false, 1.0)
