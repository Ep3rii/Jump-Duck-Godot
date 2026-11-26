"""Tileset de pedra da torre na base de estilo (tools/arte/estilo.py), com os MESMOS 36 blocos e
indices do tileset de grama (4x9 blocos de 128): assim o auto-tile do jogo (Level._retile_grass)
serve para os dois. Tijolos claros com fio de luz em cima, rejunte no tom de sombra, laje lisa no
topo, borda de 1 px e luz da esquerda (lado direito e base no tom de sombra).
Uso: python tools/arte/pedra.py [--salvar]   (previa em tools/arte/saida/pedra_cena.png)"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas, load_png, hexc  # noqa: E402
from estilo import P  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
ARTE = os.path.join(ROOT, "assets", "sprites", "arte")
OUT = os.path.join(HERE, "saida")
os.makedirs(OUT, exist_ok=True)

# pedra escura e suja (torre do gaviao): cinza-azulado fechado, rejunte quase preto
PEDRA, LUZ, SOMBRA, BORDA = hexc("767d96"), hexc("8f96ad"), hexc("5b617b"), hexc("20232f")
LAJE = hexc("838aa2")       # laje do topo (um pouco mais clara que o tijolo)
ESCURO = hexc("3a3e52")     # base e buracos
MUSGO, MUSGO_S = hexc("4f8a3c"), hexc("2f5a2c")
SUJO = hexc("636982")      # mancha de sujeira / umidade

# indice -> lados abertos (C = cima, B = baixo, E = esquerda, D = direita), como no auto-tile
LADOS = {7: "CBED", 8: "CBE", 9: "CB", 10: "CBD", 25: "CED", 4: "CE", 5: "C", 6: "CD",
         16: "C", 17: "C", 18: "C", 19: "C", 27: "BED", 28: "BE", 29: "B", 30: "BD", 26: "ED",
         12: "E", 14: "D", 11: "", 24: "", 13: "", 20: "", 21: "", 22: "", 23: "",
         0: "", 1: "", 2: "", 3: "", 15: "", 31: ""}


# Alvenaria medieval: pedras de tamanhos diferentes, cada uma com a quina de cima/esquerda
# clara e a de baixo/direita no tom de sombra (luz da esquerda), e rejunte escuro.
# (x, y, largura, altura) dentro do bloco de 32; o desenho emenda nos quatro lados.
PEDRAS = [(0, 0, 13, 11), (13, 0, 19, 11), (26, 11, 16, 10), (10, 11, 16, 10),
          (0, 21, 21, 11), (21, 21, 11, 11)]
PEDRA_B = hexc("6a708a")  # algumas pedras um tom abaixo


def tijolos():
    g = [[ESCURO] * 32 for _ in range(32)]
    for n, (x0, y0, w, h) in enumerate(PEDRAS):
        base = PEDRA_B if n in (1, 4) else PEDRA
        for y in range(y0, y0 + h - 1):
            for x in range(x0, x0 + w - 1):
                c = base
                if y == y0 or x == x0:
                    c = LUZ
                if y == y0 + h - 2 or x == x0 + w - 2:
                    c = SOMBRA
                g[y % 32][x % 32] = c
    # sujeira: manchas de umidade escorrendo e lascas nas pedras (sempre no miolo delas)
    for (x, y, h) in ((4, 2, 6), (5, 3, 4), (20, 13, 5), (21, 13, 7), (22, 14, 4), (8, 23, 6), (9, 24, 4), (27, 24, 5)):
        for j in range(h):
            if g[(y + j) % 32][x % 32] in (PEDRA, PEDRA_B):
                g[(y + j) % 32][x % 32] = SUJO
    for (x, y) in ((17, 4), (18, 4), (18, 5), (28, 7), (14, 16), (15, 16), (3, 15), (13, 27), (14, 27), (14, 28), (25, 29)):
        if g[y][x] in (PEDRA, PEDRA_B):
            g[y][x] = SOMBRA
    return g


def bloco(idx):
    lados = LADOS[idx]
    g = tijolos()
    C, B, E, D = "C" in lados, "B" in lados, "E" in lados, "D" in lados
    if C:  # fiada de pedras de capa no topo (duas por bloco), com a sombra delas embaixo
        for x in range(32):
            cx = x % 16
            g[0][x] = BORDA
            for y in range(1, 9):
                c = LAJE
                if y <= 2 or cx == 0:
                    c = LUZ
                if y == 8 or cx == 14:
                    c = SOMBRA
                if cx == 15:
                    c = ESCURO
                g[y][x] = c
            g[9][x] = ESCURO
            g[10][x] = ESCURO
        for (x, h) in ((6, 5), (7, 8), (8, 4), (19, 6), (20, 3), (27, 7)):  # escorrido da capa
            for y in range(11, 11 + h):
                if g[y][x] in (PEDRA, PEDRA_B, LUZ):
                    g[y][x] = SUJO
    if B:
        for x in range(32):
            g[29][x] = ESCURO
            g[30][x] = ESCURO
            g[31][x] = BORDA
    if E:
        for y in range(32):
            g[y][0] = BORDA
            if g[y][1] not in (BORDA,):
                g[y][1] = LUZ
    if D:
        for y in range(32):
            g[y][31] = BORDA
            for x in (29, 30):
                if g[y][x] != BORDA:
                    g[y][x] = ESCURO if (B and y >= 29) else SOMBRA
    if C:
        for x in range(32):
            g[0][x] = BORDA
    if B:
        for x in range(32):
            g[31][x] = BORDA
    # cantos de fora arredondados por 1 px
    for (cy, cx, a, b) in ((0, 0, C, E), (0, 31, C, D), (31, 0, B, E), (31, 31, B, D)):
        if a and b:
            g[cy][cx] = None
            g[cy + (1 if cy == 0 else -1)][cx + (1 if cx == 0 else -1)] = BORDA
    # canto interno (pe do degrau): a borda do piso de baixo encosta na parede
    if idx == 11:
        g[0][0] = BORDA
    if idx == 24:
        g[0][31] = BORDA
    variacao(g, idx)
    return g


def variacao(g, idx):
    def px(x, y, c):
        if 0 <= x < 32 and 0 <= y < 32 and g[y][x] is not None:
            g[y][x] = c
    if idx == 17:  # musgo pendurado na laje
        for x, h in ((5, 3), (6, 4), (7, 5), (8, 3), (9, 2), (20, 2), (21, 4), (22, 3)):
            for y in range(1, 1 + h + 2):
                px(x, y, MUSGO)
            px(x, 1 + h + 2, MUSGO_S)
        for x in (5, 6, 7, 8, 9, 20, 21, 22):
            px(x, 0, MUSGO_S)
    if idx == 18:  # laje rachada
        for x, y in ((14, 1), (14, 2), (15, 3), (15, 4), (16, 5), (15, 6), (15, 7), (14, 8), (14, 9), (13, 10), (13, 11), (12, 12)):
            px(x, y, BORDA)
    if idx == 19:  # pedrinhas soltas em cima (parte da laje)
        for x in (9, 10, 11, 23, 24):
            px(x, 1, SOMBRA)
        px(10, 2, SOMBRA)
    if idx == 20:  # tijolo rachado
        for x, y in ((12, 1), (13, 2), (13, 3), (14, 4), (13, 5), (13, 6), (12, 7), (12, 8), (13, 9), (14, 10),
                     (14, 11), (15, 12), (15, 13), (14, 14)):
            px(x, y, BORDA)
    if idx == 21:  # um tijolo mais escuro
        for y in range(1, 15):  # o tijolo inteiro de cima (31 x 14)
            for x in range(0, 31):
                px(x, y, hexc("555b74"))
        for x in range(0, 31):
            px(x, 1, PEDRA)
    if idx == 22:  # mancha de musgo num canto do tijolo
        for y, x0, x1 in ((9, 3, 9), (10, 2, 11), (11, 2, 12), (12, 3, 12), (13, 4, 10), (14, 5, 8)):
            for x in range(x0, x1 + 1):
                px(x, y, MUSGO)
        for x, y in ((10, 13), (11, 13), (12, 12), (9, 14), (8, 14), (12, 11)):
            px(x, y, MUSGO_S)
    if idx == 23:  # tijolo faltando (buraco escuro)
        for y in range(0, 15):  # o tijolo inteiro de cima
            for x in range(0, 31):
                px(x, y, ESCURO)
        for x in range(0, 31):
            px(x, 0, BORDA)
            px(x, 1, BORDA)
        for y in range(0, 15):
            px(0, y, BORDA)


def laje_solta(tipo):
    """Laje de meio bloco (linha 8 do tileset, colocada a mao): ponta esq., meio, ponta dir."""
    g = [[None] * 32 for _ in range(32)]
    for y in range(0, 14):
        for x in range(32):
            c = PEDRA
            if y == 0 or y == 13:
                c = BORDA
            elif y <= 2:
                c = LUZ
            elif y >= 10:
                c = SOMBRA
            g[y][x] = c
    for y in range(3, 10):
        g[y][15] = SOMBRA
    if tipo == "esq":
        for y in range(14):
            g[y][0] = BORDA
        g[0][0] = g[13][0] = None
        g[1][1] = g[12][1] = BORDA
    if tipo == "dir":
        for y in range(14):
            g[y][31] = BORDA
        g[0][31] = g[13][31] = None
        g[1][30] = g[12][30] = BORDA
    return g


def todos():
    blocos = {i: bloco(i) for i in LADOS}
    for i, t in ((32, "esq"), (33, "meio"), (34, "dir"), (35, "meio")):
        blocos[i] = laje_solta(t)
    return blocos


def atlas(blocos, escala):
    cv = Canvas(4 * 32 * escala, 9 * 32 * escala)
    for i, g in blocos.items():
        ox, oy = (i % 4) * 32 * escala, (i // 4) * 32 * escala
        for y in range(32):
            for x in range(32):
                c = g[y][x]
                if c is None:
                    continue
                for sy in range(escala):
                    for sx in range(escala):
                        cv.px[oy + y * escala + sy][ox + x * escala + sx] = c
    return cv


# ------------------------------------------------------------------ cena de previa
def indice(cheio, x, y, linhas):
    """Mesma regra de Level._grass_tile_for."""
    def tem(cx, cy):
        return cy >= linhas or (cx, cy) in cheio
    up, dn, lf, rt = tem(x, y - 1), tem(x, y + 1), tem(x - 1, y), tem(x + 1, y)
    h = abs((x * 73856093) ^ (y * 19349663)) % 100
    if not up:
        if not dn:
            return 7 if (not lf and not rt) else (8 if not lf else (10 if not rt else 9))
        if not lf and not rt:
            return 25
        if not lf:
            return 4
        if not rt:
            return 6
        return [16, 17, 18, 19][h % 4] if h < 35 else 5
    if not dn:
        return 27 if (not lf and not rt) else (28 if not lf else (30 if not rt else 29))
    if not lf and not rt:
        return 26
    if not lf:
        return 12
    if not rt:
        return 14
    if not tem(x - 1, y - 1):
        return 11
    if not tem(x + 1, y - 1):
        return 24
    h2 = abs((x * 73856093) ^ (y * 19349663) ^ (7 * 83492791)) % 100
    return [20, 21, 22, 23][h2 % 4] if h2 < 22 else 13


MAPA = [
    "#######......###########",
    "#.......................",
    "#.......................",
    "#.............###.......",
    "#.......................",
    "#...##..............#...",
    "#...................#...",
    "#.........#.....#####...",
    "#.........#.....#####...",
    "####......#...##########",
    "########..#...##########",
    "########################",
    "########################",
]


def cena(blocos):
    cols, linhas = len(MAPA[0]), len(MAPA)
    W, H = cols * 32, linhas * 32
    cv = Canvas(W, H)
    fundo = os.path.join(ARTE, "fundo")
    parede = load_png(os.path.join(fundo, "parede.png"))
    for y in range(0, H, 128):
        for x in range(0, W, 128):
            cv.blit(parede, x, y)
    cv.blit(load_png(os.path.join(fundo, "coluna.png")), 400, 32)
    cv.blit(load_png(os.path.join(fundo, "coluna.png")), 400, 160)
    jan = load_png(os.path.join(fundo, "janela.png"))
    for yy in range(70, 150):
        for xx in range(210, 258):
            cv.px[yy][xx] = hexc("273465")
    cv.blit(jan, 198, 52)
    tocha = load_png(os.path.join(fundo, "tocha.png"))
    for yy in range(64):
        for xx in range(32):
            c = tocha.px[yy][xx]
            if c is not None:
                cv.px[120 + yy][560 + xx] = c
    cheio = {(x, y) for y, row in enumerate(MAPA) for x, ch in enumerate(row) if ch == "#"}
    for (x, y) in cheio:
        g = blocos[indice(cheio, x, y, linhas)]
        for yy in range(32):
            for xx in range(32):
                if g[yy][xx] is not None:
                    cv.px[y * 32 + yy][x * 32 + xx] = g[yy][xx]
    for i, t in enumerate((32, 33, 34)):  # laje solta
        g = blocos[t]
        for yy in range(32):
            for xx in range(32):
                if g[yy][xx] is not None:
                    cv.px[6 * 32 + yy][(5 + i) * 32 + 16 + xx] = g[yy][xx]
    pato = load_png(os.path.join(ARTE, "pato_parado.png"))
    for (px0, py0) in ((9 * 32 - 96, 9 * 32 - 31), (17 * 32, 7 * 32 - 31)):
        for yy in range(32):
            for xx in range(32):
                c = pato.px[yy * 4 + 1][xx * 4 + 1]
                if c is not None:
                    cv.px[py0 + yy][px0 + xx] = c
    big = Canvas(W * 2, H * 2)
    big.blit(cv, 0, 0, 2)
    big.save(os.path.join(OUT, "pedra_cena.png"))


# ============================================================== versao final 16x16 (Endesga 32)
# A folha que esta no jogo (64x144, 1 px = 1 px do jogo) fica aqui em texto, pixel a pixel
# (editavel a mao). As funcoes acima geram outra variacao (pedras de tamanhos diferentes) que na
# reducao 16x16 ganha riscos azuis; por isso o --salvar grava ESTA folha, com as correcoes da
# revisao de 26/11/2026 aplicadas por corrige_pedra(): sem pixel claro solto no canto de cada
# bloco (a grade de pontinhos) e rachaduras em zigue-zague continuo.
LEGENDA_PEDRA = {
    ".": None,
    "a": "181425",  # contorno de fora do bloco
    "b": "265c42",  # musgo sombra
    "c": "3a4466",  # rejunte / rachadura / buraco
    "d": "3e8948",  # musgo
    "e": "5a6988",  # sombra da pedra (baixo/direita)
    "f": "8b9bb4",  # corpo da pedra
    "h": "c0cbdc",  # fio de luz (cima/esquerda)
}
# Na folha em texto acima, "e" e "f" ainda sao so "pedra" (tijolo / laje); corrige_pedra() troca
# isso pelo volume final (h luz, f corpo, e sombra). A parede de FUNDO da torre usa #262b44 e
# #3a4466, entao o chao jogavel fica claro (#8b9bb4) para se separar dela e do contorno do pato.
PEDRA16 = """
feeeeeceeeeeeeecfeeeeeceeeeeeeecfeeeeeceeeeeeeecfeeeeeceeeeeeeec
eeeeeeceeeeeeeeceeeeeeceeeeeeeeceeeeeeceeeeeeeeceeeeeeceeeeeeeec
eeeeeeceeeeeeeeceeeeeeceeeeeeeeceeeeeeceeeeeeeeceeeeeeceeeeeeeec
eeeeeeceeeeeeeeceeeeeeceeeeeeeeceeeeeeceeeeeeeeceeeeeeceeeeeeeec
eeeeeeceeeeeeeeceeeeeeceeeeeeeeceeeeeeceeeeeeeeceeeeeeceeeeeeeec
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
eeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceee
eeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceee
eeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceee
eeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceee
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
eeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeec
eeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeec
eeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeec
eeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeec
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
affffffcfffffffcfffffffcfffffffcfffffffcffffffeaaffffffcffffffea
affffffcfffffffcfffffffcfffffffcfffffffcffffffeaaffffffcffffffea
affffffcfffffffcfffffffcfffffffcfffffffcffffffeaaffffffcffffffea
accccccccccccccccccccccccccccccccccccccccccccceaacccccccccccccea
accccccccccccccccccccccccccccccccccccccccccccceaacccccccccccccea
aeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeaaeeeceeeeeeeceea
aeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeaaeeeceeeeeeeceea
aeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeaaeeeceeeeeeeceea
aeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeaaeeeceeeeeeeceea
accccccccccccccccccccccccccccccccccccccccccccceaacccccccccccccea
aeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeaaeeeeeeeeeceeeea
aeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeaaeeeeeeeeeceeeea
aeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeaaeeeeeeeeeceeeea
aeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeaacccccccccccccca
accccccccccccccccccccccccccccccccccccccccccccceaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaeeeeeceeeeeeeec
affffffcfffffffcfffffffcfffffffcfffffffcffffffeaeeeeeeceeeeeeeec
affffffcfffffffcfffffffcfffffffcfffffffcffffffeaeeeeeeceeeeeeeec
affffffcfffffffcfffffffcfffffffcfffffffcffffffeaeeeeeeceeeeeeeec
accccccccccccccccccccccccccccccccccccccccccccceaeeeeeeceeeeeeeec
accccccccccccccccccccccccccccccccccccccccccccceacccccccccccccccc
aeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeaeeeeceeeeeeeceee
aeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeaeeeeceeeeeeeceee
aeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeaeeeeceeeeeeeceee
aeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeaeeeeceeeeeeeceee
accccccccccccccccccccccccccccccccccccccccccccceacccccccccccccccc
aeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeaeeeeeeeeeeceeeec
aeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeaeeeeeeeeeeceeeec
aeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeaeeeeeeeeeeceeeec
accccccccccccccccccccccccccccccccccccccccccccccaeeeeeeeeeeceeeec
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccc
aeeeeeceeeeeeeecfeeeeeceeeeeeeecfeeeeeceeeeeeeeafeeeeeceeeeeeeec
aeeeeeceeeeeeeeceeeeeeceeeeeeeeceeeeeeceeeeeeeeaeeeeeeceeeeeeeec
aeeeeeceeeeeeeeceeeeeeceeeeeeeeceeeeeeceeeeeeeeaeeeeeeceeeeeeeec
aeeeeeceeeeeeeeceeeeeeceeeeeeeeceeeeeeceeeeeeeeaeeeeeeceeeeeeeec
aeeeeeceeeeeeeeceeeeeeceeeeeeeeceeeeeeceeeeeeeeaeeeeeeceeeeeeeec
accccccccccccccccccccccccccccccccccccccccccccceacccccccccccccccc
aeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeaeeeeceeeeeeeceee
aeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeaeeeeceeeeeeeceee
aeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeaeeeeceeeeeeeceee
aeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeaeeeeceeeeeeeceee
accccccccccccccccccccccccccccccccccccccccccccceacccccccccccccccc
aeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeaeeeeeeeeeeceeeec
aeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeaeeeeeeeeeeceeeec
aeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeaeeeeeeeeeeceeeec
aeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeaeeeeeeeeeeceeeec
accccccccccccccccccccccccccccccccccccccccccccceacccccccccccccccc
aaaaaaaaaaaaaaaaaaabbfaaaabaaaaaaaaaaaaaaaaaaaaaaaaaaafaaaaaaaaa
fffffffcfffffffcffdddffcffddfffcfffffffafffffffcfffffffcfffffffc
fffffffcfffffffcffdddffcffddfffcfffffffefffffffcfffffffcfffffffc
fffffffcfffffffcfffdfffcfffffffcfffffffafffffffcfffffffcfffffffc
cccccccccccccccccccccccccccccccccccccccacccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccaccccccccccccccccccccccccc
eeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeecfeeeeeeceeeeeeeceeeeeeeceee
eeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceee
eeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceee
eeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceee
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
eeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeec
eeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeec
eeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeec
eeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeec
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
feeeeefeeeeeeeeceeeeeeeeeeeeeeecfeeeeeceeeeeeeecaaaaaaaaaaaaaaaa
eeeeeeaeeeeeeeeceeeeeeeeeeeeeeeceeeeeeceeeeeeeecaccccccccccccccc
eeeeeeceeeeeeeeceeeeeeeeeeeeeeeceeeeeeceeeeeeeecaccccccccccccccc
eeeeeefeeeeeeeeceeeeeeeeeeeeeeeceeeeeeceeeeeeeecaccccccccccccccc
eeeeeeaeeeeeeeeceeeeeeeeeeeeeeeceedddeceeeeeeeecaccccccccccccccc
cccccccacfcccccceeeeeeeeeeeeeeeecdddddccccccccccaccccccccccccccc
eeeeceeaeeeeceeeeeeeeeeeeeeeeeeeeedddbeeeeeeceeeaccccccccccccccc
eeeeceeeeeeeceeeeeeeeeeeeeeeeeeeeeedbeeeeeeeceeeecccccccccccccce
eeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceee
eeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceee
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
eeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeec
eeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeec
eeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeec
eeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeec
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
feeeeeceeeeeeeeeaaaaaaaaaaaaaaaaaeeeeeceeeeeeeeaaeeeeeceeeeeeeea
eeeeeeceeeeeeeecaffffffcffffffeaaeeeeeceeeeeeeeaaeeeeeceeeeeeeea
eeeeeeceeeeeeeecaffffffcffffffeaaeeeeeceeeeeeeeaaeeeeeceeeeeeeea
eeeeeeceeeeeeeecaffffffcffffffeaaeeeeeceeeeeeeeaaeeeeeceeeeeeeea
eeeeeeceeeeeeeecaccccccccccccceaaeeeeeceeeeeeeeaaeeeeeceeeeeeeea
ccccccccccccccccaccccccccccccceaaccccccccccccceaacccccccccccccea
eeeeceeeeeeeceeeaeeeceeeeeeeceeaaeeeceeeeeeeceeaaeeeceeeeeeeceea
eeeeceeeeeeeceeeaeeeceeeeeeeceeaaeeeceeeeeeeceeaaeeeceeeeeeeceea
eeeeceeeeeeeceeeaeeeceeeeeeeceeaaeeeceeeeeeeceeaaeeeceeeeeeeceea
eeeeceeeeeeeceeeaeeeceeeeeeeceeaaeeeceeeeeeeceeaaeeeceeeeeeeceea
ccccccccccccccccaccccccccccccceaaccccccccccccceaacccccccccccccea
eeeeeeeeeeceeeecaeeeeeeeeeceeeeaaeeeeeeeeeceeeeaaeeeeeeeeeceeeea
eeeeeeeeeeceeeecaeeeeeeeeeceeeeaaeeeeeeeeeceeeeaaeeeeeeeeeceeeea
eeeeeeeeeeceeeecaeeeeeeeeeceeeeaaeeeeeeeeeceeeeaaeeeeeeeeeceeeea
eeeeeeeeeeceeeecaeeeeeeeeeceeeeaaeeeeeeeeeceeeeaacccccccccccccca
ccccccccccccccccaccccccccccccceaaccccccccccccceaaaaaaaaaaaaaaaaa
aeeeeeceeeeeeeecfeeeeeceeeeeeeecfeeeeeceeeeeeeeafeeeeeceeeeeeeec
aeeeeeceeeeeeeeceeeeeeceeeeeeeeceeeeeeceeeeeeeeaeeeeeeceeeeeeeec
aeeeeeceeeeeeeeceeeeeeceeeeeeeeceeeeeeceeeeeeeeaeeeeeeceeeeeeeec
aeeeeeceeeeeeeeceeeeeeceeeeeeeeceeeeeeceeeeeeeeaeeeeeeceeeeeeeec
aeeeeeceeeeeeeeceeeeeeceeeeeeeeceeeeeeceeeeeeeeaeeeeeeceeeeeeeec
accccccccccccccccccccccccccccccccccccccccccccceacccccccccccccccc
aeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeaeeeeceeeeeeeceee
aeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeaeeeeceeeeeeeceee
aeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeaeeeeceeeeeeeceee
aeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeeeeeeceeaeeeeceeeeeeeceee
accccccccccccccccccccccccccccccccccccccccccccceacccccccccccccccc
aeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeaeeeeeeeeeeceeeec
aeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeaeeeeeeeeeeceeeec
aeeeeeeeeeceeeeceeeeeeeeeeceeeeceeeeeeeeeeceeeeaeeeeeeeeeeceeeec
accccccccccccccccccccccccccccccccccccccccccccccaeeeeeeeeeeceeeec
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccc
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aeeeeeefeeeeeeeeeeeeeeefeeeeeeeeeeeeeeefeeeeeeeaeeeeeeefeeeeeeee
aeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaeeeeeeeeeeeeeeee
aeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaeeeeeeeeeeeeeeee
aeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaeeeeeeeeeeeeeeee
aeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaeeeeeeeeeeeeeeee
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
................................................................
................................................................
................................................................
................................................................
................................................................
................................................................
................................................................
................................................................
................................................................
""".split()


def corrige_pedra(linhas):
    """Correcoes da revisao na folha 16x16; devolve a lista de linhas de letras corrigida."""
    g = [list(r) for r in linhas]

    def bloco(idx):
        x0, y0 = (idx % 4) * 16, (idx // 4) * 16
        return [g[y0 + y][x0:x0 + 16] for y in range(16)]

    def poe(idx, t):
        x0, y0 = (idx % 4) * 16, (idx // 4) * 16
        for y in range(16):
            g[y0 + y][x0:x0 + 16] = t[y]
    # rachaduras: parte do bloco liso (laje 5 / tijolo 13) e desenha um zigue-zague de 4 px
    laje = bloco(5)
    for (x, y) in ((12, 1), (11, 2), (11, 3)):  # desce ate o rejunte da linha 4
        laje[y][x] = "g"  # marca provisoria: vira rejunte "c" depois do volume
    poe(18, laje)
    tij = bloco(13)
    for (x, y) in ((10, 1), (11, 2), (11, 3), (12, 4)):
        tij[y][x] = "g"  # marca provisoria: vira rejunte "c" depois do volume
    poe(20, tij)
    # variacoes 21-23 refeitas a partir do tijolo liso 13 (a folha em texto tinha sobras soltas)
    poe(21, bloco(13))  # tijolo mais escuro: escurecido depois do volume, logo abaixo
    musgo = bloco(13)
    for (x, y, ch) in ((2, 4, "d"), (3, 4, "d"), (4, 4, "d"), (1, 5, "d"), (2, 5, "d"), (3, 5, "d"),
                       (4, 5, "d"), (5, 5, "d"), (2, 6, "d"), (3, 6, "d"), (4, 6, "d"), (5, 6, "b"),
                       (3, 7, "d"), (4, 7, "b")):
        musgo[y][x] = ch
    poe(22, musgo)
    buraco = bloco(13)  # tijolo faltando: buraco no rejunte, sombra interna em cima/esquerda
    for y in range(0, 5):
        for x in range(7, 15):
            buraco[y][x] = "a" if (y == 0 or x == 7) else "c"
    poe(23, buraco)
    g[6 * 16][15] = "a"  # bloco 24: quina de contorno em (15,0), espelho da (0,0) do bloco 11
    # pixel claro solto (sobra do fio de luz que sumiu na reducao): vira a cor dos vizinhos
    H, W = len(g), len(g[0])
    for ty in range(H // 16):
        for tx in range(W // 16):
            x0, y0 = tx * 16, ty * 16
            for y in range(y0, y0 + 16):
                for x in range(x0, x0 + 16):
                    if g[y][x] != "f":
                        continue
                    viz = [g[yy][xx] for xx, yy in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1))
                           if x0 <= xx < x0 + 16 and y0 <= yy < y0 + 16]
                    esq = g[y][x - 1] if x > x0 else None
                    dir_ = g[y][x + 1] if x < x0 + 15 else None
                    if esq in ("a", "b") and dir_ in ("a", "b"):
                        g[y][x] = esq  # ponto claro no meio do contorno de cima
                    elif "f" not in viz:
                        conta = {}
                        for v in viz:
                            if v not in (".", "a"):
                                conta[v] = conta.get(v, 0) + 1
                        g[y][x] = max(conta, key=lambda v: (conta[v], v == "e")) if conta else "e"
    volume(g)
    # bloco 22: o musgo e so uma camada sobre o tijolo liso; fora dele vale o volume do bloco 13
    # (contar musgo como pedra apagava luz/sombra em volta e deixava pixels de corpo soltos)
    for y in range(16):
        for x in range(16):
            if g[5 * 16 + y][32 + x] not in ("d", "b"):
                g[5 * 16 + y][32 + x] = g[3 * 16 + y][16 + x]
    # bloco 21: o tijolo de cima a direita (x 7-14, y 0-4) um tom abaixo: luz #8b9bb4 em cima e
    # a esquerda, corpo #5a6988 e sombra de 1 px so na coluna da direita (embaixo fica corpo,
    # para o tijolo nao se fundir ao rejunte)
    for y in range(5):
        for x in range(7, 15):
            if x == 14 and y > 0:
                c = "c"
            elif y == 0 or x == 7:
                c = "f"
            else:
                c = "e"
            g[5 * 16 + y][16 + x] = c
    return ["".join(r) for r in g]


def volume(g):
    """Cada pedra (area de "e"/"f" cercada de rejunte) ganha fio de luz em cima/esquerda e sombra
    embaixo/direita. A vizinhanca e lida dentro do bloco de 16, com a emenda horizontal (o tijolo
    que sai pela direita continua na esquerda do bloco vizinho). Rachadura e musgo contam como
    pedra, para nao criarem luz/sombra em volta deles."""
    PEDRA_L = ("e", "f", "g", "d", "b")
    lajes = {(x, y) for y, r in enumerate(g) for x, ch in enumerate(r) if ch == "f"}
    H, W = len(g), len(g[0])
    src = [r[:] for r in g]
    for ty in range(H // 16):
        for tx in range(W // 16):
            x0, y0 = tx * 16, ty * 16

            def pedra(x, y):
                if not (y0 <= y < y0 + 16):
                    return False
                xx = x0 + (x - x0) % 16
                ch = src[y][xx]
                if xx != x and ch == "a":
                    # a emenda caiu no contorno do lado aberto do PROPRIO bloco: o vizinho real
                    # e o tijolo que continua, lido no bloco liso de miolo (13), mesma coluna
                    ch = src[48 + y - y0][16 + xx - x0]
                return ch in PEDRA_L
            for y in range(y0, y0 + 16):
                for x in range(x0, x0 + 16):
                    if src[y][x] not in ("e", "f"):
                        continue
                    if not pedra(x, y + 1):
                        c = "e"
                    elif not pedra(x, y - 1):
                        c = "h"
                    elif not pedra(x + 1, y):
                        c = "e"
                    elif not pedra(x - 1, y):
                        c = "h"
                    else:
                        c = "f"
                    if (x, y) in lajes and c == "f":
                        c = "h"  # laje do topo um tom acima do tijolo
                    g[y][x] = c
    for r in g:
        for x, ch in enumerate(r):
            if ch == "g":
                r[x] = "c"


def folha16():
    """Folha final 64x144 (Canvas em pixels do jogo, ja na Endesga 32)."""
    linhas = corrige_pedra(PEDRA16)
    cv = Canvas(len(linhas[0]), len(linhas))
    for y, r in enumerate(linhas):
        for x, ch in enumerate(r):
            c = LEGENDA_PEDRA[ch]
            if c is not None:
                cv.px[y][x] = hexc(c)
    return cv


def folha_para_salvar():
    """folha16() ampliada 8x (4x da grade de 32), o que o Canvas.save() espera para
    tileset_pedra: ele reduz 4x, o reduz2 so amostra e a paleta nao muda nada."""
    f = folha16()
    big = Canvas(f.w * 8, f.h * 8)
    big.blit(f, 0, 0, 8)
    return big


def blocos16():
    """Os 36 blocos da folha final na grade de 32 (para a cena de previa)."""
    f = folha16()
    out = {}
    for i in range(36):
        x0, y0 = (i % 4) * 16, (i // 4) * 16
        out[i] = [[f.px[y0 + y // 2][x0 + x // 2] for x in range(32)] for y in range(32)]
    return out


def pecas():
    """Para tools/arte/previa16.py: as duas folhas de tileset (grama e pedra) como o save()
    as receberia."""
    import tileset_novos
    return {"tileset_grama": tileset_novos.folha_para_salvar(), "tileset_pedra": folha_para_salvar()}


def main():
    blocos = blocos16()
    cena(blocos)
    atlas(blocos, 3).save(os.path.join(OUT, "pedra_blocos.png"))
    if "--salvar" in sys.argv:
        folha_para_salvar().save(os.path.join(ARTE, "tileset_pedra.png"))
        print("salvo: assets/sprites/arte/tileset_pedra.png")
    print("ok")


if __name__ == "__main__":
    main()
