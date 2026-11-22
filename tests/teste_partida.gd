# godot --headless --path . --script res://tests/teste_partida.gd
extends SceneTree

var passou := 0
var falhou := 0


func _initialize() -> void:
	for t: String in ["teste_inicio", "teste_dano_e_invencibilidade", "teste_morte", "teste_cura_limite",
			"teste_itens", "teste_itens_de_tiro", "teste_itens_sem_repetir", "teste_recomeco_zera", "teste_recorde"]:
		if call(t) != true:
			falhou += 1
			push_error("FALHOU %s: não terminou" % t)
	print("Resultado: %d ok, %d falhas" % [passou, falhou])
	quit(1 if falhou > 0 else 0)


func igual(a: Variant, b: Variant, rotulo: String) -> void:
	if a == b:
		passou += 1
	else:
		falhou += 1
		push_error("FALHOU %s: esperado %s, veio %s" % [rotulo, b, a])


func nova() -> Partida:
	var p := Partida.new()
	p.arquivo_recorde = "user://teste_recorde.cfg"
	p.apagar_recorde()
	p.comecar(1)
	return p


func teste_inicio() -> bool:
	var p := nova()
	igual([p.vida, p.vida_max, p.dano, p.cadencia, p.velocidade, p.tiro_triplo, p.alcance],
		[3, 3, 1, 0.4, 70.0, false, false], "valores iniciais")
	return true


func teste_dano_e_invencibilidade() -> bool:
	var p := nova()
	igual(p.levar_dano(), true, "primeiro dano conta")
	igual(p.vida, 2, "vida 2")
	igual(p.levar_dano(), false, "invencível logo depois")
	p.avancar(0.5)
	igual(p.levar_dano(), false, "ainda invencível em 0,5 s")
	p.avancar(0.6)
	igual(p.levar_dano(), true, "vulnerável depois de 1 s")
	igual(p.vida, 1, "vida 1")
	return true


func teste_morte() -> bool:
	var p := nova()
	for i in 3:
		p.levar_dano()
		p.avancar(1.1)
	igual(p.morto(), true, "morre com 0")
	igual(p.vida, 0, "não fica negativa")
	return true


func teste_cura_limite() -> bool:
	var p := nova()
	p.levar_dano()
	p.curar(2)
	igual(p.vida, 3, "cura não passa do máximo")
	return true


func teste_itens() -> bool:
	var p := nova()
	p.pegar_item("espada")
	igual(p.dano, 2, "espada")
	p.pegar_item("raio")
	igual(p.cadencia < 0.4, true, "raio")
	p.pegar_item("coracao_extra")
	igual([p.vida_max, p.vida], [4, 4], "coração extra")
	p.pegar_item("botas")
	igual(p.velocidade > 70.0, true, "botas")
	p.pegar_item("tiro_triplo")
	igual(p.tiro_triplo, true, "tiro triplo")
	p.pegar_item("alcance")
	igual(p.alcance, true, "alcance")
	for i in 10:
		p.pegar_item("coracao_extra")
	igual(p.vida_max, 8, "máximo de 8 corações")
	return true


func teste_itens_de_tiro() -> bool:
	var p := nova()
	igual([p.ricochete, p.perfurante, p.teleguiado, p.explosivo, p.gelo, p.retaguarda],
		[false, false, false, false, false, false], "tiro começa simples")
	for it: String in ["ricochete", "perfurante", "teleguiado", "explosivo", "gelo", "retaguarda"]:
		igual(it in Partida.ITENS, true, "%s está no sorteio" % it)
		p.pegar_item(it)
	igual([p.ricochete, p.perfurante, p.teleguiado, p.explosivo, p.gelo, p.retaguarda],
		[true, true, true, true, true, true], "cada item liga seu efeito")
	p.comecar(3)
	igual([p.ricochete, p.perfurante, p.teleguiado, p.explosivo, p.gelo, p.retaguarda],
		[false, false, false, false, false, false], "recomeço desliga os efeitos de tiro")
	return true


func teste_itens_sem_repetir() -> bool:
	var p := nova()
	var vistos := {}
	for i in 12:
		var it := p.sortear_item()
		p.pegar_item(it)
		vistos[it] = true
	igual(vistos.size(), 12, "12 itens diferentes")
	igual(p.sortear_item(), "coracao_extra", "acabaram: dá coração extra")
	return true


func teste_recomeco_zera() -> bool:
	var p := nova()
	p.pegar_item("espada")
	p.pegar_item("botas")
	p.limpar_sala(Vector2i(1, 0))
	p.comecar(2)
	igual([p.dano, p.velocidade, p.vida, p.salas_limpas.size(), p.itens_pegos.size()],
		[1, 70.0, 3, 0, 0], "recomeço zera build")
	return true


func teste_recorde() -> bool:
	var p := nova()
	p.limpar_sala(Vector2i(1, 0))
	p.limpar_sala(Vector2i(2, 0))
	p.terminar(false)
	igual(p.recorde, 2, "recorde = salas limpas")
	var outra: Partida = Partida.new()
	outra.arquivo_recorde = "user://teste_recorde.cfg"
	outra.carregar_recorde()
	igual(outra.recorde, 2, "recorde persiste")
	p.comecar(3)
	p.limpar_sala(Vector2i(1, 0))
	p.terminar(false)
	igual(p.recorde, 2, "recorde não cai")
	p.apagar_recorde()
	return true
