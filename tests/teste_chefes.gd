# godot --headless --path . --script res://tests/teste_chefes.gd
# Chefes: vida, espera inicial, fases, ataques com aviso, invocações, barra de vida.
extends SceneTree

var passou := 0
var falhou := 0
const PRONTOS := ["rei", "slime_mae", "aranha_rainha", "colosso"]


func _initialize() -> void:
	load("res://scripts/controles.gd").configurar()
	_rodar.call_deferred()


func _rodar() -> void:
	for t: String in ["teste_vida_espera_fases", "teste_barra_no_hud", "teste_rei_fase3",
			"teste_slime_mae_salta_com_aviso", "teste_slime_mae_divide", "teste_invocados_somem_com_chefe",
			"teste_rainha_teia_vira_poca", "teste_rainha_fase2_invoca", "teste_rainha_investida_avisada",
			"teste_colosso_investe_ate_parede", "teste_colosso_tonto", "teste_colosso_fase3_duas"]:
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
	sala.queue_free()
	await process_frame


func tiros_inimigos(sala: Sala) -> int:
	return sala.get_children().filter(func(c: Node) -> bool: return c is Tiro and not (c as Tiro).do_jogador).size()


func ferir_ate(c: Chefe, fracao: float) -> void:
	var alvo := floori(c.hp_max * fracao)
	if c.hp > alvo:
		c.levar_tiro(c.hp - alvo)


func vivos_do_tipo(sala: Sala, t: String) -> int:
	var n := 0
	for v: Variant in sala._inimigos:
		if is_instance_valid(v) and (v as Inimigo).vivo() and (v as Inimigo).tipo == t:
			n += 1
	return n


func teste_vida_espera_fases() -> void:
	for nome: String in PRONTOS:
		var sala := montar(nome)
		var c := sala.chefe()
		checa(c != null and c.hp == Chefe.VIDA_CHEFE[nome] and c.hp_max == c.hp, "%s: vida %d" % [nome, Chefe.VIDA_CHEFE[nome]])
		var p0 := c.position
		await frames(80)   # surgimento 0,5 s + quase toda a espera de 1 s
		checa(tiros_inimigos(sala) == 0 and c.position.distance_to(p0) < 1.0, "%s: espera inicial sem atacar nem andar" % nome)
		checa(c.fase() == 1, "%s: começa na fase 1" % nome)
		var fases := []
		c.fase_mudou.connect(func(n: int) -> void: fases.append(n))
		await frames(30)
		ferir_ate(c, 0.6)
		await frames(3)
		ferir_ate(c, 0.3)
		await frames(3)
		checa(fases == [2, 3] and c.fase() == 3, "%s: fases 2 e 3 a 2/3 e 1/3 (%s)" % [nome, fases])
		await desmontar(sala)


func teste_barra_no_hud() -> void:
	var p := Partida.new()
	p.arquivo_recorde = "user://teste_progresso.cfg"
	p.comecar(5)
	var a := Andar.new()
	a.chefe_forcado = "rei"
	root.add_child(a)
	a.iniciar(p, 5)
	checa(not a.hud.barra_chefe()[0], "sem chefe, sem barra")
	a.entrar(a.mapa["chefe"], Vector2i.DOWN)
	await frames(3)
	checa(a.hud.barra_chefe() == [true, 1.0, "REI ESQUELETO"], "barra cheia com o nome (%s)" % [a.hud.barra_chefe()])
	a.sala.chefe().levar_tiro(9)
	await frames(2)
	checa(is_equal_approx(a.hud.barra_chefe()[1], 36.0 / 45.0), "barra acompanha a vida")
	a.queue_free()
	await process_frame


func teste_rei_fase3() -> void:
	var sala := montar("rei")
	var c := sala.chefe()
	await frames(100)
	ferir_ate(c, 0.3)
	var viu_espiral := false
	var max_esq := 0
	for i in 60 * 8:
		await physics_frame
		viu_espiral = viu_espiral or c.ultima_rajada == 12
		max_esq = maxi(max_esq, vivos_do_tipo(sala, "esqueleto"))
	checa(viu_espiral, "Rei fase 3: espiral de 12 tiros")
	checa(max_esq >= 1 and max_esq <= 2, "Rei fase 3: invoca até 2 esqueletos (máx. %d)" % max_esq)
	await desmontar(sala)


func teste_slime_mae_salta_com_aviso() -> void:
	var sala := montar("slime_mae")
	var c := sala.chefe()
	var aviso := 0.0
	var aviso_no_pouso := -1.0
	var pousos0: int = c.get("pousos")
	for i in 60 * 6:
		await physics_frame
		if int(c.get("pousos")) > pousos0:   # pousou neste quadro: vale o aviso acumulado até o anterior
			aviso_no_pouso = aviso
			break
		aviso = aviso + 1.0 / 60.0 if c.call("aviso_ativo") else 0.0
	checa(aviso_no_pouso >= 0.4, "Slime Mãe: sombra avisa o pouso por 0,4 s+ (%.2f)" % aviso_no_pouso)
	await frames(2)
	checa(c.ultima_rajada == 8, "Slime Mãe: anel de 8 tiros ao pousar")
	await desmontar(sala)


func teste_slime_mae_divide() -> void:
	var sala := montar("slime_mae")
	var c := sala.chefe()
	await frames(100)
	var escala0 := c.escala()
	ferir_ate(c, 0.6)
	await frames(10)
	checa(vivos_do_tipo(sala, "slime_pequeno") == 2, "Slime Mãe: fase 2 solta 2 slimes pequenos")
	checa(c.escala() < escala0, "Slime Mãe: fica menor")
	await desmontar(sala)


func teste_invocados_somem_com_chefe() -> void:
	var sala := montar("slime_mae")
	var c := sala.chefe()
	var morto := [false]
	sala.chefe_morto.connect(func() -> void: morto[0] = true)
	await frames(100)
	ferir_ate(c, 0.6)
	await frames(10)
	checa(sala.vivos() == 3 and not sala.aberta(), "invocados contam e a sala segue trancada")
	c.levar_tiro(999)
	await frames(5)
	checa(morto[0] and sala.vivos() == 0 and sala.aberta(), "chefe morto: invocados somem e a sala abre")
	await desmontar(sala)


func teste_rainha_teia_vira_poca() -> void:
	var sala := montar("aranha_rainha")
	var poca: Node = null
	for i in 60 * 6:
		await physics_frame
		for ch: Node in sala.get_children():
			if ch is PocaTeia:
				poca = ch
		if poca:
			break
	checa(poca != null, "teia vira poça no chão")
	if poca:
		sala.jogador.position = (poca as Node2D).position
		await frames(4)
		checa(sala.partida.lentidao_jogador > 0.0, "jogador na poça fica lento")
		var vel0 := sala.partida.velocidade
		Input.action_press("mover_direita")
		await frames(2)
		checa(sala.jogador.velocity.x < vel0 * 0.6, "lento: anda a metade (%.0f)" % sala.jogador.velocity.x)
		Input.action_release("mover_direita")
		var t := 0
		while is_instance_valid(poca) and t < 60 * 6:
			await physics_frame
			t += 1
		checa(t >= 60 * 3 and t <= 60 * 5, "poça dura ~4 s (%d quadros depois de achar)" % t)
	await desmontar(sala)


func teste_rainha_fase2_invoca() -> void:
	var sala := montar("aranha_rainha")
	var c := sala.chefe()
	await frames(100)
	ferir_ate(c, 0.6)
	await frames(10)
	checa(vivos_do_tipo(sala, "aranha") == 2, "Rainha fase 2: invoca 2 aranhas")
	await desmontar(sala)


func teste_rainha_investida_avisada() -> void:
	var sala := montar("aranha_rainha")
	var c := sala.chefe()
	await frames(100)
	ferir_ate(c, 0.3)
	var aviso := 0.0
	var aviso_antes := -1.0
	for i in 60 * 8:
		await physics_frame
		var e: String = c.call("estado_atual")
		if e == "investida":
			aviso_antes = aviso
			break
		aviso = aviso + 1.0 / 60.0 if e == "aviso" else 0.0
	checa(aviso_antes >= 0.48, "Rainha fase 3: investida avisada por 0,5 s (%.2f)" % aviso_antes)
	await desmontar(sala)


func teste_colosso_investe_ate_parede() -> void:
	var sala := montar("colosso")
	var c := sala.chefe()
	var mira := 0.0
	var mira_antes := -1.0
	var parou_na_parede := false
	var investindo := false
	for i in 60 * 8:
		await physics_frame
		var e: String = c.call("estado_atual")
		if e == "investir" and not investindo:
			investindo = true
			mira_antes = mira
		if investindo and e != "investir":
			var p := c.position
			parou_na_parede = p.x <= 44.0 or p.x >= 276.0 or p.y <= 44.0 or p.y >= 132.0 or c.get_slide_collision_count() > 0 or e == "tonto"
			break
		mira = mira + 1.0 / 60.0 if e == "mirar" else 0.0
	checa(mira_antes >= 0.68, "Colosso: linha de aviso por 0,7 s antes de investir (%.2f)" % mira_antes)
	checa(parou_na_parede, "Colosso: investe até bater (%.0f, %.0f)" % [c.position.x, c.position.y])
	await desmontar(sala)


func teste_colosso_tonto() -> void:
	var sala := montar("colosso")
	var c := sala.chefe()
	var tonto := 0
	var hp_ok := false
	for i in 60 * 10:
		await physics_frame
		if c.call("estado_atual") == "tonto":
			if tonto == 5:
				var h := c.hp
				c.levar_tiro(1)
				hp_ok = c.hp == h - 2
			tonto += 1
		elif tonto > 0:
			break
	checa(tonto >= 66 and tonto <= 78, "Colosso: tonto por 1,2 s (%d quadros)" % tonto)
	checa(c.ultima_rajada == 5, "Colosso: leque de ossos ao bater (%d)" % c.ultima_rajada)
	checa(hp_ok, "Colosso: leva dano em dobro quando tonto")
	await desmontar(sala)


func teste_colosso_fase3_duas() -> void:
	var sala := montar("colosso")
	var c := sala.chefe()
	await frames(100)
	ferir_ate(c, 0.3)
	var investidas := 0
	var anterior := ""
	for i in 60 * 10:
		await physics_frame
		var e: String = c.call("estado_atual")
		if e == "investir" and anterior != "investir":
			investidas += 1
		if e == "tonto":
			break
		anterior = e
	checa(investidas == 2, "Colosso fase 3: 2 investidas antes de ficar tonto (%d)" % investidas)
	await desmontar(sala)
