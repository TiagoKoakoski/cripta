# Cripta

Roguelike de masmorra em **Godot 4.7**. É a versão expandida da
[Cripta de Bolso](https://github.com/TiagoKoakoski/gb-cripta) de Game Boy.

## A Torre Morta

Numa noite sem estrelas, uma torre negra brotou do cemitério de Vale-Cinza e rachou a velha cripta
ao meio. No alto dela, o Lich Vesper rasgou o céu: o **Abismo** engole as estrelas, uma a uma, e
quando a última apagar os mortos da cidade levantam. Quatro moradores entram pela cripta e **sobem**
a torre para fechar a fenda.

Suba os **3 andares** (Cripta, Catacumbas, Abismo). Em cada um, ache o **subchefe**, pegue a
**chave** e enfrente o chefe. Os andares são gerados na hora, como no The Binding of Isaac. A cada
porta você escolhe o caminho, como no Slay the Spire. Morreu, volta ao título e recomeça do andar 1.
O recorde fica salvo por personagem.

## Como jogar

`./jogar.sh` abre em tela cheia.

| | Teclado | Controle |
|---|---|---|
| Andar (8 direções) | WASD | analógico esquerdo / direcional |
| Atirar (4 direções, segurar = rajada) | setas | analógico direito / Y A X B |
| Escolher personagem (título) | ← → ou A D | analógico / direcional |
| Começar | Enter, espaço, ↑ ou ↓ | qualquer botão |
| Pausar (menu) | Esc ou P | Start |

- **Menu de pausa:** Continuar, **Visual** (Clássico ou Detalhado; vale na hora e fica salvo),
  Controles, Voltar ao título e Sair do jogo.
- **Visual Detalhado** (padrão): arte gerada por IA e reduzida para pixel art, com tela interna de
  640x360. O **Clássico** usa os sprites de 16 px desenhados à mão.
- **Salas:** 14 desenhos com pilares, pedras, **caixas** (quebram com 2 acertos, às vezes dão
  coração), **buracos** (quem anda não passa; tiros e voadores passam por cima) e **espinhos** (ferem).

- **Personagens** (escolhidos no título; os itens de tiro se adaptam a cada um, e o anúncio do item diz o efeito):
  - **Iara, a Atiradora:** 3 corações, atira a luz do farol.
  - **Bento, o Espadachim:** 4 corações, mais rápido, golpe em arco que também **destrói tiros inimigos**.
  - **Lúcio, o Alquimista:** 3 corações, frascos em arco que explodem em área (dano 2, mais lento).
  - **Cauã, o Caçador:** 3 corações, o mais rápido, bumerangue que acerta na ida e na volta.
- **Vida:** até 8 corações. Levou dano, fica ~1 s piscando e invencível.
- **Andares:** 1 Cripta (10–12 salas), 2 Catacumbas (13–15), 3 Abismo (16–19). Cada um tem seus
  inimigos, 2 tesouros, 1 fonte, 1 subchefe e 1 chefe. Os inimigos ficam mais numerosos e com mais vida
  a cada andar. Depois do chefe aparece uma **escada**: pise nela para subir (+2 de vida, itens mantidos),
  com uma transição mostrando a torre.
  - **Portas:** trancam enquanto houver inimigo. Cada tipo de sala tem a sua porta. Combate é de
    madeira, tesouro é dourada, a fonte tem arco azul, o subchefe tem correntes vermelhas. O chefe
    tem crânios e **cadeado** até você ter a chave.
  - **Minimapa:** salas ainda não visitadas aparecem cinza.
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
- **Subchefes** (um sorteado entre 2 por andar; 2 fases; deixam a chave):
  - **Cripta:** Morcego Vampiro (mergulhos, chama morcegos) ou Esqueleto Capitão (leques e investidas).
  - **Catacumbas:** Aranha Tecelã (teias em cruz) ou Slime Rei (vira 2 slimes grandes ao morrer).
  - **Abismo:** Mago Sombrio (2 teleportes e leque de 5) ou Fantasma Antigo (some e reaparece).
- **Chefes** (um sorteado entre 3 por andar; barra de vida no topo; 3 fases; todo ataque forte é avisado):
  - **Cripta:**
    - **Rei Esqueleto:** rajadas, depois espiral e esqueletos.
    - **Slime Mãe:** salta, a sombra mostra onde cai; solta slimes e fica menor.
    - **Cavaleiro sem Cabeça:** investe, arremessa a cabeça que persegue; na fase 3 deixa fogo.
  - **Catacumbas:**
    - **Aranha Rainha:** teias que viram poças e deixam você lento, aranhas, investidas.
    - **Colosso de Ossos:** mira e investe até a parede; fica tonto e leva dano em dobro.
    - **Verme de Ossos:** cava, o chão treme onde ele vai sair, anel de tiros.
  - **Abismo:**
    - **Olho do Abismo:** espirais; olhinhos que o protegem; feixe giratório.
    - **Vesper, o Lich:** teleporta, cópias falsas, chuva de tiros com uma brecha.
    - **Sombra Gêmea:** a sua sombra, que espelha você e atira quando você atira.
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
$V ferramentas/gerar_arte.py && $V ferramentas/gerar_sons.py  # regenera arte clássica e sons
ferramentas/arte_ia/gerar.sh && $V ferramentas/arte_ia/pixelizar.py  # arte detalhada (Nano Banana)
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
- **Arte:**
  - **Clássico:** desenhos da versão Game Boy, recoloridos por `ferramentas/gerar_arte.py`.
  - **Detalhado:** gerado com o Nano Banana (Gemini).
    - `ferramentas/arte_ia/prompts.json` guarda os pedidos.
    - `gerar.sh` gera o que falta em `originais/` (JPEG).
    - `pixelizar.py` recorta as figuras do fundo magenta, reduz para pixel art 2x e salva em `arte/hd/`.
  - **No código:** todo sprite passa por `Visual.aplicar(sprite, nome)` (`scripts/visual.gd`).
- **Sons:** sintetizados por `ferramentas/gerar_sons.py`.
