# godot --headless --path . --script res://tests/teste_obstaculos.gd
# Layouts com obstáculos: pilar/pedra (sólidos), caixa (quebra), buraco (só quem anda), espinhos (ferem).
extends SceneTree

var passou := 0
var falhou := 0
const BLOQUEIA := ["P", "R", "C", "B"]


func _initialize() -> void:
	load("res://scripts/controles.gd").configurar()
	_rodar.call_deferred()


func _rodar() -> void:
	for t: String in ["teste_formato", "teste_layouts_conexos", "teste_nascimento_livre", "teste_buraco",
			"teste_caixa_quebra_com_cada_arma", "teste_espinhos", "teste_andar_usa_layouts"]:
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


func teste_formato() -> void:
	var ok := Sala.LAYOUTS.size() >= 14
	for l: Array in Sala.LAYOUTS:
		ok = ok and l.size() == 9
		for y in 9:
			var linha: String = l[y]
			ok = ok and linha.length() == 18
			for x in 18:
				var c := linha[x]
				ok = ok and c in [".", "P", "R", "C", "B", "E"]
				if y == 4 or x == 8 or x == 9:   # corredores das portas livres
					ok = ok and c == "."
	checa(ok, "14+ layouts 18x9, só letras válidas, corredores das portas livres (%d)" % Sala.LAYOUTS.size())


func teste_layouts_conexos() -> void:
	var ruins := []
	for i in Sala.LAYOUTS.size():
		var l: Array = Sala.LAYOUTS[i]
		var vistos := {}
		var fila: Array[Vector2i] = [Vector2i(8, 0), Vector2i(9, 8), Vector2i(0, 4), Vector2i(17, 4)]
		for f: Vector2i in fila:
			vistos[f] = true
		while not fila.is_empty():
			var p: Vector2i = fila.pop_front()
			for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var q := p + d
				if q.x < 0 or q.y < 0 or q.x >= 18 or q.y >= 9 or vistos.has(q):
					continue
				if (l[q.y] as String)[q.x] in BLOQUEIA:
					continue
				vistos[q] = true
				fila.append(q)
		for y in 9:
			for x in 18:
				if not (l[y] as String)[x] in BLOQUEIA and not vistos.has(Vector2i(x, y)):
					ruins.append([i, x, y])
	checa(ruins.is_empty(), "todo chão alcançável a partir das portas %s" % [ruins.slice(0, 5)])


func teste_nascimento_livre() -> void:
	var ok := true
	for i in Sala.LAYOUTS.size():
		for e: Vector2i in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var ps := Sala.posicoes_inimigos(i, e)
			ok = ok and ps.size() >= 3
			for p: Vector2 in ps:
				ok = ok and not Sala.encosta_obstaculo(p, i)
	checa(ok, "todo layout tem 3+ pontos de nascimento livres por entrada")


func montar(layout: int, inimigos: Array = [], quem := "atirador") -> Sala:
	var partida := Partida.new()
	partida.arquivo_recorde = "user://teste_progresso.cfg"
	partida.comecar(1, quem)
	partida.vida = 99
	var sala := Sala.new()
	root.add_child(sala)
	sala.configurar({"tipo": GeradorAndar.COMBATE, "portas": {}, "layout": layout, "inimigos": inimigos,
		"limpa": inimigos.is_empty(), "entrada": Vector2i.ZERO}, partida)
	return sala


func desmontar(sala: Sala) -> void:
	for a: String in ["atirar_cima", "atirar_baixo", "atirar_esquerda", "atirar_direita", "mover_direita", "mover_esquerda"]:
		Input.action_release(a)
	sala.queue_free()
	await process_frame


## layout de teste: só a célula (x, y) do interior com a letra dada
func layout_com(letra: String, cel: Vector2i) -> int:
	var linhas := []
	for y in 9:
		var l := ".................."
		if y == cel.y:
			l = l.substr(0, cel.x) + letra + l.substr(cel.x + 1)
		linhas.append(l)
	Sala.LAYOUTS.append(linhas)
	return Sala.LAYOUTS.size() - 1


func centro(cel: Vector2i) -> Vector2:
	return Vector2(cel + Vector2i(1, 1)) * 16.0 + Vector2(8, 8)


func teste_buraco() -> void:
	var cel := Vector2i(12, 4 - 1)
	var li := layout_com("B", cel)
	var sala := montar(li)
	var c := centro(cel)
	sala.jogador.position = c + Vector2(-24, 0)
	Input.action_press("mover_direita")
	await frames(60)
	Input.action_release("mover_direita")
	checa(sala.jogador.position.x < c.x - 8.0, "buraco segura o jogador (x=%.0f, buraco em %.0f)" % [sala.jogador.position.x, c.x])
	var t := Tiro.criar(c + Vector2(-30, 0), Vector2.RIGHT, true, 1, 120.0, 1.0)
	sala.add_child(t)
	await frames(30)
	checa(is_instance_valid(t) and t.position.x > c.x + 8.0, "tiro passa por cima do buraco")
	sala._criar_inimigo("slime", c + Vector2(-26, 0))
	sala._criar_inimigo("morcego", c + Vector2(-26, 6))
	await frames(2)
	var slime: Inimigo = sala._inimigos[0]
	var morcego: Inimigo = sala._inimigos[1]
	checa(slime.collision_mask & Camadas.BURACO != 0 and morcego.collision_mask & Camadas.BURACO == 0,
		"slime não atravessa buraco; morcego voa por cima")
	await desmontar(sala)


func teste_caixa_quebra_com_cada_arma() -> void:
	for quem: String in ["atirador", "espadachim", "alquimista", "cacador"]:
		var cel := Vector2i(12, 3)
		var li := layout_com("C", cel)
		var sala := montar(li, [], quem)
		var c := centro(cel)
		checa(sala.caixas() == 1, "%s: sala tem 1 caixa" % quem)
		var dist := {"atirador": 40.0, "espadachim": 18.0, "alquimista": 64.0, "cacador": 50.0}[quem] as float
		sala.jogador.position = c + Vector2(-dist, 0)
		for k in 4:
			Input.action_press("atirar_direita")
			await frames(45)
			Input.action_release("atirar_direita")
			await frames(40)
			if sala.caixas() == 0:
				break
		checa(sala.caixas() == 0, "%s quebra a caixa" % quem)
		await desmontar(sala)
	# explosão também quebra
	var li2 := layout_com("C", Vector2i(12, 3))
	var s2 := montar(li2)
	Tiro.explodir_em(s2, centro(Vector2i(12, 3)) + Vector2(-10, 0), 4, null)
	Tiro.explodir_em(s2, centro(Vector2i(12, 3)) + Vector2(-10, 0), 4, null)
	await frames(3)
	checa(s2.caixas() == 0, "explosão quebra caixa")
	await desmontar(s2)


func teste_espinhos() -> void:
	var cel := Vector2i(12, 3)
	var li := layout_com("E", cel)
	var sala := montar(li)
	sala.partida.vida = 5
	sala.partida.invencivel = 0.0
	sala.jogador.position = centro(cel)
	await frames(5)
	checa(sala.partida.vida == 4, "espinho fere quem pisa (vida %d)" % sala.partida.vida)
	await desmontar(sala)


func teste_andar_usa_layouts() -> void:
	var usados := {}
	for s in 20:
		var p := Partida.new()
		p.arquivo_recorde = "user://teste_progresso.cfg"
		p.comecar(s)
		var a := Andar.new()
		root.add_child(a)
		a.iniciar(p, s)
		for pos: Vector2i in a._cfg:
			usados[a._cfg[pos]["layout"]] = true
		a.queue_free()
		await process_frame
	checa(usados.size() >= 12, "andares sorteiam entre os layouts (%d usados)" % usados.size())
