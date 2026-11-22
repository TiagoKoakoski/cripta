# godot --headless --path . --script res://tests/teste_chefes_novos.gd
# Chefes da v4: Cavaleiro sem Cabeça, Verme de Ossos, Sombra Gêmea.
extends SceneTree

var passou := 0
var falhou := 0


func _initialize() -> void:
	load("res://scripts/controles.gd").configurar()
	_rodar.call_deferred()


func _rodar() -> void:
	for t: String in ["teste_vidas", "teste_cavaleiro_investida_avisada", "teste_cavaleiro_cabeca",
			"teste_cavaleiro_fogo", "teste_verme_tremor", "teste_verme_fase3_duas", "teste_sombra_espelha",
			"teste_sombra_responde_tiro", "teste_sombra_fase2"]:
		await call(t)
	print("Resultado: %d ok, %d falhas" % [passou, falhou])
	quit(1 if falhou > 0 else 0)


func checa(cond: bool, rotulo: String) -> void:
	if cond:
		passou += 1
	else:
		falhou += 1
		push_error("FALHOU " + rotulo)


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func montar(nome: String) -> Sala:
	var partida := Partida.new()
	partida.arquivo_recorde = "user://teste_progresso.cfg"
	partida.comecar(1)
	partida.vida = 99
	partida.vida_max = 8
	var sala := Sala.new()
	root.add_child(sala)
	sala.configurar({"tipo": GeradorAndar.CHEFE, "portas": {Vector2i.DOWN: GeradorAndar.COMBATE}, "chefe": nome,
		"limpa": false, "entrada": Vector2i.DOWN}, partida)
	return sala


func desmontar(sala: Sala) -> void:
	for a: String in ["atirar_cima", "atirar_baixo", "atirar_esquerda", "atirar_direita", "mover_direita"]:
		Input.action_release(a)
	sala.queue_free()
	await process_frame


func tiros_inimigos(sala: Sala) -> Array:
	return sala.get_children().filter(func(c: Node) -> bool: return c is Tiro and not (c as Tiro).do_jogador)


func fase3(c: Chefe) -> void:
	c.hp = floori(c.hp_max * 0.3)   # direto: o Verme enterrado não leva dano


func aviso_antes_de(c: Chefe, estado_aviso: String, estado_alvo: String, limite: int) -> float:
	var aviso := 0.0
	for i in limite:
		await physics_frame
		var e: String = c.call("estado_atual")
		if e == estado_alvo:
			return aviso
		aviso = aviso + 1.0 / 60.0 if e == estado_aviso else 0.0
	return -1.0


func teste_vidas() -> void:
	for par: Array in [["cavaleiro", 45], ["verme", 55], ["sombra_gemea", 65]]:
		var sala := montar(par[0])
		var c := sala.chefe()
		checa(c != null and c.hp == par[1] and c.fases == 3, "%s: vida %d" % par)
		await desmontar(sala)


func teste_cavaleiro_investida_avisada() -> void:
	var sala := montar("cavaleiro")
	var a: float = await aviso_antes_de(sala.chefe(), "mirar", "investida", 60 * 6)
	checa(a >= 0.68, "Cavaleiro: investida avisada por 0,7 s (%.2f)" % a)
	await desmontar(sala)


func teste_cavaleiro_cabeca() -> void:
	var sala := montar("cavaleiro")
	var cabeca: Tiro = null
	for i in 60 * 10:
		await physics_frame
		for t: Tiro in tiros_inimigos(sala):
			if t.guiado_jogador != null:
				cabeca = t
		if cabeca:
			break
	checa(cabeca != null, "Cavaleiro arremessa a cabeça (persegue o jogador)")
	var vida := 0
	while is_instance_valid(cabeca) and vida < 60 * 5:
		await physics_frame
		vida += 1
	checa(vida <= 60 * 3 + 2, "cabeça dura até 3 s (%d quadros)" % vida)
	await desmontar(sala)


func teste_cavaleiro_fogo() -> void:
	var sala := montar("cavaleiro")
	var c := sala.chefe()
	await frames(100)
	fase3(c)
	var fogo := false
	for i in 60 * 8:
		await physics_frame
		fogo = sala.get_children().any(func(n: Node) -> bool: return n is PocaFogo)
		if fogo:
			break
	checa(fogo, "Cavaleiro fase 3: investida deixa fogo")
	await desmontar(sala)


func teste_verme_tremor() -> void:
	var sala := montar("verme")
	var c := sala.chefe()
	var invul := true
	var viu_enterrado := false
	for i in 60 * 6:
		await physics_frame
		if c.call("estado_atual") == "enterrado":
			viu_enterrado = true
			invul = invul and c.invulneravel() and not c.perigoso()
			break
	checa(viu_enterrado and invul, "Verme enterrado: invulnerável e sem contato")
	var a: float = await aviso_antes_de(c, "tremor", "emergir", 60 * 6)
	checa(a >= 0.78, "Verme: tremor avisa 0,8 s antes de sair (%.2f)" % a)
	await frames(3)
	checa(c.ultima_rajada == 10, "Verme sai com anel de 10")
	await desmontar(sala)


func teste_verme_fase3_duas() -> void:
	var sala := montar("verme")
	var c := sala.chefe()
	await frames(100)
	fase3(c)
	for i in 60 * 10:   # conta um ciclo inteiro: de um "exposto" até o próximo
		await physics_frame
		if c.call("estado_atual") == "exposto":
			break
	for i in 60 * 10:
		await physics_frame
		if c.call("estado_atual") != "exposto":
			break
	var saidas := 0
	var antes := ""
	var viu_exposto := false
	for i in 60 * 14:
		await physics_frame
		var e: String = c.call("estado_atual")
		if e == "emergir" and antes != "emergir":
			saidas += 1
		if e == "exposto":
			viu_exposto = true
			break
		antes = e
	checa(viu_exposto and saidas == 2, "Verme fase 3: sai 2 vezes antes de ficar exposto (%d)" % saidas)
	await desmontar(sala)


func teste_sombra_espelha() -> void:
	var sala := montar("sombra_gemea")
	var c := sala.chefe()
	sala.jogador.position = Vector2(80, 60)
	await frames(60 * 4)
	var espelho := Vector2(320, 176) - sala.jogador.position
	checa(c.position.distance_to(espelho) < 24.0, "Sombra fica no ponto espelhado (%s vs %s)" % [c.position, espelho])
	await desmontar(sala)


func teste_sombra_responde_tiro() -> void:
	var sala := montar("sombra_gemea")
	await frames(100)
	var antes := tiros_inimigos(sala).size()
	Input.action_press("atirar_direita")
	await frames(4)
	Input.action_release("atirar_direita")
	checa(tiros_inimigos(sala).size() > antes, "quando o jogador atira, a Sombra atira")
	await desmontar(sala)


func teste_sombra_fase2() -> void:
	var sala := montar("sombra_gemea")
	var c := sala.chefe()
	await frames(100)
	c.levar_tiro(c.hp - floori(c.hp_max * 0.6))
	await frames(10)
	var sombras := 0
	for v: Variant in sala._inimigos:
		if is_instance_valid(v) and (v as Inimigo).vivo() and (v as Inimigo).tipo in ["sombra_gemea", "sombra_menor"]:
			sombras += 1
	checa(sombras == 2, "Sombra fase 2: duas sombras (%d)" % sombras)
	await desmontar(sala)
