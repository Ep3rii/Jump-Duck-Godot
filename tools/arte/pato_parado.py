"""Gera o pato parado aprovado (assets/sprites/arte/pato_parado.png): o pato original dobrado
para a grade de 32, com contorno refeito em 1 px seguindo so as bordas, ampliado 4x (128x128).
Uso: python tools/arte/pato_parado.py  (as previas saem em tools/arte/saida/)
O bloco de grama aprovado e montado pelo tileset (ver ROTEIRO_FASES.md, Arte)."""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from pixelkit import Canvas, hexc  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "saida")
os.makedirs(OUT, exist_ok=True)

# quadro 0 do spr_playerAnima (32x32), copiado do arquivo original
DUCK_ORIG = [
    ".................OOO............",
    "................OWWWO...........",
    "...............OWWWWWO..........",
    "...............OWWWWWO..........",
    "...............OWOWOWOOO........",
    "...............OWWWWYYYYO.......",
    ".........OOOOOOOWWWWyyOO........",
    "........OWWWWWWWWWggOO..........",
    "........OWWWWWWWWWWWO...........",
    "........OWWWWWWWWWWWO...........",
    "........OWWWWWWWWWWWO...........",
    ".........OWWgWWWgWWWO...........",
    "..........OWWggggWWO............",
    "...........OOYYOYYO.............",
    "............OyYOyYO.............",
    "............OyYYyYYO............",
    ".............OOOOOO.............",
]
DUCK_COL = {"O": hexc("636363"), "W": hexc("ffffff"), "g": hexc("e2e2e2"),
            "Y": hexc("ffff00"), "y": hexc("fff200")}

# bloco 1,1 do spr_tileSetGrama01 (topo do chao grosso, meio), cores agrupadas
TILE_ORIG = [
    "aaaaaaaaaaaaaaaa",
    "bcbcbcbbcbcbcbcb",
    "ccccdedccdedcccc",
    "fccdghgifghgdccf",
    "cjccklmnimlkccjc",
    "copjnjincijnjpoc",
    "qroppsptnpspporq",
    "rrruurvwxvruurrr",
    "yyyyyyyyyyyyyyyy",
    "yyyyyyyyyyyyyyyy",
    "yyyyyyyyyyyyyyyy",
    "yyyyyyyyyyyyyyyy",
    "yyyyyyyyyyyyyyyy",
    "rrrrrrrrrrrrrrrr",
    "rrrrrrrrrrrrrrrr",
    "rrrrrrrrrrrrrrrr",
]
TILE_COL = {k: hexc(v) for k, v in {
    "a": "0a330a", "b": "31dc31", "c": "2ecf2e", "d": "47d246", "e": "cef0cb", "f": "3db93d",
    "g": "dee5c7", "h": "f28b57", "i": "28b228", "j": "2ba024", "k": "44be43", "l": "cae5c5",
    "m": "3ea83d", "n": "2bc32b", "o": "2eaa27", "p": "3a9925", "q": "40aa2a", "r": "d89d40",
    "s": "a29034", "t": "258f20", "u": "c78f3a", "v": "b79038", "w": "a08031", "x": "4a9728",
    "y": "e59f43"}.items()}


def smooth_edges(g, W, H):
    """Refina a silhueta ampliada: arredonda cantos de fora dos degraus de 2 px (tira o pixel
    da ponta) e preenche os dentes de dentro, para as curvas e diagonais virarem degraus de
    1 px. So mexe na borda de fora e preserva detalhes finos (bico, pes, olho)."""
    def full(x, y):
        return 0 <= x < W and 0 <= y < H and g[y][x] is not None
    out = [r[:] for r in g]
    for y in range(H):
        for x in range(W):
            for sx, sy in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
                if full(x, y):
                    # canto de fora: vazio dos dois lados e na diagonal; bloco cheio atras
                    if (not full(x + sx, y) and not full(x, y + sy) and not full(x + sx, y + sy)
                            and full(x - sx, y) and full(x, y - sy) and full(x - sx, y - sy)
                            and full(x - 2 * sx, y) and full(x, y - 2 * sy)
                            and g[y][x] in ("W", "g")
                            and not (sx < 0 and sy < 0 and x < 24)):  # ponta da cauda fica viva
                        out[y][x] = None
                else:
                    # dente de dentro: cheio dos dois lados e na diagonal; vazio atras
                    if (full(x + sx, y) and full(x, y + sy) and full(x + sx, y + sy)
                            and not full(x - sx, y) and not full(x, y - sy)
                            and g[y][x + sx] in ("W", "g") and g[y + sy][x] in ("W", "g")):
                        out[y][x] = g[y][x + sx]
    return out


def duck32():
    rows = [r.ljust(32, ".") for r in DUCK_ORIG]
    h, w = len(rows), 32

    def empty(x, y):
        return not (0 <= x < w and 0 <= y < h) or rows[y][x] == "."

    # miolo = tudo que nao e contorno de fora (o olho e as linhas internas ficam)
    H, W = h * 2, w * 2
    inner = [[None] * W for _ in range(H)]
    for y in range(h):
        for x in range(w):
            ch = rows[y][x]
            if ch == ".":
                continue
            # contorno de fora = encosta no vazio, inclusive na diagonal (os cantos de dentro
            # so encostam pela diagonal; antes eles viravam bolinhas 2x2 de contorno)
            outer = ch == "O" and any(empty(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1))
            if not outer:
                for dy in (0, 1):
                    for dx in (0, 1):
                        inner[y * 2 + dy][x * 2 + dx] = ch
    inner = smooth_edges(inner, W, H)
    # contorno novo de 1 px em volta do miolo ampliado
    out = [r[:] for r in inner]
    for y in range(H):
        for x in range(W):
            if inner[y][x] is None:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and inner[ny][nx] is not None:
                        out[y][x] = "O"
                        break
    ys = [y for y in range(H) if any(out[y])]
    xs = [x for x in range(W) if any(out[y][x] for y in range(H))]
    y0, y1, x0, x1 = min(ys), max(ys), min(xs), max(xs)
    cv = Canvas(32, 32)
    oy = 31 - (y1 - y0)
    ox = (32 - (x1 - x0 + 1)) // 2
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            ch = out[y][x]
            if ch:
                cv.set(ox + x - x0, oy + y - y0, DUCK_COL[ch])
    print("pato:", x1 - x0 + 1, "x", y1 - y0 + 1, "na grade 32")
    return cv


BORDA_SUAVE = hexc("1d6b22")  # verde-escuro mais suave que o #0a330a original


def tile32():
    cv = Canvas(32, 32)
    for y, row in enumerate(TILE_ORIG):
        for x, ch in enumerate(row):
            for dy in (0, 1):
                for dx in (0, 1):
                    cv.set(x * 2 + dx, y * 2 + dy, TILE_COL[ch])
    # borda de cima com 1 pixel (como o contorno do pato) e cor mais suave; a linha de baixo
    # dela vira grama clara
    for x in range(32):
        cv.set(x, 0, BORDA_SUAVE)
        cv.set(x, 1, TILE_COL["b"] if (x // 2) % 2 == 0 else TILE_COL["c"])
    return cv


def upscale(src, f):
    out = Canvas(src.w * f, src.h * f)
    out.blit(src, 0, 0, f)
    return out


def main():
    duck = upscale(duck32(), 4)
    tile = upscale(tile32(), 4)
    duck.save(os.path.join(OUT, "v5_pato_parado.png"))
    tile.save(os.path.join(OUT, "v5_bloco_grama.png"))
    for name, img in (("v5_pato_parado_2x.png", duck), ("v5_bloco_grama_2x.png", tile)):
        big = Canvas(256, 256)
        big.blit(img, 0, 0, 2)
        big.save(os.path.join(OUT, name))
    scene = Canvas(640, 360)
    top, bot = hexc("5aaef0"), hexc("bfe4fa")
    for y in range(360):
        t = y / 360
        c = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)) + (255,)
        for x in range(640):
            scene.px[y][x] = c
    for i in range(5):
        scene.blit(tile, i * 128, 232)
    scene.blit(duck, 250, 232 - 124)
    scene.save(os.path.join(OUT, "v5_amostra_cena.png"))
    # zoom do pe apoiado na borda (regiao 240..400 x 180..260, ampliada 3x)
    z = Canvas(480, 240)
    for y in range(80):
        for x in range(160):
            c = scene.px[180 + y][240 + x]
            for yy in range(3):
                for xx in range(3):
                    z.px[y * 3 + yy][x * 3 + xx] = c
    z.save(os.path.join(OUT, "v5_zoom_pe_na_borda.png"))
    print("ok")


main()
