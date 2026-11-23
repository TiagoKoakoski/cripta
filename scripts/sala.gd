## Uma sala da cripta: chão, paredes, pilares do layout, portas (trancadas até limpar),
## jogador e inimigos. Configurada por um dicionário vindo do andar.
class_name Sala
extends Node2D

signal limpa
signal saiu(direcao: Vector2i)
signal item_pego(item: String)
signal jogador_morreu
signal chefe_morto
signal coracao_pego
signal escada_pisada
signal chave_caiu
signal chave_pega

const T := 16
const COLS := 20
const LINS := 11
## estilo da porta pelo tipo da sala do outro lado (sem ícone: a moldura dá a pista, como no Isaac)
const PORTA := {GeradorAndar.COMBATE: "porta_combate", GeradorAndar.TESOURO: "porta_tesouro",
	GeradorAndar.FONTE: "porta_fonte", GeradorAndar.CHEFE: "porta_chefe", GeradorAndar.INICIO: "porta_inicio",
	GeradorAndar.SUBCHEFE: "porta_subchefe"}
## layouts do interior (18x9; x 0-17 = tiles 1-18, y 0-8 = tiles 1-9). Letras: . chão, P pilar,
## R pedra, C caixa (quebra), B buraco (só quem anda é bloqueado), E espinhos (ferem). Linha 4 e
## colunas 8-9 ficam livres (corredores das portas). Todo chão é alcançável a partir das portas.
static var LAYOUTS := [
	["..................", "..................", "...P..........P...", "..................", "..................",
		"..................", "...P..........P...", "..................", ".................."],
	["..................", ".....PP....PP.....", "..................", "..................", "..................",
		"..................", "..................", ".....PP....PP.....", ".................."],
	["..................", "..P............P..", "..P............P..", "..................", "..................",
		"..................", "..P............P..", "..P............P..", ".................."],
	["..................", "..................", "......PP..PP......", "..................", "..................",
		"..................", "......PP..PP......", "..................", ".................."],
	["..................", ".BB............BB.", ".B..............B.", "..................", "..................",
		"..................", ".B..............B.", ".BB............BB.", ".................."],
	["..................", "..................", "...BBBB....BBBB...", "...BBBB....BBBB...", "..................",
		"...BBBB....BBBB...", "...BBBB....BBBB...", "..................", ".................."],
	["..................", "..R....C..........", ".......C....R.....", ".R..........C.....", "..................",
		"....C.......R.....", "..........C....R..", ".R....C.........R.", ".................."],
	["..................", "..EEEE......EEEE..", "..................", "..................", "..................",
		"..................", "..................", "..EEEE......EEEE..", ".................."],
	["..................", "..................", ".CCC..........CCC.", "....B........B....", "..................",
		"....B........B....", ".CCC..........CCC.", "..................", ".................."],
	["..................", "..BBB........BBB..", "..BPB........BPB..", "..BBB........BBB..", "..................",
		"..BBB........BBB..", "..BPB........BPB..", "..BBB........BBB..", ".................."],
	["..................", ".RRR..........RRR.", ".R..............R.", ".R...C......C...R.", "..................",
		".R...C......C...R.", ".R..............R.", ".RRR..........RRR.", ".................."],
	["..................", "....P........P....", "...EEE......EEE...", "..................", "..................",
		"..................", "...EEE......EEE...", "....P........P....", ".................."],
	[".BBBBBB....BBBBBB.", "..................", "....R........R....", "..................", "..................",
		"..................", "....R........R....", "..................", ".BBBBBB....BBBBBB."],
	["..................", "...C.C......C.C...", "..................", "..C...C....C...C..", "..................",
		"..C...C....C...C..", "..................", "...C.C......C.C...", ".................."],
]
const CANDIDATOS: Array[Vector2] = [Vector2(48, 40), Vector2(272, 40), Vector2(48, 136), Vector2(272, 136),
	Vector2(160, 40), Vector2(160, 136), Vector2(88, 88), Vector2(232, 88), Vector2(120, 64), Vector2(200, 64),
	Vector2(120, 112), Vector2(200, 112), Vector2(104, 40), Vector2(216, 136)]

var partida: Partida
var jogador: Jogador
var tipo := GeradorAndar.COMBATE
var _trancada := false
var _portas := {}      # Vector2i -> {"grade": StaticBody2D, "sprite": Sprite2D}
var _objeto: Node2D
var _item := ""
var _fonte_usada := false
var _rng := RandomNumberGenerator.new()
var _layout := -1
var _tem_coracao := false   # esta sala solta (ou guarda) um coração quando limpa
var _coracao: Area2D
var _escada: Area2D
var _chave: Area2D
var _chefe_trancado := false
var _tipo_porta := {}   # Vector2i -> tipo da sala vizinha
var _escada_armado := false   # só sobe depois de o jogador pisar (não se ele já estava em cima)
var _mult_vida := 1.0
var _tema := "cripta"
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


## obstáculos do layout: tile absoluto (Vector2i) -> letra
static func obstaculos(layout: int) -> Dictionary:
	var out := {}
	if layout < 0 or layout >= LAYOUTS.size():
		return out
	var l: Array = LAYOUTS[layout]
	for y in l.size():
		var linha: String = l[y]
		for x in linha.length():
			if linha[x] != ".":
				out[Vector2i(x + 1, y + 1)] = linha[x]
	return out


## o corpo de um inimigo (12x10) centrado em p encostaria em algum obstáculo do layout?
static func encosta_obstaculo(p: Vector2, layout: int) -> bool:
	var corpo := Rect2(p - Vector2(6, 3), Vector2(12, 10))
	for t: Vector2i in obstaculos(layout):
		if corpo.intersects(Rect2(Vector2(t * T), Vector2(T, T))):
			return true
	return false


static func posicoes_inimigos(layout: int, entrada: Vector2i) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for p: Vector2 in CANDIDATOS:
		if encosta_obstaculo(p, layout):
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
	_layout = layout
	_mult_vida = cfg.get("mult_vida", 1.0)
	_tema = cfg.get("tema", "cripta")
	_chefe_trancado = cfg.get("chefe_trancado", false)
	_montar_chao_e_paredes(cfg.get("portas", {}), layout)
	jogador = Jogador.criar(partida, self, ponto_de_entrada(entrada))
	jogador.morreu.connect(func() -> void: jogador_morreu.emit())
	jogador.ferido.connect(tremer)
	add_child(jogador)
	var limpa_antes: bool = cfg.get("limpa", false)
	if tipo == GeradorAndar.TESOURO and not limpa_antes:
		_item = cfg.get("item", "espada")
		_criar_objeto("pedestal", "item_" + _item)
	elif tipo == GeradorAndar.FONTE:
		_fonte_usada = limpa_antes
		_criar_objeto("fonte", "")
	elif tipo == GeradorAndar.CHEFE and not limpa_antes:
		# o chefe nasce do lado oposto à porta de entrada (nunca colado no jogador)
		var lado := -entrada if entrada != Vector2i.ZERO else Vector2i.UP
		_criar_chefe(cfg.get("chefe", "rei"), ponto_de_entrada(lado))
	elif tipo == GeradorAndar.CHEFE and cfg.get("escada", false):
		mostrar_escada()
	elif tipo == GeradorAndar.SUBCHEFE and not limpa_antes:
		var lado := -entrada if entrada != Vector2i.ZERO else Vector2i.UP
		_criar_chefe(cfg.get("subchefe", "morcego_vampiro"), ponto_de_entrada(lado))
	elif tipo == GeradorAndar.SUBCHEFE and cfg.get("chave", false):
		_soltar_chave()
	if not limpa_antes and tipo == GeradorAndar.COMBATE:
		var livres := posicoes_inimigos(maxi(layout, 0), entrada)
		var i := 0
		for e: Variant in cfg.get("inimigos", []):
			if e is Dictionary:
				_criar_inimigo(e["tipo"], e["pos"])
			else:
				# mais inimigos que pontos: os repetidos nascem um pouco deslocados
				var desloc := Vector2(12, 0).rotated(i) * float(i / livres.size())
				_criar_inimigo(e, livres[i % livres.size()] + desloc)
			i += 1
	_tem_coracao = cfg.get("coracao", false)
	_trancada = vivos() > 0
	_atualizar_portas()
	if _tem_coracao and not _trancada:
		_soltar_coracao()


func _ponto_livre_perto(alvo: Vector2) -> Vector2:
	var melhor := alvo
	var d := INF
	for p: Vector2 in pontos_livres():
		if p.distance_to(alvo) < d and p.distance_to(Vector2(160, 88)) > 12.0:   # não em cima da chave
			d = p.distance_to(alvo)
			melhor = p
	return melhor


## pontos de chão sem obstáculo (o mago teletransporta para um deles)
func pontos_livres() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for p: Vector2 in CANDIDATOS:
		if _layout < 0 or not encosta_obstaculo(p, _layout):
			out.append(p)
	return out


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


func _criar_chefe(nome: String, pos: Vector2) -> void:
	_registrar(Chefe.criar_chefe(nome, pos, jogador, self, _rng.randi()))


func chefe() -> Chefe:
	for v: Variant in _inimigos:
		if is_instance_valid(v) and v is Chefe and (v as Chefe).vivo():
			return v
	return null


var _invocados: Array = []


## inimigo chamado pelo chefe: conta para trancar a sala e some quando o chefe cai
func invocar(t: String, pos: Vector2) -> void:
	var e := Inimigo.criar(t, pos.clamp(Vector2(24, 24), Vector2(296, 152)), jogador, self, _rng.randi())
	_invocados.append(e)
	_registrar(e)


func invocados_vivos(t: String) -> int:
	var n := 0
	for v: Variant in _invocados:
		if is_instance_valid(v) and (v as Inimigo).vivo() and (v as Inimigo).tipo == t:
			n += 1
	return n


func _criar_inimigo(t: String, pos: Vector2) -> void:
	var e := Inimigo.criar(t, pos, jogador, self, _rng.randi())
	if _mult_vida != 1.0:
		e.hp = ceili(e.hp * _mult_vida)
		e.hp_max = e.hp
	_registrar(e)


func _registrar(e: Inimigo) -> void:
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
			_criar_inimigo("slime_pequeno", (pos + d).clamp(Vector2(24, 24), Vector2(296, 152)))
	if e is Chefe and (e as Chefe).fases == 2:
		pass   # subchefe: a chave cai quando a sala fica limpa (o Slime Rei deixa filhos)
	elif e is Chefe:
		for c: Node in get_children():   # fogo e teia do chefe não ferem depois da vitória
			if (c is PocaFogo and not (c as PocaFogo).do_jogador) or c is PocaTeia:
				c.queue_free()
		for v: Variant in _inimigos.duplicate():
			if is_instance_valid(v) and v in _invocados:
				(v as Inimigo).sumir()
				_inimigos.erase(v)
		chefe_morto.emit()
	_verificar_limpa.call_deferred()


func _verificar_limpa() -> void:
	if _trancada and vivos() == 0:
		_trancada = false
		_atualizar_portas()
		Sons.tocar("porta")
		limpa.emit()
		if tipo == GeradorAndar.SUBCHEFE:
			_soltar_chave()
			chave_caiu.emit()
			coracao_solto(_ponto_livre_perto(Vector2(184, 88)), true)   # subchefe sempre deixa um coração de alma
		if _tem_coracao:
			_soltar_coracao.call_deferred()


func _criar_objeto(sprite: String, sobre: String) -> void:
	_objeto = Node2D.new()
	_objeto.position = Vector2(160, 88)
	var s := Sprite2D.new()
	Visual.aplicar(s, sprite)
	_objeto.add_child(s)
	if sobre != "":
		var s2 := Sprite2D.new()
		Visual.aplicar(s2, sobre)
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


var _tremor: Tween


func tremer() -> void:
	if _tremor:
		_tremor.kill()
	_tremor = create_tween()
	for i in 5:
		_tremor.tween_property(self, "position", Vector2(_rng.randf_range(-3, 3), _rng.randf_range(-3, 3)), 0.035)
	_tremor.tween_property(self, "position", Vector2.ZERO, 0.035)


func chave_no_chao() -> bool:
	return _chave != null and is_instance_valid(_chave) and not _chave.is_queued_for_deletion()


func _soltar_chave() -> void:
	if chave_no_chao():
		return
	_chave = Area2D.new()
	_chave.position = Vector2(160, 88)
	_chave.collision_layer = 0
	_chave.collision_mask = Camadas.JOGADOR
	var s := Sprite2D.new()
	Visual.aplicar(s, "chave")
	_chave.add_child(s)
	var c := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 12)
	c.shape = r
	_chave.add_child(c)
	_chave.body_entered.connect(func(corpo: Node) -> void:
		if corpo is Jogador and chave_no_chao():
			_chave.queue_free()
			Efeitos.faisca(self, _chave.position, Color(1, 0.9, 0.4))
			chave_pega.emit())
	add_child.call_deferred(_chave)
	var tw := _chave.create_tween().set_loops()
	tw.tween_property(s, "position:y", -3.0, 0.5)
	tw.tween_property(s, "position:y", 0.0, 0.5)


## porta para `d` está fechada? (inimigos vivos, ou é a porta do chefe sem a chave)
func porta_trancada(d: Vector2i) -> bool:
	return _trancada or (_tipo_porta.get(d, -1) == GeradorAndar.CHEFE and _chefe_trancado and not partida.tem_chave)


func destrancar_chefe() -> void:
	_chefe_trancado = false
	_atualizar_portas()


func tem_escada() -> bool:
	return _escada != null and is_instance_valid(_escada)


func mostrar_escada() -> void:
	if tem_escada():
		return
	_escada = Area2D.new()
	_escada.position = Vector2(160, 88)
	_escada.collision_layer = 0
	_escada.collision_mask = Camadas.JOGADOR
	var s := Sprite2D.new()
	Visual.aplicar(s, "escada")
	s.z_index = -5
	_escada.add_child(s)
	var c := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 12)
	c.shape = r
	_escada.add_child(c)
	_escada_armado = jogador == null or jogador.position.distance_to(_escada.position) > 16.0
	_escada.body_exited.connect(func(corpo: Node) -> void:
		if corpo is Jogador:
			_escada_armado = true)
	_escada.body_entered.connect(func(corpo: Node) -> void:
		if corpo is Jogador and not partida.morto() and _escada_armado:
			escada_pisada.emit())
	add_child.call_deferred(_escada)


func coracao_no_chao() -> bool:
	return _coracao != null and is_instance_valid(_coracao) and not _coracao.is_queued_for_deletion()


func _soltar_coracao() -> void:
	if coracao_no_chao():
		return
	_coracao = Area2D.new()
	_coracao.position = Vector2(160, 88)
	_coracao.collision_layer = 0
	_coracao.collision_mask = Camadas.JOGADOR
	var s := Sprite2D.new()
	Visual.aplicar(s, "coracao_chao")
	_coracao.add_child(s)
	var c := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 12)
	c.shape = r
	_coracao.add_child(c)
	add_child(_coracao)
	var tw := _coracao.create_tween().set_loops()
	tw.tween_property(s, "position:y", -2.0, 0.4)
	tw.tween_property(s, "position:y", 0.0, 0.4)


func _physics_process(_delta: float) -> void:
	for e: Area2D in _espinhos:
		for corpo: Node in e.get_overlapping_bodies():
			if corpo is Jogador:
				(corpo as Jogador).ferir()
	for n: Node in get_tree().get_nodes_in_group("coracao_solto"):
		var a := n as Area2D
		var alma: bool = a.get_meta("alma", false)
		if a.get_parent() == self and (partida.cabe_alma() if alma else partida.vida < partida.vida_max):
			for corpo: Node in a.get_overlapping_bodies():
				if corpo is Jogador:
					if alma:
						partida.ganhar_alma(1)
						Efeitos.faisca(self, a.position, Color(0.5, 0.7, 1.0))
					else:
						partida.curar(1)
					Sons.tocar("fonte")
					a.queue_free()
					a.remove_from_group("coracao_solto")
					break
	# o coração fica no chão enquanto a vida estiver cheia; pega quando houver espaço
	if coracao_no_chao() and partida.vida < partida.vida_max:
		for corpo: Node in _coracao.get_overlapping_bodies():
			if corpo is Jogador:
				partida.curar(1)
				Sons.tocar("fonte")
				Efeitos.faisca(self, _coracao.position, Color(1, 0.5, 0.6))
				_coracao.queue_free()
				_tem_coracao = false
				coracao_pego.emit()
				break


func objeto_usado() -> bool:
	return (tipo == GeradorAndar.TESOURO and _item == "") or (tipo == GeradorAndar.FONTE and _fonte_usada)


# ------------------------------------------------------------------ montagem

func _montar_chao_e_paredes(portas: Dictionary, layout: int) -> void:
	var tm := _tema
	var chao := ["chao_%s" % tm, "chao2_%s" % tm, "chao3_%s" % tm]
	var parede := "parede_%s" % tm
	var pilar := "pilar_%s" % tm
	var vaos := {}
	for d: Vector2i in portas:
		for t: Vector2i in _tiles_porta(d):
			vaos[t] = true
	var obst := obstaculos(layout)
	for y in LINS:
		for x in COLS:
			var t := Vector2i(x, y)
			var borda := x == 0 or y == 0 or x == COLS - 1 or y == LINS - 1
			var v := (x * 7 + y * 13 + x * y) % 9
			var tex: String = chao[2 if v == 0 else (1 if v < 3 else 0)]
			if borda and not vaos.has(t):
				tex = parede
				_solido(t, Camadas.PAREDE)
			elif borda:
				continue  # vão da porta: desenhado pela porta
			var s := Sprite2D.new()
			s.centered = false
			Visual.aplicar(s, tex)
			s.position = Vector2(t * T)
			s.z_index = -10
			add_child(s)
	for t: Vector2i in obst:
		_criar_obstaculo(t, obst[t], pilar)
	for d: Vector2i in portas:
		_criar_porta(d, portas[d])
	_decorar()


var _espinhos: Array[Area2D] = []


func _criar_obstaculo(t: Vector2i, letra: String, pilar: String) -> void:
	var centro := Vector2(t * T) + Vector2(T, T) / 2.0
	if letra == "C":
		add_child(Caixa.criar(self, centro))
		return
	var s := Sprite2D.new()
	s.position = centro
	s.z_index = -9 if letra in ["B", "E"] else -8
	add_child(s)
	match letra:
		"P":
			Visual.aplicar(s, pilar)
			_solido(t, Camadas.PILAR)
		"R":
			Visual.aplicar(s, "pedra")
			_solido(t, Camadas.PILAR)
		"B":
			Visual.aplicar(s, "buraco")
			_solido(t, Camadas.BURACO)
		"E":
			Visual.aplicar(s, "espinhos")
			var a := Area2D.new()
			a.position = centro
			a.collision_layer = 0
			a.collision_mask = Camadas.JOGADOR
			var c := CollisionShape2D.new()
			var r := RectangleShape2D.new()
			r.size = Vector2(12, 12)
			c.shape = r
			a.add_child(c)
			add_child(a)
			_espinhos.append(a)


func caixas() -> int:
	return get_children().filter(func(n: Node) -> bool: return n is Caixa and n.is_in_group("caixa")).size()


## coração que cai (caixa, subchefe): vermelho cura 1 se faltar vida; de alma (azul) dá +1 alma se couber
func coracao_solto(pos: Vector2, alma := false) -> void:
	var a := Area2D.new()
	a.position = pos
	a.collision_layer = 0
	a.collision_mask = Camadas.JOGADOR
	var s := Sprite2D.new()
	Visual.aplicar(s, "coracao_alma_chao" if alma else "coracao_chao")
	a.add_child(s)
	a.set_meta("alma", alma)
	var c := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 12)
	c.shape = r
	a.add_child(c)
	a.add_to_group("coracao_solto")
	var tw := s.create_tween().set_loops()
	tw.tween_property(s, "position:y", -2.0, 0.4)
	tw.tween_property(s, "position:y", 0.0, 0.4)
	add_child.call_deferred(a)


var _tochas: Array[Sprite2D] = []
var _brilhos: Array[Sprite2D] = []
var _t_deco := 0.0


## tochas na parede de cima (com brilho aditivo) e vinheta escurecendo as bordas
func _decorar() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for x: int in [4, 15]:
		var t := Sprite2D.new()
		Visual.aplicar(t, "tocha", 1.0, 2)
		t.position = Vector2(x * T + 8, 9)
		t.z_index = -7
		add_child(t)
		_tochas.append(t)
		var b := Sprite2D.new()
		Visual.aplicar(b, "brilho")
		b.material = mat
		b.position = t.position + Vector2(0, 6)
		b.z_index = -6
		add_child(b)
		_brilhos.append(b)
	var v := Sprite2D.new()
	Visual.aplicar(v, "vinheta")
	v.centered = false
	v.z_index = 30
	add_child(v)


func _process(delta: float) -> void:
	_t_deco += delta
	for i in _tochas.size():
		_tochas[i].frame = int(_t_deco * 6.0 + i) % _tochas[i].hframes
		var f := 1.0 + 0.08 * sin(_t_deco * 11.0 + i * 2.0) + 0.05 * sin(_t_deco * 23.0)
		_brilhos[i].scale = Vector2(f, f)


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
	_tipo_porta[d] = tipo_vizinho
	var no := Node2D.new()
	add_child(no)
	var sprites: Array[Sprite2D] = []
	var s := Sprite2D.new()   # cima/baixo: 2 tiles, 1 sprite largo (*_larga)
	s.centered = false
	s.position = Vector2(_tiles_porta(d)[0] * T)
	s.z_index = -9
	no.add_child(s)
	sprites.append(s)
	var grade := Node2D.new()
	no.add_child(grade)
	for t: Vector2i in _tiles_porta(d):
		_solido(t, Camadas.PAREDE, grade)
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
		if corpo is Jogador and not porta_trancada(d) and not partida.morto():
			saiu.emit(d))
	no.add_child(gatilho)
	_portas[d] = {"grade": grade, "sprites": sprites}


func sprites_porta(d: Vector2i) -> Array[Sprite2D]:
	return _portas[d]["sprites"] if _portas.has(d) else [] as Array[Sprite2D]


func textura_porta(d: Vector2i) -> String:
	var tipo_v: int = _tipo_porta.get(d, GeradorAndar.COMBATE)
	if tipo_v == GeradorAndar.CHEFE and _chefe_trancado and not partida.tem_chave:
		return "res://arte/porta_chefe_trancada.png"
	if porta_trancada(d):
		return "res://arte/porta_fechada.png"
	return "res://arte/%s.png" % PORTA.get(tipo_v, "porta_combate")


func _atualizar_portas() -> void:
	for d: Vector2i in _portas:
		var fechar := porta_trancada(d)
		var nome := textura_porta(d).get_file().get_basename() + ("_larga" if d.y != 0 else "")
		for s: Sprite2D in _portas[d]["sprites"]:
			Visual.aplicar(s, nome)
		for b: Node in (_portas[d]["grade"] as Node2D).get_children():
			(b as StaticBody2D).collision_layer = Camadas.PAREDE if fechar else 0
