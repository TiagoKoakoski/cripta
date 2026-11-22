# Cripta

Roguelike de masmorra em **Godot 4.7**. É a versão expandida da
[Cripta de Bolso](https://github.com/TiagoKoakoski/gb-cripta) de Game Boy.

Cada andar é gerado na hora, como no The Binding of Isaac. A cada porta você escolhe o caminho,
como no Slay the Spire. Morreu, recomeça num andar novo; o recorde fica salvo.

## Como jogar

`./jogar.sh` abre em tela cheia.

| | Teclado | Controle |
|---|---|---|
| Andar (8 direções) | WASD | analógico esquerdo / direcional |
| Atirar (4 direções, segurar = rajada) | setas | analógico direito / Y A X B |
| Começar / recomeçar | Enter, espaço ou qualquer seta | qualquer botão |

- **Vida:** 3 corações (até 8). Levou dano, fica ~1 s piscando e invencível.
- **Andar:** de 8 a 11 salas.
  - **Portas:** trancam enquanto houver inimigo. Cada porta mostra o que vem do outro lado:
    **caveira** (combate), **baú** (tesouro), **coração** (fonte), **coroa** (chefe).
  - **Minimapa:** no canto.
  - **Salas limpas:** continuam limpas quando você volta.
- **Inimigos:**
  - **Morcego:** mergulha e recua.
  - **Slime:** anda à toa; o grande se divide em dois pequenos.
  - **Esqueleto:** fica parado e atira em você.
  - **Rei Esqueleto:** o chefe tem 30 de vida. Ele persegue você e solta rajadas em cruz, e em 8 direções quando ferido.
- **Itens** (um por tesouro, sem repetir):
  - Espada: dano +1.
  - Raio: atira mais rápido.
  - Coração: +1 de vida máxima e cura 1.
  - Botas: anda mais rápido.
  - Tiro Triplo: dispara em leque.
  - Alcance: tiro mais longe e mais rápido.
- **Fonte:** cura 2, uma vez.
- **Recorde:** salas limpas, +100 se vencer. Salvo em `user://recorde.cfg`.

## Desenvolvimento

```bash
tests/rodar.sh                                         # todos os testes headless
godot --path . -- --autoplay --capturas=build/fotos --forte   # robô joga e fotografa
V=~/Projetos/jogos/_ferramentas/venv/bin/python
$V ferramentas/gerar_arte.py && $V ferramentas/gerar_sons.py  # regenera arte e sons
```

- `scripts/logica/`: regras puras, testadas sem cena.
  - `gerador_andar.gd`: o mapa do andar.
  - `partida.gd`: vida, itens e recorde.
- `scripts/`: o jogo em si.
  - `sala.gd`: uma sala montada.
  - `andar.gd`: troca de salas, HUD e minimapa.
  - `jogador.gd`, `inimigo.gd`, `tiro.gd`, `main.gd`.
  - `robo.gd`: o modo `--autoplay`.
- `tests/`: assets, andar, partida, sala (física e entrada simulada), navegação e fluxo do jogo.
- Arte e sons 100% próprios. Os desenhos vêm da versão Game Boy, recoloridos por
  `ferramentas/gerar_arte.py`, e os sons são sintetizados por `ferramentas/gerar_sons.py`.
