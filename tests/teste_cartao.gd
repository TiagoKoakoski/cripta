# godot --headless --path . --script res://tests/teste_cartao.gd
# Cartões ilustrados no visual Detalhado; no Clássico, a torre desenhada.
extends SceneTree

var passou := 0
var falhou := 0


func _initialize() -> void:
	Visual.arquivo = "user://teste_config_cartao.cfg"
	_rodar.call_deferred()


func checa(cond: bool, rotulo: String) -> void:
	if cond:
		passou += 1
	else:
		falhou += 1
		push_error("FALHOU " + rotulo)


func _rodar() -> void:
	var pag := [{"titulo": "T", "texto": "texto", "de": 1, "para": 2, "imagem": "cartao_catacumbas"}]
	Visual.definir_modo("detalhado")
	var c := Cartao.mostrar(root, pag, "atirador", 9.0)
	await process_frame
	checa(c.ilustracao_visivel(), "detalhado: cartão mostra a ilustração")
	checa(c.texto_atual() == "texto", "e o texto por cima")
	c.queue_free()
	Visual.definir_modo("classico")
	var d := Cartao.mostrar(root, pag, "atirador", 9.0)
	await process_frame
	checa(not d.ilustracao_visivel(), "clássico: sem ilustração (torre desenhada)")
	d.queue_free()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.arquivo_recorde = "user://teste_recorde_cartao.cfg"
	Visual.definir_modo("detalhado")
	root.add_child(main)
	await process_frame
	checa(main.fundo_da_tela() == "fundo_titulo", "título com ilustração de fundo (%s)" % main.fundo_da_tela())
	Visual.definir_modo("detalhado")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Visual.arquivo))
	print("Resultado: %d ok, %d falhas" % [passou, falhou])
	quit(1 if falhou > 0 else 0)
