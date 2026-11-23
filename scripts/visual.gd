## Visual do jogo: "classico" (arte de 16 px de arte/) ou "detalhado" (arte gerada em 2x de arte/hd/).
## Todo sprite passa por Visual.aplicar(sprite, nome, base, quadros): no detalhado, se houver
## arte/hd/<nome>.png, usa ela com escala base*0.5 e os quadros de QUADROS_HD; senão, o clássico.
## Os sprites ficam no grupo "visual" e são reaplicados na hora quando o modo muda.
## Classe estática (não autoload): funciona igual no jogo e nos testes headless.
class_name Visual
extends Object

const CLASSICO := "classico"
const DETALHADO := "detalhado"
## quadros (hframes) das artes HD que têm mais de 1
## personagens: (baixo, direita, cima, esquerda) x 4 quadros do ciclo de caminhada (1 = parado)
static var QUADROS_HD := {"heroi": 16, "espadachim": 16, "alquimista": 16, "cacador": 16}

static var modo := DETALHADO
static var arquivo := "user://config.cfg"
static var _cache := {}
static var _carregado := false


static func carregar() -> void:
	_carregado = true
	var cfg := ConfigFile.new()
	if cfg.load(arquivo) == OK:
		modo = cfg.get_value("visual", "modo", DETALHADO)


static func definir_modo(novo: String) -> void:
	_carregado = true
	modo = novo if novo in [CLASSICO, DETALHADO] else DETALHADO
	var cfg := ConfigFile.new()
	cfg.load(arquivo)
	cfg.set_value("visual", "modo", modo)
	cfg.save(arquivo)
	var arvore := Engine.get_main_loop() as SceneTree
	if arvore:
		for s: Node in arvore.get_nodes_in_group("visual"):
			if is_instance_valid(s) and s is Sprite2D:
				_aplicar(s)


static func alternar() -> void:
	definir_modo(CLASSICO if modo == DETALHADO else DETALHADO)


static func caminho_hd(nome: String) -> String:
	return "res://arte/hd/%s.png" % nome


static func tem_hd(nome: String) -> bool:
	return ResourceLoader.exists(caminho_hd(nome)) or FileAccess.file_exists(caminho_hd(nome))


static func aplicar(s: Sprite2D, nome: String, base := 1.0, quadros := 1) -> void:
	if not _carregado:
		carregar()
	s.set_meta("visual_nome", nome)
	s.set_meta("visual_base", base)
	s.set_meta("visual_quadros", quadros)
	_aplicar(s)
	if not s.is_in_group("visual"):
		s.add_to_group("visual")


## o sprite está mostrando arte HD agora?
static func e_hd(s: Sprite2D) -> bool:
	return s.get_meta("visual_hd", false)


## fator de escala do sprite (0,5 no HD): para quem mexe na escala depois (chefes, squash)
static func fator(s: Sprite2D) -> float:
	return 0.5 if e_hd(s) else 1.0


static func _aplicar(s: Sprite2D) -> void:
	var nome: String = s.get_meta("visual_nome", "")
	var base: float = s.get_meta("visual_base", 1.0)
	var hd := modo == DETALHADO and tem_hd(nome)
	var caminho := caminho_hd(nome) if hd else "res://arte/%s.png" % nome
	var tex := _carregar(caminho)
	if tex:
		s.texture = tex
	s.set_meta("visual_hd", hd)
	s.hframes = QUADROS_HD.get(nome, 1) if hd else int(s.get_meta("visual_quadros", 1))
	s.frame = mini(s.frame, s.hframes * s.vframes - 1)
	s.scale = Vector2.ONE * base * (0.5 if hd else 1.0)


static func _carregar(caminho: String) -> Texture2D:
	if _cache.has(caminho):
		return _cache[caminho]
	var tex: Texture2D = null
	if ResourceLoader.exists(caminho):
		tex = load(caminho)
	elif FileAccess.file_exists(caminho):   # png ainda não importado (ferramentas/testes)
		var img := Image.load_from_file(ProjectSettings.globalize_path(caminho))
		if img:
			tex = ImageTexture.create_from_image(img)
			tex.take_over_path(caminho)
	if tex:
		_cache[caminho] = tex
	return tex
