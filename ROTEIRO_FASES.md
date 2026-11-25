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
| **Fase 4** | Torre (subida 1/6) | **chaves** (novo), cipó, placas | aves de rapina | chave, porta trancada, aves |
| **Fase 5** | Torre (subida 2/6) | chaves, puzzles com caixa | aves de rapina | chave, aves |
| **Fase 6** | Torre (subida 3/6) | **vento** e **plataformas que caem** (novos) | aves de rapina | vento, plataforma que cai |
| **Fase 7** | Torre (subida 4/6) | vento, plataformas que caem | aves de rapina | idem |
| **Fase 8** | Torre (subida 5/6) | vento, plataformas que caem, chaves | aves de rapina | idem |
| **Fase Final** | Última sala antes do topo (subida 6/6) | luta contra o gavião em 2 etapas | **gavião (chefe)** | chefe |
| **Cutscene** | Topo da torre | o pato encontra a **Pata** e os dois olham o pôr do sol | — | cutscene, arte |

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

### Aves de rapina (Fases 4 a 8)
Inimigos voadores da família do gavião. Proposta de dois tipos, para variar:
- **Gaviãozinho:** voa num trajeto fixo e dá um **rasante** quando o pato passa embaixo. Pode ser pisado.
- **Águia:** circula alto e **mergulha em diagonal** em direção ao pato, depois sobe de volta. Pode ser pisada e atingida por caixas.

### Chave e porta trancada (Fases 4, 5 e 8)
- A chave é um item; as chaves que o pato carrega aparecem no HUD.
- A `porta.gd` ganha o modo "trancada": encostar com uma chave abre e gasta a chave.

### Vento e plataformas que caem (Fases 6 a 8)
- **Vento:** área que empurra o pato (e as caixas) numa direção, constante ou em rajadas, com partículas mostrando a direção.
- **Plataforma que cai:** treme ao ser pisada, cai depois de um tempo e volta alguns segundos depois.

### Chefe gavião (Fase Final)
- Ataca em **sequências de mergulhos**. No fim da sequência **bate na parede da torre e fica atordoado**.
- Atordoado, pode ser atingido **das duas formas**: pisão ou caixa arremessada.
- **Etapa 1:** 5 acertos. **Etapa 2:** mais 5 acertos, com ele mais agressivo
  (*proposta:* mergulhos mais rápidos e mais mergulhos por sequência).
- Só 2 etapas. Barra de vida no HUD durante a luta.

### Cutscene final
- No topo da torre, o pato encontra a **Pata**; os dois olham o pôr do sol. Termina nos créditos.
- Pode ser pulada. Precisa de: sprite da Pata, fundo de pôr do sol.

## Arte: sugestão

**Como fazer:** você desenha no Aseprite, que já está instalado, no mesmo estilo dos sprites atuais.
Enquanto a arte não chega, eu sigo com desenhos provisórios em código (como a caixa e as bandeiras),
então a programação não fica esperando. Quando um sprite ficar pronto, é só me avisar: eu ligo ele
no jogo e apago o provisório.

**Padrão para exportar (igual ao que o jogo já usa):**
- PNG em **tira horizontal** (todos os quadros lado a lado), fundo transparente, em `assets/sprites/`.
- Mesma grade dos atuais: tiles de **16x16**, tileset de **64x64** (4x4 tiles), pato e aves de **32x32**,
  bichos grandes de **64x64**.
- Paleta: a mesma do jogo (verdes do HUD, amarelo, contorno escuro).
- Para cada sprite, anote **quantos quadros** e o **FPS**; o resto eu configuro (origem, animações).

**O que desenhar, na ordem em que as fases vão precisar:**

| Para | Sprite | Tamanho | Quadros |
|---|---|---|---|
| Tutorial | moinho (pás girando) | ~64x96 | 4 |
| Tutorial | celeiro, cerca, feno (decoração) | livre | 1 |
| Tutorial | fardo de feno (substitui a caixa na fazenda) | 16x16 | 1 |
| Tutorial | tileset da fazenda (terra, grama, cerca) | 64x64 | — |
| Fase 1 | caixa de madeira (substitui a provisória) | 16x16 | 1 |
| Fases 2–3 | pato nadando (boiando / mergulhando) | 32x32 | 2–4 cada |
| Fases 2–3 | bolhas do fôlego (HUD) | 8x8 | 1–2 |
| Fases 2–3 | jacaré comum (nadando, mordendo) | 64x32 | 4 + 3 |
| Fase 3 | jacaré mini-chefe (nadando, saltando, mordendo, dor de dente) | ~96x48 | 4 + 2 + 3 + 2 |
| Fases 4–8 | tileset de pedra da torre | 64x64 | — |
| Fases 4–8 | chave (brilhando) | 16x16 | 2–4 |
| Fases 4–8 | porta trancada (com fechadura) | 16x48 | 1 |
| Fases 4–8 | gaviãozinho (voo, rasante) | 32x32 | 4 + 2 |
| Fases 4–8 | águia (voo, mergulho) | 32x32 ou 48x48 | 4 + 2 |
| Fases 6–8 | plataforma que cai (normal, rachada) | 16x16 | 2 |
| Final | gavião chefe (voo, mergulho, batida na parede, atordoado, dano) | 64x64 | 4 + 2 + 1 + 3 + 2 |
| Cutscene | Pata (parada, andando) | 32x32 | 3 + 4 |
| Cutscene | céu de pôr do sol e sol grande (fundo) | 320x180 | 1 |
| Geral | pato escalando o cipó | 32x32 | 2 |

**Alternativa:** pacotes de pixel art prontos (itch.io etc.) aceleram, mas como o jogo tem licença
proprietária, só servem pacotes com licença que permita uso comercial. Confira a licença de cada um.

## Ordem de construção

Cada fase vira uma entrega jogável, com a mecânica dela feita logo antes:

1. **Tutorial novo** (fazenda/moinho, com arte provisória) e **Fase 1**: os dois só usam mecânicas que já existem.
2. **Nado + jacaré comum → Fase 2**, e depois **mini-chefe jacaré → Fase 3**.
3. **Chave + aves de rapina → Fases 4 e 5**.
4. **Vento + plataformas que caem → Fases 6, 7 e 8**.
5. **Chefe gavião → Fase Final**, e depois **cutscene com a Pata**.
6. Trocar a arte provisória pela definitiva conforme ela for ficando pronta; ajuste geral de dificuldade e de pontuação.

## Ainda para confirmar

| # | Pergunta |
|---|---|
| C1 | ✅ Sem fôlego: perde 1 coração e volta à superfície (ou ao checkpoint, se houver parede em cima). |
| C2 | ✅ Jacaré comum: pode ser pisado na superfície; mergulhado, não. |
| C3 | "5 hits em cada mini-boss": existe outro mini-chefe além do jacaré, ou é só ele? (por enquanto, só ele) |
| C4 | Aves da torre: gaviãozinho e águia, como proposto acima, servem? |
