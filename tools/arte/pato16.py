"""Animacoes do pato em 16x16 com pelo menos 15 quadros cada (16 por animacao).
Os quadros intermediarios saem dos mesmos numeros que desenham as poses aprovadas
(tools/arte/pato.py: posicao e altura de cada pe, subida do corpo, pose da asa), interpolados
na grade de 32 e reduzidos para 16 pelo pixelkit (contorno de 1 px refeito, paleta Endesga 32).
Depois o acabamento() repinta em 16 o que a reducao estraga: bico 3x2 laranja, olho #181425,
contorno #262b44, pes #feae34/#f77622 e furos. Dano e morte saem do pato parado acabado,
tingido ja com cores da Endesga 32 (olho fechado de dor; olho em X e pes pedalando na morte).
A pata (cutscene_arte.py) usa estes mesmos quadros.
Em 16x16 cada pe so anda de 1 em 1 pixel, entao parte dos quadros fica igual a vizinha: o
script conta e imprime quantos desenhos diferentes cada animacao tem.
Uso: python tools/arte/pato16.py [--salvar]   (previa e GIFs em tools/arte/saida/)"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import pato as P  # noqa: E402
from pixelkit import Canvas, save_gif  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
ARTE = os.path.join(ROOT, "assets", "sprites", "arte")
OUT = os.path.join(HERE, "saida")
N = 16  # quadros por animacao (a exigencia e 15 ou mais)


def para16(cv32):
    return cv32.reduz2(32, 32, False).paleta()


# ------------------------------------------------------------ acabamento em 16 (cores Endesga 32)
# A reducao 2x engole as pecas de 2 px (bico, olho) no contorno refeito e junta os amarelos dos
# pes em tons trocados; o acabamento repinta essas pecas direto na grade de 16, igual em todas
# as tiras (pato_* e, pela cutscene, a pata).
def _c(h):
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


CONT_VELHO = _c("5a6988")   # contorno que sai do pixelkit
CONT = _c("262b44")         # contorno do pato (mais escuro que os tijolos e as colinas do fundo)
OLHO = _c("181425")         # olho: 1 px, mais escuro que o contorno e sempre cercado de branco
BRANCO, SOMBRA = _c("ffffff"), _c("c0cbdc")
PE, PE_ESC = _c("feae34"), _c("f77622")          # pe da frente / perna de tras e sombra
BICO, BICO_ESC, BICO_CONT = _c("feae34"), _c("f77622"), _c("be4a2f")
VIZ4 = ((1, 0), (-1, 0), (0, 1), (0, -1))


def topo_cabeca(cv):
    return min(y for y in range(cv.h) if any(cv.px[y][x] is not None for x in range(8, 13)))


def bico16(cv, hx, y, claro_em_cima=True, cores=None):
    """Bico 3x2 laranja colado na cabeca: miolo em x=hx..hx+2 nas linhas y e y+1 (linha de cima
    clara, de baixo escura, para a luz vir de cima), contorno de 1 px so por fora."""
    claro, escuro, borda = cores or (BICO, BICO_ESC, BICO_CONT)
    for yy, cor in ((y, claro if claro_em_cima else escuro), (y + 1, escuro if claro_em_cima else claro)):
        for x in range(hx, hx + 3):
            cv.px[yy][x] = cor
    for yy in (y, y + 1):
        for x in range(hx, hx + 3):
            for dx, dy in VIZ4:
                nx, ny = x + dx, yy + dy
                if 0 <= nx < cv.w and 0 <= ny < cv.h and cv.px[ny][nx] is None:
                    cv.px[ny][nx] = borda


def tapa_furos(cv, cor=None):
    """Pixel transparente que nao se liga a borda do quadro e furo: leva a cor do vizinho."""
    fora = set()
    pilha = [(x, y) for y in range(cv.h) for x in range(cv.w)
             if (x in (0, cv.w - 1) or y in (0, cv.h - 1)) and cv.px[y][x] is None]
    fora.update(pilha)
    while pilha:
        x, y = pilha.pop()
        for dx, dy in VIZ4:
            nx, ny = x + dx, y + dy
            if 0 <= nx < cv.w and 0 <= ny < cv.h and (nx, ny) not in fora and cv.px[ny][nx] is None:
                fora.add((nx, ny))
                pilha.append((nx, ny))
    furos = [(x, y) for y in range(cv.h) for x in range(cv.w) if cv.px[y][x] is None and (x, y) not in fora]
    for x, y in furos:
        viz = [cv.px[y + dy][x + dx] for dx, dy in VIZ4 if 0 <= x + dx < cv.w and 0 <= y + dy < cv.h]
        viz = [v for v in viz if v is not None]
        cv.px[y][x] = cor or (max(set(viz), key=viz.count) if viz else CONT)
    return len(furos)


def acabamento(cv):
    """Quadro branco do pato (saida de para16) -> quadro final: contorno #262b44, olho #181425,
    bico 3x2 laranja, pes #feae34/#f77622 sem cinza entre as pernas, sem furo."""
    out = copia(cv)
    t = topo_cabeca(cv)
    hx = max(x for x in range(16) if cv.px[t + 1][x] is not None)  # contorno da frente da cabeca
    olhos = []
    for y in range(t + 1, t + 6):
        for x in range(8, hx):
            if cv.px[y][x] == CONT_VELHO:
                viz = [cv.px[y + dy][x + dx] for dx, dy in VIZ4]
                if sum(1 for v in viz if v is not None and v != CONT_VELHO) >= 3:
                    olhos.append((x, y))
    troca = {CONT_VELHO: CONT, _c("fee761"): PE}
    for y in range(16):
        for x in range(16):
            c = out.px[y][x]
            if c is not None:
                out.px[y][x] = troca.get(c, c)
    # pes: nada de branco/cinza da barriga entre as pernas (vira contorno)
    pes = (PE, PE_ESC)
    barriga = max([y for y in range(16) if sum(1 for x in range(16) if out.px[y][x] == SOMBRA) >= 3] or [11])
    for y in range(barriga + 1, 16):
        for x in range(16):
            if out.px[y][x] in (BRANCO, SOMBRA) and any(
                    0 <= x + dx < 16 and 0 <= y + dy < 16 and out.px[y + dy][x + dx] in pes for dx, dy in VIZ4):
                out.px[y][x] = CONT
    # pe de tras escondido atras do da frente que a reducao virou so contorno (duas linhas de
    # contorno empilhadas embaixo de um pe): volta a ser pe, na sombra
    for x in range(16):
        if out.px[15][x] == CONT and out.px[14][x] == CONT and out.px[13][x] in pes:
            out.px[14][x] = PE_ESC
    # nenhuma cor de pe/perna encostada no transparente: contorno de 1 px por fora
    for y in range(barriga + 1, 16):
        for x in range(16):
            if out.px[y][x] in pes:
                for dx, dy in VIZ4:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < 16 and 0 <= ny < 16 and out.px[ny][nx] is None:
                        out.px[ny][nx] = CONT
    # bico: limpa o que a reducao deixou na frente da cabeca e repinta
    for y in range(t + 3, min(16, t + 7)):
        for x in range(hx + 1, 16):
            out.px[y][x] = None
    bico16(out, hx, t + 4)
    for x, y in olhos:
        out.px[y][x] = OLHO
    tapa_furos(out)
    return out


# amarelos dos pes na grade de 32 (pato.py) -> ja as cores finais, antes da reducao: o pe da
# frente claro, a perna/calcanhar dele e o pe de tras na sombra (igual em todas as tiras)
PES32 = {P.YELLOW: PE, P.YELLOW_DARK: PE_ESC, P.YELLOW_BACK: PE_ESC, (255, 242, 0, 255): PE_ESC}


def pes32(cv32):
    out = copia(cv32)
    for y in range(18, cv32.h):
        for x in range(cv32.w):
            c = out.px[y][x]
            if c is not None:
                out.px[y][x] = PES32.get(c, c)
    return out


def branco16(cv32):
    return acabamento(para16(pes32(cv32)))


def arred(v):
    """Arredonda para PAR: na grade de 32, passo par = 1 pixel inteiro em 16 (o desenho so se
    move, sem mudar de forma de um quadro para o outro)."""
    return 2 * int(math.floor(v / 2.0 + 0.5))


def mistura(a, b, t):
    if isinstance(a, tuple):
        return tuple(mistura(x, y, t) for x, y in zip(a, b))
    return arred(a + (b - a) * t)


def interpola(chaves, n, laco, em_pose=False):
    """n passos ao longo das chaves (cada chave = (pernas, balanco, asa) ou 5 numeros).
    Em laco volta da ultima para a primeira; sem laco vai da primeira ate a ultima.
    em_pose: as pernas nao interpolam; trocam de pose junto com a asa (batida regular)."""
    out = []
    k = len(chaves)
    for i in range(n):
        t = i * k / n if laco else i * (k - 1) / (n - 1)
        a = int(t) % k
        b = (a + 1) % k if laco else min(a + 1, k - 1)
        f = t - int(t)
        ca, cb = chaves[a], chaves[b]
        if isinstance(ca[-1], str) or ca[-1] is None:  # (pernas, balanco, asa): a asa nao interpola
            cp = ca if f < 0.5 else cb
            pernas = mistura(cp[0], cp[0], 0) if em_pose else mistura(ca[0], cb[0], f)
            out.append((pernas, mistura(ca[1], cb[1], f), cp[2]))
        else:
            out.append(mistura(ca, cb, f))
    return out


def copia(cv):
    out = Canvas(cv.w, cv.h)
    for y in range(cv.h):
        for x in range(cv.w):
            out.px[y][x] = cv.px[y][x]
    return out


def move(cv, x0, x1, y0, y1, dx, dy):
    """Move os pixels do retangulo [x0, x1) x [y0, y1) por (dx, dy) (16x16)."""
    out = copia(cv)
    pts = [(x, y, cv.px[y][x]) for y in range(y0, y1) for x in range(x0, x1) if cv.px[y][x] is not None]
    for x, y, _ in pts:
        out.px[y][x] = None
    for x, y, c in pts:
        if 0 <= x + dx < cv.w and 0 <= y + dy < cv.h:
            out.px[y + dy][x + dx] = c
    return out


def olhos16(cv):
    """Pixels do olho (cor OLHO) no quadro ja acabado."""
    return [(x, y) for y in range(16) for x in range(16) if cv.px[y][x] == OLHO]


def piscando(cv):
    out = copia(cv)
    for x, y in olhos16(cv):
        out.px[y][x] = SOMBRA  # palpebra (c0cbdc da paleta)
    return out


# ------------------------------------------------------------ as 8 animacoes
PERNAS_PARADO = ["..aaafaaeaa.....",   # perna de tras (sombra) em x=5, da frente em x=8
                 "....afaaea......",
                 "....affaeea.....",   # dois pes de 2 px com o dedo para a frente
                 "....aaaaaaa....."]


def base_parado():
    """Pato parado acabado, com o mesmo olho unico (olhando para a frente) das outras animacoes
    e as pernas redesenhadas em 16 (1 px cada, a de tras na sombra)."""
    base = branco16(P.look_forward(P.idle_fixed()))
    cor = {"a": CONT, "e": PE, "f": PE_ESC}
    for i, linha in enumerate(PERNAS_PARADO):
        y = 12 + i
        for x, ch in enumerate(linha):
            if ch != ".":
                base.px[y][x] = cor[ch]
            elif y > 12:
                base.px[y][x] = None
    return base


def parado():
    base = base_parado()
    resp = move(base, 7, 16, 0, 6, 0, 1)  # cabeca desce 1 px ao respirar
    for y in range(16):  # o bico desceu junto: fecha o contorno dele por baixo
        for x in range(16):
            if resp.px[y][x] in (BICO, BICO_ESC):
                for dx, dy in VIZ4:
                    if 0 <= x + dx < 16 and 0 <= y + dy < 16 and resp.px[y + dy][x + dx] is None:
                        resp.px[y + dy][x + dx] = BICO_CONT
    tapa_furos(resp)
    pisc = piscando(base)
    cauda = move(base, 0, 4, 6, 9, 0, -1)  # a ponta da cauda sobe 1 px
    for x in range(0, 4):  # a linha que a subida deixou vazia volta a ser o corpo
        if cauda.px[8][x] is None:
            cauda.px[8][x] = base.px[8][x]
    seq = "bbbbccbrrrrbbpbb"
    return [{"b": base, "r": resp, "p": pisc, "c": cauda}[c] for c in seq]


def correndo():
    body = P.look_forward(P.idle_body())
    # balanco sem subir acima da pose de contato (a cabeca ja encosta no topo do quadro): na
    # passagem o corpo fica onde esta e no contato desce 1 px em 16 (2 na grade de 32)
    chaves = [(a, b, c, d, bal * 2 + 2) for a, b, c, d, bal in P.RUN_CYCLE]
    return [branco16(P.clean_feet_outline(P.run_frame(body, c))) for c in interpola(chaves, N, True)]


def no_ar(chaves, laco, em_pose=False):
    body = P.look_forward(P.idle_body())
    return [branco16(P.air_variant(body, pernas, bal, asa, "AC"))
            for pernas, bal, asa in interpola(chaves, N, laco, em_pose)]


# queda em laco: duas batidas iguais de 8 quadros (cada chave dura exatamente 2 quadros)
FALL16 = [((2, 0, -2, 0), 0, "alta"),
          ((2, 0, -1, 1), 0, "meia"),
          ((1, 1, -2, 0), 0, "dobrada"),
          ((2, 0, -2, 0), 0, "meia"),
          ((3, 1, -2, 0), 0, "alta"),
          ((2, 0, -3, 1), 0, "meia"),
          ((1, 1, -2, 0), 0, "dobrada"),
          ((2, 0, -2, 0), 0, "meia")]


def tinge(cv, mapa):
    out = copia(cv)
    for y in range(16):
        for x in range(16):
            c = out.px[y][x]
            if c is not None:
                out.px[y][x] = mapa.get(c, c)
    return out


# dano: o pato parado tingido, ja nas cores da Endesga 32 (nenhuma cor cai fora do lugar)
DANO = [
    {CONT: _c("a22633"), BRANCO: _c("e43b44"), SOMBRA: _c("e43b44"), BICO_CONT: _c("a22633")},  # vermelho
    {CONT: _c("f6757a"), BICO_CONT: _c("e43b44")},                                               # flash branco
    None,
    {CONT: _c("e43b44"), BRANCO: _c("f6757a"), SOMBRA: _c("f6757a"), BICO_CONT: _c("a22633")},  # rosa medio
]
DANO[2] = DANO[0]
OLHO_DOR = _c("3e2731")


def dano():
    base = base_parado()
    (ex, ey), = olhos16(base)
    fechado = copia(base)
    for x in (ex - 1, ex):  # olho fechado de dor: tracinho de 2 px
        fechado.px[ey][x] = OLHO_DOR
    pal = [tinge(fechado, m) for m in DANO]
    # sem tremor embutido: o pato inteiro ocupa os 16 px e deslocar cortaria a cauda ou o bico
    return [copia(pal[i % 4]) for i in range(N)]


MORTO = {CONT: _c("3e2731"), BRANCO: _c("8b9bb4"), SOMBRA: _c("c0cbdc"), BICO_CONT: _c("3e2731")}


def _pe_morto(cv, x0, erguido):
    """Pe de barriga para cima, saindo do contorno da barriga (linha 3): pe de 3 px com o dedo
    para a frente; erguido sobe 1 px e mostra 1 px de perna."""
    fy = 1 if erguido else 2
    pts = {(x, fy) for x in range(x0, x0 + 3)} | ({(x0, 2)} if erguido else set())
    for x, y in pts:
        cv.px[y][x] = PE
    cv.px[fy][x0] = PE_ESC  # calcanhar na sombra
    if erguido:
        cv.px[2][x0] = PE_ESC
    for x, y in pts:
        for dx, dy in VIZ4:
            nx, ny = x + dx, y + dy
            if 0 <= nx < 16 and 0 <= ny < 4 and (nx, ny) not in pts and cv.px[ny][nx] is None:
                cv.px[ny][nx] = MORTO[CONT]


def morte():
    base = base_parado()
    (ex, ey), = olhos16(base)
    t = topo_cabeca(base)
    hx = max(x for x in range(16) if base.px[t + 1][x] is not None)
    vira = Canvas(16, 16)
    for y in range(16):
        for x in range(16):
            vira.px[15 - y][x] = base.px[y][x]
    # de barriga para cima: tira as pernas (linhas 0..2) e fecha a barriga com contorno
    for y in range(0, 3):
        for x in range(16):
            vira.px[y][x] = None
    for x in range(16):
        if vira.px[3][x] is not None:
            vira.px[3][x] = CONT
    cinza = tinge(vira, MORTO)
    # bico laranja de novo (virado: a linha clara fica em cima)
    by = 15 - (t + 5)
    for y in range(by - 1, by + 3):
        for x in range(hx + 1, 16):
            cinza.px[y][x] = None
    bico16(cinza, hx, by, True, (BICO, BICO_ESC, MORTO[CONT]))
    # olho em X de 3x3 (x=ex-1..ex+1), com 1 px de cinza ate o contorno de cima da cabeca
    ey2 = 15 - ey
    cinza.px[ey2][ex] = MORTO[BRANCO]
    for d in range(3):
        cinza.px[ey2 - 1 + d][ex - 1 + d] = MORTO[CONT]
        cinza.px[ey2 - 1 + d][ex + 1 - d] = MORTO[CONT]
    # pes pedalando: um sobe enquanto o outro desce, 4 quadros em cada pose
    out = []
    for i in range(N):
        q = copia(cinza)
        a = (i // 4) % 2 == 0
        _pe_morto(q, 3, a)
        _pe_morto(q, 7, not a)
        out.append(q)
    return out


# mergulhado: pato deitado na horizontal, cabeca e bico a frente, pes batendo atras (pernada).
# Desenhado direto em 16 (as mesmas pecas acabadas das outras tiras: contorno #262b44, olho
# #181425 cercado de branco, bico 3x2 laranja com contorno #be4a2f, pes #feae34/#f77622).
MERGULHO_CORPO = [
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "........AAAA....",
    ".AA....ABBBBA...",
    ".ABAAAABBBBBA...",
    ".ABBBBBBBBCBADD.",
    ".ABBBBBBBBBBHHHD",
    ".ABBGGGGBBBBIIID",
    "..ABBBBGBBBBADD.",
    "...AAAAAAAAA....",
    "................",
    "................",
]
# pes: recolhidos embaixo da barriga -> meio -> esticados para tras e para baixo (o empurrao)
MERGULHO_PES = {
    "r": {13: "...FA", 14: "..AFEEA", 15: "...AAA"},
    "m": {12: "AFA", 13: "AEFA", 14: ".AA"},
    "b": {13: "AAAFA", 14: "AEEFA", 15: ".AAAA"},
}
MERGULHO_SEQ = "rrrrmmbbbbbbmmrr"  # 16 quadros: recolhe devagar, empurra e segura a pernada
MERGULHO_COR = {"A": CONT, "B": BRANCO, "G": SOMBRA, "C": OLHO, "D": BICO_CONT,
                "E": PE, "F": PE_ESC, "H": BICO, "I": BICO_ESC}


def mergulhando():
    poses = {}
    for k, pes in MERGULHO_PES.items():
        g = [list(r) for r in MERGULHO_CORPO]
        for y, s in pes.items():
            for x, ch in enumerate(s):
                if ch != ".":
                    g[y][x] = ch
        cv = Canvas(16, 16)
        for y in range(16):
            for x in range(16):
                if g[y][x] != ".":
                    cv.px[y][x] = MERGULHO_COR[g[y][x]]
        poses[k] = cv
    return [copia(poses[c]) for c in MERGULHO_SEQ]


# olhando para cima / para baixo: o corpo do pato parado e a cabeca redesenhada em 16 (mesmas
# pecas: contorno #262b44, olho #181425 cercado de branco, bico laranja com contorno #be4a2f).
# Cada tira: 2 quadros de virada (meio caminho), a pose segurada, uma piscada e de novo a pose;
# toca uma vez e para no ultimo quadro enquanto o jogador segura CIMA/BAIXO.
OLHAR_CABECA = {
    "cima_meio": [
        "........AAAA....",
        ".......ABBBBA...",
        ".......ABBBBADD.",
        ".......ABBCBHHHD",
        ".......ABBBBIIID",
        ".......ABBBBADD.",
        "AAAAAAABBBGA....",
    ],
    "cima": [
        "........AAAADD..",
        ".......ABBBBHHD.",
        ".......ABBCBHID.",
        ".......ABBBBIDD.",
        ".......ABBBBA...",
        ".......ABBBBA...",
        "AAAAAAABBBGA....",
    ],
    "baixo_meio": [
        "........AAAA....",
        ".......ABBBBA...",
        ".......ABBBBA...",
        ".......ABBBBA...",
        ".......ABBCBADD.",
        ".......ABBBBHHHD",
        "AAAAAAABBBGAIIID",
        "ABBBBBBBBBGADD..",
    ],
    "baixo": [
        "................",
        "........AAAA....",
        ".......ABBBBA...",
        ".......ABBBBA...",
        ".......ABBBBA...",
        ".......ABBCBADD.",
        "AAAAAAABBBGAHHD.",
        "ABBBBBBBBBGAHID.",
        "ABBBBBBBBBBAIID.",
        "ABBBBBBBBBBADD..",
    ],
}
OLHAR_SEQ = "mmpppppppfpppppp"  # m = virando, p = pose, f = piscada


def _olhar_pose(nome):
    base = base_parado()
    cv = copia(base)
    for y, linha in enumerate(OLHAR_CABECA[nome]):
        for x, ch in enumerate(linha):
            # so a coluna da cabeca/bico (x >= 7) e as linhas do corpo que a cabeca cobre
            if x < 7 and y < 6:
                cv.px[y][x] = None if ch == "." else MERGULHO_COR[ch]
            elif ch == ".":
                if x >= 7:
                    cv.px[y][x] = None
            else:
                cv.px[y][x] = MERGULHO_COR[ch]
    return cv


def olhando(lado):
    meio, pose = _olhar_pose(lado + "_meio"), _olhar_pose(lado)
    pisc = piscando(pose)
    return [copia({"m": meio, "p": pose, "f": pisc}[c]) for c in OLHAR_SEQ]


def pecas():
    return {
        "pato_olhando_cima": olhando("cima"),
        "pato_olhando_baixo": olhando("baixo"),
        "pato_parado": parado(),
        "pato_correndo": correndo(),
        "pato_pulando": no_ar(P.JUMP3, False),
        "pato_apice": no_ar(P.APEX3, False),
        "pato_caindo": no_ar(FALL16, True, True),  # pes trocam de pose junto com a asa
        "pato_dano": dano(),
        "pato_morte": morte(),
        "pato_mergulhando": mergulhando(),
    }


def distintos(qs):
    vistos = []
    for q in qs:
        k = tuple(tuple(r) for r in q.px)
        if k not in vistos:
            vistos.append(k)
    return len(vistos)


def tira(qs):
    cv = Canvas(16 * len(qs), 16)
    for i, q in enumerate(qs):
        cv.blit(q, i * 16, 0)
    return cv


def main():
    p = pecas()
    linhas = []
    for nome, qs in p.items():
        print("%-14s %d quadros, %d desenhos diferentes" % (nome, len(qs), distintos(qs)))
        linhas.append(tira(qs))
        save_gif(os.path.join(OUT, "%s_16.gif" % nome), qs, delay_cs=6, scale=8, bg=(118, 194, 246))
    folha = Canvas(16 * N + 4, len(linhas) * 18 + 2)
    for y in range(folha.h):
        for x in range(folha.w):
            folha.px[y][x] = (118, 194, 246, 255)
    for i, t in enumerate(linhas):
        folha.blit(t, 2, 2 + i * 18)
    big = Canvas(folha.w * 6, folha.h * 6)
    big.blit(folha, 0, 0, 6)
    big.save(os.path.join(OUT, "pato16_quadros.png"))
    if "--salvar" in sys.argv:
        for nome, qs in p.items():
            t = tira(qs)
            big = Canvas(t.w * 8, t.h * 8)  # o save() reduz 4x e depois 2x (identidade aqui)
            big.blit(t, 0, 0, 8)
            big.save(os.path.join(ARTE, nome + ".png"))
        print("salvo em assets/sprites/arte/")
    print("ok")


if __name__ == "__main__":
    main()
