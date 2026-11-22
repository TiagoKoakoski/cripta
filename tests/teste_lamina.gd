# godot --headless --path . --script res://tests/teste_lamina.gd
# Espadachim: golpe em arco e itens adaptados.
extends SceneTree

var passou := 0
var falhou := 0


func _initialize() -> void:
	load("res://scripts/controles.gd").configurar()
	_rodar.call_deferred()


func _rodar() -> void:
	for t: String in ["teste_base", "teste_golpe_acerta_na_frente", "teste_golpe_destroi_tiro", "teste_arco_triplo",
			"teste_alcance", "teste_retaguarda", "teste_lamina_ricochete_devolve", "teste_perfurante_avanca",
			"teste_teleguiado_lanca", "teste_explosivo", "teste_gelo", "teste_descricao_hud"]:
		await call(t)
	print("Resultado: %d ok, %d falhas" % [passou, falhou])
	quit(1 if falhou > 0 else 0)


func checa(cond: bool, rotulo: String) -> void:
	if cond:
		passou += 1
	else:
		falhou += 1
		push_error("FALHOU " + rotulo)


func montar(inimigos: Array, itens: Array = []) -> Sala:
	var partida := Partida.new()
	partida.arquivo_recorde = "user://teste_progresso.cfg"
	partida.comecar(1, "espadachim")
	partida.vida = 99
	for it: String in itens:
		partida.pegar_item(it)
	var sala := Sala.new()
	root.add_child(sala)
	sala.configurar({"tipo": GeradorAndar.COMBATE, "portas": {}, "layout": 0, "inimigos": inimigos,
		"limpa": false, "entrada": Vector2i.ZERO}, partida)
	return sala


func desmontar(sala: Sala) -> void:
	for a: String in ["atirar_cima", "atirar_baixo", "atirar_esquerda", "atirar_direita"]:
		Input.action_release(a)
	sala.queue_free()
	await process_frame


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func golpe(acao: String) -> void:
	Input.action_press(acao)
	await frames(2)
	Input.action_release(acao)
	await frames(2)


## o inimigo vivo mais perto de `pos` (o empurrão do golpe tira ele uns pixels do lugar)
func inimigo_em(sala: Sala, pos: Vector2) -> Inimigo:
	var melhor: Inimigo = null
	for v: Variant in sala._inimigos:
		if is_instance_valid(v) and (melhor == null or (v as Inimigo).position.distance_to(pos) < melhor.position.distance_to(pos)):
			melhor = v
	return melhor


func teste_base() -> void:
	var p := Partida.new()
	p.arquivo_recorde = "user://teste_progresso.cfg"
	p.comecar(1, "espadachim")
	checa([p.vida, p.vida_max, p.velocidade, p.dano, p.cadencia] == [4, 4, 80.0, 2, 0.45], "espadachim: 4 corações, vel 80, dano 2, 0,45 s")
	p.comecar(1)
	checa([p.vida, p.personagem] == [3, "atirador"], "padrão é o atirador")


func teste_golpe_acerta_na_frente() -> void:
	var sala := montar([{"tipo": "esqueleto", "pos": Vector2(180, 88)}, {"tipo": "esqueleto", "pos": Vector2(140, 88)}])
	await frames(40)
	await golpe("atirar_direita")
	checa(inimigo_em(sala, Vector2(180, 88)).hp == 1, "golpe à direita acerta quem está a 20 px na frente")
	checa(inimigo_em(sala, Vector2(140, 88)).hp == 3, "golpe não acerta quem está atrás")
	checa(sala.tiros_do_jogador().is_empty(), "espadachim não atira")
	await desmontar(sala)


func teste_golpe_destroi_tiro() -> void:
	var sala := montar([])
	var t := Tiro.criar(Vector2(176, 88), Vector2.LEFT, false, 1, 10.0, 3.0)
	sala.add_child(t)
	await golpe("atirar_direita")
	checa(not is_instance_valid(t) or t.is_queued_for_deletion(), "golpe destrói tiro inimigo no arco")
	await desmontar(sala)


func teste_arco_triplo() -> void:
	var sala := montar([{"tipo": "esqueleto", "pos": Vector2(160, 68)}], ["tiro_triplo"])
	await frames(40)
	await golpe("atirar_direita")
	checa(inimigo_em(sala, Vector2(160, 68)).hp < 3, "tiro triplo: arco de 180° acerta a 90° (em cima)")
	await desmontar(sala)


func teste_alcance() -> void:
	var sala := montar([{"tipo": "esqueleto", "pos": Vector2(192, 88)}], ["alcance"])
	await frames(40)
	await golpe("atirar_direita")
	checa(inimigo_em(sala, Vector2(192, 88)).hp < 3, "alcance: raio 36 acerta a 32 px")
	await desmontar(sala)


func teste_retaguarda() -> void:
	var sala := montar([{"tipo": "esqueleto", "pos": Vector2(140, 88)}], ["retaguarda"])
	await frames(40)
	await golpe("atirar_direita")
	checa(inimigo_em(sala, Vector2(140, 88)).hp < 3, "retaguarda: golpe também atrás")
	await desmontar(sala)


func teste_lamina_ricochete_devolve() -> void:
	var sala := montar([], ["ricochete"])
	var t := Tiro.criar(Vector2(176, 88), Vector2.LEFT, false, 1, 10.0, 3.0)
	sala.add_child(t)
	await golpe("atirar_direita")
	var meus := sala.tiros_do_jogador()
	checa(meus.size() == 1 and (meus[0] as Tiro).direcao.x > 0.0, "ricochete: tiro inimigo volta como tiro do jogador")
	await desmontar(sala)


func teste_perfurante_avanca() -> void:
	var sala := montar([], ["perfurante"])
	var x0 := sala.jogador.position.x
	await golpe("atirar_direita")
	checa(sala.jogador.position.x >= x0 + 12.0, "perfurante: golpe avança (%.1f -> %.1f)" % [x0, sala.jogador.position.x])
	await desmontar(sala)


func teste_teleguiado_lanca() -> void:
	var sala := montar([], ["teleguiado"])
	for i in 3:
		await golpe("atirar_direita")
		await frames(30)
	var lancou := sala.get_children().any(func(c: Node) -> bool: return c is Tiro and (c as Tiro).do_jogador and (c as Tiro).guiado)
	checa(lancou, "teleguiado: o 3º golpe lança uma lâmina teleguiada")
	await desmontar(sala)


func teste_explosivo() -> void:
	var sala := montar([{"tipo": "esqueleto", "pos": Vector2(180, 88)}, {"tipo": "esqueleto", "pos": Vector2(196, 100)}], ["explosivo"])
	await frames(40)
	inimigo_em(sala, Vector2(180, 88)).hp = 1
	await golpe("atirar_direita")
	checa(inimigo_em(sala, Vector2(196, 100)).hp < 3, "explosivo: inimigo morto pelo golpe explode no vizinho")
	await desmontar(sala)


func teste_gelo() -> void:
	var sala := montar([{"tipo": "esqueleto", "pos": Vector2(180, 88)}], ["gelo"])
	await frames(40)
	await golpe("atirar_direita")
	checa(inimigo_em(sala, Vector2(180, 88)).lento > 1.0, "gelo: golpe congela")
	await desmontar(sala)


func teste_descricao_hud() -> void:
	checa(Hud.descricao("ricochete", "espadachim") != Hud.descricao("ricochete", "atirador"), "HUD descreve o item pelo personagem")
