"""Previa do resultado FINAL (16x16, Endesga 32) de um gerador, sem gravar nada em assets/.
Faz exatamente o que o Canvas.save() faria (reduz 4x os AMPLIADOS_4X, reduz2 quadro a quadro,
paleta) e grava uma folha ampliada em tools/arte/saida/previa16_<gerador>.png.
Uso: python tools/arte/previa16.py <gerador> [escala]
     gerador = inimigos | chefes | objetos | lote_base | itens | fundos | cenario | pato16 | cutscene_arte | pedra
O gerador precisa ter pecas() devolvendo {nome: Canvas ou lista de Canvas (quadros)}; os nomes
de cenario/fundos ganham o prefixo da pasta automaticamente."""
import importlib
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import pixelkit as K  # noqa: E402
from pixelkit import Canvas  # noqa: E402

PREFIXO = {"cenario": "cenario/", "fundos": "fundo/"}
BG = (118, 194, 246, 255)


def final16(rel, img):
    """O que o save() gravaria para a peca 'rel' (ex.: 'raposa.png', 'fundo/sol.png')."""
    nome = K._nome(rel)
    if nome in K.AMPLIADOS_4X:
        try:  # alguns geradores entregam a grade de 32 e so ampliam 4x na hora de gravar
            img = img._reduz(4)
        except AssertionError:
            pass
    if nome in K.SEM_REDUCAO:
        return img
    fw, fh = K._quadro_de(rel, img.w, img.h)
    return img.reduz2(fw, fh, K.emenda(rel)).paleta()


def tira(qs):
    if isinstance(qs, Canvas):
        return qs
    w, h = qs[0].w, qs[0].h
    cv = Canvas(w * len(qs), h)
    for i, q in enumerate(qs):
        cv.blit(q, i * w, 0)
    return cv


def main():
    modulo = sys.argv[1]
    escala = int(sys.argv[2]) if len(sys.argv) > 2 else 4
    m = importlib.import_module(modulo)
    p = m.pecas()
    res = []
    for nome, qs in p.items():
        t = tira(qs)
        if modulo == "pato16":  # o pato16 ja entrega 16x16 prontos (o save so amplia e reduz de volta)
            res.append((nome, t.paleta()))
            continue
        rel = PREFIXO.get(modulo, "") + nome + ".png"
        try:
            res.append((nome, final16(rel, t)))
        except AssertionError as e:
            print("AVISO", nome, "nao reduz:", e)
    MAXW = 1400 // escala
    y = 2
    pos = []
    for nome, im in res:
        pos.append((nome, im, y))
        y += im.h + 3
    W = min(MAXW, max(im.w for _, im in res) + 4)
    cv = Canvas(W, y)
    for yy in range(y):
        for xx in range(W):
            cv.px[yy][xx] = BG
    for nome, im, y0 in pos:
        for yy in range(im.h):
            for xx in range(min(im.w, W - 2)):
                c = im.px[yy][xx]
                if c is not None:
                    cv.px[y0 + yy][2 + xx] = c
    big = Canvas(cv.w * escala, cv.h * escala)
    big.blit(cv, 0, 0, escala)
    dest = os.path.join(HERE, "saida", "previa16_%s.png" % modulo)
    big.save(dest)
    print(dest)
    for nome, im, _ in pos:
        print("  %-22s %dx%d" % (nome, im.w, im.h))


if __name__ == "__main__":
    main()
