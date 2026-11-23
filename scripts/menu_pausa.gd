## Menu de pausa (Start/Esc/P): Continuar, Visual, Controles, Voltar ao título, Sair do jogo.
## Roda com a árvore pausada (PROCESS_MODE_ALWAYS). Emite `escolheu(opcao)`.
class_name MenuPausa
extends CanvasLayer

signal escolheu(opcao: String)

const OPCOES := ["continuar", "visual", "controles", "titulo", "sair"]
const AJUDA := "TECLADO\nWASD anda   •   setas atacam\nEnter confirma   •   Esc / P pausa\n\nCONTROLE\nanalógico esquerdo anda\nanalógico direito ou Y A X B atacam\nStart pausa"

var _i := 0
var _rotulos: Array[Label] = []
var _ajuda: Label
var _painel: ColorRect


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	var fundo := ColorRect.new()
	fundo.color = Color(0.02, 0.01, 0.04, 0.72)
	fundo.size = Vector2(640, 360)
	add_child(fundo)
	_painel = ColorRect.new()
	_painel.color = Color(0.1, 0.07, 0.14, 0.95)
	_painel.position = Vector2(180, 70)
	_painel.size = Vector2(280, 230)
	add_child(_painel)
	var t := _label("PAUSA", Vector2(180, 82), 26, Color(1, 0.85, 0.45))
	t.size.x = 280
	for k in OPCOES.size():
		var l := _label("", Vector2(180, 130 + k * 32), 18, Color.WHITE)
		l.size.x = 280
		_rotulos.append(l)
	_ajuda = _label(AJUDA, Vector2(120, 60), 16, Color(0.95, 0.92, 0.85))
	_ajuda.size = Vector2(400, 260)
	_ajuda.visible = false
	_atualizar()


func _label(txt: String, pos: Vector2, tam: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.position = pos
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.05))
	l.add_theme_constant_override("outline_size", 6)
	add_child(l)
	return l


func opcao_atual() -> int:
	return _i


func mostrando_controles() -> bool:
	return _ajuda.visible


func _atualizar() -> void:
	var nomes := {"continuar": "Continuar", "visual": "Visual: %s" % ("Detalhado" if Visual.modo == Visual.DETALHADO else "Clássico"),
		"controles": "Controles", "titulo": "Voltar ao título", "sair": "Sair do jogo"}
	for k in OPCOES.size():
		_rotulos[k].text = ("▶  %s  ◀" if k == _i else "%s") % nomes[OPCOES[k]]
		_rotulos[k].add_theme_color_override("font_color", Color(1, 0.88, 0.5) if k == _i else Color(0.75, 0.72, 0.8))
	for l: Label in _rotulos:
		l.visible = not _ajuda.visible
	_painel.visible = not _ajuda.visible


func _apertou(acoes: Array) -> bool:
	for a: String in acoes:
		if Input.is_action_just_pressed(a):
			return true
	return false


func _process(_d: float) -> void:
	if _ajuda.visible:
		if _apertou(["confirmar", "pausar"]):
			_ajuda.visible = false
			_atualizar()
		return
	if _apertou(["pausar"]):
		escolheu.emit("continuar")
		return
	if _apertou(["mover_cima", "atirar_cima"]):
		_i = posmod(_i - 1, OPCOES.size())
		_atualizar()
	elif _apertou(["mover_baixo", "atirar_baixo"]):
		_i = posmod(_i + 1, OPCOES.size())
		_atualizar()
	elif _apertou(["confirmar"]):
		match OPCOES[_i]:
			"visual":
				Visual.alternar()
				_atualizar()
			"controles":
				_ajuda.visible = true
				_atualizar()
			_:
				escolheu.emit(OPCOES[_i])
