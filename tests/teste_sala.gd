# godot --headless --path . --script res://tests/teste_sala.gd
# Monta uma sala de verdade, simula entrada e avança a física.
extends SceneTree

var passou := 0
var falhou := 0


func _initialize() -> void:
	load("res://scripts/controles.gd").configurar()
	_rodar.call_deferred()


func _rodar() -> void:
	for t: String in ["teste_tiro_na_direcao", "teste_morcego_morre_e_sala_abre", "teste_esqueleto_atira",
			"teste_invencibilidade", "teste_slime_divide_e_sala_abre", "teste_spawn_longe_da_porta",
			"teste_parede_segura", "teste_quatro_morcegos_limpam", "teste_porta_trancada",
			"teste_montar_durante_fisica_tranca",
			"teste_inimigo_morto_nao_fere", "teste_coracao_ao_limpar", "teste_coracao_vida_cheia", "teste_tremor", "teste_pontos_sem_pilar", "teste_portas_por_tipo"]:
		await call(t)
	print("Resultado: %d ok, %d falhas" % [passou, falhou])
	quit(1 if falhou > 0 else 0)


func checa(cond: bool, rotulo: String) -> void:
	if cond:
		passou += 1
	else:
		falhou += 1
		push_error("FALHOU " + rotulo)


func montar(inimigos: Array, vida := 3, entrada := Vector2i.DOWN, layout := 0) -> Sala:
	var partida := Partida.new()
	partida.arquivo_recorde = "user://teste_recorde.cfg"
	partida.comecar(1)
	partida.vida = vida
	partida.vida_max = maxi(3, mini(vida, 8))
	var sala := Sala.new()
	root.add_child(sala)
	sala.configurar({"tipo": GeradorAndar.COMBATE, "portas": {Vector2i.UP: GeradorAndar.COMBATE},
		"layout": layout, "inimigos": inimigos, "limpa": false, "entrada": entrada}, partida)
	return sala


func desmontar(sala: Sala) -> void:
	for a: String in ["mover_cima", "mover_baixo", "mover_esquerda", "mover_direita",
			"atirar_cima", "atirar_baixo", "atirar_esquerda", "atirar_direita"]:
		Input.action_release(a)
	sala.queue_free()
	await process_frame


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func teste_tiro_na_direcao() -> void:
	var sala := montar([])
	Input.action_press("atirar_direita")
	await frames(3)
	Input.action_release("atirar_direita")
	var tiros := sala.tiros_do_jogador()
	checa(tiros.size() >= 1, "atirar cria tiro")
	if tiros.size() >= 1:
		var x0: float = tiros[0].position.x
		await frames(5)
		checa(is_instance_valid(tiros[0]) and tiros[0].position.x > x0, "tiro vai pra direita")
	await desmontar(sala)


func teste_morcego_morre_e_sala_abre() -> void:
	var sala := montar([{"tipo": "morcego", "pos": Vector2(160, 40)}], 99)
	var abriu := [false]
	sala.limpa.connect(func() -> void: abriu[0] = true)
	Input.action_press("atirar_cima")
	for i in 600:
		await physics_frame
		if sala.vivos() == 0:
			break
	Input.action_release("atirar_cima")
	await frames(2)
	checa(sala.vivos() == 0 and abriu[0], "morcego morre e a sala abre")
	await desmontar(sala)


func teste_esqueleto_atira() -> void:
	var sala := montar([{"tipo": "esqueleto", "pos": Vector2(160, 40)}])
	await frames(60 * 5)
	checa(sala.partida.vida < 3, "esqueleto atira e tira vida (vida %d)" % sala.partida.vida)
	await desmontar(sala)


func teste_invencibilidade() -> void:
	var sala := montar([{"tipo": "morcego", "pos": Vector2(160, 120)}], 6)
	for i in 600:
		await physics_frame
		if sala.partida.vida < 6:
			break
	var v := sala.partida.vida
	await frames(40)   # 0,66 s: mesmo encostado, não pode perder outra
	checa(v == 5 and sala.partida.vida >= 4, "invencibilidade segura dano repetido")
	await desmontar(sala)


func teste_slime_divide_e_sala_abre() -> void:
	var sala := montar([{"tipo": "slime", "pos": Vector2(160, 50)}], 99)
	var maximo := 0
	Input.action_press("atirar_cima")
	for i in 60 * 30:
		await physics_frame
		maximo = maxi(maximo, sala.vivos())
		if i % 20 == 0:   # mira no slime vivo mais próximo
			_mirar(sala)
		if sala.vivos() == 0:
			break
	_soltar_tiro()
	await frames(2)   # a sala abre no quadro seguinte à última morte
	checa(maximo >= 2, "slime grande se divide (máx. %d vivos)" % maximo)
	checa(sala.vivos() == 0 and sala.aberta(), "depois de matar os pequenos a sala abre")
	await desmontar(sala)


func teste_spawn_longe_da_porta() -> void:
	for entrada: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		for layout in 4:
			for p: Vector2 in Sala.posicoes_inimigos(layout, entrada):
				if p.distance_to(Sala.ponto_de_entrada(entrada)) < 80.0:
					checa(false, "inimigo nasce perto da entrada %s layout %d" % [entrada, layout])
					return
	checa(true, "inimigos nascem a 80+ px da entrada")


func teste_parede_segura() -> void:
	var sala := montar([])
	Input.action_press("mover_esquerda")
	await frames(60 * 4)
	Input.action_release("mover_esquerda")
	checa(sala.jogador.position.x >= 16.0, "parede segura o jogador (x=%.1f)" % sala.jogador.position.x)
	await desmontar(sala)


func teste_quatro_morcegos_limpam() -> void:
	var ini := []
	for p: Vector2 in [Vector2(60, 40), Vector2(260, 40), Vector2(60, 100), Vector2(260, 100)]:
		ini.append({"tipo": "morcego", "pos": p})
	var sala := montar(ini, 99)
	for i in 60 * 40:
		await physics_frame
		if i % 20 == 0:
			_mirar(sala)
		if sala.vivos() == 0:
			break
	_soltar_tiro()
	checa(sala.vivos() == 0, "4 morcegos: jogador parado atirando limpa a sala (restaram %d)" % sala.vivos())
	await desmontar(sala)


func teste_porta_trancada() -> void:
	var sala := montar([{"tipo": "esqueleto", "pos": Vector2(60, 40)}], 99)
	var saiu := [false]
	sala.saiu.connect(func(_d: Vector2i) -> void: saiu[0] = true)
	sala.jogador.position = Vector2(160, 40)
	Input.action_press("mover_cima")
	await frames(90)
	Input.action_release("mover_cima")
	checa(not saiu[0], "porta trancada com inimigo vivo")
	await desmontar(sala)


func _soltar_tiro() -> void:
	for a: String in ["atirar_cima", "atirar_baixo", "atirar_esquerda", "atirar_direita"]:
		Input.action_release(a)


func _mirar(sala: Sala) -> void:
	_soltar_tiro()
	var alvo := sala.inimigo_mais_perto()
	if alvo == null:
		return
	var d: Vector2 = alvo.position - sala.jogador.position
	if absf(d.x) > absf(d.y):
		Input.action_press("atirar_direita" if d.x > 0 else "atirar_esquerda")
	else:
		Input.action_press("atirar_baixo" if d.y > 0 else "atirar_cima")


func teste_montar_durante_fisica_tranca() -> void:
	# ao atravessar uma porta a sala nova é montada no meio da física: inimigos entram na árvore
	# um quadro depois, mas já têm que contar e trancar as portas
	await physics_frame
	var sala := montar([{"tipo": "morcego", "pos": Vector2(60, 40)}, {"tipo": "slime", "pos": Vector2(260, 40)}])
	checa(sala.vivos() == 2 and not sala.aberta(), "montada na física: conta 2 e tranca (vivos %d)" % sala.vivos())
	await desmontar(sala)


func teste_inimigo_morto_nao_fere() -> void:
	var sala := montar([{"tipo": "morcego", "pos": Vector2(160, 142)}], 6)
	sala.partida.invencivel = 0.0
	var m: Inimigo = sala.inimigo_mais_perto()
	m.position = sala.jogador.position
	m.levar_tiro(99)   # morre colado no jogador; o corpo só sai da árvore no fim do quadro
	await frames(1)
	checa(sala.partida.vida == 6, "inimigo que acabou de morrer não fere (vida %d)" % sala.partida.vida)
	await desmontar(sala)


func sala_com_coracao(vida: int) -> Sala:
	var partida := Partida.new()
	partida.arquivo_recorde = "user://teste_recorde.cfg"
	partida.comecar(1)
	partida.vida = vida
	var sala := Sala.new()
	root.add_child(sala)
	sala.configurar({"tipo": GeradorAndar.COMBATE, "portas": {}, "layout": 0, "coracao": true,
		"inimigos": [{"tipo": "esqueleto", "pos": Vector2(60, 40)}], "limpa": false, "entrada": Vector2i.DOWN}, partida)
	return sala


func teste_coracao_ao_limpar() -> void:
	var sala := sala_com_coracao(2)
	var pegou := [false]
	sala.coracao_pego.connect(func() -> void: pegou[0] = true)
	checa(not sala.coracao_no_chao(), "coração só aparece depois de limpar")
	sala.inimigo_mais_perto().levar_tiro(99)
	await frames(3)
	checa(sala.coracao_no_chao(), "sala limpa solta o coração")
	sala.jogador.position = Vector2(160, 88)
	await frames(4)
	checa(sala.partida.vida == 3 and pegou[0] and not sala.coracao_no_chao(), "coração cura 1 e some")
	await desmontar(sala)


func teste_coracao_vida_cheia() -> void:
	var sala := sala_com_coracao(3)
	sala.inimigo_mais_perto().levar_tiro(99)
	await frames(3)
	sala.jogador.position = Vector2(160, 88)
	await frames(4)
	checa(sala.coracao_no_chao(), "com vida cheia o coração fica no chão")
	await desmontar(sala)


func teste_tremor() -> void:
	var sala := montar([], 5)
	sala.jogador.ferir()
	var mexeu := false
	for i in 6:
		await physics_frame
		mexeu = mexeu or sala.position != Vector2.ZERO
	await frames(30)
	checa(mexeu and sala.position == Vector2.ZERO, "levar dano treme a tela e ela volta ao lugar")
	await desmontar(sala)


func teste_pontos_sem_pilar() -> void:
	var ruins := []
	for layout in 4:
		var sala := montar([], 3, Vector2i.DOWN, layout)
		var pontos: Array = sala.pontos_livres()
		for e: Vector2i in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			pontos += Sala.posicoes_inimigos(layout, e)
		for pt: Vector2 in pontos:
			var corpo := Rect2(pt - Vector2(6, 3), Vector2(12, 10))
			for t: Vector2i in Sala.LAYOUTS[layout]:
				if corpo.intersects(Rect2(Vector2(t * 16), Vector2(16, 16))):
					ruins.append([layout, pt])
		await desmontar(sala)
	checa(ruins.is_empty(), "nenhum ponto de nascimento/teleporte encosta em pilar %s" % [ruins])


func _texturas(no: Node) -> Array:
	var out := []
	for c: Node in no.get_children():
		if c is Sprite2D and (c as Sprite2D).texture:
			out.append((c as Sprite2D).texture.resource_path)
		out += _texturas(c)
	return out


func teste_portas_por_tipo() -> void:
	var partida := Partida.new()
	partida.arquivo_recorde = "user://teste_recorde.cfg"
	partida.comecar(1)
	var sala := Sala.new()
	root.add_child(sala)
	sala.configurar({"tipo": GeradorAndar.COMBATE, "layout": 0, "limpa": true, "entrada": Vector2i.ZERO,
		"chefe_trancado": true, "portas": {Vector2i.UP: GeradorAndar.TESOURO, Vector2i.DOWN: GeradorAndar.CHEFE,
		Vector2i.LEFT: GeradorAndar.FONTE, Vector2i.RIGHT: GeradorAndar.SUBCHEFE}}, partida)
	var tex := _texturas(sala)
	checa(not tex.any(func(t: String) -> bool: return t.contains("icone_")), "portas sem ícone em cima")
	checa(sala.textura_porta(Vector2i.UP).ends_with("porta_tesouro.png"), "porta do tesouro é dourada")
	checa(sala.textura_porta(Vector2i.LEFT).ends_with("porta_fonte.png"), "porta da fonte")
	checa(sala.textura_porta(Vector2i.RIGHT).ends_with("porta_subchefe.png"), "porta do subchefe")
	checa(sala.textura_porta(Vector2i.DOWN).ends_with("porta_chefe_trancada.png"), "porta do chefe com cadeado sem chave")
	partida.tem_chave = true
	sala.destrancar_chefe()
	checa(sala.textura_porta(Vector2i.DOWN).ends_with("porta_chefe.png"), "com a chave, porta do chefe aberta")
	await desmontar(sala)
