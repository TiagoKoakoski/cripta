# Cripta

Roguelike de masmorra em **Godot 4.7**. É a versão expandida da
[Cripta de Bolso](https://github.com/TiagoKoakoski/gb-cripta) de Game Boy.

Desça os **3 andares** (Cripta, Catacumbas e Abismo) e vença o chefe de cada um. Cada andar é gerado
na hora, como no The Binding of Isaac, e a cada porta você escolhe o caminho, como no Slay the Spire.
Morreu, volta ao título e recomeça do andar 1; o recorde fica salvo por personagem.

## Como jogar

`./jogar.sh` abre em tela cheia.

| | Teclado | Controle |
|---|---|---|
| Andar (8 direções) | WASD | analógico esquerdo / direcional |
| Atirar (4 direções, segurar = rajada) | setas | analógico direito / Y A X B |
| Escolher personagem (título) | ← → ou A D | analógico / direcional |
| Começar | Enter, espaço, ↑ ou ↓ | qualquer botão |

- **Personagens** (escolhidos no título):
  - **Atirador:** 3 corações, atira à distância.
  - **Espadachim:** 4 corações, mais rápido, golpe em arco que também **destrói tiros inimigos**.
    Os itens de tiro viram versões para a lâmina (ricochete devolve o tiro, explosivo explode quem
    morre no golpe, teleguiado lança uma lâmina a cada 3 golpes...). O anúncio do item diz o efeito.
- **Vida:** até 8 corações. Levou dano, fica ~1 s piscando e invencível.
- **Andares:** 1 Cripta (9–12 salas), 2 Catacumbas (10–13), 3 Abismo (11–14), cada um com seus
  inimigos, 2 tesouros e 1 fonte. Os inimigos ficam mais numerosos e com mais vida a cada andar.
  Depois do chefe aparece um **alçapão**: pise nele para descer (+2 de vida, itens mantidos).
  - **Portas:** trancam enquanto houver inimigo. Cada porta mostra o que vem do outro lado:
    **caveira** (combate), **baú** (tesouro), **coração** (fonte), **coroa** (chefe).
  - **Minimapa:** no canto.
  - **Salas limpas:** continuam limpas quando você volta.
- **Inimigos:**
  - **Morcego:** mergulha e recua.
  - **Slime:** anda à toa; o grande se divide em dois pequenos.
  - **Esqueleto:** fica parado e atira em você.
  - **Aranha:** chega em saltos curtos e rápidos.
  - **Fantasma:** persegue devagar e atravessa pilares.
  - **Olho:** parado; atira em cruz e depois em X.
  - **Mago:** some, reaparece longe de você e atira 3 tiros em leque.
  - Todo inimigo leva meio segundo para surgir (pisca e não fere). Quanto mais longe do início, mais e mais fortes.
- **Chefes** (um sorteado entre 2 por andar; barra de vida no topo; 3 fases; todo ataque forte é avisado):
  - **Cripta:** **Rei Esqueleto** (rajadas, depois espiral e esqueletos) ou **Slime Mãe** (salta, a
    sombra mostra onde cai; solta slimes e fica menor).
  - **Catacumbas:** **Aranha Rainha** (teias que viram poças que deixam você lento, aranhas,
    investidas) ou **Colosso de Ossos** (mira e investe até a parede; tonto, leva dano em dobro).
  - **Abismo:** **Olho do Abismo** (espirais; olhinhos que o protegem; feixe giratório) ou **Lich**
    (teleporta, cópias falsas, chuva de tiros com uma brecha).
- **Itens** (um por tesouro, sem repetir; os de tiro combinam entre si):
  - Espada: dano +1.
  - Raio: atira mais rápido.
  - Coração: +1 de vida máxima e cura 1.
  - Botas: anda mais rápido.
  - Tiro Triplo: dispara em leque.
  - Alcance: tiro mais longe e mais rápido.
  - Ricochete: o tiro quica uma vez na parede.
  - Perfurante: o tiro atravessa inimigos.
  - Teleguiado: o tiro curva atrás do inimigo mais perto.
  - Explosivo: o tiro explode e fere quem está em volta.
  - Gelo: o inimigo atingido fica lento por 2 s.
  - Retaguarda: atira também para trás.
- **Coração no chão:** algumas salas soltam um coração ao serem limpas (cura 1; fica no chão se a vida estiver cheia).
- **Fonte:** cura 2, uma vez.
- **Recorde:** 100 por andar concluído + salas limpas, por personagem, em `user://progresso.cfg`.

## Desenvolvimento

```bash
tests/rodar.sh                                         # todos os testes headless
godot --path . -- --autoplay --capturas=build/fotos --forte   # robô joga os 3 andares e fotografa
#   opções: --personagem=espadachim  --chefe=lich (força o chefe de todo andar)
godot --path . --script res://ferramentas/fotos_chefes.gd      # foto de cada chefe em build/chefes
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
