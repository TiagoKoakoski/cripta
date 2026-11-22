## Ataque do Alquimista: frascos em arco que explodem em área. Itens adaptados: tiro triplo = 3
## frascos, alcance = mais longe e explosão maior, ricochete = quica e explode de novo, perfurante =
## deixa fogo, teleguiado = cai no inimigo perto da mira, explosivo = explosão maior, gelo = congela,
## retaguarda = um frasco para trás.
class_name ArmaFrasco
extends RefCounted

const DISTANCIA := 64.0
const RAIO := 20.0


func atacar(j: Jogador, dir: Vector2) -> void:
	var p := j.partida
	var dist := DISTANCIA * (1.5 if p.alcance else 1.0)
	var raio := (28.0 if p.alcance else RAIO) + (8.0 if p.explosivo else 0.0)
	var dirs: Array[Vector2] = [dir]
	if p.tiro_triplo:
		dirs.append(dir.rotated(deg_to_rad(22)))
		dirs.append(dir.rotated(deg_to_rad(-22)))
	if p.retaguarda:
		dirs.append(-dir)
	for d: Vector2 in dirs:
		var alvo := j.position + d * dist
		if p.teleguiado:
			alvo = _inimigo_perto(j, alvo, 50.0)
		Frasco.lancar(j.sala, p, j.position, alvo, raio)
	Sons.tocar("tiro")


func _inimigo_perto(j: Jogador, ponto: Vector2, alcance: float) -> Vector2:
	var melhor := ponto
	var d_melhor := alcance
	for n: Node in j.get_tree().get_nodes_in_group("inimigo"):
		var e := n as Inimigo
		if e and e.vivo() and e.position.distance_to(ponto) < d_melhor:
			melhor = e.position
			d_melhor = e.position.distance_to(ponto)
	return melhor
