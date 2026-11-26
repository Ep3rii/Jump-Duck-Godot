"""Camadas de fundo (parallax) na base de estilo (tools/arte/estilo.py). Regra da distancia:
quanto mais longe, mais claro e azulado, sem contorno e com menos detalhe. Luz de cima e da
esquerda (face direita dos morros e das torres no tom de sombra).
Gravadas direto na grade (2 px = 1 px do jogo) em assets/sprites/arte/fundo/. As tiras de
1024 px emendam nas pontas (repetem a cada 512 px do jogo).
Uso: python tools/arte/fundos.py [--salvar]   (previas em tools/arte/saida/)"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas, hexc  # noqa: E402
from estilo import Desenho, P  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
DEST = os.path.join(ROOT, "assets", "sprites", "arte", "fundo")
OUT = os.path.join(HERE, "saida")
os.makedirs(OUT, exist_ok=True)

L = 1024  # largura das tiras


def degrau(v, passo=2):
    return int(round(v / passo)) * passo


# Cores ja da Endesga 32 (a troca de paleta devolve a mesma cor; nada de dist() que o arredondamento
# leva para tons errados)
E = {n: hexc(n) for n in (
    "be4a2f e43b44 a22633 f6757a 3e2731 733e39 b86f50 e4a672 e8b796 c28569 f77622 feae34 fee761 "
    "63c74d 3e8948 265c42 193c3e ffffff c0cbdc 8b9bb4 5a6988 3a4466 262b44 181425 68386c b55088").split()}


def amplia(cv):
    """Peca desenhada direto em pixels do jogo -> grade de 32 (blocos 2x2: o reduz2 so amostra,
    sem refazer contorno)."""
    big = Canvas(cv.w * 2, cv.h * 2)
    big.blit(cv, 0, 0, 2)
    return big


def contorna(cv, mask, cor, sem_baixo=False):
    """Pinta de 'cor' os pixels de 'mask' (set de (x, y)) que encostam (4 vizinhos) fora dela."""
    for x, y in mask:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if (x + dx, y + dy) not in mask:
                if sem_baixo and dy == 1 and y == cv.h - 1:
                    continue
                cv.px[y][x] = cor
                break


# ------------------------------------------------------------------ montanhas
SERRA = [(0, 90), (60, 150), (125, 95), (190, 230), (262, 120), (330, 170), (398, 110), (470, 250),
         (545, 125), (610, 190), (672, 100), (730, 140), (790, 105), (850, 220), (910, 115),
         (960, 170), (1024, 90)]
M_LUZ, M_SOMBRA = E["c0cbdc"], E["8b9bb4"]
NEVE, NEVE_SOMBRA = E["ffffff"], E["c0cbdc"]
M_BASE = 12  # faixa lisa no pe da serra (6 px): a sombra termina antes e emenda no preenchimento


def montanhas():
    H = 260
    cv = Canvas(L, H)
    topo = [0] * L
    for (x0, h0), (x1, h1) in zip(SERRA, SERRA[1:]):
        for x in range(x0, x1):
            topo[x] = H - degrau(h0 + (h1 - h0) * (x - x0) / (x1 - x0))
    for x in range(L):
        for y in range(topo[x], H):
            cv.px[y][x] = M_LUZ
    # face direita de cada pico no tom de sombra (um triangulo que desce ate o vale)
    for i in range(1, len(SERRA) - 1, 2):
        (px, ph), (vx, vh) = SERRA[i], SERRA[i + 1]
        # a sombra para onde comeca a face clara do pico seguinte (a linha dela continua
        # descendo para a esquerda ate a base)
        nx, nh = SERRA[i + 2] if i + 2 < len(SERRA) else (SERRA[1][0] + L, SERRA[1][1])
        ex = vx - (nx - vx) * vh / float(max(1, nh - vh))
        crista = px + (vx - px) * 0.3
        fim = H - M_BASE
        for x, y in cv.mask_poly([(px, H - ph), (vx, H - vh), (max(ex, crista + 8), fim), (crista, fim)]):
            if 0 <= x < L and topo[x] <= y < fim:
                cv.px[y][x] = M_SOMBRA
        # um dente de sombra na face clara (relevo)
        (lx, lh) = SERRA[i - 1]
        mx = (lx + px) // 2
        for x, y in cv.mask_poly([(mx, topo[mx] + 14), (mx + 18, topo[mx] + 60), (mx + 4, topo[mx] + 60)]):
            if 0 <= x < L and topo[x] <= y < fim:
                cv.px[y][x] = M_SOMBRA
        # neve nos picos altos, com a barra em ziguezague
        if ph >= 165:
            for x in range(px - 40, px + 40):
                if not 0 <= x < L:
                    continue
                zig = abs((x % 16) - 8)
                lim = (H - ph) + 26 + zig + int(abs(x - px) * 0.15)
                for y in range(topo[x], min(lim, H)):
                    cv.px[y][x] = NEVE if x <= px else NEVE_SOMBRA
    return cv


# ------------------------------------------------------------------ colinas
# Desenhadas direto em pixels do jogo (G = 512 de largura) e ampliadas para a grade de 32 no fim,
# para o reduz2 so amostrar (nada de contorno refeito nem pixel solto).
# Separacao das duas camadas por valor (regra da distancia):
#   colinas_longe: verde medio #3e8948 chapado, sem contorno, matas #265c42/#193c3e (mais claro);
#   colinas_perto: corpo #265c42 com crista #3e8948 e CONTORNO #193c3e de 1 px na silhueta toda,
#   copas #265c42 com luz #3e8948 no alto/esquerda e contorno #193c3e proprio (assim as copas que
#   sobem acima da crista se destacam do #3e8948 da camada de tras).
G = L // 2


def perfil(base, ondas):
    """Altura do morro em pixels do jogo (G colunas, emenda nas pontas)."""
    return [int(round(base + sum(a * math.sin(2 * math.pi * n * x / G + f) for a, n, f in ondas)))
            for x in range(G)]


def contorno_g(cv, mask, cor, alvo=None):
    """Pinta de 'cor' os pixels de 'mask' com vizinho (4) fora de 'alvo' (padrao: a propria mask).
    O x da a volta (a tira emenda); a borda de baixo nao conta."""
    alvo = mask if alvo is None else alvo
    for x, y in mask:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = (x + dx) % cv.w, y + dy
            if ny >= cv.h:
                continue
            if ny < 0 or (nx, ny) not in alvo:
                cv.px[y][x] = cor
                break


def colinas(H, alt, cor, cor_luz, luz_h, matas, raio, mata, mata_s, mata_luz=None,
            contorno=None, extras=None):
    """H e alt em pixels do jogo. Devolve a peca ja ampliada para a grade de 32."""
    cv = Canvas(G, H)
    topo = [H - a for a in alt]
    morro = set()
    for x in range(G):
        for y in range(topo[x], H):
            cv.px[y][x] = cor_luz if y < topo[x] + luz_h else cor
            morro.add((x, y))
    # matas: copas redondinhas apoiadas no morro
    copas = set()
    luz = set()
    sombra = set()
    for x0, n in matas:
        for j in range(n):
            r = raio + ((x0 * 7 + j * 5) % 3) - 1
            x = (x0 + j * int(round(r * 1.6))) % G
            cy = topo[x] - r + 2
            fora = set((px % G, py) for px, py in cv.mask_ellipse(x + 0.5, cy, r, r) if 0 <= py < H)
            if mata_luz:  # luz: miolo deslocado para cima/esquerda
                luz |= set((px % G, py) for px, py in cv.mask_ellipse(x - 1.5, cy - 2, r - 3, r - 3))
            else:  # sem luz: meia-lua de sombra embaixo/direita
                dentro = set((px % G, py) for px, py in cv.mask_ellipse(x - 1, cy - 1, r, r))
                sombra |= fora - dentro
            copas |= fora
    for px, py in copas:
        if (px, py) in luz:
            c = mata_luz
        elif (px, py) in sombra:
            c = mata_s
        else:
            c = mata
        cv.px[py][px] = c
    if extras:
        extras(cv, topo)
    if contorno:
        silhueta = morro | copas
        contorno_g(cv, copas, contorno)               # cada copa com borda propria
        contorno_g(cv, silhueta, contorno)            # e a silhueta toda contra o ceu
    return amplia(cv)


def colinas_longe():
    """Morro distante: verde medio #3e8948 chapado e sem contorno (um degrau abaixo da grama
    jogavel #63c74d, que nao aparece no fundo), matas mais escuras e casinhas. Fica mais claro
    que o morro de perto (o ar clareia o que esta longe)."""
    alt = perfil(56, [(17, 1, 0.5), (9, 3, 2.0), (4, 5, 4.1)])
    verde = E["3e8948"]

    def extras(cv, topo):
        casinha(cv, topo, 125)
        casinha(cv, topo, 371)
    return colinas(90, alt, verde, verde, 0,
                   [(20, 3), (85, 5), (165, 2), (235, 4), (320, 6), (400, 2), (465, 3)], 4,
                   E["265c42"], E["193c3e"], extras=extras)


def casinha(cv, topo, x):
    """Casinha bem ao longe (pixels do jogo): parede clara 6x4 com o lado direito na sombra,
    telhado vermelho 8x2 e porta escura de 1x2, com o pe reto no ponto mais baixo do morro."""
    base = max(topo[(x + i) % G] for i in range(6)) + 2
    y0 = base - 4
    for xx in range(x, x + 6):
        for yy in range(y0, base):
            cv.px[yy][xx % G] = E["e8b796"] if xx < x + 4 else E["c28569"]
    for yy in range(y0 - 2, y0):
        for xx in range(x - 1, x + 7):
            cv.px[yy][xx % G] = E["a22633"]
    for yy in range(base - 2, base):
        cv.px[yy][(x + 2) % G] = E["3e2731"]


def colinas_perto():
    """Morro de perto: corpo verde-escuro #265c42, crista #3e8948 e contorno #193c3e (a grama
    jogavel #63c74d fica sempre mais clara e mais viva)
    e uma faixa escura na base, que aparece nos buracos e le
    como profundidade."""
    alt = perfil(37, [(14, 2, 1.0), (6, 5, 0.3), (2, 9, 2.2)])

    def extras(cv, topo):
        # Sem plantacoes: em amarelo pareciam feno jogavel, e em trigo/madeira pareciam caixa ou
        # cerca (revisao das capturas 16x16). O morro fica so verde, com as moitas.
        for x in range(G):  # base escura (os vaos entre os blocos de chao mostram isso)
            for y in range(cv.h - 6, cv.h):
                cv.px[y][x] = E["193c3e"]
    return colinas(75, alt, E["265c42"], E["3e8948"], 2,
                   [(10, 2), (105, 4), (210, 3), (260, 2), (350, 5), (450, 3)], 6,
                   E["265c42"], E["193c3e"], mata_luz=E["3e8948"], contorno=E["193c3e"],
                   extras=extras)


# ------------------------------------------------------------------ nuvens, sol e lua
NUVENS = {
    "nuvem_grande": (192, 64, [(40, 44, 36, 18), (84, 30, 44, 26), (130, 38, 40, 22), (162, 48, 26, 14)],
                     (10, 44, 172, 18)),
    "nuvem_media": (128, 48, [(30, 32, 26, 13), (62, 22, 30, 18), (96, 30, 26, 14)], (8, 32, 112, 14)),
    "nuvem_pequena": (80, 32, [(22, 20, 18, 9), (46, 14, 20, 12), (62, 22, 14, 8)], (6, 20, 68, 10)),
}


def nuvem(nome):
    w, h, bolas, base = NUVENS[nome]
    d = Desenho(w, h)
    for cx, cy, rx, ry in bolas:
        d.elipse(cx, cy, rx, ry, P["nuvem"], "nuvem")
    d.rect(*base, P["nuvem"], "nuvem")
    d.sombra("nuvem", P["nuvem_sombra"], dx=0, dy=max(4, h // 9))
    # cantos de baixo arredondados
    cv = d.cv
    yb = base[1] + base[3] - 1
    for x, y in [(base[0], yb), (base[0] + 1, yb), (base[0], yb - 1),
                 (base[0] + base[2] - 1, yb), (base[0] + base[2] - 2, yb), (base[0] + base[2] - 1, yb - 1)]:
        cv.px[y][x] = None
    return cv


SOL, SOL_BORDA, SOL_BRILHO, RAIO = E["fee761"], E["feae34"], E["ffffff"], E["fee761"]


def sol(quadro):
    """Sol de 48x48 px do jogo desenhado direto em pixels (simetrico nos 4 quadrantes): disco
    amarelo com anel laranja de 1 px, brilho branco em cima/esquerda e 8 raios em direcoes FIXAS
    (retos de 2 px de largura, diagonais em escada) que so pulsam o comprimento."""
    S = 48
    cv = Canvas(S, S)
    fase = 2 * math.pi * quadro / 16.0
    lr = 3 + int(round(1.5 + 1.5 * math.sin(fase)))   # raios retos: 3..6 px
    ld = 2 + int(round(1.0 - 1.0 * math.sin(fase)))   # diagonais (fase oposta): 2..4 px
    R, D0 = 11.5, 14
    for j in range(S // 2):
        for i in range(S // 2):
            d = math.hypot(i + 0.5, j + 0.5)
            cor = None
            if d <= R:
                cor = SOL_BORDA if d > R - 1.15 else SOL
            elif (j == 0 and D0 <= i < D0 + lr) or (i == 0 and D0 <= j < D0 + lr):
                cor = RAIO
            elif i == j and 10 <= i < 10 + ld:
                cor = RAIO
            if cor is None:
                continue
            for x, y in ((S // 2 + i, S // 2 + j), (S // 2 - 1 - i, S // 2 + j),
                         (S // 2 + i, S // 2 - 1 - j), (S // 2 - 1 - i, S // 2 - 1 - j)):
                cv.px[y][x] = cor
    for x, y in ((17, 16), (18, 16), (16, 17), (17, 17), (16, 18)):  # brilho (luz de cima/esquerda)
        cv.px[y][x] = SOL_BRILHO
    return amplia(cv)


def lua():
    """Lua crescente de 32x32 px do jogo desenhada direto em pixels: a mordida fica na diagonal
    exata (as duas pontas saem iguais e afinadas) e nao sobra pixel solto."""
    S = 32
    cv = Canvas(S, S)
    c, r, m, rm = 16.0, 11.0, 5.0, 10.5
    cheio = set()
    for y in range(S):  # cobertura de 4x4 amostras por pixel: as pontas afinam sozinhas
        for x in range(S):
            n = 0
            for sy in range(4):
                for sx in range(4):
                    px, py = x + (sx + 0.5) / 4, y + (sy + 0.5) / 4
                    if math.hypot(px - c, py - c) <= r and math.hypot(px - c - m, py - c + m) > rm:
                        n += 1
            if n >= 7:
                cheio.add((x, y))
    # nenhum pixel solto (sem vizinho de lado) nas pontas
    cheio = {p for p in cheio if any((p[0] + dx, p[1] + dy) in cheio
                                     for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
    for x, y in cheio:
        cv.px[y][x] = E["ffffff"]
    return amplia(cv)


# ------------------------------------------------------------------ torre do gaviao (ao longe)
# medidas em pixels do jogo: largura, altura, meia largura do corpo, meia largura do parapeito,
# topo do parapeito, altura do parapeito, dente, vao, meia largura do telhado, faixa de sombra,
# janela (larg, alt), seteira (larg, alt), riscos de tijolo
TORRES = {
    "torre_longe": (18, 67, 5, 7, 11, 4, 2, 1, 4, 3, (2, 4), (1, 3), False),
    "torre_media": (28, 105, 8, 11, 17, 6, 4, 2, 7, 5, (2, 7), (2, 4), True),
    "torre_perto": (36, 135, 10, 14, 22, 8, 4, 2, 9, 6, (4, 8), (2, 5), True),
}
T_LUZ, T_SOMBRA, T_CONTORNO = E["c0cbdc"], E["8b9bb4"], E["5a6988"]
T_TELHA, T_TELHA_S, T_TELHA_C = E["b55088"], E["68386c"], E["3e2731"]


def torre(nome):
    """Torre vista de fora, desenhada direto em pixels do jogo (sem meio pixel): parapeito com
    dentes iguais separados por vaos iguais, bordas retas, contorno #5a6988 dos dois lados
    (diferente da faixa de sombra #8b9bb4), janela e seteiras retangulares."""
    W, H, bw, tw, p0, ph, dente, vao, rw, sw, (jw, jh), (sl, sa), riscos = TORRES[nome]
    cv = Canvas(W, H)
    cx = W // 2
    th = 2 if W < 20 else 3  # altura dos dentes
    # telhado: do pico (2 px, y=1) ate logo acima dos dentes (os vaos mostram o ceu)
    telhado = set()
    fim = p0 - th
    for y in range(1, fim):
        hw = 1 + int(round((rw - 1) * (y - 1) / float(max(1, fim - 2))))
        for x in range(cx - hw, cx + hw):
            telhado.add((x, y))
    for x, y in telhado:
        cv.px[y][x] = T_TELHA if x < cx else T_TELHA_S
    contorna(cv, telhado, T_TELHA_C)
    # corpo + parapeito + dentes (silhueta unica, contorno de 1 px)
    pedra = set()
    for y in range(p0 + ph, H):
        for x in range(cx - bw, cx + bw):
            pedra.add((x, y))
    for y in range(p0, p0 + ph):
        for x in range(cx - tw, cx + tw):
            pedra.add((x, y))
    n = (2 * tw + vao) // (dente + vao)
    sobra = 2 * tw - (n * dente + (n - 1) * vao)
    x = cx - tw + sobra // 2
    for _ in range(n):
        for xx in range(x, x + dente):
            for y in range(p0 - th, p0):
                pedra.add((xx, y))
        x += dente + vao
    for x, y in pedra:
        lim = cx + (tw if y < p0 + ph else bw) - sw  # faixa de sombra a direita
        cv.px[y][x] = T_SOMBRA if x >= lim else T_LUZ
    for x in range(cx - bw, cx + bw):  # sombra do parapeito sobre o corpo
        cv.px[p0 + ph][x] = T_SOMBRA
    if riscos:  # riscos de tijolo na face clara
        larg = 3 if W < 36 else 4
        for bx, by in ((-6, 60), (1, 85), (-5, 111), (2, 134), (-2, 52)):
            yy = int(round(by * H / 150.0))
            x0 = min(cx + int(round(bx * W / 36.0)), cx + bw - sw - 1 - larg)
            if p0 + ph + 2 <= yy < H - 2:
                for xx in range(x0, x0 + larg):
                    # 1 px de folga antes da faixa de sombra: o risco nao a alarga (degrau)
                    if cx - bw + 1 <= xx < cx + bw - sw - 1:
                        cv.px[yy][xx] = T_SOMBRA
    contorna(cv, pedra, T_CONTORNO, sem_baixo=True)
    # janela acesa (a Pata esta la) com moldura escura, e seteiras
    jy = int(round(43 * H / 150.0))
    for y in range(jy, jy + jh):
        for x in range(cx - jw // 2, cx + jw // 2):
            cv.px[y][x] = E["fee761"]
    if W > 20:
        for y in range(jy - 1, jy + jh + 1):
            for x in (cx - jw // 2 - 1, cx + jw // 2):
                cv.px[y][x] = T_CONTORNO
        for x in range(cx - jw // 2, cx + jw // 2):
            cv.px[jy - 1][x] = T_CONTORNO
            cv.px[jy + jh][x] = T_CONTORNO
    for i, yy in enumerate((70, 95, 120)):
        y0 = int(round(yy * H / 150.0))
        if y0 + sa >= H - 1:
            continue
        x0 = cx - sl // 2 + (int(round(4 * W / 36.0)) if i % 2 else -int(round(4 * W / 36.0)))
        for y in range(y0, y0 + sa):
            for x in range(x0, x0 + sl):
                cv.px[y][x] = E["3a4466"]
    return amplia(cv)


# ------------------------------------------------------------------ por dentro da torre
# A parede do fundo fica ESCURA (#262b44 com tijolos claros #3a4466 e rejunte #181425) para se
# separar do piso de pedra jogavel (tons de #5a6988 para cima) e dos personagens.
PAREDE = E["262b44"]
PAREDE_LUZ = E["3a4466"]
PAREDE_ESC = E["262b44"]
REJUNTE = E["181425"]


def parede():
    """Bloco de 128 px da parede de tijolos do fundo (emenda nos quatro lados). Tudo em blocos de
    2 na grade de 32 (1 px do jogo)."""
    S = 128
    cv = Canvas(S, S)
    for y in range(S):
        for x in range(S):
            cv.px[y][x] = REJUNTE
    for r in range(8):
        y0 = r * 16
        desloc = 16 if r % 2 else 0
        for c in range(-1, 5):
            x0 = c * 32 + desloc
            h = ((c % 4) * 31 + r * 17) % 7  # c=-1 e c=3 sao o mesmo tijolo cortado na emenda
            cor = PAREDE_LUZ if h == 0 else (PAREDE_ESC if h == 3 else PAREDE)
            for y in range(y0 + 2, y0 + 16):
                for x in range(x0 + 2, x0 + 32):
                    if 0 <= x < S:
                        cv.px[y][x] = cor
            # fio de luz de 1 px em cima dos tijolos escuros
            if cor != PAREDE_LUZ:
                for x in range(x0 + 2, x0 + 32):
                    if 0 <= x < S:
                        cv.px[y0 + 2][x] = cv.px[y0 + 3][x] = PAREDE_LUZ
    return cv


def janela_torre():
    """Janela em arco (o vidro e transparente: o ceu da hora da fase aparece atras). Moldura no
    tom da parede do fundo, um degrau mais clara, longe das cores do piso."""
    W, H = 72, 112
    d = Desenho(W, H)
    # sem #5a6988 (cor do contorno do pato e do piso de pedra): o filete de luz de 1 px que
    # sobrava no alto do arco (22,3) era o unico pixel dela e lia como sujeira
    pedra, pedra_s = E["3a4466"], E["262b44"]
    d.rect(4, 36, 64, 68, pedra, "moldura")
    d.elipse(36, 36, 32, 32, pedra, "moldura")
    d.rect(0, 100, 72, 12, pedra, "peitoril")
    d.sombra("moldura", pedra_s, dx=6, dy=0)
    d.sombra("peitoril", pedra_s, dx=0, dy=4)
    vidro = set(d.cv.mask_rect(14, 38, 44, 62)) | set(d.cv.mask_ellipse(36, 38, 22, 22))
    d.apaga(vidro)
    d.rect(34, 12, 4, 90, pedra_s, "grade")
    d.rect(12, 60, 48, 4, pedra_s, "grade")
    esc = E["181425"]
    d.contorno({"moldura": esc, "peitoril": esc, "grade": esc}, juntas=[("peitoril", "moldura")])
    return d.cv


FOGO_C, FOGO, FOGO_MEIO, FOGO_LUZ = E["be4a2f"], E["f77622"], E["feae34"], E["fee761"]
# (topo da chama, inclinacao da ponta) de cada quadro: vizinhos sempre com altura diferente
CHAMA = [(1, 0), (2, 1), (3, 0), (2, -1), (1, -1), (3, 1), (2, 0), (1, 1),
         (3, -1), (1, 0), (2, -1), (3, 0), (1, 1), (3, -1), (2, 1), (1, -1)]


def tocha(quadro):
    """Tocha de 16x32 px do jogo desenhada direto em pixels: cabo de madeira, aro de ferro escuro
    e chama cuja ponta sobe e desce 1-2 px e balanca; miolo amarelo afinando para cima."""
    W, H = 16, 32
    cv = Canvas(W, H)
    cabo = {(x, y) for x in range(6, 10) for y in range(15, 31)}
    for x, y in cabo:
        cv.px[y][x] = E["b86f50"] if x < 8 else E["733e39"]
    contorna(cv, cabo, E["3e2731"])
    # chama: largura por linha do topo t (ponta) ate a linha 12 (encosta no aro)
    t, inc = CHAMA[quadro]
    fogo = set()
    for y in range(t, 13):
        rel = (y - t) / float(12 - t)
        hw = 0.6 + 3.4 * math.sin(min(1.0, rel * 1.25) * math.pi / 2)
        meio = 8 + inc * (1 - rel) * 1.5
        for x in range(3, 13):
            if abs(x + 0.5 - meio) <= hw:
                fogo.add((x, y))
    # camadas por distancia a borda (a base continua dentro do aro)
    base = {(x, 13) for x in range(4, 12)}
    camada = {}
    atual = set(fogo)
    for k in range(4):
        viz = atual | base
        borda = {p for p in atual if any((p[0] + dx, p[1] + dy) not in viz
                                         for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
        for p in borda:
            camada[p] = k
        atual -= borda
    for p in atual:
        camada[p] = 4
    cores = (FOGO_C, FOGO, FOGO_MEIO, FOGO_LUZ, FOGO_LUZ)
    for (x, y), k in camada.items():
        cv.px[y][x] = cores[k]
    aro = {(x, y) for x in range(4, 12) for y in range(13, 16)}
    for x, y in aro:
        cv.px[y][x] = E["5a6988"] if y == 14 else E["3a4466"]
    contorna(cv, aro, E["181425"])
    return amplia(cv)


def coluna():
    """Trecho de 128 px de altura da coluna (emenda em cima e embaixo), com um anel no meio.
    Desenhada em pixels do jogo (28x64): um degrau mais clara que a parede do fundo, ainda
    longe das cores do piso."""
    W, H = 28, 64
    cv = Canvas(W, H)
    base, luz, som, esc = E["3a4466"], E["5a6988"], E["262b44"], E["181425"]
    for y in range(H):
        for x in range(3, 25):
            cv.px[y][x] = luz if x == 4 else (som if x >= 19 else base)
        cv.px[y][3] = esc
        cv.px[y][24] = esc
    for y in range(28, 36):  # anel
        for x in range(0, W):
            cv.px[y][x] = luz if (y == 29 and x < 22) else (som if (x >= 22 or y == 34) else base)
        cv.px[y][0] = esc
        cv.px[y][W - 1] = esc
    for x in range(W):
        cv.px[28][x] = esc
        cv.px[35][x] = esc
    for y in range(36, 38):  # sombra do anel na coluna
        for x in range(4, 24):
            cv.px[y][x] = som
    return amplia(cv)


def bandeira():
    """Estandarte do gaviao pendurado na parede, em pixels do jogo (20x44): pano vermelho #e43b44
    com luz #f6757a a esquerda, sombra #a22633 de 2 px a direita, contorno #3e2731 e o V amarelo."""
    W, H = 20, 44
    cv = Canvas(W, H)
    haste = {(x, y) for x in range(0, 20) for y in range(0, 3)}
    for x, y in haste:
        cv.px[y][x] = E["b86f50"] if y < 2 else E["733e39"]
    contorna(cv, haste, E["3e2731"])
    pano = set()
    for y in range(3, 39):
        for x in range(2, 18):
            corte = y - 31  # corte em V na ponta de baixo
            if corte > 0 and abs(x + 0.5 - 10) < corte * 8 / 7.0:
                continue
            pano.add((x, y))
    for x, y in pano:
        cv.px[y][x] = E["f6757a"] if x == 3 else (E["a22633"] if x >= 15 else E["e43b44"])
    for x in range(3, 17):
        cv.px[3][x] = E["a22633"]  # sombra da haste no pano
    contorna(cv, pano, E["3e2731"])
    # emblema: V amarelo (asas do gaviao), 2 px de traco, sombra laranja de 1 px embaixo
    v = set()
    for k in range(7):
        for g in (0, 1):
            v.add((5 + (k * 4) // 6 + g, 11 + k))
            v.add((14 - (k * 4) // 6 - g, 11 + k))
    for x, y in v:
        cv.px[y][x] = E["fee761"]
    for x, y in v:
        if (x, y + 1) not in v:
            cv.px[y + 1][x] = E["feae34"]
    return amplia(cv)


def tira(quadros):
    w, h = quadros[0].w, quadros[0].h
    cv = Canvas(w * len(quadros), h)
    for i, q in enumerate(quadros):
        cv.blit(q, i * w, 0)
    return cv


def pecas():
    p = {
        "montanhas": montanhas(),
        "colinas_longe": colinas_longe(),
        "colinas_perto": colinas_perto(),
        "sol": tira([sol(i) for i in range(16)]),
        "lua": lua(),
        "torre_longe": torre("torre_longe"),
        "torre_media": torre("torre_media"),
        "torre_perto": torre("torre_perto"),
        "parede": parede(),
        "janela": janela_torre(),
        "tocha": tira([tocha(i) for i in range(16)]),
        "coluna": coluna(),
        "bandeira": bandeira(),
    }
    for nome in NUVENS:
        p[nome] = nuvem(nome)
    return p


def folha(p):
    """Folha de conferencia com todas as pecas (fundo azul do ceu)."""
    W, H = 1100, 1010
    cv = Canvas(W, H)
    ceu = hexc("76c2f6")
    for y in range(H):
        for x in range(W):
            cv.px[y][x] = ceu
    cv.blit(p["montanhas"], 20, 20)
    cv.blit(p["colinas_longe"], 20, 290)
    cv.blit(p["colinas_perto"], 20, 480)
    x = 20
    for nome in ("nuvem_grande", "nuvem_media", "nuvem_pequena", "sol", "lua"):
        cv.blit(p[nome], x, 650)
        x += p[nome].w + 16
    x = 720
    for nome in ("torre_longe", "torre_media", "torre_perto"):
        cv.blit(p[nome], x, 990 - p[nome].h)
        x += p[nome].w + 20
    for yy in range(760, 1000):
        for xx in range(20, 700):
            cv.px[yy][xx] = REJUNTE
    for i in range(5):
        cv.blit(p["parede"], 24 + i * 128, 764)
        if 764 + 128 < 990:
            cv.blit(p["parede"], 24 + i * 128, 764 + 128)
    for yy in range(772, 872):
        for xx in range(110, 160):
            cv.px[yy][xx] = hexc("e0718f")
    cv.blit(p["janela"], 98, 770)
    cv.blit(p["tocha"], 220, 800)
    cv.blit(p["coluna"], 380, 764)
    cv.blit(p["coluna"], 380, 764 + 100)
    cv.blit(p["bandeira"], 480, 790)
    cv.save(os.path.join(OUT, "fundos_pecas.png"))


def composicao(p):
    """Conferencia das camadas como no jogo (parallax.gd, hora 'Dia'): ceu em faixas, montanhas,
    colinas_longe e colinas_perto empilhadas pela base (56, 54 e 22 px acima da base da tela),
    ja no resultado final 16x16. Grava tools/arte/saida/comp_colinas2.png (escala 3)."""
    from previa16 import final16  # so aqui: o previa16 importa os geradores
    W, H = G, 216
    cv = Canvas(W, H)
    ceu = ["0099db", "0099db", "0099db", "2ce8f5", "c0cbdc"]
    faixas = [0.0, 0.24, 0.44, 0.6, 0.74, 1.0]
    for i, c in enumerate(ceu):
        for y in range(int(H * faixas[i]), int(H * faixas[i + 1])):
            for x in range(W):
                cv.px[y][x] = hexc(c)
    for nome, acima in (("montanhas", 56), ("colinas_longe", 54), ("colinas_perto", 22)):
        im = final16("fundo/%s.png" % nome, p[nome])
        base = H - acima
        cv.blit(im, 0, base - im.h)
        for y in range(base, H):  # abaixo da tira, a cor da ultima linha (como no jogo)
            for x in range(W):
                c = im.px[im.h - 1][x]
                if c is not None:
                    cv.px[y][x] = c
    big = Canvas(W * 3, H * 3)
    big.blit(cv, 0, 0, 3)
    big.save(os.path.join(OUT, "comp_colinas2.png"))  # fora de assets/: grava como esta

def main():
    p = pecas()
    folha(p)
    composicao(p)
    if "--salvar" in sys.argv:
        os.makedirs(DEST, exist_ok=True)
        for nome, cv in p.items():
            cv.save(os.path.join(DEST, nome + ".png"))
        print("salvo em assets/sprites/arte/fundo/:", ", ".join(sorted(p)))
    print("ok")


if __name__ == "__main__":
    main()
