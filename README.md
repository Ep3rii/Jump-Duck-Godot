# Jump Duck — versão Godot 4

Conversão do projeto GameMaker `Jump Duck` para **Godot 4.4+** (renderer Compatibility).
Abra a pasta no Godot (`project.godot`) e rode com F5. Na primeira abertura o editor importa
os PNGs e o MP3 sozinho.

## Controles

| Ação | Teclas |
|---|---|
| Mover | Setas ou A / D |
| Pular (pulo duplo) | Espaço |
| Pegar / arremessar caixa | X ou J |
| Pousar caixa na frente | Baixo + X/J |
| Escalar cipó | Cima / Baixo (Espaço solta) |
| Nadar | boia sozinho; Baixo mergulha (fôlego de 5 s, bolhas no HUD); Espaço sai da água |
| Pausar | Esc |
| Menus | Setas/W/S, Enter ou Espaço, mouse |

### Teclas de depuração (só rodando pelo editor / build de debug)

| Tecla | Efeito |
|---|---|
| F1 | Liga/desliga invencível (aparece "DEBUG: INVENCÍVEL" no canto) |
| F2 | +1 vida |
| F3 | Recomeça a fase |
| F4 | Conclui a fase na hora |

## Regras do jogo

- A fase termina ao encostar na **saída** (bandeira amarela). As flores valem pontos (até 50);
  o tempo vale o resto (até 50). 90+ = 3 estrelas, 60+ = 2.
- Encostar num inimigo tira 1 coração; pular em cima derrota (inimigos com `stompable`).
- Perigos (`perigo.tscn`) e cair para fora do mapa tiram 1 coração e levam ao último
  **checkpoint** (bandeirinha que fica verde) ou ao início da fase.
- Sem corações: FIM DE JOGO, e TENTAR NOVAMENTE recomeça **a mesma fase** com vidas cheias.
- Recorde e estrelas de cada fase e as fases liberadas ficam em `user://jump_duck_save.cfg`
  (menu CONTINUAR e FASES).
- **Caixas:** o pato empurra andando contra elas, sobe nelas, pega (X/J) e arremessa. A caixa
  arremessada derrota inimigos. Caixa que cai para fora do mapa volta ao lugar inicial.
- **Placa de pressão:** fica apertada com o pato ou uma caixa em cima e liga seus `alvos`
  (portas e plataformas móveis).
- **Chave e porta trancada:** a chave vai para o bolso (aparece no HUD, embaixo dos corações);
  encostar numa porta com fechadura gasta 1 chave e abre a porta para sempre.
- **Aves de rapina:** o gaviãozinho patrulha no alto e dá um rasante em arco onde o pato estava
  quando ele gritou (correr depois do grito escapa); a águia circula, grita, mergulha em
  diagonal e, se bate no chão, fica com o bico preso (2 golpes). Pisão ou caixa arremessada.
- **Vento:** áreas com listras empurram o pato (e caixas paradas) para o lado; as rajadas
  ligam e desligam, e as listras voltam um pouco antes de cada rajada. A **corrente de ar** para
  cima levanta o pato até o andar de cima, e dentro dela cair não machuca.
- **Pedra rachada:** treme quando o pato (ou uma caixa) pisa, cai depois de meio segundo e volta
  para o lugar uns 3 segundos depois.

## Fases

| Fase | Cena | Conteúdo |
|---|---|---|
| Tutorial | `scenes/tutorial.tscn` | fazenda e moinho; placas de dica ensinam andar, pular, flores, pulo duplo, queda alta + cipó, empurrar o feno, checkpoint e, no fim, a raposa |
| Fase 1 | `scenes/fase1.tscn` | caminho até a torre (torre ao fundo): raposa entre buracos, caixa empurrada do ressalto para subir o paredão, placa + porta, arremesso na raposa do patamar, plataforma móvel |
| Fase 2 | `scenes/fase2.tscn` | o lago: nadar e mergulhar (flor no fundo), caixa que boia empurrada pelo lago até virar degrau, jacarés, parede que só se passa mergulhando |
| Fase 3 | `scenes/fase3.tscn` | lago com jacarés e túnel submerso, depois a arena do **jacaré gigante** (mini-chefe): bolhas avisam o salto contra as plataformas, mordida forte e "dor de dente", a hora do pisão; 5 pisões abrem a porta da saída |
| Fase 4 | `scenes/fase4.tscn` | dentro da torre (1/6), 4 andares ligados por cipós: a primeira chave e porta trancada, um gaviãozinho por andar, caixa empurrada para um buraco segurando a placa da sala da 2ª chave, saída numa sacada no alto |
| Fase 5 | `scenes/fase5.tscn` | torre (2/6), de baixo à direita: paredão de 5 tiles (empurrar a caixa para subir), a águia, chave num ressalto alto (levar a caixa até embaixo), derrubar a caixa de um ressalto até a placa, porta trancada antes da saída |
| Fase 6 | `scenes/fase6.tscn` | torre (3/6): apresenta as pedras que caem (sobre um poço sem fundo), a rajada de vento contra (esperar acalmar para pular o vão) e a corrente de ar que sobe; depois pedras sobre vãos, rajadas e gaviões em 4 andares |
| Fase 7 | `scenes/fase7.tscn` | torre (4/6), um poço estreito e alto: escada de pedras que caem, corrente de ar, travessia com vento a favor e gavião, cipó, pedras com rajada contra e a águia, e a última corrente até a saída |
| Fase 8 | `scenes/fase8.tscn` | torre (5/6), tudo junto: rajada com vãos sem fundo, duas chaves e portas trancadas, pedras sobre poços, correntes de ar, águia e gaviões; vento a favor sobre um vão enorme no fim |

O roteiro das fases seguintes está em [ROTEIRO_FASES.md](ROTEIRO_FASES.md). Toda a decoração
(moinho, celeiro, cerca, árvores, placas, caixa/feno) é provisória, desenhada em código, até
existir a arte definitiva.

## Laboratório de mecânicas

`scenes/laboratorio.tscn` tem uma de cada mecânica (caixa, placa e porta, raposa, cipó,
plataforma móvel, água, checkpoint, vida extra, saída). Abra e rode com F6, ou entre por
FASES → LABORATÓRIO (só aparece rodando pelo editor). Ele não grava recorde nem progresso.

## Testes automáticos

Jogam sozinhos, sem abrir janela: a fase de testes `scenes/testes/fase_teste.tscn` (o tutorial
original do GameMaker, mantido só para os testes), o laboratório e trechos de cada fase
do jogo (cada pulo, paredão, puzzle e inimigo que precisa ser possível, ou impossível, de passar):

```
godot --headless --path . res://tests/test_runner.tscn
```

O código de saída é o número de falhas. Rode depois de cada mudança na jogabilidade.
Os testes usam arquivos de save próprios e não mexem no seu progresso.

Para revisar o visual das telas sem jogar, este comando abre uma janela por alguns segundos e
salva uma captura de cada tela em `%APPDATA%\Godot\app_userdata\Jump Duck\screenshots\`:

```
godot --path . res://tests/screenshots.tscn
```

## Criando uma fase nova

1. Duplique `scenes/fase_base.tscn` (modelo vazio 640x360 com moldura, chão, jogador, câmera,
   paralaxe, saída e uma camada `TilesChao` com o TileSet `assets/tilesets/grama_solida.tres`,
   já marcado como sólido: é só pintar).
2. No nó raiz ajuste `room_size`; `level_id` pode ficar vazio (usa o nome do arquivo).
3. Acrescente a fase em `Game.levels` (`scripts/game.gd`), na ordem em que deve ser jogada,
   com o nome que aparece nas telas. A seleção de fases, o CONTINUAR e o botão PRÓXIMA FASE
   saem dessa lista.
4. Chão: nós `Block` **ou** um `TileMapLayer` no grupo `solid_tiles` cujo TileSet tenha a
   camada de *custom data* `solid` (bool) marcada nos tiles que são chão/parede.
5. Objetos prontos em `scenes/`: `saida` (obrigatória), `checkpoint`, `perigo` (área com
   `tiles_w`/`tiles_h`; invisível ou com aparência de água), `flor`, `vida` (coração extra),
   `raposa`, `caixa`, `placa` (ligue os `alvos`), `porta`, `plataforma` (deslocamento,
   velocidade, espera; desligue `ativa` para só andar com a placa), `escalavel` (cipó;
   alinhe o topo com o chão de cima), `dica` (placa com texto; `|` quebra a linha) e
   `decoracao` (moinho, celeiro, cerca, árvore, arbusto, seta de saída, junco), `agua` (água
   nadável, desenhada translúcida na frente do pato; caixas boiam nela), `chave`, `porta` com
   `trancada` (abre com a chave), `gaviaozinho` (`alcance` da patrulha), `aguia` (circula em
   volta de onde foi posta), `vento` (direção Direita/Esquerda/Cima, `forca`, `rajada` com
   tempos e `atraso`), `plataforma_cai` (pedra rachada; `tempo_tremendo`, `tempo_volta`),
   `jacare_chefe` (use
   `alvos_ao_derrotar` para abrir a porta da arena; todo inimigo tem esse campo) e `jacare` (vive numa
   `agua`; `comeca_mergulhado` alterna o ciclo entre jacarés). A paralaxe tem
   `mostrar_torre` para a torre aparecer ao fundo e `cenario` = "Torre por dentro" (parede de
   tijolos com janelas e tochas). Para as fases da torre use o TileSet
   `assets/tilesets/pedra_solida.tres` (mesma grade do de grama).
   Alturas de referência: pulo simples sobe ~34 px (2 tiles), pulo duplo ~68 px (4 tiles);
   5 tiles só com uma caixa embaixo; queda de 6 tiles (96 px) ou mais machuca.
6. Inimigo novo: script com `extends Enemy` (`scripts/enemy.gd` explica o contrato).
7. A câmera olha 50 px para cima do pato (como no original; `camera_offset_y` no nó raiz da fase
   muda isso, as fases de lago usam 0): perigos muito abaixo de uma
   plataforma ficam fora da tela.

## Mapa GameMaker → Godot

| GameMaker | Godot |
|---|---|
| `obj_game_manager` (estado, menus, pontuação, ini) | `scripts/game.gd` (autoload `Game`) |
| `Draw_64` do manager (menus e HUD) | `scripts/ui.gd` (desenha em código, grade 320x180) |
| `obj_player` | `scenes/player.tscn` + `scripts/player.gd` |
| `obj_raposa` | `scenes/raposa.tscn` + `scripts/raposa.gd` (herda de `scripts/enemy.gd`) |
| `obj_flor01` / `obj_efeito` | `scenes/flor.tscn` / `scenes/efeito.tscn` |
| `obj_blocoPiso01` | `scenes/block.tscn` (`tiles_w` / `tiles_h` = image_xscale/yscale) |
| `obj_camera` | `scripts/camera.gd` (Camera2D) |
| `obj_parallax` | `scripts/parallax.gd` |
| rooms `menu`, `tutorial_fase1` | `scenes/menu.tscn`, `scenes/testes/fase_teste.tscn` (o tutorial original; hoje só serve aos testes) |
| `place_meeting` contra sólidos | `scripts/solids.gd` (blocos + tiles com custom data `solid`) |
| sprites | `assets/sprites/*.png` (tiras horizontais) + `assets/frames/*.tres` (SpriteFrames) |
| tilemaps `Tiles_1` / `Tiles_2` | `scripts/tile_data.gd` → `TileMapLayer` montado em `levels/fase_teste.gd` |
| `ini_*` (jump_duck_settings.ini) | `ConfigFile` em `user://jump_duck_settings.cfg` |

## Decisões da conversão

- **Física idêntica ao GameMaker.** O movimento foi portado passo a passo para `_physics_process`
  (60 Hz): gravidade 0.25, pulo -4, buffer de pulo, dano por queda de 96 px, pisão na raposa.
  A colisão usa retângulos (a máscara dos sprites no GameMaker) contra os blocos, em vez de
  `CharacterBody2D`, para manter a mesma sensação.
- **Ordem de desenho** (`depth` do GameMaker) virou `z_index = -depth` nos nós de cada camada.
- **Tile 0** do GameMaker é o tile "vazio" e não é desenhado (as células com índice 0 foram omitidas).
- A fonte pixel (`spr_fontPixel`, glifos 8x8) é desenhada diretamente, com a mesma ordem de glifos.
- O jogo exportado abre em **tela cheia** (modo sem borda do sistema, alt-tab funciona); rodando pelo editor abre em janela. Muda em Configurações → TELA.
- **Pausa real:** fora do estado "playing" a árvore é pausada (`get_tree().paused`); `Game` e a UI rodam com `PROCESS_MODE_ALWAYS`.
- `obj_blocoAgua01`, `obj_lago01`, `obj_piso01` e `obj_florVazia01` existem no GameMaker, mas não são
  usados em nenhuma sala, então não foram convertidos. A água da fase é só decoração (tiles).
- Sprites não usados (`spr_agua01Anima`, `spr_BBg01Anima`, `spr_voltar`, `spr_fechar`...) foram
  exportados para `assets/` caso queira usá-los.

## Direitos autorais

Copyright (c) 2026 Euzébio Pereira da Silva Filho. Todos os direitos reservados.

Consulte o arquivo [LICENSE](./LICENSE) para conhecer as condições de uso.
