"""Blocos novos do tileset de grama (incremental: os 16 atuais ficam como estao, linhas 0-3;
os novos entram nas linhas 4-8, numa folha 4x9 de blocos de 128).
Mesmo processo e paleta dos blocos aprovados (categoria "plana crocante")."""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas, load_png  # noqa: E402
import tileset as T  # noqa: E402

GRAMA = (0x2e, 0xcf, 0x2e, 255)
TERRA_BAIXA = (0xd8, 0x9d, 0x40, 255)
TERRA_SOMBRA = (0xc7, 0x8f, 0x3a, 255)
TERRA_ESCURA = (0xa0, 0x70, 0x2c, 255)
TERRA_CLARA = (0xf2, 0xb8, 0x60, 255)
WHITE = (255, 255, 255, 255)


def c32(sheet, idx):
    return T.rebuild_tile(T.tile16(sheet, idx % 4, idx // 4))


def copy(cv):
    out = Canvas(cv.w, cv.h)
    for y in range(cv.h):
        for x in range(cv.w):
            out.px[y][x] = cv.px[y][x]
    return out


def outlined(cv, pts, fill, line, light=None):
    """Pinta uma forma com contorno de 1 px na cor escura do material."""
    s = set(pts)
    for (x, y) in s:
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if (nx, ny) not in s and 0 <= nx < 32 and 0 <= ny < 32:
                cv.px[ny][nx] = line
    top = min(y for _, y in s)
    for (x, y) in s:
        cv.px[y][x] = light if (light and y == top) else fill


FLOWER_COLORS = [(0xce, 0xf0, 0xcb), (0xde, 0xe5, 0xc7), (0xf2, 0x8b, 0x57), (0xca, 0xe5, 0xc5)]
PETAL_COLORS = FLOWER_COLORS[:2] + FLOWER_COLORS[3:]


def _near(c, cols, tol=18):
    return c is not None and any(sum(abs(c[i] - k[i]) for i in range(3)) <= tol for k in cols)


def no_flowers(base):
    t = copy(base)
    for y in range(1, 14):
        for x in range(32):
            if _near(t.px[y][x], FLOWER_COLORS):
                t.px[y][x] = GRAMA
    return t


def yellow_flowers(base):
    t = copy(base)
    for y in range(1, 14):
        for x in range(32):
            if _near(t.px[y][x], PETAL_COLORS):
                t.px[y][x] = (0xff, 0xe0, 0x4a, 255)
    return t


def with_stone(base):
    t = no_flowers(base)
    pts = [(x, y) for y in range(5, 9) for x in range(17, 24)
           if not ((x in (17, 23)) and (y in (5, 8)))]
    outlined(t, pts, (0xb8, 0xb0, 0xa0, 255), (0x5e, 0x5a, 0x50, 255), (0xd8, 0xd2, 0xc4, 255))
    return t


def with_mushroom(base):
    t = no_flowers(base)
    stem = [(x, y) for y in range(6, 10) for x in (12, 13)]
    outlined(t, stem, (0xf3, 0xea, 0xd8, 255), (0x7a, 0x50, 0x3a, 255))
    cap = [(x, y) for y in range(2, 6) for x in range(9, 17)
           if not ((x in (9, 16)) and y in (2, 5)) and not (y == 2 and x in (10, 15))]
    outlined(t, cap, (0xe0, 0x4a, 0x3a, 255), (0x7a, 0x20, 0x20, 255), (0xf0, 0x70, 0x60, 255))
    for (x, y) in ((11, 3), (14, 4)):
        t.px[y][x] = WHITE
    return t


def dirt_stones(base):
    t = copy(base)
    for (x0, y0, w, h) in ((5, 12, 5, 3), (19, 21, 6, 4)):
        pts = [(x, y) for y in range(y0, y0 + h) for x in range(x0, x0 + w)
               if not ((x in (x0, x0 + w - 1)) and (y in (y0, y0 + h - 1)))]
        outlined(t, pts, (0xc9, 0xb7, 0x9a, 255), (0x8a, 0x6a, 0x3c, 255), (0xe2, 0xd3, 0xb8, 255))
    return t


def dirt_root(base):
    t = copy(base)
    x = 13
    for y in range(0, 17):
        t.px[y][x] = TERRA_ESCURA
        if y == 5:
            x += 1
        if y == 11:
            x -= 1
    for (bx, by, d) in ((14, 7, 1), (12, 13, -1)):
        for k in range(3):
            t.px[by + k][bx + d * (k + 1)] = TERRA_ESCURA
    return t


def dirt_layer(base):
    t = copy(base)
    for x in range(32):
        t.px[18][x] = TERRA_BAIXA
        t.px[19][x] = TERRA_SOMBRA
        if x % 6 == 2:
            t.px[17][x] = TERRA_SOMBRA
    return t


def dirt_dots(base):
    t = copy(base)
    for (x, y) in ((6, 6), (21, 9), (11, 18), (26, 24), (4, 27), (16, 29)):
        t.px[y][x] = TERRA_SOMBRA
        t.px[y][x + 1] = TERRA_SOMBRA
        t.px[y - 1][x] = TERRA_CLARA
    return t


def mirror(cv):
    out = Canvas(32, 32)
    for y in range(32):
        for x in range(32):
            out.px[y][x] = cv.px[y][31 - x]
    return out


def halves(left, right):
    out = Canvas(32, 32)
    for y in range(32):
        for x in range(32):
            out.px[y][x] = left.px[y][x] if x < 16 else right.px[y][x]
    return out


def bottom_from(cv, src, rows=10):
    """Troca as ultimas linhas de cv pelas de src (base reta com faixa escura e borda)."""
    out = copy(cv)
    for y in range(32 - rows, 32):
        for x in range(32):
            out.px[y][x] = src.px[y][x]
    return out


WOOD = (0xa8, 0x68, 0x34, 255)
WOOD_LIGHT = (0xc8, 0x84, 0x48, 255)
WOOD_DARK = (0x7a, 0x48, 0x22, 255)
WOOD_LINE = (0x4a, 0x2a, 0x14, 255)
RING = (0xe8, 0xc0, 0x80, 255)
RING_DARK = (0xc0, 0x8c, 0x50, 255)


def log_tile(kind):
    """Tronco deitado (plataforma): meio, ponta esquerda ou direita com o corte e os aneis."""
    t = Canvas(32, 32)
    pts = []
    for y in range(1, 13):
        for x in range(32):
            if kind == "esq" and (x < 1 or (x < 4 and (y < 3 or y > 10))):
                continue
            if kind == "dir" and (x > 30 or (x > 27 and (y < 3 or y > 10))):
                continue
            pts.append((x, y))
    s = set(pts)
    for (x, y) in s:
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if (nx, ny) not in s and 0 <= nx < 32 and 0 <= ny < 32:
                t.px[ny][nx] = WOOD_LINE
    for (x, y) in s:
        t.px[y][x] = WOOD_LIGHT if y <= 3 else (WOOD_DARK if y >= 10 else WOOD)
    if kind == "meio":  # sem contorno nas laterais (emenda com o vizinho)
        for y in range(1, 13):
            t.px[y][0] = WOOD_LIGHT if y <= 3 else (WOOD_DARK if y >= 10 else WOOD)
            t.px[y][31] = t.px[y][0]
    for (x0, y0, ln) in ((4, 6, 7), (17, 8, 9), (26, 5, 4)):  # riscos da casca
        for k in range(ln):
            if 0 <= x0 + k < 32 and (x0 + k, y0) in s:
                t.px[y0][x0 + k] = WOOD_DARK
    if kind in ("esq", "dir"):
        cx = 5 if kind == "esq" else 26
        for y in range(2, 12):
            for x in range(cx - 4, cx + 5):
                d = ((x - cx) / 4.2) ** 2 + ((y - 6.5) / 5.0) ** 2
                if d <= 1.0 and 0 <= x < 32:
                    t.px[y][x] = RING if d < 0.25 or 0.5 < d < 0.75 else RING_DARK
        t.px[6][cx] = WOOD_DARK
    return t


def bridge_tile():
    """Ponte de tabuas (repete na horizontal): tabuas com frestas, pregos e corda embaixo."""
    t = Canvas(32, 32)
    for y in range(1, 9):
        for x in range(32):
            t.px[y][x] = WOOD_LIGHT if y == 1 else WOOD
    for x in range(32):
        t.px[0][x] = WOOD_LINE
        t.px[9][x] = WOOD_LINE
        t.px[8][x] = WOOD_DARK
    for x in (7, 15, 23, 31):
        for y in range(1, 9):
            t.px[y][x] = WOOD_LINE
    for x in (3, 11, 19, 27):
        t.px[4][x] = WOOD_LINE
    for x in range(32):
        y = 12 + (1 if 8 <= (x % 16) <= 12 else 0)
        t.px[y][x] = (0x8a, 0x6a, 0x3c, 255)
    return t


NEW_TILES = [
    # linha 4 (indices 16-19): variacoes do topo (no lugar do 5)
    ("topo sem flores", lambda s: no_flowers(c32(s, 5))),
    ("topo flores amarelas", lambda s: yellow_flowers(c32(s, 5))),
    ("topo pedrinha", lambda s: with_stone(c32(s, 5))),
    ("topo cogumelo", lambda s: with_mushroom(c32(s, 5))),
    # linha 5 (20-23): variacoes da terra (no lugar do 13)
    ("terra pedrinhas", lambda s: dirt_stones(c32(s, 13))),
    ("terra raiz", lambda s: dirt_root(c32(s, 13))),
    ("terra camada", lambda s: dirt_layer(c32(s, 13))),
    ("terra pontinhos", lambda s: dirt_dots(c32(s, 13))),
    # linha 6 (24-27): canto interno (lado direito) e coluna de 1 bloco
    ("canto interno dir", lambda s: mirror(c32(s, 11))),
    ("coluna topo", lambda s: halves(c32(s, 4), c32(s, 6))),
    ("coluna meio", lambda s: halves(c32(s, 12), c32(s, 14))),
    ("coluna base", lambda s: bottom_from(halves(c32(s, 12), c32(s, 14)), halves(c32(s, 1), c32(s, 3)))),
    # linha 7 (28-31): teto de terra (fundo exposto) e bloquinho sozinho de base reta
    ("teto esq", lambda s: bottom_from(c32(s, 12), c32(s, 1))),
    ("teto meio", lambda s: bottom_from(c32(s, 13), c32(s, 2))),
    ("teto dir", lambda s: bottom_from(c32(s, 14), c32(s, 3))),
    ("bloco sozinho", lambda s: halves(c32(s, 1), c32(s, 3))),
    # linha 8 (32-35): plataformas novas
    ("tronco esq", lambda s: log_tile("esq")),
    ("tronco meio", lambda s: log_tile("meio")),
    ("tronco dir", lambda s: log_tile("dir")),
    ("ponte", lambda s: bridge_tile()),
]


def build_full():
    sheet = load_png(os.path.join(T.SPR, "spr_tileSetGrama01.png"))
    tiles = T.build()
    for i, (_name, fn) in enumerate(NEW_TILES):
        tiles[(i % 4, 4 + i // 4)] = T.upscale(fn(sheet), 4)
    return tiles


def preview_new(tiles):
    cv = Canvas(4 * 136, 5 * 136)
    for y in range(cv.h):
        for x in range(cv.w):
            cv.px[y][x] = (200, 220, 235, 255)
    for (tx, ty), t in tiles.items():
        if ty >= 4:
            cv.blit(t, tx * 136 + 4, (ty - 4) * 136 + 4)
    cv.save(os.path.join(T.OUT, "tileset_novos.png"))


if __name__ == "__main__":
    tl = build_full()
    preview_new(tl)
    print("ok", len(tl))
