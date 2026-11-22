## Ataque do Caçador: bumerangue que vai e volta. Só 1 no ar (2 com tiro triplo, +1 com retaguarda).
## Itens: alcance = vai 135 px, ricochete = volta mais rápido, perfurante = atravessa paredes,
## teleguiado = curva para inimigos, explosivo = explode no ponto de virada, gelo = congela.
class_name ArmaBumerangue
extends RefCounted


func atacar(j: Jogador, dir: Vector2) -> void:
	var p := j.partida
	var no_ar := j.get_tree().get_nodes_in_group("bumerangue").filter(func(b: Node) -> bool:
		return not b.is_queued_for_deletion() and (b as Bumerangue).dono == j).size()
	var limite := (2 if p.tiro_triplo else 1) + (1 if p.retaguarda else 0)
	if no_ar >= limite:
		return
	var dirs: Array[Vector2] = []
	if p.tiro_triplo:
		dirs.append_array([dir.rotated(deg_to_rad(18)), dir.rotated(deg_to_rad(-18))])
	else:
		dirs.append(dir)
	if p.retaguarda:
		dirs.append(-dir)
	for d: Vector2 in dirs:
		if no_ar >= limite:
			break
		Bumerangue.lancar(j, d)
		no_ar += 1
	Sons.tocar("tiro")
