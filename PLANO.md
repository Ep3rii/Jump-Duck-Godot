# Jump Duck — Plano de desenvolvimento

Base: resumo do Notion (`jump-duck-resumo.md`) + leitura completa do código atual
(Godot 4.7, conversão do GameMaker: 1 fase `tutorial_fase1`, 1 inimigo `raposa`, flores, menus desenhados em `ui.gd`).

> **Como os bugs foram levantados:** só pela leitura do código. Não rodei o jogo (não há
> binário do Godot no PATH). Se você já viu outros bugs jogando, eles entram na Fase 1.

---

## Andamento

| Fase | Status |
|---|---|
| 0 — Preparação | ✅ git + `.gitignore`, teclas de debug F1–F4, repositório privado [Ep3rii/Jump-Duck-Godot](https://github.com/Ep3rii/Jump-Duck-Godot) (o antigo `Jump-Duck` fica com o projeto GameMaker) |
| 1 — Bugs e base | ✅ B1–B6 e E1, E2, E3, E6, E7, E8 corrigidos; 40 testes automáticos passando (`tests/test_runner.tscn`). E4 e E5 feitos na Fase 2 |
| 2 — Sistemas | ✅ Saída (D4), checkpoint, perigo, vida extra, `enemy.gd` com raposa por cima, fim de jogo recomeça a fase (D3), recorde/estrelas/fases liberadas salvos, menu com CONTINUAR, FASES, CRÉDITOS e CONTROLES, volumes de música e efeitos separados, efeitos sonoros sintetizados (provisórios), fade entre cenas; 76 testes passando. Ficou para a Fase 4: arremesso de objetos (D2), que depende dos objetos carregáveis |
| 4 — Mecânicas | ✅ Caixa (empurrar, subir, pegar, arremessar e pousar), placa de pressão, porta, plataforma móvel, cipó escalável, perigo com aparência de água, laboratório de mecânicas (`scenes/laboratorio.tscn`), cena modelo `fase_base.tscn` com TileSet sólido pronto para pintar; 106 testes passando |
| 3, 5 e 6 | Não iniciadas |

---

## Estado atual (o que já existe)

| Item do escopo | Situação no código |
|---|---|
| Vidas | 3 corações no HUD, invulnerabilidade de 120 frames, dano por queda (96 px) |
| Morte | Animação `dead` → tela FIM DE JOGO |
| Pontuação | Tempo (até 50) + flores (até 50) por fase, estrelas, histórico em `level_history` |
| Combate | Só o pisão na raposa; encostar de lado causa dano |
| Menu | Principal, configurações (tela/janela/volume), pausa, fase concluída, fim de jogo |
| Inimigos | Raposa (patrulha ±64 px). **Gavião e jacaré não existem, nem os sprites** |
| Fases | Só `tutorial_fase1` (tiles gerados a partir do GameMaker em `tile_data.gd`) |
| Arrastáveis / cutscene | Não existem |

---

## Bugs e problemas encontrados

### Bugs de jogo

| # | Bug | Onde | Correção proposta |
|---|---|---|---|
| B1 | **Despausar com ESPAÇO faz o pato pular.** ESPAÇO é `confirm` e `jump` ao mesmo tempo; o `Game` muda para `playing` e o jogador lê o mesmo "acabou de apertar" no mesmo frame | [game.gd:15](scripts/game.gd:15), [game.gd:369](scripts/game.gd:369), [player.gd:157](scripts/player.gd:157) | Ignorar o pulo até a tecla ser solta depois de qualquer troca de estado |
| B2 | **Pato congela no ar ao levar dano** (30 frames sem gravidade) | [player.gd:106-107](scripts/player.gd:106) | Manter gravidade no estado `hurt` e aplicar um pequeno recuo (knockback) |
| B3 | **Pausa não pausa tudo:** animações do pato, flores, brilho e nuvens continuam | `_step()` de cada script testa `game_state` à mão | Usar `get_tree().paused` + `process_mode` (UI e Game com `ALWAYS`) |
| B4 | **Dano de queda ignora o pulo duplo:** `fall_start_y` não é zerado ao pular no ar, então cair 80 px, pular e cair mais 30 px dá dano | [player.gd:152](scripts/player.gd:152), [player.gd:158](scripts/player.gd:158) | Zerar `fall_start_y` ao pular (o pulo duplo "amortece" a queda) |
| B5 | **Raposa ignora o terreno:** patrulha ±64 px sem olhar parede nem borda; em outra posição ela anda no ar ou atravessa blocos | [raposa.gd:36-40](scripts/raposa.gd:36) | Virar ao encontrar parede ou ao chegar na beirada |
| B6 | **Tela cheia exclusiva** (`EXCLUSIVE_FULLSCREEN`) dá problemas de alt-tab no Windows e abre em tela cheia toda vez que roda pelo editor | [game.gd:187](scripts/game.gd:187) | `WINDOW_MODE_FULLSCREEN`; no editor, abrir em janela |

### Problemas de estrutura (impedem crescer o jogo)

| # | Problema | Onde | Correção proposta |
|---|---|---|---|
| E1 | **Nome da fase fixo no código.** Timer, pausa (ESC) e HUD só funcionam se a sala se chamar `tutorial_fase1`. Uma fase nova não teria pausa nem HUD | [game.gd:99](scripts/game.gd:99), [game.gd:249](scripts/game.gd:249), [game.gd:260](scripts/game.gd:260), [ui.gd:113](scripts/ui.gd:113), [level.gd:14](scripts/level.gd:14) | `level.gd` vira script base com `@export` (id, tamanho, próxima fase) e avisa o `Game` (`Game.begin_level(self)`); `Game` testa "estou numa fase", não o nome |
| E2 | **Contagem de flores frágil:** o `Game` conta as flores no 1º frame "playing", e ao reiniciar de dentro da fase pode contar a cena antiga antes da nova carregar | [game.gd:249-256](scripts/game.gd:249) | A própria fase informa o total no `_ready` (junto com E1) |
| E3 | **Pontuação pensada para uma fase só:** "TOTAL: x / 100" e estrelas usam a soma de todas as fases | [ui.gd:215-232](scripts/ui.gd:215) | Estrelas e total por fase; total geral separado |
| E4 | **Fim de fase = pegar todas as flores.** Sem saída/bandeira, flores não podem ser opcionais | [player.gd:230](scripts/player.gd:230) | Objeto "saída"; flores viram pontuação (ver decisão D4) |
| E5 | **"Tentar novamente" reinicia o jogo inteiro** (vidas, pontos, volta à 1ª fase) | [game.gd:91-99](scripts/game.gd:91) | Reiniciar a fase atual / checkpoint (ver decisão D3) |
| E6 | **Colisão só com nós `Block`.** Cada pedaço de chão é um nó posicionado à mão; os tiles são só desenho | [player.gd:59](scripts/player.gd:59), [block.gd](scripts/block.gd) | Também tratar como sólido o tile com *custom data* `solid` num `TileMapLayer`, para desenhar fases no editor do Godot |
| E7 | Código morto: `is_aiming` (botão direito), `var_flor01`; `efeito.gd` altera o recurso compartilhado `spr_brilho.tres` em tempo de execução | [player.gd:24-25](scripts/player.gd:24), [player.gd:183](scripts/player.gd:183), [efeito.gd:8](scripts/efeito.gd:8) | Remover / marcar `loop = false` no próprio `.tres` |
| E8 | HUD desenha sempre 3 corações | [ui.gd:122](scripts/ui.gd:122) | Desenhar `max_lives` (prepara vida extra) |

---

## Fases do plano

A ordem segue a regra "base sólida antes de conteúdo". Tamanho: **P** = algumas horas, **M** = 1–2 dias, **G** = vários dias.

### Fase 0 — Preparação (P)

1. ✅ Repositório git próprio para o projeto Godot: `Ep3rii/Jump-Duck-Godot` (privado).
2. `.gitignore` do Godot: ignorar a pasta `.godot/` (cache), mas versionar os arquivos `*.import`.
3. Menu de depuração só no editor (`OS.is_debug_build()`): pular fase, invencível, +1 vida, recarregar fase. Acelera todo o resto.

### Fase 1 — Correção dos bugs e base estrutural (M)

Ordem sugerida (cada item = um commit):

1. **E1 + E2** — script base de fase e `Game.begin_level()`. É o que destrava todo o resto.
2. **B3** — pausa real com `get_tree().paused`.
3. **B1** — trava do pulo após troca de estado.
4. **B2, B4** — dano sem congelar, queda zerada no pulo duplo.
5. **B6** — modo de tela.
6. **E6** — colisão por tile (mantendo os `Block` atuais funcionando).
7. **E7, E8** — limpeza.
8. Teste manual: jogar `tutorial_fase1` inteira, pausar/despausar com ESPAÇO e ESC, morrer, reiniciar, trocar modo de tela.

### Fase 2 — Sistemas: vidas, morte, combate, pontuação (M–G)

**Vidas e morte**
- `max_lives` configurável; item de vida extra (opcional).
- Checkpoints: ao morrer com vidas restantes, volta ao último checkpoint em vez de só piscar.
- Perigos que matam ou ferem: água (o `obj_blocoAgua01` do GameMaker não foi convertido), espinhos, queda.
- Fim de jogo → reiniciar a fase atual (ver D3).

**Combate (componente reutilizável)**
- `Hurtbox`/`Hitbox` simples por retângulo (mesmo estilo da colisão atual) para jogador, inimigos e chefe.
- Script base `enemy.gd`: vida, contato causa dano, pisão, animação/efeito de derrota, sinal `defeated`.
- Ataque do pato além do pisão (ver D2) — necessário para a luta final.

**Pontuação**
- Resultado e estrelas por fase; total geral da campanha.
- Recorde por fase salvo em disco (mesmo `ConfigFile` das configurações, ou `user://save.cfg`).
- Pontos por inimigo derrotado (opcional).

**Menu**
- O menu atual funciona; falta: **Continuar** (progresso salvo), **Seleção de fases** (fases desbloqueadas + estrelas), **Controles**, **Créditos**.
- Volume separado: música e efeitos (buses `Music` e `SFX`).
- Transição com fade entre cenas.

**Áudio** — efeitos de pulo, flor, dano, pisão, morte, botão de menu.

### Fase 3 — Inimigos (G)

Todos herdam `enemy.gd` da Fase 2.

| Inimigo | Comportamento proposto | Precisa |
|---|---|---|
| **Raposa** | Refatorar sobre a base; virar em parede/beirada (B5); variante mais rápida para fases intermediárias | — |
| **Jacaré** | Fica na água; sobe e morde quando o pato passa por cima. Costas como plataforma temporária quando de boca fechada; não pode ser pisado de boca aberta | Sprites (parado, abrindo boca, mordendo) + água como perigo |
| **Gavião (comum)** | Voa em padrão fixo e dá rasante na direção do pato; pode ser pisado | Sprites (voo, rasante, derrota) |
| **Gavião (chefe)** | Fase final no topo da torre: 2–3 padrões de ataque, vida em barra, fases de dificuldade | Sprites maiores + combate da Fase 2 |

> Faltam os sprites do jacaré e do gavião em `assets/`. Dá para começar com retângulos coloridos (placeholder) e trocar depois.

### Fase 4 — Mecânicas de fase (M–G)

- **Objetos arrastáveis** (`draggable.gd`): caem com gravidade, são sólidos para o pato (dá para subir neles), ativam placas de pressão. Forma de arrastar depende da decisão D1.
- **Placa de pressão + porta/plataforma** ligadas por sinal (base dos puzzles).
- **Bloco escalável** — o sprite `spr_objBEscalavel01` já existe.
- **Saída da fase** (E4) e **checkpoint**.
- **Plataforma móvel** (útil para a torre).
- Cena modelo `fase_base.tscn` (parallax, câmera, camadas de tile, jogador, HUD) para criar fases novas copiando.

### Fase 5 — Apresentação (M)

- Animações que faltam: derrota da raposa, jacaré, gavião, ataque do pato (se houver), comemoração.
- Efeitos de tela: tremor de câmera no dano, fade entre fases.
- **Cutscene final**: pato chega ao topo da torre, gavião derrotado, encontro com a amada, créditos. Feita com `AnimationPlayer` + caixa de diálogo simples; pode ser pulada.
- (Opcional) cutscene de abertura curta contando a história.

### Fase 6 — Fases

Roteiro completo em [ROTEIRO_FASES.md](ROTEIRO_FASES.md): Tutorial (fazenda/moinho), Fases 1–3 (caminho até a torre, nado, mini-chefe jacaré), Fases 4–8 (subida da torre: chaves, vento, plataformas que caem), Fase Final (gavião) e cutscene. A Fase 3 (inimigos) e a Fase 5 (cutscene) passam a ser feitas junto com as fases que as usam.

---

## Decisões (respondidas em 25/11/2026: sugestões aceitas)

| # | Pergunta | Decidido |
|---|---|---|
| D1 | Objetos arrastáveis: o **pato empurra/carrega** ou o jogador **arrasta com o mouse**? (o código tem resto de "mirar com botão direito") | Pato empurra/carrega — mantém o jogo todo no teclado/controle |
| D2 | O pato tem algum ataque além do pisão? | Pisão + arremessar objetos carregáveis na luta final (reaproveita os arrastáveis) |
| D3 | Ao perder todas as vidas: reinicia **a fase** ou **o jogo todo**? | Reinicia a fase, com vidas cheias |
| D4 | A fase termina ao **pegar todas as flores** (como hoje) ou ao **chegar na saída**? | Saída; flores viram pontuação/estrelas |

## Próximo passo

**Fase 3 (inimigos)**: jacaré e gavião herdando `enemy.gd`, começando com sprites provisórios se a arte ainda não existir. Ou, com as mecânicas prontas, conversar sobre as suas ideias de fases (Fase 6).
