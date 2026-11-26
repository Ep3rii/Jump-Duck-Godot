"""Chefes na pixel art quadradinha (lote 2): jacare gigante (Fase 3) e gaviao chefe (Fase final).
Tamanho: 64x64 por quadro (2 blocos no jogo = 32 px). Gravados em 1:1 em assets/sprites/arte/.
Estilo: formas simples em blocos (retangulos de cantos arredondados), contorno de 1 px na cor
escura do material, cor so para detalhe (olho, dente, bochecha, estrelas).
Uso: python tools/arte/chefes.py [--salvar]   (previas em tools/arte/saida/)"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas, hexc, save_gif  # noqa: E402
from estilo import Desenho  # noqa: E402
import inimigos as ini  # noqa: E402  (mesma familia de aves: o chefe reusa a mecanica do desenho)

ROOT = os.path.dirname(os.path.dirname(HERE))
ARTE = os.path.join(ROOT, "assets", "sprites", "arte")
OUT = os.path.join(HERE, "saida")
os.makedirs(OUT, exist_ok=True)

# ---------------------------------------------------------------- paleta do jacare gigante
VERDE, VERDE_S, VERDE_L, VERDE_ESC = hexc("3c8a3c"), hexc("2a6a2e"), hexc("5aa84e"), hexc("16361a")
BARRIGA, ESCAMA = hexc("d2dc8a"), hexc("215a26")
DENTE, BOCA, BOCA_ESC = hexc("ffffff"), hexc("b8322e"), hexc("6e1a18")
BOCHECHA, BOCHECHA_ESC = hexc("ec7068"), hexc("8a2a22")
ESTRELA, OLHO = hexc("ffe04a"), hexc("ffe94a")
PUPILA = hexc("1a1a1a")


def jacare_gigante(q):
    """q: 0..3 nadando (cauda ondula, pernas remam); 4..5 saltando; 6..8 mordida (boca cada vez
    mais aberta); 9..10 dor de dente (bochecha inchada e estrelas)."""
    d = Desenho(64, 64)
    nado = q < 4
    fase = 2 * math.pi * (q if nado else 0) / 4.0
    ondula = int(round(3 * math.sin(fase))) if nado else 0
    salto = q in (4, 5)
    base = 46 if not salto else 36  # linha da barriga (salto: o corpo esta no ar)
    # cauda: 3 blocos afinando, ondulando
    d.rect(1, base - 13 + ondula, 14, 10, VERDE, "corpo")
    d.rect(8, base - 9 + ondula // 2, 12, 8, VERDE, "corpo")
    d.rect(14, base - 6, 8, 6, VERDE, "corpo")
    # corpo: bloco comprido, costas em degraus de escamas
    d.rect(14, base - 18, 30, 18, VERDE, "corpo")
    for i in range(6):
        d.rect(17 + i * 5, base - 20, 3, 2, ESCAMA, "corpo")
    d.rect(16, base - 4, 26, 4, BARRIGA, None, so=["corpo"])
    # patas: fora d'agua (saltando) ou remando no nado
    if salto:
        d.rect(20, base, 7, 7, VERDE, "pata")
        d.rect(34, base, 7, 7, VERDE, "pata")
    elif nado:
        d.rect(20, base + 1, 6, 4, VERDE_S, "pata")
        d.rect(33 + (q % 2) * 2, base + 1, 6, 4, VERDE_S, "pata")
    # cabeca: maxila que sobe conforme a boca abre; mandibula fica parada
    k = {6: 4, 7: 8, 8: 13}.get(q, 0)  # abertura em pixels
    d.rect(40, base - 26 - k, 22, 12, VERDE, "cabeca")         # maxila de cima
    d.rect(44, base - 28 - k, 12, 3, VERDE, "cabeca")          # testa
    d.rect(40, base - 14, 22, 8, VERDE, "cabeca")              # mandibula
    d.rect(41, base - 7, 20, 2, BARRIGA, None, so=["cabeca"])
    d.rect(45, base - 24 - k, 3, 3, OLHO)                      # olho
    d.rect(46, base - 23 - k, 1, 1, PUPILA)
    if k:  # boca aberta: vermelho por dentro e dentes nas duas bordas
        d.rect(42, base - 14 - k + 2, 20, k - 2, BOCA, "boca")
        for t in range(5):
            d.rect(43 + t * 4, base - 14 - k + 2, 2, 3, DENTE)
            d.rect(44 + t * 4, base - 14 - 1, 2, 2, DENTE)
    if q >= 9:  # dor de dente: bochecha inchada, dente com curativo e estrelas
        d.elipse(50, base - 9, 5, 5, BOCHECHA, "bochecha")
        d.rect(46, base - 16, 5, 2, DENTE)
        d.rect(47, base - 20, 2, 5, DENTE)
        for i in range(3):
            ang = (q - 9) * 0.6 + i * 2.094
            sx, sy = 52 + math.cos(ang) * 8, base - 36 + math.sin(ang) * 3
            d.rect(sx, sy - 2, 2, 5, ESTRELA)
            d.rect(sx - 1, sy, 4, 1, ESTRELA)
    d.contorno({"corpo": VERDE_ESC, "cabeca": VERDE_ESC, "pata": VERDE_ESC, "boca": BOCA_ESC,
                "bochecha": BOCHECHA_ESC},
               juntas=[("cabeca", "corpo"), ("bochecha", "cabeca")])
    return d.cv


# ---------------------------------------------------------------- gaviao chefe
G_CORPO, G_ASA, G_ASA_LONGE = hexc("7c4824"), hexc("603618"), hexc("4a2a14")
G_BARRIGA, G_CAUDA, G_BICO = hexc("ecd6aa"), hexc("c4502c"), hexc("fac428")


def gaviao(q):
    """q: 0..3 voo (asas batendo); 4..5 grito (asa no alto, bico aberto); 6..7 mergulho;
    8..9 investida (asas para tras); 10..12 atordoado (caido, com estrelas)."""
    if q <= 3:
        return ini.ave(q, 1.45, G_CORPO, G_ASA, G_ASA_LONGE, G_CORPO, G_CAUDA, peito=G_BARRIGA, env=1.25)
    if q in (4, 5):
        return ini.ave(0 if q == 4 else 1, 1.45, G_CORPO, G_ASA, G_ASA_LONGE, G_CORPO, G_CAUDA, peito=G_BARRIGA, env=1.25)
    if q in (6, 7):
        return ini.ave(6, 1.45, G_CORPO, G_ASA, G_ASA_LONGE, G_CORPO, G_CAUDA, peito=G_BARRIGA, env=1.25)
    if q in (8, 9):
        return ini.ave(6, 1.45, G_CORPO, G_ASA, G_ASA_LONGE, G_CORPO, G_CAUDA, peito=G_BARRIGA, env=1.25)
    return atordoado(q - 10)


def atordoado(i):
    """Caido de lado: corpo baixo, asa aberta no chao, 3 estrelas girando sobre a cabeca."""
    d = Desenho(64, 64)
    d.rect(10, 40, 32, 10, G_CORPO, "corpo")
    d.rect(14, 46, 22, 4, G_BARRIGA, None, so=["corpo"])
    d.rect(40, 36, 14, 12, G_CORPO, "cabeca")
    d.rect(52, 42, 6, 4, G_BICO, "bico")
    d.rect(44, 40, 3, 3, OLHO)  # olho em X: dois pixels cruzados
    d.rect(44, 40, 1, 1, PUPILA)
    d.rect(46, 42, 1, 1, PUPILA)
    d.rect(3, 42, 16, 6, G_ASA, "asa")                     # asa aberta no chao
    d.rect(4, 46, 14, 3, G_ASA_LONGE, "asa")
    d.rect(38, 46, 20, 4, G_CAUDA, "cauda")
    for k in range(3):
        ang = i * 0.7 + k * 2.094
        sx, sy = 46 + math.cos(ang) * 10, 30 + math.sin(ang) * 3
        d.rect(sx, sy - 2, 2, 5, ESTRELA)
        d.rect(sx - 1, sy, 4, 1, ESTRELA)
    d.contorno({"corpo": G_ASA_LONGE, "cabeca": G_ASA_LONGE, "asa": hexc("2a1608"),
                "cauda": hexc("7a2a16"), "bico": hexc("8a5a00")},
               juntas=[("cabeca", "corpo"), ("asa", "corpo")])
    return d.cv


# ---------------------------------------------------------------- saida
def tira(quadros):
    cv = Canvas(64 * len(quadros), 64)
    for i, q in enumerate(quadros):
        cv.blit(q, i * 64, 0)
    return cv


def pecas():
    return {
        "chefe_jacare": [jacare_gigante(i) for i in range(11)],
        "chefe_gaviao": [gaviao(i) for i in range(13)],
    }


def main():
    p = pecas()
    for nome, qs in p.items():
        t = tira(qs)
        big = Canvas(t.w * 2, t.h * 2)
        big.blit(t, 0, 0, 2)
        big.save(os.path.join(OUT, "%s.png" % nome))
    if "--salvar" in sys.argv:
        for nome, qs in p.items():
            tira(qs).save(os.path.join(ARTE, nome + ".png"))
        print("salvo:", ", ".join(sorted(p)))
    print("ok")


if __name__ == "__main__":
    main()
