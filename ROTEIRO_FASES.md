# Jump Duck — Roteiro de fases

Montado a partir das ideias e respostas da conversa de 25/11/2026. Complementa o
[PLANO.md](PLANO.md) (Fase 6).

**Estrutura:** Tutorial → Fases 1 a 8 → Fase Final (chefe) → cutscene no topo da torre.
São 10 fases jogáveis + 1 cutscene.

## Regras de design combinadas

- **Inimigos como obstáculos:** cada inimigo fica num ponto de passagem onde atrapalha a jornada
  (não é só enfeite no caminho). O primeiro aparece perto do fim do tutorial, como última lição.
- **Puzzles inteligentes, ligados ao cenário:** empurrar algo para alcançar uma parte mais alta,
  ou para destravar uma porta. Nada de puzzle "solto" sem motivo na fase.
- **Cada mecânica nova é apresentada com segurança antes de ser cobrada com perigo.**
- **Chefes e mini-chefes:** 5 acertos por chefe (ou por etapa de chefe).

## As fases

| Fase | Onde | Mecânicas | Inimigos | Precisa de |
|---|---|---|---|---|
| **Tutorial** | Fazenda, saindo de perto do moinho | andar, pulo, pulo duplo, flores, queda; empurrar um fardo de feno (a "caixa" da fazenda); no fim, a primeira raposa | raposa (perto do fim) | ✅ jogável (`scenes/tutorial.tscn`); falta a arte definitiva |
| **Fase 1** | Caminho até a torre | caixa empurrada do ressalto para subir, placa + porta, arremesso, plataforma móvel | raposas | ✅ jogável (`scenes/fase1.tscn`); falta a arte definitiva |
| **Fase 2** | Caminho até a torre (lago) | **nadar** (novo), caixa que boia, mergulho por baixo de parede | jacarés comuns | ✅ jogável (`scenes/fase2.tscn`); falta a arte definitiva |
| **Fase 3** | Caminho até a torre (lago) | nadar, túnel submerso, arena com plataformas | jacarés + **mini-chefe jacaré** | ✅ jogável (`scenes/fase3.tscn`); falta a arte definitiva |
| **Fase 4** | Torre (subida 1/6) | **chaves** (novo), cipó, placas | gaviãozinho | ✅ jogável (`scenes/fase4.tscn`); falta a arte definitiva |
| **Fase 5** | Torre (subida 2/6) | chaves, puzzles com caixa | águia + gaviãozinho | ✅ jogável (`scenes/fase5.tscn`); falta a arte definitiva |
| **Fase 6** | Torre (subida 3/6) | **vento** e **plataformas que caem** (novos) | gaviãozinho | ✅ jogável (`scenes/fase6.tscn`); falta a arte definitiva |
| **Fase 7** | Torre (subida 4/6) | vento, plataformas que caem | gaviãozinho + águia | ✅ jogável (`scenes/fase7.tscn`); falta a arte definitiva |
| **Fase 8** | Torre (subida 5/6) | vento, plataformas que caem, chaves | gaviãozinho + águia | ✅ jogável (`scenes/fase8.tscn`); falta a arte definitiva |
| **Fase Final** | Última sala antes do topo (subida 6/6) | luta contra o gavião em 2 etapas | **gavião (chefe)** | ✅ jogável (`scenes/fase_final.tscn`); falta a arte definitiva |
| **Cutscene** | Topo da torre | o pato encontra a **Pata** e os dois olham o pôr do sol | — | ✅ pronta (`scenes/cutscene_final.tscn`); falta a arte definitiva |

## Como cada coisa nova funciona (decidido)

### Nado (Fases 2 e 3)
- O pato **boia na superfície** e anda nadando de um lado para o outro.
- **BAIXO mergulha**; debaixo d'água ele nada nas 4 direções e sobe sozinho ao soltar.
- **Fôlego limitado** debaixo d'água, mostrado no HUD (bolhas). Na superfície o fôlego volta.
- *Proposta (confirmar):* sem fôlego, o pato perde 1 coração e volta à superfície com o fôlego cheio.
- Água nadável é diferente da água-perigo (`perigo.tscn`), que continua existindo para outros lugares.

### Jacaré comum (Fases 2 e 3)
- Inimigo da água, herda `enemy.gd`.
- *Proposta (confirmar):* patrulha nadando; morde quem passa perto. Pode ser pisado quando está
  com a cabeça fora d'água; encostar nele machuca.

### Mini-chefe jacaré (Fase 3)
- De tempos em tempos **salta da água e ataca as plataformas** (onde o pato está).
- Quando fica na superfície, dá **uma mordida forte** e depois fica um tempo parado
  **"com dor de dente"**. É a janela para pisar na cabeça dele.
- **5 pisões** para vencer.

### Aves de rapina (Fases 4 a 8) — feito
Inimigos voadores da família do gavião, em dois tipos:
- **Gaviãozinho** (`gaviaozinho.gd`): voa num trajeto fixo. Ao ver o pato abaixo e um pouco à frente,
  grita, para no ar e dá um **rasante** em arco cujo ponto mais baixo é onde o pato estava no grito
  (correr depois do grito escapa). 1 golpe (pisão ou caixa).
- **Águia** (`aguia.gd`): circula no alto, grita e treme, e **mergulha em diagonal** em linha reta
  até onde o pato estava. Se bate no chão ou na parede, fica com o **bico preso** um tempo (a hora
  de pisar); depois sobe de volta. 2 golpes (pisão ou caixa).
- Nenhuma das duas mergulha através de paredes: só ataca com o caminho livre.

### Chave e porta trancada (Fases 4, 5 e 8) — feito
- A chave (`chave.gd`) é um item; as chaves no bolso aparecem no HUD, embaixo dos corações.
- `porta.gd` tem o modo `trancada`: encostar com uma chave abre (para sempre) e gasta a chave; sem
  chave, toca o som de "negado". Porta trancada ignora placas.

### Interior da torre (Fases 4 a 8)
- TileSet de pedra provisório (`assets/tilesets/pedra_solida.tres`, gerado em código) e fundo
  `cenario` = "Torre por dentro" na paralaxe (tijolos, janelas com céu e tochas).
- Fases verticais: andares ligados por cipós, o pato sobe de baixo para cima.

### Vento e plataformas que caem (Fases 6 a 8) — feito
- **Vento** (`vento.gd`): área com listras que empurra o pato (e as caixas paradas) para a direita
  ou para a esquerda, constante ou em **rajadas** (as listras voltam um pouco antes de cada rajada,
  avisando). A direção **Cima** é uma corrente de ar que levanta o pato até o andar de cima
  (substitui o cipó em alguns lugares; dentro dela cair não machuca).
- **Plataforma que cai** (`plataforma_cai.gd`, pedra rachada): treme meio segundo ao ser pisada,
  despenca e volta 3 segundos depois (só se o lugar estiver livre).

### Chefe gavião (Fase Final) — feito (`gaviao_chefe.gd`)
- Ataca em **sequências de mergulhos**. No fim da sequência **bate na parede da torre e fica atordoado**.
- Atordoado, pode ser atingido **das duas formas**: pisão ou caixa arremessada.
- **Etapa 1:** 5 acertos. **Etapa 2:** mais 5 acertos, com ele mais agressivo
  (*proposta:* mergulhos mais rápidos e mais mergulhos por sequência).
- Só 2 etapas. Barra de vida no HUD durante a luta.
- Como ficou: cada sequência tem 3 mergulhos (5 na etapa 2) e termina com uma **investida** rente
  ao chão de uma parede à outra; a batida na parede deixa ele atordoado. Atordoado, aceita até
  2 golpes e levanta voo. Na troca de etapa ele fica vermelho e deixa cair um coração. A arena
  tem o tamanho exato da tela, com dois ressaltos (fogem da investida) e uma caixa em cada um.

### Cutscene final — feito (`cutscene.gd`)
- No topo da torre, o pato encontra a **Pata**; os dois olham o pôr do sol. Termina nos créditos.
- Pode ser pulada. Precisa de: sprite da Pata, fundo de pôr do sol.
- Como ficou (~22 s): o pato chega correndo, a Pata vê ele do ninho e pula (coraçãozinho), vem
  andando até ele (coração grande), os dois se viram para o sol que se põe atrás das montanhas,
  o céu escurece com estrelas, "JUNTOS, ENFIM." e "FIM". Depois os créditos com "OBRIGADO POR
  JOGAR!". Entra pelo botão VER O FINAL da tela de vitória da Fase Final.

## Arte

**Como fazer:** você desenha no Aseprite, em **pixel art detalhada**. Enquanto a arte não chega,
o jogo usa desenhos provisórios em código. Quando um sprite ficar pronto, é só me avisar: eu ligo
ele no jogo e apago o provisório.

### Tamanhos (definidos em 25/11/2026)

O jogo continua do mesmo tamanho na tela; os desenhos novos só têm mais detalhe. A regra é uma só:
**8 pixels do desenho = 1 pixel do jogo** (`Sprites.ART_SCALE` em `scripts/sprites.gd`).

| Tipo | Tamanho do desenho | Tamanho no jogo |
|---|---|---|
| **Blocos e texturas** (chão, parede, caixa, pedra que cai, cipó, água) | **128x128** por bloco | 1 bloco (16 px) |
| **Entidades pequenas** (pato, Pata, raposa, jacaré comum, gaviãozinho, águia, flor, chave, coração) | **128x128** por quadro | 1 bloco: o tamanho do pato |
| **Mini-chefes e chefes** (jacaré gigante, gavião) | **256x256** por quadro | 2 blocos (32 px) |
| Objetos mais altos que um bloco (bandeiras, porta) | 128 de largura x altura em blocos (ex.: porta de 3 blocos = 128x384) | conforme o objeto |
| Decoração (moinho, celeiro, árvore, cerca) | múltiplos de 128 | conforme o desenho |
| Fundos (céu, montanhas, parede da torre, pôr do sol) | 2560x1440 (a tela inteira) ou 2560 de largura | a tela (320x180) |

Os inimigos comuns foram reduzidos para o tamanho do pato e os chefes para 2 blocos (colisões e
testes já ajustados), então os desenhos novos encaixam sem mexer nas fases.

### Padrão para exportar
- PNG em **tira horizontal** (todos os quadros lado a lado), fundo transparente, em `assets/sprites/`.
- O personagem deve **ocupar o quadro**, com uma folga pequena (uns 4 a 8 px do desenho) nas bordas:
  o quadro de 128 corresponde à área de colisão.
- **Origem:** para quem anda no chão, o meio da base (os pés); para quem voa ou nada, o centro.
- **Tileset:** 512x512 (4x4 blocos de 128), na mesma grade do `spr_tileSetGrama01` atual: linha 2 =
  topo do chão grosso (esquerda, meio, direita) + plataforma de 1 bloco; linha 3 = plataforma fina
  (esquerda, meio, direita); linha 4 = interior (esquerda, meio, direita).
- Paleta: a mesma do jogo (verdes do HUD, amarelo, contorno escuro). Sem suavização nas bordas (pixel art).
- Para cada sprite, anote **quantos quadros** e o **FPS**; o resto eu configuro (origem, animações, mipmaps).
- O jogo reduz a arte 8x com filtro suave para não picotar os pixels. Ela aparece perfeitamente
  nítida com a janela em 2560x1440; em 1920x1080 fica levemente suavizada.

### O que desenhar, na ordem em que as fases vão precisar

| Para | Sprite | Tamanho | Quadros |
|---|---|---|---|
| Geral | pato (parado, correndo, pulando, caindo, dano, morte) | 128x128 | 4 + 6 + 1 + 1 + 2 + 4 |
| Geral | pato escalando o cipó | 128x128 | 2 |
| Geral | flor, coração (vida extra) | 128x128 | 4 / 1 |
| Geral | bandeira de checkpoint (apagada, acesa) e bandeira de saída | 128x256 / 128x384 | 1–2 / 2–4 |
| Tutorial | tileset da fazenda (terra, grama) | 512x512 | — |
| Tutorial | moinho (pás girando) | ~512x768 | 4 |
| Tutorial | celeiro, cerca, árvore, arbusto, junco (decoração) | múltiplos de 128 | 1 |
| Tutorial | fardo de feno | 128x128 | 1 |
| Tutorial e Fase 1 | raposa (andando) | 128x128 | 4–6 |
| Fase 1 | caixa de madeira | 128x128 | 1 |
| Fase 1 | placa de pressão (solta, apertada) e porta (fechada, com fechadura) | 128x128 / 128x384 | 2 / 2 |
| Fases 2–3 | pato nadando (boiando / mergulhando) | 128x128 | 2–4 cada |
| Fases 2–3 | água (superfície e fundo, animada) | 128x128 | 4 |
| Fases 2–3 | jacaré comum (nadando, mordendo) | 128x128 | 4 + 3 |
| Fase 3 | jacaré gigante (nadando, saltando, mordendo, dor de dente) | 256x256 | 4 + 2 + 3 + 2 |
| Fases 4–8 | tileset de pedra da torre | 512x512 | — |
| Fases 4–8 | fundo: parede de tijolos com janelas e tochas | 2560x1440 | 1 (+ tochas 2–4) |
| Fases 4–8 | chave (brilhando) | 128x128 | 2–4 |
| Fases 4–8 | gaviãozinho (voo, grito, rasante) | 128x128 | 4 + 1 + 2 |
| Fases 4–8 | águia (voo, grito, mergulho, bico preso) | 128x128 | 4 + 1 + 2 + 2 |
| Fases 6–8 | pedra que cai (inteira, rachada) | 128x128 | 2 |
| Fases 6–8 | vento (listras) | 128x128 | 3–4 |
| Final | gavião chefe (voo, grito, mergulho, investida, atordoado, dano) | 256x256 | 4 + 2 + 2 + 2 + 3 + 2 |
| Cutscene | Pata (parada, andando, pulinho) | 128x128 | 3 + 4 + 2 |
| Cutscene | céu de pôr do sol com sol e montanhas, topo da torre, ninho | 2560x1440 / 128x128 | 1 |

**Alternativa:** pacotes de pixel art prontos (itch.io etc.) aceleram, mas como o jogo tem licença
proprietária, só servem pacotes com licença que permita uso comercial. Confira a licença de cada um.

## Ordem de construção

Cada fase vira uma entrega jogável, com a mecânica dela feita logo antes:

1. ✅ **Tutorial novo** (fazenda/moinho, com arte provisória) e **Fase 1**: os dois só usam mecânicas que já existem.
2. ✅ **Nado + jacaré comum → Fase 2**, e depois **mini-chefe jacaré → Fase 3**.
3. ✅ **Chave + aves de rapina → Fases 4 e 5**.
4. ✅ **Vento + plataformas que caem → Fases 6, 7 e 8**.
5. ✅ **Chefe gavião → Fase Final**, e depois **cutscene com a Pata**.
6. Trocar a arte provisória pela definitiva conforme ela for ficando pronta; ajuste geral de dificuldade e de pontuação.

## Ainda para confirmar

| # | Pergunta |
|---|---|
| C1 | ✅ Sem fôlego: perde 1 coração e volta à superfície (ou ao checkpoint, se houver parede em cima). |
| C2 | ✅ Jacaré comum: pode ser pisado na superfície; mergulhado, não. |
| C3 | "5 hits em cada mini-boss": existe outro mini-chefe além do jacaré, ou é só ele? (por enquanto, só ele) |
| C4 | Aves da torre: gaviãozinho e águia (feitos nas Fases 4 e 5) servem? |
