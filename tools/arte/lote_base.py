"""Lote 1 do acabamento: coracao (HUD e vida extra), agua (16 px animada) e bloco de piso.
Estilo: pixel art quadradinha. Geometria simples (blocos e retangulos), contorno de 1 px na cor
escura do proprio material, cor so para detalhe. Gravado em 1:1 (ver ROTEIRO_FASES.md).
Uso: python tools/arte/lote_base.py [--salvar]   (previas em tools/arte/saida/)"""
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

VERM, VERM_L, VERM_S, VERM_ESC = hexc("e8364a"), hexc("ff7a7a"), hexc("b8243a"), hexc("6e1020")
CINZA, CINZA_L, CINZA_ESC = hexc("3a3f52"), hexc("4a5068"), hexc("1e2030")
AGUA, AGUA_S, AGUA_ESC, ESPUMA = hexc("4fb6f0"), hexc("2f86d6"), hexc("1c5c9c"), hexc("e6f8ff")
TERRA, TERRA_S, TERRA_ESC, GRAMA = hexc("e49e42"), hexc("b97a2c"), hexc("6a4216"), hexc("31dc31")


def coracao(cheio=True):
    """Coracao em degraus de 2 px (32x32, mostrado em 16 px): dois lobos e a ponta."""
    d = Desenho(32, 32)
    cor = VERM if cheio else CINZA
    luz = VERM_L if cheio else CINZA_L
    sombra = VERM_S if cheio else CINZA_ESC
    # degraus: cada linha e um retangulo; a forma e a de um coracao "pixel" classico
    linhas = [(4, 9, 10, 2), (2, 7, 14, 2), (2, 6, 28, 0), (1, 6, 30, 0)]
    for x0, y0, w, h in []:
        pass
    d.rect(4, 8, 8, 4, cor, "c")
    d.rect(18, 8, 8, 4, cor, "c")
    d.rect(2, 10, 28, 6, cor, "c")
    d.rect(4, 16, 24, 4, cor, "c")
    d.rect(6, 20, 20, 3, cor, "c")
    d.rect(9, 23, 14, 2, cor, "c")
    d.rect(12, 25, 8, 2, cor, "c")
    d.rect(14, 27, 4, 2, cor, "c")
    d.rect(7, 6, 6, 2, cor, "c")
    d.rect(19, 6, 6, 2, cor, "c")
    d.rect(5, 6, 2, 2, cor, "c")
    d.rect(25, 6, 2, 2, cor, "c")
    if cheio:  # brilho em blocos claros (cor de detalhe, nao degrade)
        d.rect(6, 10, 4, 2, luz)
        d.rect(6, 12, 2, 2, luz)
        d.rect(22, 20, 2, 2, sombra)
        d.rect(20, 22, 4, 2, sombra)
        d.rect(12, 26, 4, 2, sombra)
    d.contorno({"c": VERM_ESC if cheio else CINZA_ESC})
    return d.cv


def agua(frame):
    """Agua de 32x32 (16 px no jogo): faixa de superficie com espuma que anda, corpo azul."""
    d = Desenho(32, 32)
    d.rect(0, 0, 32, 32, AGUA, "a")
    d.rect(0, 16, 32, 16, AGUA_S, "a")
    # ondinhas da superficie: 3 blocos claros que andam 4 px por quadro
    for i in range(3):
        x = (i * 12 + frame * 4) % 32
        d.rect(x, 2, 6, 2, ESPUMA)
        d.rect((x + 2) % 32, 4, 2, 1, ESPUMA)
    # bolhinhas, sempre no mesmo lugar, subindo um pouco por quadro
    by = 24 - frame * 2
    d.rect(8, by, 2, 2, ESPUMA)
    d.rect(22, by + 4, 2, 2, ESPUMA)
    return d.cv


def bloco_piso():
    """Bloco de piso (32x32, mostrado em 16 px): terra com a faixa de grama no topo, que
    combina com o tileset de grama (sem flores: o bloco e para paredes e chao escondido)."""
    d = Desenho(32, 32)
    d.rect(0, 0, 32, 32, TERRA, "t")
    d.rect(0, 0, 32, 5, GRAMA, "g")
    d.rect(0, 5, 32, 1, hexc("28b228"), "g")
    d.rect(0, 22, 32, 10, TERRA_S, "t")
    # pedrinhas e raiz, em cor de detalhe
    d.rect(6, 12, 3, 2, TERRA_S)
    d.rect(20, 16, 4, 2, TERRA_S)
    d.rect(12, 26, 3, 2, TERRA_ESC)
    d.contorno({"g": hexc("1d6b22"), "t": TERRA_ESC})
    return d.cv


def pecas():
    return {
        "coracao": [coracao(True), coracao(False)],
        "agua": [agua(i) for i in range(4)],
        "bloco": [bloco_piso()],
    }


def tira(quadros):
    cv = Canvas(32 * len(quadros), 32)
    for i, q in enumerate(quadros):
        cv.blit(q, i * 32, 0)
    return cv


def main():
    p = pecas()
    for nome, qs in p.items():
        t = tira(qs)
        big = Canvas(t.w * 6, t.h * 6)
        big.blit(t, 0, 0, 6)
        big.save(os.path.join(OUT, "lote_%s.png" % nome))
    if "--salvar" in sys.argv:
        for nome, qs in p.items():
            tira(qs).save(os.path.join(ARTE, nome + ".png"))
        print("salvo em assets/sprites/arte/:", ", ".join(sorted(p)))
    print("ok")


if __name__ == "__main__":
    main()
