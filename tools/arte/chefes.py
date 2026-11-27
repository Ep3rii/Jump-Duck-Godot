"""Chefes na pixel art quadradinha (lote 2): jacare gigante (Fase 3) e gaviao chefe (Fase final).
Tamanho: 64x64 por quadro na grade (32x32 no jogo); o jacare gigante tem 144x64 (72x32 no jogo,
bem comprido) e a tira dele tem 5 linhas, uma por estagio de dano (como todo quadro dele e uma
ampliacao 2x, o reduz2 so amostra e o QUADRO_32 do pixelkit nao atrapalha). O
gaviao chefe segue a mesma ideia: 96x96 na grade (48x48 no jogo, gordo), todas as poses desenhadas direto em
pixel do jogo e ampliadas 2x, e a tira tem 5 linhas de dano (G_NIVEIS).
Estilo: formas simples em blocos (retangulos de cantos arredondados), contorno de 1 px na cor
escura do material, cor so para detalhe (olho, dente, bochecha, estrelas).
Uso: python tools/arte/chefes.py [--salvar]   (previas em tools/arte/saida/)"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas, hexc, save_gif  # noqa: E402
from estilo import Desenho  # noqa: E402
import inimigos as ini  # noqa: E402  (mesma familia de aves: o chefe reusa a mecanica do desenho)

ROOT = os.path.dirname(os.path.dirname(HERE))
ARTE = os.path.join(ROOT, "assets", "sprites", "arte")
OUT = os.path.join(HERE, "saida")
os.makedirs(OUT, exist_ok=True)

# ---------------------------------------------------------------- paleta do jacare gigante
# Cores ja na Endesga 32 (a conversao nao escolhe nada sozinha). O chefe e desenhado direto em
# 32x32 (1 px = 1 px do jogo) e so ampliado 2x para a grade de 64: o reduz2 ve blocos 2x2 de uma
# cor so e apenas amostra, entao olho, dentes, narina e estrelas saem exatamente como aqui.
VERDE, VERDE_L, VERDE_S, VERDE_ESC = hexc("3e8948"), hexc("63c74d"), hexc("265c42"), hexc("193c3e")
BARRIGA, ESCAMA = hexc("ead4aa"), hexc("265c42")
DENTE, BOCA, BOCA_ESC = hexc("ffffff"), hexc("e43b44"), hexc("a22633")
BOCHECHA, BOCHECHA_ESC = hexc("f6757a"), hexc("a22633")
ESTRELA, OLHO, PUPILA = hexc("fee761"), hexc("fee761"), hexc("181425")
CURATIVO, CURATIVO_ESC, CURATIVO_CONT = hexc("e4a672"), hexc("b86f50"), hexc("3e2731")
CONT_ESTRELA = hexc("181425")
PINGO, PINGO_LUZ = hexc("2ce8f5"), hexc("ffffff")
JG_BARRIGA = 28  # linha da barriga no quadro de 32 (PIVO.y em scripts/jacare_chefe.gd)
JG_W = 72  # largura do quadro do jacare gigante em px do jogo (grade de 144; PIVO.x = JG_W / 2)
JG_H = 32  # altura de cada linha (estagio de dano) da tira, em px do jogo
JG_ESTAGIOS = 5  # linhas da tira: 0 = inteiro, 1..4 = golpes levados (dano acumulado, sem barra)
OLHO_ROXO, OLHO_ROXO_L = hexc("68386c"), hexc("b55088")


def _amplia2(cv):
    """Quadro desenhado em 32x32 -> grade de 64 (blocos 2x2 de uma cor so)."""
    out = Canvas(cv.w * 2, cv.h * 2)
    out.blit(cv, 0, 0, 2)
    return out


def _estrela(cv, cx, cy, cor=None, miolo=None, contorno=None):
    """Estrela de tontura em "+" de 3x3 (forma fixa), opcionalmente com contorno de 1 px."""
    cor, miolo = cor or ESTRELA, miolo or DENTE
    braco = ((0, -1), (-1, 0), (1, 0), (0, 1))
    if contorno is not None:
        for dx, dy in braco + ((0, 0),):
            for ex, ey in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                x, y = cx + dx + ex, cy + dy + ey
                if cv.inside(x, y) and cv.px[y][x] is None:
                    cv.px[y][x] = contorno
    for dx, dy in braco:
        cv.set(cx + dx, cy + dy, cor)
    cv.set(cx, cy, miolo)


def _laco(cv, x0, y0, linhas, cores, contorno):
    """Desenha um mapa de caracteres (cores = {char: cor}) e poe contorno de 1 px nas casas
    vazias em volta (nao pinta por cima do que ja esta desenhado)."""
    pts = []
    for j, r in enumerate(linhas):
        for i, ch in enumerate(r):
            if ch in cores:
                cv.set(x0 + i, y0 + j, cores[ch])
                pts.append((x0 + i, y0 + j))
    for x, y in pts:
        for ex, ey in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if cv.inside(x + ex, y + ey) and cv.px[y + ey][x + ex] is None:
                cv.px[y + ey][x + ex] = contorno


def jacare_gigante(q, dano=0):
    """64 quadros, 16 por estado: 0..15 nadando (cauda ondula, pernas remam); 16..31 saltando
    (16..23 subindo com o focinho para cima, 24..31 descendo com o focinho para baixo; boca
    aberta, patas esticadas e pingos caindo); 32..47 mordida (a boca abre aos poucos; o jogo
    escolhe pela abertura; a cabeca sobe ate 3 px junto, para a mandibula e os dentes de baixo
    ficarem acima da linha d'agua); 48..63 dor de dente (bochecha inchada com contorno, faixa de
    curativo amarrada no alto da cabeca e estrelas girando).
    Desenhado em JG_W x 32 (pixels do jogo; 72 de largura, bem mais comprido que o jacare comum
    de 32) usando o quadro inteiro: cauda longa em 4 degraus e focinho vao ate as bordas, o corpo
    tem ~20 px de altura (o comum tem 11), cabeca grande, 8 cristas de 2 px nas costas, dentes
    de 2 px.
    A barriga fica na linha B = 28 (PIVO de jacare_chefe.gd); no salto o desenho inteiro e
    inclinado em degraus de 1 px (cada coluna desce/sobe, sem girar nem borrar).
    dano (0..4) = golpes ja levados; as marcas se somam e ficam ate o fim da luta (no lugar da
    barra de vida): 1 curativo em X no lombo; 2 + um dente a menos, rachadura e crista lascada na
    cauda; 3 + olho roxo, esparadrapo na cauda e o lombo sem brilho; 4 + mais dois dentes a
    menos, cristas quebradas, o corpo todo apagado e gotas de suor na cabeca."""
    bloco, i = divmod(q, 16)
    nado, salto, mordida, dor = bloco == 0, bloco == 1, bloco == 2, bloco == 3
    subindo = salto and i < 8
    fase = 2 * math.pi * (i % 8 if salto else i) / (8.0 if salto else 16.0)
    d = Desenho(JG_W, JG_H)
    B = JG_BARRIGA
    H = JG_W - 19  # x onde comeca a cabeca (cabeca de 19 px, como antes)
    # cauda grossa e longa que afina em 4 degraus; so a ponta ondula 1 px
    o = int(round(math.sin(fase))) if (nado or salto) else 0
    d.rect(0, B - 6 + o, 7, 3, VERDE, "corpo")
    d.rect(5, B - 8, 8, 6, VERDE, "corpo")
    d.rect(11, B - 10, 8, 9, VERDE, "corpo")
    d.rect(17, B - 12, 8, 11, VERDE, "corpo")
    # corpo alto e comprido; cristas de 3x2 com o bico de 1 px (o miolo verde fica a mostra)
    d.rect(22, B - 13, H + 3 - 22, 13, VERDE, "corpo")
    d.apaga([(22, B - 13), (22, B - 1)])
    cristas = (6, 12, 18, 24, 30, 36, 42, 48)
    quebradas = (24, 36) if dano >= 4 else ()
    for cx in cristas:
        y0 = {6: B - 10, 12: B - 12, 18: B - 14}.get(cx, B - 15)
        if cx == 12 and dano >= 2:  # crista lascada: so o toco de 1 px
            d.rect(cx, y0 + 1, 2, 1, VERDE, "corpo")
            continue
        d.rect(cx, y0, 3, 2, VERDE, "corpo")
        if cx not in quebradas:
            d.rect(cx + 1, y0 - 1, 1, 1, VERDE, "corpo")
    # patas (miolo verde): nadando remam; no salto esticadas (frente para a frente, tras para
    # tras); na mordida e na dor paradas
    passo = int(round(math.cos(fase)))
    if salto:
        d.rect(16, B - 3, 7, 3, VERDE, "pata")     # pata de tras esticada para tras
        d.rect(H - 1, B - 2, 7, 3, VERDE, "pata")  # pata da frente esticada para a frente
    else:
        p = passo if nado else 0
        d.rect(24 - p, B - 2, 6, 4, VERDE, "pata")
        d.rect(H - 7 + p, B - 2, 6, 4, VERDE, "pata")
    # cabeca: cranio alto com a bossa do olho, focinho comprido ate a borda; a maxila sobe k px
    # quando a boca abre, a mandibula fica parada e a nuca liga as duas
    k = int(round(7 * i / 15.0)) if mordida else (4 if salto else 0)
    # na mordida o chefe fica com a barriga 8 px abaixo da linha d'agua: a cabeca inteira sobe
    # junto com a abertura (ate 3 px; a mandibula estica para baixo) para o labio de baixo e os
    # dentes de baixo aparecerem fora d'agua e a boca ler como bocarra, nao como caixa vermelha
    Bh = B - (min(3, k) if mordida else 0)
    d.rect(H, Bh - 15 - k, 10, 8, VERDE, "cabeca")                # cranio
    d.rect(H + 2, Bh - 17 - k, 6, 3, VERDE, "cabeca")             # bossa do olho
    d.rect(H + 9, Bh - 12 - k, JG_W - H - 9, 4, VERDE, "cabeca")  # focinho
    d.rect(JG_W - 5, Bh - 13 - k, 3, 1, VERDE, "cabeca")          # narina
    d.rect(H, Bh - 8 - k, 4, k + 2, VERDE, "cabeca")              # nuca / dobradica
    d.rect(H, Bh - 7, JG_W - H, 6 + B - Bh, VERDE, "cabeca")      # mandibula (Bh-7 .. B-2)
    # boca aberta: o vao entre maxila e mandibula fica vazio aqui (o contorno vira labio dos
    # dois lados) e e preenchido em degraus por _boca_aberta depois do contorno
    d.rect(23, B - 4, H + 1 - 23, 3, BARRIGA, None, so=["corpo"])
    d.rect(H + 1, B - 4, JG_W - H - 2, 2, BARRIGA, None, so=["cabeca"])
    d.luz("corpo", VERDE_L, dx=0, dy=2)
    d.luz("cabeca", VERDE_L, dx=0, dy=2)
    if dor:
        # bochecha inchada: bolota de cantos cortados com contorno proprio; pulsa 1 px (depois
        # da luz, para a cabeca nao ganhar faixa clara embaixo da bochecha)
        grande = i % 8 < 4
        bx0, by0, bl = (H, B - 10, 7) if grande else (H + 1, B - 9, 6)
        d.rect(bx0, by0, bl, bl, BOCHECHA, "bochecha")
        for cx, cy in ((bx0, by0), (bx0 + bl - 1, by0), (bx0, by0 + bl - 1), (bx0 + bl - 1, by0 + bl - 1)):
            d.rect(cx, cy, 1, 1, VERDE, "cabeca")
    d.contorno({"corpo": VERDE_ESC, "cabeca": VERDE_ESC, "pata": VERDE_ESC, "boca": BOCA_ESC,
                "bochecha": BOCHECHA_ESC},
               juntas=[("cabeca", "boca"), ("bochecha", "cabeca"), ("bochecha", "corpo")])
    cv = d.cv
    if k and not mordida:  # sem faixa de luz no topo da mandibula (fica dentro da boca); na
        # mordida ela fica: e o labio de baixo, a unica linha da mandibula fora d'agua
        for x in range(H + 4, JG_W):
            for y in (Bh - 6, Bh - 5):
                if cv.px[y][x] == VERDE_L:
                    cv.px[y][x] = VERDE
    for x in range(24, H + 1, 3):  # escamas mais escuras no lombo
        for y in (B - 11, B - 12):
            if cv.px[y][x] == VERDE_L:
                cv.px[y][x] = ESCAMA
    # dano acumulado (1): o brilho some do lombo e da cauda (3+) e do corpo todo (4)
    if dano >= 3:
        for y in range(JG_H):
            for x in range(JG_W if dano >= 4 else H):
                if cv.px[y][x] == VERDE_L:
                    cv.px[y][x] = VERDE
    # olho de 2x2: iris amarela atras, pupila escura na frente; sobrancelha brava em cima
    ox = H + 3
    for y in (Bh - 15 - k, Bh - 14 - k):
        cv.set(ox, y, OLHO)
        cv.set(ox + 1, y, PUPILA)
    cv.set(ox, Bh - 16 - k, VERDE_ESC)
    cv.set(ox + 1, Bh - 16 - k, VERDE_ESC)
    if dano >= 3:  # olho roxo: anel de 1 px em volta do olho (sem cobrir a sobrancelha)
        for x, y, c in ((ox - 1, Bh - 15 - k, OLHO_ROXO), (ox - 1, Bh - 14 - k, OLHO_ROXO),
                        (ox + 2, Bh - 15 - k, OLHO_ROXO), (ox + 2, Bh - 14 - k, OLHO_ROXO),
                        (ox - 1, Bh - 13 - k, OLHO_ROXO), (ox + 2, Bh - 13 - k, OLHO_ROXO),
                        (ox, Bh - 13 - k, OLHO_ROXO_L), (ox + 1, Bh - 13 - k, OLHO_ROXO_L)):
            cv.set(x, y, c)
    # dano acumulado (2): dentes que caem (1 no 2o golpe, mais 2 no 4o), dos dois jeitos da boca
    sem_dente = (H + 11,) if dano >= 2 else ()
    if dano >= 4:
        sem_dente += (H + 5, H + 17, H + 12)
    dentes_cima = tuple(x for x in (H + 5, H + 8, H + 11, H + 14, H + 17) if x not in sem_dente)
    dentes_baixo = tuple(x for x in (H + 6, H + 9, H + 12, H + 15) if x not in sem_dente)
    if k == 0:  # boca fechada: linha da boca e presas de 2 px saindo dela
        for x in range(H + 7 if dor else H + 4, JG_W - 1):
            cv.px[B - 8][x] = VERDE_ESC
        if not dor:
            for x in dentes_cima:
                cv.set(x, B - 7, DENTE)
                cv.set(x, B - 6, DENTE)
    else:  # bocarra em degraus com presas de 1 px separadas (cima na maxila, baixo na mandibula)
        _boca_aberta(cv, H, Bh, k, dentes_cima, dentes_baixo)
    if dor:
        # brilho de 1 px no alto da bochecha
        cv.set(bx0 + 2, by0 + 2, DENTE)
        # faixa de curativo de desenho animado: desce do alto do cranio ate a mandibula (por
        # cima da linha da boca, logo a frente da bochecha) e amarra num laco no alto da cabeca
        for y in range(B - 15, B - 2):
            cv.set(H + 8, y, CURATIVO)
            cv.set(H + 9, y, CURATIVO_ESC)
        _laco(cv, H + 6, B - 18, ["cc..cc", "ccxxcc", "..cx.."],
              {"c": CURATIVO, "x": CURATIVO_ESC}, CURATIVO_CONT)
        # 3 estrelas em "+" de forma fixa, com contorno, girando acima da cabeca (so a posicao muda)
        for e in range(3):
            a = fase + e * 2.094
            _estrela(cv, H + 8 + int(round(9 * math.cos(a))), 4 + int(round(2 * math.sin(a))),
                     contorno=CONT_ESTRELA)
    _marcas_dano(cv, dano, H, Bh, k, i)
    if salto:
        # pingos de agua caindo da cauda e da barriga (2-3 px, ciano com brilho branco)
        for j, (px0, py0) in enumerate(((3, B - 2), (14, B), (28, B + 1), (40, B + 1))):
            y = py0 + (i % 8 + j * 3) % 6
            if 0 <= y < JG_H - 1 and cv.px[y][px0] is None and cv.px[y + 1][px0] is None:
                cv.set(px0, y, PINGO_LUZ)
                cv.set(px0, y + 1, PINGO)
        # inclina em degraus de 1 px: subindo o focinho fica alto, descendo fica baixo (inclinacao
        # menor que a do jacare curto: as pontas sobem/descem os mesmos ~4 px)
        cv = _inclina(cv, -0.11 if subindo else 0.08, JG_W // 2)
    if dano >= 4:  # depois da inclinacao: as gotas medem o espaco no quadro ja pronto
        _suor(cv, H, i)
    return _amplia2(cv)


def _boca_aberta(cv, H, Bh, k, dentes_cima, dentes_baixo):
    """Preenche o vao da boca aberta (vazio entre o labio de cima e o de baixo, ja contornados)
    em degraus: perto da dobradica a maxila desce em escada de 1 px (verde, com o labio escuro
    embaixo de cada degrau) e o vermelho vai abrindo ate o focinho; garganta mais escura no
    fundo; a ponta fica aberta (sem tampa); presas brancas de 1 px, uma a cada 3 colunas,
    alternadas entre cima e baixo (1 px, ou 2 px com a boca bem aberta)."""
    x0 = H + 4
    for x in range(x0, JG_W):
        vao = [y for y in range(Bh - 8 - k, Bh - 7) if cv.px[y][x] is None]
        if not vao:
            continue
        n = len(vao)
        if x == JG_W - 1:  # ponta do focinho: boca aberta para fora, so os labios
            continue
        o = min(n, 1 + (x - x0))  # linhas de vermelho (abre 1 px por coluna)
        cunha = n - o
        if cunha:
            acima = vao[0] - 1
            if cv.px[acima][x] == VERDE_ESC:  # o labio antigo vira miolo da maxila
                cv.px[acima][x] = VERDE
            for y in vao[:cunha - 1]:
                cv.px[y][x] = VERDE
            cv.px[vao[cunha - 1]][x] = VERDE_ESC
        for y in vao[cunha:]:
            cv.px[y][x] = BOCA_ESC if x == x0 else BOCA
        if o < 2:
            continue
        comp = 2 if o >= 5 else 1
        if x in dentes_cima:
            for j in range(comp):
                cv.px[vao[cunha + j]][x] = DENTE
        if x in dentes_baixo:
            for j in range(comp):
                cv.px[vao[n - 1 - j]][x] = DENTE


def _suor(cv, H, i):
    """2 gotas de suor (dano 4) que pulam 1 px na nuca e na frente da cabeca, sempre inteiras
    dentro do quadro: medem o topo do desenho embaixo delas e, sem espaco, param de pular e
    encostam no contorno (nunca saem pela borda de cima). Na dor de dente as estrelas giram por
    ali: a gota anda ate 4 px para o lado para nao ficar cortada por uma estrela."""
    sob = (i // 4) % 2
    estrela = (ESTRELA, DENTE, CONT_ESTRELA)

    def gota(x, y):
        return {(x, y): PINGO, (x, y + 1): PINGO_LUZ, (x + 1, y + 1): PINGO,
                (x, y + 2): PINGO, (x + 1, y + 2): PINGO}

    def livre(pts):
        for (x, y) in pts:
            if not cv.inside(x, y) or cv.px[y][x] is not None:
                return False
            for ex, ey in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if cv.inside(x + ex, y + ey) and cv.px[y + ey][x + ex] in estrela:
                    return False
        return True

    for n, gx0 in enumerate((H - 6, H + 15)):  # a de tras fica antes do galo da nuca
        pulo = sob if n == 0 else 1 - sob
        escolha = None
        for dx in (0, -2, 2, -3, 3, -4, 4):
            gx = gx0 + dx
            cols = [x for x in (gx - 1, gx, gx + 1, gx + 2) if 0 <= x < cv.w]
            topo = min([y for x in cols for y in range(cv.h)
                        if cv.px[y][x] is not None and cv.px[y][x] not in estrela] or [cv.h])
            gy = topo - 6 + pulo if topo - 6 >= 1 else max(1, topo - 5)
            if escolha is None:
                escolha = gota(gx, gy)
            if livre(gota(gx, gy)):
                escolha = gota(gx, gy)
                break
        _remendo(cv, escolha, SUOR_CONT, por_cima=False)


SUOR_CONT = hexc("124e89")


def _remendo(cv, pts, contorno, por_cima=True):
    """Pinta pts = {(x, y): cor} e poe contorno de 1 px (vizinhos em cruz) em volta. por_cima:
    o contorno cobre o que ja esta desenhado (curativo sobre o corpo, mas so dentro da silhueta);
    senao so ocupa casas vazias (gota no ar)."""
    for (x, y), c in pts.items():
        for ex, ey in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + ex, y + ey
            if (nx, ny) in pts or not cv.inside(nx, ny):
                continue
            if (por_cima and cv.px[ny][nx] is not None) or (not por_cima and cv.px[ny][nx] is None):
                cv.px[ny][nx] = contorno
    for (x, y), c in pts.items():
        if cv.inside(x, y) and (por_cima or cv.px[y][x] is None):
            cv.px[y][x] = c


def _marcas_dano(cv, dano, H, Bh, k, i):
    """Marcas do dano acumulado do jacare gigante (somam-se a cada golpe; ver jacare_gigante)."""
    B = JG_BARRIGA
    if dano >= 1:  # curativo em cruz no lombo, com almofada escura no meio
        cx, cy = 33, B - 10
        pts = {}
        for dx in range(-3, 5):
            for dy in (0, 1):
                pts[(cx + dx, cy + dy)] = CURATIVO
        for dy in range(-2, 4):
            for dx in (0, 1):
                pts[(cx + dx, cy + dy)] = CURATIVO
        for dx in (0, 1):
            for dy in (0, 1):
                pts[(cx + dx, cy + dy)] = CURATIVO_ESC
        _remendo(cv, pts, CURATIVO_CONT)
    if dano >= 2:
        # galo rosa na nuca (atras da bossa do olho): a marca nova que se ve de longe, porque a
        # cabeca e o que fica fora d'agua; 3 linhas no maximo para caber com a boca toda aberta
        r0 = Bh - 17 - k
        galo = {(H - 1, r0): BOCHECHA, (H, r0): BOCHECHA}
        for x in range(H - 2, H + 2):
            galo[(x, r0 + 1)] = BOCHECHA
            galo[(x, r0 + 2)] = BOCHECHA
        galo[(H - 1, r0 + 1)] = DENTE  # brilho
        for (x, y) in list(galo):
            for ex, ey in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + ex, y + ey
                if (nx, ny) not in galo and cv.inside(nx, ny):
                    cv.px[ny][nx] = BOCHECHA_ESC
        for (x, y), c in galo.items():
            if cv.inside(x, y):
                cv.px[y][x] = c
        # rachadura em zigue-zague nas escamas da cauda
        for x, y in ((12, B - 10), (13, B - 9), (13, B - 8), (14, B - 7), (14, B - 6), (15, B - 5),
                     (15, B - 4)):
            if cv.px[y][x] is not None:
                cv.px[y][x] = VERDE_ESC
    if dano >= 3:  # esparadrapo atravessado na cauda
        pts = {(x, y): CURATIVO for x in range(6, 12) for y in (B - 7, B - 6)}
        pts[(8, B - 7)] = pts[(9, B - 6)] = CURATIVO_ESC
        _remendo(cv, pts, CURATIVO_CONT)
    # dano 4: gotas de suor (_suor, desenhadas por ultimo, depois da inclinacao do salto)


def _inclina(cv, s, cx):
    """Desloca cada coluna x em round((x - cx) * s) px na vertical (degraus de 1 px)."""
    out = Canvas(cv.w, cv.h)
    for x in range(cv.w):
        dy = int(round((x - cx) * s))
        for y in range(cv.h):
            c = cv.px[y][x]
            if c is not None and 0 <= y + dy < cv.h:
                out.px[y + dy][x] = c
    return out


# ---------------------------------------------------------------- gaviao chefe
# Cores ja na Endesga 32: corpo e cabeca claros (#b86f50), asa de perto #733e39, asa de longe
# #3e2731, contorno de fora #181425. Assim o chefe tem 3 planos que leem sobre a parede azul
# escura da torre.
# Desenhado DIRETO em 48x48 (1 px = 1 px do jogo) e ampliado 2x para a grade de 96: o reduz2 ve
# blocos 2x2 de uma cor so e apenas amostra (com QUADRO_32 de 64 ou de 96, tanto faz).
# Gordo e robusto: peito cheio, corpo redondo em degraus, asas largas com as penas em escada.
G_LADO = 48                    # lado do quadro em px do jogo (QUADRO em scripts/gaviao_chefe.gd)
G_PIVO = (24, 29)              # centro do corpo / origem do no (PIVO em scripts/gaviao_chefe.gd)
G_CORPO, G_ASA, G_ASA_LONGE = hexc("b86f50"), hexc("733e39"), hexc("3e2731")
G_BARRIGA, G_BICO = hexc("ead4aa"), hexc("fee761")
G_CAUDA_COR, G_CAUDA_MEIO = hexc("733e39"), hexc("be4a2f")
G_LUZ = hexc("e4a672")         # luz no alto da cabeca, das costas e na ponta das asas
G_CONT, G_CONT_DENTRO = hexc("181425"), hexc("3e2731")
G_PATA, G_PATA_CONT = hexc("feae34"), hexc("be4a2f")
G_BOCA = hexc("e43b44")
# dano acumulativo (scripts/gaviao_chefe.gd desce uma linha da tira a cada 2 golpes)
G_ROXO, G_ROXO_L = hexc("68386c"), hexc("b55088")   # olho inchado
G_PELE = hexc("e8b796")                               # pele sem pena (falha no pescoco)
# com 5+ golpes as cores ficam apagadas (mesmas rampas, tons mais cinzentos da Endesga 32)
G_APAGADO = {G_CORPO: hexc("c28569"), G_LUZ: hexc("e8b796"), G_BARRIGA: hexc("e8b796"),
             G_CAUDA_MEIO: hexc("733e39"), G_BICO: hexc("feae34")}
G_APAGADO_LEVE = {G_BARRIGA: hexc("e8b796"), G_BICO: hexc("feae34")}  # ja no 1o golpe
G_NIVEIS = 5                   # linhas da tira chefe_gaviao: 0 = inteiro ... 4 = muito machucado
# asa (u = do ombro para fora, v = para o lado da borda de tras): borda da frente reta, borda
# de tras em escada (as penas largas); com dano a escada perde degraus (penas arrancadas)
G_ASA_FRENTE = [(-3, -4), (6, -5), (14, -4), (20, -2), (23, 0), (24, 2)]
G_ASA_ESCADA = [(22, 4), (19, 4), (19, 7), (15, 7), (15, 10), (10, 10), (10, 12), (4, 12), (-1, 10), (-4, 4)]


def _vazio(cv, x, y):
    return not cv.inside(x, y) or cv.px[y][x] is None


def _escada(nivel):
    """Borda de tras da asa (penas em escada). Cada estagio de dano arranca penas novas:
    1 = tres dentes (penas faltando) na escada; 2 = a pena do meio inteira (o degrau 10..15
    recua); 4 = a ponta perde um degrau."""
    if nivel <= 0:
        return list(G_ASA_ESCADA)
    if nivel < 4:
        ponta = [(22, 4), (19, 4), (19, 7), (18, 7), (18, 4.5), (16, 4.5), (16, 7)]
    else:
        ponta = [(21, 2), (17, 2), (17, 7)]
    if nivel < 2:
        meio = [(15, 7), (15, 10), (13.5, 10), (13.5, 6.5), (11.5, 6.5), (11.5, 10), (10, 10)]
    else:
        meio = [(15, 7), (10, 7)]
    base = [(10, 12), (7.5, 12), (7.5, 8.5), (5.5, 8.5), (5.5, 12), (4, 12), (-1, 10), (-4, 4)]
    return ponta + meio + base


def _asa_pts(sx, sy, ang, k=1.0, nivel=0):
    """Poligono da asa com o ombro em (sx, sy). ang em graus: 90 = para cima, 0 = para tras,
    negativo = para baixo e para tras."""
    a = math.radians(ang)
    D = (-math.cos(a), -math.sin(a))
    N = (D[1], -D[0])
    pts = []
    for u, v in G_ASA_FRENTE + _escada(nivel):
        u, v = u * k, v * k
        pts.append((sx + u * D[0] + v * N[0], sy + u * D[1] + v * N[1]))
    return pts, D, N


def _asa_detalhe(cv, part, sx, sy, D, N, k, umax=24.0):
    """Linhas entre as penas (marrom escuro) e luz na ponta da asa."""
    for y in range(cv.h):
        for x in range(cv.w):
            if cv.part[y][x] != part or cv.px[y][x] in (G_CONT, G_CONT_DENTRO):
                continue
            rx, ry = x + 0.5 - sx, y + 0.5 - sy
            u = (rx * D[0] + ry * D[1]) / k
            v = (rx * N[0] + ry * N[1]) / k
            if u >= umax - 3.0:
                cv.px[y][x] = G_LUZ
            elif v > 3.0 and any(abs(u - c) < 0.7 for c in (10.0, 15.0, 19.0)):
                cv.px[y][x] = G_CONT_DENTRO


def _cabeca(d, hx, hy, nivel, bico_aberto=False):
    """Cabeca redonda olhando para a direita, face clara, bico em gancho. Devolve o olho."""
    d.elipse(hx, hy, 7.5, 7.0, G_CORPO, "cabeca")
    if nivel >= 1:  # topete arrepiado no alto da cabeca (cresce com o dano)
        if nivel < 3:
            spikes = [(-6, 3), (-4, 4), (-2, 3)]
        elif nivel < 4:
            spikes = [(-6, 3), (-4, 4), (-2, 3), (0, 3)]
        else:
            spikes = [(-7, 2), (-5, 4), (-3, 3), (-1, 4), (1, 2)]
        for dx, h in spikes:
            d.rect(int(hx) + dx, int(hy - 7) - h + 1, 1, h, G_CORPO, "cabeca")
    d.rect(int(hx), int(hy) + 2, 6, 4, G_BARRIGA, None, so=["cabeca"])
    bx, by = int(hx) + 7, int(hy) - 3
    if bico_aberto:
        d.poli([(bx - 1, by - 1), (bx + 3, by - 1), (bx + 5, by + 2), (bx + 5, by + 5), (bx + 3, by + 4),
                (bx - 1, by + 3)], G_BICO, "bico")
        d.rect(bx - 1, by + 6, 4, 2, G_BICO, "bico")
        d.rect(bx - 1, by + 4, 3, 2, G_BOCA, "boca")
    elif nivel < 3:
        d.poli([(bx - 1, by - 1), (bx + 3, by - 1), (bx + 5, by + 2), (bx + 5, by + 7), (bx + 3, by + 6),
                (bx + 3, by + 5), (bx - 1, by + 5)], G_BICO, "bico")
    else:  # bico lascado: o gancho da ponta quebrou
        d.poli([(bx - 1, by - 1), (bx + 3, by - 1), (bx + 5, by + 2), (bx + 5, by + 4), (bx + 4, by + 5),
                (bx - 1, by + 5)], G_BICO, "bico")
    return (int(hx) + 2, int(hy) - 3)


def _olho(cv, ex, ey, nivel):
    """Olho 2x2 (iris amarela atras, pupila escura na frente) com a sobrancelha brava. Com
    dano: olho inchado (roxo em volta, palpebra caida)."""
    if nivel >= 2:
        for y in range(ey - 2, ey + 4):
            for x in range(ex - 2, ex + 4):
                if cv.px[y][x] in (G_CORPO, G_BARRIGA, G_LUZ):
                    cv.px[y][x] = G_ROXO_L if y >= ey + 2 else G_ROXO
    cv.px[ey][ex] = cv.px[ey + 1][ex] = G_BICO
    cv.px[ey][ex + 1] = cv.px[ey + 1][ex + 1] = G_CONT
    for x, y in ((ex - 1, ey - 2), (ex, ey - 1), (ex + 1, ey - 1), (ex + 2, ey - 1)):  # sobrancelha brava
        if cv.px[y][x] is not None:
            cv.px[y][x] = G_CONT
    if nivel >= 2:  # palpebra inchada cobre a metade de cima
        cv.px[ey][ex] = cv.px[ey][ex + 1] = G_ROXO
        cv.px[ey - 1][ex + 1] = G_CONT


def _acabamento(d, juntas):
    d.contorno({"corpo": G_CONT, "cabeca": G_CONT, "asa": G_CONT, "asa_longe": G_CONT, "cauda": G_CONT,
                "bico": G_CONT, "pata": G_PATA_CONT, "boca": G_CONT}, juntas=juntas)
    cv = d.cv
    for y in range(cv.h):  # linhas de dentro no marrom escuro; so a borda de fora no mais escuro
        for x in range(cv.w):
            if cv.px[y][x] == G_CONT and not any(_vazio(cv, x + dx, y + dy)
                                                  for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                if cv.part[y][x] != "bico":
                    cv.px[y][x] = G_CONT_DENTRO
    return cv


def _apaga_cores(cv, nivel):
    """1-2 golpes: peito e bico ja perdem o brilho; 5+ golpes: todas as cores apagadas."""
    if nivel < 1:
        return
    mapa = G_APAGADO if nivel >= 3 else G_APAGADO_LEVE
    for y in range(cv.h):
        for x in range(cv.w):
            c = cv.px[y][x]
            if c in mapa:
                cv.px[y][x] = mapa[c]


def _falha(cv, pts):
    """Falha de penas: pele rosada so onde ha corpo."""
    for x, y in pts:
        if cv.inside(x, y) and cv.px[y][x] in (G_CORPO, G_LUZ, G_ASA):
            cv.px[y][x] = G_PELE


G_JUNTAS = [("asa", "corpo"), ("asa", "cabeca"), ("asa", "cauda"), ("cabeca", "corpo"), ("bico", "cabeca"),
            ("asa_longe", "corpo"), ("asa_longe", "cabeca"), ("asa_longe", "cauda"), ("cauda", "corpo"),
            ("boca", "bico")]


def _cauda_leque(d, x0, y0, nivel, compr=11):
    """Cauda em leque de 3 penas (ponta para a esquerda); com dano perde penas."""
    if nivel < 1:
        d.rect(x0 + 2, y0, compr - 2, 3, G_CAUDA_COR, "cauda")
    else:  # pena de cima arrancada: so um toco
        d.rect(x0 + 7, y0 + 1, compr - 7, 2, G_CAUDA_COR, "cauda")
    d.rect(x0, y0 + 3, compr, 3, G_CAUDA_COR, "cauda")
    if nivel < 4:
        d.rect(x0 + 2, y0 + 6, compr - 2, 3, G_CAUDA_COR, "cauda")
    else:
        d.rect(x0 + 5, y0 + 6, compr - 5, 3, G_CAUDA_COR, "cauda")


def _cauda_det(cv, x0, y0, compr=11):
    for x in range(x0, x0 + compr):
        for y, c in ((y0 + 3, G_CONT_DENTRO), (y0 + 6, G_CONT_DENTRO), (y0 + 4, G_CAUDA_MEIO)):
            if cv.part[y][x] == "cauda" and cv.px[y][x] == G_CAUDA_COR and not _vazio(cv, x - 1, y):
                cv.px[y][x] = c
    for y in range(y0, y0 + 9):  # ponta clara: o 1o miolo de cada pena
        for x in range(x0, x0 + compr):
            if cv.part[y][x] == "cauda" and cv.px[y][x] in (G_CAUDA_COR, G_CAUDA_MEIO):
                cv.px[y][x] = G_LUZ
                break


def _gira(cv, rot, cx, cy, tx=0, ty=0):
    """Gira o desenho (cores e partes, ainda sem luz nem contorno) rot graus em volta de
    (cx, cy) e desloca (tx, ty). Positivo = sentido horario (bico para baixo). Vizinho mais
    proximo: depois o contorno de 1 px e refeito em cima do resultado."""
    a = math.radians(rot)
    c, s = math.cos(a), math.sin(a)
    out = Canvas(cv.w, cv.h)
    for y in range(cv.h):
        for x in range(cv.w):
            rx, ry = x + 0.5 - cx - tx, y + 0.5 - cy - ty
            ix = int(math.floor(cx + rx * c + ry * s))
            iy = int(math.floor(cy - rx * s + ry * c))
            if 0 <= ix < cv.w and 0 <= iy < cv.h and cv.px[iy][ix] is not None:
                out.px[y][x] = cv.px[iy][ix]
                out.part[y][x] = cv.part[iy][ix]
    return out


def _cauda_det_girada(cv, volta, x0, y0, nivel):
    """_cauda_det para a pose girada: decide cada pixel pela posicao dele no desenho de origem."""
    inicio = {0: 2 if nivel < 1 else 7, 1: 0, 2: 2 if nivel < 4 else 5}  # 1a coluna de cada pena
    for y in range(cv.h):
        for x in range(cv.w):
            if cv.part[y][x] != "cauda" or cv.px[y][x] != G_CAUDA_COR:
                continue
            ox, oy = volta(x + 0.5, y + 0.5)
            r = int(math.floor(oy)) - y0
            if r in (3, 6):
                cv.px[y][x] = G_CONT_DENTRO
            elif 0 <= r <= 8 and ox - x0 < inicio[r // 3] + 2.2:
                cv.px[y][x] = G_LUZ
            elif r == 4:
                cv.px[y][x] = G_CAUDA_MEIO


def _olho_x(cv, ex, ey, nivel):
    """Olho em X (atordoado); com dano o roxo em volta continua."""
    if nivel >= 2:
        for y in range(ey - 2, ey + 4):
            for x in range(ex - 2, ex + 4):
                if cv.inside(x, y) and cv.px[y][x] in (G_CORPO, G_BARRIGA, G_LUZ):
                    cv.px[y][x] = G_ROXO_L if y >= ey + 2 else G_ROXO
    for x, y in ((ex - 1, ey - 1), (ex + 2, ey - 1), (ex, ey), (ex + 1, ey), (ex, ey + 1), (ex + 1, ey + 1),
                 (ex - 1, ey + 2), (ex + 2, ey + 2)):
        if cv.inside(x, y):
            cv.px[y][x] = G_CONT


def _gaviao_pose(nivel, ang, dy=0, dx=0, grito=False, bico_aberto=None, k_asa=1.0, ang_longe=None,
                 k_longe=0.85, patas="recolhidas", cabeca=(35, 18), rot=0.0, giro=(0, 0), chao=None,
                 tonto=False):
    """Todas as poses saem do MESMO corpo redondo e gordo do voo (peito cheio, silhueta em
    degraus), so mudando asa, cabeca, patas e o giro do corpo inteiro (mergulho e investida).
    ang = angulo da asa (graus: 90 = para cima, 0 = para tras, negativo = para baixo).
    rot = giro do corpo em volta de G_PIVO (positivo = bico para baixo); chao = linha a partir da
    qual tudo e cortado (deitado no chao, a barriga achata)."""
    d = Desenho(G_LADO, G_LADO)
    sx, sy = 21 + dx, 23 + dy
    # asa de longe (atras de tudo): a mesma asa, menor, 4 px a frente e 2 acima, atrasada
    pl, _, _ = _asa_pts(sx + 4, sy - 2, ang + 8 if ang_longe is None else ang_longe, k_longe, nivel)
    d.poli(pl, G_ASA_LONGE, "asa_longe")
    _cauda_leque(d, 0 + dx, 21 + dy, nivel, compr=14)
    # corpo gordo e peito cheio
    d.elipse(22 + dx, 28 + dy, 13.0, 10.0, G_CORPO, "corpo")
    d.elipse(28 + dx, 30 + dy, 8.0, 7.0, G_CORPO, "corpo")
    d.elipse(28 + dx, 32 + dy, 7.0, 5.5, G_BARRIGA, None, so=["corpo"])
    if nivel >= 3 and abs(rot) <= 10:  # penas do peito arrepiadas (no mergulho girado viram fiapos soltos)
        for px_, h in ((22, 2), (26, 3), (31, 2)):
            d.rect(px_ + dx, 38 + dy, 1, h, G_BARRIGA, "corpo")
    if patas == "recolhidas":  # sob a barriga
        d.rect(23 + dx, 37 + dy, 4, 3, G_PATA, "pata")
        d.rect(29 + dx, 37 + dy, 4, 3, G_PATA, "pata")
    elif patas == "garras":  # esticadas para a frente, garras abertas
        for lx in (29, 34):
            d.rect(lx + dx, 36 + dy, 2, 2, G_PATA, "pata")
            d.rect(lx + dx, 37 + dy, 4, 2, G_PATA, "pata")
    hx, hy = cabeca[0] + dx, cabeca[1] + dy - (2 if grito else 0)
    ex, ey = _cabeca(d, hx, hy, nivel, bico_aberto=grito if bico_aberto is None else bico_aberto)
    # asa de perto por cima do corpo
    pn, Dn, Nn = _asa_pts(sx, sy, ang, k_asa, nivel)
    d.poli(pn, G_ASA, "asa")
    a = math.radians(rot)
    c, s = math.cos(a), math.sin(a)
    cx, cy = G_PIVO
    girado = rot != 0 or tuple(giro) != (0, 0)

    def ida(x, y):  # ponto do desenho de origem -> ponto do quadro
        rx, ry = x - cx, y - cy
        return cx + rx * c - ry * s + giro[0], cy + rx * s + ry * c + giro[1]

    def volta(x, y):  # ponto do quadro -> ponto do desenho de origem
        rx, ry = x - cx - giro[0], y - cy - giro[1]
        return cx + rx * c + ry * s, cy - rx * s + ry * c

    def px_ida(x, y):
        fx, fy = ida(x + 0.5, y + 0.5)
        return int(math.floor(fx)), int(math.floor(fy))

    if girado:
        d.cv = _gira(d.cv, rot, cx, cy, giro[0], giro[1])
    if chao is not None:
        d.apaga([(x, y) for y in range(chao, G_LADO) for x in range(G_LADO)])
    d.luz("cabeca", G_LUZ, dx=0, dy=2)
    d.luz("corpo", G_LUZ, dx=0, dy=2)
    cv = _acabamento(d, G_JUNTAS)
    s2 = ida(sx, sy)
    vet = lambda v: (v[0] * c - v[1] * s, v[0] * s + v[1] * c)  # noqa: E731
    _asa_detalhe(cv, "asa", s2[0], s2[1], vet(Dn), vet(Nn), k_asa, 24.0 if nivel < 4 else 22.0)
    if girado:
        _cauda_det_girada(cv, volta, 0 + dx, 21 + dy, nivel)
    else:
        _cauda_det(cv, 0 + dx, 21 + dy, 14)
    # marquinhas do peito (barrado)
    for x, y in ((25, 31), (26, 31), (30, 33), (31, 33), (26, 35), (27, 35)):
        qx, qy = px_ida(x + dx, y + dy)
        if cv.inside(qx, qy) and cv.px[qy][qx] == G_BARRIGA:
            cv.px[qy][qx] = G_LUZ
    ox, oy = px_ida(ex, ey)
    if tonto:
        _olho_x(cv, ox, oy, nivel)
    else:
        _olho(cv, ox, oy, nivel)
    if nivel >= 4:
        _falha(cv, [px_ida(x + dx, y + dy) for x, y in ((30, 22), (31, 22), (29, 23), (30, 23), (31, 23))])
    _apaga_cores(cv, nivel)
    return cv


def _gaviao_voo(ang, dy, nivel, grito=False, dx=0, cabeca=(35, 18)):
    """Pose de voo (ou grito) em 48x48. ang = angulo da asa (graus)."""
    return _gaviao_pose(nivel, ang, dy=dy, dx=dx, grito=grito, cabeca=cabeca)


# mergulho: a asa fecha por etapas (aberta no alto -> colada nas costas) e o corpo vai
# inclinando ate a diagonal; 12..15 = asa fechada, so as pontas tremendo com o vento (o jogo
# toca 0..11 uma vez no comeco do mergulho e repete 12..15)
G_MERG_ASA = [64, 58, 51, 44, 37, 30, 24, 18, 13, 9, 6, 4, 4, 7, 3, 6]
G_MERG_ROT = [18, 21, 24, 27, 30, 33, 36, 39, 41, 43, 44, 45, 45, 46, 45, 46]


def _gaviao_mergulho(i, nivel):
    t = min(i, 11) / 11.0
    treme = (0, 1, 1, 0)[i % 4] if i >= 12 else 0
    return _gaviao_pose(nivel, G_MERG_ASA[i], k_asa=1.0 - 0.2 * t, k_longe=0.85 - 0.13 * t,
                        patas="nenhuma", rot=G_MERG_ROT[i], giro=(-2, -2 + treme))


def _gaviao_investida(i, nivel):
    """Rasante rente ao chao: o corpo gordo um pouco inclinado para a frente, asas batendo curto
    e rapido (2 batidas em 16 quadros), o corpo avancando e recuando ate 3 px no ciclo e as
    garras esticadas a frente. A linha mais baixa (garras) fica em G_PIVO[1] + 8: na investida o
    centro anda em chao - 9."""
    ang = 26 + 30 * math.cos(2 * math.pi * i / 8.0)
    avanco = (0, 0, 1, 2, 3, 3, 2, 1)[i // 2] - 1  # 1 avanco por ciclo de 16 (2 batidas)
    cv = _gaviao_pose(nivel, ang, dx=avanco, patas="garras", rot=8, k_longe=0.8)
    fundo = max((y for y in range(cv.h) for x in range(cv.w) if cv.px[y][x] is not None
                 and cv.part[y][x] == "pata"), default=G_PIVO[1] + 8)
    return ini._desloca(cv, 0, G_PIVO[1] + 8 - fundo)


def _gaviao_atordoado(ang0, nivel, i=0):
    """Caido de brucos no chao: o mesmo corpo redondo, achatado embaixo pelo piso, a cabeca
    deitada com olho em X, a asa de perto largada no chao, a de longe mole nas costas, o peito
    respirando (sobe e desce 1 px) e 3 estrelas em "+" girando acima da cabeca (ang0)."""
    resp = (0, 0, 1, 1)[(i // 2) % 4]
    ang = -12 + 3 * math.sin(2 * math.pi * i / 16.0)
    cv = _gaviao_pose(nivel, ang, dy=7 + resp, k_asa=0.9, ang_longe=14 + 4 * math.sin(2 * math.pi * i / 16.0 + 1.0),
                      k_longe=0.75, patas="nenhuma", cabeca=(36, 18 + (1 - resp)), rot=4, chao=41,
                      tonto=True, bico_aberto=(i // 4) % 2 == 1)
    for k in range(3):
        a = ang0 + k * 2.094
        _estrela(cv, 35 + int(round(9 * math.cos(a))), 10 + int(round(4.4 * math.sin(a))), contorno=G_CONT)
    return cv


def gaviao(q, nivel=0):
    """80 quadros de 48x48 (grade de 96), 16 por estado: 0..15 voo; 16..31 grito (asa no
    alto batendo, bico aberto, cabeca e corpo tremendo); 32..47 mergulho (0..11 a asa fecha
    por etapas, 12..15 repetem); 48..63 investida (asas batendo, corpo avancando); 64..79
    atordoado. Todas as poses usam o mesmo corpo gordo do voo (_gaviao_pose).
    nivel = dano acumulado (0 = inteiro ... 4 = muito machucado), cada estagio soma algo novo:
    1 topete arrepiado, tres penas faltando na asa, pena de cima da cauda arrancada, peito e
    bico sem brilho; 2 olho roxo inchado e a pena do meio da asa arrancada; 3 todas as cores
    apagadas, peito arrepiado e bico lascado; 4 ponta da asa e cauda depenadas, topete maior e
    falha de pele no pescoco."""
    bloco, i = divmod(q, 16)
    if bloco == 0:
        ang = 18 + 54 * math.cos(2 * math.pi * i / 16.0)
        dy = int(round(math.cos(2 * math.pi * (i - 3) / 16.0)))
        cv = _gaviao_voo(ang, dy, nivel)
    elif bloco == 1:
        ang = 58 + 16 * math.cos(2 * math.pi * i * 3 / 16.0)
        cv = _gaviao_voo(ang, (0, 0, -1, -1)[(i // 4) % 4], nivel, grito=True,
                         dx=(0, 1, 0, -1)[(i // 2) % 4], cabeca=(35, 18 - (i % 2)))
    elif bloco == 2:
        cv = _gaviao_mergulho(i, nivel)
    elif bloco == 3:
        cv = _gaviao_investida(i, nivel)
    else:
        cv = _gaviao_atordoado(i * 2 * math.pi / 16.0, nivel, i)
    return _amplia2(cv)


def tira_gaviao():
    """Tira do gaviao chefe: 80 quadros de 48x48 lado a lado em G_NIVEIS linhas, uma por estagio
    de dano (linha 0 = inteiro). O jogo desce uma linha a cada 2 golpes levados."""
    linhas = [tira([gaviao(i, nivel) for i in range(80)]) for nivel in range(G_NIVEIS)]
    cv = Canvas(linhas[0].w, linhas[0].h * G_NIVEIS)
    for j, ln in enumerate(linhas):
        cv.blit(ln, 0, j * ln.h)
    return cv


# ---------------------------------------------------------------- saida
def tira(quadros):
    w = quadros[0].w  # 64 (gaviao) ou 96 (jacare gigante) na grade
    cv = Canvas(w * len(quadros), quadros[0].h)
    for i, q in enumerate(quadros):
        cv.blit(q, i * w, 0)
    return cv


def tira_jacare():
    """Tira do jacare gigante: 64 quadros lado a lado (16 por estado) em JG_ESTAGIOS linhas, uma
    por golpe levado (linha 0 = inteiro). O jogo escolhe a linha por max_hp - hp."""
    linhas = [tira([jacare_gigante(i, dano) for i in range(64)]) for dano in range(JG_ESTAGIOS)]
    cv = Canvas(linhas[0].w, linhas[0].h * JG_ESTAGIOS)
    for j, ln in enumerate(linhas):
        cv.blit(ln, 0, j * ln.h)
    return cv


def pecas():
    return {
        "chefe_jacare": [tira_jacare()],  # 1 Canvas ja montado: 64 quadros x 5 linhas de dano
        "chefe_gaviao": [tira_gaviao()],  # 1 Canvas ja montado: 80 quadros 48x48 x 5 linhas de dano
    }


def main():
    p = pecas()
    for nome, qs in p.items():
        t = tira(qs)
        big = Canvas(t.w * 2, t.h * 2)
        big.blit(t, 0, 0, 2)
        big.save(os.path.join(OUT, "%s.png" % nome))
    if "--salvar" in sys.argv:
        for nome, qs in p.items():
            tira(qs).save(os.path.join(ARTE, nome + ".png"))
        print("salvo:", ", ".join(sorted(p)))
    print("ok")


if __name__ == "__main__":
    main()
