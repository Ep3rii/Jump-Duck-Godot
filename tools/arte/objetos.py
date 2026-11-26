"""Lote 4: objetos das fases em pixel art quadradinha (geometria simples, contorno de 1 px na cor
escura do material, cor so para detalhe). Tudo em 1:1 (32 px de desenho = 16 px no jogo).
  porta.png      5 quadros 32x32: topo, meio, base, fechadura (por cima), batente aberto
  placa.png      2 quadros 32x32: placa de pressao solta e apertada
  saida.png      4 quadros 40x96: bandeira de saida tremulando
  checkpoint.png 4 quadros 28x56: apagado e 3 acesos tremulando
  cipo.png       2 quadros 32x32: trecho de cipo (folhas balancando), repete na vertical
  pedra_cai.png  2 quadros 32x32: pedra inteira e rachada
  vento.png      2 quadros 24x24: lufada horizontal e vertical
  dica.png       1 quadro 32x40: placa de madeira das dicas
  seta.png       1 quadro 40x48: placa de saida (seta)
  junco.png      2 quadros 32x56: moita de juncos balancando
  brilho.png     5 quadros 32x32: brilho de coletar
Uso: python tools/arte/objetos.py [--salvar]   (previa em tools/arte/saida/objetos.png)"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas, hexc, save_gif  # noqa: E402
from estilo import Desenho, P  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
ARTE = os.path.join(ROOT, "assets", "sprites", "arte")
OUT = os.path.join(HERE, "saida")
os.makedirs(OUT, exist_ok=True)

MAD, MAD_L, MAD_S, MAD_ESC = P["madeira"], P["madeira_luz"], P["madeira_sombra"], P["contorno_madeira"]
FERRO, FERRO_L, FERRO_ESC = hexc("5a5e72"), hexc("8f96ae"), hexc("2c3049")
OURO, OURO_L, OURO_ESC = hexc("ffd23f"), hexc("fff0a0"), hexc("8a5a00")
VERM, VERM_L, VERM_ESC = hexc("e8364a"), hexc("ff7a7a"), hexc("6e1020")
VERDE, VERDE_L, VERDE_S, VERDE_ESC = hexc("31dc31"), hexc("8af06a"), hexc("28b228"), hexc("1d6b22")
CINZA, CINZA_S, CINZA_ESC = hexc("a8b0b8"), hexc("7a828c"), hexc("3a3f52")
AREIA, AREIA_L, AREIA_S, AREIA_ESC = hexc("b8a27c"), hexc("dcc8a0"), hexc("8a7656"), hexc("3a2e22")


# ---------------------------------------------------------------- porta
def porta(peca):
    """peca: 0 topo, 1 meio, 2 base, 3 fechadura (so a placa dourada), 4 batente (aberta)."""
    d = Desenho(32, 32)
    if peca == 3:
        d.rect(10, 6, 12, 18, OURO, "f")
        d.rect(11, 7, 4, 2, OURO_L)
        d.rect(15, 11, 2, 2, OURO_ESC)   # buraco da chave
        d.rect(14, 13, 4, 2, OURO_ESC)
        d.rect(15, 15, 2, 4, OURO_ESC)
        d.contorno({"f": OURO_ESC})
        return d.cv
    if peca == 4:
        d.rect(0, 0, 32, 6, MAD_S, "b")
        d.rect(0, 0, 32, 2, MAD)
        d.contorno({"b": MAD_ESC})
        return d.cv
    d.rect(0, 0, 32, 32, MAD, "p")
    for x in range(0, 32, 8):  # tabuas verticais: luz a esquerda, fresta escura a direita
        d.rect(x + 1, 0, 1, 32, MAD_L)
        d.rect(x + 7, 0, 1, 32, MAD_S)
    faixas = {0: [6], 1: [14], 2: [20]}[peca]
    for y in faixas:  # faixa de ferro com rebites
        d.rect(0, y, 32, 6, FERRO, "p")
        d.rect(0, y, 32, 1, FERRO_L)
        for x in (3, 27):
            d.rect(x, y + 2, 2, 2, FERRO_ESC)
    cv = d.cv
    for y in range(32):  # contorno so nas laterais (topo e base fecham na primeira/ultima peca)
        cv.px[y][0] = MAD_ESC
        cv.px[y][31] = MAD_ESC
    if peca == 0:
        for x in range(32):
            cv.px[0][x] = MAD_ESC
    if peca == 2:
        for x in range(32):
            cv.px[31][x] = MAD_ESC
    return cv


# ---------------------------------------------------------------- placa de pressao
def placa(apertada):
    d = Desenho(32, 32)
    d.rect(0, 26, 32, 6, CINZA, "base")
    d.rect(0, 26, 32, 1, hexc("d0d6dc"))
    alto = 2 if apertada else 6
    d.rect(4, 26 - alto, 24, alto, VERM, "botao")
    if not apertada:
        d.rect(5, 21, 10, 1, VERM_L)
    d.contorno({"base": CINZA_ESC, "botao": VERM_ESC}, juntas=[("botao", "base")])
    return d.cv


# ---------------------------------------------------------------- bandeira de saida
def saida(q):
    d = Desenho(40, 96)
    d.rect(2, 90, 16, 6, hexc("2f5a2c"), "base")            # pe do mastro
    d.rect(8, 8, 4, 84, hexc("2f5a2c"), "mastro")
    d.rect(9, 8, 1, 82, hexc("5aa84e"))
    d.rect(6, 2, 8, 7, OURO, "ponta")                      # bolinha dourada
    d.rect(7, 3, 2, 2, OURO_L)
    for c in range(14):  # bandeira: colunas de 2 px que sobem e descem numa onda (degraus)
        x = 12 + c * 2
        h = 22 - c // 2
        dy = int(round(2 * math.sin(q * math.pi / 2 + c * 0.6)))
        y = 10 + (22 - h) // 2 + dy
        cor = OURO if c % 4 != 3 else hexc("e0a81f")
        d.rect(x, y, 2, h, cor, "bandeira")
    d.contorno({"base": VERDE_ESC, "mastro": VERDE_ESC, "ponta": OURO_ESC, "bandeira": OURO_ESC},
               juntas=[("bandeira", "mastro")])
    return d.cv


# ---------------------------------------------------------------- checkpoint
def checkpoint(q):
    """q 0: apagado (bandeira cinza murcha embaixo); 1..3: aceso (verde no alto, tremulando)."""
    d = Desenho(28, 56)
    d.rect(1, 52, 14, 4, hexc("2f5a2c"), "base")
    d.rect(6, 4, 4, 50, hexc("2f5a2c"), "mastro")
    d.rect(7, 4, 1, 48, hexc("5aa84e"))
    aceso = q > 0
    cor, cor_s, esc = (VERDE, VERDE_S, VERDE_ESC) if aceso else (CINZA, CINZA_S, CINZA_ESC)
    d.rect(4, 0, 8, 5, cor_s, "ponta")
    for c in range(8):
        x = 10 + c * 2
        h = 14 - c
        if aceso:
            y = 6 + (14 - h) // 2 + int(round(1.5 * math.sin(q * 2.1 + c * 0.7)))
        else:
            y = 26 + c * 2  # murcha, caindo para baixo
        d.rect(x, y, 2, max(4, h), cor if c < 6 else cor_s, "bandeira")
    d.contorno({"base": VERDE_ESC, "mastro": VERDE_ESC, "ponta": esc, "bandeira": esc},
               juntas=[("bandeira", "mastro")])
    return d.cv


# ---------------------------------------------------------------- cipo
def cipo(q):
    d = Desenho(32, 32)
    for y in range(32):  # caule em zigue-zague de degraus de 2 px (emenda em cima e embaixo)
        x = 14 + (2 if (y // 8) % 2 else 0)
        d.rect(x, y, 4, 1, VERDE_S, "caule")
        d.rect(x, y, 1, 1, VERDE_L)
    dx = 1 if q else 0
    for (y, esq) in ((4, True), (20, False)):  # folhas em blocos
        x = 6 + dx if esq else 20 - dx
        d.rect(x, y, 8, 4, VERDE, "folha")
        d.rect(x + 1, y, 3, 1, VERDE_L)
    d.rect(19, 12, 4, 4, hexc("fff0f0"), "flor")
    d.rect(20, 13, 2, 2, hexc("ffd23f"))
    d.contorno({"caule": VERDE_ESC, "folha": VERDE_ESC, "flor": hexc("c87a8a")},
               juntas=[("folha", "caule")])
    cv = d.cv
    for y in (0, 31):  # o caule continua no proximo trecho: sem contorno em cima e embaixo
        for x in range(32):
            if cv.px[y][x] == VERDE_ESC and d.cv.part[y][x] == "caule":
                cv.px[y][x] = VERDE_S
    return cv


# ---------------------------------------------------------------- pedra que cai
def pedra_cai(rachada):
    d = Desenho(32, 32)
    d.rect(0, 0, 32, 30, AREIA, "p")
    d.rect(1, 1, 30, 3, AREIA_L)
    d.rect(1, 24, 30, 5, AREIA_S)
    d.rect(15, 4, 1, 20, AREIA_S)  # junta entre as duas lajes
    for (x, y) in ((10, 6), (11, 9), (12, 12), (11, 15)):
        d.rect(x, y, 1, 3, AREIA_ESC)
    if rachada:
        for (x, y, w, h) in ((22, 5, 3, 1), (24, 6, 1, 4), (25, 10, 1, 3), (20, 14, 4, 1), (6, 18, 1, 4), (7, 22, 3, 1)):
            d.rect(x, y, w, h, AREIA_ESC)
    d.contorno({"p": AREIA_ESC})
    return d.cv


# ---------------------------------------------------------------- vento
def vento(vertical):
    d = Desenho(24, 24)
    BR = hexc("ffffff")
    if vertical:
        d.rect(10, 4, 2, 16, BR, "v")
        d.rect(12, 2, 2, 4, BR, "v")
        d.rect(8, 18, 2, 3, BR, "v")
    else:
        d.rect(4, 10, 16, 2, BR, "v")
        d.rect(18, 8, 4, 2, BR, "v")
        d.rect(2, 12, 3, 2, BR, "v")
    return d.cv


# ---------------------------------------------------------------- placas de madeira
def dica():
    d = Desenho(32, 40)
    d.rect(14, 18, 4, 22, MAD_S, "poste")
    d.rect(2, 2, 28, 18, MAD, "tabua")
    d.rect(3, 3, 26, 2, MAD_L)
    d.rect(3, 17, 26, 2, MAD_S)
    for y, w in ((7, 18), (11, 14)):  # "linhas de texto"
        d.rect(7, y, w, 2, MAD_ESC)
    d.contorno({"poste": MAD_ESC, "tabua": MAD_ESC}, juntas=[("tabua", "poste")])
    return d.cv


def seta():
    d = Desenho(40, 48)
    d.rect(18, 20, 4, 28, MAD_S, "poste")
    d.poli([(2, 6), (28, 6), (38, 13), (28, 21), (2, 21)], MAD, "tabua")
    d.rect(4, 8, 22, 2, MAD_L)
    d.rect(8, 13, 18, 2, MAD_ESC)   # risco da seta
    d.rect(24, 11, 2, 6, MAD_ESC)
    d.contorno({"poste": MAD_ESC, "tabua": MAD_ESC}, juntas=[("tabua", "poste")])
    return d.cv


# ---------------------------------------------------------------- junco
def junco(q):
    d = Desenho(32, 56)
    hastes = [(8, 40), (12, 50), (16, 38), (20, 48), (24, 36)]
    for i, (x, h) in enumerate(hastes):
        topo = 56 - h
        for seg in range(4):
            y0 = topo + seg * h // 4
            ond = (1 if q else -1) * (3 - seg) // 2 if i % 2 == 0 else (-1 if q else 1) * (3 - seg) // 2
            d.rect(x + ond, y0, 2, h // 4 + 1, VERDE_S, "haste")
        if i in (1, 3):  # taboa marrom no alto
            ond = (1 if q else -1) if i % 2 == 0 else (-1 if q else 1)
            d.rect(x - 1 + ond, topo - 2, 4, 9, MAD, "taboa")
    d.contorno({"haste": VERDE_ESC, "taboa": MAD_ESC}, juntas=[("taboa", "haste")])
    return d.cv


# ---------------------------------------------------------------- brilho de coletar
def brilho(q):
    d = Desenho(32, 32)
    r = [3, 7, 11, 9, 5][q]
    c = 16
    d.rect(c - 1, c - r, 2, 2 * r, OURO, "b")
    d.rect(c - r, c - 1, 2 * r, 2, OURO, "b")
    if q in (1, 2, 3):
        k = r // 2
        for sx, sy in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
            d.rect(c + sx * k - 1, c + sy * k - 1, 2, 2, OURO_L, "b")
    d.rect(c - 1, c - 1, 2, 2, hexc("ffffff"))
    # sem contorno: a cruz e fina (2 px) e o contorno a deixaria toda escura
    if r > 4:
        for (x, y) in ((c - 1, c - r), (c - 1, c + r - 2), (c - r, c - 1), (c + r - 2, c - 1)):
            d.rect(x, y, 2, 2, OURO_L)
    return d.cv


# ---------------------------------------------------------------- saida
def pecas():
    return {
        "porta": [porta(i) for i in range(5)],
        "placa": [placa(False), placa(True)],
        "saida": [saida(i) for i in range(4)],
        "checkpoint": [checkpoint(i) for i in range(4)],
        "cipo": [cipo(0), cipo(1)],
        "pedra_cai": [pedra_cai(False), pedra_cai(True)],
        "vento": [vento(False), vento(True)],
        "dica": [dica()],
        "seta": [seta()],
        "junco": [junco(0), junco(1)],
        "brilho": [brilho(i) for i in range(5)],
    }


def tira(qs):
    w, h = qs[0].w, qs[0].h
    cv = Canvas(w * len(qs), h)
    for i, q in enumerate(qs):
        cv.blit(q, i * w, 0)
    return cv


def folha(p):
    S = 3
    tiras = [tira(qs) for qs in p.values()]
    W = max(t.w for t in tiras) + 8
    H = sum(t.h + 6 for t in tiras) + 4
    cv = Canvas(W, H)
    for y in range(H):
        for x in range(W):
            cv.px[y][x] = (118, 194, 246, 255)
    y = 4
    for t in tiras:
        cv.blit(t, 4, y)
        y += t.h + 6
    big = Canvas(W * S, H * S)
    big.blit(cv, 0, 0, S)
    big.save(os.path.join(OUT, "objetos.png"))


def main():
    p = pecas()
    folha(p)
    if "--salvar" in sys.argv:
        for nome, qs in p.items():
            tira(qs).save(os.path.join(ARTE, nome + ".png"))
        print("salvo:", ", ".join(sorted(p)))
    print("ok")


if __name__ == "__main__":
    main()
