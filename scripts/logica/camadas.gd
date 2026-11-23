## Camadas de colisão (bits).
class_name Camadas
extends RefCounted

const PAREDE := 1
const PILAR := 2
const JOGADOR := 4
const INIMIGO := 8
const TIRO_JOGADOR := 16
const TIRO_INIMIGO := 32
const BURACO := 64   # bloqueia quem anda; tiros e voadores passam por cima
