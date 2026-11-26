"""Itens de cenario na base de estilo (tools/arte/estilo.py), na ESCALA DO PATO: o pato e
pequeno (32 px da grade) e o cenario e grande. Gravados direto na grade (2 px = 1 px do jogo)
em assets/sprites/arte/cenario/.
Uso: python tools/arte/cenario.py [--salvar]   (previa em tools/arte/saida/cenario_escala.png)"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas, load_png, hexc, mapa_paleta  # noqa: E402
from estilo import Desenho, P, conferir  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
ARTE = os.path.join(ROOT, "assets", "sprites", "arte")
DEST = os.path.join(ARTE, "cenario")
OUT = os.path.join(HERE, "saida")
os.makedirs(OUT, exist_ok=True)

# Contorno da copa no verde mais escuro (#193c3e), como o arbusto e as copas do morro de perto:
# com #265c42 a borda direita da copa (sombra #3e8948, a cor do morro de longe) sumia no fundo e,
# com a arvore cortada pela beira da tela, sobrava so um arco solto (captura 16)
CONTORNO_COPA = hexc("193c3e")
ESC_MADEIRA = {"tronco": P["contorno_madeira"], "copa": CONTORNO_COPA}


# ------------------------------------------------------------------ retoque em 16x16
# Algumas pecas precisam de retoque DEPOIS da reducao 2x (o contorno refeito cria frestas e
# pixels soltos). em16() faz a mesma conversao do save() (reduz2 + paleta) e devolve tambem a
# cor final de cada cor de origem; amplia2() devolve a peca retocada na grade de 32 como
# ampliacao 2x exata, que o save() so amostra (e a paleta deixa igual: ja e Endesga 32).
def em16(cv, fw=None, fh=None, emenda=False):
    r = cv.reduz2(fw, fh, emenda)
    conta = {}
    for row in r.px:
        for c in row:
            if c is not None:
                conta[c[:3]] = conta.get(c[:3], 0) + 1
    m = mapa_paleta(list(conta), conta)
    out = Canvas(r.w, r.h)
    for y in range(r.h):
        for x in range(r.w):
            c = r.px[y][x]
            out.px[y][x] = None if c is None else m[c[:3]]
    return out, (lambda c: m.get(c[:3]))


def amplia2(cv16):
    big = Canvas(cv16.w * 2, cv16.h * 2)
    big.blit(cv16, 0, 0, 2)
    return big


def ilhas(cv, cor, max_px, viz_ok, troca):
    """Componentes (8-vizinhanca) da cor 'cor' com ate max_px pixels, cercados so por cores de
    viz_ok, viram 'troca' (cacos que a reducao deixou soltos)."""
    visto = set()
    for y in range(cv.h):
        for x in range(cv.w):
            if cv.px[y][x] != cor or (x, y) in visto:
                continue
            comp, pilha, borda = [], [(x, y)], set()
            visto.add((x, y))
            while pilha:
                a, b = pilha.pop()
                comp.append((a, b))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = a + dx, b + dy
                        c = cv.get(nx, ny)
                        if c == cor:
                            if (nx, ny) not in visto:
                                visto.add((nx, ny))
                                pilha.append((nx, ny))
                        else:
                            borda.add(c)
            if len(comp) <= max_px and borda and borda <= set(viz_ok):
                for a, b in comp:
                    cv.px[b][a] = troca


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
    # dx minimo 4 na grade de 32: com 2 a luz vira 1 px e o contorno refeito a engole (tronco jovem)
    d.luz("tronco", P["madeira_luz"], dx=max(4, k(4)), dy=0)
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


def brilho_solto(cv, luz, som, esc):
    """Pixel claro com no maximo 1 vizinho claro (4-viz.), encostado na sombra e cercado so
    por sombra/contorno vira sombra; repete ate parar."""
    mudou = True
    while mudou:
        mudou = False
        for y in range(cv.h):
            for x in range(cv.w):
                if cv.px[y][x] != luz:
                    continue
                viz = [cv.get(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
                if viz.count(luz) <= 1 and som in viz and all(v in (luz, som, esc) for v in viz):
                    cv.px[y][x] = som
                    mudou = True


def copa16(d):
    """Copa em 16x16 sem brilho solto do lado da sombra: (1) pixel claro quase sem vizinho
    claro e encostado na sombra vira sombra (repete ate parar); (2) na metade direita/de baixo,
    claro a ate 2 px do contorno (para a direita/para baixo) vira sombra, para a borda da
    sombra ir inteira ate o contorno (luz de cima/esquerda), sem fiapo claro de 1 px entre
    duas sombras."""
    cv, cor = em16(d.cv)
    luz, som, esc = cor(P["folha"]), cor(P["folha_sombra"]), cor(CONTORNO_COPA)
    xs = [x for y in range(cv.h) for x in range(cv.w) if cv.px[y][x] is not None]
    ys = [y for y in range(cv.h) for x in range(cv.w) if cv.px[y][x] is not None]
    mx, my = (min(xs) + max(xs)) / 2.0, (min(ys) + max(ys)) / 2.0
    brilho_solto(cv, luz, som, esc)
    troca = []
    for y in range(cv.h):
        for x in range(cv.w):
            if cv.px[y][x] != luz:
                continue
            if x > mx and esc in (cv.get(x + 1, y), cv.get(x + 2, y)):
                troca.append((x, y))
            elif y > my and esc in (cv.get(x, y + 1), cv.get(x, y + 2)):
                troca.append((x, y))
            elif x > mx and cv.get(x - 1, y) == som and cv.get(x + 1, y) == som:
                troca.append((x, y))  # fiapo claro de 1 px entre duas sombras
    for x, y in troca:
        cv.px[y][x] = som
    brilho_solto(cv, luz, som, esc)
    return amplia2(cv)


# ------------------------------------------------------------------ arbusto
# o arbusto fica na frente do morro de perto (verde #63c74d): o miolo e um verde mais escuro
# da Endesga e o verde do morro so aparece como brilho no alto a esquerda
ARB = hexc("3e8948")
ARB_SOMBRA = hexc("265c42")
ARB_LUZ = hexc("63c74d")
ARB_CONTORNO = hexc("193c3e")


def arbusto():
    d = Desenho(96, 56)
    for cx, cy, rx, ry in [(26, 34, 24, 20), (70, 34, 24, 20), (48, 26, 30, 24)]:
        d.elipse(cx, cy, rx, ry, ARB, "copa")
    d.rect(6, 38, 84, 18, ARB, "copa")
    d.sombra("copa", ARB_SOMBRA, dx=7, dy=8)
    d.luz("copa", ARB_LUZ, dx=5, dy=5)
    cv = d.cv
    # meias-luas dos tufos com 2 px de grosso na grade de 32 (inteiras depois da reducao)
    for cx, cy, rx, ry in [(30, 34, 12, 10), (66, 30, 13, 10)]:
        fora = set(cv.mask_ellipse(cx, cy, rx, ry))
        dentro = set(cv.mask_ellipse(cx - 6, cy - 6, rx, ry))
        for x, y in fora - dentro:
            if cv.part[y][x] == "copa" and cv.px[y][x] == ARB:
                cv.px[y][x] = ARB_SOMBRA
    for fx, fy in [(20, 22), (50, 12), (58, 24), (64, 42)]:
        d.flor(fx, fy)
    d.contorno({"copa": ARB_CONTORNO})
    return d


def arbusto16():
    """Arbusto em 16x16 sem cacos de sombra soltos no verde (nem de verde solto na sombra)."""
    cv, _ = em16(arbusto().cv)
    flor = [c for c in (cv.get(x, y) for y in range(cv.h) for x in range(cv.w))
            if c is not None and c[:3] not in (ARB[:3], ARB_SOMBRA[:3], ARB_LUZ[:3], ARB_CONTORNO[:3])]
    ilhas(cv, ARB_SOMBRA, 3, [ARB, ARB_LUZ] + flor, ARB)
    ilhas(cv, ARB_LUZ, 3, [ARB] + flor, ARB)
    ilhas(cv, ARB, 3, [ARB_LUZ], ARB_LUZ)
    brilho_solto(cv, ARB_LUZ, ARB_SOMBRA, ARB_CONTORNO)
    return amplia2(cv)


# ------------------------------------------------------------------ cerca
def cerca(tipo="meio"):
    """Trecho de 32 px (1 bloco) com um mourao no meio. tipo: 'esq', 'meio', 'dir' (as pontas
    fecham as tabuas)."""
    d = Desenho(32, 48)
    # nas pontas a tabua acaba DENTRO do mourao (11..21): toco para fora vira so contorno em 16
    x0 = 0 if tipo != "esq" else 12
    x1 = 32 if tipo != "dir" else 20
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


def celeiro16():
    """Celeiro em 16x16 com o telhado retocado: na aba ingreme a reducao tira o contorno entre
    a sombra do telhado e a parede e o fio de luz. Em cada linha da aba ingreme fica, de fora
    para dentro: contorno, luz (so na esquerda), madeira, 1 px de sombra, 1 px de contorno,
    parede. E o pe do portao (friso branco) fecha no contorno da parede, nao em cinza."""
    cv, cor = em16(celeiro().cv)
    esc = cor(P["contorno_madeira"])
    luz = cor(P["madeira_luz"])
    mad = cor(P["madeira"])
    som = cor(P["madeira_sombra"])
    parede = {cor(P["vermelho"]), cor(P["vermelho_sombra"]), cor(P["vermelho_luz"])} - {None}
    for y in range(cv.h):
        row = cv.px[y]
        cheios = [x for x in range(cv.w) if row[x] is not None]
        if not cheios:
            continue
        # esquerda: do contorno de fora ate o primeiro pixel de parede
        a = cheios[0]
        b = next((x for x in range(a, cv.w) if row[x] in parede), None)
        if b is None or row[a] != esc or not 4 <= b - a <= 12:
            continue
        if any(row[x] not in (esc, luz, mad, som) for x in range(a, b)):
            continue  # linha que ja passou do beiral (friso)
        for x in range(a + 1, b):
            row[x] = mad
        row[a + 1] = luz
        row[b - 2], row[b - 1] = som, esc
        # direita (espelho, sem luz: a luz vem da esquerda)
        a = cheios[-1]
        b = next((x for x in range(a, -1, -1) if row[x] in parede), None)
        if b is None or row[a] != esc or not 4 <= a - b <= 12:
            continue
        if any(row[x] not in (esc, luz, mad, som) for x in range(b + 1, a + 1)):
            continue
        for x in range(b + 1, a):
            row[x] = mad
        row[b + 2], row[b + 1] = som, esc
    # fio de luz continuo na aba esquerda inteira, ate o beiral
    for y in range(cv.h):
        row = cv.px[y]
        cheios = [x for x in range(cv.w) if row[x] is not None]
        if cheios and row[cheios[0]] == esc and cv.get(cheios[0] + 1, y) == mad:
            row[cheios[0] + 1] = luz
    base = cv.px[cv.h - 1]
    cont = {}
    for c in base:
        if c is not None:
            cont[c] = cont.get(c, 0) + 1
    fundo = max(cont, key=cont.get)
    cinza = cor(P["contorno_cinza"])
    for x in range(cv.w):
        if base[x] is not None and base[x] == cinza:
            base[x] = fundo
    return amplia2(cv)


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
    # varanda de madeira (o trilho e retocado em 16x16: moinho_corpo16)
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


def moinho_corpo16():
    """Moinho em 16x16 com os detalhes retocados depois da reducao: arco da porta fechado,
    trilho da varanda continuo (contorno em cima, madeira embaixo), viga de baixo com o
    contorno inteiro e as linhas de contorno do telhado e da varanda sem pixel de outra cor."""
    cv, cor = em16(moinho_corpo().cv)
    esc_mad = cor(P["contorno_madeira"])
    mad = cor(P["madeira"])
    esc_tel = cor(P["contorno_vermelho"])
    creme = {cor(P["creme"]), cor(P["creme_luz"]), cor(P["creme_sombra"])} - {None}

    def linha(y, c, so_meio=True):
        xs = [x for x in range(cv.w) if cv.px[y][x] is not None]
        for x in range(xs[0] + 1 if so_meio else xs[0], xs[-1] if so_meio else xs[-1] + 1):
            cv.px[y][x] = c
    linha(78 // 2 - 1, esc_tel, False)   # base do telhado
    linha(132 // 2, esc_mad, False)      # topo do trilho
    linha(132 // 2 + 1, mad)             # trilho (madeira continua)
    linha(148 // 2, esc_mad, False)      # topo da viga
    linha(156 // 2 - 1, esc_mad, False)  # base da viga
    # arco da porta: creme encostado (4-viz.) na madeira da porta vira contorno
    porta = {mad, cor(P["madeira_sombra"]), cor(P["amarelo"])}
    troca = []
    for y in range(180 // 2, 204 // 2):
        for x in range(60 // 2, 100 // 2):
            if cv.px[y][x] in creme and any(cv.get(x + dx, y + dy) in porta
                                            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                troca.append((x, y))
    for x, y in troca:
        cv.px[y][x] = esc_mad
    return amplia2(cv)


PAS_QUADRO = 192
PAS_QUADROS = 16  # um quarto de volta (as 4 pas sao iguais), 16 quadros


# As pas sao desenhadas DIRETO em 16x16 (quadro de 96x96 do jogo) e entregues ampliadas 2x:
# girar poligonos na grade de 32 e reduzir desfazia a grade das velas e a vara nos angulos
# diagonais. Aqui cada angulo e rasterizado no pixel final (centro do pixel dentro do
# poligono), com o contorno de 1 px feito no proprio quadro, grade de 1 px tracada por
# Bresenham e o cubo carimbado igual em todos os quadros (nao pulsa).
PAS_COR = {
    "vela": hexc("ffffff"), "grade": hexc("c0cbdc"), "esc_vela": hexc("5a6988"),
    "haste": hexc("b86f50"), "esc_haste": hexc("3e2731"), "cubo": hexc("d77643"),
    "cubo_luz": hexc("e4a672"),
}
CUBO = ["..AAAA..",
        ".ACCCCA.",
        "ACLCCCCA",
        "ACCCCCCA",
        "ACCCCCCA",
        "ACCCCCCA",
        ".ACCCCA.",
        "..AAAA.."]


def _dentro(pt, poli):
    x, y = pt
    ok = False
    n = len(poli)
    for k in range(n):
        x1, y1 = poli[k]
        x2, y2 = poli[(k + 1) % n]
        if (y1 > y) != (y2 > y) and x < x1 + (y - y1) * (x2 - x1) / (y2 - y1):
            ok = not ok
    return ok


def _bresenham(x0, y0, x1, y1):
    pts = []
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
    err = dx + dy
    while True:
        pts.append((x0, y0))
        if x0 == x1 and y0 == y1:
            return pts
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy


def moinho_pas16(i):
    S = PAS_QUADRO // 2
    c = S / 2.0
    ang0 = math.radians(90.0 * i / PAS_QUADROS)
    parte = [[None] * S for _ in range(S)]
    px = [[None] * S for _ in range(S)]

    def rot(u, v, a):
        sa, ca = round(math.sin(a), 9), round(math.cos(a), 9)
        return (c + u * sa + v * ca, c - u * ca + v * sa)

    def enche(poli, nome):
        xs = [p[0] for p in poli]
        ys = [p[1] for p in poli]
        for y in range(max(0, int(min(ys)) - 1), min(S, int(max(ys)) + 2)):
            for x in range(max(0, int(min(xs)) - 1), min(S, int(max(xs)) + 2)):
                if _dentro((x + 0.5, y + 0.5), poli):
                    parte[y][x] = nome
    angs = [ang0 + kk * math.pi / 2.0 for kk in range(4)]
    # vela: u 11..45 ao longo da pa, v 0..14 para o lado (encosta na vara, sem fresta de ceu)
    for a in angs:
        enche([rot(11, 0, a), rot(45, 0, a), rot(45, 14, a), rot(11, 14, a)], "vela")
    # vara: 4 px de largura (2 de madeira + contorno dos dois lados)
    for a in angs:
        enche([rot(-2, -2, a), rot(47, -2, a), rot(47, 2, a), rot(-2, 2, a)], "haste")
    for y in range(S):
        for x in range(S):
            p = parte[y][x]
            if p is None:
                continue
            viz = [parte[y + dy][x + dx] if 0 <= x + dx < S and 0 <= y + dy < S else None
                   for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
            if p == "haste":
                px[y][x] = PAS_COR["esc_haste"] if any(v != "haste" for v in viz) else PAS_COR["haste"]
            else:
                px[y][x] = PAS_COR["esc_vela"] if None in viz else PAS_COR["vela"]
    # grade da vela: 1 linha ao longo (meio da vela) e 2 de traves, so no miolo branco
    for a in angs:
        for (u0, v0), (u1, v1) in (((11, 7.5), (45, 7.5)), ((22.5, 0), (22.5, 14)), ((33.5, 0), (33.5, 14))):
            p0, p1 = rot(u0, v0, a), rot(u1, v1, a)
            for x, y in _bresenham(int(p0[0]), int(p0[1]), int(p1[0]), int(p1[1])):
                if 0 <= x < S and 0 <= y < S and px[y][x] == PAS_COR["vela"]:
                    px[y][x] = PAS_COR["grade"]
    # cubo fixo (8x8 centrado no eixo), igual em todos os quadros
    o = S // 2 - 4
    for j, row in enumerate(CUBO):
        for k, ch in enumerate(row):
            if ch != ".":
                px[o + j][o + k] = {"A": PAS_COR["esc_haste"], "C": PAS_COR["cubo"],
                                    "L": PAS_COR["cubo_luz"]}[ch]
    cv = Canvas(S, S)
    cv.px = px
    return amplia2(cv)


def tira(quadros):
    quadros = [getattr(q, "cv", q) for q in quadros]
    w, h = quadros[0].w, quadros[0].h
    cv = Canvas(w * len(quadros), h)
    for i, q in enumerate(quadros):
        cv.blit(q, i * w, 0)
    return cv


# ------------------------------------------------------------------ todas as pecas
def pecas():
    cerca_cv = Canvas(96, 48)
    for i, t in enumerate(("esq", "meio", "dir")):
        cerca_cv.blit(cerca(t).cv, i * 32, 0)
    return {
        "arvore_tronco": arvore_tronco(1.0).cv,
        "arvore_copa": copa16(arvore_copa(1.0)),
        "arvore_jovem_tronco": arvore_tronco(0.6).cv,
        "arvore_jovem_copa": copa16(arvore_copa(0.6, macas=False)),
        "arbusto": arbusto16(),
        "cerca": cerca_cv,
        "celeiro": celeiro16(),
        "moinho_corpo": moinho_corpo16(),
        "moinho_pas": tira([moinho_pas16(i) for i in range(PAS_QUADROS)]),
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
