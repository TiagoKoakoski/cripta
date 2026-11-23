## HUD: corações (canto superior esquerdo) e minimapa (canto superior direito).
class_name Hud
extends CanvasLayer

const CORES_MAPA := {GeradorAndar.INICIO: Color(0.55, 0.5, 0.6), GeradorAndar.COMBATE: Color(0.45, 0.4, 0.5),
	GeradorAndar.TESOURO: Color(0.88, 0.7, 0.25), GeradorAndar.FONTE: Color(0.3, 0.6, 0.85),
	GeradorAndar.CHEFE: Color(0.85, 0.25, 0.3), GeradorAndar.SUBCHEFE: Color(0.75, 0.45, 0.2)}
const COR_DESCONHECIDA := Color(0.32, 0.3, 0.36)

const NOMES := {"espada": "ESPADA", "raio": "RAIO", "coracao_extra": "CORAÇÃO", "botas": "BOTAS",
	"tiro_triplo": "TIRO TRIPLO", "alcance": "ALCANCE", "ricochete": "RICOCHETE", "perfurante": "PERFURANTE",
	"teleguiado": "TELEGUIADO", "explosivo": "EXPLOSIVO", "gelo": "GELO", "retaguarda": "RETAGUARDA"}
const DESCRICOES := {"espada": "dano +1", "raio": "atira mais rápido", "coracao_extra": "+1 coração",
	"botas": "anda mais rápido", "tiro_triplo": "3 tiros em leque", "alcance": "tiro vai mais longe",
	"ricochete": "o tiro quica na parede", "perfurante": "o tiro atravessa inimigos",
	"teleguiado": "o tiro persegue inimigos", "explosivo": "o tiro explode", "gelo": "o tiro congela",
	"retaguarda": "atira também para trás"}

const DESCRICOES_ESPADACHIM := {"tiro_triplo": "golpe em arco largo", "alcance": "golpe mais longo",
	"ricochete": "devolve tiros inimigos", "perfurante": "golpe com avanço",
	"teleguiado": "lâmina teleguiada a cada 3 golpes", "explosivo": "quem morre no golpe explode",
	"gelo": "o golpe congela", "retaguarda": "golpeia também para trás"}


const DESCRICOES_ALQUIMISTA := {"tiro_triplo": "3 frascos em leque", "alcance": "frasco mais longe, explosão maior",
	"ricochete": "o frasco quica e explode de novo", "perfurante": "a explosão deixa fogo",
	"teleguiado": "o frasco cai no inimigo mais perto", "explosivo": "explosão maior",
	"gelo": "a explosão congela", "retaguarda": "um frasco também para trás"}
const DESCRICOES_CACADOR := {"tiro_triplo": "2 bumerangues", "alcance": "bumerangue vai mais longe",
	"ricochete": "bumerangue volta mais rápido", "perfurante": "bumerangue atravessa paredes",
	"teleguiado": "bumerangue curva para inimigos", "explosivo": "explode quando vira",
	"gelo": "o bumerangue congela", "retaguarda": "um bumerangue para trás"}


static func descricao(item: String, quem: String) -> String:
	var tabela: Dictionary = {"espadachim": DESCRICOES_ESPADACHIM, "alquimista": DESCRICOES_ALQUIMISTA,
		"cacador": DESCRICOES_CACADOR}.get(quem, {})
	if tabela.has(item):
		return tabela[item]
	return DESCRICOES.get(item, "")


var partida: Partida
var andar: Node
var _coracoes: Array[Sprite2D] = []
var _mapa: Node2D
var _icones: Node2D
var _aviso: Label
var _aviso_t := 0.0
var _barra: Node2D
var _icone_chave: Sprite2D
var _nome_chefe: Label


func _init(p: Partida, a: Node) -> void:
	partida = p
	andar = a
	layer = 10
	for i in Partida.CORACOES_MAX:   # vermelhos e depois os de alma, em fileiras de 6
		var s := Sprite2D.new()
		Visual.aplicar(s, "coracao", 2.0, 2)
		s.position = Vector2(20 + (i % 6) * 22, 12 + (i / 6) * 20)
		add_child(s)
		_coracoes.append(s)
	_icones = Node2D.new()
	_icones.position = Vector2(16, 336)
	add_child(_icones)
	_aviso = Label.new()
	_aviso.position = Vector2(0, 48)
	_aviso.size = Vector2(640, 60)
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.add_theme_font_size_override("font_size", 18)
	_aviso.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	_aviso.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.1))
	_aviso.add_theme_constant_override("outline_size", 6)
	_aviso.visible = false
	add_child(_aviso)
	_icone_chave = Sprite2D.new()
	Visual.aplicar(_icone_chave, "chave", 2.0)
	_icone_chave.position = Vector2(20, 36)
	_icone_chave.visible = false
	add_child(_icone_chave)
	_barra = Node2D.new()
	_barra.draw.connect(_desenhar_barra)
	add_child(_barra)
	_nome_chefe = Label.new()
	_nome_chefe.position = Vector2(200, -2)
	_nome_chefe.size = Vector2(240, 20)
	_nome_chefe.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nome_chefe.add_theme_font_size_override("font_size", 16)
	_nome_chefe.add_theme_color_override("font_color", Color(1, 0.85, 0.85))
	_nome_chefe.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.1))
	_nome_chefe.add_theme_constant_override("outline_size", 6)
	add_child(_nome_chefe)
	_mapa = Node2D.new()
	_mapa.position = origem_mapa()
	_mapa.draw.connect(_desenhar_mapa)
	add_child(_mapa)


## mostra o nome e o efeito do item por 2,5 s
func anunciar(item: String) -> void:
	if not NOMES.has(item):
		return
	anunciar_texto(NOMES[item], Hud.descricao(item, partida.personagem))


func anunciar_texto(titulo: String, linha: String) -> void:
	_aviso.text = "%s\n%s" % [titulo, linha]
	_aviso.visible = true
	_aviso.modulate.a = 1.0
	_aviso_t = 2.5


## [visível, fração de vida, nome] do chefe vivo na sala atual
func barra_chefe() -> Array:
	var s: Variant = andar.get("sala") if andar else null
	if s == null or not is_instance_valid(s) or not s.has_method("chefe"):
		return [false, 0.0, ""]
	var c: Chefe = s.chefe()
	if c == null:
		return [false, 0.0, ""]
	return [true, float(c.hp) / c.hp_max, c.nome_exibido]


func _desenhar_barra() -> void:
	var b := barra_chefe()
	_nome_chefe.visible = b[0]
	if not b[0]:
		return
	_nome_chefe.text = b[2]
	var r := Rect2(200, 22, 240, 10)
	_barra.draw_rect(r.grow(1), Color(0.08, 0.05, 0.1))
	_barra.draw_rect(r, Color(0.25, 0.1, 0.12))
	_barra.draw_rect(Rect2(r.position, Vector2(r.size.x * b[1], r.size.y)), Color(0.85, 0.2, 0.25))


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
		Visual.aplicar(s, "item_%s" % partida.itens_pegos[i], 1.5)
		s.position = Vector2(i * 24, 0)
		_icones.add_child(s)


func _process(d: float) -> void:
	_atualizar_icones()
	if _aviso_t > 0.0:
		_aviso_t -= d
		_aviso.modulate.a = clampf(_aviso_t / 0.6, 0.0, 1.0)
		if _aviso_t <= 0.0:
			_aviso.visible = false
	for i in _coracoes.size():
		var c := _coracoes[i]
		var alma := i >= partida.vida_max
		c.visible = i < partida.vida_max + partida.almas
		var nome := "coracao_alma" if alma else "coracao"
		if c.get_meta("visual_nome", "") != nome:
			Visual.aplicar(c, nome, 2.0, 1 if alma else 2)
		var cheio := alma or i < partida.vida
		c.frame = (0 if cheio else 1) % c.hframes
		c.modulate = Color.WHITE if cheio or c.hframes > 1 else Color(0.3, 0.25, 0.3)
	_mapa.queue_redraw()
	_barra.queue_redraw()
	_icone_chave.visible = partida.tem_chave


func almas_visiveis() -> int:
	return _coracoes.filter(func(c: Sprite2D) -> bool:
		return c.visible and c.get_meta("visual_nome", "") == "coracao_alma").size()


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
	return Vector2(580, 36)


## retângulos do minimapa (relativos à origem) com a cor de cada sala conhecida perto da atual
func retangulos_mapa() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for item: Array in _itens_mapa():
		out.append(item[0])
	return out


func _itens_mapa() -> Array:
	var tam := Vector2(14, 10)
	var atual: Vector2i = andar.posicao
	var out := []
	for p: Vector2i in andar.salas_conhecidas():
		var d := p - atual
		if absi(d.x) > ALCANCE_MAPA.x or absi(d.y) > ALCANCE_MAPA.y:
			continue
		var r := Rect2(Vector2(d) * (tam + Vector2(2, 2)) - tam / 2.0, tam)
		var cor := cor_sala(p)
		out.append([r, cor, p == atual])
	return out


## cor da sala no minimapa: o tipo só aparece depois de visitar (o chefe aparece com a chave)
func cor_sala(p: Vector2i) -> Color:
	var tipo: int = andar.mapa["salas"][p]
	if andar.visitadas.has(p) or (tipo == GeradorAndar.CHEFE and partida.tem_chave):
		return CORES_MAPA[tipo]
	return COR_DESCONHECIDA


func _desenhar_mapa() -> void:
	for item: Array in _itens_mapa():
		_mapa.draw_rect(item[0], item[1])
		if item[2]:
			_mapa.draw_rect(item[0], Color.WHITE, false, 2.0)
