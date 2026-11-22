# godot --path . --script res://ferramentas/fotos_chefes.gd -- --pasta=build/chefes
# Fotografa a sala de cada chefe (com o tema do andar) e uma sala de combate de cada andar.
extends SceneTree

const CHEFES := {"rei": 1, "slime_mae": 1, "aranha_rainha": 2, "colosso": 2, "olho_abismo": 3, "lich": 3}


func _initialize() -> void:
	load("res://scripts/controles.gd").configurar()
	_rodar.call_deferred()


func _rodar() -> void:
	var pasta := "build/chefes"
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--pasta="):
			pasta = a.split("=", true, 1)[1]
	DirAccess.make_dir_recursive_absolute(pasta)
	for nome: String in CHEFES:
		for quem: String in ["atirador", "espadachim"] if nome == "rei" else ["atirador"]:
			var p := Partida.new()
			p.arquivo_recorde = "user://progresso_fotos.cfg"
			p.comecar(11, quem)
			p.andar_atual = CHEFES[nome]
			p.vida = 99
			var a := Andar.new()
			a.chefe_forcado = nome
			root.add_child(a)
			a.iniciar(p, 11)
			if nome == "rei":
				for pos: Vector2i in a.mapa["salas"]:
					if a.mapa["salas"][pos] == GeradorAndar.COMBATE:
						a.entrar(pos, Vector2i.DOWN)
						break
				for i in 90:
					await physics_frame
				await _foto("%s/combate_%s_andar%d.png" % [pasta, quem, CHEFES[nome]])
			a.entrar(a.mapa["chefe"], Vector2i.DOWN)
			for i in 200:
				await physics_frame
			var c := a.sala.chefe()
			if c:
				c.levar_tiro(c.hp / 2)
			for i in 60:
				await physics_frame
			await _foto("%s/chefe_%s_%s.png" % [pasta, nome, quem])
			a.queue_free()
			await process_frame
	for n in [2, 3]:
		var p := Partida.new()
		p.comecar(12)
		p.andar_atual = n
		p.vida = 99
		var a := Andar.new()
		root.add_child(a)
		a.iniciar(p, 12)
		for pos: Vector2i in a.mapa["salas"]:
			if a.mapa["salas"][pos] == GeradorAndar.COMBATE:
				a.entrar(pos, Vector2i.DOWN)
				break
		for i in 90:
			await physics_frame
		await _foto("%s/combate_andar%d.png" % [pasta, n])
		a.queue_free()
		await process_frame
	quit(0)


func _foto(arq: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(arq)
