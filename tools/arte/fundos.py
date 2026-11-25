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
from estilo import Desenho, P, dist  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
DEST = os.path.join(ROOT, "assets", "sprites", "arte", "fundo")
OUT = os.path.join(HERE, "saida")
os.makedirs(OUT, exist_ok=True)

L = 1024  # largura das tiras


def degrau(v, passo=2):
    return int(round(v / passo)) * passo


# ------------------------------------------------------------------ montanhas
SERRA = [(0, 90), (60, 150), (125, 95), (190, 230), (262, 120), (330, 170), (398, 110), (470, 250),
         (545, 125), (610, 190), (672, 100), (730, 140), (790, 105), (850, 220), (910, 115),
         (960, 170), (1024, 90)]
M_LUZ, M_SOMBRA = hexc("9db6e6"), hexc("8aa2d8")
NEVE, NEVE_SOMBRA = hexc("ffffff"), hexc("d9e6fa")


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
        for x, y in cv.mask_poly([(px, H - ph), (vx, H - vh), (max(ex, crista + 8), H), (crista, H)]):
            if 0 <= x < L and topo[x] <= y < H:
                cv.px[y][x] = M_SOMBRA
        # um dente de sombra na face clara (relevo)
        (lx, lh) = SERRA[i - 1]
        mx = (lx + px) // 2
        for x, y in cv.mask_poly([(mx, topo[mx] + 14), (mx + 18, topo[mx] + 60), (mx + 4, topo[mx] + 60)]):
            if 0 <= x < L and topo[x] <= y < H:
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
def perfil(base, ondas):
    return [degrau(base + sum(a * math.sin(2 * math.pi * n * x / L + f) for a, n, f in ondas))
            for x in range(L)]


def colinas(H, alt, cor, cor_luz, cor_mata, cor_mata_sombra, matas, raio, extras=None):
    cv = Canvas(L, H)
    topo = [H - a for a in alt]
    for x in range(L):
        for y in range(topo[x], H):
            cv.px[y][x] = cor_luz if y < topo[x] + 4 else cor
    # matas: arvores redondinhas ao longo do morro (a meia-lua de sombra fica embaixo/direita)
    for x0, n in matas:
        for j in range(n):
            x = (x0 + j * int(raio * 1.5)) % L
            r = raio + ((x0 * 7 + j * 5) % 5) - 2
            cy = topo[x] - r + 5
            fora = set(cv.mask_ellipse(x, cy, r, r + 1))
            dentro = set(cv.mask_ellipse(x - 3, cy - 3, r, r + 1))
            for px, py in fora:
                if 0 <= py < H:
                    cv.px[py][px % L] = cor_mata_sombra if (px, py) not in dentro else cor_mata
    if extras:
        extras(cv, topo)
    return cv


def colinas_longe():
    alt = perfil(112, [(34, 1, 0.5), (18, 3, 2.0), (8, 5, 4.1)])
    verde, luz = dist(P["folha"], 0.52), dist(P["folha_luz"], 0.5)
    mata, mata_s = (96, 196, 122, 255), (76, 174, 108, 255)
    def extras(cv, topo):
        casinha(cv, topo, 250)
        casinha(cv, topo, 742)
    return colinas(180, alt, verde, luz, mata, mata_s,
                   [(40, 3), (170, 5), (330, 2), (470, 4), (640, 6), (800, 2), (930, 3)], 8, extras)


def casinha(cv, topo, x):
    """Celeiro bem ao longe, no alto do morro distante (da nocao de distancia: perto do chao
    do jogo nada de cenario e menor que o pato)."""
    y = topo[x] + 3
    par, par_s, tel = dist(P["vermelho"], 0.55), dist(P["vermelho_sombra"], 0.55), dist(P["madeira_sombra"], 0.55)
    for yy in range(y - 10, y):
        for xx in range(x, x + 16):
            cv.px[yy][xx % L] = par if xx < x + 12 else par_s
    for k in range(6):
        for xx in range(x - 2 + k * 2, x + 18 - k * 2):
            cv.px[y - 11 - k][xx % L] = tel


def colinas_perto():
    alt = perfil(74, [(28, 2, 1.0), (13, 5, 0.3), (5, 9, 2.2)])
    verde, luz = dist(P["folha"], 0.3), dist(P["folha_luz"], 0.26)
    mata, mata_s = dist(P["folha_sombra"], 0.22), dist(P["contorno_verde"], 0.42)

    def extras(cv, topo):
        # plantacao: um canteiro amarelado com as fileiras em diagonal
        campo, campo_s = dist(hexc("d9e86a"), 0.25), dist(hexc("b4cf4c"), 0.25)
        for x0, larg in ((108, 84), (590, 100)):
            for x in range(x0, x0 + larg):
                t = topo[x % L]
                borda = min(x - x0, x0 + larg - 1 - x)
                for j in range(10 - min(borda, 4), 40 + min(borda, 4)):
                    y = t + j
                    if y < cv.h:
                        cv.px[y][x % L] = campo_s if (x + j) % 10 < 2 else campo
    return colinas(150, alt, verde, luz, mata, mata_s,
                   [(20, 2), (210, 4), (420, 3), (520, 2), (700, 5), (900, 3)], 13, extras)


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


SOL, SOL_LUZ, RAIO = hexc("ffe94a"), hexc("fff7a8"), hexc("fff3a0")


def sol(quadro):
    S = 96
    d = Desenho(S, S)
    c = S // 2
    r0, r1 = (30, 38) if quadro == 0 else (33, 44)
    for k in range(8):
        a = k * math.pi / 4.0 + (0.0 if quadro == 0 else math.pi / 8.0)
        ca, sa = math.cos(a), math.sin(a)
        d.poli([(c + ca * r0 - sa * 3, c + sa * r0 + ca * 3), (c + ca * r1 - sa * 2, c + sa * r1 + ca * 2),
                (c + ca * r1 + sa * 2, c + sa * r1 - ca * 2), (c + ca * r0 + sa * 3, c + sa * r0 - ca * 3)], RAIO)
    d.elipse(c, c, 24, 24, SOL)
    d.elipse(c - 3, c - 3, 17, 17, SOL_LUZ)
    return d.cv


def lua():
    S = 64
    d = Desenho(S, S)
    d.elipse(32, 32, 20, 20, hexc("f4f1d0"), "lua")
    d.apaga(d.cv.mask_ellipse(42, 26, 18, 18))
    return d.cv


# ------------------------------------------------------------------ torre do gaviao (ao longe)
ROXO, ROXO_S = (126, 92, 140, 255), (98, 70, 112, 255)


def torre(s=1.0, k=0.3):
    """Torre vista de fora. s = tamanho (1 = 150 px do jogo de altura); k = quao longe (cor)."""
    W, H = int(80 * s) // 2 * 2, int(300 * s) // 2 * 2  # pares: meio pixel do jogo nao existe
    d = Desenho(W, H)
    n = lambda v: int(round(v * s))  # noqa: E731
    cx = W // 2
    pedra, pedra_s, pedra_l = dist(P["pedra"], k), dist(P["pedra_sombra"], k), dist(P["pedra_luz"], k)
    d.rect(cx - n(22), n(64), n(44), H - n(64), pedra, "corpo")
    d.rect(cx - n(28), n(48), n(56), n(22), pedra, "topo")
    m = max(4, n(8))
    d.rect(cx - n(24), n(48) - m, n(48), m, pedra_s, "fundo_topo")  # parede de tras das ameias
    x = cx - n(28)
    while x + m <= cx + n(28) + 1:
        d.rect(x, n(48) - m, m, m, pedra, "topo")
        x += m * 2 - (1 if s < 0.6 else 0)
    d.sombra("corpo", pedra_s, dx=max(4, n(14)), dy=0)
    d.luz("corpo", pedra_l, dx=max(2, n(5)), dy=0)
    d.sombra("topo", pedra_s, dx=max(4, n(16)), dy=max(2, n(4)))
    # sombra do topo sobre o corpo
    d.rect(cx - n(22), n(70), n(44), max(2, n(5)), pedra_s, None, so=["corpo"])
    # telhado pontudo e bandeira
    d.poli([(cx - n(20), n(48) - m + 1), (cx, n(2)), (cx + n(20), n(48) - m + 1)], dist(ROXO, k), "telhado")
    d.sombra("telhado", dist(ROXO_S, k), dx=max(3, n(10)), dy=0)
    # janela acesa la no alto (a Pata esta la) e seteiras
    jw, jh = max(4, n(10)), max(6, n(16))
    d.rect(cx - jw // 2, n(86), jw, jh, P["janela_luz"], "janela")
    d.elipse(cx, n(86), jw / 2.0, max(2, n(5)), P["janela_luz"], "janela")
    sw, sh = max(2, n(5)), max(5, n(14))
    for i, yy in enumerate((140, 190, 240)):
        d.rect(cx - sw // 2 + (n(8) if i % 2 else -n(8)), n(yy), sw, sh, dist(P["janela"], k), "seteira")
    if s >= 0.6:
        for bx, by in [(-16, 120), (4, 170), (-12, 222), (6, 268), (-4, 104)]:
            d.rect(cx + n(bx), n(by), max(4, n(9)), max(2, n(3)), pedra_s, None, so=["corpo"])
    esc = dist(P["contorno_pedra"], k)
    d.contorno({"corpo": esc, "topo": esc, "fundo_topo": esc, "telhado": dist((70, 48, 84, 255), k), "janela": esc, "seteira": esc},
               juntas=[("topo", "corpo"), ("telhado", "topo")])
    # a base some atras do morro: tira o contorno de baixo
    for x in range(W):
        if d.cv.px[H - 1][x] is not None:
            d.cv.px[H - 1][x] = d.cv.px[H - 2][x] if d.cv.px[H - 2][x] != esc else pedra
    return d.cv


# ------------------------------------------------------------------ por dentro da torre
PAREDE = hexc("454a69")
PAREDE_LUZ = hexc("50567a")
PAREDE_ESC = hexc("3d4160")
REJUNTE = hexc("343852")


def parede():
    """Bloco de 128 px da parede de tijolos do fundo (emenda nos quatro lados)."""
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
            h = (c * 31 + r * 17) % 7
            cor = PAREDE_LUZ if h == 0 else (PAREDE_ESC if h == 3 else PAREDE)
            for y in range(y0 + 2, y0 + 16):
                for x in range(x0 + 2, x0 + 32):
                    if 0 <= x < S:
                        cv.px[y][x] = cor
            # fio de luz em cima e a esquerda de cada tijolo
            for x in range(x0 + 2, x0 + 32):
                if 0 <= x < S:
                    cv.px[y0 + 2][x] = PAREDE_LUZ if cor != PAREDE_LUZ else hexc("5c6288")
    return cv


def janela_torre():
    """Janela em arco (o vidro e transparente: o ceu da hora da fase aparece atras)."""
    W, H = 72, 112
    d = Desenho(W, H)
    pedra, pedra_s, pedra_l = hexc("7d84a3"), hexc("636a8a"), hexc("979ebb")
    d.rect(4, 36, 64, 68, pedra, "moldura")
    d.elipse(36, 36, 32, 32, pedra, "moldura")
    d.rect(0, 100, 72, 12, pedra, "peitoril")
    d.sombra("moldura", pedra_s, dx=5, dy=0)
    d.luz("moldura", pedra_l, dx=3, dy=3)
    d.sombra("peitoril", pedra_s, dx=0, dy=4)
    d.luz("peitoril", pedra_l, dx=0, dy=2)
    vidro = set(d.cv.mask_rect(14, 38, 44, 62)) | set(d.cv.mask_ellipse(36, 38, 22, 22))
    d.apaga(vidro)
    d.rect(34, 12, 4, 90, pedra_s, "grade")
    d.rect(12, 60, 48, 4, pedra_s, "grade")
    esc = hexc("2c3049")
    d.contorno({"moldura": esc, "peitoril": esc, "grade": esc}, juntas=[("peitoril", "moldura")])
    return d.cv


FOGO, FOGO_MEIO, FOGO_LUZ = hexc("ff8a2a"), hexc("ffc93c"), hexc("fff6b0")


def tocha(quadro):
    W, H = 32, 64
    d = Desenho(W, H)
    d.rect(13, 30, 6, 30, P["madeira"], "cabo")
    d.rect(17, 30, 2, 30, P["madeira_sombra"], None, so=["cabo"])
    d.rect(8, 26, 16, 6, hexc("8f96ae"), "aro")
    d.rect(8, 30, 16, 2, hexc("636a8a"), None, so=["aro"])
    formas = [
        [(16, 2), (23, 14), (24, 22), (20, 27), (12, 27), (8, 22), (10, 12)],
        [(13, 3), (22, 12), (24, 22), (20, 27), (12, 27), (8, 21), (9, 13)],
        [(18, 4), (24, 15), (23, 23), (20, 27), (12, 27), (8, 22), (11, 11)],
    ]
    d.poli(formas[quadro], FOGO, "fogo")
    dx = (0, -1, 1)[quadro]
    d.elipse(16 + dx, 20, 5, 7, FOGO_MEIO, None, so=["fogo"])
    d.elipse(16 + dx, 23, 3, 4, FOGO_LUZ, None, so=["fogo"])
    d.contorno({"cabo": P["contorno_madeira"], "aro": hexc("2c3049"), "fogo": hexc("d9601c")},
               juntas=[("aro", "cabo")])
    return d.cv


def coluna():
    """Trecho de 128 px de altura da coluna (emenda em cima e embaixo), com um anel no meio."""
    W, H = 56, 128
    cv = Canvas(W, H)
    base, luz, som, esc = hexc("5a6085"), hexc("6b7198"), hexc("4a5072"), hexc("2c3049")
    for y in range(H):
        for x in range(6, 50):
            cv.px[y][x] = luz if x < 14 else (som if x >= 38 else base)
        cv.px[y][6] = esc
        cv.px[y][49] = esc
    for y in range(56, 72):  # anel
        for x in range(0, W):
            cv.px[y][x] = luz if y < 60 else (som if y >= 68 else base)
            if x >= 44:
                cv.px[y][x] = som
        cv.px[y][0] = esc
        cv.px[y][W - 1] = esc
    for x in range(W):
        cv.px[56][x] = esc
        cv.px[71][x] = esc
    for y in range(72, 77):  # sombra do anel na coluna
        for x in range(7, 49):
            cv.px[y][x] = som
    return cv


def bandeira():
    """Estandarte do gaviao pendurado na parede."""
    W, H = 40, 88
    d = Desenho(W, H)
    d.rect(0, 0, 40, 6, P["madeira"], "haste")
    d.poli([(4, 6), (36, 6), (36, 76), (20, 62), (4, 76)], P["vermelho_sombra"], "pano")
    d.sombra("pano", hexc("962824"), dx=6, dy=0)
    d.luz("pano", P["vermelho"], dx=4, dy=0)
    # emblema: um V amarelo (asas do gaviao)
    for t in range(4):
        d.linha(12, 22 + t, 20, 36 + t, P["amarelo_escuro"], so=["pano"], grossura=2)
        d.linha(28, 22 + t, 20, 36 + t, P["amarelo_escuro"], so=["pano"], grossura=2)
    d.contorno({"haste": P["contorno_madeira"], "pano": P["contorno_vermelho"]}, juntas=[("haste", "pano")])
    return d.cv


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
        "sol": tira([sol(0), sol(1)]),
        "lua": lua(),
        "torre_longe": torre(0.45, 0.42),
        "torre_media": torre(0.7, 0.34),
        "torre_perto": torre(0.9, 0.26),
        "parede": parede(),
        "janela": janela_torre(),
        "tocha": tira([tocha(0), tocha(1), tocha(2)]),
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


def main():
    p = pecas()
    folha(p)
    if "--salvar" in sys.argv:
        os.makedirs(DEST, exist_ok=True)
        for nome, cv in p.items():
            cv.save(os.path.join(DEST, nome + ".png"))
        print("salvo em assets/sprites/arte/fundo/:", ", ".join(sorted(p)))
    print("ok")


if __name__ == "__main__":
    main()
