## Estado de uma partida: vida, build (itens) e progresso. Lógica pura, sem nós.
class_name Partida
extends RefCounted

const ITENS: Array[String] = ["espada", "raio", "coracao_extra", "botas", "tiro_triplo", "alcance",
	"ricochete", "perfurante", "teleguiado", "explosivo", "gelo", "retaguarda"]
const ITENS_DE_TIRO: Array[String] = ["ricochete", "perfurante", "teleguiado", "explosivo", "gelo", "retaguarda"]
const VIDA_INICIAL := 3
const VIDA_MAXIMA := 8
const INVENCIBILIDADE := 1.0
const VELOCIDADE := 70.0

var vida := VIDA_INICIAL
var vida_max := VIDA_INICIAL
var dano := 1
var cadencia := 0.4        # segundos entre tiros
var velocidade := VELOCIDADE  # px/s
var tiro_triplo := false
var alcance := false
var ricochete := false
var perfurante := false
var teleguiado := false
var explosivo := false
var gelo := false
var retaguarda := false
var invencivel := 0.0
var itens_pegos: Array[String] = []
var salas_limpas: Dictionary = {}
var andar_atual := 1
var andares_concluidos := 0
var salas_total := 0       # salas limpas dos andares já deixados para trás
var semente := 0
var recorde := 0
var venceu := false
var arquivo_recorde := "user://recorde.cfg"
var _rng := RandomNumberGenerator.new()


func comecar(nova_semente: int) -> void:
	semente = nova_semente
	_rng.seed = nova_semente * 7919 + 13
	vida = VIDA_INICIAL
	vida_max = VIDA_INICIAL
	dano = 1
	cadencia = 0.4
	velocidade = VELOCIDADE
	tiro_triplo = false
	alcance = false
	for it: String in ITENS_DE_TIRO:
		set(it, false)
	invencivel = 0.0
	itens_pegos.clear()
	salas_limpas.clear()
	andar_atual = 1
	andares_concluidos = 0
	salas_total = 0
	venceu = false
	carregar_recorde()


func avancar(dt: float) -> void:
	invencivel = maxf(0.0, invencivel - dt)


## Devolve true se o dano contou (não estava invencível nem morto).
func levar_dano() -> bool:
	if invencivel > 0.0 or morto() or venceu:
		return false
	vida -= 1
	invencivel = INVENCIBILIDADE
	return true


func morto() -> bool:
	return vida <= 0


func curar(n: int) -> void:
	vida = mini(vida_max, vida + n)


func sortear_item(excluir: Array = []) -> String:
	var livres: Array[String] = []
	for it in ITENS:
		if not it in itens_pegos and not it in excluir:
			livres.append(it)
	if livres.is_empty():
		return "coracao_extra"
	return livres[_rng.randi_range(0, livres.size() - 1)]


func pegar_item(item: String) -> void:
	itens_pegos.append(item)
	match item:
		"espada":
			dano += 1
		"raio":
			cadencia = maxf(0.15, cadencia * 0.65)
		"coracao_extra":
			vida_max = mini(VIDA_MAXIMA, vida_max + 1)
			curar(1)
		"botas":
			velocidade *= 1.3
		"tiro_triplo":
			tiro_triplo = true
		"alcance":
			alcance = true
		_:
			if item in ITENS_DE_TIRO:
				set(item, true)


func limpar_sala(p: Vector2i) -> void:
	salas_limpas[p] = true


## pisou no alçapão: andar seguinte, +2 de vida, itens mantidos, salas do andar zeradas
func descer() -> void:
	andares_concluidos += 1
	andar_atual += 1
	salas_total += salas_limpas.size()
	salas_limpas.clear()
	curar(2)


func pontos() -> int:
	return 100 * andares_concluidos + salas_total + salas_limpas.size()


func terminar(vitoria: bool) -> void:
	venceu = vitoria
	if vitoria:
		andares_concluidos = Andares.TOTAL
	var pontos_ := pontos()
	if pontos_ > recorde:
		recorde = pontos_
		var cfg := ConfigFile.new()
		cfg.set_value("cripta", "recorde", recorde)
		cfg.save(arquivo_recorde)


func carregar_recorde() -> void:
	var cfg := ConfigFile.new()
	recorde = int(cfg.get_value("cripta", "recorde", 0)) if cfg.load(arquivo_recorde) == OK else 0


func apagar_recorde() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(arquivo_recorde))
	recorde = 0
