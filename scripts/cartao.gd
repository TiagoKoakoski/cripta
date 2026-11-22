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
	_fundo.size = Vector2(320, 180)
	_fundo.modulate.a = 0.0
	add_child(_fundo)
	_torre = Node2D.new()
	_torre.draw.connect(_desenhar_torre)
	_fundo.add_child(_torre)
	_icone = Sprite2D.new()
	_icone.texture = load("res://arte/%s.png" % Jogador.sprite_de(personagem))
	_icone.hframes = 8
	_icone.frame = 4   # de costas, subindo
	_fundo.add_child(_icone)
	_titulo = _label(Vector2(104, 52), 10, Color(1, 0.85, 0.45))
	_texto = _label(Vector2(104, 72), 8, Color(0.92, 0.88, 0.8))
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.size = Vector2(200, 80)
	create_tween().tween_property(_fundo, "modulate:a", 1.0, FADE)
	_montar()


func _label(pos: Vector2, tam: int, cor: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(200, 16)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	_fundo.add_child(l)
	return l


func pagina_atual() -> int:
	return _i


func _montar() -> void:
	var p: Dictionary = paginas[_i]
	_titulo.text = p.get("titulo", "")
	_texto.text = p.get("texto", "")
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
	_icone.position = Vector2(60, y - 2.0)
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
	_torre.draw_rect(Rect2(36, 20, 48, 2), Color(0.5, 0.8, 1.0, 0.6))   # a fenda no céu
	for n in 3:
		var y := _y_andar(n + 1) - 16.0
		var destaque: bool = n + 1 == p.get("para", 0)
		var r := Rect2(40, y, 40, 32)
		_torre.draw_rect(r, cores[n].lightened(0.25) if destaque else cores[n])
		_torre.draw_rect(r, Color(0.08, 0.05, 0.1), false, 1.0)
		_torre.draw_string(ThemeDB.fallback_font, Vector2(4, y + 20), nomes[n], HORIZONTAL_ALIGNMENT_LEFT, 36, 6,
			Color(1, 0.9, 0.6) if destaque else Color(0.6, 0.55, 0.65))
