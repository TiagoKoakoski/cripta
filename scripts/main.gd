## Fluxo do jogo: título (escolhe o personagem) -> partida (3 andares) -> fim ou vitória -> título.
## Modo de teste: godot --path . -- --autoplay --capturas=/pasta  (um robô joga e fotografa)
extends Node2D

var estado := "titulo"
var partida: Partida
var andar: Andar
var arquivo_recorde := "user://progresso.cfg"
var selecionado := 0       # índice em Partida.PERSONAGENS
var _tela: Node2D
var _espera := 0.0
var _robo: Node


func _ready() -> void:
	arquivo_recorde = arquivo_para(OS.get_cmdline_user_args()) if arquivo_recorde == "user://progresso.cfg" \
		else arquivo_recorde
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--personagem="):
			selecionado = maxi(0, Partida.PERSONAGENS.find(a.split("=", true, 1)[1]))
	partida = Partida.new()
	partida.arquivo_recorde = arquivo_recorde
	partida.carregar_recorde()
	if OS.get_cmdline_user_args().has("--autoplay"):
		_robo = load("res://scripts/robo.gd").new(self)
		add_child(_robo)
	_mostrar_tela("titulo")


## o robô (--autoplay) nunca mexe no recorde de quem joga
func arquivo_para(args: PackedStringArray) -> String:
	return "user://progresso_robo.cfg" if args.has("--autoplay") else "user://progresso.cfg"


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventKey and (evento as InputEventKey).pressed \
			and (evento as InputEventKey).physical_keycode == KEY_ESCAPE:
		get_tree().quit()


func _process(delta: float) -> void:
	_espera = maxf(0.0, _espera - delta)
	# só as telas (título, fim, vitória) aceitam botão; "terminando" é a pausa da morte/vitória
	if not estado in ["titulo", "fim", "vitoria"] or _espera > 0.0:
		return
	if estado == "titulo":
		for a: String in ["atirar_esquerda", "atirar_direita", "mover_esquerda", "mover_direita"]:
			if Input.is_action_just_pressed(a):
				var passo := -1 if a.ends_with("esquerda") else 1
				selecionado = posmod(selecionado + passo, Partida.PERSONAGENS.size())
				_mostrar_tela("titulo", false)
				return
		for a: String in ["confirmar", "atirar_cima", "atirar_baixo"]:
			if Input.is_action_just_pressed(a) or (Input.is_action_pressed(a) and _robo):
				comecar()
				return
		return
	# fim / vitória: qualquer botão volta ao título
	for a: String in ["confirmar", "atirar_cima", "atirar_baixo", "atirar_esquerda", "atirar_direita"]:
		if Input.is_action_just_pressed(a) or (Input.is_action_pressed(a) and _robo):
			_mostrar_tela("titulo")
			return


func comecar() -> void:
	partida.arquivo_recorde = arquivo_recorde
	var semente := int(Time.get_ticks_usec() % 1000000007) + randi() % 1000
	if semente == partida.semente:
		semente += 1
	partida.comecar(semente, Partida.PERSONAGENS[selecionado])
	if _tela:
		_tela.queue_free()
		_tela = null
	if andar:
		andar.queue_free()
	andar = Andar.new()
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--chefe="):
			andar.chefe_forcado = a.split("=", true, 1)[1]
	add_child(andar)
	andar.iniciar(partida, semente)
	andar.derrota.connect(_terminar.bind(false))
	andar.vitoria.connect(_terminar.bind(true))
	estado = "jogando"


func _terminar(vitoria: bool) -> void:
	if estado != "jogando":
		return
	estado = "terminando"
	partida.terminar(vitoria)
	Sons.tocar("vitoria" if vitoria else "derrota")
	await get_tree().create_timer(1.0).timeout
	if andar:
		andar.queue_free()
		andar = null
	_mostrar_tela("vitoria" if vitoria else "fim")


func _mostrar_tela(qual: String, com_espera := true) -> void:
	estado = qual
	if com_espera:
		_espera = 0.6
	if _tela:
		_tela.queue_free()
	_tela = Node2D.new()
	add_child(_tela)
	var titulo := {"titulo": "titulo", "fim": "texto_fim", "vitoria": "texto_vitoria"}[qual] as String
	_imagem(titulo, Vector2(160, 40))
	_imagem("texto_aperte", Vector2(160, 160))
	var quem: String = Partida.PERSONAGENS[selecionado]
	if qual == "titulo":
		for i in Partida.PERSONAGENS.size():
			var r := Sprite2D.new()
			r.texture = load("res://arte/%s.png" % ("heroi" if i == 0 else "espadachim"))
			r.hframes = 8
			r.scale = Vector2(2, 2) if i == selecionado else Vector2(1.5, 1.5)
			r.modulate = Color.WHITE if i == selecionado else Color(0.45, 0.42, 0.5)
			r.position = Vector2(130 + i * 60, 92)
			_tela.add_child(r)
		_texto("<  %s  >" % Partida.PERSONAGENS[selecionado].to_upper(), Vector2(0, 112))
	else:
		_texto("ANDAR %d" % partida.andar_atual, Vector2(0, 80))
		_imagem("icone_combate", Vector2(130, 104))
		_numero(partida.pontos(), Vector2(160, 104))
	_imagem("icone_chefe", Vector2(130, 132))
	_numero(partida.recorde_de(quem) if qual == "titulo" else partida.recorde, Vector2(160, 132))


func _texto(t: String, pos: Vector2) -> void:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.size = Vector2(320, 12)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", Color(0.95, 0.9, 0.78))
	_tela.add_child(l)


func _imagem(nome: String, pos: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = load("res://arte/%s.png" % nome)
	s.position = pos
	_tela.add_child(s)


func _numero(n: int, pos: Vector2) -> void:
	var txt := str(n)
	for i in txt.length():
		var s := Sprite2D.new()
		s.texture = load("res://arte/digitos.png")
		s.hframes = 10
		s.frame = int(txt[i])
		s.position = pos + Vector2(i * 11, 0)
		_tela.add_child(s)
