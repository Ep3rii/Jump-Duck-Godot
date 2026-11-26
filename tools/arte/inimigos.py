"""Inimigos comuns na base de estilo, pelo mesmo caminho aprovado nos itens ("mais fiel ao
original, mais simples"):
  - raposa: o sprite original (spr_raposaAnda, 64x64) ja esta na grade da arte; entra como e,
    em tamanho exato (antes era desenhada reduzida em 0,45, o que borrava os pixels);
  - jacare, gaviaozinho e aguia: nao tinham sprite, eram desenhados em codigo com retangulos.
    Aqui o mesmo desenho e refeito no dobro, com cor chapada e contorno de 1 px.
Grade: 2 px do desenho = 1 px do jogo. Gravados 4x em assets/sprites/arte/ (com --salvar).
Uso: python tools/arte/inimigos.py [--salvar]   (previas em tools/arte/saida/)"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas, load_png, hexc, save_gif  # noqa: E402
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


def gira(pts, cx, cy, graus):
    a = math.radians(graus)
    ca, sa = math.cos(a), math.sin(a)
    return [(cx + (x - cx) * ca - (y - cy) * sa, cy + (x - cx) * sa + (y - cy) * ca) for x, y in pts]


def oval(cx, cy, rx, ry, n=24):
    return [(cx + math.cos(2 * math.pi * i / n) * rx, cy + math.sin(2 * math.pi * i / n) * ry) for i in range(n)]


# ------------------------------------------------------------------ raposa
R_COR, R_SOMBRA, R_LONGE, R_ESC = hexc("f26b3a"), hexc("d9562a"), hexc("c9552c"), hexc("8a3a1c")
R_BRANCO, R_MEIA, R_MEIA_LONGE, R_MEIA_ESC = hexc("ffffff"), hexc("5a3520"), hexc("42281a"), hexc("2a1608")
R_W, R_H = 46, 34
R_QUADROS = 6


def _perna_raposa(d, quadril_x, fase, cor, meia, parte):
    """Perna em dois trechos: coxa (cor do corpo) e canela com meia escura e pata. A pata vai
    para a frente e para tras no passo e levanta 2 px quando esta voltando para a frente."""
    dx = int(round(3 * math.cos(fase)))
    levanta = 2 if math.sin(fase) < -0.3 else 0  # no ar a pata volta para a frente
    joelho_y, chao = 25, R_H - levanta
    jx = quadril_x + dx * 0.4
    px = quadril_x + dx
    d.poli([(quadril_x - 2, 20), (quadril_x + 3, 20), (jx + 2.5, joelho_y + 1), (jx - 2, joelho_y + 1)], cor, parte)
    d.poli([(jx - 1.5, joelho_y), (jx + 2, joelho_y), (px + 2, chao - 2), (px - 1.5, chao - 2)], meia, parte + "_meia")
    d.rect(px - 1, chao - 3, 5, 3, meia, parte + "_meia")


def raposa(quadro):
    d = Desenho(R_W, R_H)
    fase = 2 * math.pi * quadro / R_QUADROS
    rabo = [0, -1, -1, 0, 1, 1][quadro]  # a ponta da cauda balanca 1 px
    # as quatro pernas aparecem sempre: as de longe (mais escuras) 4 px a frente das de perto
    _perna_raposa(d, 34, fase + math.pi, R_LONGE, R_MEIA_LONGE, "longe")
    _perna_raposa(d, 20, fase, R_LONGE, R_MEIA_LONGE, "longe")
    # cauda comprida e cheia, com a ponta branca
    d.poli([(14, 17), (7, 13 + rabo), (2, 14 + rabo), (0, 19 + rabo), (2, 25 + rabo), (8, 27), (15, 24)], R_COR, "cauda")
    d.poli([(5, 13 + rabo), (2, 14 + rabo), (0, 19 + rabo), (2, 25 + rabo), (5, 26 + rabo), (6, 19 + rabo)],
           R_BRANCO, None, so=["cauda"])
    # corpo, pescoco e peito branco
    d.elipse(22, 19.5, 11, 5.5, R_COR, "corpo")
    d.poli([(27, 15), (32, 9), (38, 16), (33, 23), (27, 23)], R_COR, "corpo")
    d.sombra("corpo", R_SOMBRA, dx=0, dy=2)
    d.poli([(31, 18), (35, 17), (34, 24), (30, 24)], R_BRANCO, None, so=["corpo"])
    _perna_raposa(d, 28, fase, R_COR, R_MEIA, "perto")
    _perna_raposa(d, 13, fase + math.pi, R_COR, R_MEIA, "perto")
    # cabeca grande como a do pato, orelhas em ponta, focinho com a parte de baixo branca
    d.elipse(35, 12, 7, 6, R_COR, "cabeca")
    d.poli([(29, 9), (30, 1), (35, 7)], R_COR, "cabeca")
    d.poli([(35, 7), (39, 1), (41, 9)], R_COR, "cabeca")
    d.poli([(39, 10), (46, 13), (46, 16), (39, 18)], R_COR, "cabeca")
    d.poli([(34, 15), (46, 15), (46, 16), (40, 18), (34, 18)], R_BRANCO, None, so=["cabeca"])
    d.rect(36, 10, 2, 2, OLHO)
    d.rect(44, 13, 2, 2, OLHO)  # nariz
    d.contorno({"corpo": R_ESC, "cabeca": R_ESC, "cauda": R_ESC, "perto": R_ESC, "longe": R_ESC,
                "perto_meia": R_MEIA_ESC, "longe_meia": R_MEIA_ESC},
               juntas=[("cabeca", "corpo"), ("corpo", "cauda"), ("perto", "corpo")])
    return d.cv


# ------------------------------------------------------------------ jacare
# verde-agua fechado: destaca do verde vivo da grama do jogo
J_COR, J_SOMBRA, J_LONGE, J_ESC = hexc("3c9468"), hexc("2f7a54"), hexc("2f7a54"), hexc("123f2c")
J_BARRIGA, J_DENTE, J_BOCA, J_OLHO = hexc("e3ecaa"), hexc("ffffff"), hexc("c93a34"), hexc("ffe94a")
J_W, J_H = 64, 28
J_BASE = 21          # linha da barriga
J_DOBRA = (42, 17)   # canto da boca: a maxila gira em volta dele


def _perna_jacare(d, x, passo, cor, parte):
    """Perna curta vista de lado: coxa descendo da barriga e pe pequeno virado para a frente,
    com tres dedinhos. 'passo' (-1, 0, 1) leva o pe para tras/frente."""
    d.poli([(x, J_BASE - 3), (x + 5, J_BASE - 3), (x + 5 + passo, J_BASE + 3), (x + 1 + passo, J_BASE + 3)], cor, parte)
    px = x + passo
    d.rect(px, J_BASE + 3, 7, 2, cor, parte)
    for t in range(3):  # dedos: dentinhos na frente do pe
        d.rect(px + 7, J_BASE + 3 + (t % 2), 1, 1, cor, parte)
    return [(px + 2, J_BASE + 4), (px + 4, J_BASE + 4), (px + 6, J_BASE + 4)]


def jacare(quadro):
    """quadros 0..3 = nadando (a cauda ondula e as pernas remam); 4 e 5 = mordida."""
    d = Desenho(J_W, J_H)
    nado = quadro < 4
    fase = 2 * math.pi * (quadro if nado else 1) / 4.0
    abre = 0 if nado else (14 if quadro == 4 else 26)  # graus que a maxila abre
    passo = int(round(math.cos(fase))) if nado else 0
    garras = []
    garras += _perna_jacare(d, 39, -passo, J_LONGE, "perna_longe")
    garras += _perna_jacare(d, 21, passo, J_LONGE, "perna_longe")
    # cauda: ondula como cobra (a onda anda da base para a ponta) e afina ate 2 px
    topo, fundo = [], []
    for i in range(0, 25, 2):
        x = 23 - i
        onda = 2.5 * (i / 24.0) * math.sin(fase - i / 5.0) if nado else 0.0
        meia = 4.5 * (1 - i / 24.0) + 1.0
        topo.append((x, 16 + onda - meia))
        fundo.append((x, 16 + onda + meia))
    d.poli(topo + fundo[::-1], J_COR, "corpo")
    # corpo baixo de costas arredondadas
    d.poli(oval(31, 16.5, 12.5, 5.5), J_COR, "corpo")
    d.rect(21, 15, 22, 7, J_COR, "corpo")
    # escamas das costas: dentinhos baixos (2 px) do pescoco ate o meio da cauda
    for x in range(8, 42, 4):
        topo_y = 16 - (4.5 * (1 - (23 - x) / 24.0) + 1.0) if x < 23 else 11
        d.rect(x, topo_y - 2, 2, 2, J_COR, "corpo")
    # mandibula fina e parada
    d.poli([(41, 17), (61, 17), (63, 18), (62, 20), (41, 21)], J_COR, "corpo")
    # maxila: focinho comprido que afina ate a ponta, olho alto em cima e narina na ponta
    maxila = [(41, 11), (44, 10), (49, 11), (62, 14), (63, 16), (63, 17), (41, 17)]
    olho = oval(46.5, 10, 3, 2.5, 12)
    narina = oval(61, 14, 1.5, 1.2, 8)
    cx, cy = J_DOBRA
    for pts in (maxila, olho, narina):
        d.poli(gira(pts, cx, cy, -abre), J_COR, "maxila")
    if abre:  # boca aberta: vermelho chapado entre a maxila e a mandibula
        d.poli(gira([(42, 17), (62, 17)], cx, cy, -abre) + [(62, 17), (42, 18)], J_BOCA, "boca")
    d.rect(16, J_BASE - 2, 26, 2, J_BARRIGA, None, so=["corpo"])
    d.rect(43, 19, 18, 1, J_BARRIGA, None, so=["corpo"])
    garras += _perna_jacare(d, 36, passo, J_COR, "perna")
    garras += _perna_jacare(d, 18, -passo, J_COR, "perna")
    d.contorno({"corpo": J_ESC, "maxila": J_ESC, "perna": J_ESC, "perna_longe": J_ESC, "boca": hexc("7a1f1f")},
               juntas=[("maxila", "corpo"), ("perna", "corpo"), ("maxila", "boca")])
    cv = d.cv
    part = cv.part

    def pinta(x, y):
        if 0 <= x < J_W and 0 <= y < J_H and cv.px[y][x] is not None and part[y][x] in ("boca", "corpo"):
            cv.px[y][x] = J_DENTE
    # dentes presos na borda real de cada mandibula (acompanham a boca em qualquer abertura)
    for tx in range(46, 61, 3):
        for y in range(J_H - 1, -1, -1):  # de cima: pendem da beirada de baixo da maxila
            if part[y][tx] == "maxila":
                pinta(tx, y + 1)
                pinta(tx + 1, y + 1)
                pinta(tx, y + 2)
                break
        if abre:  # de baixo: nascem da beirada de cima da mandibula
            for y in range(1, J_H):
                if part[y][tx + 1] == "corpo" and part[y - 1][tx + 1] == "boca":
                    pinta(tx + 1, y - 1)
                    pinta(tx + 2, y - 1)
                    pinta(tx + 2, y - 2)
                    break
    for (x, y) in garras:
        if 0 <= x < J_W and 0 <= y < J_H and cv.px[y][x] not in (None, J_ESC):
            cv.px[y][x] = J_BARRIGA
    ex, ey = gira([(46, 9)], cx, cy, -abre)[0]
    d.rect(int(ex), int(ey), 2, 2, J_OLHO)
    d.rect(int(ex) + 1, int(ey), 1, 2, OLHO)
    return cv


# ------------------------------------------------------------------ aves de rapina
# Quadradas como o pato: corpo e cabeca sao blocos de cantos arredondados, e a asa e um bloco
# com as penas da ponta em "dedos" (degraus). Nada e girado: cada pose da asa e desenhada em
# retangulos, entao as bordas ficam retas e limpas.
ESC_AVE = hexc("4a2a14")
G_CORPO, G_ASA, G_ASA_LONGE, G_PEITO = hexc("b9743a"), hexc("8a5226"), hexc("6e3f1c"), hexc("f0dcb4")
A_CORPO, A_ASA, A_ASA_LONGE, A_BRANCO = hexc("6e4424"), hexc("4a2c14"), hexc("3a2210"), hexc("ffffff")
BICO, BICO_ESC, CINZA = hexc("ffd23f"), hexc("8a5a00"), hexc("636363")

# poses da asa em retangulos (x, y, w, h) relativos ao ombro, ave olhando para a direita.
# A asa e uma escada: larga no ombro, afinando ate a ponta, e as penas da ponta sao "dedos"
# de 2 px separados por 1 px. Nas diagonais os degraus seguem a direcao da asa (nada de
# tabua reta atravessando o corpo).
ASA_POSES = {
    "cima": [(-6, -9, 9, 10), (-8, -13, 7, 5),
             (-9, -16, 2, 4), (-6, -17, 2, 5), (-3, -16, 2, 4)],
    "meia": [(-5, -5, 9, 7), (-10, -8, 7, 5), (-14, -11, 6, 4),
             (-17, -14, 2, 4), (-15, -15, 2, 4), (-19, -12, 2, 3)],
    "meia_baixa": [(-5, -2, 9, 6), (-10, 1, 7, 5), (-14, 4, 6, 4),
                   (-17, 6, 2, 4), (-15, 7, 2, 4), (-19, 5, 2, 3)],
    "baixo": [(-6, -1, 9, 9), (-8, 6, 7, 5),
              (-9, 10, 2, 4), (-6, 11, 2, 5), (-3, 10, 2, 4)],
    "fechada": [(-6, -4, 9, 6), (-12, -3, 7, 5), (-17, -2, 6, 3), (-21, -1, 5, 2)],
}
# batida em 6 quadros: cima, meio subindo, meio descendo, embaixo e volta
ASA_CICLO = ["cima", "meia", "meia_baixa", "baixo", "meia_baixa", "meia"]


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
    ox, oy = n(24), n(18)  # ombro
    baixa = n(2) if ataque else 0  # no ataque a cabeca desce

    def asa_rects(dx, dy, kk):
        out = []
        for (x, y, w, h) in ASA_POSES[nome]:
            out.append((ox + dx + x * kk * env, oy + dy + y * kk, w * kk * env, h * kk))
        return out
    # asa de longe: a mesma pose, mais escura, 3 px a frente e 2 acima (aparece atras do corpo)
    for (x, y, w, h) in asa_rects(n(3), -n(2), k * 0.9):
        d.rect(round(x), round(y), max(2, round(w)), max(2, round(h)), asa_longe, "asa_longe")
    # cauda em leque: tres penas retas de comprimentos diferentes
    for i, (dy, comp) in enumerate(((-3, 10), (-1, 11), (1, 10))):
        _bloco(d, n(4 - comp + 9), n(19 + dy * 1.0), n(comp), n(2.4), cauda, "cauda")
    # corpo: bloco comprido arredondado; peito claro embaixo
    _bloco(d, n(11), n(13), n(19), n(12), corpo, "corpo", r=2)
    if peito is not None:
        _bloco(d, n(17), n(20), n(12), n(4), peito, None, r=1)
        for i in range(3):  # risquinhos do peito
            d.rect(n(19 + i * 3), n(21), 1, max(1, int(n(1.5))), corpo)
    # cabeca: bloco de topo reto, um pouco a frente e acima do corpo
    hx, hy = n(27), n(7) + baixa
    _bloco(d, hx, hy, n(10), n(10), cabeca, "cabeca", r=2)
    # bico em gancho: bloco amarelo com a ponta descendo, e a ponta escura
    _bloco(d, hx + n(9), hy + n(3), n(4), n(4), BICO, "bico", r=1)
    d.rect(hx + n(11), hy + n(6), max(2, int(n(2))), max(2, int(n(2.5))), BICO, "bico")
    # pernas: recolhidas no voo; no ataque esticadas para a frente com tres garras
    if ataque:
        for i in range(2):
            px = n(19 + i * 4)
            d.rect(px, n(24), max(2, int(n(2))), n(4), BICO, "pata")
            d.rect(px, n(27), n(6), max(2, int(n(2))), BICO, "pata")
    else:
        d.rect(n(17), n(24), n(6), max(2, int(n(2))), BICO, "pata")
    # asa de perto por cima de tudo
    for (x, y, w, h) in asa_rects(0, 0, k):
        d.rect(round(x), round(y), max(2, round(w)), max(2, round(h)), asa, "asa")
    esc_cab = ESC_AVE if cabeca != A_BRANCO else CINZA
    d.contorno({"corpo": ESC_AVE, "cabeca": esc_cab, "cauda": CINZA if cauda == A_BRANCO else ESC_AVE,
                "asa": hexc("2a1608"), "asa_longe": hexc("2a1608"), "bico": BICO_ESC, "pata": BICO_ESC},
               juntas=[("asa", "corpo"), ("cabeca", "corpo"), ("bico", "cabeca"), ("asa", "cauda"),
                       ("asa", "cabeca"), ("corpo", "cauda"), ("corpo", "asa_longe"), ("pata", "corpo"),
                       ("cabeca", "asa_longe")])
    # olho de ponto com a sobrancelha brava por cima; ponta escura do gancho; garras escuras
    e = 2
    d.rect(hx + n(5), hy + n(3.5), e, e, OLHO)
    d.rect(hx + n(3), hy + n(2), max(4, int(n(5))), 1, OLHO)
    d.rect(hx + n(11), hy + n(8), max(2, int(n(2))), 1, BICO_ESC)
    return d.cv


def gaviaozinho(pose):
    return ave(pose, 1.0, G_CORPO, G_ASA, G_ASA_LONGE, G_CORPO, G_ASA, peito=G_PEITO)


def aguia(pose):
    return ave(pose, 1.4, A_CORPO, A_ASA, A_ASA_LONGE, A_BRANCO, A_BRANCO, env=1.15)


# ------------------------------------------------------------------ saida
def tira(quadros):
    w, h = quadros[0].w, quadros[0].h
    cv = Canvas(w * len(quadros), h)
    for i, q in enumerate(quadros):
        cv.blit(q, i * w, 0)
    return cv


def pecas():
    return {
        "raposa": [raposa(i) for i in range(6)],
        "jacare": [jacare(i) for i in range(6)],
        "gaviaozinho": [gaviaozinho(i) for i in range(7)],
        "aguia": [aguia(i) for i in range(7)],
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
    save_gif(os.path.join(OUT, "raposa.gif"), p["raposa"], delay_cs=10, scale=6, bg=bg)
    save_gif(os.path.join(OUT, "gaviaozinho.gif"), p["gaviaozinho"][:6], delay_cs=9, scale=6, bg=bg)
    save_gif(os.path.join(OUT, "aguia.gif"), p["aguia"][:6], delay_cs=11, scale=6, bg=bg)
    save_gif(os.path.join(OUT, "jacare.gif"), [p["jacare"][i] for i in (0, 1, 2, 3, 0, 1, 2, 3, 4, 5, 5, 4)], delay_cs=14, scale=6, bg=bg)


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
