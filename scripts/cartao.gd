## Cartões de história/transição (no estilo do Isaac): a tela escurece, aparece a torre com os 3
## andares, o ícone do personagem sobe de um andar para o outro e um texto curto. Cada página dura
## `duracao` s ou avança com botão (depois de 0,5 s). Emite `terminou` depois da última.
class_name Cartao
extends CanvasLayer

signal terminou

const MIN := 0.5
const FADE := 0.4

## página: {"titulo": String, "texto": String, "de": int, "para": int}  (andares 1..3; 0 = fora da torre)
var paginas: Array = []
var duracao := 3.5
var personagem := "atirador"
var _i := 0
var _t := 0.0
var _fundo: ColorRect
var _torre: Node2D
var _icone: Sprite2D
var _titulo: Label
var _texto: Label
var _acabou := false
var _ilustracao: Sprite2D
var _faixa: ColorRect
var _painel_torre: ColorRect


static func mostrar(pai: Node, paginas_: Array, quem: String, duracao_ := 3.5) -> Cartao:
	var c := Cartao.new()
	c.paginas = paginas_
	c.personagem = quem
	c.duracao = duracao_
	c.layer = 20
	pai.add_child(c)
	return c


func _ready() -> void:
	_fundo = ColorRect.new()
	_fundo.color = Color(0.03, 0.02, 0.05)
	_fundo.size = Vector2(640, 360)
	_fundo.modulate.a = 0.0
	add_child(_fundo)
	_ilustracao = Sprite2D.new()
	_ilustracao.centered = false
	_ilustracao.visible = false
	_fundo.add_child(_ilustracao)
	_faixa = ColorRect.new()
	_faixa.color = Color(0.02, 0.01, 0.04, 0.78)
	_faixa.position = Vector2(0, 252)
	_faixa.size = Vector2(640, 108)
	_faixa.visible = false
	_fundo.add_child(_faixa)
	_painel_torre = ColorRect.new()
	_painel_torre.color = Color(0.02, 0.01, 0.04, 0.6)
	_painel_torre.position = Vector2(0, 30)
	_painel_torre.size = Vector2(206, 212)
	_painel_torre.visible = false
	_fundo.add_child(_painel_torre)
	_torre = Node2D.new()
	_torre.draw.connect(_desenhar_torre)
	_fundo.add_child(_torre)
	_icone = Sprite2D.new()
	Visual.aplicar(_icone, Jogador.sprite_de(personagem), 2.0, 8)
	_icone.frame = 6 if _icone.hframes == 12 else 4   # de costas, subindo
	_fundo.add_child(_icone)
	_titulo = _label(Vector2(216, 100), 22, Color(1, 0.85, 0.45))
	_texto = _label(Vector2(216, 144), 17, Color(0.95, 0.92, 0.85))
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.size = Vector2(400, 180)
	create_tween().tween_property(_fundo, "modulate:a", 1.0, FADE)
	_montar()


func _label(pos: Vector2, tam: int, cor: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(400, 32)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.05))
	l.add_theme_constant_override("outline_size", 6)
	_fundo.add_child(l)
	return l


func pagina_atual() -> int:
	return _i


func ilustracao_visivel() -> bool:
	return _ilustracao.visible


func texto_atual() -> String:
	return _texto.text


func _montar() -> void:
	var p: Dictionary = paginas[_i]
	_titulo.text = p.get("titulo", "")
	_texto.text = p.get("texto", "")
	# Detalhado: ilustração em tela cheia, texto numa faixa embaixo; a torre só nas subidas
	var img: String = p.get("imagem", "")
	var ilustrado := img != "" and Visual.modo == Visual.DETALHADO and Visual.tem_hd(img)
	_ilustracao.visible = ilustrado
	_faixa.visible = ilustrado
	if ilustrado:
		_ilustracao.texture = Visual._carregar(Visual.caminho_hd(img))
		_titulo.position = Vector2(32, 262)
		_texto.position = Vector2(32, 294)
		_texto.size = Vector2(576, 60)
	else:
		_titulo.position = Vector2(216, 100)
		_texto.position = Vector2(216, 144)
		_texto.size = Vector2(400, 180)
	var subida: bool = p.get("de", 0) != p.get("para", 0)
	_torre.visible = not ilustrado or subida
	_icone.visible = _torre.visible
	_painel_torre.visible = ilustrado and subida
	_t = 0.0
	_torre.queue_redraw()


func avancar() -> void:
	if _acabou or _t < MIN:
		return
	_i += 1
	if _i >= paginas.size():
		_acabou = true
		var tw := create_tween()
		tw.tween_property(_fundo, "modulate:a", 0.0, FADE)
		tw.tween_callback(func() -> void:
			terminou.emit()
			queue_free())
		return
	_montar()


func _process(delta: float) -> void:
	if _acabou:
		return
	_t += delta
	var p: Dictionary = paginas[_i]
	var k := clampf((_t - 0.3) / 1.0, 0.0, 1.0)
	var y := lerpf(_y_andar(p.get("de", 0)), _y_andar(p.get("para", 0)), k * k * (3.0 - 2.0 * k))
	_icone.position = Vector2(148, (y - 2.0) * 2.0)
	if _icone.hframes == 12:   # de costas, passos
		_icone.frame = 6 + ([0, 1, 0, 2][int(_t * 8.0) % 4] if k < 1.0 else 0)
		_icone.offset.y = 0.0
	else:
		_icone.frame = 4 + int(_t * 6.0) % 2 if k < 1.0 else 4
	if _t >= duracao:
		_t = MIN
		avancar()


func _y_andar(n: int) -> float:
	return 166.0 - 36.0 * n if n > 0 else 172.0


func _desenhar_torre() -> void:
	var p: Dictionary = paginas[_i] if _i < paginas.size() else {}
	var nomes := ["CRIPTA", "CATACUMBAS", "ABISMO"]
	var cores := [Color(0.35, 0.28, 0.42), Color(0.45, 0.36, 0.26), Color(0.18, 0.3, 0.38)]
	_torre.draw_rect(Rect2(100, 40, 96, 4), Color(0.5, 0.8, 1.0, 0.6))   # a fenda no céu
	for n in 3:
		var y := (_y_andar(n + 1) - 16.0) * 2.0
		var destaque: bool = n + 1 == p.get("para", 0)
		var r := Rect2(108, y, 80, 64)
		_torre.draw_rect(r, cores[n].lightened(0.25) if destaque else cores[n])
		_torre.draw_rect(r, Color(0.08, 0.05, 0.1), false, 2.0)
		_torre.draw_string(ThemeDB.fallback_font, Vector2(4, y + 38), nomes[n], HORIZONTAL_ALIGNMENT_LEFT, 100, 12,
			Color(1, 0.9, 0.6) if destaque else Color(0.6, 0.55, 0.65))
