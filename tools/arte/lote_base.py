"""Lote 1 do acabamento: coracao (HUD e vida extra), agua (16 px animada), bloco de piso e
coracao_grande (cutscene: 16 quadros de 32x32 crescendo, sempre em escala 1).
Estilo: pixel art quadradinha. Geometria simples (blocos e retangulos), contorno de 1 px na cor
escura do proprio material, cor so para detalhe. Gravado em 1:1 (ver ROTEIRO_FASES.md).
Uso: python tools/arte/lote_base.py [--salvar]   (previas em tools/arte/saida/)"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas, hexc, save_gif  # noqa: E402
from estilo import Desenho, P  # noqa: E402
from objetos import x2  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
ARTE = os.path.join(ROOT, "assets", "sprites", "arte")
OUT = os.path.join(HERE, "saida")
os.makedirs(OUT, exist_ok=True)

VERM, VERM_L, VERM_S, VERM_ESC = hexc("e8364a"), hexc("ff7a7a"), hexc("b8243a"), hexc("6e1020")
CINZA, CINZA_L, CINZA_ESC = hexc("3a3f52"), hexc("4a5068"), hexc("1e2030")
AGUA, AGUA_S, AGUA_ESC, ESPUMA = hexc("4fb6f0"), hexc("2f86d6"), hexc("1c5c9c"), hexc("e6f8ff")
TERRA, TERRA_S, TERRA_ESC, GRAMA = hexc("e49e42"), hexc("b97a2c"), hexc("6a4216"), hexc("31dc31")


def coracao(cheio=True):
    """Coracao do HUD em 16x16: o mesmo desenho do primeiro quadro do coracao_grande (16 px de
    largura), recortado do quadro de 32 e com as cores Endesga escritas direto. Contorno #3e2731
    nos dois (cheio e vazio); o vazio troca o vermelho por azul-escuro apagado."""
    cv32 = _coracao32(0)
    troca = {} if cheio else {E_VERM: hexc("3a4466"), E_VERM_S: hexc("262b44"),
                              E_VERM_L: hexc("5a6988"), E_VERM_ESC: E_VERM_ESC}
    cv = Canvas(16, 16)
    for y in range(16):
        for x in range(16):
            c = cv32.px[y + 7][x + 8]
            if c is not None:
                cv.px[y][x] = troca.get(c, c)
    return x2(cv)


# cores exatas da Endesga 32 (a paleta() nao mexe nelas)
E_AGUA_L, E_AGUA, E_AGUA_FUNDA, E_BRANCO = hexc("2ce8f5"), hexc("0099db"), hexc("124e89"), hexc("ffffff")
E_GRAMA_ESC, E_GRAMA_S, E_GRAMA = hexc("265c42"), hexc("3e8948"), hexc("63c74d")
E_TERRA, E_TERRA_S, E_TERRA_ESC = hexc("b86f50"), hexc("733e39"), hexc("3e2731")
E_FLOR, E_FLOR_MIOLO = hexc("ffffff"), hexc("feae34")
E_VERM_L, E_VERM, E_VERM_S, E_VERM_ESC = hexc("f6757a"), hexc("e43b44"), hexc("a22633"), hexc("3e2731")


def _mapa(linhas, cores):
    cv = Canvas(len(linhas[0]), len(linhas))
    for y, linha in enumerate(linhas):
        for x, ch in enumerate(linha):
            if ch != ".":
                cv.px[y][x] = cores[ch]
    return cv


def agua(frame):
    """Agua em 16x16 (desenhada direto, entregue 2x). Superficie: espuma #2ce8f5 de 1-2 px (a
    linha 0 inteira e cristas de 3 px na linha 1 que andam 1 px por quadro, periodo 8). Corpo
    #0099db com uma marola curta e bolhinhas. Embaixo, dither de 1 px ate #124e89: linha 13 com
    1 em 4, linha 14 em xadrez e linha 15 inteira #124e89, que emenda com a agua funda que o jogo
    pinta por baixo na mesma cor (sem terceira faixa). Todos os periodos dividem 16 (emenda nos
    lados e nos 16 quadros)."""
    cv = Canvas(16, 16)
    for y in range(16):
        for x in range(16):
            cv.px[y][x] = E_AGUA
    for x in range(16):
        cv.px[0][x] = E_AGUA_L
        if (x - frame) % 8 < 3:          # cristas de espuma (2 px de altura onde passam)
            cv.px[1][x] = E_AGUA_L
        if (x + frame + 3) % 8 < 2:      # marola curta, andando ao contrario
            cv.px[3][x] = E_AGUA_L
        if x % 4 == 1:                   # dither: 1 em 4
            cv.px[13][x] = E_AGUA_FUNDA
        if x % 2 == 0:                   # dither: xadrez
            cv.px[14][x] = E_AGUA_FUNDA
        cv.px[15][x] = E_AGUA_FUNDA
    by = 12 - (frame % 8)  # bolhinhas subindo 1 px por quadro, so no corpo (fora do dither)
    for bx, b in ((4, by), (11, by + 3)):
        if 4 < b < 13:
            cv.px[b][bx] = E_AGUA_L
    return x2(cv)


def bloco_piso():
    """Bloco de piso em 16x16 com as cores do tileset_grama novo: grama #63c74d (sombra #3e8948,
    contorno #265c42) com franja irregular caindo sobre a terra e uma florzinha branca de miolo
    #feae34; terra #b86f50 com sombra #733e39 logo abaixo da franja, riscos #733e39 e faixa do
    fundo #733e39; contorno da terra #3e2731 (onde o contorno so encosta em terra, como no
    tileset). Desenhado direto e entregue 2x."""
    linhas = ["CCCCCCCCCCCCCCCC",
              "CEEEEEEEEEEWEEEC",
              "CEEEEEEEEEWYWEDC",
              "CEEDEEEEEDEWEEDC",
              "CDDEDDEEDDDEDDDC",
              "CDTDDTDDDTDDTDDC",
              "CTTDTTTDTTTTTDTC",
              "CTTTTTTTTTTTTTTC",
              "CTTTTTTTTTTTTTTC",
              "CTTTHHTTTTTTTTTC",
              "CTTTTTTTTTTTTTTC",
              "CTTTTTTTTTHHTTTC",
              "CTTTTTTTTTTTTTTC",
              "CTHHTTTTTTTTTTTC",
              "CSSSSSSSSSSSSSSC",
              "CCCCCCCCCCCCCCCC"]
    g = [list(r) for r in linhas]
    for y in range(1, 15):           # sombra da grama: terra logo abaixo de grama
        for x in range(1, 15):
            if linhas[y][x] == "T" and linhas[y - 1][x] in "ED":
                g[y][x] = "S"
    grama = set("EDWY")
    for y in range(16):              # contorno que so encosta em terra vira #3e2731
        for x in range(16):
            if linhas[y][x] != "C":
                continue
            if x in (0, 15) and 0 < y < 15:  # laterais: decide pelo pixel de dentro (simetrico)
                if linhas[y][1 if x == 0 else 14] not in grama:
                    g[y][x] = "K"
                continue
            viz = [linhas[yy][xx] for yy in (y - 1, y, y + 1) for xx in (x - 1, x, x + 1)
                   if 0 <= yy < 16 and 0 <= xx < 16 and (xx, yy) != (x, y)]
            if not any(v in grama for v in viz) and y > 0:
                g[y][x] = "K"
    cores = {"C": E_GRAMA_ESC, "E": E_GRAMA, "D": E_GRAMA_S, "W": E_FLOR, "Y": E_FLOR_MIOLO,
             "T": E_TERRA, "S": E_TERRA_S, "H": E_TERRA_S, "K": E_TERRA_ESC}
    return x2(_mapa(["".join(r) for r in g], cores))


def _forma_coracao(n):
    """Mascara de coracao com n px de largura (par), centrada num quadro de 32x32: dois lobos
    redondos (com o vale no meio) e a ponta em V."""
    r = n / 4.0
    h = int(round(n * 0.875))
    topo = 16 - h // 2
    cy = topo + r
    fundo = topo + h
    pts = set()
    for y in range(32):
        for x in range(32):
            px, py = x + 0.5, y + 0.5
            lobo = any((px - cx) ** 2 + (py - cy) ** 2 <= (r + 0.15) ** 2 for cx in (16 - r, 16 + r))
            v = cy <= py <= fundo and abs(px - 16) <= (n / 2.0) * (fundo - py) / (fundo - cy)
            if lobo or v:
                pts.add((x, y))
    return pts


def coracao_grande(q):
    """Coracao grande da cutscene: 16 quadros de 32x32 em pixels do jogo (escala 1), crescendo
    de 16 px (o tamanho do coracao do HUD) ate 30 px. Cada tamanho e redesenhado (nao e
    ampliado): contorno de 1 px #3e2731, brilho em cima/esquerda e sombra embaixo/direita."""
    return x2(_coracao32(q))


def _coracao32(q):
    """O quadro q do coracao grande em pixels do jogo (Canvas 32x32, sem ampliar)."""
    n = 16 + 2 * int(round(q * 7 / 15.0))
    forma = _forma_coracao(n)
    cv = Canvas(32, 32)
    for (x, y) in forma:
        cv.px[y][x] = E_VERM
    for (x, y) in forma:
        if any((x + dx, y + dy) not in forma for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            cv.px[y][x] = E_VERM_ESC
    k = max(1, n // 10)
    sombra = []
    for (x, y) in forma:
        if cv.px[y][x] != E_VERM or x < 16:
            continue
        # sombra SOLIDA: faixa de k px colada no contorno da direita/de baixo (metade direita),
        # sem miolo vermelho entre a sombra e o contorno (nada de contorno duplo)
        viz = [(x + i, y) for i in range(1, k + 1)] + [(x, y + j) for j in range(1, k + 1)]
        if any(0 <= vx < 32 and 0 <= vy < 32 and cv.px[vy][vx] == E_VERM_ESC for vx, vy in viz):
            sombra.append((x, y))
    for (x, y) in sombra:
        cv.px[y][x] = E_VERM_S
    # brilho: um bloquinho no lobo esquerdo
    bx, by = 16 - n // 2 + max(2, n // 6), 16 - n // 4 + max(0, n // 16)
    t = max(1, n // 8)
    for j in range(t):
        for i in range(t + 1):
            if cv.px[by + j][bx + i] == E_VERM:
                cv.px[by + j][bx + i] = E_VERM_L
    return cv


def pecas():
    return {
        "coracao": [coracao(True), coracao(False)],
        "agua": [agua(i) for i in range(16)],
        "bloco": [bloco_piso()],
        "coracao_grande": [coracao_grande(i) for i in range(16)],
    }


def tira(quadros):
    w = quadros[0].w
    cv = Canvas(w * len(quadros), quadros[0].h)
    for i, q in enumerate(quadros):
        cv.blit(q, i * w, 0)
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
