"""Flores e itens na base de estilo (tools/arte/estilo.py): flor vermelha (4 quadros balancando),
coracao (cheio e vazio), chave, caixa de madeira, fardo de feno e estrela (cheia e vazia).
Grade de 32 (o tamanho do pato), gravados 4x em 128x128 por quadro.
Uso: python tools/arte/itens.py [--salvar]   (previa em tools/arte/saida/itens.png)"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas, load_png, hexc, save_gif  # noqa: E402
from estilo import Desenho, P  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
ARTE = os.path.join(ROOT, "assets", "sprites", "arte")
OUT = os.path.join(HERE, "saida")
os.makedirs(OUT, exist_ok=True)

OURO, OURO_LUZ, OURO_S, OURO_ESC = hexc("ffd23f"), hexc("fff0a0"), hexc("e0a81f"), hexc("8a5a00")
FENO, FENO_LUZ, FENO_S, FENO_ESC = hexc("f4d35e"), hexc("fbe58c"), hexc("d9ae3a"), hexc("8a6a1e")
VAZIO, VAZIO_S, VAZIO_ESC = hexc("4a5072"), hexc("3d4160"), hexc("2c3049")


SPR = os.path.join(ROOT, "assets", "sprites")


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
    """A rosa original (spr_flor01, 16x16) com o dobro de detalhe e contorno de 1 px."""
    return refazer(load_png(os.path.join(SPR, "spr_flor01.png")), quadro * 16, 16, 16, (76, 8, 11), sem_branco=True)


def coracao(cheio=True):
    """O coracao original: ele ja esta na grade da arte (32x32 desenhado pela metade)."""
    nome = "spr_vidaCheia.png" if cheio else "spr_vidaVazia.png"
    return refazer(load_png(os.path.join(SPR, nome)), 0, 32, 32, (255, 255, 255), escala=1)


def estrela(cheia=True):
    """A estrela original (spr_estrela, 16x16) com o dobro de detalhe e contorno de 1 px."""
    cont = (154, 106, 0) if cheia else (29, 42, 29)
    return refazer(load_png(os.path.join(SPR, "spr_estrela.png")), 0 if cheia else 16, 16, 16, cont)


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


MAD, MAD_LUZ, MAD_ESC = hexc("a86830"), hexc("d69650"), hexc("4a2810")


def caixa():
    """A caixa que o jogo desenhava em codigo, no dobro: tres tabuas e um X claro."""
    d = Desenho(32, 32)
    d.rect(0, 0, 32, 32, MAD, "c")
    d.rect(1, 1, 30, 1, MAD_LUZ)
    for y in (10, 21):
        d.rect(1, y, 30, 1, MAD_ESC)
    d.linha(3, 3, 28, 28, MAD_LUZ)
    d.linha(28, 3, 3, 28, MAD_LUZ)
    for y in (10, 21):
        d.rect(1, y, 30, 1, MAD_ESC)
    d.contorno({"c": MAD_ESC})
    return d.cv


def feno():
    """O fardo de feno que o jogo desenhava em codigo, no dobro: palhas claras e duas cordas."""
    d = Desenho(32, 32)
    d.rect(0, 0, 32, 32, hexc("deb84a"), "f")
    d.rect(1, 1, 30, 1, FENO_LUZ)
    for i, y in enumerate(range(5, 29, 5)):
        d.rect(3 + (i % 2) * 2, y, 9, 1, FENO_LUZ)
        d.rect(17 + (i % 2) * 2, y + 2, 9, 1, FENO_LUZ)
    for x in (8, 22):
        d.rect(x, 1, 2, 30, hexc("963c28"))
    d.contorno({"f": hexc("8c681e")})
    return d.cv


def tira(quadros):
    cv = Canvas(32 * len(quadros), 32)
    for i, q in enumerate(quadros):
        cv.blit(q, i * 32, 0)
    return cv


def pecas():
    return {
        "flor": tira([flor(i) for i in range(4)]),
        "coracao": tira([coracao(True), coracao(False)]),
        "chave": chave(),
        "caixa": caixa(),
        "feno": feno(),
        "estrela": tira([estrela(True), estrela(False)]),
    }


def folha(p):
    S = 6
    ordem = ["flor", "coracao", "estrela", "chave", "caixa", "feno"]
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
            big = Canvas(cv.w * 4, cv.h * 4)
            big.blit(cv, 0, 0, 4)
            big.save(os.path.join(ARTE, nome + ".png"))
        print("salvo em assets/sprites/arte/:", ", ".join(sorted(p)))
    print("ok")


if __name__ == "__main__":
    main()
