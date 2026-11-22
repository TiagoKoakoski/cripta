## Gera um andar no estilo The Binding of Isaac: salas num grid, ligadas por portas.
## Lógica pura (sem nós), determinística pela semente.
class_name GeradorAndar
extends RefCounted

const INICIO := 0
const COMBATE := 1
const TESOURO := 2
const FONTE := 3
const CHEFE := 4

const DIRECOES: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const LIMITE := 4  # o grid vai de -4 a 4 em cada eixo


static func vizinhos(salas: Dictionary, p: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d: Vector2i in DIRECOES:
		if salas.has(p + d):
			out.append(p + d)
	return out


## Retorna {"salas": {Vector2i: tipo}, "inicio": Vector2i, "chefe": Vector2i}.
static func gerar(semente: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	while true:
		var a := _tentar(rng)
		if not a.is_empty():
			return a
	return {}


static func _tentar(rng: RandomNumberGenerator) -> Dictionary:
	var alvo := rng.randi_range(9, 12)
	var salas := {Vector2i.ZERO: COMBATE}
	var ordem: Array[Vector2i] = [Vector2i.ZERO]
	var tentativas := 0
	while salas.size() < alvo and tentativas < 400:
		tentativas += 1
		var base: Vector2i = ordem[rng.randi_range(0, ordem.size() - 1)]
		var nova: Vector2i = base + DIRECOES[rng.randi_range(0, 3)]
		if salas.has(nova) or absi(nova.x) > LIMITE or absi(nova.y) > LIMITE:
			continue
		if vizinhos(salas, nova).size() > 1:  # mantém corredores e becos, sem blocos 2x2
			continue
		salas[nova] = COMBATE
		ordem.append(nova)
	if salas.size() < alvo:
		return {}
	var becos: Array[Vector2i] = []
	for p: Vector2i in ordem:
		if p != Vector2i.ZERO and vizinhos(salas, p).size() == 1:
			becos.append(p)
	if becos.size() < 4:
		return {}
	var dist := _distancias(salas, Vector2i.ZERO)
	var chefe: Vector2i = becos[0]
	for b: Vector2i in becos:
		if dist[b] > dist[chefe]:
			chefe = b
	# o chefe precisa ser o mais distante de todo o andar, não só dos becos
	for p: Vector2i in salas:
		if dist[p] > dist[chefe]:
			return {}
	becos.erase(chefe)
	var i_tesouro := rng.randi_range(0, becos.size() - 1)
	var tesouro: Vector2i = becos[i_tesouro]
	becos.remove_at(i_tesouro)
	var i_tesouro2 := rng.randi_range(0, becos.size() - 1)
	var tesouro2: Vector2i = becos[i_tesouro2]
	becos.remove_at(i_tesouro2)
	var fonte: Vector2i = becos[rng.randi_range(0, becos.size() - 1)]
	salas[Vector2i.ZERO] = INICIO
	salas[chefe] = CHEFE
	salas[tesouro] = TESOURO
	salas[tesouro2] = TESOURO
	salas[fonte] = FONTE
	return {"salas": salas, "inicio": Vector2i.ZERO, "chefe": chefe}


static func _distancias(salas: Dictionary, de: Vector2i) -> Dictionary:
	var dist := {de: 0}
	var fila: Array[Vector2i] = [de]
	while not fila.is_empty():
		var p: Vector2i = fila.pop_front()
		for v: Vector2i in vizinhos(salas, p):
			if not dist.has(v):
				dist[v] = dist[p] + 1
				fila.append(v)
	return dist
