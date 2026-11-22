## Um andar da cripta: mapa do GeradorAndar, troca de sala pelas portas, HUD e minimapa.
class_name Andar
extends Node2D

signal vitoria
signal derrota
signal sala_mudou(posicao: Vector2i)

var partida: Partida
var mapa: Dictionary
var posicao := Vector2i.ZERO
var sala: Sala
var hud: Hud
var visitadas := {}
var _cfg := {}   # Vector2i -> dicionário de configuração da sala (fixo para o andar)


func iniciar(p: Partida, semente: int) -> void:
	partida = p
	mapa = GeradorAndar.gerar(semente)
	var rng := RandomNumberGenerator.new()
	rng.seed = semente * 31 + 7
	var dist := GeradorAndar._distancias(mapa["salas"], mapa["inicio"])
	for pos: Vector2i in mapa["salas"]:
		var tipo: int = mapa["salas"][pos]
		var portas := {}
		for v: Vector2i in GeradorAndar.vizinhos(mapa["salas"], pos):
			portas[v - pos] = mapa["salas"][v]
		var cfg := {"tipo": tipo, "portas": portas, "layout": rng.randi_range(0, 3), "semente": rng.randi(),
			"inimigos": _sortear_inimigos(rng, dist[pos]) if tipo == GeradorAndar.COMBATE else []}
		if tipo == GeradorAndar.TESOURO:
			cfg["item"] = partida.sortear_item()
		_cfg[pos] = cfg
	hud = Hud.new(partida, self)
	add_child(hud)
	entrar(mapa["inicio"], Vector2i.ZERO)


func _sortear_inimigos(rng: RandomNumberGenerator, dist: int) -> Array:
	var n := clampi(1 + dist, 2, 4)
	var tipos := ["morcego", "slime"] if dist <= 1 else ["morcego", "slime", "esqueleto"]
	var out := []
	for i in n:
		out.append(tipos[rng.randi_range(0, tipos.size() - 1)])
	return out


## Entra na sala `pos` pela porta do lado `entrada` (ZERO = centro, no início).
func entrar(pos: Vector2i, entrada: Vector2i) -> void:
	if sala:
		sala.queue_free()
	posicao = pos
	visitadas[pos] = true
	var cfg: Dictionary = _cfg[pos].duplicate()
	cfg["limpa"] = partida.salas_limpas.has(pos) or cfg["tipo"] == GeradorAndar.INICIO
	cfg["entrada"] = entrada
	sala = Sala.new()
	sala.configurar(cfg, partida)
	sala.saiu.connect(func(d: Vector2i) -> void: _mudar.call_deferred(pos + d, -d))
	sala.limpa.connect(func() -> void: partida.limpar_sala(pos))
	sala.item_pego.connect(func(_i: String) -> void: partida.limpar_sala(pos))
	sala.jogador_morreu.connect(func() -> void: derrota.emit())
	sala.chefe_morto.connect(func() -> void:
		partida.limpar_sala(pos)
		vitoria.emit())
	add_child(sala)
	sala_mudou.emit(pos)


func _mudar(pos: Vector2i, entrada: Vector2i) -> void:
	if mapa["salas"].has(pos):
		entrar(pos, entrada)


## salas que aparecem no minimapa: visitadas e vizinhas delas
func salas_conhecidas() -> Array[Vector2i]:
	var out := {}
	for p: Vector2i in visitadas:
		out[p] = true
		for v: Vector2i in GeradorAndar.vizinhos(mapa["salas"], p):
			out[v] = true
	var lista: Array[Vector2i] = []
	lista.assign(out.keys())
	return lista
