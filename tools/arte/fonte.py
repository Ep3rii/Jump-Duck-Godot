"""Fonte pixel nova do jogo (categoria "plana crocante"): maiusculas de 7 px de altura, tracos
grossos e cantos arredondados, largura proporcional (I estreito, M largo) e acentos EM CIMA da
letra inteira (a letra acentuada tem o mesmo tamanho das outras).
Celula do atlas: 8 x 12 (3 linhas para o acento, 7 da letra, 2 abaixo para virgula e cedilha).
Uso: python tools/arte/fonte.py [--salvar]
  --salvar grava assets/sprites/arte/fonte.png e scripts/fonte_meta.gd (largura de cada letra)."""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(HERE, "saida")
os.makedirs(OUT, exist_ok=True)

CELL_W, CELL_H, TOP = 8, 12, 3  # TOP = linha da celula onde comeca a letra

G = {}


def g(ch, rows):
    """Glifo: lista de linhas ('#' = pixel). 7 linhas = so a letra; mais linhas = desce abaixo."""
    G[ch] = rows


g("A", [".###.", "##.##", "##.##", "#####", "##.##", "##.##", "##.##"])
g("B", ["####.", "##.##", "##.##", "####.", "##.##", "##.##", "####."])
g("C", [".####", "##...", "##...", "##...", "##...", "##...", ".####"])
g("D", ["####.", "##.##", "##.##", "##.##", "##.##", "##.##", "####."])
g("E", ["#####", "##...", "##...", "####.", "##...", "##...", "#####"])
g("F", ["#####", "##...", "##...", "####.", "##...", "##...", "##..."])
g("G", [".####", "##...", "##...", "##.##", "##.##", "##.##", ".####"])
g("H", ["##.##", "##.##", "##.##", "#####", "##.##", "##.##", "##.##"])
g("I", ["####", ".##.", ".##.", ".##.", ".##.", ".##.", "####"])
g("J", ["...##", "...##", "...##", "...##", "...##", "##.##", ".###."])
g("K", ["##.##", "##.##", "####.", "###..", "####.", "##.##", "##.##"])
g("L", ["##...", "##...", "##...", "##...", "##...", "##...", "#####"])
g("M", ["##...##", "###.###", "#######", "##.#.##", "##...##", "##...##", "##...##"])
g("N", ["##..##", "###.##", "######", "##.###", "##..##", "##..##", "##..##"])
g("O", [".####.", "##..##", "##..##", "##..##", "##..##", "##..##", ".####."])
g("P", ["####.", "##.##", "##.##", "####.", "##...", "##...", "##..."])
g("Q", [".####.", "##..##", "##..##", "##..##", "##..##", "##.##.", ".##.##"])
g("R", ["####.", "##.##", "##.##", "####.", "####.", "##.##", "##.##"])
g("S", [".####", "##...", "##...", ".###.", "...##", "...##", "####."])
g("T", ["######", "..##..", "..##..", "..##..", "..##..", "..##..", "..##.."])
g("U", ["##.##", "##.##", "##.##", "##.##", "##.##", "##.##", ".###."])
g("V", ["##.##", "##.##", "##.##", "##.##", ".###.", ".###.", "..#.."])
g("W", ["##...##", "##...##", "##...##", "##.#.##", "#######", "###.###", "##...##"])
g("X", ["##.##", "##.##", ".###.", "..#..", ".###.", "##.##", "##.##"])
g("Y", ["##..##", "##..##", ".####.", "..##..", "..##..", "..##..", "..##.."])
g("Z", ["#####", "...##", "..##.", ".##..", "##...", "##...", "#####"])
g("0", [".###.", "##.##", "##.##", "##.##", "##.##", "##.##", ".###."])
g("1", [".##.", "###.", ".##.", ".##.", ".##.", ".##.", "####"])
g("2", [".###.", "##.##", "...##", "..##.", ".##..", "##...", "#####"])
g("3", ["####.", "...##", "...##", ".###.", "...##", "...##", "####."])
g("4", ["##.##", "##.##", "##.##", "#####", "...##", "...##", "...##"])
g("5", ["#####", "##...", "####.", "...##", "...##", "##.##", ".###."])
g("6", [".###.", "##...", "####.", "##.##", "##.##", "##.##", ".###."])
g("7", ["#####", "...##", "...##", "..##.", "..##.", ".##..", ".##.."])
g("8", [".###.", "##.##", "##.##", ".###.", "##.##", "##.##", ".###."])
g("9", [".###.", "##.##", "##.##", "##.##", ".####", "...##", ".###."])
g(" ", ["...", "...", "...", "...", "...", "...", "..."])
g(".", ["..", "..", "..", "..", "..", "##", "##"])
g(",", ["..", "..", "..", "..", "..", "##", "##", "#."])
g(":", ["..", "##", "##", "..", "..", "##", "##"])
g("!", ["##", "##", "##", "##", "##", "..", "##"])
g("?", [".###.", "##.##", "...##", "..##.", "..##.", ".....", "..##."])
g("/", ["...##", "...##", "..##.", "..##.", ".##..", "##...", "##..."])
g("-", ["....", "....", "....", "####", "####", "....", "...."])
g("+", ["......", "..##..", "..##..", "######", "..##..", "..##..", "......"])
g("(", [".##", "##.", "##.", "##.", "##.", "##.", ".##"])
g(")", ["##.", ".##", ".##", ".##", ".##", ".##", "##."])
g("<", ["....", "..##", ".##.", "##..", ".##.", "..##", "...."])
g(">", ["....", "##..", ".##.", "..##", ".##.", "##..", "...."])
g("%", ["##..#", "##.##", "..##.", ".##..", "##.##", "#..##", "....."])
g("'", ["##", "##", "#.", "..", "..", "..", ".."])
g('"', ["##.##", "##.##", "#..#.", ".....", ".....", ".....", "....."])
g("=", ["....", "....", "####", "....", "####", "....", "...."])
g("*", [".....", "#.#.#", ".###.", "#####", ".###.", "#.#.#", "....."])

# acentos (3 linhas acima da letra; a de baixo fica vazia para nao grudar)
ACCENTS = {
    "agudo": ["...#.", "..#..", "....."],
    "grave": [".#...", "..#..", "....."],
    "circ": ["..#..", ".#.#.", "....."],
    "til": [".#.##", "##.#.", "....."],
}
COMPOSE = {
    "Á": ("A", "agudo"), "À": ("A", "grave"), "Â": ("A", "circ"), "Ã": ("A", "til"),
    "É": ("E", "agudo"), "Ê": ("E", "circ"), "Í": ("I", "agudo"),
    "Ó": ("O", "agudo"), "Ô": ("O", "circ"), "Õ": ("O", "til"), "Ú": ("U", "agudo"),
}
CEDILLA = ["..#..", ".##.."]  # embaixo do C


def glyph_bitmap(ch):
    """Devolve (linhas da celula 12 de altura, largura)."""
    base, acc, below = ch, None, None
    if ch in COMPOSE:
        base, acc = COMPOSE[ch]
    if ch == "Ç":
        base, below = "C", CEDILLA
    rows = G[base]
    w = max(len(r) for r in rows)
    cell = [["."] * w for _ in range(CELL_H)]
    for y, r in enumerate(rows):
        for x, c in enumerate(r):
            if c == "#":
                cell[TOP + y][x] = "#"
    if acc:
        a = ACCENTS[acc]
        off = (w - 5) // 2 if w >= 5 else 0
        for y, r in enumerate(a):
            for x, c in enumerate(r):
                xx = x + off if w >= 5 else x - 1
                if c == "#" and 0 <= xx < w:
                    cell[y][xx] = "#"
    if below:
        for y, r in enumerate(below):
            for x, c in enumerate(r):
                if c == "#":
                    cell[TOP + 7 + y][x] = "#"
    return ["".join(r) for r in cell], w


ORDER = list("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,:!?/-+()<>%'\"=*") + list("ÁÀÂÃÉÊÍÓÔÕÚÇ")


def render(text, scale=1, col=(255, 255, 255, 255), shadow=None):
    """Canvas com o texto (para as amostras)."""
    text = text.upper()
    w = sum(glyph_bitmap(c)[1] + 1 for c in text if c in ORDER or c in G)
    cv = Canvas(max(1, w * scale + scale), (CELL_H + 1) * scale)
    for pass_col, off in ((shadow, 1), (col, 0)):
        if pass_col is None:
            continue
        x = 0
        for c in text:
            if c not in ORDER:
                continue
            rows, gw = glyph_bitmap(c)
            for yy, r in enumerate(rows):
                for xx, p in enumerate(r):
                    if p == "#":
                        cv.fill(cv.mask_rect((x + xx + off) * scale, (yy + off) * scale, scale, scale), pass_col)
            x += gw + 1
    return cv


def save_atlas():
    atlas = Canvas(CELL_W * len(ORDER), CELL_H)
    meta = []
    for i, ch in enumerate(ORDER):
        rows, w = glyph_bitmap(ch)
        for y, r in enumerate(rows):
            for x, p in enumerate(r):
                if p == "#":
                    atlas.px[y][i * CELL_W + x] = (255, 255, 255, 255)
        meta.append((ch, i, w))
    atlas.save(os.path.join(ROOT, "assets", "sprites", "arte", "fonte.png"))
    lines = ["# GERADO por tools/arte/fonte.py (nao editar a mao).", "extends RefCounted", "",
             "const CELL := Vector2i(%d, %d)" % (CELL_W, CELL_H),
             "const TOP := %d  # linha da celula onde comeca a letra (7 px de altura)" % TOP,
             "# letra: [indice no atlas, largura em px]", "const GLYPHS := {"]
    for ch, i, w in meta:
        key = '"\\""' if ch == '"' else '"%s"' % ch
        lines.append("\t%s: [%d, %d]," % (key, i, w))
    lines.append("}")
    open(os.path.join(ROOT, "scripts", "fonte_meta.gd"), "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")
    print("salvo: assets/sprites/arte/fonte.png e scripts/fonte_meta.gd")


def sample():
    lines = ["ABCDEFGHIJKLMNOPQRSTUVWXYZ", "0123456789 .,:!?/-+()<>%", "ÁÀÂÃ ÉÊ Í ÓÔÕ Ú Ç",
             "", "JUMP DUCK", "OPÇÕES   CRÉDITOS   MÚSICA", "FASE CONCLUÍDA!   PRÓXIMA FASE",
             "CRIAÇÃO E DESENVOLVIMENTO", "FLORES 2/3   TEMPO 0:07", "A ÁGUIA MERGULHA ONDE VOCÊ ESTÁ",
             "ESPAÇO: PULAR   X OU J: PEGAR"]
    S = 4
    W, H = 760, len(lines) * (CELL_H + 3) * S + 24
    cv = Canvas(W, H)
    for y in range(H):
        for x in range(W):
            cv.px[y][x] = (13, 80, 0, 255)
    y = 12
    for i, ln in enumerate(lines):
        if ln:
            col = (255, 210, 63, 255) if i in (4,) else (255, 255, 255, 255)
            t = render(ln, S, col, (0, 40, 0, 255))
            cv.blit(t, 16, y)
        y += (CELL_H + 3) * S
    cv.save(os.path.join(OUT, "fonte_amostra.png"))
    print("ok amostra")


if __name__ == "__main__":
    sample()
    if "--salvar" in sys.argv:
        save_atlas()
