"""Gera o tileset de grama na categoria "plana crocante" a partir do original
(assets/sprites/spr_tileSetGrama01.png, 4x4 blocos de 16 px):
  1. dobra cada bloco (grade 32);
  2. afina a borda verde-escura para 1 px (tira a metade de dentro, que vira a cor vizinha)
     e troca a cor pela mais suave aprovada (#1d6b22);
  3. desfaz quadradinhos 2x2 de borda nos cantos;
  4. amplia 4x (blocos de 128) -> assets/sprites/arte/tileset_grama.png (com --salvar).
Uso: python tools/arte/tileset.py [--salvar]   (previas em tools/arte/saida/)"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas, load_png  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
SPR = os.path.join(ROOT, "assets", "sprites")
OUT = os.path.join(HERE, "saida")
ARTE = os.path.join(SPR, "arte")
os.makedirs(OUT, exist_ok=True)

BORDA_ORIG = (0x0a, 0x33, 0x0a)
BORDA_SUAVE = (0x1d, 0x6b, 0x22, 255)


def is_border(c):
    return c is not None and sum(abs(c[i] - BORDA_ORIG[i]) for i in range(3)) < 40


def tile16(sheet, tx, ty):
    t = Canvas(16, 16)
    for y in range(16):
        for x in range(16):
            t.px[y][x] = sheet.px[ty * 16 + y][tx * 16 + x]
    return t


def rebuild_tile(t):
    """Bloco original 16x16 -> grade 32 com a borda de 1 px e suave."""
    g = [[None] * 32 for _ in range(32)]
    for y in range(16):
        for x in range(16):
            c = t.px[y][x]
            for dy in (0, 1):
                for dx in (0, 1):
                    g[y * 2 + dy][x * 2 + dx] = c

    def get(x, y):
        return g[y][x] if 0 <= x < 32 and 0 <= y < 32 else None

    # metade de dentro da borda (borda com miolo de um lado e borda do outro) vira o miolo
    out = [r[:] for r in g]
    for y in range(32):
        for x in range(32):
            if not is_border(g[y][x]):
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                inner = get(x + dx, y + dy)
                behind = get(x - dx, y - dy)
                if inner is not None and not is_border(inner) and is_border(behind):
                    out[y][x] = inner
                    break
    g = out
    # quadradinhos 2x2 de borda (cantos): o pixel mais "de dentro" vira o miolo vizinho
    for _ in range(4):
        changed = False
        for y in range(31):
            for x in range(31):
                block = [(x, y), (x + 1, y), (x, y + 1), (x + 1, y + 1)]
                if not all(is_border(g[by][bx]) for bx, by in block):
                    continue
                best, best_n, best_c = None, -1, None
                for bx, by in block:
                    n = 0
                    col = None
                    for dx in (-1, 0, 1):
                        for dy in (-1, 0, 1):
                            c = get(bx + dx, by + dy)
                            if c is not None and not is_border(c):
                                n += 1
                                col = c
                    if n > best_n:
                        best, best_n, best_c = (bx, by), n, col
                if best and best_c is not None:
                    g[best[1]][best[0]] = best_c
                    changed = True
        if not changed:
            break
    cv = Canvas(32, 32)
    for y in range(32):
        for x in range(32):
            c = g[y][x]
            if c is None:
                continue
            cv.px[y][x] = BORDA_SUAVE if is_border(c) else (c[0], c[1], c[2], 255)
    return cv


def upscale(src, f):
    out = Canvas(src.w * f, src.h * f)
    out.blit(src, 0, 0, f)
    return out


def build():
    sheet = load_png(os.path.join(SPR, "spr_tileSetGrama01.png"))
    tiles = {}
    for ty in range(4):
        for tx in range(4):
            tiles[(tx, ty)] = upscale(rebuild_tile(tile16(sheet, tx, ty)), 4)
    return tiles


def sample_scene(tiles, scale_down=2):
    """Cena com todos os tipos de bloco: chao grosso com pontas e interior, plataforma fina,
    bloco sozinho. Cada bloco de 128 aparece com 128/scale_down px."""
    T = 128
    W, H = 12 * T, 6 * T
    sc = Canvas(W, H)
    top, bot = (0x5a, 0xae, 0xf0), (0xbf, 0xe4, 0xfa)
    for y in range(H):
        t = y / H
        c = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)) + (255,)
        for x in range(W):
            sc.px[y][x] = c

    def put(idx, cx, cy):
        sc.blit(tiles[(idx % 4, idx // 4)], cx * T, cy * T)
    # chao grosso: topo (4,5,5,5,6) + interior (12,13,13,13,14)
    for i, cx in enumerate(range(0, 5)):
        put(4 if i == 0 else (6 if i == 4 else 5), cx, 3)
        for cy in (4, 5):
            put(12 if i == 0 else (14 if i == 4 else 13), cx, cy)
    # plataforma fina (8,9,9,10) no ar
    for i, cx in enumerate(range(6, 10)):
        put(8 if i == 0 else (10 if i == 3 else 9), cx, 1)
    # bloco sozinho (7) e mais um chao a direita
    put(7, 11, 2)
    for i, cx in enumerate(range(7, 12)):
        put(4 if i == 0 else (6 if i == 4 else 5), cx, 4)
        put(12 if i == 0 else (14 if i == 4 else 13), cx, 5)
    small = Canvas(W // scale_down, H // scale_down)
    for y in range(small.h):
        for x in range(small.w):
            small.px[y][x] = sc.px[y * scale_down][x * scale_down]
    return small


def main():
    if not os.path.exists(os.path.join(SPR, "spr_tileSetGrama01.png")):
        # o original do GameMaker saiu do projeto; a folha final (4x9, 16x16) e gravada por
        # tileset_novos.py (python tools/arte/tileset_novos.py --salvar)
        print("spr_tileSetGrama01.png nao existe mais: use tools/arte/tileset_novos.py")
        return
    tiles = build()
    sheet = Canvas(512, 512)
    for (tx, ty), t in tiles.items():
        sheet.blit(t, tx * 128, ty * 128)
    sheet.save(os.path.join(OUT, "tileset_grama.png"))
    sample_scene(tiles).save(os.path.join(OUT, "tileset_cena.png"))
    if "--salvar" in sys.argv:
        sheet.save(os.path.join(ARTE, "tileset_grama.png"))
        print("salvo em assets/sprites/arte/tileset_grama.png")
    # confere: o bloco (1,1) gerado aqui e igual ao aprovado que esta no jogo?
    approved = load_png(os.path.join(ARTE, "tileset_grama.png"))
    diff = sum(1 for y in range(128) for x in range(128)
               if approved.px[128 + y][128 + x] != sheet.px[128 + y][128 + x])
    print("ok; diferencas no bloco (1,1) aprovado:", diff)


if __name__ == "__main__":
    main()
