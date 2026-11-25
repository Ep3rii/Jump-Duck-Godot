# Jump Duck — Roteiro de fases

Montado a partir das ideias da conversa de 25/11/2026. Complementa o [PLANO.md](PLANO.md) (Fase 6).

**Estrutura:** Tutorial → Fases 1 a 8 → Fase Final (chefe) → cutscene no topo da torre.
São 10 fases jogáveis + 1 cutscene.

## Regras de design combinadas

- **Inimigos como obstáculos:** cada inimigo fica num ponto de passagem onde atrapalha a jornada
  (não é só enfeite no caminho). O primeiro aparece perto do fim do tutorial, como última lição.
- **Puzzles inteligentes, ligados ao cenário:** empurrar algo para alcançar uma parte mais alta,
  ou para destravar uma porta. Nada de puzzle "solto" sem motivo na fase.
- **Cada mecânica nova é apresentada com segurança antes de ser cobrada com perigo.**

## As fases

| Fase | Onde | Mecânicas | Inimigos | Situação |
|---|---|---|---|---|
| **Tutorial** | Fazenda, saindo de perto do moinho | andar, pulo, pulo duplo, flores, queda; no fim, a primeira raposa | raposa (perto do fim) | ✅ jogável: o layout atual já termina com a raposa. Falta o tema fazenda/moinho |
| **Fase 1** | Caminho até a torre | primeiro puzzle de empurrar caixa para subir | raposas | ✅ dá para montar só com o que já existe |
| **Fase 2** | Caminho até a torre (lago) | **nadar** (novo), caixas | jacarés? (ver P2) | precisa: nado, jacaré |
| **Fase 3** | Caminho até a torre (lago) | nadar | **mini-chefe jacaré** | precisa: nado, mini-chefe |
| **Fase 4** | Torre (subida 1/6) | **chaves** (novo), cipó, placas | ver P3 | precisa: chave e porta trancada |
| **Fase 5** | Torre (subida 2/6) | chaves, puzzles com caixa | ver P3 | precisa: chave |
| **Fase 6** | Torre (subida 3/6) | **vento** e **plataformas que caem** (novos) | ver P3 | precisa: vento, plataforma que cai |
| **Fase 7** | Torre (subida 4/6) | vento, plataformas que caem | ver P3 | idem |
| **Fase 8** | Torre (subida 5/6) | vento, plataformas que caem, chaves | ver P3 | idem |
| **Fase Final** | Última sala antes do topo (subida 6/6) | luta contra o **gavião**: mergulhos em padrão; depois da sequência ele bate na parede e fica vulnerável; caixas arremessadas também acertam | gavião (chefe) | precisa: chefe |
| **Cutscene** | Topo da torre | encontro com a amada | — | precisa: sistema de cutscene, arte |

## Mecânicas e conteúdo novos

| O quê | Para | Esboço | Tamanho |
|---|---|---|---|
| Nado | Fases 2 e 3 | área de água "nadável" (diferente do perigo): gravidade menor, pulo vira braçada; ver P1 | M |
| Jacaré (inimigo) | Fases 2 e 3 | herda `enemy.gd`; vive na água; ver P2 | M |
| Mini-chefe jacaré | Fase 3 | padrão de ataque + janela de vulnerabilidade; barra de vida | G |
| Chave + porta trancada | Fases 4, 5 e 8 | chave é um item (aparece no HUD); a `porta.gd` ganha o modo "trancada", que abre gastando uma chave | P |
| Vento | Fases 6 a 8 | área que empurra o pato (e caixas) numa direção, com ou sem rajadas | P–M |
| Plataforma que cai | Fases 6 a 8 | treme ao ser pisada, cai depois de um tempo e volta depois de alguns segundos | P |
| Gavião (chefe) | Final | mergulhos em sequência → bate na parede → atordoado (vulnerável); caixas arremessadas acertam | G |
| Câmera vertical | Fases 4 a Final | as fases da torre são "para cima": conferir o enquadramento (hoje a câmera olha 50 px acima do pato) | P |
| Cutscene | Final | sequência roteirizada (`AnimationPlayer`) + caixa de diálogo; dá para pular | M |
| Arte | todas | moinho e fazenda, lago, interior da torre, jacaré, gavião, amada, chave, animação de nado | — |

## Ordem sugerida: construir fase por fase

Cada fase vira uma entrega jogável, com a mecânica dela feita logo antes:

1. **Fase 1**: só mecânicas que já existem. Serve para validar o processo (montar, testar, ajustar a dificuldade).
2. **Nado + jacaré → Fase 2**, e depois **mini-chefe → Fase 3**.
3. **Chaves → Fases 4 e 5**.
4. **Vento + plataformas que caem → Fases 6, 7 e 8**.
5. **Gavião → Fase Final**, e depois **cutscene**.
6. **Tutorial com tema de fazenda e moinho** (quando houver arte), ajuste geral de dificuldade e de pontuação.

## Perguntas em aberto

| # | Pergunta | Por que importa |
|---|---|---|
| P1 | **Nado:** o pato boia na superfície e mergulha (como um pato de verdade) ou nada livre debaixo d'água? Tem limite de fôlego? | Muda a física e o desenho das fases 2 e 3 |
| P2 | **Jacaré:** aparece como inimigo comum nas fases 2 e 3, ou só como mini-chefe? Como o mini-chefe ataca e como é derrotado? | Define quantos comportamentos programar |
| P3 | **Inimigos na torre (fases 4 a 8):** há gaviões menores, raposas, outra coisa? Ou a torre é mais puzzle e plataforma? | O resumo só cita gavião, raposa e jacaré |
| P4 | **Chefe gavião:** quantos acertos para vencer? Atordoado, ele pode ser pisado, ou só as caixas acertam? Fica mais agressivo com menos vida? | Define a luta final |
| P5 | **Cutscene:** o que acontece no topo (só o encontro? o gavião foge ou cai?) e qual a duração? | Define o sistema e a arte necessária |
| P6 | **Arte:** você vai desenhar os sprites novos (vi o Aseprite instalado)? Enquanto isso, sigo com desenhos provisórios em código | Define se a programação espera a arte ou não |
| P7 | **Tutorial:** mantém o layout atual (vindo do GameMaker) e só troca a decoração, ou refaz pensando no moinho? | O layout atual já termina com a raposa |
