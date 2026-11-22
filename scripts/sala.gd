## Uma sala da cripta: chão, paredes, pilares do layout, portas (trancadas até limpar),
## jogador e inimigos. Configurada por um dicionário vindo do andar.
class_name Sala
extends Node2D

signal limpa
signal saiu(direcao: Vector2i)
signal item_pego(item: String)
signal jogador_morreu
signal chefe_morto

const T := 16
const COLS := 20
const LINS := 11
const ICONE := {GeradorAndar.COMBATE: "icone_combate", GeradorAndar.TESOURO: "icone_tesouro",
	GeradorAndar.FONTE: "icone_fonte", GeradorAndar.CHEFE: "icone_chefe", GeradorAndar.INICIO: ""}
## pilares por layout (tiles); nunca na linha 5 nem nas colunas 9-10 (corredores das portas)
const LAYOUTS := [
	[Vector2i(4, 3), Vector2i(15, 3), Vector2i(4, 7), Vector2i(15, 7)],
	[Vector2i(6, 2), Vector2i(7, 2), Vector2i(12, 2), Vector2i(13, 2), Vector2i(6, 8), Vector2i(7, 8),
		Vector2i(12, 8), Vector2i(13, 8)],
	[Vector2i(3, 2), Vector2i(3, 3), Vector2i(16, 2), Vector2i(16, 3), Vector2i(3, 7), Vector2i(3, 8),
		Vector2i(16, 7), Vector2i(16, 8)],
	[Vector2i(7, 3), Vector2i(8, 3), Vector2i(11, 3), Vector2i(12, 3), Vector2i(7, 7), Vector2i(8, 7),
		Vector2i(11, 7), Vector2i(12, 7)],
]
const CANDIDATOS: Array[Vector2] = [Vector2(48, 40), Vector2(272, 40), Vector2(48, 136), Vector2(272, 136),
	Vector2(160, 40), Vector2(160, 136), Vector2(88, 88), Vector2(232, 88)]

var partida: Partida
var jogador: Jogador
var tipo := GeradorAndar.COMBATE
var _trancada := false
var _portas := {}      # Vector2i -> {"grade": StaticBody2D, "sprite": Sprite2D}
var _objeto: Node2D
var _item := ""
var _fonte_usada := false
var _rng := RandomNumberGenerator.new()
var _inimigos: Array = []  # registrados na criação (podem entrar na árvore um quadro depois)


static func centro_porta(d: Vector2i) -> Vector2:
	match d:
		Vector2i.UP: return Vector2(160, 8)
		Vector2i.DOWN: return Vector2(160, 168)
		Vector2i.LEFT: return Vector2(8, 88)
	return Vector2(312, 88)


## onde o jogador aparece ao entrar pela porta do lado `entrada`
static func ponto_de_entrada(entrada: Vector2i) -> Vector2:
	match entrada:
		Vector2i.UP: return Vector2(160, 34)
		Vector2i.DOWN: return Vector2(160, 142)
		Vector2i.LEFT: return Vector2(34, 88)
		Vector2i.RIGHT: return Vector2(286, 88)
	return Vector2(160, 88)


static func posicoes_inimigos(layout: int, entrada: Vector2i) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for p: Vector2 in CANDIDATOS:
		var tile := Vector2i(int(p.x) / T, int(p.y) / T)
		if tile in LAYOUTS[layout]:
			continue
		if entrada != Vector2i.ZERO and p.distance_to(ponto_de_entrada(entrada)) < 80.0:
			continue
		out.append(p)
	return out


## cfg: tipo, portas {Vector2i: tipo vizinho}, layout, inimigos [{tipo,pos} | "tipo"], limpa, entrada,
## item (tesouro), semente
func configurar(cfg: Dictionary, p: Partida) -> void:
	partida = p
	tipo = cfg.get("tipo", GeradorAndar.COMBATE)
	_rng.seed = cfg.get("semente", 1)
	var layout: int = cfg.get("layout", 0) if tipo == GeradorAndar.COMBATE else -1
	var entrada: Vector2i = cfg.get("entrada", Vector2i.ZERO)
	_montar_chao_e_paredes(cfg.get("portas", {}), layout)
	jogador = Jogador.criar(partida, self, ponto_de_entrada(entrada))
	jogador.morreu.connect(func() -> void: jogador_morreu.emit())
	add_child(jogador)
	var limpa_antes: bool = cfg.get("limpa", false)
	if tipo == GeradorAndar.TESOURO and not limpa_antes:
		_item = cfg.get("item", "espada")
		_criar_objeto("pedestal", "item_" + _item)
	elif tipo == GeradorAndar.FONTE:
		_fonte_usada = limpa_antes
		_criar_objeto("fonte", "")
	elif tipo == GeradorAndar.CHEFE and not limpa_antes:
		_criar_inimigo("rei", Vector2(160, 60))
	if not limpa_antes and tipo == GeradorAndar.COMBATE:
		var livres := posicoes_inimigos(maxi(layout, 0), entrada)
		var i := 0
		for e: Variant in cfg.get("inimigos", []):
			if e is Dictionary:
				_criar_inimigo(e["tipo"], e["pos"])
			else:
				_criar_inimigo(e, livres[i % livres.size()])
			i += 1
	_trancada = vivos() > 0
	_atualizar_portas()


func vivos() -> int:
	var n := 0
	for e: Variant in _inimigos:
		if is_instance_valid(e) and (e as Inimigo).vivo():
			n += 1
	return n


func aberta() -> bool:
	return not _trancada


func tiros_do_jogador() -> Array:
	return get_children().filter(func(c: Node) -> bool: return c is Tiro and (c as Tiro).do_jogador)


func inimigo_mais_perto() -> Inimigo:
	var melhor: Inimigo = null
	for v: Variant in _inimigos:
		if is_instance_valid(v) and (v as Inimigo).vivo():
			var e := v as Inimigo
			if melhor == null or jogador.position.distance_to(e.position) < jogador.position.distance_to(melhor.position):
				melhor = e
	return melhor


func _criar_inimigo(t: String, pos: Vector2) -> void:
	var e := Inimigo.criar(t, pos, jogador, self, _rng.randi())
	e.morreu.connect(_inimigo_morreu)
	_inimigos.append(e)
	# durante a física (morte por tiro) não dá pra adicionar corpos na hora
	if is_inside_tree() and Engine.is_in_physics_frame():
		add_child.call_deferred(e)
	else:
		add_child(e)


func _inimigo_morreu(e: Inimigo, t: String, pos: Vector2) -> void:
	_inimigos.erase(e)
	if t == "slime":
		for d: Vector2 in [Vector2(-8, 0), Vector2(8, 0)]:
			_criar_inimigo("slime_pequeno", pos + d)
	if t == "rei":
		chefe_morto.emit()
	_verificar_limpa.call_deferred()


func _verificar_limpa() -> void:
	if _trancada and vivos() == 0:
		_trancada = false
		_atualizar_portas()
		Sons.tocar("porta")
		limpa.emit()


func _criar_objeto(sprite: String, sobre: String) -> void:
	_objeto = Node2D.new()
	_objeto.position = Vector2(160, 88)
	var s := Sprite2D.new()
	s.texture = load("res://arte/%s.png" % sprite)
	_objeto.add_child(s)
	if sobre != "":
		var s2 := Sprite2D.new()
		s2.texture = load("res://arte/%s.png" % sobre)
		s2.position = Vector2(0, -6)
		s2.name = "Item"
		_objeto.add_child(s2)
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = Camadas.JOGADOR
	var c := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(20, 20)
	c.shape = r
	area.add_child(c)
	area.body_entered.connect(_tocou_objeto)
	_objeto.add_child(area)
	add_child(_objeto)


func _tocou_objeto(corpo: Node) -> void:
	if not corpo is Jogador:
		return
	if tipo == GeradorAndar.TESOURO and _item != "":
		partida.pegar_item(_item)
		Sons.tocar("item")
		item_pego.emit(_item)
		_item = ""
		var s := _objeto.get_node_or_null("Item")
		if s:
			s.queue_free()
	elif tipo == GeradorAndar.FONTE and not _fonte_usada:
		_fonte_usada = true
		partida.curar(2)
		Sons.tocar("fonte")
		(_objeto.get_child(0) as Sprite2D).modulate = Color(0.5, 0.5, 0.6)
		item_pego.emit("fonte")


func objeto_usado() -> bool:
	return (tipo == GeradorAndar.TESOURO and _item == "") or (tipo == GeradorAndar.FONTE and _fonte_usada)


# ------------------------------------------------------------------ montagem

func _montar_chao_e_paredes(portas: Dictionary, layout: int) -> void:
	var chao := [load("res://arte/chao.png"), load("res://arte/chao2.png")]
	var parede: Texture2D = load("res://arte/parede.png")
	var pilar: Texture2D = load("res://arte/pilar.png")
	var vaos := {}
	for d: Vector2i in portas:
		for t: Vector2i in _tiles_porta(d):
			vaos[t] = true
	var pilares: Array = LAYOUTS[layout] if layout >= 0 else []
	for y in LINS:
		for x in COLS:
			var t := Vector2i(x, y)
			var borda := x == 0 or y == 0 or x == COLS - 1 or y == LINS - 1
			var tex: Texture2D = chao[1 if (x * 7 + y * 3) % 5 == 0 else 0]
			if borda and not vaos.has(t):
				tex = parede
				_solido(t, Camadas.PAREDE)
			elif t in pilares:
				tex = pilar
				_solido(t, Camadas.PILAR)
			elif borda:
				continue  # vão da porta: desenhado pela porta
			var s := Sprite2D.new()
			s.texture = tex
			s.centered = false
			s.position = Vector2(t * T)
			s.z_index = -10
			add_child(s)
	for d: Vector2i in portas:
		_criar_porta(d, portas[d])


func _tiles_porta(d: Vector2i) -> Array[Vector2i]:
	match d:
		Vector2i.UP: return [Vector2i(9, 0), Vector2i(10, 0)]
		Vector2i.DOWN: return [Vector2i(9, LINS - 1), Vector2i(10, LINS - 1)]
		Vector2i.LEFT: return [Vector2i(0, 5)]
	return [Vector2i(COLS - 1, 5)]


func _solido(t: Vector2i, camada: int, pai: Node = null) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.collision_layer = camada
	b.collision_mask = 0
	b.position = Vector2(t * T) + Vector2(T, T) / 2.0
	var c := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(T, T)
	c.shape = r
	b.add_child(c)
	(pai if pai else self).add_child(b)
	return b


func _criar_porta(d: Vector2i, tipo_vizinho: int) -> void:
	var no := Node2D.new()
	add_child(no)
	var sprites: Array[Sprite2D] = []
	for t: Vector2i in _tiles_porta(d):
		var s := Sprite2D.new()
		s.centered = false
		s.position = Vector2(t * T)
		s.z_index = -9
		no.add_child(s)
		sprites.append(s)
	var grade := Node2D.new()
	no.add_child(grade)
	for t: Vector2i in _tiles_porta(d):
		_solido(t, Camadas.PAREDE, grade)
	if ICONE.get(tipo_vizinho, "") != "":
		var ic := Sprite2D.new()
		ic.texture = load("res://arte/%s.png" % ICONE[tipo_vizinho])
		ic.position = centro_porta(d) + Vector2(d) * -14.0
		ic.z_index = -8
		ic.modulate = Color(1, 1, 1, 0.85)
		no.add_child(ic)
	var gatilho := Area2D.new()
	gatilho.collision_layer = 0
	gatilho.collision_mask = Camadas.JOGADOR
	gatilho.position = centro_porta(d) + Vector2(d) * 4.0
	var c := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(32, 10) if d.y != 0 else Vector2(10, 16)
	c.shape = r
	gatilho.add_child(c)
	gatilho.body_entered.connect(func(corpo: Node) -> void:
		if corpo is Jogador and not _trancada and not partida.morto():
			saiu.emit(d))
	no.add_child(gatilho)
	_portas[d] = {"grade": grade, "sprites": sprites}


func _atualizar_portas() -> void:
	var fechada: Texture2D = load("res://arte/porta_fechada.png")
	var aberta_: Texture2D = load("res://arte/porta_aberta.png")
	for d: Vector2i in _portas:
		for s: Sprite2D in _portas[d]["sprites"]:
			s.texture = fechada if _trancada else aberta_
		for b: Node in (_portas[d]["grade"] as Node2D).get_children():
			(b as StaticBody2D).collision_layer = Camadas.PAREDE if _trancada else 0
