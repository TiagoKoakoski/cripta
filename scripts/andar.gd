## Um andar da cripta: mapa do GeradorAndar, troca de sala pelas portas, HUD e minimapa.
class_name Andar
extends Node2D

signal vitoria
signal derrota
signal sala_mudou(posicao: Vector2i)
signal chefe_vencido
signal subiu
signal pediu_subida   # com subida_externa, quem decide quando subir é o main (transição)

var partida: Partida
var mapa: Dictionary
var posicao := Vector2i.ZERO
var sala: Sala
var hud: Hud
var visitadas := {}
var _cfg := {}   # Vector2i -> dicionário de configuração da sala (fixo para o andar)
var chefe_forcado := ""      # --chefe=<nome> e testes; vazio = sorteado da tabela do andar
var subchefe_forcado := ""
var subida_externa := false  # o main faz a transição antes de subir
var _semente := 0


func iniciar(p: Partida, semente: int) -> void:
	partida = p
	_semente = semente
	_montar_andar()
	if hud == null:
		hud = Hud.new(partida, self)
		add_child(hud)
	entrar(mapa["inicio"], Vector2i.ZERO)


func _montar_andar() -> void:
	var n := partida.andar_atual
	var info := Andares.info(n)
	var semente := _semente * 7 + n * 1013
	mapa = GeradorAndar.gerar(semente, n)
	visitadas.clear()
	_cfg.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = semente * 31 + 7
	var chefes: Array = info["chefes"]
	var chefe: String = chefe_forcado if chefe_forcado != "" else chefes[rng.randi_range(0, chefes.size() - 1)]
	var subs: Array = info["subchefes"]
	var subchefe: String = subchefe_forcado if subchefe_forcado != "" else subs[rng.randi_range(0, subs.size() - 1)]
	var dist := GeradorAndar._distancias(mapa["salas"], mapa["inicio"])
	var sorteados := []
	for pos: Vector2i in mapa["salas"]:
		var tipo: int = mapa["salas"][pos]
		var portas := {}
		for v: Vector2i in GeradorAndar.vizinhos(mapa["salas"], pos):
			portas[v - pos] = mapa["salas"][v]
		var cfg := {"tipo": tipo, "portas": portas, "layout": rng.randi_range(0, 3), "semente": rng.randi(),
			"inimigos": Andar.sortear_inimigos(rng, dist[pos], n) if tipo == GeradorAndar.COMBATE else [],
			"tema": info["tema"], "mult_vida": info["mult_vida"], "chefe": chefe, "subchefe": subchefe,
			"coracao": tipo == GeradorAndar.COMBATE and rng.randf() < 0.3}
		if tipo == GeradorAndar.TESOURO:
			cfg["item"] = partida.sortear_item(sorteados)
			sorteados.append(cfg["item"])
		_cfg[pos] = cfg


## perto do início: os inimigos "perto" do andar; a partir de DIST_LONGE entram também os "longe".
## Quantidade clamp(1+dist, 2, 5) + (andar-1), máx. 6. Atiradores (olho, mago) no máximo 1 de cada.
static func sortear_inimigos(rng: RandomNumberGenerator, dist: int, andar := 1) -> Array:
	var info := Andares.info(andar)
	var n := mini(6, clampi(1 + dist, 2, 5) + andar - 1)
	var tipos: Array = info["perto"].duplicate()
	if dist >= Andares.DIST_LONGE:
		tipos += info["longe"]
	var out := []
	for i in n:
		var t: String = tipos[rng.randi_range(0, tipos.size() - 1)]
		if t in ["olho", "mago"] and t in out:
			t = "aranha"
		out.append(t)
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
	cfg["chefe_trancado"] = not partida.tem_chave
	cfg["escada"] = cfg["limpa"] and cfg["tipo"] == GeradorAndar.CHEFE and partida.andar_atual < Andares.TOTAL
	sala = Sala.new()
	sala.configurar(cfg, partida)
	sala.saiu.connect(func(d: Vector2i) -> void: _mudar.call_deferred(pos + d, -d))
	sala.limpa.connect(func() -> void: partida.limpar_sala(pos))
	sala.item_pego.connect(func(i: String) -> void:
		partida.limpar_sala(pos)
		hud.anunciar(i))
	sala.chave_caiu.connect(func() -> void: _cfg[pos]["chave"] = true)
	sala.chave_pega.connect(func() -> void:
		_cfg[pos]["chave"] = false
		partida.tem_chave = true
		sala.destrancar_chefe()
		Sons.tocar("item")
		hud.anunciar_texto("CHAVE DA TORRE", "a porta do chefe se abre"))
	sala.coracao_pego.connect(func() -> void: _cfg[pos]["coracao"] = false)
	sala.jogador_morreu.connect(func() -> void: derrota.emit())
	sala.chefe_morto.connect(func() -> void:
		partida.limpar_sala(pos)
		if partida.andar_atual >= Andares.TOTAL:
			vitoria.emit()
		else:
			sala.mostrar_escada()
			chefe_vencido.emit())
	sala.escada_pisada.connect(_escada_pisada, CONNECT_DEFERRED)
	add_child(sala)
	sala_mudou.emit(pos)


func _escada_pisada() -> void:
	if subida_externa:
		pediu_subida.emit()
	else:
		_subir()


func subir() -> void:
	_subir()


func _subir() -> void:
	if partida.morto():
		return
	partida.subir()
	_montar_andar()
	entrar(mapa["inicio"], Vector2i.ZERO)
	Sons.tocar("porta")
	subiu.emit()


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
