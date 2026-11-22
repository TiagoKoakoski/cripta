# godot --headless --path . --script res://tests/teste_main.gd
extends SceneTree

var passou := 0
var falhou := 0


func _initialize() -> void:
	load("res://scripts/controles.gd").configurar()
	_rodar.call_deferred()


func _rodar() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.arquivo_recorde = "user://teste_recorde_main.cfg"
	root.add_child(main)
	await frames(5)
	checa(main.estado == "titulo", "começa no título")
	await apertar("confirmar")
	checa(main.estado == "jogando" and main.andar != null, "confirmar começa a partida")
	var semente1: int = main.partida.semente
	main.partida.pegar_item("espada")
	main.partida.pegar_item("botas")
	main.partida.limpar_sala(Vector2i(1, 0))
	main.partida.vida = 1
	main.partida.invencivel = 0.0
	main.andar.sala.jogador.ferir()
	await frames(90)
	checa(main.estado == "fim", "morrer vai pra tela de fim")
	checa(main.partida.recorde >= 1, "recorde gravado")
	await apertar("confirmar")
	checa(main.estado == "jogando", "botão na tela de fim recomeça")
	checa([main.partida.dano, main.partida.velocidade, main.partida.vida, main.partida.itens_pegos.size()]
		== [1, Partida.VELOCIDADE, 3, 0], "recomeço zera a build")
	checa(main.partida.semente != semente1, "andar novo")
	# apertar tiro durante a pausa da morte não pode pular a tela de fim
	main.partida.vida = 1
	main.partida.invencivel = 0.0
	main.andar.sala.jogador.ferir()
	await frames(5)
	checa(main.estado == "terminando", "morreu: pausa antes da tela de fim")
	var tecla := InputEventKey.new()
	tecla.physical_keycode = KEY_UP
	tecla.pressed = true
	Input.parse_input_event(tecla)
	Input.flush_buffered_events()
	await process_frame
	await process_frame
	tecla.pressed = false
	Input.parse_input_event(tecla)
	Input.flush_buffered_events()
	checa(main.estado == "terminando", "tiro na pausa da morte não recomeça (estado %s)" % main.estado)
	await frames(90)
	checa(main.estado == "fim", "e a tela de fim aparece")
	# vitória: vencer os chefes dos 3 andares (descendo pelos alçapões) leva à tela de vitória
	await apertar("confirmar")
	checa(main.estado == "jogando", "nova partida")
	for n in 3:
		main.andar.entrar(main.andar.mapa["chefe"], Vector2i.DOWN)
		await frames(3)
		main.andar.sala.inimigo_mais_perto().levar_tiro(999)
		await frames(5)
		if n < 2:
			checa(main.estado == "jogando" and main.andar.sala.tem_alcapao(), "andar %d: alçapão" % (n + 1))
			main.andar.sala.jogador.position = Vector2(160, 88)
			await frames(5)
			checa(main.partida.andar_atual == n + 2, "desceu ao andar %d" % (n + 2))
	await frames(90)
	checa(main.estado == "vitoria", "chefe do andar 3 mostra a vitória (estado %s)" % main.estado)
	checa(main.partida.recorde >= 300, "vitória vale 300+ no recorde")
	checa(main.arquivo_para(["--autoplay"]) != main.arquivo_para([]), "robô grava recorde em arquivo próprio")
	main.partida.apagar_recorde()
	print("Resultado: %d ok, %d falhas" % [passou, falhou])
	quit(1 if falhou > 0 else 0)


func checa(cond: bool, rotulo: String) -> void:
	if cond:
		passou += 1
	else:
		falhou += 1
		push_error("FALHOU " + rotulo)


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func apertar(acao: String) -> void:
	await frames(45)   # telas ignoram botão nos primeiros 0,6 s
	Input.action_press(acao)
	await frames(3)
	Input.action_release(acao)
	await frames(5)
