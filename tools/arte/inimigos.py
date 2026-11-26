"""Inimigos comuns em pixel art 16x16 (Endesga 32), 16 quadros por animacao:
  - raposa e jacare: desenhados direto em pixels do jogo (mapa fixo + pernas/cauda/boca em
    codigo) e ampliados 2x, para o reduz2 so amostrar (nada some no contorno refeito);
  - gaviaozinho e aguia: ave() desenha na grade de 32 (o gaviao chefe, em chefes.py, usa a
    mesma ave()); depois em16() faz a reducao aqui mesmo e _retoque_ave() redesenha a mao, no
    tamanho do jogo, bico, patas, olho, luz de cima e juntas internas; o mergulho e o bico
    preso da aguia sao desenhados direto em pixels do jogo (aguia_mergulho, aguia_presa).
Grade: 2 px do desenho = 1 px do jogo. Gravados em assets/sprites/arte/ (com --salvar).
Uso: python tools/arte/inimigos.py [--salvar]   (previas em tools/arte/saida/)"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas, load_png, hexc, save_gif, na_paleta  # noqa: E402
from estilo import Desenho  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
ARTE = os.path.join(ROOT, "assets", "sprites", "arte")
SPR = os.path.join(ROOT, "assets", "sprites")
OUT = os.path.join(HERE, "saida")
os.makedirs(OUT, exist_ok=True)


def c8(r, g, b):
    return (r, g, b, 255)


class Rascunho:
    """Tela pequena (1 px = 1 px do jogo) onde o desenho de retangulos do codigo e refeito;
    'pronto' devolve no dobro com o contorno afinado para 1 px."""

    def __init__(self, w, h, ox, oy, contorno):
        self.cv = Canvas(w, h)
        self.ox, self.oy = ox, oy
        self.contorno = contorno

    def r(self, x, y, w, h, cor):
        for yy in range(int(y), int(y + h)):
            for xx in range(int(x), int(x + w)):
                self.cv.set(self.ox + xx, self.oy + yy, cor)

    def pronto(self):
        return refazer(self.cv, 0, self.cv.w, self.cv.h, self.contorno[:3])


# Simples como o pato (poucas cores chapadas, olho de ponto, contorno de 1 px, quase sem sombra)
# e um pouco MAIORES que ele. Desenhados olhando para a direita, com a base na ultima linha.
# Revisados depois da avaliacao de 20 agentes (25/11/2026): pernas de verdade e sempre as
# quatro visiveis na raposa; jacare de outro verde, com quatro pernas, cauda ondulando e dentes
# de verdade; aves em pose de voo (pernas recolhidas), duas asas de area constante, cauda em
# leque, cabeca achatada com sobrancelha e bico em gancho.
OLHO = hexc("3a2a20")
OLHO_16, CINZA_16 = na_paleta(OLHO), na_paleta(hexc("636363"))


def gira(pts, cx, cy, graus):
    a = math.radians(graus)
    ca, sa = math.cos(a), math.sin(a)
    return [(cx + (x - cx) * ca - (y - cy) * sa, cy + (x - cx) * sa + (y - cy) * ca) for x, y in pts]


def oval(cx, cy, rx, ry, n=24):
    return [(cx + math.cos(2 * math.pi * i / n) * rx, cy + math.sin(2 * math.pi * i / n) * ry) for i in range(n)]


# ------------------------------------------------------------------ desenho direto em 16 px
# Os inimigos pequenos sao desenhados direto nos pixels do jogo (1 px = 1 px no jogo) e so
# ampliados 2x para a grade de 32: o reduz2 ve blocos 2x2 de uma cor so e apenas amostra, entao
# olho, dentes, focinho branco e pernas saem exatamente como aqui (o contorno refeito na reducao
# comia as pecas de 1-2 px). Cores ja na Endesga 32 (a conversao nao escolhe nada sozinha).
E_PRETO, E_ESC, E_MARROM, E_COBRE = hexc("181425"), hexc("3e2731"), hexc("733e39"), hexc("b86f50")
E_PELE, E_CREME, E_BRANCO, E_CINZA = hexc("e4a672"), hexc("ead4aa"), hexc("ffffff"), hexc("8b9bb4")
E_LARANJA, E_LARANJA_S, E_VERMELHO = hexc("f77622"), hexc("be4a2f"), hexc("e43b44")
E_AMARELO, E_OURO, E_VINHO = hexc("fee761"), hexc("feae34"), hexc("a22633")


def amplia2(cv):
    """Quadro desenhado em pixels do jogo -> grade de 32 (blocos 2x2 de uma cor so)."""
    out = Canvas(cv.w * 2, cv.h * 2)
    out.blit(cv, 0, 0, 2)
    return out


def mapa(cv, linhas, legenda, ox=0, oy=0):
    """Pinta um mapa de pixels (uma string por linha; '.' = nao mexe)."""
    for j, ln in enumerate(linhas):
        for i, ch in enumerate(ln):
            if ch != "." and ch in legenda:
                cv.set(ox + i, oy + j, legenda[ch])


# ------------------------------------------------------------------ raposa
# 23x17 no jogo (46x34 na grade de 32), olhando para a direita, pes na ultima linha.
# Corpo, cabeca e peito sao um mapa fixo (nada pisca entre quadros); so a cauda balanca e as
# pernas andam. Pernas de perto em marrom (#733e39) e de longe em #3e2731, sempre com 1 px de
# vao entre vizinhas; o quase-preto #181425 so no olho e no nariz.
R_W, R_H = 46, 34
R_QUADROS = 16  # 16 quadros por animacao (exigencia: 15 ou mais)
R_LEG = {"o": E_MARROM, "O": E_LARANJA, "s": E_LARANJA_S, "w": E_BRANCO, "k": E_PRETO}
R_CORPO = [
    "...............o...o...",
    "..............oOo.oOo..",
    "..............oOOoOOo..",
    ".............oOOOOOOOo.",
    ".............oOOOOkOOo.",
    ".............oOOOOOOOoo",
    ".......ooooooOOOOOOOOOk",
    "......oOOOOOOOOOOwwwwo.",
    "......oOOOOOOOOOwwwoo..",
    "......oOOOOOOOOOwwwo...",
    "......osssssssssOwwo...",
    ".......ooooooooooooo...",
]  # linhas 1..12
R_CAUDA = [
    "..ooo.",
    ".oOOOo",
    "owOOOO",
    "owwOOO",
    "owwOOo",
    ".oooo.",
]  # linhas 6..11 (+ balanco)


def _perna_raposa(cv, x, dx, no_ar, meia, pata):
    """Perna de 2 px de largura que sai de baixo do corpo (linha 13) ate o chao (linha 16).
    dx (-1, 0, 1) leva a pata para tras/frente; no ar a pata sobe 1 px."""
    if no_ar:
        trechos = [(13, 0), (14, dx), (15, dx)]
    else:
        trechos = [(13, 0), (14, 0), (15, dx), (16, dx)]
    for i, (y, d) in enumerate(trechos):
        cor = pata if i == len(trechos) - 1 else meia
        cv.set(x + d, y, cor)
        cv.set(x + d + 1, y, cor)


def raposa(quadro):
    cv = Canvas(R_W // 2, R_H // 2)
    fase = 2 * math.pi * quadro / R_QUADROS
    s = math.sin(fase)
    rabo = -1 if s > 0.5 else (1 if s < -0.5 else 0)  # a cauda balanca 1 px
    # pernas: as de perto (2 e 14) andam para frente e para tras; as de longe (10 e 18) so
    # levantam no compasso oposto. Assim o vao de 1 px entre vizinhas nunca fecha.
    for x, f in ((6, fase + math.pi), (14, fase)):
        dx = int(round(math.cos(f)))
        _perna_raposa(cv, x, dx, math.sin(f) < -0.3, E_MARROM, E_ESC)
    for x, f in ((10, fase), (18, fase + math.pi)):
        _perna_raposa(cv, x, 0, math.sin(f) < -0.3, E_ESC, E_ESC)
    mapa(cv, R_CAUDA, R_LEG, 0, 6 + rabo)
    mapa(cv, R_CORPO, R_LEG, 0, 1)
    return amplia2(cv)


# ------------------------------------------------------------------ jacare
# 32x14 no jogo (64x28 na grade de 32), desenhado direto em pixels do jogo como o jacare chefe:
# mesmo verde (#3e8948, contorno #193c3e), barriga creme fixa, olho amarelo numa saliencia
# em cima da cabeca, crista de dentinhos de 2 px com 2 px de vao, cauda com verde ate perto
# da ponta. Mordida: a maxila gira em volta do canto da boca; miolo vermelho chapado, dentes
# brancos de 1 px a cada 3 px so nas beiradas.
J_COR, J_LONGE, J_ESC, J_LUZ = hexc("3e8948"), hexc("265c42"), hexc("193c3e"), hexc("63c74d")
J_BARRIGA, J_DENTE, J_BOCA, J_OLHO = E_CREME, E_BRANCO, E_VERMELHO, E_AMARELO
J_W, J_H = 64, 28


def _perna_jacare(d, x, no_ar, cor, parte):
    """Perna curta de 3 px de largura (contorno + 1 px de miolo + contorno) que sai de baixo
    do corpo; no ar (remada) a pata sobe 1 px. Fica sempre na mesma coluna, entao o vao de
    1 px entre as quatro pernas nunca fecha."""
    d.rect(x, 9, 3, 3 if no_ar else 4, cor, parte)


# colunas das pernas (de tras para a frente): perto, longe, perto, longe, com 1 px de vao
J_PERNAS = ((8, "perna"), (12, "perna_longe"), (16, "perna"), (20, "perna_longe"))
J_ABRE_MAX = 5  # px que a ponta da maxila sobe na mordida toda aberta


def jacare(quadro):
    """quadros 0..15 = nadando (a cauda ondula e as pernas remam); 16..31 = mordida (a boca
    abre de 0 a 26 graus; o jogo escolhe o quadro pela abertura)."""
    d = Desenho(J_W // 2, J_H // 2)
    nado = quadro < 16
    fase = 2 * math.pi * (quadro if nado else 0) / 16.0
    abre = 0.0 if nado else 26.0 * (quadro - 16) / 15.0  # graus que a maxila abre
    # remada em diagonal: perto-de-tras com longe-da-frente, depois as outras duas
    s = math.sin(fase) if nado else 0.0
    ar = (s > 0.3, s < -0.3, s < -0.3, s > 0.3)
    # cauda: afina da base (5 px) para a ponta (3 px, ainda com verde dentro); so a ponta
    # (4 colunas) ondula, 1 px para cima e para baixo, como no jacare chefe
    tops = {}
    ponta = int(round(math.sin(fase))) if nado else 0
    for x in range(0, 10):
        alt = 3 if x < 3 else (4 if x < 6 else 5)
        top = 10 - alt + (ponta if x < 4 else 0)
        tops[x] = top
        d.rect(x, top, 1, alt, J_COR, "corpo")
    # corpo baixo e comprido
    d.rect(9, 5, 13, 5, J_COR, "corpo")
    # crista: dentinhos de 2 px com 2 px de vao (viram um serrilhado do contorno)
    for x in (10, 14, 18):
        d.rect(x, 4, 2, 1, J_COR, "corpo")
    d.rect(5, tops[5] - 1, 2, 1, J_COR, "corpo")
    # mandibula parada
    d.rect(20, 8, 11, 2, J_COR, "corpo")
    # maxila: sobe em degraus, mais na ponta (abertura em px na ponta: 0 a J_ABRE_MAX), com a
    # saliencia do olho em cima. Aberta, a mandibula ganha 1 linha a mais em cima (contorno /
    # creme / contorno) e a boca e o vao vermelho entre a maxila e esse contorno
    nivel = int(round(J_ABRE_MAX * abre / 26.0))

    def sobe(x):
        return int(round(nivel * (min(x, 29) - 21) / 8.0)) if x > 21 else 0  # ponta: 2 px iguais
    for x in range(20, 32 if not nivel else 31):  # aberta: ponta reta em x=30, sem degrau
        top = (5 if (x <= 28 or nivel) else 6) - sobe(x)
        fundo = 8 - sobe(x)  # 1a linha abaixo da maxila (que tem sempre 3 linhas)
        d.rect(x, top, 1, fundo - top, J_COR, "maxila")
        if sobe(x):
            d.rect(x, 7, 1, 1, J_COR, "corpo")  # linha de cima da mandibula
            if fundo < 7 and x <= 30:
                d.rect(x, fundo, 1, 7 - fundo, J_BOCA, "boca")
    # saliencia do olho: 5x4 de cantos de cima cortados (o miolo tem 2 linhas, entao a pupila
    # fica cercada de amarelo/verde e nunca encosta no contorno)
    ex, ey = 21, 2 - sobe(23)
    d.rect(ex, ey, 5, 4, J_COR, "maxila")
    d.apaga([(ex, ey), (ex + 4, ey)])
    # barriga: uma linha creme fixa embaixo do corpo e da mandibula
    d.rect(9, 8, 21, 1, J_BARRIGA, None, so=["corpo"])
    for (x, parte), no_ar in zip(J_PERNAS, ar):  # as de longe mais escuras
        _perna_jacare(d, x, no_ar, J_COR if parte == "perna" else J_LONGE, parte)
    d.contorno({"corpo": J_ESC, "maxila": J_ESC, "perna": J_ESC, "perna_longe": J_ESC, "boca": J_ESC},
               juntas=[("maxila", "corpo"), ("perna", "corpo"), ("perna_longe", "corpo"),
                       ("maxila", "boca"), ("corpo", "boca")])
    cv = d.cv
    part = cv.part
    if nivel:  # mandibula aberta: contorno / creme / contorno em toda a parte que abriu
        for x in range(20, 31):
            if sobe(x):
                cv.px[7][x] = J_ESC
                if x < 30:
                    cv.px[8][x] = J_BARRIGA
    # luz: 1 px mais claro na linha logo abaixo do contorno das costas
    for x in range(1, 30):
        for y in range(1, J_H // 2 - 1):
            if cv.px[y][x] == J_ESC and part[y][x] in ("corpo", "maxila"):
                if cv.px[y + 1][x] == J_COR and cv.px[y - 1][x] is None:
                    cv.px[y + 1][x] = J_LUZ
                break
    # olho: amarelo em L com a pupila no canto de baixo, fixo no miolo da saliencia
    cv.px[ey + 1][ex + 1] = J_OLHO
    cv.px[ey + 1][ex + 2] = J_OLHO
    cv.px[ey + 2][ex + 1] = J_OLHO
    cv.px[ey + 2][ex + 2] = E_PRETO
    cv.px[ey + 1][ex + 3] = J_LUZ
    cv.px[ey + 2][ex + 3] = J_COR
    # dentes: 1 px branco, separados (nenhum encosta em outro, nem na diagonal)
    dentes = []

    def poe(x, y):
        if any(abs(x - a) <= 1 and abs(y - b) <= 1 for a, b in dentes):
            return
        cv.px[y][x] = J_DENTE
        dentes.append((x, y))
    if not nivel:  # fechada: na linha da boca
        for tx in (23, 26):
            for y in range(J_H // 2 - 1, 0, -1):
                if part[y][tx] == "maxila":
                    poe(tx, y)
                    break
    else:
        for tx in (26, 29):  # de cima: pendem da maxila, se a boca tem 2+ linhas ali
            if sobe(tx) - 1 >= 2:
                poe(tx, 8 - sobe(tx))
        for tx in (28, 25):  # de baixo: em cima do contorno da mandibula, se cabem
            if sobe(tx) >= 4:
                poe(tx, 6)
    return amplia2(cv)


# ------------------------------------------------------------------ aves de rapina
# Quadradas como o pato: corpo e cabeca sao blocos de cantos arredondados, e a asa e um bloco
# em escada que afina ate a ponta. Nada e girado: cada pose da asa e desenhada em retangulos,
# entao as bordas ficam retas e limpas. Cores ja na Endesga 32; contorno #3e2731 (nunca o
# quase-preto), bico e pata amarelos com contorno laranja (nada de vermelho de ferida).
ESC_AVE = hexc("3e2731")
# gaviaozinho em tons claros (pele/areia/creme): no fundo azul-marinho escuro da torre, com o
# "ambiente" da fase escurecendo tudo, o cobre/marrom de antes virava uma mancha so com o
# contorno; o escuro agora fica so na silhueta de 1 px e o miolo e uma mancha clara continua
G_PELE = hexc("c28569")
G_CORPO, G_ASA, G_ASA_LONGE, G_PEITO = G_PELE, G_PELE, E_COBRE, E_CREME
G_LUZ, G_PONTA = E_PELE, E_CREME  # luz de cima (areia) e ponta clara da cauda
A_CORPO, A_ASA, A_ASA_LONGE, A_BRANCO = E_MARROM, E_COBRE, E_MARROM, E_BRANCO
BICO, BICO_ESC, PATA_ESC, CINZA = E_AMARELO, E_LARANJA, E_LARANJA, hexc("636363")

# poses da asa em retangulos (x, y, w, h) relativos ao ombro, ave olhando para a direita.
# Toda peca tem 4 px ou mais na grade de 32 (vira 1 px de contorno + 1 px de miolo no jogo) e
# os vaos tem 2 px (1 px no jogo): a ponta e uma escada, com no maximo 2 dedos.
ASA_POSES = {
    "cima": [(-6, -9, 10, 10), (-8, -13, 8, 6), (-10, -17, 4, 6), (-4, -17, 4, 4)],
    "meia": [(-6, -6, 10, 9), (-12, -9, 8, 8), (-17, -12, 7, 6), (-21, -13, 6, 4)],
    "meia_baixa": [(-6, -2, 10, 7), (-12, 0, 8, 8), (-17, 4, 7, 6), (-21, 7, 6, 4)],
    "baixo": [(-6, -1, 10, 10), (-8, 6, 8, 6), (-10, 10, 4, 6), (-4, 10, 4, 4)],
    "fechada": [(-6, -4, 10, 6), (-12, -3, 8, 6), (-20, -2, 8, 4)],
}
# gaviaozinho (k = 1): pecas de 6 px ou mais na grade de 32 (3 px no jogo = contorno + miolo +
# contorno), degraus de 2 px (1 px no jogo); a ponta e um degrau quadrado com miolo, nunca dedo
ASA_POSES_GAV = {
    "meia": [(-6, -8, 10, 11), (-12, -10, 8, 9), (-18, -12, 8, 6)],
    "meia_baixa": [(-6, -2, 10, 8), (-12, 0, 8, 8), (-18, 4, 8, 6)],
    "baixo": [(-6, -2, 10, 10), (-8, 6, 8, 8), (-12, 10, 8, 6)],  # cai para tras, sem dedos
}
# batida em 6 quadros: cima, meio subindo, meio descendo, embaixo e volta
ASA_CICLO = ["cima", "meia", "meia_baixa", "baixo", "meia_baixa", "meia"]


def _par(v):
    """Arredonda para numero par: na grade de 32 isso cai num pixel inteiro do jogo."""
    return 2 * int(round(v / 2.0))


def _bloco(d, x, y, w, h, cor, parte, r=1):
    """Retangulo de cantos arredondados em 'r' px (degrau), como o pato."""
    x, y, w, h = int(round(x)), int(round(y)), int(round(w)), int(round(h))
    d.rect(x, y, w, h, cor, parte)
    if w > 2 * r and h > 2 * r:
        for i in range(r):
            for (cx, cy) in ((x + i, y), (x, y + i), (x + w - 1 - i, y), (x + w - 1, y + i),
                             (x + i, y + h - 1), (x, y + h - 1 - i), (x + w - 1 - i, y + h - 1),
                             (x + w - 1, y + h - 1 - i)):
                if r - i > 0 and ((cx == x + i and cy == y) or True):
                    pass
        # corta so o pixel do canto (r = 1) ou um degrau de 2 (r = 2)
        cantos = [(x, y), (x + w - 1, y), (x, y + h - 1), (x + w - 1, y + h - 1)]
        if r >= 2:
            cantos += [(x + 1, y), (x, y + 1), (x + w - 2, y), (x + w - 1, y + 1),
                       (x + 1, y + h - 1), (x, y + h - 2), (x + w - 2, y + h - 1), (x + w - 1, y + h - 2)]
        d.apaga(cantos)


def ave(pose, k, corpo, asa, asa_longe, cabeca, cauda, peito=None, env=1.0):
    """Ave de rapina de lado, em voo, olhando para a direita. k = tamanho (1 = gaviaozinho);
    env = comprimento das asas. pose 0..5 = batendo as asas; 6 = ataque (asas fechadas para
    tras, cabeca baixa, garras abertas a frente)."""
    W, H = int(44 * k) // 2 * 2 + 2, int(38 * k) // 2 * 2
    d = Desenho(W, H)
    n = lambda v: v * k  # noqa: E731
    ataque = pose == 6
    nome = "fechada" if ataque else ASA_CICLO[pose]
    ox, oy = _par(n(24)), _par(n(18))  # ombro
    baixa = _par(n(2)) if ataque else 0  # no ataque a cabeca desce

    def asa_rects(dx, dy, kk):
        out = []
        for (x, y, w, h) in ASA_POSES[nome]:
            out.append((_par(ox + dx + x * kk * env), _par(oy + dy + y * kk),
                        max(4, _par(w * kk * env)), max(4, _par(h * kk))))
        return out
    # asa de longe: a mesma pose, mais escura, 4 px a frente e 2 acima (aparece atras do corpo)
    for (x, y, w, h) in asa_rects(n(3), -n(2), k * 0.9):
        d.rect(x, y, w, h, asa_longe, "asa_longe")
    # cauda em leque: abre para tras (mais alta na ponta), com um corte no meio da ponta que
    # separa duas penas
    cx0, cx1 = _par(n(3)), _par(n(14))
    d.poli([(cx1, _par(n(16))), (cx1, _par(n(23))), (cx0, _par(n(25))), (cx0, _par(n(14)))], cauda, "cauda")
    d.apaga([(cx0 + i, _par(n(19.5)) + j) for i in range(2) for j in range(2)])
    # corpo: bloco comprido arredondado; peito claro embaixo
    _bloco(d, _par(n(11)), _par(n(13)), _par(n(19)), _par(n(12)), corpo, "corpo", r=2)
    if peito is not None:
        _bloco(d, _par(n(17)), _par(n(20)), _par(n(12)), _par(n(4)), peito, None, r=1)
    # cabeca: bloco de topo reto, um pouco a frente e acima do corpo
    hx, hy = _par(n(27)), _par(n(7)) + baixa
    _bloco(d, hx, hy, _par(n(10)), _par(n(10)), cabeca, "cabeca", r=2)
    # bico em gancho: bloco amarelo com a ponta descendo
    _bloco(d, hx + _par(n(9)), hy + _par(n(3)), max(4, _par(n(4))), max(4, _par(n(4))), BICO, "bico", r=1)
    d.rect(hx + _par(n(11)), hy + _par(n(6)), max(2, _par(n(2))), max(4, _par(n(3))), BICO, "bico")
    # pernas: recolhidas no voo; no ataque esticadas para a frente com as garras
    if ataque:
        for i in range(2):
            px = _par(n(19 + i * 5))
            d.rect(px, _par(n(24)), max(2, _par(n(2))), _par(n(4)), BICO, "pata")
            d.rect(px, _par(n(27)), _par(n(5)), max(2, _par(n(2))), BICO, "pata")
    else:
        d.rect(_par(n(17)), _par(n(24)), _par(n(6)), max(2, _par(n(2))), BICO, "pata")
    # asa de perto por cima de tudo
    for (x, y, w, h) in asa_rects(0, 0, k):
        d.rect(x, y, w, h, asa, "asa")
    # contorno escuro tambem na cabeca e na cauda brancas: com o cinza elas viravam blocos
    # soltos do corpo no fundo escuro do castelo
    d.contorno({"corpo": ESC_AVE, "cabeca": ESC_AVE, "cauda": ESC_AVE,
                "asa": ESC_AVE, "asa_longe": ESC_AVE, "bico": BICO_ESC, "pata": PATA_ESC},
               juntas=[("asa", "corpo"), ("cabeca", "corpo"), ("bico", "cabeca"), ("asa", "cauda"),
                       ("asa", "cabeca"), ("corpo", "cauda"), ("corpo", "asa_longe"), ("pata", "corpo"),
                       ("cabeca", "asa_longe")])
    # olho de ponto (com cor da cabeca em volta) e a sobrancelha brava por cima
    d.rect(hx + _par(n(5)), hy + _par(n(4.5)), 2, 2, OLHO)
    d.rect(hx + _par(n(3)), hy + _par(n(2.5)), max(4, _par(n(5))), 2, ESC_AVE if cabeca != A_BRANCO else CINZA)
    d.rect(hx + _par(n(11)), hy + _par(n(8)), max(2, _par(n(2))), 2, BICO_ESC)
    return d.cv


def em16(cv):
    """O que o save() faria com o quadro (reducao 2x com o contorno refeito + Endesga 32), para
    retocar pixel a pixel no tamanho do jogo antes de ampliar de volta com amplia2."""
    r = cv.reduz2()
    for y in range(r.h):
        for x in range(r.w):
            if r.px[y][x] is not None:
                r.px[y][x] = na_paleta(r.px[y][x])
    return r


def _cauda16(cv):
    """Pixels (no tamanho do jogo) que sao so cauda no desenho da grade de 32: o bloco 2x2 tem
    cauda e nenhuma asa por cima (para a ponta clara nao cair na ponta da asa)."""
    out = set()
    for y in range(cv.h // 2):
        for x in range(cv.w // 2):
            bloco = [cv.part[2 * y + j][2 * x + i] for i in (0, 1) for j in (0, 1)]
            if bloco.count("cauda") >= 2 and not any(b in ("asa", "asa_longe") for b in bloco):
                out.add((x, y))
    return out


def _retoque_ave(c, k, pose, gav, cauda=None, grito=False):
    """Retoques no tamanho do jogo (o contorno refeito na reducao come pecas de 1-2 px): bico
    e patas desenhados a mao, olho de 1 px com a cor da cabeca em volta, luz de cima e (no
    gaviaozinho) juntas internas em meio-tom, para o contorno escuro ficar so na silhueta.
    grito = bico bem aberto (mandibula de cima e de baixo separadas pela boca vermelha)."""
    ataque = pose == 6
    meio = G_CORPO if gav else E_COBRE  # cor do miolo que recebe a luz de cima
    X = _par(27 * k) // 2
    Y = (_par(7 * k) + (_par(2 * k) if ataque else 0)) // 2
    lado = 5 if gav else 7  # lado da cabeca em px do jogo
    vazio = lambda x, y: not c.inside(x, y) or c.px[y][x] is None  # noqa: E731
    for y in range(c.h):  # tira o bico e as patas que sobraram da reducao
        for x in range(c.w):
            if c.px[y][x] in (BICO, BICO_ESC):
                c.px[y][x] = None
    # juntas internas em meio-tom (o escuro so na borda de fora); na aguia so as da asa de
    # perto (a asa de longe tem a cor do corpo e precisa da linha para separar)
    viz = ((1, 0), (-1, 0), (0, 1), (0, -1))
    troca = [(x, y) for y in range(c.h) for x in range(c.w)
             if c.px[y][x] == ESC_AVE and not any(vazio(x + dx, y + dy) for dx, dy in viz)
             and (gav or any(c.px[y + dy][x + dx] == E_COBRE for dx, dy in viz))]
    for x, y in troca:
        c.px[y][x] = E_MARROM
    soltos = [(x, y) for y in range(c.h) for x in range(c.w)  # pontinho escuro solto no miolo
              if c.px[y][x] == ESC_AVE and not any(vazio(x + dx, y + dy) or c.px[y + dy][x + dx] == ESC_AVE
                                                   for dx, dy in viz)]
    for x, y in soltos:
        c.px[y][x] = E_MARROM
    # luz de cima: 1 px mais claro logo abaixo do contorno de cima
    luz = G_LUZ if gav else E_PELE
    for y in range(1, c.h):
        for x in range(c.w):
            if c.px[y][x] == meio and c.px[y - 1][x] in (ESC_AVE, E_MARROM, None):
                c.px[y][x] = luz
    if gav:  # ponta clara na cauda (so nos pixels de cauda: a ponta da asa tambem chega ali)
        for y in range(c.h):
            for x in range(1, 5):
                if cauda is not None and (x, y) not in cauda:
                    continue
                if c.px[y][x] in (meio, luz) and c.px[y][x - 1] == ESC_AVE:
                    c.px[y][x] = G_PONTA
    # olho: 1 px quase preto no miolo da cabeca, longe do contorno de cima
    cab = c.px[Y + lado // 2][X + lado // 2]
    for yy in range(Y + 1, Y + lado - 1):
        for xx in range(X + 1, X + lado - 1):
            if c.px[yy][xx] in (OLHO_16, E_ESC, E_PRETO):
                c.px[yy][xx] = cab
    if gav:  # rosto 3x3: sobrancelha no canto de tras, olho no meio com face clara em volta
        for yy in range(Y + 1, Y + lado - 1):
            for xx in range(X + 1, X + lado - 1):
                c.px[yy][xx] = luz if yy == Y + 1 else meio
        c.px[Y + 1][X + 1] = E_MARROM
        c.px[Y + 2][X + 2] = E_PRETO
    else:
        for xx in range(X + 2, X + 5):
            c.px[Y + 2][xx] = hexc("8b9bb4")
        c.px[Y + 3][X + 4] = E_PRETO
    # bico em gancho encostado na cabeca: contorno laranja, miolo amarelo, sem buraco
    bx = X + lado
    if gav and grito:  # aberto: mandibula de cima, boca vermelha, mandibula de baixo
        bico = ["ooo.", "yyyo", "r...", "yyo.", "oo.."]
    elif gav:
        bico = ["oo.", "yyo", ".o."]
    elif grito:
        bico = ["oo...", "yyyo.", "yyyyo", "rr.oo", "yyo..", "oo..."]
    else:
        bico = ["oo..", "yyyo", "yyyo", "ooyo", "...o"]
    mapa(c, bico, {"o": BICO_ESC, "y": BICO, "r": E_VERMELHO}, bx, Y + 1)
    if gav:  # o amarelo entra 1 px no contorno da cara: o bico pequeno nao parece um pixel solto
        c.px[Y + 2][bx - 1] = BICO
    for yy in range(Y + 1, Y + lado - 1):  # fecha a cabeca do lado do bico (sem buraco)
        if c.px[yy][bx - 1] is None:
            c.px[yy][bx - 1] = ESC_AVE
    # patas: no voo, recolhidas (1 linha laranja); no ataque, perna de 1 px e dois dedos
    # amarelos abertos com a garra escura na ponta
    base = (_par(13 * k) + _par(12 * k)) // 2  # 1a linha embaixo do corpo
    if ataque:
        for px_ in (_par(19 * k) // 2, _par(19 * k) // 2 + (4 if gav else 5)):
            mapa(c, [".o.", ".o.", "y.y", "k.k"], {"o": BICO_ESC, "y": BICO, "k": E_ESC}, px_ - 1, base)
    else:
        x0 = _par(17 * k) // 2
        for xx in range(x0, x0 + (2 if gav else 3)):
            if vazio(xx, base) and not vazio(xx, base - 1):
                c.set(xx, base, BICO_ESC)
    if not gav:  # fecha a barriga: a reducao as vezes perde o contorno de baixo junto da pata
        for yy in range(1, c.h):
            for xx in range(c.w):
                if vazio(xx, yy) and c.px[yy - 1][xx] in (E_MARROM, E_COBRE, E_PELE, A_BRANCO):
                    c.set(xx, yy, ESC_AVE)
    return c


def gaviaozinho(pose, grito=False):
    velha = ASA_POSES.copy()  # poses proprias do gaviaozinho (o chefe e a aguia usam ASA_POSES)
    ASA_POSES.update(ASA_POSES_GAV)
    try:
        a = ave(pose, 1.0, G_CORPO, G_ASA, G_ASA_LONGE, G_CORPO, G_ASA, peito=G_PEITO)
    finally:
        ASA_POSES.clear()
        ASA_POSES.update(velha)
    return amplia2(_retoque_ave(em16(a), 1.0, pose, True, cauda=_cauda16(a), grito=grito))


def aguia(pose, grito=False):
    if pose >= 7:  # 7..22 = os 16 quadros de bico preso
        return aguia_presa(pose - 7)
    return amplia2(_retoque_ave(em16(ave(pose, 1.4, A_CORPO, A_ASA, A_ASA_LONGE, A_BRANCO, A_BRANCO,
                                         env=1.15)), 1.4, pose, False, grito=grito))


# grito (aviso antes do rasante/mergulho): parada no ar, asas erguidas no alto batendo curto
# (so entre "cima" e "meia"), corpo sem subir e descer e o bico bem aberto. Assim o aviso se le
# no sprite, e nao so pelo som e pelo pisca.
GRITO_ASA = [0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1]
GRITO_DY = [0, 0, 0, 0, -2, -2, 0, 0, 0, 0, 0, 0, -2, -2, 0, 0]  # 1 px de "pulo" no grito


def grito16(fn):
    """16 quadros de grito da ave fn(pose, grito=True)."""
    return [_desloca(fn(GRITO_ASA[i], grito=True), 0, 2 + GRITO_DY[i]) for i in range(16)]


# aguia de bico preso, desenhada direto em pixels do jogo (31x26): o corpo inclinado com a
# frente para baixo, a cabeca baixa e a ponta do bico como pixel mais baixo do desenho, FIXA
# em (19, 18) nos 16 quadros (e ela que esta presa; o jogo poe o meio do corpo em (14, 13) e o
# chao fica 4-7 px abaixo dele). Cauda em leque para cima, asas erguidas acima das costas.
PRESA_ASA = [  # retangulos relativos ao ombro (12, 5)
    [(-3, -5, 7, 6), (-6, -5, 5, 4)],                    # 0 erguida, junto do corpo
    [(-4, -4, 8, 5), (-9, -5, 7, 4), (-13, -5, 5, 3)],   # 1 meio aberta, para tras
    [(-2, -5, 6, 6), (2, -5, 4, 3)],                     # 2 batida para o alto
    [(-4, -2, 8, 5), (-10, -2, 7, 4), (-14, -1, 5, 3)],  # 3 batida esticada para tras
]
PRESA_SEQ = [0, 0, 1, 1, 0, 0, 1, 1, 2, 3, 2, 3, 2, 1, 0, 0]


def aguia_presa(i):
    d = Desenho(31, 26)
    puxa = (0, 0, 1, 1, 0, 0, -1, -1)[i % 8]   # o corpo puxa para os lados
    rabo = (0, -1, -1, 0, 0, 1, 1, 0)[(i + 2) % 8]  # a cauda sobe e desce
    asa = PRESA_SEQ[i]
    sx, sy = 12 + puxa, 5

    def asa_em(dx, dy, cor, parte):
        for (x, y, w, h) in PRESA_ASA[asa]:
            d.rect(sx + dx + x, max(0, sy + dy + y), w, h, cor, parte)
    asa_em(2, 1, A_ASA_LONGE, "asa_longe")
    # cauda branca em leque, para cima e para tras, com um corte entre as penas da ponta
    p = puxa
    d.poli([(8 + p, 6), (4 + p, 1 + rabo), (0 + p, 2 + rabo), (0 + p, 7 + rabo), (6 + p, 11)], A_BRANCO, "cauda")
    d.apaga([(p, 4 + rabo), (p + 1, 4 + rabo)])
    # corpo inclinado (a frente desce ate a cabeca)
    d.poli([(4 + p, 6), (10 + p, 2), (20, 8), (19, 14), (8 + p, 13)], A_CORPO, "corpo")
    # cabeca baixa, do tamanho da do voo
    _bloco(d, 15, 8, 7, 7, A_BRANCO, "cabeca", r=1)
    asa_em(0, 0, A_ASA, "asa")
    d.contorno({"corpo": ESC_AVE, "cabeca": ESC_AVE, "cauda": ESC_AVE, "asa": ESC_AVE, "asa_longe": ESC_AVE},
               juntas=[("asa", "corpo"), ("cabeca", "corpo"), ("asa", "cauda"), ("corpo", "cauda"),
                       ("corpo", "asa_longe"), ("asa", "cabeca")])
    c = d.cv
    for y in range(1, c.h):  # luz de cima na asa de perto
        for x in range(c.w):
            if c.px[y][x] == A_ASA and c.px[y - 1][x] in (ESC_AVE, None):
                c.px[y][x] = E_PELE
    # olho bravo olhando para baixo e bico enfiado (a ponta, em (19, 18), e o pixel mais baixo)
    c.px[10][18] = hexc("8b9bb4")
    c.px[10][19] = hexc("8b9bb4")
    c.px[11][19] = E_PRETO
    mapa(c, ["oyyo", ".yyo", ".oyo", "..o."], {"o": BICO_ESC, "y": BICO}, 17, 15)
    return amplia2(c)


# aguia em mergulho, desenhada direto em pixels do jogo (31x26, o mesmo quadro do voo): o corpo
# inclinado uns 40 graus com a cabeca e o bico a frente e embaixo, a cauda em cima e atras, as
# asas fechadas coladas nas costas (a ponta passa da cauda) e as garras abertas a frente,
# apontando para o alvo. O meio do corpo fica em (14, 13), o PIVO de scripts/aguia.gd.
def aguia_mergulho(i):
    d = Desenho(31, 26)
    rabo = (0, 0, 1, 1, 0, 0, -1, -1)[i % 8]  # as penas da cauda tremem com o vento
    ponta = (0, 1, 1, 0)[(i // 2) % 4]       # e a ponta da asa tambem
    d.poli([(9, 1), (13, 1), (22, 9), (20, 11), (12, 6)], A_ASA_LONGE, "asa_longe")
    d.poli([(9, 8), (4, 2 + rabo), (0, 4 + rabo), (1, 9 + rabo), (7, 13)], A_BRANCO, "cauda")
    d.apaga([(0, 6 + rabo), (1, 6 + rabo)])
    d.poli([(5, 8), (11, 4), (23, 13), (22, 18), (15, 21), (5, 13)], A_CORPO, "corpo")
    _bloco(d, 18, 12, 7, 7, A_BRANCO, "cabeca", r=1)
    d.poli([(4 - ponta, 1), (9, 2), (20, 10), (18, 14), (13, 13), (6, 6)], A_ASA, "asa")
    d.contorno({"corpo": ESC_AVE, "cabeca": ESC_AVE, "cauda": ESC_AVE, "asa": ESC_AVE,
                "asa_longe": ESC_AVE},
               juntas=[("asa", "corpo"), ("cabeca", "corpo"), ("asa", "cauda"), ("corpo", "cauda"),
                       ("asa", "asa_longe"), ("asa", "cabeca")])
    c = d.cv
    for y in range(1, c.h):  # luz de cima na asa de perto
        for x in range(c.w):
            if c.px[y][x] == A_ASA and c.px[y - 1][x] in (ESC_AVE, None):
                c.px[y][x] = E_PELE
    # sobrancelha brava, olho para a frente e bico em gancho descendo
    for x in (20, 21, 22):
        c.px[14][x] = hexc("8b9bb4")
    c.px[15][22] = E_PRETO
    mapa(c, ["oo..", "yyo.", "yyyo", "oyyo", ".oyo", "..oo"], {"o": BICO_ESC, "y": BICO}, 25, 13)
    # garras abertas a frente, embaixo da cabeca (a de longe um pouco mais curta)
    mapa(c, ["o....", ".o...", "..o..", "..yyy", "..k.k"], {"o": BICO_ESC, "y": BICO, "k": E_ESC}, 14, 20)
    mapa(c, ["o...", ".o..", ".yyy", ".k.k"], {"o": BICO_ESC, "y": BICO, "k": E_ESC}, 18, 19)
    return amplia2(c)


def mergulho16():
    """16 quadros de mergulho da aguia: o corpo treme 1 px (so para a direita e para baixo, a
    cauda encosta na borda esquerda do quadro) e as penas da cauda e da asa batem ao vento."""
    return [_desloca(aguia_mergulho(i), (0, 2, 2, 0)[(i // 4) % 4], (0, 0, 2, 2)[i % 4]) for i in range(16)]


# ------------------------------------------------------------------ saida
def tira(quadros):
    w, h = quadros[0].w, quadros[0].h
    cv = Canvas(w * len(quadros), h)
    for i, q in enumerate(quadros):
        cv.blit(q, i * w, 0)
    return cv


def _desloca(cv, dx, dy):
    out = Canvas(cv.w, cv.h)
    for y in range(cv.h):
        for x in range(cv.w):
            c = cv.px[y][x]
            if c is not None and 0 <= x + dx < cv.w and 0 <= y + dy < cv.h:
                out.px[y + dy][x + dx] = c
    return out


def voo16(fn):
    """16 quadros de voo: a asa passa pelas 6 poses e o corpo desce 1 px (em 16x16) com a asa
    no alto e sobe quando ela bate para baixo."""
    out = []
    for i in range(16):
        pose = int(i * 6 / 16)
        # o corpo sobe e desce um pouco atrasado em relacao a asa (gera as poses intermediarias)
        dy = 2 * int(round(math.cos(2 * math.pi * (i - 3) / 16.0)))
        out.append(_desloca(fn(pose), 0, dy))
    return out


def ataque16(fn):
    """16 quadros de rasante/mergulho: asas fechadas, o corpo treme 1 px para cima e para baixo."""
    return [_desloca(fn(6), (0, 2, 2, 0)[(i // 4) % 4], (0, 0, 2, 2, 0, 0, -2, -2)[i % 8]) for i in range(16)]


def presa16(fn):
    """16 quadros de bico preso (pose 7..22 da ave: cabeca para baixo, bico enfiado no chao,
    cauda para cima, asas batendo para se soltar)."""
    return [fn(7 + i) for i in range(16)]


# Os quadros de grito so entram nas folhas com COM_GRITO = True. ATENCAO: ligar muda o numero
# de quadros das folhas, entao tem de ser gravado JUNTO com os scripts: scripts/gaviaozinho.gd
# QUADROS := 48 (grito 32..47) e scripts/aguia.gd QUADROS := 64 (grito 48..63), cada um usando
# esses quadros no estado "aviso". Com os scripts antigos a folha maior sai espremida no jogo.
COM_GRITO = False


def pecas():
    gav = voo16(gaviaozinho) + ataque16(gaviaozinho)                 # voo 0..15, rasante 16..31
    agu = voo16(aguia) + mergulho16() + presa16(aguia)               # voo, mergulho, bico preso
    if COM_GRITO:
        gav += grito16(gaviaozinho)                                  # grito 32..47
        agu += grito16(aguia)                                        # grito 48..63
    return {
        "raposa": [raposa(i) for i in range(16)],
        "jacare": [jacare(i) for i in range(32)],                       # nado 0..15, mordida 16..31
        "gaviaozinho": gav,
        "aguia": agu,
    }


def folha(p):
    S = 4
    CEU, GRAMA = hexc("76c2f6"), hexc("28b228")
    linhas = [("raposa", True), ("jacare", True), ("gaviaozinho", False), ("aguia", False)]
    W = 44 + max(sum(q.w + 8 for q in p[n]) for n, _ in linhas) + 8
    alturas = [max(q.h for q in p[n]) + 14 for n, _ in linhas]
    H = sum(alturas)
    cv = Canvas(W, H)
    pato = load_png(os.path.join(ARTE, "pato_parado.png"))
    y0 = 0
    for (n, chao), alt in zip(linhas, alturas):
        for y in range(y0, y0 + alt):
            for x in range(W):
                cv.px[y][x] = GRAMA if (chao and y >= y0 + alt - 6) else CEU
        base = y0 + alt - 6
        for yy in range(32):
            for xx in range(32):
                c = pato.px[yy * 4 + 1][xx * 4 + 1]
                if c is not None and base - 31 + yy >= y0:
                    cv.px[base - 31 + yy][6 + xx] = c
        x = 44
        for q in p[n]:
            cv.blit(q, x, base - q.h + 1)
            x += q.w + 8
        y0 += alt
    big = Canvas(W * S, H * S)
    big.blit(cv, 0, 0, S)
    big.save(os.path.join(OUT, "inimigos.png"))
    bg = (118, 194, 246)
    save_gif(os.path.join(OUT, "raposa.gif"), p["raposa"], delay_cs=4, scale=6, bg=bg)
    save_gif(os.path.join(OUT, "gaviaozinho.gif"), p["gaviaozinho"][:16], delay_cs=5, scale=6, bg=bg)
    save_gif(os.path.join(OUT, "aguia.gif"), p["aguia"][:16], delay_cs=6, scale=6, bg=bg)
    save_gif(os.path.join(OUT, "jacare.gif"), p["jacare"], delay_cs=6, scale=6, bg=bg)
    save_gif(os.path.join(OUT, "gaviaozinho_grito.gif"), grito16(gaviaozinho), delay_cs=5, scale=6, bg=bg)
    save_gif(os.path.join(OUT, "aguia_grito.gif"), grito16(aguia), delay_cs=5, scale=6, bg=bg)


def main():
    p = pecas()
    folha(p)
    if "--salvar" in sys.argv:
        for nome, quadros in p.items():
            t = tira(quadros)
            big = Canvas(t.w * 4, t.h * 4)
            big.blit(t, 0, 0, 4)
            big.save(os.path.join(ARTE, nome + ".png"))
        print("salvo em assets/sprites/arte/:", ", ".join(sorted(p)))
    print("ok")


if __name__ == "__main__":
    main()
