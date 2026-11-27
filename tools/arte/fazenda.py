"""Pecas da fazenda desenhadas direto em pixels do jogo (1 px do arquivo = 1 px do jogo), so com
cores da Endesga 32 e contorno escuro de 1 px; luz vindo de cima/esquerda.
Cada peca e montada por CAMADAS (mapa de caracteres -> cores de preenchimento). O contorno de
cada camada sai sozinho em volta da silhueta (4-vizinhanca, como as pontas da cerca), entao uma
camada da frente sempre fica separada da de tras. O balanco do vento empurra 1 px as linhas de
cima de cada camada (cada uma com a sua fase, fora de fase com as vizinhas).
  plantacao_milho    16 quadros 32x32: 3 pes de milho com espigas balancando (cenario)
  plantacao_repolho  16 quadros 32x16: fileira de repolhos na terra arada (cenario)
  plantacao_cenoura  16 quadros 32x16: fileira de cenouras (rama verde e ombro laranja) (cenario)
  espantalho         16 quadros 24x32: espantalho com palha das mangas balancando (cenario)
  cerca_portao       16 quadros 16x48: portao de cerca que afunda no chao; 0 = fechado, 15 = aberto
  cerca_portao_alta  16 quadros 16x96: porteira alta (6 blocos) que afunda; 0 = fechada, 15 = aberta
  flor_unica         16 quadros 16x16: uma flor no cabo (o pato segura no final)
  buque_pequeno      16 quadros 16x16: 3 flores embrulhadas
  buque_grande       16 quadros 16x16: 7 flores com folhas, embrulho e laco
Origem das plantacoes e do espantalho: centro de baixo (a ultima linha encosta na grama).
Uso: python tools/arte/fazenda.py [--salvar]
  previa: tools/arte/saida/fazenda.png (folha ampliada) e tools/arte/saida/fazenda_<nome>.gif
  tiras 1:1: tools/arte/saida/fazenda/<nome>.png
  --salvar: grava as tiras em assets/sprites/arte/ (cenario/ para as plantacoes e o espantalho)"""
import math
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas, save_gif  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
ARTE = os.path.join(ROOT, "assets", "sprites", "arte")
CENARIO = os.path.join(ARTE, "cenario")
OUT = os.path.join(HERE, "saida")
OUT_TIRAS = os.path.join(OUT, "fazenda")
N = 16  # quadros por animacao (a exigencia e 15 ou mais)

PALETA = [
    "be4a2f", "d77643", "ead4aa", "e4a672", "b86f50", "733e39", "3e2731", "a22633",
    "e43b44", "f77622", "feae34", "fee761", "63c74d", "3e8948", "265c42", "193c3e",
    "124e89", "0099db", "2ce8f5", "ffffff", "c0cbdc", "8b9bb4", "5a6988", "3a4466",
    "262b44", "181425", "ff0044", "68386c", "b55088", "f6757a", "e8b796", "c28569"]


def c(h):
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


PAL = set(c(h) for h in PALETA)
assert all(len(h) == 6 for h in PALETA) and len(PAL) == 32

# ---------------------------------------------------------------- cores (todas da Endesga 32)
CONT = c("3e2731")                                  # contorno da madeira / tinta escura
MAD_L, MAD, MAD_S = c("c28569"), c("b86f50"), c("733e39")   # as mesmas da cerca
FOLHA_CONT = c("193c3e")                            # contorno das plantas (como a copa)
VERDE_L, VERDE, VERDE_E = c("63c74d"), c("3e8948"), c("265c42")
AMAR_L, AMAR, LARANJA = c("fee761"), c("feae34"), c("f77622")
CENOURA_C = c("be4a2f")
PALHA_L, PALHA = c("ead4aa"), c("e4a672")
TERRA_L, TERRA = c("b86f50"), c("733e39")
BRANCO, CINZA_L, CINZA = c("ffffff"), c("c0cbdc"), c("8b9bb4")
VERM_L, VERM, VERM_S = c("f6757a"), c("ff0044"), c("a22633")
ROSA_L, ROSA, ROSA_S = c("f6757a"), c("b55088"), c("68386c")
AZUL_L, AZUL, AZUL_S = c("2ce8f5"), c("0099db"), c("124e89")
PAPEL_L, PAPEL = c("e8b796"), c("c28569")
LACO_L, LACO = c("e43b44"), c("a22633")
CAMISA_L, CAMISA, CAMISA_S = c("0099db"), c("124e89"), c("262b44")


# ---------------------------------------------------------------- camadas
class Camada:
    """mapa: lista de strings (um caractere por pixel, '.' = vazio); cores: {char: cor}.
    (x, y) = canto de cima/esquerda no quadro. contorno: cor do contorno automatico (None = sem).
    fase: fase do balanco (0..1). dobra: as linhas do mapa ACIMA dela andam o balanco inteiro
    (as de baixo ficam paradas, presas ao chao). amp: px do balanco (1). base_aberta: nao fecha
    o contorno embaixo (a peca entra na terra / no embrulho)."""

    def __init__(self, mapa, cores, x, y, contorno=None, fase=None, dobra=None, amp=1,
                 base_aberta=False, sobe=None):
        self.mapa, self.cores, self.x, self.y = mapa, cores, x, y
        self.contorno, self.fase, self.dobra, self.amp = contorno, fase, dobra, amp
        self.base_aberta = base_aberta
        self.sobe = sobe          # fase de um sobe-e-desce de 1 px (cabecas de flor)

    def desvio(self, q, linha):
        dx = dy = 0
        if self.fase is not None and (self.dobra is None or linha < self.dobra):
            dx = round(self.amp * math.sin(2 * math.pi * (q / N + self.fase)))
        if self.sobe is not None:
            dy = 1 if math.sin(2 * math.pi * (q / N + self.sobe)) > 0.6 else 0
        return dx, dy

    def pinta(self, quadro, q):
        w, h = len(quadro[0]), len(quadro)
        cheio = {}
        for ly, row in enumerate(self.mapa):
            dx, dy = self.desvio(q, ly)
            for lx, ch in enumerate(row):
                if ch != "." and ch != " ":
                    cheio[(self.x + lx + dx, self.y + ly + dy)] = self.cores[ch]
        if self.contorno is not None:
            fundo_y = max(y for _, y in cheio) if cheio else 0
            borda = set()
            for (x, y) in cheio:
                for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    p = (x + ox, y + oy)
                    if p in cheio:
                        continue
                    if self.base_aberta and oy == 1 and y == fundo_y:
                        continue
                    borda.add(p)
            for (x, y) in borda:
                if 0 <= x < w and 0 <= y < h:
                    quadro[y][x] = self.contorno
        for (x, y), cor in cheio.items():
            if 0 <= x < w and 0 <= y < h:
                quadro[y][x] = cor


def vazio(w, h):
    return [[None] * w for _ in range(h)]


def monta(w, h, camadas, q):
    qd = vazio(w, h)
    for cam in camadas:
        if callable(cam):
            cam(qd, q)
        else:
            cam.pinta(qd, q)
    return qd


def anima(w, h, camadas):
    return [monta(w, h, camadas, q) for q in range(N)]


# ---------------------------------------------------------------- terra arada (repolho/cenoura)
def terra_arada(qd, q=0):
    """Leira de terra de 32x5 na base do quadro 32x16: topo claro, corpo escuro, sulcos."""
    w, h = len(qd[0]), len(qd)
    y0 = h - 5
    for y in range(y0, h):
        for x in range(w):
            qd[y][x] = TERRA
    for x in range(1, w - 1):
        qd[y0 + 1][x] = TERRA_L
    for x in range(w):           # contorno: topo e base; pontas arredondadas
        qd[y0][x] = CONT
        qd[h - 1][x] = CONT
    for y in range(y0, h):
        qd[y][0] = CONT
        qd[y][w - 1] = CONT
    qd[y0][0] = None
    qd[y0][w - 1] = None
    for x in (4, 5, 13, 14, 22, 23, 29):   # torroes (sulcos escuros na terra)
        qd[y0 + 3][x] = CONT
    for x in (9, 18, 26):
        qd[y0 + 2][x] = TERRA_L


# ---------------------------------------------------------------- milho
MILHO_CORES = {"L": VERDE_L, "M": VERDE, "D": VERDE_E, "Y": AMAR_L, "O": AMAR,
               "T": PALHA, "t": PALHA_L}
# Um pe de milho: talo de 2 px (claro/escuro), folhas largas de 2 tons saindo dos nos e
# caindo na ponta, espiga amarela com palha verde, pendao de palha no alto.
PE_MILHO = [
    "....tT.....",
    "...t.tT....",
    "....tT.....",
    "....LM.....",
    "....LM.....",
    "LL..LM.....",
    ".LLLLM.....",
    "..MMLM..LL.",
    "....LMLLLMM",
    "....LMMM..M",
    "....LM.....",
    "....LMYO...",
    "....LMYO...",
    ".LL.LMYO...",
    "L.LLLMLO...",
    "L..MLMLM...",
    "....LMM....",
    "....LM.LL..",
    "....LMLLML.",
    "....LMM..MM",
    "....LM....M",
    "....LM.....",
    ".LL.LM.....",
    "L.LLLM.....",
    "...MLM.....",
    "....LM.....",
    "....LM.....",
]


def _milho_pe(x, y, fase, espelha=False, corta=0):
    mapa = PE_MILHO[corta:]
    if espelha:
        mapa = [r[::-1] for r in mapa]
        # o talo continua claro a esquerda (luz da esquerda) depois de espelhar
        mapa = [r.replace("ML", "LM") for r in mapa]
    return Camada(mapa, MILHO_CORES, x, y, FOLHA_CONT, fase=fase, dobra=len(mapa) - 9,
                  base_aberta=True)


def plantacao_milho():
    W, H = 32, 32
    camadas = [
        _milho_pe(11, H - len(PE_MILHO) - 3, 0.30, espelha=True),         # o de tras, mais alto
        _milho_pe(0, H - len(PE_MILHO) + 2, 0.0, corta=2),
        _milho_pe(19, H - len(PE_MILHO) + 2, 0.55, corta=0),
    ]
    return anima(W, H, camadas)


# ---------------------------------------------------------------- repolho
REPOLHO_CORES = {"L": VERDE_L, "M": VERDE, "D": VERDE_E, "W": c("c0cbdc")}
# Cabeca redonda de folhas: miolo claro em cima/esquerda, folhas de fora mais escuras, nervura
REPOLHO = [
    "..LLLL...",
    ".LLLLLM..",
    "LLLMLLMM.",
    "LLMLLMMMD",
    "MLLLMMMDD",
    ".MMMMMDD.",
]
FOLHA_SOLTA_E = ["LL.", ".MM"]     # folha de fora que abre para o lado (balanca)
FOLHA_SOLTA_D = [".LL", "MM."]


def plantacao_repolho():
    W, H = 32, 16
    camadas = [terra_arada]
    for i, x in enumerate((1, 12, 22)):
        f = i * 0.33
        y = H - 5 - len(REPOLHO) + 2
        camadas.append(Camada(FOLHA_SOLTA_E, REPOLHO_CORES, x - 1, y + 2, FOLHA_CONT, fase=f))
        camadas.append(Camada(FOLHA_SOLTA_D, REPOLHO_CORES, x + 8, y + 2, FOLHA_CONT, fase=f + 0.5))
        camadas.append(Camada(REPOLHO, REPOLHO_CORES, x, y, FOLHA_CONT, fase=f, dobra=2,
                              base_aberta=True))
    return anima(W, H, camadas)


# ---------------------------------------------------------------- cenoura
CENOURA_CORES = {"L": VERDE_L, "M": VERDE, "O": LARANJA, "o": AMAR, "R": CENOURA_C}
# Rama em leque (3 talos de 1 px com folhinhas) e o ombro laranja saindo da terra
CENOURA = [
    ".L...L.",
    "LML.LML",
    ".L.L.L.",
    "..LML..",
    "...M...",
    "..oOO..",
    "..OOR..",
]


def plantacao_cenoura():
    W, H = 32, 16
    camadas = [terra_arada]
    for i, x in enumerate((1, 9, 17, 25)):
        y = H - 5 - len(CENOURA) + 2
        camadas.append(Camada(CENOURA, CENOURA_CORES, x, y, FOLHA_CONT, fase=i * 0.27,
                              dobra=4, base_aberta=True))
    return anima(W, H, camadas)


# ---------------------------------------------------------------- espantalho
ESP_CORES = {"W": MAD_L, "w": MAD, "s": MAD_S, "P": PALHA_L, "p": PALHA, "a": AMAR,
             "B": CAMISA_L, "b": CAMISA, "k": CAMISA_S, "R": VERM, "r": VERM_S,
             "H": c("d77643"), "h": c("be4a2f"), "E": CONT, "X": c("181425")}
# chapeu de palha, cabeca de saco com olhos de botao e boca costurada, camisa azul com remendo
ESP_CABECA = [
    "....pPPp....",
    "...pPPPPp...",
    "...pPPPPp...",
    ".hHHHHHHHHh.",
    "hhhhhhhhhhhh",
    "...PPPPPP...",
    "...PXPPXp...",
    "...PPPPPp...",
    "...PEpEpp...",
    "....pppp....",
]
ESP_CORPO = [
    ".....ss.....",
    "BBBBBBBbbbbb",
    "BBBBBBBbbbbk",
    "kbbbbbbbbbkk",
    "...BBRrbb...",
    "...BBrRbb...",
    "...Bbbbbk...",
    "...bbbbkk...",
    "....pPPp....",
]
ESP_POSTE = ["Ws", "Ws", "Ws", "Ws", "Ws", "Ws", "Ws", "Ws", "Ws", "Ws", "Ws", "Ws", "Ws"]
PALHA_MAO_E = ["Pp.", "pPp", ".p."]
PALHA_MAO_D = [".pP", "pPp", ".p."]


def espantalho():
    W, H = 24, 32
    x0 = 6
    camadas = [
        Camada(ESP_POSTE, ESP_CORES, x0 + 5, H - len(ESP_POSTE), CONT, base_aberta=True),
        Camada(PALHA_MAO_E, ESP_CORES, x0 - 3, 12, CONT, fase=0.0),
        Camada(PALHA_MAO_D, ESP_CORES, x0 + 12, 12, CONT, fase=0.5),
        Camada(ESP_CORPO, ESP_CORES, x0, 10, CONT),
        Camada(ESP_CABECA, ESP_CORES, x0, 1, CONT),
    ]
    return anima(W, H, camadas)


# ---------------------------------------------------------------- portao de cerca
PORTAO_W, PORTAO_H = 16, 48
# Altura visivel do portao (topo das ripas) em cada quadro: 0 = fechado, segura 1 quadro,
# afunda acelerando e some (15 = aberto, passagem livre).
PORTAO_ALTURAS = [46, 46, 45, 44, 42, 39, 35, 30, 25, 19, 13, 8, 4, 2, 1, 0]


def _portao_cheio():
    """Portao de cerca 16x46: 3 ripas de 4 px com ponta (a do meio mais alta), 3 travessas
    pregadas por cima e uma mao-francesa na diagonal entre as duas de baixo. Cores da cerca."""
    H = 46
    qd = vazio(PORTAO_W, H)
    # ripas: contorno, luz, meio, contorno; ponta de 2 px no alto
    for x0, topo in ((0, 2), (6, 0), (12, 2)):
        for y in range(topo, H):
            qd[y][x0] = CONT
            qd[y][x0 + 1] = MAD_L
            qd[y][x0 + 2] = MAD
            qd[y][x0 + 3] = CONT
        qd[topo][x0 + 1] = CONT
        qd[topo][x0 + 2] = CONT
        qd[topo][x0] = None
        qd[topo][x0 + 3] = None
        for y in range(topo + 1, H, 9):          # veio da madeira
            qd[min(H - 1, y + 4)][x0 + 2] = MAD_S
    # mao-francesa (diagonal de baixo-esq. para cima-dir.) entre a travessa do meio e a de baixo
    for i in range(12):
        x = 1 + i
        y = 33 - (i * 2) // 3 - 1
        for yy, cor in ((y - 1, CONT), (y, MAD), (y + 1, MAD_S), (y + 2, CONT)):
            if 0 <= yy < H:
                qd[yy][x] = cor
    # travessas: contorno, luz, meio, sombra, contorno (como as tabuas da cerca)
    for y0 in (7, 21, 35):
        for x in range(PORTAO_W):
            qd[y0][x] = CONT
            qd[y0 + 1][x] = MAD_L
            qd[y0 + 2][x] = MAD
            qd[y0 + 3][x] = MAD_S
            qd[y0 + 4][x] = CONT
            if y0 + 5 < H and qd[y0 + 5][x] in (MAD_L, MAD):
                qd[y0 + 5][x] = MAD_S            # sombra da travessa na ripa
        for x in (2, 8, 14):                      # pregos
            qd[y0 + 2][x] = CONT
    return qd


def cerca_portao():
    """Quadro q: o topo das ripas fica PORTAO_ALTURAS[q] px acima do chao; o que passa do chao
    (a base do portao) nao aparece, esta enterrado."""
    cheio = _portao_cheio()
    qs = []
    for q in range(N):
        h = PORTAO_ALTURAS[q]
        qd = vazio(PORTAO_W, PORTAO_H)
        for sy in range(len(cheio)):
            y = PORTAO_H - h + sy
            if 0 <= y < PORTAO_H:
                qd[y] = list(cheio[sy])
        qs.append(qd)
    return qs


# ---------------------------------------------------------------- porteira alta
# Porteira de 16x96 (6 blocos) que substitui a porta alta: 3 tabuas inteiras de cima a baixo com
# ponta (inteiras, sem emenda), 5 travessas pregadas e 2 maos-francesas em vaos alternados (o 2o
# e o 4o), para ler como UMA porteira e nao como cercas empilhadas. Mesmo sentido da cerca_portao: 0 = fechada,
# segura 1 quadro, afunda acelerando (easing quadratico) e o quadro 15 fica vazio.
ALTA_H = 96
ALTA_CHEIO = 94
ALTA_ALTURAS = [ALTA_CHEIO, ALTA_CHEIO] + [
    round(ALTA_CHEIO * (1 - ((q - 1) / 14) ** 2)) for q in range(2, 15)] + [0]
ALTA_TRAVESSAS = (8, 26, 44, 62, 80)


def _mao_francesa(qd, y_baixo, y_cima):
    """Diagonal de baixo-esq. (x=1) para cima-dir. (x=14) dentro de um vao, coluna a coluna
    (como a da cerca_portao): contorno, meio, sombra, contorno."""
    for i in range(12):
        x = 1 + i
        y = y_baixo - round(i * (y_baixo - y_cima) / 11)
        for yy, cor in ((y - 1, CONT), (y, MAD), (y + 1, MAD_S), (y + 2, CONT)):
            if 0 <= yy < len(qd):
                qd[yy][x] = cor


def _porteira_cheia():
    H = ALTA_CHEIO
    qd = vazio(PORTAO_W, H)
    for x0, topo in ((0, 2), (6, 0), (12, 2)):
        for y in range(topo, H):
            qd[y][x0] = CONT
            qd[y][x0 + 1] = MAD_L
            qd[y][x0 + 2] = MAD
            qd[y][x0 + 3] = CONT
        qd[topo][x0 + 1] = CONT
        qd[topo][x0 + 2] = CONT
        qd[topo][x0] = None
        qd[topo][x0 + 3] = None
        for y in range(topo + 5, H, 11):          # veio da madeira
            qd[y][x0 + 2] = MAD_S
    t = ALTA_TRAVESSAS
    _mao_francesa(qd, t[4] - 3, t[3] + 5)        # vao de baixo (travessas 4-5)
    _mao_francesa(qd, t[2] - 3, t[1] + 5)        # vao do meio de cima (travessas 2-3)
    for y0 in t:
        for x in range(PORTAO_W):
            qd[y0][x] = CONT
            qd[y0 + 1][x] = MAD_L
            qd[y0 + 2][x] = MAD
            qd[y0 + 3][x] = MAD_S
            qd[y0 + 4][x] = CONT
            if y0 + 5 < H and qd[y0 + 5][x] in (MAD_L, MAD):
                qd[y0 + 5][x] = MAD_S
        for x in (2, 8, 14):
            qd[y0 + 2][x] = CONT
    return qd


def cerca_portao_alta():
    cheio = _porteira_cheia()
    qs = []
    for q in range(N):
        h = ALTA_ALTURAS[q]
        qd = vazio(PORTAO_W, ALTA_H)
        for sy in range(len(cheio)):
            y = ALTA_H - h + sy
            if 0 <= y < ALTA_H:
                qd[y] = list(cheio[sy])
        qs.append(qd)
    return qs


# ---------------------------------------------------------------- flores e buques
# Cabeca de flor 4x4 (miolo 2x2) como a flor coletavel, em varias cores: cada camada tem
# contorno #3e2731 proprio, e as cabecas sobem/descem 1 px fora de fase.
def cabeca(cl, cm, cs, miolo=None):
    m = miolo or cm
    return ([".AB.", "ABCD", "ACDD", ".DD."],
            {"A": cl, "B": cm, "C": m, "D": cs})


def cabeca_peq(cl, cm, cs):
    return ([".A.", "ABC", ".C."], {"A": cl, "B": cm, "C": cs})


def flor_cam(tipo, x, y, fase, peq=False):
    cores = {"verm": (VERM_L, VERM, VERM_S), "amar": (AMAR_L, AMAR, LARANJA),
             "bran": (BRANCO, CINZA_L, CINZA), "rosa": (ROSA_L, ROSA, ROSA_S),
             "azul": (AZUL_L, AZUL, AZUL_S)}[tipo]
    if peq:
        mapa, cs = cabeca_peq(*cores)
    else:
        miolo = AMAR if tipo in ("bran", "azul", "rosa") else None
        mapa, cs = cabeca(*cores, miolo=miolo)
    return Camada(mapa, cs, x, y, CONT, fase=fase, amp=1, sobe=None)


VERDES = {"L": VERDE_L, "M": VERDE, "D": VERDE_E}


def brilho(qd, x, y, q, q0, dur=3):
    """Estrelinha de brilho (cruz de 3x3, miolo branco) aceso por dur quadros a partir de q0."""
    if not (q0 <= q < q0 + dur):
        return
    cores = {0: (CINZA_L, BRANCO), 1: (BRANCO, BRANCO)}.get(q - q0, (CINZA_L, CINZA_L))
    for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
        qd[y + dy][x + dx] = cores[0]
    qd[y][x] = cores[1]


def flor_unica():
    caule = Camada(["L", "M", "M", "LM", ".M", ".M", ".M"], VERDES, 7, 7, None, fase=0.0, dobra=3)
    folha = Camada(["LL.", ".MM"], VERDES, 4, 9, None, fase=0.15)
    flor = Camada([".AB.", "ABCD", "ACDD", ".DD."],
                  {"A": VERM_L, "B": VERM, "C": VERM, "D": VERM_S}, 6, 2, CONT, fase=0.0)
    return anima(16, 16, [caule, folha, flor, lambda qd, q: brilho(qd, 11, 2, q, 9)])


# Nos buques as flores NAO tem contorno proprio (com 7 cabecas o contorno de cada uma virava uma
# grade escura): ficam sobre um fundo de folhagem verde-escura e o contorno #3e2731 sai uma vez
# so em volta do buque inteiro (contorno_geral), como na silhueta das outras pecas.
CORES_FLOR = {"verm": (VERM_L, VERM, VERM_S), "amar": (AMAR_L, AMAR, LARANJA),
              "bran": (BRANCO, CINZA_L, CINZA), "rosa": (ROSA_L, ROSA, ROSA_S),
              "azul": (AZUL_L, AZUL, AZUL_S)}


def cabeca_solta(tipo, x, y, fase, botao=False):
    """Cabeca 4x4 sem contorno (luz em cima/esq., miolo amarelo nas claras); botao = 2x2."""
    cl, cm, cs = CORES_FLOR[tipo]
    if botao:
        return Camada(["AB", "BD"], {"A": cl, "B": cm, "D": cs}, x, y, None, fase=fase)
    miolo = AMAR if tipo in ("bran", "azul", "rosa") else cm
    return Camada([".AB.", "ABCD", "BCDD", ".DD."], {"A": cl, "B": cm, "C": miolo, "D": cs},
                  x, y, None, fase=fase)


def contorno_geral(qd, q=0):
    h, w = len(qd), len(qd[0])
    borda = [(x, y) for y in range(h) for x in range(w) if qd[y][x] is None and any(
        0 <= x + ox < w and 0 <= y + oy < h and qd[y + oy][x + ox] is not None
        for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
    for x, y in borda:
        qd[y][x] = CONT


EMB_CORES = {"K": PAPEL_L, "k": PAPEL}
LACO_CORES = {"X": LACO_L, "x": LACO}


def buque_pequeno():
    fundo = Camada(["..DDDDDD..", ".DDDDDDDD.", "LDDDDDDDDL", ".LMDDDDML.", "...DDDD..."],
                   VERDES, 3, 3, None, fase=0.25, dobra=2)
    emb = Camada(["KKKKKk", "KKKKkk", ".KKkk.", ".Kkk..", "..k..."], EMB_CORES, 5, 9)
    flores = [cabeca_solta("amar", 3, 3, 0.5), cabeca_solta("bran", 9, 3, 0.75),
              cabeca_solta("verm", 6, 1, 0.0)]
    return anima(16, 16, [fundo] + flores + [emb, contorno_geral,
                                              lambda qd, q: brilho(qd, 13, 2, q, 5)])


def buque_grande():
    fundo = Camada(["...DDDDDDDD...", ".DDDDDDDDDDDD.", "DDDDDDDDDDDDDD", "LDDDDDDDDDDDDL",
                    "LMDDDDDDDDDDML", ".LMDDDDDDDDML.", "..LMDDDDDDML..", "....DDDDDD...."],
                   VERDES, 1, 2, None)
    emb = Camada(["KKKKKKKk", ".KKKKKkk", "..KKKkk.", "..KKkk..", "...Kk..."], EMB_CORES, 4, 10)
    laco = Camada(["XX.XX", ".xXx."], LACO_CORES, 5, 10)
    flores = [cabeca_solta("verm", 2, 6, 0.4, botao=True), cabeca_solta("bran", 12, 6, 0.9, botao=True),
              cabeca_solta("rosa", 4, 5, 0.5), cabeca_solta("azul", 8, 5, 0.1),
              cabeca_solta("bran", 2, 2, 0.35), cabeca_solta("amar", 10, 2, 0.85),
              cabeca_solta("verm", 6, 1, 0.0)]
    return anima(16, 16, [fundo] + flores + [emb, laco, contorno_geral,
                                              lambda qd, q: brilho(qd, 14, 1, q, 3),
                                              lambda qd, q: brilho(qd, 1, 13, q, 11)])


# ---------------------------------------------------------------- saida
DESTINO = {  # onde o --salvar grava cada peca
    "plantacao_milho": CENARIO, "plantacao_repolho": CENARIO, "plantacao_cenoura": CENARIO,
    "espantalho": CENARIO, "cerca_portao": ARTE, "cerca_portao_alta": ARTE,
    "flor_unica": ARTE, "buque_pequeno": ARTE, "buque_grande": ARTE,
}


def pecas():
    return {
        "plantacao_milho": plantacao_milho(),
        "plantacao_repolho": plantacao_repolho(),
        "plantacao_cenoura": plantacao_cenoura(),
        "espantalho": espantalho(),
        "cerca_portao": cerca_portao(),
        "cerca_portao_alta": cerca_portao_alta(),
        "flor_unica": flor_unica(),
        "buque_pequeno": buque_pequeno(),
        "buque_grande": buque_grande(),
    }


def tira_img(qs):
    h, w = len(qs[0]), len(qs[0][0])
    im = Image.new("RGBA", (w * len(qs), h), (0, 0, 0, 0))
    for i, qd in enumerate(qs):
        for y in range(h):
            for x in range(w):
                if qd[y][x] is not None:
                    im.putpixel((i * w + x, y), qd[y][x])
    return im


def canvas(qd):
    cv = Canvas(len(qd[0]), len(qd))
    for y in range(cv.h):
        for x in range(cv.w):
            cv.px[y][x] = qd[y][x]
    return cv


def conferir(nome, qs):
    """Cor fora da paleta, alfa parcial e pixel solto (sem nenhum vizinho em 8-viz.)."""
    probs = []
    for i, qd in enumerate(qs):
        h, w = len(qd), len(qd[0])
        for y in range(h):
            for x in range(w):
                p = qd[y][x]
                if p is None:
                    continue
                if p not in PAL:
                    probs.append((i, x, y, "cor fora da paleta %r" % (p,)))
                viz = sum(1 for dx in (-1, 0, 1) for dy in (-1, 0, 1) if (dx or dy)
                          and 0 <= x + dx < w and 0 <= y + dy < h and qd[y + dy][x + dx] is not None)
                if viz == 0:
                    probs.append((i, x, y, "pixel solto"))
    for p in probs[:8]:
        print("AVISO", nome, p)
    return probs


def folha(p, S=5):
    """Folha de previa: cada peca numa linha, todos os quadros, sobre ceu e com a grama embaixo."""
    tiras = [(nome, tira_img(qs)) for nome, qs in p.items()]
    W = max(t.width for _, t in tiras) + 8
    H = sum(t.height + 8 for _, t in tiras) + 4
    im = Image.new("RGBA", (W, H), (118, 194, 246, 255))
    y = 4
    for _, t in tiras:
        im.alpha_composite(t, (4, y))
        for x in range(4, 4 + t.width):          # linha da grama (onde a peca apoia)
            im.putpixel((x, y + t.height), (99, 199, 77, 255))
        y += t.height + 8
    im.resize((W * S, H * S), Image.NEAREST).save(os.path.join(OUT, "fazenda.png"))


def detalhe(p, quadros=(0, 4, 8, 12), S=10):
    """Previa de perto: alguns quadros de cada peca lado a lado (para conferir pixel a pixel)."""
    linhas = []
    for nome, qs in p.items():
        sel = quadros if not nome.startswith("cerca_portao") else (0, 1, 6, 9, 12, 15)
        linhas.append(tira_img([qs[i] for i in sel]))
    W = max(t.width for t in linhas) + 4
    H = sum(t.height + 4 for t in linhas) + 2
    im = Image.new("RGBA", (W, H), (118, 194, 246, 255))
    y = 2
    for t in linhas:
        im.alpha_composite(t, (2, y))
        y += t.height + 4
    im.resize((W * S, H * S), Image.NEAREST).save(os.path.join(OUT, "fazenda_detalhe.png"))


def main():
    p = pecas()
    os.makedirs(OUT_TIRAS, exist_ok=True)
    total = 0
    for nome, qs in p.items():
        assert len(qs) >= 15, nome
        total += len(conferir(nome, qs))
        tira_img(qs).save(os.path.join(OUT_TIRAS, nome + ".png"))
        esc = 12 if len(qs[0][0]) <= 16 and len(qs[0]) <= 16 else 8
        save_gif(os.path.join(OUT, "fazenda_%s.gif" % nome), [canvas(q) for q in qs],
                 delay_cs=8, scale=esc, bg=(118, 194, 246))
        print("%-18s %2d quadros %dx%d" % (nome, len(qs), len(qs[0][0]), len(qs[0])))
    folha(p)
    detalhe(p)
    if "--salvar" in sys.argv:
        for nome, qs in p.items():
            os.makedirs(DESTINO[nome], exist_ok=True)
            tira_img(qs).save(os.path.join(DESTINO[nome], nome + ".png"))
        print("salvo:", ", ".join(sorted(p)))
    print("ok" if total == 0 else "%d avisos" % total)


if __name__ == "__main__":
    main()
