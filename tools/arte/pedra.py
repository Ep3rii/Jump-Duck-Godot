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


def main():
    blocos = todos()
    cena(blocos)
    atlas(blocos, 3).save(os.path.join(OUT, "pedra_blocos.png"))
    if "--salvar" in sys.argv:
        atlas(blocos, 4).save(os.path.join(ARTE, "tileset_pedra.png"))
        print("salvo: assets/sprites/arte/tileset_pedra.png")
    print("ok")


if __name__ == "__main__":
    main()
