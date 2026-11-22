## Estado de uma partida: vida, build (itens) e progresso. Lógica pura, sem nós.
class_name Partida
extends RefCounted

const ITENS: Array[String] = ["espada", "raio", "coracao_extra", "botas", "tiro_triplo", "alcance",
	"ricochete", "perfurante", "teleguiado", "explosivo", "gelo", "retaguarda"]
const ITENS_DE_TIRO: Array[String] = ["ricochete", "perfurante", "teleguiado", "explosivo", "gelo", "retaguarda"]
const PERSONAGENS: Array[String] = ["atirador", "espadachim", "alquimista", "cacador"]
## vida, velocidade, dano, cadência de cada personagem
const BASE := {"atirador": [3, 70.0, 1, 0.4], "espadachim": [4, 80.0, 2, 0.45], "alquimista": [3, 70.0, 2, 0.7],
	"cacador": [3, 85.0, 1, 0.45]}
const VERSAO_SAVE := 3
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
var lentidao_jogador := 0.0   # segundos restantes de lentidão (teia)
var itens_pegos: Array[String] = []
var salas_limpas: Dictionary = {}
var andar_atual := 1
var andares_concluidos := 0
var tem_chave := false     # chave do chefe do andar atual (cai do subchefe)
var salas_total := 0       # salas limpas dos andares já deixados para trás
var semente := 0
var personagem := "atirador"
var recorde := 0
var venceu := false
var arquivo_recorde := "user://progresso.cfg"
var _rng := RandomNumberGenerator.new()


func comecar(nova_semente: int, quem := "atirador") -> void:
	semente = nova_semente
	personagem = quem if quem in PERSONAGENS else "atirador"
	_rng.seed = nova_semente * 7919 + 13
	var b: Array = BASE[personagem]
	vida = b[0]
	vida_max = b[0]
	velocidade = b[1]
	dano = b[2]
	cadencia = b[3]
	tiro_triplo = false
	alcance = false
	for it: String in ITENS_DE_TIRO:
		set(it, false)
	invencivel = 0.0
	lentidao_jogador = 0.0
	itens_pegos.clear()
	salas_limpas.clear()
	andar_atual = 1
	andares_concluidos = 0
	salas_total = 0
	tem_chave = false
	venceu = false
	carregar_recorde()


func avancar(dt: float) -> void:
	invencivel = maxf(0.0, invencivel - dt)
	lentidao_jogador = maxf(0.0, lentidao_jogador - dt)


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


## pisou no escada: andar seguinte, +2 de vida, itens mantidos, salas do andar zeradas
func subir() -> void:
	andares_concluidos += 1
	andar_atual += 1
	salas_total += salas_limpas.size()
	salas_limpas.clear()
	tem_chave = false
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
		cfg.load(arquivo_recorde)   # mantém o recorde dos outros personagens
		cfg.set_value("save", "versao", VERSAO_SAVE)
		cfg.set_value(personagem, "recorde", recorde)
		cfg.save(arquivo_recorde)


func carregar_recorde() -> void:
	recorde = recorde_de(personagem)


## recorde salvo de um personagem (0 se não houver ou se o arquivo for de outra versão)
func recorde_de(quem: String) -> int:
	var cfg := ConfigFile.new()
	if cfg.load(arquivo_recorde) != OK or int(cfg.get_value("save", "versao", 0)) != VERSAO_SAVE:
		return 0
	return int(cfg.get_value(quem, "recorde", 0))


func apagar_recorde() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(arquivo_recorde))
	recorde = 0
