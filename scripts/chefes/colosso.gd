## Colosso de Ossos (60): mira com linha de aviso (0,7 s) e investe em linha reta até bater; fica
## tonto 1,2 s (leva dano em dobro) e solta leque de 5 ossos. Fase 3: 2 investidas seguidas.
extends Chefe

const MIRA := 0.7
const TONTO := 1.2

var _estado_c := "pausa"
var _dir_c := Vector2.ZERO
var _seguidas := 0
var _linha: Line2D


func _preparar() -> void:
	_t = 0.3
	_ajustar_escala(2.2)


func estado_atual() -> String:
	return _estado_c


func _fator_dano() -> float:
	return 2.0 if _estado_c == "tonto" else 1.0


func aviso_ativo() -> bool:
	return _estado_c == "mirar"


func _agir(delta: float) -> void:
	match _estado_c:
		"pausa":
			velocity = _para_jogador() * 20.0
			if _t <= 0.0:
				_mirar()
		"mirar":
			velocity = Vector2.ZERO
			_dir_c = _para_jogador()
			_mostrar_linha(true)
			if _t <= 0.0:
				_mostrar_linha(false)
				_estado_c = "investir"
				_t = 3.0   # segurança: nunca investe para sempre
		"investir":
			velocity = _dir_c * 220.0
			var bateu := get_slide_collision_count() > 0 or position.x <= 21.0 or position.x >= 299.0 \
				or position.y <= 21.0 or position.y >= 155.0
			if (bateu and _t < 2.9) or _t <= 0.0:
				velocity = Vector2.ZERO
				_seguidas += 1
				if _fase == 3 and _seguidas < 2:
					_mirar()
				else:
					_seguidas = 0
					_estado_c = "tonto"
					_t = TONTO
					var p := _para_jogador()
					for a: float in [-0.6, -0.3, 0.0, 0.3, 0.6]:
						atirar(p.rotated(a), 90.0)
					ultima_rajada = 5
					Sons.tocar("acerto")
		"tonto":
			velocity = Vector2.ZERO
			_sprite.rotation = sin(_t * 20.0) * 0.15
			if _t <= 0.0:
				_sprite.rotation = 0.0
				_estado_c = "pausa"
				_t = [0.0, 1.2, 0.9, 0.7][_fase]


func _mirar() -> void:
	_estado_c = "mirar"
	_t = MIRA


func _mostrar_linha(sim: bool) -> void:
	if _linha == null:
		_linha = Line2D.new()
		_linha.width = 2.0
		_linha.default_color = Color(1, 0.3, 0.3, 0.6)
		_linha.z_index = -3
		add_child(_linha)
	_linha.visible = sim
	_linha.points = PackedVector2Array([Vector2.ZERO, _dir_c * 300.0])
