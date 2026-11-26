"""Lote 3: arte da cutscene final em pixel art quadradinha.
- pata.png: a Pata, feita a partir dos quadros aprovados do pato (mesmo corpo e contorno), com
  laco rosa atras da cabeca, cilios e bochecha rosada. 11 quadros de 32x32:
  0 parada, 1..8 andando (o ciclo de corrida do pato), 9..10 feliz (asa batendo, do apice).
- ninho.png: ninho de gravetos em blocos (40x16, 20x8 no jogo).
Gravado em 1:1 em assets/sprites/arte/. Uso: python tools/arte/cutscene_arte.py [--salvar]"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas, load_png, hexc, save_gif  # noqa: E402
from estilo import Desenho  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
ARTE = os.path.join(ROOT, "assets", "sprites", "arte")
OUT = os.path.join(HERE, "saida")
os.makedirs(OUT, exist_ok=True)

CONTORNO = (99, 99, 99, 255)
BRANCO = (255, 255, 255, 255)
LACO, LACO_ESC, LACO_NO = hexc("ff6fa8"), hexc("a8245c"), hexc("d83a7c")
BOCHECHA = hexc("ffb0c4")
GRAVETO, GRAVETO_S, GRAVETO_L, GRAVETO_ESC = hexc("a86834"), hexc("7a4822"), hexc("c88448"), hexc("4a2a14")


def quadros(nome, n):
    src = load_png(os.path.join(ARTE, nome + ".png"), ampliar=False)
    out = []
    for i in range(n):
        q = Canvas(32, 32)
        for y in range(32):
            for x in range(32):
                q.px[y][x] = src.px[y][i * 32 + x]
        out.append(q)
    return out


def olhos(q):
    """Blocos de olho: pixels de contorno no MIOLO da cabeca (os 4 vizinhos preenchidos),
    nas linhas de cima. Devolve o canto de cima/esquerda de cada olho."""
    topo = min(y for y in range(32) if any(q.px[y]))
    achados = []
    for y in range(topo + 3, min(32, topo + 12)):
        for x in range(15, 31):  # so na cabeca (o pato olha para a direita)
            if q.px[y][x] != CONTORNO:
                continue
            if all(q.px[y + dy][x + dx] is not None for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                if not any(abs(x - ax) <= 2 and abs(y - ay) <= 2 for ax, ay in achados):
                    achados.append((x, y))
    return achados


def pata(q):
    d = Desenho(32, 32)
    for y in range(32):  # o pato por baixo (sem "parte": o contorno novo nao mexe nele)
        for x in range(32):
            d.cv.px[y][x] = q.px[y][x]
    topo = min(y for y in range(32) if any(q.px[y]))
    # laco na parte de tras da cabeca: duas orelhas e o no, encostados na borda da cabeca
    r = topo + 3
    esq = next(x for x in range(32) if q.px[r][x] is not None)
    d.rect(esq - 4, r - 3, 4, 3, LACO, "laco")
    d.rect(esq - 4, r + 1, 4, 3, LACO, "laco")
    d.rect(esq - 1, r - 1, 3, 3, LACO_NO, "laco")
    d.contorno({"laco": LACO_ESC})
    cv = d.cv
    # cilios e bochecha em cada olho
    for (ex, ey) in olhos(q):
        for (x, y, c) in ((ex + 2, ey - 1, CONTORNO), (ex + 1, ey - 2, CONTORNO),
                          (ex - 1, ey + 3, BOCHECHA), (ex, ey + 3, BOCHECHA)):
            if 0 <= x < 32 and 0 <= y < 32 and cv.px[y][x] == BRANCO:
                cv.px[y][x] = c
    return cv


def ninho():
    """Ninho em tigela: aro largo de gravetos em cima, fundo arredondado em degraus."""
    d = Desenho(40, 16)
    d.rect(1, 5, 38, 4, GRAVETO, "n")      # aro
    d.rect(3, 9, 34, 3, GRAVETO, "n")
    d.rect(7, 12, 26, 2, GRAVETO, "n")
    d.rect(12, 14, 16, 1, GRAVETO, "n")    # fundo
    d.rect(5, 6, 30, 2, GRAVETO_ESC)       # a cavidade (escuro por dentro)
    for i, x in enumerate(range(2, 37, 4)):  # gravetos do aro, alternando o tom
        d.rect(x, 4 + (i % 2), 3, 2, GRAVETO_L if i % 2 == 0 else GRAVETO_S, "n")
    for x in (0, 37):  # pontas de graveto saindo para os lados
        d.rect(x, 3, 3, 2, GRAVETO_L, "n")
    for x in range(6, 34, 6):
        d.rect(x, 10, 4, 1, GRAVETO_S)
    d.contorno({"n": GRAVETO_ESC})
    return d.cv


def pecas():
    base = quadros("pato_parado", 1) + quadros("pato_correndo", 8) + quadros("pato_apice", 2)
    return {"pata": [pata(q) for q in base], "ninho": [ninho()]}


def tira(qs):
    w, h = qs[0].w, qs[0].h
    cv = Canvas(w * len(qs), h)
    for i, q in enumerate(qs):
        cv.blit(q, i * w, 0)
    return cv


def main():
    p = pecas()
    for nome, qs in p.items():
        t = tira(qs)
        big = Canvas(t.w * 6, t.h * 6)
        big.blit(t, 0, 0, 6)
        big.save(os.path.join(OUT, "cutscene_%s.png" % nome))
    save_gif(os.path.join(OUT, "pata_andando.gif"), p["pata"][1:9], delay_cs=10, scale=6, bg=(250, 170, 110))
    if "--salvar" in sys.argv:
        for nome, qs in p.items():
            tira(qs).save(os.path.join(ARTE, nome + ".png"))
        print("salvo:", ", ".join(sorted(p)))
    print("ok")


if __name__ == "__main__":
    main()
