# godot --headless --path . --script res://tests/teste_visual.gd
# Visual Clássico (16 px) x Detalhado (arte/hd, 2x) e a resolução 640x360.
extends SceneTree

var passou := 0
var falhou := 0
const HD_TESTE := "res://arte/hd/_teste_visual.png"


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var v := Visual
	v.arquivo = "user://teste_config.cfg"
	# uma imagem HD de teste (2x do clássico "sombra", 4 quadros)
	var img := Image.create(32 * 4, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	img.save_png(ProjectSettings.globalize_path(HD_TESTE))
	v.QUADROS_HD["_teste_visual"] = 4
	checa(ProjectSettings.get_setting("display/window/size/viewport_width") == 640
		and ProjectSettings.get_setting("display/window/size/viewport_height") == 360, "tela interna 640x360")
	v.definir_modo("classico")
	var s := Sprite2D.new()
	root.add_child(s)
	v.aplicar(s, "sombra", 1.0)
	checa(s.texture.resource_path.ends_with("arte/sombra.png") and s.scale == Vector2.ONE, "clássico: arte 16 px, escala 1")
	var t := Sprite2D.new()
	root.add_child(t)
	# nome sem HD: no detalhado continua o clássico
	v.definir_modo("detalhado")
	v.aplicar(t, "tocha", 2.0, 2)
	checa(t.texture.resource_path.ends_with("arte/tocha.png") and t.scale == Vector2(2, 2) and t.hframes == 2,
		"detalhado sem arte HD: cai no clássico")
	# com HD: escala pela metade e quadros do HD
	var u := Sprite2D.new()
	root.add_child(u)
	v.definir_modo("classico")
	v.aplicar(u, "_teste_visual", 2.0, 8)
	u.frame = 7
	checa(u.hframes == 8 and u.scale == Vector2(2, 2), "clássico com 8 quadros")
	v.definir_modo("detalhado")   # troca ao vivo: todo sprite do grupo é reaplicado
	checa(u.texture.resource_path == HD_TESTE and u.scale == Vector2(1, 1) and u.hframes == 4,
		"troca ao vivo para o detalhado (escala 0,5 x base, 4 quadros)")
	checa(u.frame < u.hframes, "quadro continua dentro do hframes (%d)" % u.frame)
	checa(v.e_hd(u) and not v.e_hd(t), "e_hd diz quem tem arte HD")
	var cfg := ConfigFile.new()
	cfg.load(v.arquivo)
	checa(cfg.get_value("visual", "modo", "") == "detalhado", "modo salvo na config")
	v.definir_modo("classico")
	checa(u.texture.resource_path.ends_with("arte/_teste_visual.png") or u.scale == Vector2(2, 2), "volta ao clássico")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HD_TESTE))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(v.arquivo))
	print("Resultado: %d ok, %d falhas" % [passou, falhou])
	quit(1 if falhou > 0 else 0)


func checa(cond: bool, rotulo: String) -> void:
	if cond:
		passou += 1
	else:
		falhou += 1
		push_error("FALHOU " + rotulo)
