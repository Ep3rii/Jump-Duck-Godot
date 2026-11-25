"""Cena de amostra do tileset completo, escolhendo os blocos com a mesma regra que o jogo vai
usar (auto-tile com variacoes por posicao, canto interno, coluna e teto de terra).
Uso: python tools/arte/tileset_cena.py"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas, load_png  # noqa: E402
import tileset as T  # noqa: E402
import tileset_novos as N  # noqa: E402

TOP_VARIANTS = [16, 17, 18, 19]
DIRT_VARIANTS = [20, 21, 22, 23]


def hash2(x, y, salt=0):
    return abs((x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)) % 100


def tile_for(cells, x, y, rows):
    """Mesma regra do jogo (scripts/level.gd): devolve o indice do bloco (linha*4 + coluna)."""
    def has(cx, cy):
        if cy >= rows:
            return True  # abaixo da sala conta como cheio
        return (cx, cy) in cells
    up, dn = has(x, y - 1), has(x, y + 1)
    lf, rt = has(x - 1, y), has(x + 1, y)
    if not up:
        if not dn:
            if not lf and not rt:
                return 7
            if not lf:
                return 8
            if not rt:
                return 10
            return 9
        if not lf and not rt:
            return 25
        if not lf:
            return 4
        if not rt:
            return 6
        h = hash2(x, y)
        return TOP_VARIANTS[h % 4] if h < 35 else 5
    if not dn:
        if not lf and not rt:
            return 27
        if not lf:
            return 28
        if not rt:
            return 30
        return 29
    if not lf and not rt:
        return 26
    if not lf:
        return 12
    if not rt:
        return 14
    if not has(x - 1, y - 1):
        return 11  # canto interno: a grama do chao mais baixo faz a curva
    if not has(x + 1, y - 1):
        return 24
    h = hash2(x, y, 7)
    return DIRT_VARIANTS[h % 4] if h < 22 else 13


def main():
    tiles = N.build_full()
    cols, rows = 24, 11
    cells = set()

    def rect(c0, r0, c1, r1):
        for cy in range(r0, r1 + 1):
            for cx in range(c0, c1 + 1):
                cells.add((cx, cy))
    rect(0, 7, 9, 10)        # chao
    rect(4, 5, 9, 6)         # degrau (canto interno no pe)
    rect(7, 3, 9, 4)         # outro degrau
    rect(12, 4, 12, 10)      # coluna de 1 bloco
    rect(15, 3, 20, 5)       # bloco suspenso (teto de terra embaixo)
    rect(15, 9, 23, 10)      # chao da direita
    rect(22, 6, 23, 8)       # degrau no chao da direita (canto interno do outro lado)
    T_ = 128
    sc = Canvas(cols * T_, rows * T_)
    top, bot = (0x5a, 0xae, 0xf0), (0xbf, 0xe4, 0xfa)
    for yy in range(sc.h):
        t = yy / sc.h
        c = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)) + (255,)
        for xx in range(sc.w):
            sc.px[yy][xx] = c
    for (cx, cy) in cells:
        idx = tile_for(cells, cx, cy, rows)
        sc.blit(tiles[(idx % 4, idx // 4)], cx * T_, cy * T_)
    # plataformas novas (colocadas a mao): tronco e ponte
    for i, cx in enumerate(range(1, 5)):
        idx = 32 if i == 0 else (34 if i == 3 else 33)
        sc.blit(tiles[(idx % 4, idx // 4)], cx * T_, 2 * T_)
    for cx in range(13, 15):
        sc.blit(tiles[(3, 8)], cx * T_, 7 * T_)
    small = Canvas(sc.w // 2, sc.h // 2)
    for yy in range(small.h):
        for xx in range(small.w):
            small.px[yy][xx] = sc.px[yy * 2][xx * 2]
    small.save(os.path.join(T.OUT, "tileset_cena_completa.png"))
    print("ok cena", small.w, small.h)


if __name__ == "__main__":
    main()
