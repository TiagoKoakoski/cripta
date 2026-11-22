## Ataque do atirador: tiros (com tiro triplo, retaguarda, alcance e os efeitos da build).
class_name ArmaTiro
extends RefCounted


func atacar(j: Jogador, dir: Vector2) -> void:
	var p := j.partida
	var vel := 240.0 if p.alcance else 180.0
	var dur := 0.9 if p.alcance else 0.6
	var dirs: Array[Vector2] = [dir]
	if p.tiro_triplo:
		dirs.append(dir.rotated(deg_to_rad(15)))
		dirs.append(dir.rotated(deg_to_rad(-15)))
	if p.retaguarda:
		dirs.append(-dir)
	for d: Vector2 in dirs:
		var t := Tiro.criar(j.position + d * 8.0, d, true, p.dano, vel, dur)
		t.aplicar_build(p)
		j.sala.add_child(t)
	Sons.tocar("tiro")
