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
- TileSet de pedra (`assets/tilesets/pedra_solida.tres`, arte `tileset_pedra.png`) e fundo
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

**Estado (26/11/2026):** toda a arte do jogo é nova, em pixel art quadradinha ("plana crocante":
geometria simples, contorno de 1 px na cor escura do material, cor só para detalhe). Nenhum sprite
do GameMaker é usado mais. O que continua desenhado em código, de propósito, são efeitos e
interface: partículas, bolhas, estrelinhas de tontura, sombras, luz, o céu em faixas, o balão de
texto das dicas, os painéis do menu e as guias que só aparecem no editor.

### Tamanhos (definidos em 25/11/2026)

O jogo continua do mesmo tamanho na tela; os desenhos novos só têm mais detalhe. A regra é uma só:
**2 pixels do desenho = 1 pixel do jogo** (`Sprites.ART_SCALE` em `scripts/sprites.gd`), e os
arquivos são gravados em **1:1** (1 pixel do arquivo = 1 pixel do desenho; o jogo amplia sozinho).
Até 25/11/2026 parte da arte era gravada ampliada 4x (quadros de 128); foi convertida para 1:1 para
dar para editar à mão pixel por pixel, sem mudar nada na tela.

| Tipo | Tamanho do arquivo | Tamanho no jogo |
|---|---|---|
| **Blocos e texturas** (chão, parede, caixa, pedra que cai, cipó, água) | **32x32** por bloco | 1 bloco (16 px) |
| **Entidades pequenas** (pato, Pata, flor, chave, coração) | **32x32** por quadro | 1 bloco: o tamanho do pato |
| **Inimigos comuns** (raposa, jacaré, gaviãozinho, águia) | quadro do tamanho do bicho (ex.: raposa 46x34) | um pouco maiores que o pato |
| **Mini-chefes e chefes** (jacaré gigante, gavião) | **64x64** por quadro | 2 blocos (32 px) |
| Objetos mais altos que um bloco (bandeiras, porta) | 32 de largura x altura em blocos (ex.: porta de 3 blocos = 32x96) | conforme o objeto |
| **Cenário grande** (moinho, celeiro, árvore, cerca, arbusto) | conforme o desenho | ver "Escala" abaixo |
| **Fundos** (montanhas, colinas, nuvens, torre ao longe, parede da torre) | tiras de 1024 px que emendam nas pontas | repetem a cada 512 px |

Os inimigos comuns foram reduzidos para o tamanho do pato e os chefes para 2 blocos (colisões e
testes já ajustados), então os desenhos novos encaixam sem mexer nas fases.

### Categoria de arte: pixel art plana "crocante"

Definida a partir do pato e do tileset originais (25/11/2026). Vale para todos os sprites novos.

| Regra | Como é |
|---|---|
| **Grade** | 32 px de desenho por bloco (o dobro do original, que tem 16), gravados em 1:1. Chefes: grade de 64. Nada de meio pixel, rotação ou escala quebrada. |
| **Contorno** | 1 pixel, contínuo, seguindo só as bordas (sem pixel sobrando nos cantos de dentro), numa cor escura do próprio material, nunca preto puro: cinza `#636363` no pato, verde-escuro suave `#1d6b22` na borda do terreno. |
| **Preenchimento** | Cor chapada, mais no máximo 1 ou 2 tons de sombra onde o volume dobra (barriga do pato `#e2e2e2`, base da terra `#d89d40` / `#99692c`). Sem degradê, sem pontilhado, sem suavização e sem textura de ruído. |
| **Paleta** | Viva e limpa, como a original: branco `#ffffff`, amarelo `#ffff00` / `#fff200`, verdes `#31dc31` `#2ecf2e` `#28b228` `#2ba024`, terra `#e59f43` `#d89d40`, flores brancas com miolo laranja `#f28b57`. Poucas cores por sprite (o pato usa 5). |
| **Formas** | Silhuetas simples e fáceis de ler, degraus de pixel limpos (sem pixel solto), cantos arredondados por 1 ou 2 pixels. Detalhe mínimo: o olho é um ponto 2x2, sem pupila nem brilho. |
| **Luz** | Vem de cima e da **esquerda** (o sol fica à esquerda no céu): tom claro em cima/esquerda, tom de sombra embaixo/direita. Sombra projetada cai para baixo e para a direita. |
| **Escala** | O pato é pequeno e o cenário é grande. Régua: 1 pato = 32 px da grade (16 no jogo). Cerca 1,5 pato; arbusto 1,5; árvore jovem 4; árvore 7; celeiro 6,5 de altura por 9,5 de largura; moinho 7,5 (10 com as pás); torre ao longe de 4 a 8,5. Nada de cenário menor que o pato perto do chão do jogo. |
| **Distância** | Quanto mais longe, mais claro e azulado, sem contorno (ou com contorno suave) e com menos detalhe. Só o plano do jogo usa as cores vivas inteiras. |
| **Blocos** | Faixa de grama com franja de folhas em dentes e florzinhas; terra lisa em duas faixas; borda de 1 px verde-escura; cantos arredondados nas pontas e na base das plataformas. Tudo se repete a cada 8 ou 16 px para emendar sem costura. |
| **Animação** | Poucos quadros (3 a 6), com movimentos de 1 a 2 pixels: pés e cabeça mexem, o corpo quase não. |

Sem acessórios no pato e sem tema medieval: o estilo é o do original, só que com mais detalhe.

**A base está em código:** `tools/arte/estilo.py` tem a paleta, o contorno de 1 px, os tons de luz
e sombra (luz da esquerda) e a cor "de longe". Todo sprite novo (cenário, fundos, inimigos, itens,
chefes) é desenhado com ela, para sair igual ao pato e ao tileset.

### Cenário, parallax, luz e sombra (aprovados em 25/11/2026)

- **Cenário na escala do pato** (`tools/arte/cenario.py` → `assets/sprites/arte/cenario/`): moinho
  (corpo + 8 quadros das pás, sem girar pixel), celeiro, árvore e árvore jovem (tronco + copa que
  balança meio pixel), arbusto e cerca (ponta esquerda, meio, ponta direita). `decoracao.gd` usa
  essa arte; placa de saída, junco e pilar ainda são desenhados em código.
- **Parallax** (`tools/arte/fundos.py` → `assets/sprites/arte/fundo/`, desenhado por `parallax.gd`):
  céu em 5 faixas chapadas, sol (ou lua e estrelas), nuvens de longe, montanhas, nuvens de perto,
  torre do gavião, colinas de longe, pássaros e colinas de perto. Cada camada anda numa velocidade
  na horizontal e na vertical. A torre cresce de fase em fase (longe → média → perto).
  Por dentro da torre: parede de tijolos, janelas com o céu da hora, tochas animadas, estandartes
  e colunas numa camada mais à frente.
- **Hora do dia** (`hora` no nó Parallax de cada fase): A Fazenda de manhã, O Caminho de dia,
  O Lago à tarde, O Jacaré Gigante ao entardecer; torre 1 e 2 com o entardecer nas janelas e
  torre 3 em diante de noite.
- **Luz** (`luz.gd`): uma película que multiplica a cena pela luz ambiente da hora e abre
  clareiras em faixas chapadas em volta de tochas, janelas, chave, saída e do pato (só no escuro
  da torre). De dia fica desligada.
- **Sombra** (`sombras.gd`): sombra no chão embaixo do pato, dos inimigos, caixas e itens (encolhe
  e desliza para a direita conforme sobem) e faixa de sombra deitada à direita de árvores, moinho,
  celeiro e arbustos.
- O lago ganhou um fundo opaco: os morros do parallax apareciam "dentro" d'água.

### Arte nova aprovada e já no jogo

| Sprite | Arquivo | Observação |
|---|---|---|
| Pato parado | `assets/sprites/arte/pato_parado.png` | o original ampliado com contorno de 1 px; pés com a linha entre eles de 1 px (sem contorno dobrado) |
| Pato correndo | `assets/sprites/arte/pato_correndo.png` | 8 quadros a 16 por segundo: corpo do parado subindo e descendo a cada passo, pés gordinhos (o de trás um pouco mais escuro), só o olho da frente e uma linha só de contorno entre os pés |
| Pato pulando, no ápice e caindo | `pato_pulando.png` (4 quadros, 8/s), `pato_apice.png` (2, 6/s), `pato_caindo.png` (6, 8/s) | subindo: pés encolhendo, sem asa; ápice: transição em que a asa pequena bate e os pés começam a descer; caindo: pernas penduradas e asa batendo. A asa se separa do corpo por cores leves (sombra `#e2e2e2` embaixo, tom `#f0f0f0` na parte de baixo dela), com contorno escuro só na borda de fora. |
| Pato levando dano e morrendo | `pato_dano.png` (4 quadros, 12/s), `pato_morte.png` (4, 8/s) | dano: olhos fechados de dor, piscando vermelho e rosa; morte: de barriga para cima, cinza, olhos em X, pés mexendo (o pulinho é da física do jogo). Com isso, todas as animações do pato usam a arte nova |
| Tileset de grama | `assets/sprites/arte/tileset_grama.png` (4x9 blocos de 32) | os 16 blocos originais ampliados com todas as bordas finas (1 px) e suaves (`#1d6b22`), mais 20 novos: 4 variações do topo (sem flores, flores amarelas, pedrinha, cogumelo), 4 da terra (pedrinhas, raiz, camada, pontinhos), canto interno dos dois lados, coluna de 1 bloco (topo, meio, base), teto de terra (esq., meio, dir.), bloquinho sozinho, tronco (esq., meio, dir.) e ponte. O jogo escolhe sozinho o bloco de cada célula (`Level._retile_grass`), com as variações pela posição; tronco e ponte são colocados à mão (linha 8 do tileset) |
| Tileset de pedra da torre | `assets/sprites/arte/tileset_pedra.png` (4x9 blocos de 32, `tools/arte/pedra.py`) | alvenaria medieval escura e suja: pedras de tamanhos diferentes, capa de pedras no topo, manchas de umidade, musgo, rachaduras e tijolo faltando. Mesmos 36 blocos e índices do tileset de grama, então o auto-tile do jogo serve para os dois; a linha 8 tem uma laje solta de meio bloco |
| Flor, estrela, chave, caixa e feno | `flor.png` (4 quadros), `estrela.png` (cheia, vazia), `chave.png`, `caixa.png`, `feno.png` em `assets/sprites/arte/` (`tools/arte/itens.py`) | flor e estrela são as originais com o dobro de detalhe e contorno de 1 px (a flor perdeu o brilhinho solto); chave, caixa e feno são os desenhos que o jogo fazia em código, no dobro. O coração continua sendo o original, que já estava na grade |
| Inimigos comuns | `raposa.png` (6 quadros de trote), `jacare.png` (4 nadando + 2 de mordida), `gaviaozinho.png` (6 de voo + 1 de rasante), `aguia.png` (6 de voo + 1 de mergulho) em `assets/sprites/arte/` (`tools/arte/inimigos.py`) | simples como o pato e um pouco maiores que ele (águia bem maior); aves quadradas com asas em degraus que seguem a batida, pernas recolhidas no voo; raposa com as quatro pernas de coxa e meia escura; jacaré verde-água com quatro pernas, cauda ondulando e dentes presos às mandíbulas. Revisados depois de uma avaliação com 20 agentes. A máscara de colisão continua do tamanho da do pato |
| Coração, água e bloco | `coracao.png` (cheio, vazio), `agua.png` (4 quadros), `bloco.png` (`tools/arte/lote_base.py`) | coração em degraus de 2 px (HUD e vida extra); água com espuma que anda; bloco de terra com grama para paredes e chão escondido |
| Chefes | `chefe_jacare.png` (11 quadros de 64x64: nadando, saltando, mordida em 3 aberturas, dor de dente), `chefe_gaviao.png` (13 quadros: voo, grito, mergulho, investida, atordoado) (`tools/arte/chefes.py`) | 2 blocos no jogo (32 px); o gavião usa a mesma construção das aves comuns; a cor de raiva da etapa 2 e o piscar do aviso vêm do código (tinta por cima da arte) |
| Cutscene | `pata.png` (11 quadros: parada, andando, feliz), `ninho.png` (`tools/arte/cutscene_arte.py`) | a Pata é o pato aprovado com laço rosa, cílios e bochecha; topo da torre montado com o tileset de pedra; sol, montanhas e nuvens dos fundos; corações com a arte do HUD |
| Objetos | `porta.png`, `placa.png`, `saida.png`, `checkpoint.png`, `cipo.png`, `pedra_cai.png`, `vento.png`, `dica.png`, `seta.png`, `junco.png`, `brilho.png` (`tools/arte/objetos.py`) | porta em peças (topo, meio, base) com fechadura por cima; placa de pressão solta/apertada; bandeiras tremulando; cipó em trechos; pedra inteira/rachada; lufadas de vento; placas de madeira; juncos; brilho de coletar. O pilar dos lagos usa o tileset de pedra |
| Fonte | `assets/sprites/arte/fonte.png` + `scripts/fonte_meta.gd` (gerados por `tools/arte/fonte.py`) | maiúsculas de 7 px, traço grosso e arredondado, largura proporcional; acentos em cima da letra inteira (a letra acentuada tem o mesmo tamanho das outras). Usada em todos os textos (`scripts/pixel_font.gd`) |

Os geradores estão em `tools/arte/` (Python, sem dependências): `estilo.py` (a base de estilo),
`pato.py` (animações do pato), `tileset.py` e `tileset_novos.py` (tileset de grama),
`tileset_cena.py` (cena de prévia), `cenario.py` (cenário na escala do pato), `fundos.py` (camadas
do parallax), `pedra.py` (tileset de pedra), `itens.py`, `inimigos.py`, `lote_base.py`, `chefes.py`,
`cutscene_arte.py`, `objetos.py` e `gif_jogo.py` (GIFs a partir de quadros gravados por
`tests/gif_fundo.tscn`). Cada sprite novo só entra
no jogo depois de aprovado; o pé do pato fica apoiado sobre a borda do chão (o contorno de baixo
do pato é desenhado por cima da borda do terreno).

### Menus e textos (25/11/2026)

- **Menu inicial:** cenário vivo (chão do tileset novo, moinho, árvore, o pato novo passeando e
  pulando quando a seleção muda), título grande e 4 botões: JOGAR (ou CONTINUAR, com progresso
  salvo), FASES, OPÇÕES e SAIR. Recomeçar do zero: FASES → A FAZENDA. CRÉDITOS e CONTROLES
  ficam em OPÇÕES.
- **Botões e painéis:** arredondados, com sombra; o selecionado fica amarelo com uma florzinha
  pulando ao lado. Vale para pausa, fase concluída, fim de jogo, fases e opções.
- **Nomes das fases** na lista: A FAZENDA (tutorial), O CAMINHO, O LAGO, O JACARÉ GIGANTE,
  A PORTA DA TORRE, A ÁGUIA, VENTO FORTE, O POÇO ALTO, QUASE NO TOPO, O GAVIÃO.
- **Textos reescritos:** mais curtos e diretos, em tom amigável (dicas das placas, controles,
  opções, resultado da fase, fim de jogo e créditos).

### Editar a arte à mão (ajuste fino)

Toda a arte nova fica em `assets/sprites/arte/` como **PNG em 1:1** e pode ser aberta em qualquer
editor de pixel art (Aseprite, LibreSprite, Piskel; no Photoshop/GIMP use interpolação "vizinho mais
próximo"). Salvou, o Godot reimporta sozinho e o jogo já mostra a mudança.

1. **Não mude o tamanho do arquivo nem a ordem dos quadros.** As tiras são quadros lado a lado do
   mesmo tamanho (pato: 32x32; raposa: 46x34, 6 quadros; jacaré: 64x28, 6; gaviãozinho: 46x38, 7;
   águia: 62x52, 7; flor: 32x32, 4). Os tilesets têm 4x9 blocos de 32 em posições fixas (o jogo
   escolhe cada bloco pela posição no arquivo). Pintar dentro de cada quadro pode à vontade.
2. **Fundo transparente e cores cheias:** nada de pixel meio transparente, suavização ou pincel
   macio (vira borda borrada no jogo).
3. **Os geradores não apagam o que você editou.** Os scripts de `tools/arte/` (com `--salvar`)
   gravam a arte, mas guardam a impressão de cada arquivo que gravaram em `tools/arte/gerados.json`.
   Se o PNG foi mexido depois, o gerador avisa `PROTEGIDO: ... foi editado à mão` e não sobrescreve.
   Para trocar de propósito pela versão do gerador (perdendo a edição), rode com `--forcar`.
   Sem `--salvar`, os geradores só fazem prévias em `tools/arte/saida/`.
4. Se mudar a pose a ponto de mexer onde os pés ou o centro ficam, me avise: a origem de cada
   sprite (o ponto que encosta no chão) está no código (`ART_ORIGIN` / `PIVO`).

Os sprites originais do GameMaker que os geradores usam como referência ficam em
`tools/arte/originais/`.

### Padrão para exportar
- PNG em **tira horizontal** (todos os quadros lado a lado), fundo transparente, em 1:1, em
  `assets/sprites/arte/`.
- O personagem deve **ocupar o quadro**, com uma folga pequena (1 ou 2 px) nas bordas.
- **Origem:** para quem anda no chão, o meio da base (os pés); para quem voa ou nada, o centro.
- **Tileset:** 128x288 (4x9 blocos de 32), na mesma ordem do `tileset_grama.png`.
- Para cada sprite, anote **quantos quadros** e o **FPS**; o resto eu configuro (origem, animações).
- O jogo amplia a arte com filtro "vizinho mais próximo": os pixels ficam nítidos em qualquer
  resolução.

### O que desenhar, na ordem em que as fases vão precisar

Tudo desta lista já tem arte nova (26/11/2026), menos o **pato escalando o cipó** e o **pato
nadando**, que ainda reaproveitam quadros do pulo e da queda. A tabela fica como referência de
tamanhos e quadros.

| Para | Sprite | Tamanho | Quadros |
|---|---|---|---|
| Geral | pato (parado, correndo, pulando, caindo, dano, morte) | 32x32 | 4 + 6 + 1 + 1 + 2 + 4 |
| Geral | pato escalando o cipó | 32x32 | 2 |
| Geral | flor, coração (vida extra) | 32x32 | 4 / 1 |
| Geral | bandeira de checkpoint (apagada, acesa) e bandeira de saída | 32x64 / 32x96 | 1–2 / 2–4 |
| Tutorial | tileset da fazenda (terra, grama) | 128x288 | — |
| Tutorial | moinho (pás girando) | conforme o desenho | 8 |
| Tutorial | celeiro, cerca, árvore, arbusto, junco (decoração) | conforme o desenho | 1 |
| Tutorial | fardo de feno | 32x32 | 1 |
| Tutorial e Fase 1 | raposa (andando) | 32x32 | 4–6 |
| Fase 1 | caixa de madeira | 32x32 | 1 |
| Fase 1 | placa de pressão (solta, apertada) e porta (fechada, com fechadura) | 32x32 / 32x96 | 2 / 2 |
| Fases 2–3 | pato nadando (boiando / mergulhando) | 32x32 | 2–4 cada |
| Fases 2–3 | água (superfície e fundo, animada) | 32x32 | 4 |
| Fases 2–3 | jacaré comum (nadando, mordendo) | 32x32 | 4 + 3 |
| Fase 3 | jacaré gigante (nadando, saltando, mordendo, dor de dente) | 64x64 | 4 + 2 + 3 + 2 |
| Fases 4–8 | tileset de pedra da torre | 128x288 | — |
| Fases 4–8 | fundo: parede de tijolos com janelas e tochas | 128x128 | 1 (+ tochas 3) |
| Fases 4–8 | chave (brilhando) | 32x32 | 2–4 |
| Fases 4–8 | gaviãozinho (voo, grito, rasante) | 32x32 | 4 + 1 + 2 |
| Fases 4–8 | águia (voo, grito, mergulho, bico preso) | 32x32 | 4 + 1 + 2 + 2 |
| Fases 6–8 | pedra que cai (inteira, rachada) | 32x32 | 2 |
| Fases 6–8 | vento (listras) | 32x32 | 3–4 |
| Final | gavião chefe (voo, grito, mergulho, investida, atordoado, dano) | 64x64 | 4 + 2 + 2 + 2 + 3 |
| Cutscene | Pata (parada, andando, pulinho) | 32x32 | 3 + 4 + 2 |
| Cutscene | céu de pôr do sol com sol e montanhas, topo da torre, ninho | 1024 de largura / 32x32 | 1 |

**Alternativa:** pacotes de pixel art prontos (itch.io etc.) aceleram, mas como o jogo tem licença
proprietária, só servem pacotes com licença que permita uso comercial. Confira a licença de cada um.

## Ambientação e conteúdo

### Feito em 25/11/2026
- **Câmera** um pouco mais afastada: mostra 384x216 do mundo (20% a mais que antes).
- **Partículas:** poeira ao correr, pular e pousar; anel de ar no pulo duplo; respingos ao cair na
  água e bolhas mergulhado; penas, pelo ou respingos ao derrotar inimigos; pedrinhas quando a pedra
  rachada cai ou o gavião bate na parede; brilho na chave, no checkpoint e na porta destrancada.
- **Vida no cenário** (montada sozinha em cada fase): tufos de grama, florzinhas e pedrinhas no
  chão, borboletas e folhas caindo das árvores (fazenda), libélulas (lago), musgo, entulho, teias,
  musgo pendurado e poeira flutuando na luz (torre). Pássaros distantes no céu, brilho das tochas e
  feixes de luz das janelas, brilhos e raios de luz na água.
- **Animações com mais quadros:** pato estica no pulo e achata no pouso; bandeira do checkpoint sobe
  e tremula ao ativar; chave girando; coração batendo; folhas do cipó, árvores, arbustos e juncos
  balançando; aves com 4 poses de asa; jacaré piscando, balançando a cauda e soltando bolhas; Pata
  andando em 4 quadros, piscando e batendo as asas de alegria (e do tamanho do pato).
- **Posições corrigidas:** paredes no meio dos lagos viraram pilares de pedra com musgo (antes eram
  colunas de terra com grama no topo); placas, juncos, árvore, cerca e arbusto que se sobrepunham
  foram afastados; a moldura fora da sala não aparece mais com a câmera afastada.

### Assets que faltam
- **Arte:** pato escalando o cipó e pato nadando (hoje reaproveitam o pulo e a queda); se
  quiser, quadros de piscar e de olhinho feliz para a Pata.
- **Música:** só existe uma (Grasslands), tocando no jogo inteiro. Faltam: menu, fazenda, lago,
  torre, luta contra chefe (jacaré e gavião) e a música do final/créditos.
- **Efeitos sonoros:** os atuais são sintetizados em código (provisórios). O ideal é ter sons
  gravados ou compostos para pulo, flor, pisão, dano, água, vento, gavião, portas etc.
- **Som ambiente:** pássaros e vento na fazenda, água no lago, eco e goteiras na torre.
- **Interface:** logo do título, ícone de cada fase na seleção de fases, molduras dos menus.

### Ideias para mais conteúdo (para decidir)
- **Pena dourada secreta** em cada fase (em áreas escondidas, atrás de paredes falsas), liberando
  um extra (chapéu para o pato, galeria de artes ou uma cena a mais).
- **Medalha por tempo** em cada fase (contra-relógio).
- **Hora do dia:** manhã na fazenda, tarde no lago, anoitecendo na torre (combina com o pôr do sol
  do final).
- **Clima:** chuvinha no lago, folhas voando nas fases de vento.
- **Bichos amigos** dando dicas no lugar de algumas placas (um sapo no lago, uma coruja na torre).
- **Mais inimigos:** cobra na fazenda, corvo na torre (da família das aves de rapina, como pediu o roteiro).

## Ordem de construção

Cada fase vira uma entrega jogável, com a mecânica dela feita logo antes:

1. ✅ **Tutorial novo** (fazenda/moinho, com arte provisória) e **Fase 1**: os dois só usam mecânicas que já existem.
2. ✅ **Nado + jacaré comum → Fase 2**, e depois **mini-chefe jacaré → Fase 3**.
3. ✅ **Chave + aves de rapina → Fases 4 e 5**.
4. ✅ **Vento + plataformas que caem → Fases 6, 7 e 8**.
5. ✅ **Chefe gavião → Fase Final**, e depois **cutscene com a Pata**.
6. ✅ Arte provisória trocada pela definitiva (26/11/2026). Falta o ajuste geral de dificuldade e de pontuação.

## Ainda para confirmar

| # | Pergunta |
|---|---|
| C1 | ✅ Sem fôlego: perde 1 coração e volta à superfície (ou ao checkpoint, se houver parede em cima). |
| C2 | ✅ Jacaré comum: pode ser pisado na superfície; mergulhado, não. |
| C3 | "5 hits em cada mini-boss": existe outro mini-chefe além do jacaré, ou é só ele? (por enquanto, só ele) |
| C4 | Aves da torre: gaviãozinho e águia (feitos nas Fases 4 e 5) servem? |
