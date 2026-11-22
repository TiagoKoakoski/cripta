# godot --headless --path . --script res://tests/teste_chefes.gd
# Chefes: vida, espera inicial, fases, ataques com aviso, invocações, barra de vida.
extends SceneTree

var passou := 0
var falhou := 0
const PRONTOS := ["rei", "slime_mae"]


func _initialize() -> void:
	load("res://scripts/controles.gd").configurar()
	_rodar.call_deferred()


func _rodar() -> void:
	for t: String in ["teste_vida_espera_fases", "teste_barra_no_hud", "teste_rei_fase3",
			"teste_slime_mae_salta_com_aviso", "teste_slime_mae_divide", "teste_invocados_somem_com_chefe"]:
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
