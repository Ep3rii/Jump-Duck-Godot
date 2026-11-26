"""Chefes na pixel art quadradinha (lote 2): jacare gigante (Fase 3) e gaviao chefe (Fase final).
Tamanho: 64x64 por quadro na grade (32x32 no jogo). O jacare e o atordoado do gaviao sao desenhados
direto em 32x32 e ampliados 2x; as poses de voo do gaviao vem de inimigos.ave(), sao reduzidas aqui
mesmo e ganham os acabamentos do chefe (cores Endesga, contorno #181425, olho, bico, cauda).
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
# Cores ja na Endesga 32 (a conversao nao escolhe nada sozinha). O chefe e desenhado direto em
# 32x32 (1 px = 1 px do jogo) e so ampliado 2x para a grade de 64: o reduz2 ve blocos 2x2 de uma
# cor so e apenas amostra, entao olho, dentes, narina e estrelas saem exatamente como aqui.
VERDE, VERDE_L, VERDE_S, VERDE_ESC = hexc("3e8948"), hexc("63c74d"), hexc("265c42"), hexc("193c3e")
BARRIGA, ESCAMA = hexc("ead4aa"), hexc("265c42")
DENTE, BOCA, BOCA_ESC = hexc("ffffff"), hexc("e43b44"), hexc("a22633")
BOCHECHA, BOCHECHA_ESC = hexc("f6757a"), hexc("a22633")
ESTRELA, OLHO, PUPILA = hexc("fee761"), hexc("fee761"), hexc("181425")
CURATIVO = hexc("e4a672")
PINGO, PINGO_LUZ = hexc("2ce8f5"), hexc("ffffff")
JG_BARRIGA = 28  # linha da barriga no quadro de 32 (PIVO.y em scripts/jacare_chefe.gd)


def _amplia2(cv):
    """Quadro desenhado em 32x32 -> grade de 64 (blocos 2x2 de uma cor so)."""
    out = Canvas(cv.w * 2, cv.h * 2)
    out.blit(cv, 0, 0, 2)
    return out


def _estrela(cv, cx, cy, cor=None, miolo=None, contorno=None):
    """Estrela de tontura em "+" de 3x3 (forma fixa), opcionalmente com contorno de 1 px."""
    cor, miolo = cor or ESTRELA, miolo or DENTE
    braco = ((0, -1), (-1, 0), (1, 0), (0, 1))
    if contorno is not None:
        for dx, dy in braco + ((0, 0),):
            for ex, ey in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                x, y = cx + dx + ex, cy + dy + ey
                if cv.inside(x, y) and cv.px[y][x] is None:
                    cv.px[y][x] = contorno
    for dx, dy in braco:
        cv.set(cx + dx, cy + dy, cor)
    cv.set(cx, cy, miolo)


def jacare_gigante(q):
    """64 quadros, 16 por estado: 0..15 nadando (cauda ondula, pernas remam); 16..31 saltando
    (16..23 subindo com o focinho para cima, 24..31 descendo com o focinho para baixo; boca
    aberta, patas esticadas e pingos caindo); 32..47 mordida (a boca abre aos poucos; o jogo
    escolhe pela abertura); 48..63 dor de dente (bochecha inchada e estrelas girando).
    Desenhado em 32x32 (pixels do jogo) usando quase o quadro inteiro: o corpo tem ~20 px de
    altura (o jacare comum tem 11), cabeca grande, cristas de 2 px nas costas, dentes de 2 px.
    A barriga fica na linha B = 28 (PIVO de jacare_chefe.gd); no salto o desenho inteiro e
    inclinado em degraus de 1 px (cada coluna desce/sobe, sem girar nem borrar)."""
    bloco, i = divmod(q, 16)
    nado, salto, mordida, dor = bloco == 0, bloco == 1, bloco == 2, bloco == 3
    subindo = salto and i < 8
    fase = 2 * math.pi * (i % 8 if salto else i) / (8.0 if salto else 16.0)
    d = Desenho(32, 32)
    B = JG_BARRIGA
    # cauda grossa que afina em degraus; so a ponta ondula 1 px
    o = int(round(math.sin(fase))) if (nado or salto) else 0
    d.rect(0, B - 7 + o, 4, 4, VERDE, "corpo")
    d.rect(2, B - 9, 5, 7, VERDE, "corpo")
    d.rect(5, B - 11, 6, 10, VERDE, "corpo")
    # corpo alto; cristas de 3x2 com o bico de 1 px (o miolo verde fica a mostra)
    d.rect(8, B - 13, 14, 13, VERDE, "corpo")
    d.apaga([(8, B - 13), (8, B - 1)])
    for cx in (3, 7, 11, 15):
        y0 = B - 11 if cx == 3 else (B - 13 if cx == 7 else B - 15)
        d.rect(cx, y0, 3, 2, VERDE, "corpo")
        d.rect(cx + 1, y0 - 1, 1, 1, VERDE, "corpo")
    # patas (miolo verde 3 x 2): nadando remam; no salto esticadas (frente para a frente,
    # tras para tras); na mordida e na dor paradas
    passo = int(round(math.cos(fase)))
    if salto:
        d.rect(4, B - 3, 6, 3, VERDE, "pata")      # pata de tras esticada para tras
        d.rect(19, B - 2, 6, 3, VERDE, "pata")     # pata da frente esticada para a frente
    else:
        p = passo if nado else 0
        d.rect(9 - p, B - 2, 5, 4, VERDE, "pata")
        d.rect(17 + p, B - 2, 5, 4, VERDE, "pata")
    # cabeca: cranio alto com a bossa do olho, focinho comprido; a maxila sobe k px quando a
    # boca abre, a mandibula fica parada e a nuca liga as duas
    k = int(round(7 * i / 15.0)) if mordida else (4 if salto else 0)
    d.rect(19, B - 15 - k, 9, 8, VERDE, "cabeca")        # cranio (B-15-k .. B-8-k)
    d.rect(21, B - 17 - k, 5, 3, VERDE, "cabeca")        # bossa do olho
    d.rect(27, B - 12 - k, 5, 4, VERDE, "cabeca")        # focinho (B-12-k .. B-9-k)
    d.rect(29, B - 13 - k, 2, 1, VERDE, "cabeca")        # narina
    d.rect(19, B - 8 - k, 4, k + 2, VERDE, "cabeca")     # nuca / dobradica
    d.rect(19, B - 7, 13, 6, VERDE, "cabeca")            # mandibula (B-7 .. B-2)
    if k:  # boca aberta: vermelho da base da maxila ao topo da mandibula
        d.rect(23, B - 7 - k, 9, k, BOCA, "boca")
    d.rect(9, B - 4, 12, 3, BARRIGA, None, so=["corpo"])
    d.rect(20, B - 4, 11, 2, BARRIGA, None, so=["cabeca"])
    d.luz("corpo", VERDE_L, dx=0, dy=2)
    d.luz("cabeca", VERDE_L, dx=0, dy=2)
    d.contorno({"corpo": VERDE_ESC, "cabeca": VERDE_ESC, "pata": VERDE_ESC, "boca": BOCA_ESC},
               juntas=[("cabeca", "boca")])
    cv = d.cv
    if k:  # sem faixa de luz no topo da mandibula (fica dentro da boca)
        for x in range(23, 32):
            for y in (B - 6, B - 5):
                if cv.px[y][x] == VERDE_L:
                    cv.px[y][x] = VERDE
    for x in range(10, 20, 3):  # escamas mais escuras no lombo
        for y in (B - 11, B - 12):
            if cv.px[y][x] == VERDE_L:
                cv.px[y][x] = ESCAMA
    # olho de 2x2: iris amarela atras, pupila escura na frente; sobrancelha brava em cima
    for y in (B - 15 - k, B - 14 - k):
        cv.set(22, y, OLHO)
        cv.set(23, y, PUPILA)
    cv.set(22, B - 16 - k, VERDE_ESC)
    cv.set(23, B - 16 - k, VERDE_ESC)
    if k == 0:  # boca fechada: linha da boca e presas de 2 px saindo dela
        for x in range(23, 31):
            cv.px[B - 8][x] = VERDE_ESC
        if not dor:
            for x in (24, 27, 30):
                cv.set(x, B - 7, DENTE)
                cv.set(x, B - 6, DENTE)
    else:  # presas de cima penduradas na maxila e de baixo na mandibula, alternadas
        for x in (24, 27, 30):
            cv.set(x, B - 7 - k, DENTE)
            if k >= 6:
                cv.set(x, B - 6 - k, DENTE)
        for x in (25, 28):
            cv.set(x, B - 8, DENTE)
            if k >= 6:
                cv.set(x, B - 9, DENTE)
    if dor:
        # bochecha inchada inteira dentro da mandibula, atras do canto da boca; pulsa 1 px
        grande = i % 8 < 4
        topo = B - 7 if grande else B - 6
        for x in (21, 22):
            cv.set(x, topo, BOCHECHA)
        for x in (20, 21, 22, 23):
            for y in range(topo + 1, B - 2):
                cv.set(x, y, BOCHECHA)
        # dente com curativo: dente de 2 px pendurado na linha da boca e a faixa bege enrolada
        for x in (26, 27):
            cv.set(x, B - 7, DENTE)
        for x in range(25, 29):
            cv.set(x, B - 6, CURATIVO)
        # 3 estrelas em "+" de forma fixa girando sobre a cabeca (so a posicao muda)
        for e in range(3):
            a = fase + e * 2.094
            _estrela(cv, 23 + int(round(6 * math.cos(a))), 4 + int(round(2 * math.sin(a))))
    if salto:
        # pingos de agua caindo da cauda e da barriga (2-3 px, ciano com brilho branco)
        for j, (px0, py0) in enumerate(((2, B - 2), (8, B), (14, B + 1))):
            y = py0 + (i % 8 + j * 3) % 6
            if 0 <= y < 31 and cv.px[y][px0] is None and cv.px[y + 1][px0] is None:
                cv.set(px0, y, PINGO_LUZ)
                cv.set(px0, y + 1, PINGO)
        # inclina em degraus de 1 px: subindo o focinho fica alto, descendo fica baixo
        cv = _inclina(cv, -0.16 if subindo else 0.12, 16)
    return _amplia2(cv)


def _inclina(cv, s, cx):
    """Desloca cada coluna x em round((x - cx) * s) px na vertical (degraus de 1 px)."""
    out = Canvas(cv.w, cv.h)
    for x in range(cv.w):
        dy = int(round((x - cx) * s))
        for y in range(cv.h):
            c = cv.px[y][x]
            if c is not None and 0 <= y + dy < cv.h:
                out.px[y + dy][x] = c
    return out


# ---------------------------------------------------------------- gaviao chefe
# Cores ja na Endesga 32: corpo e cabeca claros (#b86f50), asa de perto #733e39, asa de longe
# #3e2731, contorno de fora #181425. Assim o chefe tem 3 planos que leem sobre a parede azul
# escura da torre (antes corpo e asa caiam os dois em #733e39, da mesma luz da parede).
G_CORPO, G_ASA, G_ASA_LONGE = hexc("b86f50"), hexc("733e39"), hexc("3e2731")
G_BARRIGA, G_BICO = hexc("ead4aa"), hexc("fee761")
G_CAUDA = hexc("743f3a")       # marca a cauda no desenho; vira #733e39 com a ponta barrada
G_CAUDA_COR, G_CAUDA_MEIO = hexc("733e39"), hexc("be4a2f")
G_LUZ = hexc("e4a672")         # linha de luz no alto da cabeca e das costas
G_CONT, G_CONT_DENTRO = hexc("181425"), hexc("3e2731")
G_ESC_DESENHO = (ini.ESC_AVE[:3], (0x2a, 0x16, 0x08))  # contornos que a ave() usa
# asa "baixo" do chefe inclinada para tras (a vertical de ave() parecia quatro patas no chao)
G_ASA_BAIXO = [(-7, -1, 9, 7), (-12, 3, 7, 5), (-16, 5, 5, 4), (-18, 7, 3, 3)]
# cauda em leque de 3 penas (ponta para a esquerda; a ultima coluna encosta no corpo)
G_CAUDA_MAPA = ["..#####",
                ".#mlmmm",
                "#mldddd",
                "#mlrrmm",
                "#mldddd",
                ".#mlmmm",
                "..#####"]
# pata do mergulho/investida (coluna 1 = a perna; linha 0 = a linha de baixo do corpo)
G_PE_MAPA = [".o..",
             "ror.",
             "rood",
             ".rr."]
G_PATA, G_PATA_CONT = hexc("feae34"), hexc("be4a2f")
G_OMBRO = (17, 13)   # ombro da asa em pixel do jogo (ox, oy da ave() com k = 1.45, reduzido)
G_PONTA = 1.5        # quanto da ponta da asa (em px a partir da mais distante) recebe a luz


def _vazio(cv, x, y):
    return not cv.inside(x, y) or cv.px[y][x] is None


def _gaviao_32(pose):
    """Pose do gaviao chefe ja em 32x32 (pixels do jogo), com os acabamentos do chefe."""
    velha = ini.ASA_POSES["baixo"]
    ini.ASA_POSES["baixo"] = G_ASA_BAIXO
    try:
        a = ini.ave(pose, 1.45, G_CORPO, G_ASA, G_ASA_LONGE, G_CORPO, G_CAUDA, peito=G_BARRIGA, env=1.25)
    finally:
        ini.ASA_POSES["baixo"] = velha
    q = Canvas(64, 64)
    for y in range(min(64, a.h)):
        for x in range(min(64, a.w)):
            q.px[y][x] = a.px[y][x]
    cv = q.reduz2()  # a mesma reducao que o save() faria; daqui em diante tudo e pixel do jogo
    px = cv.px
    orig = [row[:] for row in px]
    viz4 = ((1, 0), (-1, 0), (0, 1), (0, -1))

    def cor_orig(x, y, *refs):
        c = orig[y][x]
        return c is not None and c[:3] in [r[:3] for r in refs]
    # o amarelo/laranja da ave() serve para o bico E para as patas: o bico fica na metade de
    # cima (ate by + 4); abaixo disso e pata, que sai daqui e ganha desenho proprio no fim
    amarelos = [(x, y) for y in range(32) for x in range(32) if y < 16 and cor_orig(x, y, ini.BICO)]
    lim_cab = (min(y for _, y in amarelos) + 4) if amarelos else 15
    pata = [(x, y) for y in range(lim_cab + 1, 32) for x in range(32) if cor_orig(x, y, ini.BICO, ini.BICO_ESC)]
    for x, y in pata:
        px[y][x] = None
    troca = {ini.OLHO[:3]: G_CONT, G_CAUDA[:3]: G_CAUDA_COR}
    troca_cab = {ini.BICO[:3]: G_BICO, ini.BICO_ESC[:3]: G_CONT_DENTRO}
    for y in range(32):
        for x in range(32):
            c = px[y][x]
            if c is None:
                continue
            if c[:3] in G_ESC_DESENHO:  # contorno: de fora no mais escuro, por dentro no marrom
                fora = any(_vazio(cv, x + dx, y + dy) for dx, dy in viz4)
                px[y][x] = G_CONT if fora else G_CONT_DENTRO
            elif c[:3] in troca:
                px[y][x] = troca[c[:3]]
            elif y <= lim_cab and c[:3] in troca_cab:
                px[y][x] = troca_cab[c[:3]]
    # bico: contorno de fora tambem no mais escuro, e a ponta do gancho escura
    for y in range(lim_cab + 1):
        for x in range(32):
            if cor_orig(x, y, ini.BICO_ESC):
                if any(_vazio(cv, x + dx, y + dy) for dx, dy in ((1, 0), (0, 1), (0, -1))):
                    px[y][x] = G_CONT
    # cauda: a da ave() vira um bloco na reducao; sai inteira (com o contorno que so encostava
    # nela) e entra um leque de 3 penas em degraus, desenhado em pixel do jogo: ponta escura de
    # 1 px, 1 px de marrom, faixa clara #e4a672 seguindo os degraus, linhas de dentro separando
    # as penas e o avermelhado so na pena do meio. So ocupa pixel vazio (a asa fica por cima).
    cauda = {(x, y) for y in range(32) for x in range(32) if cor_orig(x, y, G_CAUDA)}
    if cauda:
        for x, y in cauda:
            px[y][x] = None
        for y in range(32):
            for x in range(32):
                if px[y][x] not in (G_CONT, G_CONT_DENTRO):
                    continue
                miolo = [(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)
                         if (dx or dy) and cv.inside(x + dx, y + dy) and orig[y + dy][x + dx] is not None
                         and orig[y + dy][x + dx][:3] not in G_ESC_DESENHO]
                if miolo and all(m in cauda for m in miolo):
                    px[y][x] = None
        xr = max(x for x, _ in cauda)
        topo = int((min(y for _, y in cauda) + max(y for _, y in cauda)) / 2.0) - 3
        cores = {"#": G_CONT, "d": G_CONT_DENTRO, "m": G_CAUDA_COR, "l": G_LUZ, "r": G_CAUDA_MEIO}
        for j, linha in enumerate(G_CAUDA_MAPA):
            for i, ch in enumerate(linha):
                x, y = xr - len(linha) + 1 + i, topo + j
                if ch != "." and cv.inside(x, y) and px[y][x] is None:
                    px[y][x] = cores[ch]
    # cabeca: acha o bico (o amarelo mais alto e mais a esquerda) e redesenha olho e bico
    # direto em pixel do jogo: olho 2x2 (iris amarela atras, pupila escura na frente) a 1 px
    # do contorno, sobrancelha de 1 px, luz no alto da cabeca e bico em gancho sem vermelho
    if amarelos:
        by = min(y for _, y in amarelos)
        bx = min(x for x, y in amarelos if y <= by + 3)
        hx0 = bx - 1
        while hx0 > 0 and px[by][hx0 - 1] not in (None, G_CONT_DENTRO) and not _vazio(cv, hx0 - 2, by):
            hx0 -= 1  # borda de tras da cabeca na linha do olho
        for y in range(by - 1, by + 3):  # limpa olho e sobrancelha antigos
            for x in range(hx0, bx):
                if px[y][x] in (G_CONT, G_CONT_DENTRO, G_LUZ) and not _vazio(cv, x, y - 1)                         and not _vazio(cv, x - 1, y) and not _vazio(cv, x + 1, y):
                    px[y][x] = G_CORPO
        for x in range(hx0, bx - 1):  # linha de luz no alto da cabeca (1o miolo de cada coluna)
            for y in range(max(1, by - 4), by + 1):
                if px[y][x] == G_CORPO and px[y - 1][x] in (G_CONT, G_CONT_DENTRO):
                    px[y][x] = G_LUZ
                    break
        # olho 2x2: iris amarela atras, pupila escura na frente; a sobrancelha fica em cima da
        # iris (1 px atras da pupila), entao pupila e sobrancelha nao viram uma barra so, e
        # sobra face clara entre o olho e o bico
        px[by][bx - 4] = px[by + 1][bx - 4] = G_BICO
        px[by][bx - 3] = px[by + 1][bx - 3] = G_CONT
        px[by - 1][bx - 4] = G_CONT                      # sobrancelha brava
        px[by - 1][bx - 3] = G_CORPO
        for x in (bx - 2, bx - 1):
            if px[by][x] in (G_CONT, G_CONT_DENTRO):
                px[by][x] = G_CORPO
        for y in range(by - 1, by + 4):  # bico novo
            for x in range(bx, min(32, bx + 4)):
                c = orig[y][x]
                if c is not None and c[:3] in (ini.BICO[:3], ini.BICO_ESC[:3]) or px[y][x] == G_CONT:
                    px[y][x] = None
        bico = {(0, -1): G_CONT, (1, -1): G_CONT,
                (0, 0): G_BICO, (1, 0): G_BICO, (2, 0): G_CONT,
                (0, 1): G_BICO, (1, 1): G_BICO, (2, 1): G_CONT_DENTRO, (3, 1): G_CONT,
                (0, 2): G_CONT, (1, 2): G_CONT, (2, 2): G_CONT}
        for (dx, dy), c in bico.items():
            cv.set(bx + dx, by + dy, c)
        borda = []  # fecha o contorno da cabeca onde o bico antigo saiu
        for y in range(by - 2, min(32, by + 5)):
            for x in range(max(0, hx0 - 1), min(32, bx + 5)):
                c = px[y][x]
                if c is not None and c not in (G_CONT, G_CONT_DENTRO) and                         any(_vazio(cv, x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    borda.append((x, y))
        for x, y in borda:
            px[y][x] = G_CONT
    # patas desenhadas em pixel do jogo: amarelo #feae34 com contorno #be4a2f (nada de palito
    # escuro). No voo ficam recolhidas (1 linha amarela sob a barriga); no mergulho/investida
    # cada pata e uma perna de 1 px com dois dedos para a frente e a garra escura na ponta.
    if pata:
        y0 = min(y for _, y in pata)
        if pose == 6:
            y1 = max(y for _, y in pata)
            pernas = sorted({x for x, y in pata if y == y1 - 1})[:2]
            if len(pernas) == 2 and pernas[1] - pernas[0] < 4:
                pernas[0] = pernas[1] - 4
            for x, y in pata:  # a linha de baixo do corpo volta a ser contorno onde a perna saiu
                if y == y0:
                    px[y][x] = G_CONT
            for lx in pernas:
                for j, linha in enumerate(G_PE_MAPA):
                    for i, ch in enumerate(linha):
                        if ch != ".":
                            cv.set(lx - 1 + i, y0 + j, {"o": G_PATA, "r": G_PATA_CONT, "d": G_CONT_DENTRO}[ch])
        else:
            xs = sorted({x for x, y in pata if y == y0})
            for x in range(xs[0], xs[-1] + 1):
                cv.set(x, y0, G_PATA)
                cv.set(x, y0 + 1, G_PATA_CONT)
    # pontas das asas com luz: o miolo da asa de perto mais longe do ombro fica #e4a672
    asa = [(x, y) for y in range(32) for x in range(32) if cor_orig(x, y, G_ASA) and px[y][x] == G_ASA]
    if asa:
        ox, oy = G_OMBRO
        dist = {(x, y): math.hypot(x - ox, y - oy) for x, y in asa}
        dmax = max(dist.values())
        for (x, y), dd in dist.items():
            if dd >= dmax - G_PONTA:
                px[y][x] = G_LUZ
    return cv


def _gaviao_pose(pose):
    return _amplia2(_gaviao_32(pose))


def gaviao(q):
    """80 quadros, 16 por estado: 0..15 voo; 16..31 grito (asa no alto, batendo curto);
    32..47 mergulho; 48..63 investida; 64..79 atordoado (caido, estrelas girando)."""
    bloco, i = divmod(q, 16)
    if bloco == 0:
        return ini.voo16(_gaviao_pose)[i]
    if bloco == 1:  # grito: a asa so vai do alto ao meio e volta, e o corpo treme
        pose = (0, 0, 1, 1)[i % 4]
        return ini._desloca(_gaviao_pose(pose), (0, 2, 0, -2)[(i // 2) % 4], 0)
    if bloco == 2:  # mergulho: pose propria em diagonal (cabeca para baixo, asas fechadas)
        return mergulho(i)
    if bloco == 3:  # investida rente ao chao: corpo esticado, tremendo para frente e para tras
        return ini._desloca(_gaviao_pose(6), (0, 0, 2, 2)[i % 4], 0)
    return atordoado(i * 2 * math.pi / 16.0)


def mergulho(i):
    """Mergulho em diagonal (45 graus, cabeca para baixo e para a frente), desenhado direto em
    32x32 (pixels do jogo): asas fechadas coladas nas costas com as pontas para tras e para
    cima, cauda fechada apontando para cima, patas recolhidas sob a barriga, bico em gancho
    na ponta de baixo. Nos 16 quadros so treme 1 px e a luz corre pela ponta da asa."""
    d = Desenho(32, 32)
    # cauda fechada (para cima e para tras), ponta em degraus
    d.poli([(3, 2), (8, 1), (12, 6), (8, 10), (3, 6)], G_CAUDA_COR, "cauda")
    # corpo: capsula na diagonal, costas para cima/direita e barriga para baixo/esquerda
    d.poli([(12, 3), (25, 14), (19, 23), (5, 11)], G_CORPO, "corpo")
    # barriga clara do lado de baixo
    d.poli([(5, 11), (8, 10), (21, 21), (19, 24)], G_BARRIGA, None, so=["corpo"])
    # cabeca redonda na frente de baixo, com a face clara
    d.elipse(23.5, 20.5, 5.0, 5.0, G_CORPO, "cabeca")
    d.rect(21, 22, 4, 3, G_BARRIGA, None, so=["cabeca"])
    # asa fechada por cima das costas: do ombro ate a ponta, que passa da cauda para cima
    d.poli([(11, 1), (15, 1), (24, 11), (21, 14), (11, 6)], G_ASA, "asa")
    # bico em gancho apontando para baixo e para a frente
    d.poli([(26, 21), (30, 22), (31, 29), (28, 29), (26, 26)], G_BICO, "bico")
    # patas recolhidas: so os dedos amarelos sob a barriga
    d.rect(10, 15, 3, 2, G_PATA, "pata")
    d.luz("cabeca", G_LUZ, dx=0, dy=2)
    d.luz("corpo", G_LUZ, dx=0, dy=2)
    d.contorno({"corpo": G_CONT, "cabeca": G_CONT, "asa": G_CONT, "cauda": G_CONT, "bico": G_CONT,
                "pata": G_PATA_CONT},
               juntas=[("asa", "corpo"), ("asa", "cauda"), ("asa", "cabeca"), ("cabeca", "corpo"),
                       ("bico", "cabeca"), ("corpo", "cauda")])
    cv = d.cv
    for y in range(32):  # linhas de dentro no marrom escuro; so a borda de fora no mais escuro
        for x in range(32):
            if cv.px[y][x] == G_CONT and not any(_vazio(cv, x + dx, y + dy)
                                                  for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                cv.px[y][x] = G_CONT_DENTRO
    # penas da asa: duas linhas na diagonal, e a luz correndo pela ponta (sobe e desce)
    for x, y in ((15, 5), (16, 6), (18, 8), (19, 9)):
        if cv.px[y][x] == G_ASA:
            cv.px[y][x] = G_CONT_DENTRO
    luz = (i // 2) % 4
    for x, y in ((12 + luz, 2 + (luz > 1)), (13 + luz, 2 + (luz > 1))):
        if cv.inside(x, y) and cv.px[y][x] == G_ASA:
            cv.px[y][x] = G_LUZ
    # pena do meio da cauda com o avermelhado
    for x, y in ((5, 4), (6, 5), (7, 6)):
        if cv.px[y][x] == G_CAUDA_COR:
            cv.px[y][x] = G_CAUDA_MEIO
    # olho 2x2 (iris amarela atras, pupila na frente) com a sobrancelha brava em cima
    cv.px[18][24] = cv.px[19][24] = G_BICO
    cv.px[18][25] = cv.px[19][25] = G_CONT
    cv.px[17][24] = G_CONT
    cv.px[27][29] = G_CONT_DENTRO  # ponta escura do gancho
    # tremor de 1 px (o vento do mergulho)
    dx, dy = (0, 1, 1, 0)[(i // 4) % 4], (0, 0, 1, 1, 0, 0, -1, -1)[i % 8]
    return _amplia2(ini._desloca(cv, dx, dy))


def atordoado(ang0):
    """Caido de bruços, desenhado direto em 32x32 (pixels do jogo): corpo alto (10 px) com a
    barriga clara, asa caida por cima das costas com a ponta no chao, cauda em leque atras,
    cabeca com a face clara, olho em X de 3x3 e bico separado da cauda; 3 estrelas em "+" de
    forma fixa (com contorno escuro) girando acima da cabeca (ang0 = quanto ja giraram)."""
    d = Desenho(32, 32)
    # cauda em leque atras do corpo: pena do meio mais comprida (ponta em degraus)
    d.rect(2, 17, 6, 2, G_CAUDA_COR, "cauda")
    d.rect(1, 19, 7, 2, G_CAUDA_COR, "cauda")
    d.rect(2, 21, 6, 2, G_CAUDA_COR, "cauda")
    # corpo arredondado
    d.rect(5, 16, 16, 10, G_CORPO, "corpo")
    d.apaga([(5, 16), (20, 16), (5, 25), (20, 25)])
    d.rect(8, 22, 11, 2, G_BARRIGA, None, so=["corpo"])
    # asa caida sobre as costas, primarias pendendo ate o chao
    d.rect(7, 15, 11, 6, G_ASA, "asa")
    d.rect(4, 19, 5, 4, G_ASA, "asa")
    d.rect(3, 22, 4, 4, G_ASA, "asa")
    # cabeca deitada, com a face clara
    d.rect(19, 13, 9, 11, G_CORPO, "cabeca")
    d.apaga([(19, 13), (20, 13), (27, 13), (27, 14), (26, 13), (27, 23), (19, 23)])
    d.rect(21, 19, 5, 3, G_BARRIGA, None, so=["cabeca"])
    # bico em gancho a frente da cabeca
    d.rect(26, 16, 5, 3, G_BICO, "bico")
    d.rect(28, 19, 3, 1, G_BICO, "bico")
    d.luz("cabeca", G_LUZ, dx=0, dy=2)
    d.luz("corpo", G_LUZ, dx=0, dy=2)
    d.contorno({"corpo": G_CONT, "cabeca": G_CONT, "asa": G_CONT, "cauda": G_CONT, "bico": G_CONT},
               juntas=[("asa", "corpo"), ("asa", "cauda"), ("cabeca", "corpo"), ("bico", "cabeca"),
                       ("corpo", "cauda")])
    cv = d.cv
    # linhas de dentro no marrom escuro; so a borda de fora fica no mais escuro
    for y in range(32):
        for x in range(32):
            if cv.px[y][x] == G_CONT and not any(_vazio(cv, x + dx, y + dy)
                                                  for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                cv.px[y][x] = G_CONT_DENTRO
    # ponta da cauda como no voo: so o contorno escuro de 1 px, 1 px de marrom e a faixa clara
    # seguindo os degraus das penas; a pena do meio com o avermelhado
    for y in (17, 18, 19, 20, 21, 22):
        xl = 3 if y in (19, 20) else 4
        if cv.px[y][xl] == G_CAUDA_COR:
            cv.px[y][xl] = G_LUZ
    cv.px[19][4] = cv.px[19][5] = G_CAUDA_MEIO
    # penas da asa (linhas de separacao) e ponta escura do gancho
    for x in (10, 13):
        for y in (18, 19):
            cv.px[y][x] = G_CONT_DENTRO
    cv.px[19][29] = G_CONT_DENTRO
    # olho em X (3x3) na face, a 1 px do contorno
    for (x, y) in ((21, 15), (23, 15), (22, 16), (21, 17), (23, 17)):
        cv.px[y][x] = G_CONT
    for k in range(3):
        a = ang0 + k * 2.094
        # orbita mais alta (raio vertical 3.6): as 3 estrelas ficam sempre a 7+ px uma da outra
        # (os contornos nao se tocam) e a de baixo nao encosta na cabeca
        _estrela(cv, 22 + int(round(7 * math.cos(a))), 5 + int(round(3.6 * math.sin(a))), contorno=G_CONT)
    return _amplia2(cv)


# ---------------------------------------------------------------- saida
def tira(quadros):
    cv = Canvas(64 * len(quadros), 64)
    for i, q in enumerate(quadros):
        cv.blit(q, i * 64, 0)
    return cv


def pecas():
    return {
        "chefe_jacare": [jacare_gigante(i) for i in range(64)],
        "chefe_gaviao": [gaviao(i) for i in range(80)],
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
