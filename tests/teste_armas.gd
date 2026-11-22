# godot --headless --path . --script res://tests/teste_armas.gd
# Alquimista (frasco que explode em área) e Caçador (bumerangue que vai e volta).
extends SceneTree

var passou := 0
var falhou := 0


func _initialize() -> void:
	load("res://scripts/controles.gd").configurar()
	_rodar.call_deferred()


func _rodar() -> void:
	for t: String in ["teste_bases", "teste_frasco_cai_e_explode", "teste_frasco_alcance", "teste_frasco_triplo",
			"teste_frasco_fogo", "teste_frasco_teleguiado", "teste_frasco_retaguarda",
			"teste_bumerangue_vai_e_volta", "teste_bumerangue_acerta_ida_e_volta", "teste_bumerangue_um_so",
			"teste_bumerangue_triplo", "teste_bumerangue_segue_jogador", "teste_descricoes"]:
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


func montar(quem: String, inimigos: Array, itens: Array = []) -> Sala:
	var partida := Partida.new()
	partida.arquivo_recorde = "user://teste_progresso.cfg"
	partida.comecar(1, quem)
	partida.vida = 99
	for it: String in itens:
		partida.pegar_item(it)
	var sala := Sala.new()
	root.add_child(sala)
	sala.configurar({"tipo": GeradorAndar.COMBATE, "portas": {}, "layout": 0, "inimigos": inimigos,
		"limpa": false, "entrada": Vector2i.ZERO}, partida)
	return sala


func desmontar(sala: Sala) -> void:
	for a: String in ["atirar_cima", "atirar_baixo", "atirar_esquerda", "atirar_direita", "mover_esquerda"]:
		Input.action_release(a)
	sala.queue_free()
	await process_frame


func ataque(acao: String) -> void:
	Input.action_press(acao)
	await frames(2)
	Input.action_release(acao)


func perto(sala: Sala, pos: Vector2) -> Inimigo:
	var melhor: Inimigo = null
	for v: Variant in sala._inimigos:
		if is_instance_valid(v) and (melhor == null or (v as Inimigo).position.distance_to(pos) < melhor.position.distance_to(pos)):
			melhor = v
	return melhor


func esq(pos: Vector2) -> Dictionary:
	return {"tipo": "esqueleto", "pos": pos}


func filhos(sala: Sala, classe: String) -> Array:
	return sala.get_children().filter(func(c: Node) -> bool: return c.get_script() and (c.get_script() as Script).get_global_name() == classe)


func teste_bases() -> void:
	var p := Partida.new()
	p.arquivo_recorde = "user://teste_progresso.cfg"
	p.comecar(1, "alquimista")
	checa([p.vida, p.velocidade, p.dano, p.cadencia] == [3, 70.0, 2, 0.7], "alquimista: 3, 70, dano 2, 0,7 s")
	p.comecar(1, "cacador")
	checa([p.vida, p.velocidade, p.dano] == [3, 85.0, 1], "caçador: 3, 85, dano 1")
	checa(Partida.PERSONAGENS.size() == 4, "4 personagens")


func teste_frasco_cai_e_explode() -> void:
	var sala := montar("alquimista", [esq(Vector2(224, 88)), esq(Vector2(224, 104)), esq(Vector2(160, 40))])
	await frames(40)
	await ataque("atirar_direita")
	await frames(60)
	checa(perto(sala, Vector2(224, 88)).hp < 3 and perto(sala, Vector2(224, 104)).hp < 3, "frasco cai a 64 px e explode em área")
	checa(perto(sala, Vector2(160, 40)).hp == 3, "fora do raio não leva dano")
	await desmontar(sala)


func teste_frasco_alcance() -> void:
	var sala := montar("alquimista", [esq(Vector2(256, 88))], ["alcance"])
	await frames(40)
	await ataque("atirar_direita")
	await frames(70)
	checa(perto(sala, Vector2(256, 88)).hp < 3, "alcance: frasco cai a 96 px")
	await desmontar(sala)


func teste_frasco_triplo() -> void:
	var sala := montar("alquimista", [], ["tiro_triplo"])
	await ataque("atirar_direita")
	await frames(1)
	checa(filhos(sala, "Frasco").size() == 3, "tiro triplo: 3 frascos (%d)" % filhos(sala, "Frasco").size())
	await desmontar(sala)


func teste_frasco_fogo() -> void:
	var sala := montar("alquimista", [], ["perfurante"])
	await ataque("atirar_direita")
	await frames(60)
	checa(sala.get_children().any(func(n: Node) -> bool: return n is PocaFogo and (n as PocaFogo).do_jogador), "perfurante: explosão deixa fogo")
	await desmontar(sala)


func teste_frasco_teleguiado() -> void:
	var sala := montar("alquimista", [esq(Vector2(210, 130))], ["teleguiado"])
	await frames(40)
	await ataque("atirar_direita")
	await frames(70)
	checa(perto(sala, Vector2(210, 130)).hp < 3, "teleguiado: frasco cai no inimigo perto da mira")
	await desmontar(sala)


func teste_frasco_retaguarda() -> void:
	var sala := montar("alquimista", [esq(Vector2(96, 88))], ["retaguarda"])
	await frames(40)
	await ataque("atirar_direita")
	await frames(60)
	checa(perto(sala, Vector2(96, 88)).hp < 3, "retaguarda: frasco também para trás")
	await desmontar(sala)


func teste_bumerangue_vai_e_volta() -> void:
	var sala := montar("cacador", [])
	await ataque("atirar_direita")
	await frames(1)
	var b: Node2D = filhos(sala, "Bumerangue")[0] if filhos(sala, "Bumerangue").size() > 0 else null
	checa(b != null, "caçador lança bumerangue")
	var max_x := 0.0
	var voltou := false
	for i in 60 * 4:
		await physics_frame
		if not is_instance_valid(b):
			voltou = true
			break
		max_x = maxf(max_x, b.position.x - sala.jogador.position.x)
	checa(max_x >= 80.0 and max_x <= 100.0, "vai uns 90 px (%.0f)" % max_x)
	checa(voltou, "volta à mão e some")
	await desmontar(sala)


func teste_bumerangue_acerta_ida_e_volta() -> void:
	var sala := montar("cacador", [esq(Vector2(210, 88))])
	sala.partida.dano = 1
	await frames(40)
	await ataque("atirar_direita")
	await frames(120)
	checa(perto(sala, Vector2(210, 88)).hp == 1, "acerta na ida e na volta (hp %d)" % perto(sala, Vector2(210, 88)).hp)
	await desmontar(sala)


func teste_bumerangue_um_so() -> void:
	var sala := montar("cacador", [])
	Input.action_press("atirar_direita")
	await frames(40)
	Input.action_release("atirar_direita")
	checa(filhos(sala, "Bumerangue").size() == 1, "só 1 bumerangue no ar (%d)" % filhos(sala, "Bumerangue").size())
	await desmontar(sala)


func teste_bumerangue_triplo() -> void:
	var sala := montar("cacador", [], ["tiro_triplo"])
	Input.action_press("atirar_direita")
	await frames(40)
	Input.action_release("atirar_direita")
	checa(filhos(sala, "Bumerangue").size() == 2, "tiro triplo: 2 bumerangues (%d)" % filhos(sala, "Bumerangue").size())
	await desmontar(sala)


func teste_bumerangue_segue_jogador() -> void:
	var sala := montar("cacador", [])
	await ataque("atirar_direita")
	Input.action_press("mover_esquerda")
	var voltou := false
	for i in 60 * 5:
		await physics_frame
		if filhos(sala, "Bumerangue").is_empty():
			voltou = true
			break
	Input.action_release("mover_esquerda")
	checa(voltou, "bumerangue volta mesmo com o jogador andando")
	await desmontar(sala)


func teste_descricoes() -> void:
	var ok := true
	for it: String in ["tiro_triplo", "alcance", "ricochete", "perfurante", "teleguiado", "explosivo", "retaguarda"]:
		for quem: String in ["alquimista", "cacador"]:
			ok = ok and Hud.descricao(it, quem) != Hud.descricao(it, "atirador")
	checa(ok, "itens de tiro têm descrição própria para alquimista e caçador")
