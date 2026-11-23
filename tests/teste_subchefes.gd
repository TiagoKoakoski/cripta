# godot --headless --path . --script res://tests/teste_subchefes.gd
# Subchefes: vida, espera, 2 fases, ataque característico e a chave.
extends SceneTree

var passou := 0
var falhou := 0
const SUBS := {"morcego_vampiro": 18, "esqueleto_capitao": 20, "aranha_tecela": 26, "slime_rei": 28,
	"mago_sombrio": 32, "fantasma_antigo": 30}


func _initialize() -> void:
	load("res://scripts/controles.gd").configurar()
	_rodar.call_deferred()


func _rodar() -> void:
	for t: String in ["teste_basico", "teste_morcego_mergulhos", "teste_capitao", "teste_tecela_teias",
			"teste_slime_rei_chave_depois_dos_filhos", "teste_mago_dois_teleportes", "teste_fantasma_some_com_aviso",
			"teste_chave_cai", "teste_slime_rei_divide_uma_vez"]:
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
	sala.configurar({"tipo": GeradorAndar.SUBCHEFE, "portas": {Vector2i.DOWN: GeradorAndar.COMBATE},
		"subchefe": nome, "limpa": false, "entrada": Vector2i.DOWN}, partida)
	return sala


func desmontar(sala: Sala) -> void:
	sala.queue_free()
	await process_frame


func vivos_do_tipo(sala: Sala, t: String) -> int:
	var n := 0
	for v: Variant in sala._inimigos:
		if is_instance_valid(v) and (v as Inimigo).vivo() and (v as Inimigo).tipo == t:
			n += 1
	return n


func tiros_inimigos(sala: Sala) -> int:
	return sala.get_children().filter(func(c: Node) -> bool: return c is Tiro and not (c as Tiro).do_jogador).size()


func teste_basico() -> void:
	for nome: String in SUBS:
		var sala := montar(nome)
		var c := sala.chefe()
		checa(c != null and c.hp == SUBS[nome] and c.fases == 2, "%s: vida %d, 2 fases" % [nome, SUBS[nome]])
		var p0 := c.position
		await frames(80)
		checa(tiros_inimigos(sala) == 0 and c.position.distance_to(p0) < 1.0, "%s: espera inicial" % nome)
		var fases := []
		c.fase_mudou.connect(func(n: int) -> void: fases.append(n))
		await frames(30)
		c.levar_tiro(c.hp - c.hp_max / 2)
		await frames(5)
		checa(fases == [2], "%s: fase 2 na metade (%s)" % [nome, fases])
		await desmontar(sala)


func teste_morcego_mergulhos() -> void:
	var sala := montar("morcego_vampiro")
	var c := sala.chefe()
	var mergulhos := 0
	var antes := ""
	for i in 60 * 7:
		await physics_frame
		var e: String = c.call("estado_atual")
		if e == "mergulho" and antes != "mergulho":
			mergulhos += 1
		antes = e
	checa(mergulhos >= 3, "Morcego Vampiro: mergulhos em sequência (%d)" % mergulhos)
	c.levar_tiro(c.hp - c.hp_max / 2)
	await frames(10)
	checa(vivos_do_tipo(sala, "morcego") == 2, "fase 2: chama 2 morcegos")
	await desmontar(sala)


func teste_capitao() -> void:
	var sala := montar("esqueleto_capitao")
	var c := sala.chefe()
	var leque := false
	for i in 60 * 5:
		await physics_frame
		if c.ultima_rajada == 3:
			leque = true
			break
	checa(leque, "Capitão: leque de 3")
	c.levar_tiro(c.hp - c.hp_max / 2)
	var aviso := 0.0
	var aviso_antes := -1.0
	for i in 60 * 8:
		await physics_frame
		var e: String = c.call("estado_atual")
		if e == "investida":
			aviso_antes = aviso
			break
		aviso = aviso + 1.0 / 60.0 if e == "aviso" else 0.0
	checa(aviso_antes >= 0.48, "Capitão fase 2: investida avisada (%.2f)" % aviso_antes)
	await desmontar(sala)


func teste_tecela_teias() -> void:
	var sala := montar("aranha_tecela")
	var c := sala.chefe()
	var poca := false
	var rajada := 0
	for i in 60 * 7:
		await physics_frame
		rajada = maxi(rajada, c.ultima_rajada)
		for ch: Node in sala.get_children():
			if ch is PocaTeia:
				poca = true
		if poca and rajada >= 4:
			break
	checa(rajada == 4 and poca, "Tecelã: teias em cruz (4) que viram poças")
	await desmontar(sala)


func teste_slime_rei_chave_depois_dos_filhos() -> void:
	var sala := montar("slime_rei")
	await frames(100)
	sala.chefe().levar_tiro(999)
	await frames(5)
	checa(vivos_do_tipo(sala, "slime") == 2 and not sala.aberta() and not sala.chave_no_chao(),
		"Slime Rei morre e vira 2 slimes grandes; sem chave ainda")
	for k in 6:
		for v: Variant in sala._inimigos.duplicate():
			if is_instance_valid(v) and (v as Inimigo).vivo():
				(v as Inimigo).levar_tiro(99)
		await frames(5)
	checa(sala.vivos() == 0 and sala.aberta() and sala.chave_no_chao(), "filhos mortos: sala abre e a chave cai")
	await desmontar(sala)


func teste_mago_dois_teleportes() -> void:
	var sala := montar("mago_sombrio")
	var c := sala.chefe()
	var teleportes := 0
	var antes := ""
	var ok := false
	for i in 60 * 8:
		await physics_frame
		var e: String = c.call("estado_atual")
		if e == "aparecer" and antes != "aparecer":
			teleportes += 1
		if c.ultima_rajada == 5:
			ok = teleportes == 2
			break
		antes = e
	checa(ok, "Mago Sombrio: 2 teleportes e depois leque de 5 (%d)" % teleportes)
	await desmontar(sala)


func teste_fantasma_some_com_aviso() -> void:
	var sala := montar("fantasma_antigo")
	var c := sala.chefe()
	var sumiu := false
	var invul := true
	var aviso := 0.0
	var aviso_antes := -1.0
	for i in 60 * 10:
		await physics_frame
		var e: String = c.call("estado_atual")
		if e == "invisivel":
			sumiu = true
			invul = invul and c.invulneravel() and not c.perigoso()
		if sumiu and e == "perseguir":
			aviso_antes = aviso
			break
		aviso = aviso + 1.0 / 60.0 if e == "reaparecer" else 0.0
	checa(sumiu and invul, "Fantasma Antigo some (invulnerável e sem contato)")
	checa(aviso_antes >= 0.38, "avisa antes de reaparecer (%.2f)" % aviso_antes)
	await desmontar(sala)


func teste_chave_cai() -> void:
	for nome: String in ["morcego_vampiro", "mago_sombrio"]:
		var sala := montar(nome)
		var caiu := [false]
		sala.chave_caiu.connect(func() -> void: caiu[0] = true)
		await frames(100)
		sala.chefe().levar_tiro(999)
		await frames(10)
		checa(caiu[0] and sala.chave_no_chao() and sala.vivos() == 0, "%s: morte solta a chave" % nome)
		await desmontar(sala)


func teste_slime_rei_divide_uma_vez() -> void:
	var sala := montar("slime_rei")
	await frames(100)
	var c := sala.chefe()
	c.hp = 1
	c.levar_tiro(1)
	c.levar_tiro(1)   # segundo acerto no mesmo quadro (ex.: duas poças de fogo)
	await frames(5)
	checa(vivos_do_tipo(sala, "slime") == 2, "Slime Rei divide uma vez só (%d slimes)" % vivos_do_tipo(sala, "slime"))
	await desmontar(sala)
