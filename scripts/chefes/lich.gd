## Lich (70): teleporta como o mago e atira leques de 5. Fase 2: 2 cópias falsas (1 de vida) que
## somem quando ele leva dano (e voltam depois de 8 s). Fase 3: chuva do topo com colunas livres.
extends Chefe

var ultima_chuva: Array = []   # x de cada coluna da última onda de chuva
var _estado_l := "pausa"
var _copias := 8.0
var _ondas := 0


func _preparar() -> void:
	_t = 0.6


func estado_atual() -> String:
	return _estado_l


func levar_tiro(dano: int, dir := Vector2.ZERO) -> void:
	var antes := hp
	super(dano, dir)
	if hp < antes:
		_sumir_copias()
		_copias = 8.0


func _agir(delta: float) -> void:
	velocity = Vector2.ZERO
	if _fase >= 2:
		_copias -= delta
		if _copias <= 0.0 and invocados_vivos("lich_copia") == 0:
			_criar_copias()
	match _estado_l:
		"pausa":
			if _t <= 0.0:
				if _fase == 3 and _ondas < 3:
					_estado_l = "chuva"
					_t = 0.0
				else:
					_ondas = 0
					_estado_l = "sumir"
					_t = 0.35
		"sumir":
			_sprite.modulate.a = clampf(_t / 0.35, 0.0, 1.0)
			if _t <= 0.0:
				position = _ponto_de_teleporte()
				_estado_l = "aparecer"
				_t = 0.35
		"aparecer":
			_sprite.modulate.a = clampf(1.0 - _t / 0.35, 0.0, 1.0)
			if _t <= 0.0:
				var alvo := _para_jogador()
				for a: float in [-0.5, -0.25, 0.0, 0.25, 0.5]:
					atirar(alvo.rotated(a), 85.0)
				ultima_rajada = 5
				_estado_l = "pausa"
				_t = [0.0, 1.5, 1.2, 0.9][_fase]
		"chuva":
			if _t <= 0.0:
				_chuva()
				_ondas += 1
				_estado_l = "pausa"
				_t = 1.3


func _chuva() -> void:
	var colunas := []
	var x := 32.0
	while x <= 288.0:
		colunas.append(x)
		x += 16.0
	var buraco := _rng.randi_range(0, colunas.size() - 3)
	var onda: Array = []
	for i in colunas.size():
		if i >= buraco and i < buraco + 3:
			continue
		atirar(Vector2.DOWN, 70.0, 2.4, Vector2(colunas[i], 22.0))
		onda.append(colunas[i])
	ultima_chuva = onda
	ultima_rajada = onda.size()


func _criar_copias() -> void:
	for d: Vector2 in [Vector2(-60, 20), Vector2(60, 20)]:
		invocar("lich_copia", position + d)
	for v: Variant in sala._inimigos:
		if is_instance_valid(v) and (v as Inimigo).tipo == "lich_copia":
			(v as Inimigo)._sprite.modulate = Color(0.8, 1, 0.9, 0.7)


func _sumir_copias() -> void:
	for v: Variant in sala._inimigos.duplicate():
		if is_instance_valid(v) and (v as Inimigo).tipo == "lich_copia":
			(v as Inimigo).sumir()
			sala._inimigos.erase(v)


func _ao_mudar_fase(f: int) -> void:
	if f == 2:
		_criar_copias()
