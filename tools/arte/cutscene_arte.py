"""Lote 3: arte da cutscene final em pixel art quadradinha (16x16, Endesga 32).
- pata.png: a Pata, feita dos MESMOS quadros acabados do pato (tools/arte/pato16.py: bico,
  olho, pes e contorno iguais), com laco vermelho atras da cabeca, cilio e bochecha rosada,
  desenhados direto na grade de 16 (nao passam pela reducao, que apagava os detalhes).
  48 quadros de 16x16: 0..15 parada, 16..31 andando (o ciclo de corrida do pato),
  32..47 feliz (corpo e asa batendo da queda do pato, com as pernas da parada no chao).
- ninho.png: ninho de gravetos desenhado em 1:1 (20x8 no jogo).
As pecas sao entregues ampliadas 2x (blocos 2x2 de uma cor so): o save() so amostra de volta,
sem refazer contorno nem trocar cor. Uso: python tools/arte/cutscene_arte.py [--salvar]"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas, hexc, save_gif  # noqa: E402
import pato16 as Q  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
ARTE = os.path.join(ROOT, "assets", "sprites", "arte")
OUT = os.path.join(HERE, "saida")
os.makedirs(OUT, exist_ok=True)

BRANCO = Q.BRANCO
LACO, LACO_CLARO, LACO_NO, LACO_ESC = hexc("e43b44"), hexc("f6757a"), hexc("a22633"), hexc("3e2731")
BOCHECHA = hexc("f6757a")
CILIO = Q.OLHO

# laco tipo gravata-borboleta (5x3: duas abas abertas para fora e o no escuro no meio),
# encostado no contorno da nuca. L = luz (cima/esquerda), A = aba, N = no. Mais largo que alto
# e com o estreitamento do no, para nao ler como crista.
LACO_DESENHO = ["LA.AA",
                ".ANA.",
                "AA.AA"]
LACO_X, LACO_DY = 2, 1  # canto de cima/esquerda, relativo ao topo da cabeca
LACO_COR = {"L": LACO_CLARO, "A": LACO, "N": LACO_NO}

# ninho 20x8: A = contorno/cavidade, C = graveto escuro, B = graveto, L = luz (cima/esquerda)
NINHO = ["....A..........A....",   # dois gravetos soltos de 1 px, cada um num angulo
         ".....C.......CC.....",
         ".ALBLBCLBBLCBLBBLCA.",
         "ACAAAAAAAAAAAAAAAACA",
         ".ABBCLBBBCCBLBBBCBA.",   # trama irregular (nada de xadrez)
         ".ACBBCBBLBBCBCCBBCA.",
         "..AACCBBCBBBCBBCAA..",
         "....AAAAAAAAAAAA...."]
NINHO_COR = {"A": hexc("3e2731"), "C": hexc("733e39"), "B": hexc("b86f50"), "L": hexc("e4a672")}


def pata(q):
    """Quadro acabado do pato (16x16) -> a Pata: laco, cilio e bochecha, que acompanham a cabeca."""
    cv = Q.copia(q)
    t = Q.topo_cabeca(q)
    dy = LACO_DY
    abaixo = t + dy + len(LACO_DESENHO)  # a linha logo abaixo do laco
    if dy > 0 and abaixo < 16 and any(q.px[abaixo][x] is not None for x in range(LACO_X, LACO_X + 5)):
        dy -= 1  # a asa alta chega perto: o laco sobe 1 px e o vao dele continua aberto
    for j, linha in enumerate(LACO_DESENHO):
        for i, ch in enumerate(linha):
            if ch != "." and 0 <= t + dy + j < 16:
                cv.px[t + dy + j][LACO_X + i] = LACO_COR[ch]
    ex, ey = 10, t + 3  # o olho do pato (o mesmo lugar no quadro que pisca)
    for x, y, c in ((ex + 1, ey - 1, CILIO), (ex, ey + 2, BOCHECHA)):
        if 0 <= y < 16 and cv.px[y][x] == BRANCO:
            cv.px[y][x] = c
    Q.tapa_furos(cv)  # o vao do laco nao pode virar furo quando encosta no corpo
    return cv


def feliz():
    """Asa batendo (a queda do pato, duas batidas regulares) com as pernas da parada: os pes
    ficam na linha 15, como nos outros quadros (nada de flutuar)."""
    pernas = Q.base_parado()
    out = []
    for q in Q.no_ar(Q.FALL16, True):
        f = Q.copia(q)
        for y in range(12, 16):
            for x in range(16):
                f.px[y][x] = pernas.px[y][x]
        if f.px[3][4] is not None:  # asa alta: desce 1 px para nao fechar o vao do laco
            f = Q.move(f, 0, 7, 3, 6, 0, 1)
            for y in range(3, 7):  # o branco que ficou exposto ganha contorno
                for x in range(7):
                    if f.px[y][x] is None and any(
                            0 <= x + dx < 16 and f.px[y + dy][x + dx] in (Q.BRANCO, Q.SOMBRA) for dx, dy in Q.VIZ4):
                        f.px[y][x] = Q.CONT
        out.append(f)
    return out


def ninho():
    cv = Canvas(20, 8)
    for y, linha in enumerate(NINHO):
        for x, ch in enumerate(linha):
            if ch != ".":
                cv.px[y][x] = NINHO_COR[ch]
    return cv


def pecas16():
    # 16 parada + 16 andando + 16 feliz: pelo menos 15 quadros por animacao
    return [pata(q) for q in Q.parado() + Q.correndo() + feliz()]


def x2(cv):
    big = Canvas(cv.w * 2, cv.h * 2)
    big.blit(cv, 0, 0, 2)
    return big


def pecas():
    return {"pata": [x2(q) for q in pecas16()], "ninho": [x2(ninho())]}


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
        big = Canvas(t.w * 3, t.h * 3)
        big.blit(t, 0, 0, 3)
        big.save(os.path.join(OUT, "cutscene_%s.png" % nome))
    save_gif(os.path.join(OUT, "pata_andando.gif"), p["pata"][16:32], delay_cs=5, scale=6, bg=(250, 170, 110))
    if "--salvar" in sys.argv:
        for nome, qs in p.items():
            tira(qs).save(os.path.join(ARTE, nome + ".png"))
        print("salvo:", ", ".join(sorted(p)))
    print("ok")


if __name__ == "__main__":
    main()
