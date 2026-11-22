## Robô do modo --autoplay: joga sozinho e fotografa cada sala em --capturas=/pasta.
## --forte deixa o robô com vida cheia em toda sala (pra chegar ao chefe nas capturas).
extends Node

var main: Node
var _pasta := ""
var _forte := false
var _fotos := 0
var _sala_vista: Sala
var _t_sala := 0.0
var _t_total := 0.0
var _ultima_pos := Vector2.ZERO
var _parado := 0.0
var _desvio := Vector2.ZERO
var _fim_t := -1.0
var _acabou := false
var _hp_alvo := -1
var _sem_progresso := 0.0
var _reposicionar := Vector2.ZERO


func _init(m: Node) -> void:
	main = m
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--capturas="):
			_pasta = a.split("=", true, 1)[1]
	_forte = OS.get_cmdline_user_args().has("--forte")
	if _pasta != "":
		DirAccess.make_dir_recursive_absolute(_pasta)


func _soltar() -> void:
	for a: String in ["mover_cima", "mover_baixo", "mover_esquerda", "mover_direita",
			"atirar_cima", "atirar_baixo", "atirar_esquerda", "atirar_direita", "confirmar"]:
		Input.action_release(a)


func _foto(nome: String) -> void:
	if _pasta == "":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%02d_%s.png" % [_pasta, _fotos, nome])
	_fotos += 1


func _physics_process(delta: float) -> void:
	_t_total += delta
	if _t_total > 900.0:
		print("robô: tempo esgotado")
		get_tree().quit(1)
		return
	match main.estado:
		"titulo":
			if _fotos == 0 and _t_total > 0.8:
				await _foto("titulo")
				Input.action_press("confirmar")
		"fim", "vitoria":
			_soltar()
			if _fim_t < 0.0:
				_fim_t = _t_total
			elif _t_total - _fim_t > 1.0 and not _acabou:
				_acabou = true
				await _foto(main.estado)
				print("robô: terminou em %s com %s no andar %d, pontos %d, recorde %d" % [main.estado,
					main.partida.personagem, main.partida.andar_atual, main.partida.pontos(), main.partida.recorde])
				get_tree().quit(0)
		"jogando":
			Input.action_release("confirmar")
			_jogar(delta)


func _jogar(delta: float) -> void:
	var andar: Andar = main.andar
	if andar == null or andar.sala == null or not is_instance_valid(andar.sala):
		return
	var sala := andar.sala
	if sala != _sala_vista:
		_sala_vista = sala
		_t_sala = 0.0
		if _forte:
			main.partida.vida = main.partida.vida_max
	_t_sala += delta
	if _forte:
		main.partida.vida = main.partida.vida_max
	if is_equal_approx(_t_sala, delta) or (_t_sala > 0.5 and _t_sala - delta <= 0.5):
		if _t_sala > 0.5:
			_foto(["inicio", "combate", "tesouro", "fonte", "chefe"][sala.tipo])
	_soltar()
	var j := sala.jogador
	var alvo := sala.inimigo_mais_perto()
	var destino := Vector2.ZERO
	if alvo:
		# tiro bloqueado (pilar no meio)? sem dano por 3 s: muda de lugar por um tempo
		if alvo.hp != _hp_alvo:
			_hp_alvo = alvo.hp
			_sem_progresso = 0.0
		else:
			_sem_progresso += delta
		if _sem_progresso > 3.0:
			_sem_progresso = 0.0
			_reposicionar = Vector2(randf_range(40, 280), randf_range(30, 150))
		if _reposicionar != Vector2.ZERO:
			if j.position.distance_to(_reposicionar) < 8.0 or _sem_progresso > 2.0:
				_reposicionar = Vector2.ZERO
			else:
				_ir(j, _reposicionar, delta)
				Input.action_press(_eixo(alvo.position - j.position, "atirar"))
				return
		var d: Vector2 = alvo.position - j.position
		Input.action_press(_eixo(d, "atirar"))
		var dist := d.length()
		if main.partida.personagem == "espadachim":   # corpo a corpo: encosta e golpeia
			if dist > 16.0:
				destino = alvo.position - d.normalized() * 14.0
		elif absf(d.x) > 3.0 and absf(d.y) > 3.0:   # alinha no eixo menor pra acertar
			destino = j.position + (Vector2(0, d.y) if absf(d.y) < absf(d.x) else Vector2(d.x, 0))
		elif dist < 40.0:
			destino = j.position - d
		elif dist > 90.0:
			destino = alvo.position
	elif sala.tem_alcapao():
		destino = Vector2(160, 88)
	elif not sala.objeto_usado() and sala.tipo in [GeradorAndar.TESOURO, GeradorAndar.FONTE] \
			and (sala.tipo == GeradorAndar.TESOURO or main.partida.vida < main.partida.vida_max):
		destino = Vector2(160, 92)
	else:
		destino = Sala.centro_porta(_proxima_porta(andar))
	if destino != Vector2.ZERO:
		_ir(j, destino, delta)


func _ir(j: Jogador, destino: Vector2, delta: float) -> void:
	if true:
		var v := destino - j.position
		if j.position.distance_to(_ultima_pos) < 0.2:
			_parado += delta
		else:
			_parado = 0.0
		_ultima_pos = j.position
		if _parado > 0.4:
			_desvio = Vector2(-v.y, v.x).normalized() * (1.0 if randf() < 0.5 else -1.0)
			_parado = 0.0
		var mover := v.normalized() + _desvio
		_desvio *= 0.97
		if mover.x > 0.3: Input.action_press("mover_direita")
		if mover.x < -0.3: Input.action_press("mover_esquerda")
		if mover.y > 0.3: Input.action_press("mover_baixo")
		if mover.y < -0.3: Input.action_press("mover_cima")


func _eixo(d: Vector2, prefixo: String) -> String:
	if absf(d.x) > absf(d.y):
		return prefixo + ("_direita" if d.x > 0 else "_esquerda")
	return prefixo + ("_baixo" if d.y > 0 else "_cima")


## porta da sala atual que leva ao próximo objetivo: tesouro ainda não pego, depois o chefe
func _proxima_porta(andar: Andar) -> Vector2i:
	var salas: Dictionary = andar.mapa["salas"]
	var objetivo: Vector2i = andar.mapa["chefe"]
	for p: Vector2i in salas:
		if salas[p] == GeradorAndar.TESOURO and not main.partida.salas_limpas.has(p):
			objetivo = p
	var ant := {andar.posicao: andar.posicao}
	var fila: Array[Vector2i] = [andar.posicao]
	while not fila.is_empty():
		var p: Vector2i = fila.pop_front()
		if p == objetivo:
			break
		for v: Vector2i in GeradorAndar.vizinhos(salas, p):
			if not ant.has(v):
				ant[v] = p
				fila.append(v)
	var passo := objetivo
	while ant.has(passo) and ant[passo] != andar.posicao and passo != andar.posicao:
		passo = ant[passo]
	return passo - andar.posicao
