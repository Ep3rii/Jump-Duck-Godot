"""Lote 4: objetos das fases em pixel art quadradinha (geometria simples, contorno de 1 px na cor
escura do material, cor so para detalhe). Quase tudo desenhado direto em 16x16 (pixels do jogo,
cores da Endesga 32) e entregue 2x na grade de 32 (ver x2()); o vento horizontal e o brilho
ainda sao desenhados na grade de 32.
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
  portao_fazenda.png 16 quadros 32x96: barranco de grama que sobe e fecha a arena (lagoa)
  portao_torre.png   16 quadros 32x96: grade de ferro levadica que desce (torre)
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


# ---------------------------------------------------------------- desenho direto em 16x16
# As pecas abaixo sao desenhadas JA em pixels do jogo (16 px por bloco), com as cores exatas da
# Endesga 32, e entregues ampliadas 2x (blocos 2x2 de uma cor so). Assim o reduz2() do pixelkit
# so amostra (nao refaz o contorno nem apaga detalhe de 1 px) e a paleta() nao muda nenhuma cor.
E_CONT = hexc("3e2731")      # contorno da madeira / tinta escura
E_MAD_S = hexc("733e39")
E_MAD = hexc("b86f50")
E_MAD_L = hexc("d77643")
E_FERRO_ESC = hexc("262b44")
E_PEDRA_ESC = hexc("3a4466")
E_PEDRA_S = hexc("5a6988")
E_PEDRA = hexc("8b9bb4")
E_PEDRA_L = hexc("c0cbdc")
E_OURO_L = hexc("fee761")
E_OURO = hexc("feae34")
E_OURO_ESC = hexc("be4a2f")
E_VERM_L = hexc("f6757a")
E_VERM = hexc("e43b44")
E_VERM_S = hexc("a22633")
E_VERDE_L = hexc("63c74d")
E_VERDE = hexc("3e8948")
E_VERDE_ESC = hexc("265c42")
E_BRANCO = hexc("ffffff")


def x2(cv):
    """Desenho em pixels do jogo -> grade de 32 (cada pixel vira um bloco 2x2)."""
    big = Canvas(cv.w * 2, cv.h * 2)
    big.blit(cv, 0, 0, 2)
    return big


def ponto(d, x, y, cor, parte=None):
    d.cv.set(x, y, cor, parte)


# ---------------------------------------------------------------- porta
def porta(peca):
    """peca: 0 topo, 1 meio, 2 base, 3 fechadura (so a placa dourada), 4 batente (aberta).
    Em 16x16: tabuas de 4 px (veio claro a esquerda, fresta escura), faixa de ferro de 3 px com
    rebites fora do contorno; contorno #3e2731 nas laterais (topo e base fecham em cima/embaixo)."""
    d = Desenho(16, 16)
    if peca == 3:
        d.rect(4, 3, 7, 10, E_OURO, "f")
        d.contorno({"f": E_MAD_S})
        d.rect(5, 4, 2, 1, E_OURO_L)
        d.rect(6, 6, 3, 2, E_CONT)   # buraco da chave: cabeca 3x2 e fenda de 1 px embaixo
        d.rect(7, 8, 1, 2, E_CONT)
        return x2(d.cv)
    if peca == 4:
        d.rect(0, 0, 16, 4, E_MAD, "b")
        d.contorno({"b": E_CONT})
        d.rect(1, 2, 14, 1, E_MAD_S)
        return x2(d.cv)
    d.rect(0, 0, 16, 16, E_MAD, "p")
    for x in (1, 5, 9, 13):
        d.rect(x, 0, 1, 16, E_MAD_L)
    for x in (4, 8, 12):
        d.rect(x, 0, 1, 16, E_MAD_S)
    y = {0: 3, 1: 7, 2: 10}[peca]
    d.rect(0, y, 16, 3, E_PEDRA_S)
    d.rect(0, y, 16, 1, E_PEDRA)
    for x in (2, 13):
        ponto(d, x, y + 1, E_FERRO_ESC)
    for yy in range(16):
        ponto(d, 0, yy, E_CONT)
        ponto(d, 15, yy, E_CONT)
    if peca == 0:
        d.rect(0, 0, 16, 1, E_CONT)
    if peca == 2:
        d.rect(0, 15, 16, 1, E_CONT)
    return x2(d.cv)


# ---------------------------------------------------------------- placa de pressao
def placa(apertada):
    d = Desenho(16, 16)
    d.rect(0, 12, 16, 4, E_PEDRA, "base")
    d.contorno({"base": E_PEDRA_ESC})
    d.rect(1, 13, 14, 1, E_PEDRA_L)
    if apertada:
        d.rect(2, 10, 12, 2, E_CONT)
        d.rect(3, 11, 10, 1, E_VERM)
    else:  # botao de 3 px de vermelho: brilho a esquerda, sombra embaixo
        d.rect(2, 8, 12, 4, E_CONT)
        d.rect(3, 9, 10, 3, E_VERM)
        d.rect(3, 9, 5, 1, E_VERM_L)
        d.rect(3, 11, 10, 1, E_VERM_S)
    return x2(d.cv)


# ---------------------------------------------------------------- mastro com ponteira
def _mastro(d, x, y0, y1):
    """Mastro de 3 px: contorno escuro, filete de luz e corpo (luz de cima/esquerda)."""
    for y in range(y0, y1):
        ponto(d, x, y, E_VERDE_ESC)
        ponto(d, x + 1, y, E_VERDE_L)
        ponto(d, x + 2, y, E_VERDE)


def _ponteira(d, x):
    """Bolinha dourada de 5x4 em cima do mastro (x = coluna do contorno esquerdo). Desenhada
    por ultimo, igual em todos os quadros."""
    d.rect(x + 1, 0, 3, 1, E_CONT)
    d.rect(x + 1, 3, 3, 1, E_CONT)
    d.rect(x, 1, 1, 2, E_CONT)
    d.rect(x + 4, 1, 1, 2, E_CONT)
    d.rect(x + 1, 1, 3, 2, E_OURO)
    ponto(d, x + 1, 1, E_OURO_L)


# ---------------------------------------------------------------- bandeira de saida
def saida(q):
    d = Desenho(20, 48)
    d.rect(1, 45, 8, 3, E_VERDE, "base")
    d.contorno({"base": E_VERDE_ESC})
    _mastro(d, 3, 4, 45)
    for c in range(14):  # bandeira: colunas de 1 px que sobem e descem numa onda
        h = 11 - c // 4
        dy = int(round(math.sin(q * 2 * math.pi / 16.0 + c * 0.6)))
        y = 5 + (11 - h) // 2 + dy
        d.rect(6 + c, y, 1, h, E_OURO_L if c % 4 != 3 else E_OURO, "bandeira")
    # contorno escuro de 1 px como as outras pecas (caixa, placa, cerca); o laranja #be4a2f
    # nao e escuro e deixava a bandeira sem borda
    d.contorno({"bandeira": E_CONT})
    _ponteira(d, 2)
    return x2(d.cv)


# ---------------------------------------------------------------- checkpoint
def checkpoint(q):
    """q 0: apagado (bandeira vermelha murcha, presa ao mastro); 1..16: aceso (verde no alto,
    tremulando)."""
    d = Desenho(14, 28)
    d.rect(0, 25, 7, 3, E_VERDE, "base")
    d.contorno({"base": E_VERDE_ESC})
    _mastro(d, 2, 4, 25)
    if q > 0:
        for c in range(8):
            h = 7 - c // 2
            dy = int(round(math.sin((q - 1) * 2 * math.pi / 16.0 + c * 0.7)))
            y = 5 + (7 - h) // 2 + dy
            d.rect(5 + c, y, 1, h, E_VERDE_L if c < 6 else E_VERDE, "bandeira")
        d.contorno({"bandeira": E_VERDE_ESC})
    else:
        for c, (y0, y1) in enumerate(((11, 21), (12, 20), (13, 19), (14, 18), (15, 17))):
            d.rect(5 + c, y0, 1, y1 - y0, E_VERM, "bandeira")
        d.contorno({"bandeira": E_CONT})
        d.rect(5, 18, 1, 2, E_VERM_S)   # dobra do pano, embaixo
        d.rect(6, 17, 1, 2, E_VERM_S)
        ponto(d, 7, 17, E_VERM_S)
    _ponteira(d, 1)
    return x2(d.cv)


# ---------------------------------------------------------------- cipo
def cipo(q):
    """Trecho de cipo de 16x16 que repete na vertical: caule de 2 px (luz a esquerda) com
    contorno so a direita, 2 folhas e 1 flor presas no caule por um peciolo de 1 px (a ponta das
    folhas balanca 1 px)."""
    d = Desenho(16, 16)
    for y in range(16):
        x = 7 if (y // 4) % 2 == 0 else 8
        ponto(d, x, y, E_VERDE_L)
        ponto(d, x + 1, y, E_VERDE)
        ponto(d, x + 2, y, E_VERDE_ESC)
    dy = int(round(math.sin(2 * math.pi * q / 16.0)))
    # folha da esquerda (linhas 2-3), presa no caule em x=7
    d.rect(4, 2, 3, 1, E_VERDE_L)
    d.rect(4, 3, 3, 1, E_VERDE)
    d.rect(4, 4, 3, 1, E_VERDE_ESC)
    d.rect(3, 2 + dy, 1, 2, E_VERDE)        # ponta que balanca
    ponto(d, 3, 1 + dy, E_VERDE_L)
    # folha da direita (linhas 10-11), presa no caule em x=11 (contorno do caule)
    d.rect(11, 10, 3, 1, E_VERDE_L)
    d.rect(11, 11, 3, 1, E_VERDE)
    d.rect(11, 12, 3, 1, E_VERDE_ESC)
    d.rect(14, 10 - dy, 1, 2, E_VERDE)
    ponto(d, 14, 9 - dy, E_VERDE_L)
    ponto(d, 10, 11, E_VERDE)               # peciolo: prende a folha no caule
    # flor 3x3 encostada no caule, a esquerda
    ponto(d, 5, 6, E_VERM_L)
    d.rect(4, 7, 3, 1, E_VERM_L)
    ponto(d, 5, 8, E_VERM)
    ponto(d, 5, 7, E_OURO_L)
    ponto(d, 7, 7, E_VERDE)                 # peciolo: prende a flor no caule (x=8 nessas linhas)
    return x2(d.cv)


# ---------------------------------------------------------------- pedra que cai
def pedra_cai(rachada):
    """Bloco de pedra fria (a mesma rampa do castelo); rachadura em diagonal continua que
    cresce no quadro rachado."""
    d = Desenho(16, 16)
    d.rect(0, 0, 16, 15, E_PEDRA, "p")
    d.contorno({"p": E_PEDRA_ESC})
    d.rect(1, 1, 14, 1, E_PEDRA_L)
    d.rect(1, 1, 1, 12, E_PEDRA_L)
    d.rect(1, 13, 14, 1, E_PEDRA_S)
    d.rect(14, 2, 1, 12, E_PEDRA_S)
    ponto(d, 4, 10, E_PEDRA_S)   # pintinha da pedra, longe da rachadura
    racha = [(9, 4), (8, 5), (7, 6)]
    if rachada:
        racha = [(10, 3), (9, 4), (8, 5), (7, 6), (6, 7), (5, 8), (8, 7), (9, 8)]
    for x, y in racha:
        ponto(d, x, y, E_FERRO_ESC)
    return x2(d.cv)


# ---------------------------------------------------------------- vento
def vento(vertical):
    if vertical:  # seta para cima (^) com rastro que some embaixo (nao parece chuva)
        d = Desenho(12, 12)
        ponto(d, 5, 1, E_BRANCO)        # ponta em triangulo
        d.rect(4, 2, 3, 1, E_BRANCO)
        d.rect(3, 3, 5, 1, E_BRANCO)
        d.rect(5, 4, 1, 4, E_BRANCO)    # haste
        ponto(d, 5, 9, E_PEDRA_L)
        ponto(d, 5, 11, E_PEDRA)
        return x2(d.cv)
    # horizontal: o mesmo desenho deitado, ponta ">" para a DIREITA e rastro que some a esquerda
    # (o jogo espelha o quadro para o vento que vai para a esquerda)
    d = Desenho(12, 12)
    ponto(d, 10, 5, E_BRANCO)       # ponta em triangulo
    d.rect(9, 4, 1, 3, E_BRANCO)
    d.rect(8, 3, 1, 5, E_BRANCO)
    d.rect(4, 5, 4, 1, E_BRANCO)    # haste
    ponto(d, 2, 5, E_PEDRA_L)
    ponto(d, 0, 5, E_PEDRA)
    return x2(d.cv)


# ---------------------------------------------------------------- placas de madeira
# As duas placas: faixa de luz #d77643 em cima, corpo #b86f50, sombra #733e39 embaixo, contorno
# #3e2731 de 1 px, detalhe de 1 px e poste com 1 px claro e 1 px escuro.
def dica():
    d = Desenho(16, 20)
    d.rect(1, 1, 14, 9, E_MAD, "tabua")
    d.contorno({"tabua": E_CONT})
    d.rect(2, 2, 12, 1, E_MAD_L)
    d.rect(2, 8, 12, 1, E_MAD_S)
    # duas linhas de "texto" de 1 px, separadas por 1 px de madeira (com espaco entre palavras)
    d.rect(3, 4, 3, 1, E_CONT)
    d.rect(7, 4, 5, 1, E_CONT)
    d.rect(3, 6, 4, 1, E_CONT)
    d.rect(8, 6, 2, 1, E_CONT)
    d.rect(7, 10, 1, 10, E_MAD)
    d.rect(8, 10, 1, 10, E_CONT)
    return x2(d.cv)


def seta():
    d = Desenho(20, 24)
    # tabua de 9 linhas (contorno 3 e 11) simetrica em volta da linha 7, onde fica a haste
    d.rect(1, 3, 13, 9, E_MAD, "tabua")
    for c, (y0, y1) in enumerate(((3, 12), (4, 11), (5, 10), (6, 9), (7, 8))):  # ponta da placa
        d.rect(14 + c, y0, 1, y1 - y0, E_MAD, "tabua")
    d.contorno({"tabua": E_CONT})
    d.rect(2, 4, 13, 1, E_MAD_L)
    d.rect(2, 10, 13, 1, E_MAD_S)
    d.rect(3, 7, 9, 1, E_CONT)      # seta de 1 px: haste e ponta em ">", simetrica
    for x, y in ((9, 5), (10, 6), (10, 8), (9, 9)):
        ponto(d, x, y, E_CONT)
    d.rect(9, 12, 1, 12, E_MAD)
    d.rect(10, 12, 1, 12, E_CONT)
    return x2(d.cv)


# ---------------------------------------------------------------- junco
def junco(q):
    """Moita de 3 folhas de 2 px (luz a esquerda) que balancam juntas (mesma fase) a partir da
    base, o deslocamento crescendo com a altura; 2 taboas presas nas folhas do meio e da direita.
    Bases espacadas (2, 6, 11) e a folha da esquerda mais baixa que a taboa do meio: em nenhum
    quadro uma taboa encosta numa folha vizinha (o contorno dela fica inteiro)."""
    d = Desenho(16, 28)
    folhas = [(2, 17), (6, 25), (11, 18)]   # (x da base, altura)
    taboas = (1, 2)
    s = math.sin(2 * math.pi * q / 16.0)
    for i, (x, h) in enumerate(folhas):
        topo = 28 - h

        def ond(y):
            t = (27 - y) / float(h)
            return int(round(s * 2.0 * t ** 1.5))
        for y in range(topo, 28):
            o = ond(y)
            ponto(d, x + o, y, E_VERDE_L)
            ponto(d, x + 1 + o, y, E_VERDE)
        ponto(d, x + 1 + ond(topo), topo, E_VERDE_ESC)  # ponta fina
        if i in taboas:
            o = ond(topo + 2)
            tx, ty = x + o - 1, topo + 1
            # contorno so nas laterais, desenhado direto (sem contorno de silhueta): o miolo
            # 2x6 fica inteiro em todos os quadros, mesmo quando a folha de baixo se desloca
            d.rect(tx, ty, 4, 6, E_CONT, "taboa")
            d.rect(tx + 1, ty, 2, 6, E_MAD, "taboa")
            d.rect(tx + 1, ty + 1, 1, 2, E_MAD_L)
    return x2(d.cv)


# ---------------------------------------------------------------- brilho de coletar
def brilho(q):
    d = Desenho(32, 32)
    r = int(round(3 + 8 * math.sin(math.pi * q / 15.0)))  # cresce e encolhe em 16 quadros
    c = 16
    d.rect(c - 1, c - r, 2, 2 * r, OURO, "b")
    d.rect(c - r, c - 1, 2 * r, 2, OURO, "b")
    if r >= 7:
        k = r // 2
        for sx, sy in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
            d.rect(c + sx * k - 1, c + sy * k - 1, 2, 2, OURO_L, "b")
    d.rect(c - 1, c - 1, 2, 2, hexc("ffffff"))
    # sem contorno: a cruz e fina (2 px) e o contorno a deixaria toda escura
    if r > 4:
        for (x, y) in ((c - 1, c - r), (c - 1, c + r - 2), (c - r, c - 1), (c + r - 2, c - 1)):
            d.rect(x, y, 2, 2, OURO_L)
    return d.cv


# ---------------------------------------------------------------- portoes das arenas de chefe
# Barreiras que fecham a entrada e a saida da arena (scripts/arena_chefe.gd). Cada uma: 16
# quadros de 16x48 (pixels do jogo), entregues 2x (32x96 na grade de 32; sem entrada em QUADRO_32
# o reduz2 trata a tira como um quadro so e, como e 2x exato, so amostra). Quadro 0 = aberto (so
# um indicio do portao), 15 = fechado. A arena toca 0 -> 15 para fechar e 15 -> 0 para abrir.
# PORTAO_ALTURAS = quantos px da barreira aparecem em cada quadro (o mesmo que
# arena_chefe.gd PORTAO_ALTURAS usa no desenho de reserva): acelera, encosta, quica 1 vez e assenta.
PORTAO_W, PORTAO_H = 16, 48
PORTAO_ALTURAS = [2, 3, 5, 8, 12, 17, 23, 30, 38, 47, 48, 44, 48, 46, 48, 48]
E_GRAMA, E_GRAMA_S, E_GRAMA_ESC = hexc("63c74d"), hexc("3e8948"), hexc("265c42")
E_TERRA, E_TERRA_S = hexc("b86f50"), hexc("733e39")


def _portao_fazenda_cheio():
    """Barranco de terra com tampa de grama (as cores do tileset_grama) e dois juncos no alto:
    um pedaco do chao que sobe e fecha a passagem. Raizes e pedrinhas na terra."""
    d = Desenho(PORTAO_W, PORTAO_H)
    d.rect(1, 6, 14, 42, E_TERRA, "terra")
    d.rect(1, 4, 14, 5, E_GRAMA, "grama")       # tampa de grama
    d.rect(3, 3, 4, 1, E_GRAMA, "grama")        # tufos irregulares no topo
    d.rect(9, 3, 5, 1, E_GRAMA, "grama")
    for x, y in ((2, 9), (4, 10), (5, 9), (8, 10), (11, 9), (12, 10)):   # franja caindo na terra
        d.rect(x, y, 1, 1, E_GRAMA, "grama")
    d.contorno({"grama": E_GRAMA_ESC, "terra": E_CONT})
    d.rect(2, 8, 12, 1, E_GRAMA_S)              # sombra embaixo da tampa
    d.rect(3, 4, 3, 1, hexc("ffffff"))          # florzinha branca de miolo laranja
    ponto(d, 4, 4, E_OURO)
    for y in range(11, 47):                     # sombra da terra a direita (luz de cima/esq.)
        ponto(d, 13, y, E_TERRA_S)
    for x, y in ((3, 14), (4, 15), (4, 16), (5, 17), (9, 21), (10, 22), (10, 23), (11, 24),
                 (4, 29), (5, 30), (5, 31), (8, 36), (9, 37), (9, 38), (3, 42), (4, 43)):
        ponto(d, x, y, E_TERRA_S)               # raizes finas
    for x, y in ((7, 18), (11, 32), (6, 40)):   # pedrinhas
        d.rect(x, y, 2, 1, E_PEDRA)
        d.rect(x, y + 1, 2, 1, E_PEDRA_S)
    # juncos espetados no alto (2 folhas de 1 px com a ponta escura)
    for x, h in ((6, 4), (11, 3)):
        for y in range(4 - h, 4):
            ponto(d, x, y, E_VERDE_L)
        ponto(d, x, 3 - h, E_GRAMA_ESC)
    return d.cv


def _portao_torre_cheio():
    """Grade de ferro levadica: 3 barras verticais de 4 px (contorno, luz, corpo, contorno),
    3 travessas com rebites e pontas embaixo. Mesmas cores frias do tileset_pedra."""
    d = Desenho(PORTAO_W, PORTAO_H)
    for y0 in (5, 19, 33):                      # travessas (por baixo das barras)
        d.rect(0, y0, 16, 4, E_FERRO_ESC)
        d.rect(1, y0 + 1, 14, 1, E_PEDRA)
        d.rect(1, y0 + 2, 14, 1, E_PEDRA_S)
    for x0 in (1, 6, 11):
        d.rect(x0, 0, 4, 44, E_FERRO_ESC)
        d.rect(x0 + 1, 0, 1, 44, E_PEDRA_L)
        d.rect(x0 + 2, 0, 1, 44, E_PEDRA)
        d.rect(x0 + 1, 44, 2, 2, E_PEDRA_S)     # ponta: afina em 2 linhas e fecha escura
        ponto(d, x0, 44, E_FERRO_ESC)
        ponto(d, x0 + 3, 44, E_FERRO_ESC)
        ponto(d, x0, 45, E_FERRO_ESC)
        ponto(d, x0 + 3, 45, E_FERRO_ESC)
        d.rect(x0 + 1, 46, 2, 1, E_FERRO_ESC)
        for y0 in (5, 19, 33):                  # rebite no cruzamento
            ponto(d, x0 + 1, y0 + 1, E_BRANCO)
            ponto(d, x0 + 2, y0 + 2, E_PEDRA_S)
    return d.cv


def _portao_quadro(cheio, q, de_baixo):
    """Quadro q: mostra PORTAO_ALTURAS[q] px da barreira. de_baixo = sobe do chao (mostra o
    TOPO da barreira encostado embaixo); senao desce do teto (mostra a BASE encostada em cima)."""
    h = PORTAO_ALTURAS[q]
    cv = Canvas(PORTAO_W, PORTAO_H)
    for y in range(PORTAO_H):
        sy = y - (PORTAO_H - h) if de_baixo else y + (PORTAO_H - h)
        if 0 <= sy < PORTAO_H:
            for x in range(PORTAO_W):
                cv.px[y][x] = cheio.px[sy][x]
    return x2(cv)


def portao_fazenda(q):
    return _portao_quadro(_portao_fazenda_cheio(), q, True)


def portao_torre(q):
    return _portao_quadro(_portao_torre_cheio(), q, False)


# ---------------------------------------------------------------- saida
def pecas():
    return {
        "porta": [porta(i) for i in range(5)],
        "placa": [placa(False), placa(True)],
        "saida": [saida(i) for i in range(16)],
        "checkpoint": [checkpoint(i) for i in range(17)],  # 0 apagado, 1..16 aceso
        "cipo": [cipo(i) for i in range(16)],
        "pedra_cai": [pedra_cai(False), pedra_cai(True)],
        "vento": [vento(False), vento(True)],
        "dica": [dica()],
        "seta": [seta()],
        "junco": [junco(i) for i in range(16)],
        "brilho": [brilho(i) for i in range(16)],
        "portao_fazenda": [portao_fazenda(i) for i in range(16)],
        "portao_torre": [portao_torre(i) for i in range(16)],
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
