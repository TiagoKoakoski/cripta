# godot --headless --path . --script res://tests/teste_inimigos.gd
# Inimigos novos (aranha, fantasma, olho, mago), surgimento e empurrão.
extends SceneTree

var passou := 0
var falhou := 0


func _initialize() -> void:
	load("res://scripts/controles.gd").configurar()
	_rodar.call_deferred()


func _rodar() -> void:
	for t: String in ["teste_aranha_salta", "teste_fantasma_atravessa_pilar", "teste_fantasma_fica_na_sala",
			"teste_olho_cruz_e_x", "teste_mago_teleporta_e_atira", "teste_surgindo_nao_fere",
			"teste_surgindo_tranca", "teste_empurrao", "teste_novos_morrem_e_abrem", "teste_distribuicao",
			"teste_animacao_detalhado"]:
		await call(t)
	print("Resultado: %d ok, %d falhas" % [passou, falhou])
	quit(1 if falhou > 0 else 0)


func checa(cond: bool, rotulo: String) -> void:
	if cond:
		passou += 1
	else:
		falhou += 1
		push_error("FALHOU " + rotulo)


func montar(inimigos: Array, layout := 0) -> Sala:
	var partida := Partida.new()
	partida.arquivo_recorde = "user://teste_recorde.cfg"
	partida.comecar(1)
	partida.vida = 99
	partida.vida_max = 8
	var sala := Sala.new()
	root.add_child(sala)
	sala.configurar({"tipo": GeradorAndar.COMBATE, "portas": {}, "layout": layout, "inimigos": inimigos,
		"limpa": false, "entrada": Vector2i.ZERO}, partida)
	return sala


func desmontar(sala: Sala) -> void:
	sala.queue_free()
	await process_frame


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func primeiro(sala: Sala) -> Inimigo:
	return sala._inimigos[0] as Inimigo


func dentro(p: Vector2) -> bool:
	return p.x >= 16.0 and p.x <= 304.0 and p.y >= 16.0 and p.y <= 160.0


func teste_aranha_salta() -> void:
	var sala := montar([{"tipo": "aranha", "pos": Vector2(60, 140)}])
	var e := primeiro(sala)
	var d0 := e.position.distance_to(sala.jogador.position)
	var parada := 0
	var rapida := 0
	for i in 180:
		await physics_frame
		if not is_instance_valid(e):
			break
		if e.velocity.length() < 1.0:
			parada += 1
		elif e.velocity.length() > 120.0:
			rapida += 1
	var d1 := e.position.distance_to(sala.jogador.position) if is_instance_valid(e) else 0.0
	checa(d1 < d0 - 30.0, "aranha se aproxima (%.0f -> %.0f)" % [d0, d1])
	checa(parada > 20 and rapida > 5, "aranha anda em saltos (parada %d, rápida %d)" % [parada, rapida])
	await desmontar(sala)


func teste_fantasma_atravessa_pilar() -> void:
	# pilar no tile (4,3) = centro (72,56); fantasma à esquerda, jogador à direita na mesma linha
	var sala := montar([{"tipo": "fantasma", "pos": Vector2(40, 56)}])
	sala.jogador.position = Vector2(120, 56)
	var e := primeiro(sala)
	var passou_pilar := false
	for i in 60 * 6:
		await physics_frame
		if e.position.x > 84.0:
			passou_pilar = true
			break
	checa(passou_pilar, "fantasma atravessa o pilar (x=%.0f)" % e.position.x)
	await desmontar(sala)


func teste_fantasma_fica_na_sala() -> void:
	var sala := montar([{"tipo": "fantasma", "pos": Vector2(40, 40)}])
	var e := primeiro(sala)
	var ok := true
	for i in 60 * 8:
		if i % 60 == 0:   # jogador "foge" pelos cantos
			sala.jogador.position = [Vector2(24, 24), Vector2(296, 152), Vector2(296, 24), Vector2(24, 152)][(i / 60) % 4]
		await physics_frame
		ok = ok and dentro(e.position)
	checa(ok, "fantasma não sai da sala (%.0f, %.0f)" % [e.position.x, e.position.y])
	await desmontar(sala)


func tiros_inimigos(sala: Sala) -> Array:
	return sala.get_children().filter(func(c: Node) -> bool: return c is Tiro and not (c as Tiro).do_jogador)


func teste_olho_cruz_e_x() -> void:
	var sala := montar([{"tipo": "olho", "pos": Vector2(240, 88)}])
	var rajadas: Array = []
	var vistos := {}
	for i in 60 * 6:
		await physics_frame
		var novos: Array = []
		for t: Tiro in tiros_inimigos(sala):
			if not vistos.has(t.get_instance_id()):
				vistos[t.get_instance_id()] = true
				novos.append(t.direcao)
		if novos.size() > 0:
			rajadas.append(novos)
		if rajadas.size() >= 2:
			break
	checa(rajadas.size() >= 2 and rajadas[0].size() == 4 and rajadas[1].size() == 4, "olho solta rajadas de 4")
	if rajadas.size() >= 2:
		var cruz: bool = rajadas[0].all(func(d: Vector2) -> bool: return absf(d.x) < 0.01 or absf(d.y) < 0.01)
		var xis: bool = rajadas[1].all(func(d: Vector2) -> bool: return absf(absf(d.x) - absf(d.y)) < 0.01)
		checa(cruz and xis, "olho alterna cruz e X")
	await desmontar(sala)


func teste_mago_teleporta_e_atira() -> void:
	var sala := montar([{"tipo": "mago", "pos": Vector2(200, 88)}])
	var e := primeiro(sala)
	var p0 := e.position
	var teleportou := false
	var longe := true
	var leque := 0
	var vistos := {}
	for i in 60 * 7:
		await physics_frame
		if e.position.distance_to(p0) > 40.0 and not teleportou:
			teleportou = true
			longe = e.position.distance_to(sala.jogador.position) >= 80.0 and dentro(e.position)
		for t: Tiro in tiros_inimigos(sala):
			if not vistos.has(t.get_instance_id()):
				vistos[t.get_instance_id()] = true
				leque += 1
		if teleportou and leque >= 3:
			break
	checa(teleportou and longe, "mago teleporta para longe do jogador e dentro da sala")
	checa(leque >= 3, "mago atira leque de 3 (%d)" % leque)
	await desmontar(sala)


func teste_surgindo_nao_fere() -> void:
	var sala := montar([{"tipo": "slime", "pos": Vector2(160, 88)}])
	sala.partida.vida = 6
	await frames(20)   # 0,33 s: ainda surgindo, em cima do jogador
	checa(sala.partida.vida == 6, "inimigo surgindo não fere (vida %d)" % sala.partida.vida)
	checa(primeiro(sala).surgindo(), "inimigo começa surgindo")
	await frames(30)
	checa(not primeiro(sala).surgindo(), "surgimento acaba em 0,5 s")
	await desmontar(sala)


func teste_surgindo_tranca() -> void:
	var sala := montar([{"tipo": "aranha", "pos": Vector2(60, 40)}])
	checa(sala.vivos() == 1 and not sala.aberta(), "sala tranca enquanto o inimigo surge")
	await desmontar(sala)


func teste_empurrao() -> void:
	var sala := montar([{"tipo": "esqueleto", "pos": Vector2(220, 88)}])
	await frames(40)
	var e := primeiro(sala)
	var x0 := e.position.x
	e.levar_tiro(1, Vector2.RIGHT)
	await frames(10)
	checa(e.position.x > x0 + 3.0, "acerto empurra o inimigo (%.1f -> %.1f)" % [x0, e.position.x])
	await desmontar(sala)


func teste_novos_morrem_e_abrem() -> void:
	var ini := []
	for t: String in ["aranha", "fantasma", "olho", "mago"]:
		ini.append(t)
	var sala := montar(ini)
	await frames(40)
	checa(sala.vivos() == 4, "4 inimigos novos vivos")
	for v: Variant in sala._inimigos.duplicate():
		(v as Inimigo).levar_tiro(99)
	await frames(3)
	checa(sala.vivos() == 0 and sala.aberta(), "inimigos novos morrem e a sala abre")
	await desmontar(sala)


func teste_distribuicao() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var perto_ok := true
	var viu_mago := false
	var no_max_um := true
	for i in 300:
		var perto := Andar.sortear_inimigos(rng, 1, 1)
		perto_ok = perto_ok and perto.all(func(t: String) -> bool: return t in ["morcego", "slime", "aranha"])
		var longe := Andar.sortear_inimigos(rng, 5, 3)
		viu_mago = viu_mago or "mago" in longe
		no_max_um = no_max_um and longe.count("mago") <= 1 and longe.count("olho") <= 1 and longe.size() == 6
	checa(perto_ok, "perto do início só morcego, slime e aranha")
	checa(viu_mago and no_max_um, "andar 3 longe aparece o mago; 6 inimigos; no máximo 1 olho e 1 mago")


## detalhado: quem anda não flutua (pés no chão), voador balança; personagem tem passos de verdade
func teste_animacao_detalhado() -> void:
	Visual.arquivo = "user://teste_config.cfg"
	Visual.definir_modo("detalhado")
	var sala := montar([{"tipo": "esqueleto", "pos": Vector2(60, 140)}, {"tipo": "morcego", "pos": Vector2(250, 40)}])
	var esq: Inimigo = sala._inimigos[0]
	var morc: Inimigo = sala._inimigos[1]
	var ofs_esq := {}
	var ofs_morc := {}
	for i in 90:
		await physics_frame
		ofs_esq[snappedf(esq._sprite.offset.y, 0.1)] = true
		ofs_morc[snappedf(morc._sprite.offset.y, 0.1)] = true
	checa(ofs_esq.keys() == [0.0], "esqueleto não sobe e desce no ar (%s)" % [ofs_esq.keys()])
	checa(ofs_morc.size() > 3, "morcego balança no ar")
	var j := sala.jogador
	checa(j._sprite.hframes == 16, "personagem detalhado: 16 quadros (%d)" % j._sprite.hframes)
	var quadros := {}
	Input.action_press("mover_direita")
	for i in 40:
		await physics_frame
		quadros[j._sprite.frame] = true
	Input.action_release("mover_direita")
	checa(quadros.size() == 4 and quadros.keys().all(func(q: int) -> bool: return q >= 4 and q <= 7),
		"andando para a direita passa pelos 4 quadros 4..7 (%s)" % [quadros.keys()])
	for i in 3:
		await physics_frame
	checa(j._sprite.frame == 5, "parado: quadro de passagem da direção (%d)" % j._sprite.frame)
	Visual.definir_modo("classico")
	checa(j._sprite.hframes == 8 and esq._sprite.offset.y == 0.0, "clássico continua com 8 quadros")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Visual.arquivo))
	await desmontar(sala)
