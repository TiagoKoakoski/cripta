# godot --headless --path . --script res://tests/teste_navegacao.gd
extends SceneTree

var passou := 0
var falhou := 0


func _initialize() -> void:
	load("res://scripts/controles.gd").configurar()
	_rodar.call_deferred()


func _rodar() -> void:
	for t: String in ["teste_porta_muda_sala", "teste_sala_limpa_continua_limpa", "teste_item_uma_vez",
			"teste_fonte_uma_vez", "teste_chefe_morto_vence", "teste_morte_derrota", "teste_hud",
			"teste_minimapa_revela",
			"teste_chefe_longe_da_entrada", "teste_minimapa_dentro_do_canto", "teste_dois_tesouros_diferentes",
			"teste_coracao_persiste", "teste_coracao_sorteado"]:
		await call(t)
	print("Resultado: %d ok, %d falhas" % [passou, falhou])
	quit(1 if falhou > 0 else 0)


func checa(cond: bool, rotulo: String) -> void:
	if cond:
		passou += 1
	else:
		falhou += 1
		push_error("FALHOU " + rotulo)


func novo_andar(semente := 5) -> Andar:
	var p := Partida.new()
	p.arquivo_recorde = "user://teste_recorde.cfg"
	p.comecar(semente)
	var a := Andar.new()
	root.add_child(a)
	a.iniciar(p, semente)
	return a


func fim(a: Andar) -> void:
	for x: String in ["mover_cima", "mover_baixo", "mover_esquerda", "mover_direita"]:
		Input.action_release(x)
	a.queue_free()
	await process_frame


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func sala_do_tipo(a: Andar, tipo: int) -> Vector2i:
	for p: Vector2i in a.mapa["salas"]:
		if a.mapa["salas"][p] == tipo:
			return p
	return Vector2i(99, 99)


func andar_ate_porta(a: Andar, d: Vector2i) -> void:
	a.sala.jogador.position = Sala.ponto_de_entrada(d)
	var acao: String = {Vector2i.UP: "mover_cima", Vector2i.DOWN: "mover_baixo",
		Vector2i.LEFT: "mover_esquerda", Vector2i.RIGHT: "mover_direita"}[d]
	var antes := a.posicao
	Input.action_press(acao)
	for i in 120:
		await physics_frame
		if a.posicao != antes:
			break
	Input.action_release(acao)
	await frames(3)


func teste_porta_muda_sala() -> void:
	var a := novo_andar()
	var d: Vector2i = GeradorAndar.vizinhos(a.mapa["salas"], a.posicao)[0] - a.posicao
	await andar_ate_porta(a, d)
	checa(a.posicao == d, "porta leva à sala vizinha (%s)" % a.posicao)
	checa(a.sala.jogador.position.distance_to(Sala.ponto_de_entrada(-d)) < 12.0,
		"jogador aparece na porta oposta")
	await fim(a)


func teste_sala_limpa_continua_limpa() -> void:
	var a := novo_andar()
	var alvo := sala_do_tipo(a, GeradorAndar.COMBATE)
	a.entrar(alvo, Vector2i.DOWN)
	await frames(3)
	checa(a.sala.vivos() > 0, "sala de combate começa com inimigos")
	for e: Variant in a.sala._inimigos.duplicate():
		if is_instance_valid(e):
			(e as Inimigo).levar_tiro(99)
	await frames(3)
	for e: Variant in a.sala._inimigos.duplicate():   # slimes pequenos
		if is_instance_valid(e):
			(e as Inimigo).levar_tiro(99)
	await frames(3)
	checa(a.partida.salas_limpas.has(alvo), "sala registrada como limpa")
	a.entrar(a.mapa["inicio"], Vector2i.DOWN)
	await frames(2)
	a.entrar(alvo, Vector2i.DOWN)
	await frames(3)
	checa(a.sala.vivos() == 0 and a.sala.aberta(), "voltar a sala limpa: sem inimigos e aberta")
	await fim(a)


func tocar_objeto(a: Andar) -> void:
	a.sala.jogador.position = Vector2(160, 110)
	Input.action_press("mover_cima")
	await frames(30)
	Input.action_release("mover_cima")
	a.sala.jogador.position = Vector2(160, 140)
	await frames(5)


func teste_item_uma_vez() -> void:
	var a := novo_andar()
	var t := sala_do_tipo(a, GeradorAndar.TESOURO)
	a.entrar(t, Vector2i.DOWN)
	await frames(3)
	await tocar_objeto(a)
	checa(a.partida.itens_pegos.size() == 1, "pegou o item")
	a.entrar(a.mapa["inicio"], Vector2i.DOWN)
	await frames(2)
	a.entrar(t, Vector2i.DOWN)
	await frames(3)
	await tocar_objeto(a)
	checa(a.partida.itens_pegos.size() == 1, "item não reaparece")
	await fim(a)


func teste_fonte_uma_vez() -> void:
	var a := novo_andar()
	a.partida.vida = 1
	var f := sala_do_tipo(a, GeradorAndar.FONTE)
	a.entrar(f, Vector2i.DOWN)
	await frames(3)
	await tocar_objeto(a)
	checa(a.partida.vida == 3, "fonte cura 2")
	a.partida.vida = 1
	a.entrar(a.mapa["inicio"], Vector2i.DOWN)
	await frames(2)
	a.entrar(f, Vector2i.DOWN)
	await frames(3)
	await tocar_objeto(a)
	checa(a.partida.vida == 1, "fonte só uma vez")
	await fim(a)


func teste_chefe_morto_vence() -> void:
	var a := novo_andar()
	var venceu := [false]
	a.vitoria.connect(func() -> void: venceu[0] = true)
	a.entrar(a.mapa["chefe"], Vector2i.DOWN)
	await frames(3)
	var rei: Inimigo = a.sala.inimigo_mais_perto()
	checa(rei != null and rei.tipo == "rei" and rei.hp == 30, "sala do chefe tem o Rei com 30")
	rei.levar_tiro(99)
	await frames(5)
	checa(venceu[0], "matar o Rei vence")
	await fim(a)


func teste_morte_derrota() -> void:
	var a := novo_andar()
	var perdeu := [false]
	a.derrota.connect(func() -> void: perdeu[0] = true)
	a.partida.vida = 1
	a.sala.jogador.ferir()
	await frames(3)
	checa(perdeu[0], "vida 0 = derrota")
	await fim(a)


func teste_hud() -> void:
	var a := novo_andar()
	a.partida.vida = 2
	a.partida.vida_max = 5
	await frames(2)
	checa(a.hud.coracoes_visiveis() == [2, 5], "HUD mostra 2 cheios de 5 (%s)" % [a.hud.coracoes_visiveis()])
	await fim(a)


func teste_minimapa_revela() -> void:
	var a := novo_andar()
	var vistas := a.salas_conhecidas()
	checa(vistas.size() == 1 + GeradorAndar.vizinhos(a.mapa["salas"], a.posicao).size(),
		"minimapa: sala atual + vizinhas")
	await fim(a)


func teste_chefe_longe_da_entrada() -> void:
	for entrada: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var a := novo_andar()
		a.partida.vida = 6
		a.partida.vida_max = 6
		a.entrar(a.mapa["chefe"], entrada)
		await frames(2)
		var rei: Inimigo = a.sala.inimigo_mais_perto()
		var dist := rei.position.distance_to(a.sala.jogador.position)
		var t := 0
		while a.partida.vida == 6 and t < 180:
			await physics_frame
			t += 1
		checa(dist >= 80.0 and t >= 60, "chefe entrando por %s: %.0f px, 1º dano em %d quadros" % [entrada, dist, t])
		await fim(a)


func teste_minimapa_dentro_do_canto() -> void:
	for semente in 30:
		var a := novo_andar(semente)
		for p: Vector2i in a.mapa["salas"]:
			a.entrar(p, Vector2i.DOWN)
			for r: Rect2 in a.hud.retangulos_mapa():
				var tela := Rect2(r.position + a.hud.origem_mapa(), r.size)
				if not Rect2(244, 0, 76, 40).encloses(tela):
					checa(false, "minimapa fora do canto: %s" % tela)
					await fim(a)
					return
		await fim(a)
	checa(true, "minimapa sempre no canto superior direito")


func teste_dois_tesouros_diferentes() -> void:
	var ok := true
	for s in 20:
		var a := novo_andar(s)
		var itens := []
		for p: Vector2i in a.mapa["salas"]:
			if a.mapa["salas"][p] == GeradorAndar.TESOURO:
				itens.append(a._cfg[p]["item"])
		ok = ok and itens.size() == 2 and itens[0] != itens[1]
		await fim(a)
	checa(ok, "2 tesouros por andar, com itens diferentes")


func teste_coracao_persiste() -> void:
	var a := novo_andar()
	var c := sala_do_tipo(a, GeradorAndar.COMBATE)
	a._cfg[c]["coracao"] = true
	a.partida.limpar_sala(c)
	a.entrar(c, Vector2i.DOWN)
	await frames(3)
	checa(a.sala.coracao_no_chao(), "sala limpa com coração ainda guardado mostra o coração")
	a.partida.vida = 2
	a.sala.jogador.position = Vector2(160, 88)
	await frames(4)
	checa(a.partida.vida == 3 and not a._cfg[c]["coracao"], "pegou o coração: cura 1 e não volta")
	await fim(a)


func teste_coracao_sorteado() -> void:
	var com := 0
	var total := 0
	for s in 30:
		var a := novo_andar(s)
		for p: Vector2i in a.mapa["salas"]:
			if a.mapa["salas"][p] == GeradorAndar.COMBATE:
				total += 1
				com += 1 if a._cfg[p]["coracao"] else 0
		await fim(a)
	var taxa := float(com) / total
	checa(taxa > 0.2 and taxa < 0.4, "cerca de 30%% das salas de combate soltam coração (%.2f)" % taxa)
