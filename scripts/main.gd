## Fluxo do jogo: título (escolhe o personagem) -> história -> partida (3 andares, com transição a cada
## subida) -> fim, ou final da história e vitória -> título.
## Modo de teste: godot --path . -- --autoplay --capturas=/pasta  (um robô joga e fotografa)
extends Node2D

var estado := "titulo"
var partida: Partida
var andar: Andar
var arquivo_recorde := "user://progresso.cfg"
var selecionado := 0       # índice em Partida.PERSONAGENS
const NOMES := {"atirador": "IARA, A ATIRADORA", "espadachim": "BENTO, O ESPADACHIM",
	"alquimista": "LÚCIO, O ALQUIMISTA", "cacador": "CAUÃ, O CAÇADOR"}
const RESUMO := {"atirador": "atira a luz do farol", "espadachim": "golpe em arco, corta tiros",
	"alquimista": "frascos que explodem em área", "cacador": "bumerangue que vai e volta"}
var _tela: Node2D
var _espera := 0.0
var _robo: Node
var _cartao: Cartao
var _fundo_tela := ""


func fundo_da_tela() -> String:
	return _fundo_tela

const ANDAR_TEXTO := {2: "A cripta ficou para trás. Acima, o ossuário das Catacumbas range sob o peso dos ossos.",
	3: "O ar esfria. No topo da torre, o céu rasgado: o Abismo engole as últimas estrelas."}


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


var pausado := false
var _menu: MenuPausa


func menu_pausa() -> MenuPausa:
	return _menu if _menu and is_instance_valid(_menu) else null


## Start/Esc/P: só durante o jogo (não na história, transição, morte ou telas)
func pausar() -> void:
	if estado != "jogando" or pausado:
		return
	pausado = true
	get_tree().paused = true
	_menu = MenuPausa.new()
	add_child(_menu)
	_menu.escolheu.connect(_menu_escolheu)


func despausar() -> void:
	pausado = false
	get_tree().paused = false
	if menu_pausa():
		_menu.queue_free()
	_menu = null


func _menu_escolheu(opcao: String) -> void:
	match opcao:
		"continuar":
			despausar()
		"titulo":
			despausar()
			if andar:
				andar.queue_free()
				andar = null
			_mostrar_tela("titulo")
		"sair":
			get_tree().quit()


func _process(delta: float) -> void:
	_espera = maxf(0.0, _espera - delta)
	if estado == "jogando" and not pausado and Input.is_action_just_pressed("pausar"):
		pausar()
		return
	if estado in ["historia", "transicao", "final"]:
		if _cartao and is_instance_valid(_cartao):
			for a: String in ["confirmar", "atirar_cima", "atirar_baixo", "atirar_esquerda", "atirar_direita"]:
				if Input.is_action_just_pressed(a) or (Input.is_action_pressed(a) and _robo):
					_cartao.avancar()
					break
		return
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
				_abertura()
				return
		return
	# fim / vitória: qualquer botão volta ao título
	for a: String in ["confirmar", "atirar_cima", "atirar_baixo", "atirar_esquerda", "atirar_direita"]:
		if Input.is_action_just_pressed(a) or (Input.is_action_pressed(a) and _robo):
			_mostrar_tela("titulo")
			return


func _nome_curto() -> String:
	return (NOMES[Partida.PERSONAGENS[selecionado]] as String).split(",")[0].capitalize()


func _abertura() -> void:
	if _tela:
		_tela.queue_free()
		_tela = null
	estado = "historia"
	var quem := _nome_curto()
	_cartao = Cartao.mostrar(self, [
		{"titulo": "VALE-CINZA", "texto": "Numa noite sem estrelas, uma torre negra brotou do cemitério e rachou a velha cripta ao meio.", "de": 0, "para": 0, "imagem": "cartao_abertura1"},
		{"titulo": "O LICH VESPER", "texto": "No alto da torre ele rasgou o céu. O Abismo engole as estrelas, uma a uma. Quando a última apagar, os mortos levantam.", "de": 0, "para": 0, "imagem": "cartao_abertura2"},
		{"titulo": "ANDAR 1 — CRIPTA", "texto": "%s entra pela cripta. É preciso subir." % quem, "de": 0, "para": 1, "imagem": "cartao_abertura3"},
	], Partida.PERSONAGENS[selecionado], 4.0)
	_cartao.terminou.connect(comecar)


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
	andar.scale = Vector2(2, 2)   # o mundo vive em 320x176 e é desenhado em 640x360
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--chefe="):
			andar.chefe_forcado = a.split("=", true, 1)[1]
	add_child(andar)
	andar.iniciar(partida, semente)
	andar.subida_externa = true
	andar.pediu_subida.connect(_transicao)
	andar.derrota.connect(_terminar.bind(false))
	andar.vitoria.connect(_terminar.bind(true))
	estado = "jogando"


func _transicao() -> void:
	if estado != "jogando" or andar == null:
		return
	estado = "transicao"
	var para := partida.andar_atual + 1
	var info := Andares.info(para)
	andar.process_mode = Node.PROCESS_MODE_DISABLED
	_cartao = Cartao.mostrar(self, [{"titulo": "ANDAR %d — %s" % [para, info["nome"]], "texto": ANDAR_TEXTO.get(para, ""),
		"de": para - 1, "para": para, "imagem": "cartao_%s" % info["tema"]}], partida.personagem, 3.0)
	_cartao.terminou.connect(func() -> void:
		if andar == null:
			return
		andar.process_mode = Node.PROCESS_MODE_INHERIT
		andar.subir()
		estado = "jogando")


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
	if not vitoria:
		_mostrar_tela("fim")
		return
	estado = "final"
	var quem := _nome_curto()
	_cartao = Cartao.mostrar(self, [
		{"titulo": "A FENDA SE FECHA", "texto": "Vesper cai. Devagar, o rasgo no céu se costura, e a primeira estrela volta a brilhar.", "de": 3, "para": 3, "imagem": "cartao_final1"},
		{"titulo": "AMANHECER", "texto": "As estrelas voltam a Vale-Cinza. %s desce a torre morta enquanto o sol nasce." % quem, "de": 3, "para": 3, "imagem": "cartao_final2"},
	], partida.personagem, 4.0)
	_cartao.terminou.connect(func() -> void: _mostrar_tela("vitoria"))


func _mostrar_tela(qual: String, com_espera := true) -> void:
	estado = qual
	if com_espera:
		_espera = 0.6
	if _tela:
		_tela.queue_free()
	_tela = Node2D.new()
	add_child(_tela)
	_fundo_tela = {"titulo": "fundo_titulo", "fim": "cartao_fim", "vitoria": "cartao_final2"}[qual]
	if Visual.modo == Visual.DETALHADO and Visual.tem_hd(_fundo_tela):
		var f := Sprite2D.new()
		f.centered = false
		f.texture = Visual._carregar(Visual.caminho_hd(_fundo_tela))
		_tela.add_child(f)
		var escuro := ColorRect.new()
		escuro.color = Color(0.02, 0.01, 0.04, 0.5)
		escuro.size = Vector2(640, 360)
		_tela.add_child(escuro)
	else:
		_fundo_tela = ""
	var titulo := {"titulo": "titulo", "fim": "texto_fim", "vitoria": "texto_vitoria"}[qual] as String
	_imagem(titulo, Vector2(320, 80))
	_texto("aperte um botão", Vector2(0, 318), 16, Color(0.8, 0.75, 0.68))
	var quem: String = Partida.PERSONAGENS[selecionado]
	if qual == "titulo":
		for i in Partida.PERSONAGENS.size():
			var r := Sprite2D.new()
			Visual.aplicar(r, Jogador.sprite_de(Partida.PERSONAGENS[i]), 4.0 if i == selecionado else 3.0, 8)
			r.frame = 0
			r.modulate = Color.WHITE if i == selecionado else Color(0.45, 0.42, 0.5)
			r.position = Vector2(170 + i * 100, 168)
			_tela.add_child(r)
		_texto("<  %s  >" % NOMES[quem], Vector2(0, 212), 20, Color(1, 0.88, 0.55))
		_texto(RESUMO[quem], Vector2(0, 240), 16)
		_texto("recorde: %d" % partida.recorde_de(quem), Vector2(0, 270), 16)
	else:
		_texto("chegou ao andar %d" % partida.andar_atual, Vector2(0, 170), 20, Color(1, 0.88, 0.55))
		_texto("pontos: %d" % partida.pontos(), Vector2(0, 205), 18)
		_texto("recorde: %d" % partida.recorde, Vector2(0, 235), 18)


func _texto(t: String, pos: Vector2, tam := 16, cor := Color(0.95, 0.9, 0.78)) -> void:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.size = Vector2(640, tam + 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.08))
	l.add_theme_constant_override("outline_size", 6)
	_tela.add_child(l)


func _imagem(nome: String, pos: Vector2) -> void:
	var s := Sprite2D.new()
	Visual.aplicar(s, nome, 2.0)
	s.position = pos
	_tela.add_child(s)
