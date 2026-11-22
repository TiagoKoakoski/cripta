# godot --headless --path . --script res://tests/teste_andar.gd
extends SceneTree

var passou := 0
var falhou := 0


func _initialize() -> void:
	for t: String in ["teste_quantidade", "teste_salas_por_andar", "teste_geracao_rapida", "teste_andar_conexo", "teste_especiais", "teste_determinismo",
			"teste_vizinhos_simetricos", "teste_variedade"]:
		if call(t) != true:
			falhou += 1
			push_error("FALHOU %s: não terminou" % t)
	print("Resultado: %d ok, %d falhas" % [passou, falhou])
	quit(1 if falhou > 0 else 0)


func checa(cond: bool, rotulo: String) -> void:
	if cond:
		passou += 1
	else:
		falhou += 1
		push_error("FALHOU " + rotulo)


func distancias(andar: Dictionary) -> Dictionary:
	var salas: Dictionary = andar["salas"]
	var dist := {andar["inicio"]: 0}
	var fila: Array[Vector2i] = [andar["inicio"]]
	while not fila.is_empty():
		var p: Vector2i = fila.pop_front()
		for v: Vector2i in GeradorAndar.vizinhos(salas, p):
			if not dist.has(v):
				dist[v] = dist[p] + 1
				fila.append(v)
	return dist


func teste_quantidade() -> bool:
	for s in 200:
		var n: int = GeradorAndar.gerar(s)["salas"].size()
		if n < 10 or n > 12:
			checa(false, "semente %d gerou %d salas" % [s, n])
			return true
	checa(true, "10 a 12 salas")
	return true


func teste_andar_conexo() -> bool:
	for s in 500:
		var a := GeradorAndar.gerar(s)
		if distancias(a).size() != a["salas"].size():
			checa(false, "semente %d desconexa" % s)
			return true
	checa(true, "todas as salas alcançáveis (500 sementes)")
	return true


func teste_especiais() -> bool:
	for s in 300:
		var a := GeradorAndar.gerar(s)
		var salas: Dictionary = a["salas"]
		var conta := {}
		for p: Vector2i in salas:
			conta[salas[p]] = conta.get(salas[p], 0) + 1
		var ok: bool = conta.get(GeradorAndar.INICIO, 0) == 1 and conta.get(GeradorAndar.CHEFE, 0) == 1 \
			and conta.get(GeradorAndar.TESOURO, 0) == 2 and conta.get(GeradorAndar.FONTE, 0) == 1 \
			and conta.get(GeradorAndar.SUBCHEFE, 0) == 1
		var dist := distancias(a)
		var max_d := 0
		for p: Vector2i in dist:
			max_d = maxi(max_d, dist[p])
		ok = ok and salas[a["chefe"]] == GeradorAndar.CHEFE and dist[a["chefe"]] == max_d
		for p: Vector2i in salas:
			if salas[p] in [GeradorAndar.CHEFE, GeradorAndar.TESOURO, GeradorAndar.FONTE, GeradorAndar.SUBCHEFE]:
				ok = ok and GeradorAndar.vizinhos(salas, p).size() == 1
			if salas[p] == GeradorAndar.SUBCHEFE:
				ok = ok and dist[p] >= 2
		if not ok:
			checa(false, "semente %d: especiais errados %s" % [s, conta])
			return true
	checa(true, "1 início, 2 tesouros, 1 fonte, 1 subchefe (dist 2+), 1 chefe (o mais distante), especiais em becos")
	return true


func teste_determinismo() -> bool:
	checa(GeradorAndar.gerar(42) == GeradorAndar.gerar(42), "mesma semente, mesmo andar")
	return true


func teste_vizinhos_simetricos() -> bool:
	var salas: Dictionary = GeradorAndar.gerar(7)["salas"]
	var ok := true
	for p: Vector2i in salas:
		for v: Vector2i in GeradorAndar.vizinhos(salas, p):
			ok = ok and p in GeradorAndar.vizinhos(salas, v)
	checa(ok, "vizinhança simétrica")
	return true


func teste_variedade() -> bool:
	var formas := {}
	for s in 50:
		formas[str(GeradorAndar.gerar(s)["salas"].keys())] = true
	checa(formas.size() >= 40, "andares variados (%d formas em 50)" % formas.size())
	return true


func teste_salas_por_andar() -> bool:
	for n in [1, 2, 3]:
		var faixa: Vector2i = Andares.info(n)["salas"]
		for s in 200:
			var q: int = GeradorAndar.gerar(s, n)["salas"].size()
			if q < faixa.x or q > faixa.y:
				checa(false, "andar %d semente %d: %d salas fora de %s" % [n, s, q, faixa])
				return true
	checa(Andares.info(1)["salas"] == Vector2i(10, 12) and Andares.info(2)["salas"] == Vector2i(13, 15)
		and Andares.info(3)["salas"] == Vector2i(16, 19), "faixas da tabela: 10-12, 13-15, 16-19")
	checa(true, "salas na faixa de cada andar")
	return true


func teste_geracao_rapida() -> bool:
	var t0 := Time.get_ticks_msec()
	for n in [1, 2, 3]:
		for s in 170:
			GeradorAndar.gerar(s, n)
	var ms := Time.get_ticks_msec() - t0
	checa(ms < 5000, "510 andares gerados em menos de 5 s (%d ms)" % ms)
	return true
