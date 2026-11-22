## Toca efeitos sonoros (autoload). Em modo headless não toca nada.
class_name Sons
extends Node

var _cache := {}


static func tocar(nome: String) -> void:
	var raiz := Engine.get_main_loop() as SceneTree
	if raiz == null or DisplayServer.get_name() == "headless":
		return
	var no := raiz.root.get_node_or_null("Audio")
	if no:
		no._tocar(nome)


func _tocar(nome: String) -> void:
	if not _cache.has(nome):
		_cache[nome] = load("res://sons/%s.wav" % nome)
	var p := AudioStreamPlayer.new()
	p.stream = _cache[nome]
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
