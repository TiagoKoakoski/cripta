# godot --headless --path . --script res://tests/teste_pausa.gd
# Start/Esc pausa e abre o menu: Continuar, Visual, Controles, Voltar ao título, Sair.
extends SceneTree

var passou := 0
var falhou := 0


func _initialize() -> void:
	load("res://scripts/controles.gd").configurar()
	Visual.arquivo = "user://teste_config_pausa.cfg"
	Engine.max_fps = 60   # quadros de processo em tempo real (a pausa para a física)
	_rodar.call_deferred()


func checa(cond: bool, rotulo: String) -> void:
	if cond:
		passou += 1
	else:
		falhou += 1
		push_error("FALHOU " + rotulo)


## espera n/60 s de tempo real (funciona também com a árvore pausada)
func frames(n: int) -> void:
	for i in n:
		await process_frame


func apertar(acao: String, espera := 10) -> void:
	Input.action_press(acao)
	await frames(3)
	Input.action_release(acao)
	await frames(espera)


func _rodar() -> void:
	checa(InputMap.has_action("pausar"), "ação pausar existe (Esc, P, Start)")
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.arquivo_recorde = "user://teste_recorde_pausa.cfg"
	root.add_child(main)
	await frames(50)
	await apertar("pausar")
	checa(not main.pausado and main.estado == "titulo", "no título o Start não pausa")
	await apertar("confirmar", 50)
	checa(main.estado == "historia", "história (estado %s)" % main.estado)
	await apertar("pausar")
	checa(not main.pausado, "na história o Start não pausa")
	while main.estado == "historia":
		await apertar("confirmar", 45)
	checa(main.estado == "jogando", "jogando")
	await apertar("pausar")
	checa(main.pausado and paused and main.menu_pausa() != null, "Start pausa e abre o menu")
	var j: Node2D = main.andar.sala.jogador
	var p0 := j.position
	Input.action_press("mover_direita")
	await frames(20)
	Input.action_release("mover_direita")
	checa(j.position == p0, "pausado: o jogo para")
	checa(main.menu_pausa().opcao_atual() == 0, "menu começa em Continuar")
	# Visual: desce 1 e confirma -> alterna
	var antes: String = Visual.modo
	await apertar("mover_baixo")
	await apertar("confirmar")
	checa(Visual.modo != antes and main.pausado, "opção Visual alterna o visual e continua pausado")
	var cfg := ConfigFile.new()
	cfg.load(Visual.arquivo)
	checa(cfg.get_value("visual", "modo", "") == Visual.modo, "visual salvo")
	# Controles: mostra a ajuda e volta
	await apertar("mover_baixo")
	await apertar("confirmar")
	checa(main.menu_pausa().mostrando_controles(), "Controles mostra a ajuda")
	await apertar("confirmar")
	checa(not main.menu_pausa().mostrando_controles(), "botão volta da ajuda")
	# Continuar: de Controles (2) sobe 2 até o topo e confirma
	for k in 2:
		await apertar("mover_cima")
	await apertar("confirmar")
	checa(not main.pausado and not paused and main.menu_pausa() == null, "Continuar despausa")
	# Start de novo pausa; Start no menu também despausa
	await apertar("pausar")
	await apertar("pausar")
	checa(not main.pausado, "Start no menu volta ao jogo")
	# Voltar ao título
	await apertar("pausar")
	for k in 3:
		await apertar("mover_baixo")
	await apertar("confirmar", 20)
	checa(main.estado == "titulo" and not paused and main.andar == null, "Voltar ao título encerra a partida")
	Visual.definir_modo("detalhado")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Visual.arquivo))
	print("Resultado: %d ok, %d falhas" % [passou, falhou])
	quit(1 if falhou > 0 else 0)
