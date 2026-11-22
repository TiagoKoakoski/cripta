# godot --headless --path . --script res://tests/teste_tiros.gd
# Itens que mudam o tiro: cada efeito numa sala de verdade.
extends SceneTree

var passou := 0
var falhou := 0


func _initialize() -> void:
	load("res://scripts/controles.gd").configurar()
	_rodar.call_deferred()


func _rodar() -> void:
	for t: String in ["teste_ricochete", "teste_perfurante", "teste_teleguiado", "teste_explosivo",
			"teste_explosao_abre_sala", "teste_gelo", "teste_retaguarda", "teste_build_completa_some",
			"teste_cor_do_tiro", "teste_ricochete_nao_escapa"]:
		await call(t)
	print("Resultado: %d ok, %d falhas" % [passou, falhou])
	quit(1 if falhou > 0 else 0)


func checa(cond: bool, rotulo: String) -> void:
	if cond:
		passou += 1
	else:
		falhou += 1
		push_error("FALHOU " + rotulo)


func montar(inimigos: Array) -> Sala:
	var partida := Partida.new()
	partida.arquivo_recorde = "user://teste_recorde.cfg"
	partida.comecar(1)
	partida.vida = 99
	partida.vida_max = 8
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


func tiro(sala: Sala, pos: Vector2, dir: Vector2, dano := 1, vel := 180.0, dur := 3.0) -> Tiro:
	var t := Tiro.criar(pos, dir, true, dano, vel, dur)
	t.aplicar_build(sala.partida)
	sala.add_child(t)
	return t


func esqueleto(sala: Sala, pos: Vector2) -> Inimigo:
	for v: Variant in sala._inimigos:
		var e := v as Inimigo
		if e.position == pos:
			return e
	return null


func teste_ricochete() -> void:
	var sala := montar([])
	sala.partida.ricochete = true
	var t := tiro(sala, Vector2(280, 88), Vector2.RIGHT, 1, 180.0, 5.0)
	await frames(20)
	checa(is_instance_valid(t) and t.direcao.x < 0.0, "ricochete: tiro volta da parede")
	var sumiu := false
	for i in 120:
		await physics_frame
		if not is_instance_valid(t):
			sumiu = true
			break
	checa(sumiu, "ricochete: some no segundo choque (antes de acabar a duração)")
	await desmontar(sala)


func teste_perfurante() -> void:
	var sala := montar([{"tipo": "esqueleto", "pos": Vector2(230, 88)}, {"tipo": "esqueleto", "pos": Vector2(270, 88)}])
	sala.partida.perfurante = true
	await frames(40)   # depois do surgimento
	tiro(sala, Vector2(190, 88), Vector2.RIGHT, 3, 300.0, 1.0)
	await frames(30)
	checa(sala.vivos() == 0, "perfurante: 1 tiro atravessa e mata 2 em fila (vivos %d)" % sala.vivos())
	await desmontar(sala)


func teste_teleguiado() -> void:
	var sala := montar([{"tipo": "esqueleto", "pos": Vector2(170, 40)}])
	sala.partida.teleguiado = true
	await frames(40)
	var e := esqueleto(sala, Vector2(170, 40))
	tiro(sala, Vector2(110, 88), Vector2.RIGHT, 1, 150.0, 2.0)
	await frames(90)
	checa(e.hp < 3, "teleguiado: tiro curva e acerta quem está fora da linha (hp %d)" % e.hp)
	await desmontar(sala)


func teste_explosivo() -> void:
	var sala := montar([{"tipo": "esqueleto", "pos": Vector2(230, 88)}, {"tipo": "esqueleto", "pos": Vector2(230, 106)}])
	sala.partida.explosivo = true
	await frames(40)
	var vizinho := esqueleto(sala, Vector2(230, 106))
	tiro(sala, Vector2(190, 88), Vector2.RIGHT, 2, 300.0, 1.0)
	await frames(30)
	checa(vizinho.hp < 3, "explosivo: o vizinho também leva dano (hp %d)" % vizinho.hp)
	await desmontar(sala)


func teste_explosao_abre_sala() -> void:
	var sala := montar([{"tipo": "esqueleto", "pos": Vector2(230, 88)}, {"tipo": "esqueleto", "pos": Vector2(230, 104)}])
	sala.partida.explosivo = true
	await frames(40)
	for v: Variant in sala._inimigos:
		(v as Inimigo).hp = 1
	tiro(sala, Vector2(190, 88), Vector2.RIGHT, 2, 300.0, 1.0)
	await frames(30)
	checa(sala.vivos() == 0 and sala.aberta(), "explosão que mata 2 de uma vez abre a sala")
	await desmontar(sala)


func teste_gelo() -> void:
	var sala := montar([{"tipo": "esqueleto", "pos": Vector2(230, 88)}])
	sala.partida.gelo = true
	await frames(40)
	var e := esqueleto(sala, Vector2(230, 88))
	tiro(sala, Vector2(190, 88), Vector2.RIGHT, 1, 300.0, 1.0)
	await frames(20)
	checa(e.lento > 1.0, "gelo: inimigo fica lento (%.2f s)" % e.lento)
	await frames(150)
	checa(e.lento == 0.0, "gelo: passa depois de 2 s")
	await desmontar(sala)


func teste_retaguarda() -> void:
	var sala := montar([])
	sala.partida.retaguarda = true
	Input.action_press("atirar_direita")
	await frames(3)
	Input.action_release("atirar_direita")
	var tras := sala.tiros_do_jogador().filter(func(t: Tiro) -> bool: return t.direcao.x < 0.0)
	checa(tras.size() >= 1, "retaguarda: sai um tiro para trás")
	await desmontar(sala)


func teste_build_completa_some() -> void:
	var sala := montar([{"tipo": "morcego", "pos": Vector2(60, 40)}, {"tipo": "slime", "pos": Vector2(260, 136)}])
	for it: String in Partida.ITENS:
		sala.partida.pegar_item(it)
	Input.action_press("atirar_direita")
	await frames(30)
	Input.action_release("atirar_direita")
	await frames(90)   # duração máxima do tiro (alcance) é 0,9 s
	checa(sala.tiros_do_jogador().is_empty(), "build com todos os itens: nenhum tiro eterno (%d)" % sala.tiros_do_jogador().size())
	await desmontar(sala)


func teste_cor_do_tiro() -> void:
	var sala := montar([])
	var simples := tiro(sala, Vector2(160, 88), Vector2.UP)
	sala.partida.gelo = true
	var gelado := tiro(sala, Vector2(160, 88), Vector2.UP)
	checa(simples.modulate != gelado.modulate, "tiro muda de cor com o gelo")
	await desmontar(sala)


func teste_ricochete_nao_escapa() -> void:
	var sala := montar([])
	sala.partida.ricochete = true
	var escapou := 0
	for ang: float in [225.0, 315.0, 45.0, 135.0, 200.0, 340.0]:
		for origem: Vector2 in [Vector2(40, 40), Vector2(280, 40), Vector2(40, 136), Vector2(280, 136)]:
			var t := tiro(sala, origem, Vector2.RIGHT.rotated(deg_to_rad(ang)), 1, 180.0, 4.0)
			for i in 240:
				await physics_frame
				if not is_instance_valid(t):
					break
				if t.position.x < 0 or t.position.x > 320 or t.position.y < 0 or t.position.y > 176:
					escapou += 1
					t.queue_free()
					break
	checa(escapou == 0, "ricochete diagonal não atravessa canto (%d escaparam)" % escapou)
	await desmontar(sala)
