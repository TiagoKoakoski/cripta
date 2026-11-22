## Fluxo do jogo: título -> partida (andar) -> fim ou vitória -> partida nova.
## Modo de teste: godot --path . -- --autoplay --capturas=/pasta  (um robô joga e fotografa)
extends Node2D

var estado := "titulo"
var partida: Partida
var andar: Andar
var arquivo_recorde := "user://recorde.cfg"
var _tela: Node2D
var _espera := 0.0
var _robo: Node


func _ready() -> void:
	partida = Partida.new()
	partida.arquivo_recorde = arquivo_recorde
	partida.carregar_recorde()
	if OS.get_cmdline_user_args().has("--autoplay"):
		_robo = load("res://scripts/robo.gd").new(self)
		add_child(_robo)
	_mostrar_tela("titulo")


func _process(delta: float) -> void:
	_espera = maxf(0.0, _espera - delta)
	# só as telas (título, fim, vitória) aceitam botão; "terminando" é a pausa da morte/vitória
	if not estado in ["titulo", "fim", "vitoria"] or _espera > 0.0:
		return
	for a: String in ["confirmar", "atirar_cima", "atirar_baixo", "atirar_esquerda", "atirar_direita"]:
		if Input.is_action_just_pressed(a) or (Input.is_action_pressed(a) and estado == "titulo" and _robo):
			comecar()
			return


func comecar() -> void:
	partida.arquivo_recorde = arquivo_recorde
	var semente := int(Time.get_ticks_usec() % 1000000007) + randi() % 1000
	if semente == partida.semente:
		semente += 1
	partida.comecar(semente)
	if _tela:
		_tela.queue_free()
		_tela = null
	if andar:
		andar.queue_free()
	andar = Andar.new()
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


func _mostrar_tela(qual: String) -> void:
	estado = qual
	_espera = 0.6
	if _tela:
		_tela.queue_free()
	_tela = Node2D.new()
	add_child(_tela)
	var titulo := {"titulo": "titulo", "fim": "texto_fim", "vitoria": "texto_vitoria"}[qual] as String
	_imagem(titulo, Vector2(160, 50))
	_imagem("texto_aperte", Vector2(160, 150))
	if qual != "titulo":
		_imagem("icone_combate", Vector2(130, 95))
		_numero(partida.salas_limpas.size(), Vector2(160, 95))
	_imagem("icone_chefe", Vector2(130, 120))
	_numero(partida.recorde, Vector2(160, 120))


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
