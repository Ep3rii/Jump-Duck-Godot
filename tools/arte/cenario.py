"""Itens de cenario na base de estilo (tools/arte/estilo.py), na ESCALA DO PATO: o pato e
pequeno (32 px da grade) e o cenario e grande. Gravados direto na grade (2 px = 1 px do jogo)
em assets/sprites/arte/cenario/.
Uso: python tools/arte/cenario.py [--salvar]   (previa em tools/arte/saida/cenario_escala.png)"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas, load_png, hexc  # noqa: E402
from estilo import Desenho, P, conferir  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
ARTE = os.path.join(ROOT, "assets", "sprites", "arte")
DEST = os.path.join(ARTE, "cenario")
OUT = os.path.join(HERE, "saida")
os.makedirs(OUT, exist_ok=True)

ESC_MADEIRA = {"tronco": P["contorno_madeira"], "copa": P["contorno_verde"]}


# ------------------------------------------------------------------ arvore
def arvore_tronco(s=1.0):
    """Tronco (com a parte que fica atras da copa). s = tamanho (1 = arvore grande)."""
    W, H = int(160 * s), int(224 * s)
    d = Desenho(W, H)
    k = lambda v: int(round(v * s))  # noqa: E731
    cx = W // 2
    d.poli([(cx - k(22), H), (cx - k(14), H - k(20)), (cx - k(10), H - k(40)), (cx - k(10), k(96)),
            (cx + k(10), k(96)), (cx + k(10), H - k(40)), (cx + k(14), H - k(20)), (cx + k(22), H)],
           P["madeira"], "tronco")
    # galhos entrando na copa
    d.poli([(cx - k(10), k(132)), (cx - k(34), k(100)), (cx - k(26), k(96)), (cx - k(4), k(120))],
           P["madeira"], "tronco")
    d.poli([(cx + k(10), k(138)), (cx + k(32), k(108)), (cx + k(24), k(104)), (cx + k(4), k(126))],
           P["madeira"], "tronco")
    d.sombra("tronco", P["madeira_sombra"], dx=max(3, k(7)), dy=0)
    d.luz("tronco", P["madeira_luz"], dx=max(2, k(4)), dy=0)
    # no da madeira
    if s >= 0.9:
        d.elipse(cx - 1, H - 58, 4, 5, P["madeira_sombra"], so=["tronco"])
        d.elipse(cx - 1, H - 58, 2, 3, P["madeira"], so=["tronco"])
    d.contorno(ESC_MADEIRA)
    return d


COPA_BOLAS = [(80, 70, 62, 56), (40, 94, 34, 30), (120, 94, 34, 30), (54, 42, 38, 30),
              (108, 46, 36, 28), (80, 112, 44, 22)]
COPA_TUFOS = [(52, 62, 22, 18), (104, 70, 24, 18), (78, 34, 20, 14), (34, 98, 16, 12),
              (118, 104, 18, 12), (76, 96, 22, 14)]
MACAS = [(38, 80), (64, 54), (98, 40), (120, 82), (86, 100), (54, 110), (108, 116)]


def arvore_copa(s=1.0, macas=True):
    W, H = int(160 * s), int(224 * s)
    d = Desenho(W, H)
    for cx, cy, rx, ry in COPA_BOLAS:
        d.elipse(cx * s, cy * s, rx * s, ry * s, P["folha"], "copa")
    d.sombra("copa", P["folha_sombra"], dx=max(5, int(12 * s)), dy=max(6, int(14 * s)))
    d.luz("copa", P["folha_luz"], dx=max(4, int(9 * s)), dy=max(4, int(9 * s)))
    # tufos: cada um e uma bola com a meia-lua de sombra embaixo/direita (volume das folhas)
    cv = d.cv
    for cx, cy, rx, ry in COPA_TUFOS:
        fora = set(cv.mask_ellipse(cx * s, cy * s, rx * s, ry * s))
        dentro = set(cv.mask_ellipse((cx - 5) * s, (cy - 6) * s, rx * s, ry * s))
        for x, y in fora - dentro:
            if 0 <= x < W and 0 <= y < H and cv.part[y][x] == "copa" and cv.px[y][x] == P["folha"]:
                cv.px[y][x] = P["folha_sombra"]
    if macas:
        for ax, ay in MACAS:
            x, y = int(ax * s), int(ay * s)
            if cv.part[y][x] != "copa":
                continue
            for j, row in enumerate([".RR.", "RRRR", "RRRS", ".SS."]):
                for i, ch in enumerate(row):
                    if ch != ".":
                        cv.px[y + j][x + i] = P["vermelho"] if ch == "R" else P["vermelho_sombra"]
            cv.px[y + 1][x + 1] = P["vermelho_luz"]
    d.contorno(ESC_MADEIRA)
    return d


# ------------------------------------------------------------------ arbusto
def arbusto():
    d = Desenho(96, 56)
    for cx, cy, rx, ry in [(26, 34, 24, 20), (70, 34, 24, 20), (48, 26, 30, 24)]:
        d.elipse(cx, cy, rx, ry, P["folha"], "copa")
    d.rect(6, 38, 84, 18, P["folha"], "copa")
    d.sombra("copa", P["folha_sombra"], dx=7, dy=8)
    d.luz("copa", P["folha_luz"], dx=5, dy=5)
    cv = d.cv
    for cx, cy, rx, ry in [(30, 34, 12, 10), (66, 30, 13, 10)]:
        fora = set(cv.mask_ellipse(cx, cy, rx, ry))
        dentro = set(cv.mask_ellipse(cx - 4, cy - 5, rx, ry))
        for x, y in fora - dentro:
            if cv.part[y][x] == "copa" and cv.px[y][x] == P["folha"]:
                cv.px[y][x] = P["folha_sombra"]
    for fx, fy in [(20, 22), (50, 12), (72, 26), (40, 36)]:
        d.flor(fx, fy)
    d.contorno(ESC_MADEIRA)
    return d


# ------------------------------------------------------------------ cerca
def cerca(tipo="meio"):
    """Trecho de 32 px (1 bloco) com um mourao no meio. tipo: 'esq', 'meio', 'dir' (as pontas
    fecham as tabuas)."""
    d = Desenho(32, 48)
    x0 = 0 if tipo != "esq" else 8
    x1 = 32 if tipo != "dir" else 24
    for y in (15, 31):
        d.rect(x0, y, x1 - x0, 8, P["madeira"], "tabua")
        d.rect(x0, y + 1, x1 - x0, 2, P["madeira_luz"], None, so=["tabua"])
        d.rect(x0, y + 5, x1 - x0, 2, P["madeira_sombra"], None, so=["tabua"])
    d.poli([(11, 6), (16, 1), (21, 6), (21, 48), (11, 48)], P["madeira"], "mourao")
    d.sombra("mourao", P["madeira_sombra"], dx=3, dy=0)
    d.luz("mourao", P["madeira_luz"], dx=3, dy=0)
    cv = d.cv
    esc = P["contorno_madeira"]

    def cheio(x, y):
        if x < 0:
            return tipo != "esq"
        if x >= 32:
            return tipo != "dir"
        return 0 <= y < 48 and cv.px[y][x] is not None
    borda = []
    for y in range(48):
        for x in range(32):
            if cv.px[y][x] is None:
                continue
            if not (cheio(x - 1, y) and cheio(x + 1, y) and cheio(x, y - 1) and (y == 47 or cheio(x, y + 1))):
                borda.append((x, y))
            elif cv.part[y][x] == "mourao" and any(
                    0 <= x + dx < 32 and cv.part[y][x + dx] == "tabua" for dx in (-1, 1)):
                borda.append((x, y))
    for x, y in borda:
        cv.px[y][x] = esc
    for x in range(11, 22):  # a base do mourao tambem fecha (apoia na borda do chao)
        if cv.px[47][x] is not None:
            cv.px[47][x] = esc
    return d


# ------------------------------------------------------------------ celeiro
def celeiro():
    W, H = 304, 216
    d = Desenho(W, H)
    # telhado (aba) e fachada
    d.poli([(2, 122), (40, 46), (152, 0), (264, 46), (302, 122), (288, 122), (288, 110), (16, 110),
            (16, 122)], P["madeira"], "telhado")
    d.poli([(16, 110), (50, 58), (152, 16), (254, 58), (288, 110)], P["vermelho"], "parede")
    d.rect(16, 110, 272, H - 110, P["vermelho"], "parede")
    # tabuas
    for x in range(32, 288, 16):
        d.rect(x, 20, 1, H, P["vermelho_sombra"], None, so=["parede"])
    d.sombra("parede", P["vermelho_sombra"], dx=12, dy=0)
    d.luz("parede", P["vermelho_luz"], dx=4, dy=0)
    # sombra da aba do telhado na fachada (a luz vem de cima)
    cv = d.cv
    for y in range(H):
        for x in range(W):
            if cv.part[y][x] == "parede" and any(
                    0 <= y - j < H and cv.part[y - j][x] == "telhado" for j in range(1, 7)):
                cv.px[y][x] = P["vermelho_sombra"]
    d.sombra("telhado", P["madeira_sombra"], dx=0, dy=5)
    d.luz("telhado", P["madeira_luz"], dx=0, dy=3)
    # friso branco na altura do beiral
    d.rect(17, 110, 270, 6, P["branco"], "friso")
    d.rect(17, 114, 270, 2, P["branco_sombra"], None, so=["friso"])
    # portao de duas folhas com X
    d.rect(100, 122, 104, H - 122, P["branco"], "friso")
    for px in (106, 154):
        d.rect(px, 128, 44, H - 128, P["vermelho_sombra"], "porta")
        for t in range(3):
            d.linha(px, 128 + t, px + 43 - 0, H - 1 - 2 + t, P["branco"], so=["porta"])
            d.linha(px + 43, 128 + t, px, H - 1 - 2 + t, P["branco"], so=["porta"])
        d.linha(px, 129, px + 43, H - 2, P["branco"], so=["porta"], grossura=3)
        d.linha(px + 43, 129, px, H - 2, P["branco"], so=["porta"], grossura=3)
    # janela do sotao
    d.rect(130, 50, 44, 40, P["branco"], "friso")
    d.rect(136, 56, 32, 28, P["janela"], "vidro")
    d.rect(150, 56, 4, 28, P["branco"], "friso")
    d.rect(136, 68, 32, 4, P["branco"], "friso")
    d.contorno({"parede": P["contorno_vermelho"], "telhado": P["contorno_madeira"],
                "friso": P["contorno_cinza"], "porta": P["contorno_vermelho"], "vidro": P["janela"]},
               juntas=[("telhado", "parede"), ("porta", "friso"), ("vidro", "friso")])
    return d


# ------------------------------------------------------------------ moinho
MOINHO_CUBO = (80, 52)  # centro das pas, na tela do corpo
TIJOLOS = [(52, 92), (92, 100), (64, 124), (100, 128), (44, 168), (84, 176), (110, 164),
           (40, 204), (100, 210), (112, 190), (56, 188), (72, 84)]


def moinho_corpo():
    W, H = 160, 240
    d = Desenho(W, H)
    d.poli([(20, H), (46, 72), (114, 72), (140, H)], P["creme"], "corpo")
    d.sombra("corpo", P["creme_sombra"], dx=14, dy=0)
    d.luz("corpo", P["creme_luz"], dx=6, dy=0)
    for bx, by in TIJOLOS:
        d.rect(bx, by, 9, 3, P["creme_sombra"], None, so=["corpo"])
    # janela em arco
    d.rect(72, 100, 16, 20, P["janela"], "vidro")
    d.elipse(80, 100, 8, 6, P["janela"], "vidro")
    d.rect(68, 120, 24, 4, P["creme_luz"], "peitoril")
    # varanda de madeira
    d.rect(28, 132, 104, 4, P["madeira"], "varanda")
    for x in range(30, 132, 12):
        d.rect(x, 136, 3, 12, P["madeira"], "varanda")
    d.rect(24, 148, 112, 8, P["madeira"], "varanda")
    d.rect(24, 149, 112, 2, P["madeira_luz"], None, so=["varanda"])
    d.rect(24, 153, 112, 2, P["madeira_sombra"], None, so=["varanda"])
    # sombra da varanda no corpo
    cv = d.cv
    for y in range(156, 162):
        for x in range(W):
            if cv.part[y][x] == "corpo":
                cv.px[y][x] = P["creme_sombra"]
    # porta em arco
    d.rect(66, 198, 28, H - 198, P["madeira"], "porta")
    d.elipse(80, 198, 14, 10, P["madeira"], "porta")
    d.rect(79, 190, 2, H - 190, P["madeira_sombra"], None, so=["porta"])
    d.rect(84, 216, 3, 3, P["amarelo"], None, so=["porta"])
    # telhado (chapeu) vermelho
    d.poli([(32, 78), (46, 44), (80, 24), (114, 44), (128, 78)], P["vermelho"], "telhado")
    d.sombra("telhado", P["vermelho_sombra"], dx=14, dy=6)
    d.luz("telhado", P["vermelho_luz"], dx=6, dy=0)
    d.contorno({"corpo": P["contorno_creme"], "telhado": P["contorno_vermelho"],
                "varanda": P["contorno_madeira"], "porta": P["contorno_madeira"],
                "vidro": P["contorno_creme"], "peitoril": P["contorno_creme"]},
               juntas=[("telhado", "corpo"), ("varanda", "corpo"), ("porta", "corpo"),
                       ("vidro", "corpo"), ("peitoril", "corpo")])
    return d


PAS_QUADRO = 192
PAS_QUADROS = 8  # um quarto de volta (as 4 pas sao iguais)


def moinho_pas(i):
    S = PAS_QUADRO
    d = Desenho(S, S)
    c = S / 2.0
    ang0 = math.radians(90.0 * i / PAS_QUADROS)

    def rot(u, v, a):
        # u = ao longo da pa (para cima no angulo 0), v = para o lado
        return (c + u * math.sin(a) + v * math.cos(a), c - u * math.cos(a) + v * math.sin(a))
    for kk in range(4):
        a = ang0 + kk * math.pi / 2.0
        d.poli([rot(22, 4, a), rot(90, 4, a), rot(90, 28, a), rot(22, 28, a)], P["branco"], "vela")
        for v in (12, 20):
            p0, p1 = rot(22, v, a), rot(90, v, a)
            d.linha(p0[0], p0[1], p1[0], p1[1], P["branco_sombra"], so=["vela"])
        for u in range(34, 90, 12):
            p0, p1 = rot(u, 4, a), rot(u, 28, a)
            d.linha(p0[0], p0[1], p1[0], p1[1], P["branco_sombra"], so=["vela"])
    for kk in range(4):
        a = ang0 + kk * math.pi / 2.0
        d.poli([rot(0, -3, a), rot(92, -3, a), rot(92, 3, a), rot(0, 3, a)], P["madeira"], "haste")
    d.elipse(c, c, 8, 8, P["madeira_luz"], "cubo")
    d.contorno({"vela": P["contorno_cinza"], "haste": P["contorno_madeira"], "cubo": P["contorno_madeira"]},
               juntas=[("haste", "vela"), ("cubo", "haste")])
    return d


def tira(quadros):
    w, h = quadros[0].w, quadros[0].h
    cv = Canvas(w * len(quadros), h)
    for i, q in enumerate(quadros):
        cv.blit(q.cv, i * w, 0)
    return cv


# ------------------------------------------------------------------ todas as pecas
def pecas():
    cerca_cv = Canvas(96, 48)
    for i, t in enumerate(("esq", "meio", "dir")):
        cerca_cv.blit(cerca(t).cv, i * 32, 0)
    return {
        "arvore_tronco": arvore_tronco(1.0).cv,
        "arvore_copa": arvore_copa(1.0).cv,
        "arvore_jovem_tronco": arvore_tronco(0.6).cv,
        "arvore_jovem_copa": arvore_copa(0.6, macas=False).cv,
        "arbusto": arbusto().cv,
        "cerca": cerca_cv,
        "celeiro": celeiro().cv,
        "moinho_corpo": moinho_corpo().cv,
        "moinho_pas": tira([moinho_pas(i) for i in range(PAS_QUADROS)]),
    }


def bloco32(sheet, idx):
    """Bloco do tileset (128 px) reduzido para a grade (32)."""
    t = Canvas(32, 32)
    tx, ty = idx % 4, idx // 4
    for y in range(32):
        for x in range(32):
            t.px[y][x] = sheet.px[ty * 128 + y * 4 + 1][tx * 128 + x * 4 + 1]
    return t


def pato32():
    src = load_png(os.path.join(ARTE, "pato_parado.png"))
    t = Canvas(32, 32)
    for y in range(32):
        for x in range(32):
            t.px[y][x] = src.px[y * 4 + 1][x * 4 + 1]
    return t


def previa(p):
    """Uma tela do jogo (384x216 px do jogo = 768x432 da grade) com as pecas e o pato."""
    W, H = 768, 432
    cv = Canvas(W, H)
    ceu = hexc("6cbcf5")
    for y in range(H):
        for x in range(W):
            cv.px[y][x] = ceu
    chao = H - 64
    sheet = load_png(os.path.join(ARTE, "tileset_grama.png"))
    tops = [16, 5, 17, 5, 18, 5, 19, 5]
    for i in range(W // 32):
        cv.blit(bloco32(sheet, tops[i % len(tops)]), i * 32, chao)
        cv.blit(bloco32(sheet, 13), i * 32, chao + 32)

    def poe(nome, x, dy=0, quadro=None, fw=None):
        src = p[nome]
        if quadro is not None:
            sub = Canvas(fw, src.h)
            for yy in range(src.h):
                for xx in range(fw):
                    sub.px[yy][xx] = src.px[yy][quadro * fw + xx]
            src = sub
        cv.blit(src, x, chao - src.h + 1 + dy)
    # (o contorno de baixo de cada peca fica em cima da borda do chao, como o pe do pato)
    poe("moinho_corpo", 16)
    cx, cy = 16 + MOINHO_CUBO[0], chao - 240 + 1 + MOINHO_CUBO[1]
    pas = p["moinho_pas"]
    for yy in range(PAS_QUADRO):
        for xx in range(PAS_QUADRO):
            c = pas.px[yy][2 * PAS_QUADRO + xx]
            if c is not None:
                cv.set(cx - PAS_QUADRO // 2 + xx, cy - PAS_QUADRO // 2 + yy, c)
    poe("celeiro", 196)
    poe("arvore_tronco", 520)
    poe("arvore_copa", 520)
    poe("arvore_jovem_tronco", 668)
    poe("arvore_jovem_copa", 668)
    poe("arbusto", 420)
    for i, q in enumerate([0, 1, 1, 2]):
        poe("cerca", 432 + 64 + i * 32 - 80 + 64, 0, q, 32)
    cv.blit(pato32(), 372, chao - 31)
    cv.blit(pato32(), 640, chao - 31)
    big = Canvas(W * 2, H * 2)
    big.blit(cv, 0, 0, 2)
    big.save(os.path.join(OUT, "cenario_escala.png"))


def main():
    p = pecas()
    for nome, cv in p.items():
        probs = conferir(cv)
        if probs:
            print("AVISO", nome, probs[:6])
    previa(p)
    if "--salvar" in sys.argv:
        os.makedirs(DEST, exist_ok=True)
        for nome, cv in p.items():
            cv.save(os.path.join(DEST, nome + ".png"))
        print("salvo em assets/sprites/arte/cenario/:", ", ".join(sorted(p)))
    print("ok")


if __name__ == "__main__":
    main()
