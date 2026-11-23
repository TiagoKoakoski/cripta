## Ataque do espadachim: golpe em arco na direção do ataque. Destrói tiros inimigos no arco.
## Itens de tiro adaptados: tiro triplo = arco de 180°, alcance = raio +50%, ricochete = devolve o
## tiro inimigo, perfurante = avanço curto, teleguiado = lâmina teleguiada a cada 3 golpes,
## explosivo = quem morre no golpe explode, gelo = congela, retaguarda = golpe também atrás.
class_name ArmaLamina
extends RefCounted

const RAIO := 24.0
const ANGULO := 100.0
const AVANCO := 14.0
const FOLGA_CORPO := 6.0   # metade aproximada do corpo do inimigo

var _golpes := 0


static func no_arco(origem: Vector2, dir: Vector2, raio: float, angulo_graus: float, ponto: Vector2) -> bool:
	var d := ponto - origem
	if d.length() > raio:
		return false
	if d.length() < 4.0:
		return true
	return absf(dir.angle_to(d)) <= deg_to_rad(angulo_graus) / 2.0 + 0.02


## devolve true se o ataque saiu
func atacar(j: Jogador, dir: Vector2) -> bool:
	var p := j.partida
	_golpes += 1
	if p.perfurante:
		j.move_and_collide(dir * AVANCO)
	var raio := RAIO * (1.5 if p.alcance else 1.0)
	var angulo := 180.0 if p.tiro_triplo else ANGULO
	var dirs: Array[Vector2] = [dir]
	if p.retaguarda:
		dirs.append(-dir)
	for d: Vector2 in dirs:
		Golpe.mostrar(j.sala, j.position, d, raio, angulo)
		for n: Node in j.get_tree().get_nodes_in_group("inimigo"):
			var e := n as Inimigo
			if e == null or not e.vivo():
				continue
			if not no_arco(j.position, d, raio + FOLGA_CORPO, angulo, e.position):
				continue
			e.levar_tiro(p.dano, d)
			if p.gelo and e.vivo():
				e.congelar(2.0)
			if p.explosivo and not e.vivo():
				Tiro.explodir_em(j.sala, e.position, p.dano, e)
		for n: Node in j.get_tree().get_nodes_in_group("caixa"):
			var cx := n as Caixa
			if cx and no_arco(j.position, d, raio + 8.0, angulo, cx.position):
				cx.levar_dano(p.dano)
		for n: Node in j.get_tree().get_nodes_in_group("tiro_inimigo"):
			var t := n as Tiro
			if t == null or t.is_queued_for_deletion():
				continue
			if not no_arco(j.position, d, raio + 4.0, angulo, t.position):
				continue
			if p.ricochete:
				var meu := Tiro.criar(t.position, -t.direcao, true, p.dano, 200.0, 0.8)
				j.sala.add_child(meu)
			t.queue_free()
	if p.teleguiado and _golpes % 3 == 0:
		var l := Tiro.criar(j.position + dir * 8.0, dir, true, p.dano, 160.0, 1.4)
		l.guiado = true
		l.modulate = Color(0.85, 0.6, 1.0)
		j.sala.add_child(l)
	Sons.tocar("tiro")
	return true
