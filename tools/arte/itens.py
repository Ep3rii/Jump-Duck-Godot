"""Flores e itens na base de estilo (tools/arte/estilo.py): flor vermelha (4 quadros balancando),
coracao (cheio e vazio), chave, caixa de madeira, fardo de feno e estrela (cheia e vazia).
Grade de 32 (o tamanho do pato), gravados 4x em 128x128 por quadro.
Uso: python tools/arte/itens.py [--salvar]   (previa em tools/arte/saida/itens.png)"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas, load_png, hexc, save_gif, AMPLIADOS_4X  # noqa: E402
from estilo import Desenho, P  # noqa: E402
from objetos import x2  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
ARTE = os.path.join(ROOT, "assets", "sprites", "arte")
OUT = os.path.join(HERE, "saida")
os.makedirs(OUT, exist_ok=True)

OURO, OURO_LUZ, OURO_S, OURO_ESC = hexc("ffd23f"), hexc("fff0a0"), hexc("e0a81f"), hexc("8a5a00")
FENO, FENO_LUZ, FENO_S, FENO_ESC = hexc("f4d35e"), hexc("fbe58c"), hexc("d9ae3a"), hexc("8a6a1e")
VAZIO, VAZIO_S, VAZIO_ESC = hexc("4a5072"), hexc("3d4160"), hexc("2c3049")
# flor (Endesga 32)
F_CONT, F_PET_L, F_PET, F_PET_S = hexc("3e2731"), hexc("f6757a"), hexc("ff0044"), hexc("a22633")
F_VERDE_L, F_VERDE, F_VERDE_ESC = hexc("63c74d"), hexc("3e8948"), hexc("265c42")


SPR = os.path.join(HERE, "originais")  # sprites originais do GameMaker (referencia)


def refazer(src, x0, w, h, contorno, escala=2, sem_branco=False):
    """Como no pato: amplia o quadro original (x0..x0+w) e troca o contorno de fora, que
    ficaria grosso, por um novo de 1 px na mesma cor. Pixels soltos (brilhinhos) saem."""
    def px(x, y):
        c = src.px[y][x0 + x] if 0 <= x < w and 0 <= y < h else None
        if sem_branco and c is not None and min(c[:3]) > 240:
            return None  # o miolo branco do brilhinho
        return c

    def e_contorno(c):
        return c is not None and sum(abs(c[i] - contorno[i]) for i in range(3)) < 30
    # brilhinhos: grupos pequenos de pixels separados do desenho principal saem
    grupo = {}
    for y in range(h):
        for x in range(w):
            if px(x, y) is None or (x, y) in grupo:
                continue
            pilha, membros = [(x, y)], []
            grupo[(x, y)] = membros
            while pilha:
                cx, cy = pilha.pop()
                membros.append((cx, cy))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        n = (cx + dx, cy + dy)
                        if px(*n) is not None and n not in grupo:
                            grupo[n] = membros
                            pilha.append(n)
    soltos = {k for k, m in grupo.items() if len(m) < 12}
    W, H = w * escala, h * escala
    g = [[None] * W for _ in range(H)]
    for y in range(h):
        for x in range(w):
            c = px(x, y)
            if c is None or (x, y) in soltos:
                continue
            viz = [px(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy]
            if all(v is None for v in viz):
                continue  # pixel solto
            if escala > 1 and e_contorno(c) and any(v is None for v in viz):
                continue  # contorno de fora: sera refeito fino
            for dy in range(escala):
                for dx in range(escala):
                    g[y * escala + dy][x * escala + dx] = c
    cv = Canvas(W, H)
    for y in range(H):
        for x in range(W):
            if g[y][x] is not None:
                cv.px[y][x] = g[y][x]
            elif escala > 1 and any(0 <= x + dx < W and 0 <= y + dy < H and g[y + dy][x + dx] is not None
                                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                cv.px[y][x] = tuple(contorno[:3]) + (255,)
    return cv


def flor(quadro):
    """Rosa desenhada direto em 16x16 (cores da Endesga 32), entregue 2x para o reduz2 so amostrar.
    16 quadros: a cabeca inteira (petalas + calice) balanca como um bloco, dx = -1/0/+1 seguindo um
    seno, e sobe 1 px nos dois extremos do balanco (esquerda e direita, simetrico); o caule e
    reto, continuo e sem contorno preto."""
    d = Desenho(16, 16)
    s = math.sin(2 * math.pi * quadro / 16.0)
    dx = int(round(s))
    dy = -1 if abs(s) > 0.5 else 0
    # caule de 1 px (#3e8948); a metade de cima acompanha a cabeca no maximo 1 px
    for y in range(8 + dy, 15):
        d.cv.set(7 + (dx if y < 10 else 0), y, F_VERDE)
    # folhas encostadas no caule
    for (x, y, c) in ((4, 10, F_VERDE_L), (5, 10, F_VERDE_L), (5, 11, F_VERDE), (6, 11, F_VERDE),
                      (9, 11, F_VERDE_L), (10, 11, F_VERDE_L), (8, 12, F_VERDE), (9, 12, F_VERDE)):
        d.cv.set(x, y, c)
    cabeca = [".OOOO.",
              "OLLRRO",
              "OLRRSO",
              "ORRSSO",
              ".OSSO.",
              ".gGGg."]
    cores = {"O": F_CONT, "L": F_PET_L, "R": F_PET, "S": F_PET_S, "G": F_VERDE, "g": F_VERDE_ESC}
    for j, linha in enumerate(cabeca):
        for i, ch in enumerate(linha):
            if ch != ".":
                d.cv.set(5 + i + dx, 2 + j + dy, cores[ch])
    d.cv.set(7 + dx, 7 + dy, F_VERDE_L)
    return x2(d.cv)


def coracao(cheio=True):
    """O coracao original: ele ja esta na grade da arte (32x32 desenhado pela metade)."""
    nome = "spr_vidaCheia.png" if cheio else "spr_vidaVazia.png"
    return refazer(load_png(os.path.join(SPR, nome)), 0, 32, 32, (255, 255, 255), escala=1)


def estrela(cheia=True):
    """Estrela de 16x16 desenhada direto (cores da Endesga 32), com 1 px livre em cima e embaixo.
    O mapa ja traz o contorno (O) de 1 px: as 5 pontas terminam em miolo (Y) com contorno em volta
    (nenhuma ponta e so contorno nem acaba em pixel solto). A cheia tem contorno escuro (#733e39)
    para aparecer tambem sobre fundo amarelo, brilho em cima/esquerda e sombra embaixo/direita; a
    vazia e cinza-azulada (#3a4466 / #8b9bb4 / sombra #5a6988), sem brilho: le bem sobre o painel
    verde-escuro (#193c3e) da tela de resultado, onde a antiga, verde, sumia."""
    forma = ["................",
             ".......OO.......",
             "......OYYO......",
             "......OYYO......",
             ".....OYYYYO.....",
             "OOOOOOYYYYOOOOOO",
             "OYYYYYYYYYYYYYYO",
             ".OYYYYYYYYYYYYO.",
             "..OYYYYYYYYYYO..",
             "...OYYYYYYYYO...",
             "...OYYYYYYYYO...",
             "..OYYYYOOYYYYO..",
             "..OYYYO..OYYYO..",
             ".OYYYO....OYYYO.",
             ".OOOO......OOOO.",
             "................"]
    if cheia:
        cont, cor, luz, sombra = hexc("733e39"), hexc("fee761"), hexc("ffffff"), hexc("feae34")
    else:
        cont, cor, luz, sombra = hexc("3a4466"), hexc("8b9bb4"), hexc("8b9bb4"), hexc("5a6988")
    d = Desenho(16, 16)
    for y, linha in enumerate(forma):
        for x, ch in enumerate(linha):
            if ch == "O":
                d.cv.set(x, y, cont)
            elif ch == "Y":
                d.cv.set(x, y, cor)
    for (x, y) in ((7, 2), (7, 3), (6, 6)):   # brilho em cima/esquerda
        d.cv.set(x, y, luz)
    for y in range(7, 16):  # sombra: o miolo logo acima/esquerda do contorno de baixo/direita
        for x in range(16):
            if forma[y][x] == "Y" and (forma[y][x + 1] == "O" or
                                       (forma[y + 1][x] == "O" and (x >= 7 or y >= 13))):
                d.cv.px[y][x] = sombra
    for (x, y) in ((3, 13), (12, 13)):  # pontas de baixo: o pixel do meio fica no miolo
        d.cv.px[y][x] = cor
    return x2(d.cv)


ESTRELA_MINI = ["....O....",
                "...OYO...",
                "OOOOYOOOO",
                "OYYYYYYYO",
                ".OYYYYYO.",
                "..OYYYO..",
                ".OYYOYYO.",
                ".OYO.OYO.",
                ".OO...OO."]


def estrela_mini(cheia=True):
    """Estrela pequena do menu de fases: 9x9 no jogo (cabe na linha de 11 px dos botoes), com o
    contorno de 1 px no proprio mapa e as mesmas cores da estrela grande (cheia: #733e39/#fee761,
    brilho branco e sombra #feae34; vazia: #3a4466/#8b9bb4, sombra #5a6988).
    Como 9 e impar, nao da para desenhar na grade de 32 e deixar o reduz2 refazer o contorno: a
    peca e desenhada pixel a pixel em 9x9 e entregue 2x (18x18) com x2(); a tira inteira e entao
    uma ampliacao 2x exata, e o reduz2 so amostra (18x9 final, os 2 quadros de 9x9 lado a lado).
    Por nao estar em AMPLIADOS_4X, ela e gravada sem a ampliacao 4x das outras (ver main())."""
    if cheia:
        cont, cor, luz, sombra = hexc("733e39"), hexc("fee761"), hexc("ffffff"), hexc("feae34")
    else:
        cont, cor, luz, sombra = hexc("3a4466"), hexc("8b9bb4"), hexc("8b9bb4"), hexc("5a6988")
    f = ESTRELA_MINI
    cv = Canvas(9, 9)
    for y, linha in enumerate(f):
        for x, ch in enumerate(linha):
            if ch == "O":
                cv.set(x, y, cont)
            elif ch == "Y":
                # sombra: miolo com contorno logo a direita, ou embaixo na metade direita/pernas
                dir_ = x + 1 < 9 and f[y][x + 1] == "O"
                baixo = y + 1 < 9 and f[y + 1][x] == "O"
                cv.set(x, y, sombra if (y >= 4 and (dir_ or (baixo and x >= 4))) else cor)
    cv.set(4, 2, luz)  # brilho no alto da ponta de cima
    cv.set(2, 3, luz)
    return x2(cv)


def chave():
    """A chave que o jogo desenhava em codigo, no dobro: argola quadrada, haste e dois dentes."""
    d = Desenho(32, 32)
    d.rect(3, 9, 12, 14, OURO, "k")
    d.rect(14, 13, 15, 6, OURO, "k")
    d.rect(21, 18, 4, 6, OURO, "k")
    d.rect(26, 18, 3, 4, OURO, "k")
    d.apaga(d.cv.mask_rect(7, 13, 4, 6))
    d.rect(4, 10, 6, 1, OURO_LUZ, None, so=["k"])
    d.rect(4, 10, 1, 4, OURO_LUZ, None, so=["k"])
    d.contorno({"k": OURO_ESC})
    return d.cv


def caixa():
    """Caixa de madeira em 16x16 (cores da Endesga 32): moldura com luz em cima/esquerda e sombra
    embaixo/direita, X de reforco claro com sombra de 1 px embaixo e pregos nos cantos."""
    CONT, SOMB, MAD, LUZ = hexc("3e2731"), hexc("733e39"), hexc("b86f50"), hexc("e4a672")
    d = Desenho(16, 16)
    d.rect(0, 0, 16, 16, CONT)
    d.rect(1, 1, 14, 14, MAD)
    d.rect(1, 1, 14, 1, LUZ)
    d.rect(1, 1, 1, 14, LUZ)
    d.rect(1, 14, 14, 1, SOMB)
    d.rect(14, 1, 1, 14, SOMB)
    xs = set()
    for i in range(2, 14):
        xs.add((i, i))
        xs.add((15 - i, i))
    for (x, y) in xs:
        d.cv.set(x, y, LUZ)
    for (x, y) in xs:
        if (x, y + 1) not in xs and y + 1 < 14:
            d.cv.set(x, y + 1, SOMB)
    for (x, y) in ((2, 2), (13, 2), (2, 13), (13, 13)):
        d.cv.set(x, y, CONT)
    return x2(d.cv)


def feno():
    """Fardo de feno em 16x16 (cores da Endesga 32): palha amarela clara com tracinhos de palha,
    sombra fina embaixo/direita, duas cordas e contorno #733e39 com os cantos arredondados (nao
    usa o laranja da terra como cor do corpo)."""
    CONT, CORDA, CORPO, SOMB, PALHA = (hexc("733e39"), hexc("b86f50"), hexc("fee761"), hexc("feae34"),
                                       hexc("ead4aa"))
    d = Desenho(16, 16)
    d.rect(0, 0, 16, 16, CORPO, "f")
    for (x, y) in ((0, 0), (15, 0), (0, 15), (15, 15)):
        d.cv.px[y][x] = None
        d.cv.part[y][x] = None
    d.contorno({"f": CONT})
    d.rect(1, 14, 14, 1, SOMB)
    d.rect(14, 1, 1, 14, SOMB)
    for (x, y, w, c) in ((6, 3, 3, SOMB), (7, 7, 3, PALHA), (6, 11, 2, SOMB), (1, 5, 2, SOMB),
                         (2, 10, 2, PALHA), (12, 4, 2, PALHA), (12, 9, 2, SOMB), (8, 12, 2, PALHA)):
        d.rect(x, y, w, 1, c)
    for x in (4, 10):
        d.rect(x, 1, 2, 14, CORDA)
        d.cv.set(x + 1, 14, CONT)
    return x2(d.cv)


def tira(quadros):
    cv = Canvas(32 * len(quadros), 32)
    for i, q in enumerate(quadros):
        cv.blit(q, i * 32, 0)
    return cv


def tira_n(quadros, lado):
    cv = Canvas(lado * len(quadros), lado)
    for i, q in enumerate(quadros):
        cv.blit(q, i * lado, 0)
    return cv


def pecas():
    return {
        "flor": tira([flor(i) for i in range(16)]),
        "coracao": tira([coracao(True), coracao(False)]),
        "chave": chave(),
        "caixa": caixa(),
        "feno": feno(),
        "estrela": tira([estrela(True), estrela(False)]),
        "estrela_mini": tira_n([estrela_mini(True), estrela_mini(False)], 18),
    }


def folha(p):
    S = 6
    ordem = ["flor", "coracao", "estrela", "estrela_mini", "chave", "caixa", "feno"]
    W = sum(p[n].w for n in ordem) + 12 * (len(ordem) + 1) + 44
    H = 32 + 24
    cv = Canvas(W, H)
    for y in range(H):
        for x in range(W):
            cv.px[y][x] = hexc("76c2f6") if y < H - 10 else P["folha_sombra"]
    x = 12
    pato = load_png(os.path.join(ARTE, "pato_parado.png"))
    for yy in range(32):
        for xx in range(32):
            c = pato.px[yy * 4 + 1][xx * 4 + 1]
            if c is not None:
                cv.px[H - 10 - 31 + yy][x + xx] = c
    x += 44
    for n in ordem:
        cv.blit(p[n], x, H - 10 - 31)
        x += p[n].w + 12
    big = Canvas(W * S, H * S)
    big.blit(cv, 0, 0, S)
    big.save(os.path.join(OUT, "itens.png"))
    # a flor balancando
    quadros = []
    for i in range(4):
        q = Canvas(32, 32)
        for yy in range(32):
            for xx in range(32):
                q.px[yy][xx] = p["flor"].px[yy][i * 32 + xx]
        quadros.append(q)
    save_gif(os.path.join(OUT, "flor.gif"), quadros, delay_cs=20, scale=8, bg=(118, 194, 246))


def main():
    p = pecas()
    folha(p)
    if "--salvar" in sys.argv:
        for nome, cv in p.items():
            if nome == "coracao":
                continue  # o jogo usa o coracao original (spr_vidaCheia), que ja esta na grade
            if nome not in AMPLIADOS_4X:  # estrela_mini: grava a grade de 32 direto (18x9 final)
                cv.save(os.path.join(ARTE, nome + ".png"))
                continue
            big = Canvas(cv.w * 4, cv.h * 4)
            big.blit(cv, 0, 0, 4)
            big.save(os.path.join(ARTE, nome + ".png"))
        print("salvo em assets/sprites/arte/:", ", ".join(sorted(p)))
    print("ok")


if __name__ == "__main__":
    main()
