## Mapa de controles (autoload). Teclado: WASD anda, setas atiram. Controle: analógico esquerdo
## ou direcional anda; analógico direito ou botões Y/A/X/B atiram (cima/baixo/esquerda/direita).
extends Node

const ZONA_MORTA := 0.3


func _ready() -> void:
	configurar()


static func configurar() -> void:
	var mapa := {
		"mover_cima": [KEY_W, [JOY_AXIS_LEFT_Y, -1.0], JOY_BUTTON_DPAD_UP],
		"mover_baixo": [KEY_S, [JOY_AXIS_LEFT_Y, 1.0], JOY_BUTTON_DPAD_DOWN],
		"mover_esquerda": [KEY_A, [JOY_AXIS_LEFT_X, -1.0], JOY_BUTTON_DPAD_LEFT],
		"mover_direita": [KEY_D, [JOY_AXIS_LEFT_X, 1.0], JOY_BUTTON_DPAD_RIGHT],
		"atirar_cima": [KEY_UP, [JOY_AXIS_RIGHT_Y, -1.0], JOY_BUTTON_Y],
		"atirar_baixo": [KEY_DOWN, [JOY_AXIS_RIGHT_Y, 1.0], JOY_BUTTON_A],
		"atirar_esquerda": [KEY_LEFT, [JOY_AXIS_RIGHT_X, -1.0], JOY_BUTTON_X],
		"atirar_direita": [KEY_RIGHT, [JOY_AXIS_RIGHT_X, 1.0], JOY_BUTTON_B],
	}
	for acao: String in mapa:
		_limpar(acao)
		var tecla := InputEventKey.new()
		tecla.physical_keycode = mapa[acao][0]
		InputMap.action_add_event(acao, tecla)
		var eixo := InputEventJoypadMotion.new()
		eixo.device = -1
		eixo.axis = mapa[acao][1][0]
		eixo.axis_value = mapa[acao][1][1]
		InputMap.action_add_event(acao, eixo)
		var botao := InputEventJoypadButton.new()
		botao.device = -1
		botao.button_index = mapa[acao][2]
		InputMap.action_add_event(acao, botao)
	_limpar("confirmar")
	for k: Key in [KEY_ENTER, KEY_SPACE, KEY_KP_ENTER]:
		var t := InputEventKey.new()
		t.physical_keycode = k
		InputMap.action_add_event("confirmar", t)
	for b: JoyButton in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_START]:
		var e := InputEventJoypadButton.new()
		e.device = -1
		e.button_index = b
		InputMap.action_add_event("confirmar", e)


static func _limpar(acao: String) -> void:
	if InputMap.has_action(acao):
		InputMap.erase_action(acao)
	InputMap.add_action(acao, ZONA_MORTA)
