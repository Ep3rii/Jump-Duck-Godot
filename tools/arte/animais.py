"""Animais da fazenda (enfeite com quem o pato conversa, sem colisao): galinha, porco, vaca e
ovelha, cada um com a animacao parada de 16 quadros (a exigencia e 15 ou mais).
Mesmo jeito do pato16.py: cada desenho e um mapa de caracteres direto na grade do jogo, sem
reducao. O mapa so traz o miolo; o contorno de 1 px sai sozinho em volta da silhueta e a luz
de cima/esquerda sai sozinha nos materiais com rampa (claro, medio, escuro). Todos olham para
a DIREITA (o jogo espelha) e pisam na ultima linha do quadro. So cores da Endesga 32.
Cada quadro da tira = pose (mapa inteiro ou remendos) + respiracao (tudo acima das pernas
desce 1 px) + piscada.
Uso: python tools/arte/animais.py [--salvar]
  previa: GIFs e folha ampliada em tools/arte/saida/, tiras 1:1 em tools/arte/saida/animais/
  --salvar: grava as tiras 1:1 em assets/sprites/arte/<nome>.png (PIL direto, sem reducao)"""
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas, ENDESGA32, save_gif  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
ARTE = os.path.join(ROOT, "assets", "sprites", "arte")
OUT = os.path.join(HERE, "saida")
OUT_TIRAS = os.path.join(OUT, "animais")
N = 16  # quadros por animacao
VIZ4 = ((1, 0), (-1, 0), (0, 1), (0, -1))


def _c(h):
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


# ------------------------------------------------------------ desenho a partir do mapa
def render(grade, cores, contorno, linhas=""):
    """grade: lista de strings ('.' = vazio). cores[ch] = '#rrggbb' fixo ou (claro, medio,
    escuro) com luz automatica. Caracteres em 'linhas' sao tracos de 1 px: desenhados por cima
    do contorno e sem contorno proprio. Devolve uma Canvas."""
    h, w = len(grade), len(grade[0])
    cv = Canvas(w, h)

    def cheio(x, y):
        return 0 <= x < w and 0 <= y < h and grade[y][x] != "." and grade[y][x] not in linhas

    for y in range(h):
        for x in range(w):
            ch = grade[y][x]
            if ch == "." or ch in linhas:
                continue
            cor = cores[ch]
            if isinstance(cor, tuple):
                claro, medio, escuro = cor
                if not cheio(x, y - 1):
                    cor = claro
                elif not cheio(x, y + 1) or not cheio(x + 1, y):
                    cor = escuro
                elif not cheio(x - 1, y):
                    cor = claro
                else:
                    cor = medio
            cv.px[y][x] = _c(cor.lstrip("#"))
    cont = _c(contorno.lstrip("#"))
    for y in range(h):
        for x in range(w):
            if not cheio(x, y) and any(cheio(x + dx, y + dy) for dx, dy in VIZ4):
                cv.px[y][x] = cont
    for y in range(h):
        for x in range(w):
            ch = grade[y][x]
            if ch != "." and ch in linhas:
                cv.px[y][x] = _c(cores[ch].lstrip("#"))
    return cv


def remenda(grade, remendos):
    """remendos: [(x, y, [linhas])]; ',' mantem, '.' apaga, o resto troca."""
    g = [list(r) for r in grade]
    for x0, y0, rows in remendos:
        for dy, row in enumerate(rows):
            for dx, ch in enumerate(row):
                if ch != ",":
                    g[y0 + dy][x0 + dx] = ch
    return ["".join(r) for r in g]


def respira(grade, y_pernas):
    """Tudo acima da linha y_pernas desce 1 px (as pernas ficam; a de cima some sob o corpo)."""
    g = [list(r) for r in grade]
    w = len(g[0])
    novo = [["."] * w] + [list(r) for r in g[:y_pernas]]
    for x in range(w):
        if novo[y_pernas][x] == ".":
            novo[y_pernas][x] = g[y_pernas][x]
    return ["".join(r) for r in novo[:y_pernas + 1]] + ["".join(r) for r in g[y_pernas + 1:]]


def troca(grade, de, para):
    return [r.replace(de, para) for r in grade]


class Bicho:
    def __init__(self, nome, cores, contorno, linhas, y_pernas, poses, seq):
        self.nome, self.cores, self.contorno, self.linhas = nome, cores, contorno, linhas
        self.y_pernas, self.poses, self.seq = y_pernas, poses, seq
        for k, g in poses.items():
            assert len(set(len(r) for r in g)) == 1, (nome, k)

    def quadros(self):
        """seq: 16 itens 'pose' ou 'pose+r' (respira) e/ou '+p' (pisca)."""
        out = []
        assert len(self.seq) == N, self.nome
        for item in self.seq:
            partes = item.split("+")
            g = self.poses[partes[0]]
            if "p" in partes[1:]:
                g = troca(g, "e", "z")  # olho fechado: palpebra
            if "r" in partes[1:]:
                g = respira(g, self.y_pernas)
            out.append(render(g, self.cores, self.contorno, self.linhas))
        return out


# ------------------------------------------------------------ galinha (16x16)
# b corpo marrom com luz, w asa, W risco da asa, t rabo, r crista, y/q bico, k barbela,
# e olho, z palpebra, f pernas
GALINHA_BASE = [
    "................",
    "................",
    "................",
    ".........r.r....",
    "........rrrr....",
    "..t.....bbbb....",
    ".ttt...bbbebyy..",
    ".tttb..bbbbbq...",
    ".ttbbb.bbbbk....",
    "..bbbbbbbbbk....",
    "..bbWwwwbbbb....",
    "..bbbWwwwbb.....",
    "...bbbbbbbb.....",
    ".....f..f.......",
    ".....ff.ff......",
    "................",
]
# cabeca a meio caminho do chao
GALINHA_MEIO = [
    "................",
    "................",
    "................",
    "................",
    "................",
    "..t.......r.r...",
    ".ttt.....rrrr...",
    ".tttb....bbbb...",
    ".ttbbb..bbbebyy.",
    "..bbbbbbbbbbq...",
    "..bbWwwwbbbbk...",
    "..bbbWwwwbbk....",
    "...bbbbbbbb.....",
    ".....f..f.......",
    ".....ff.ff......",
    "................",
]
# bicando o chao: corpo inclina, rabo sobe, bico encosta no chao
GALINHA_BICA = [
    "................",
    "................",
    "................",
    "..t.............",
    ".ttt............",
    ".tttb...........",
    ".ttbbb..........",
    "..bbbbbbbb......",
    "..bbbbbbbbbrr...",
    "..bbWwwwbbbbbr..",
    "..bbbWwwwbbbebk.",
    "...bbbbbbbbbbbk.",
    "...........yq...",
    ".....f..f..yq...",
    ".....ff.ff......",
    "................",
]
GALINHA_RABO = remenda(GALINHA_BASE, [(0, 4, ["t...", ".t..", "ttt,", "tt,,"])])
GALINHA = Bicho(
    "galinha",
    {"b": ("e4a672", "d77643", "b86f50"), "w": "b86f50", "W": "733e39",
     "t": ("b86f50", "733e39", "733e39"), "r": ("e43b44", "e43b44", "a22633"),
     "y": "feae34", "q": "f77622", "k": "a22633", "e": "181425", "z": "b86f50", "f": "f77622"},
    "3e2731", "", 12,
    {"base": GALINHA_BASE, "meio": GALINHA_MEIO, "bica": GALINHA_BICA, "rabo": GALINHA_RABO},
    ["base", "base", "base+r", "base+r", "base", "base+p", "base", "meio",
     "bica", "bica", "meio", "base", "rabo", "rabo", "base+r", "base"],
)


# ------------------------------------------------------------ porco (24x16)
# b corpo rosa com luz, p orelha, s focinho, n narina, c rabo enrolado (traco), l/d perna da
# frente/de tras, h casco, O risco escuro entre as pernas
PORCO_BASE = [
    "........................",
    "........................",
    "........................",
    "...............ppp......",
    "......bbbbbbbb.ppbb.....",
    "....bbbbbbbbbbbbpbbb....",
    "...bbbbbbbbbbbbbbbbeb...",
    "..cbbbbbbbbbbbbbbbbbOss.",
    ".c.bbbbbbbbbbbbbbbbbOns.",
    "..cbbbbbbbbbbbbbbbbbOss.",
    "...bbbbbbbbbbbbbbbbbb...",
    "...bbbbbbbbbbbbbbbbb....",
    "....bbbbbbbbbbbbbbb.....",
    ".....llOd....llOd.......",
    ".....hhOh....hhOh.......",
    "........................",
]
PORCO_FUNGA = remenda(PORCO_BASE, [(20, 6, ["Oss", "Ons", "Oss", ".,,"])])
PORCO_ORELHA = remenda(PORCO_BASE, [(15, 2, ["...p", ".ppp", "b,,,"])])
PORCO_RABO = remenda(PORCO_BASE, [(0, 6, [".c,", "..c", "..c", "..,"])])
PORCO = Bicho(
    "porco",
    {"b": ("e8b796", "f6757a", "b55088"), "p": "b55088", "s": "e8b796", "n": "b55088",
     "c": "b55088", "l": "f6757a", "d": "b55088", "h": "733e39", "O": "3e2731",
     "e": "181425", "z": "b55088"},
    "3e2731", "c", 12,
    {"base": PORCO_BASE, "funga": PORCO_FUNGA, "orelha": PORCO_ORELHA, "rabo": PORCO_RABO},
    ["base", "base", "base+r", "base+r", "base", "funga", "base", "funga",
     "base", "base+p", "base+r", "base+r", "orelha", "rabo", "rabo", "base"],
)


# ------------------------------------------------------------ ovelha (24x16)
# w la com luz, W cachinho, f cara bege, k orelha, m boca, l/d pernas, h casco
OVELHA_BASE = [
    "........................",
    "........................",
    "........................",
    "....ww..ww..ww...ww.....",
    "....wwwwwwwwwwwwwwww....",
    "...wwwwwwwwwwwwwkkfff...",
    "..wwwwwwwWWwwwwwwffeff..",
    "..wwwwwwwwwwwwwwwffffff.",
    "..wwwWWwwwwwwwWWwwfffmf.",
    "..wwwwwwwwwwwwwwwwwfff..",
    "...wwwwwwwwWWwwwwww.....",
    "....ww.wwwwwww.ww.......",
    ".....llOd....llOd.......",
    ".....llOd....llOd.......",
    ".....hhOh....hhOh.......",
    "........................",
]
OVELHA_MASTIGA = remenda(OVELHA_BASE, [(18, 8, [",,,,.", ",ffmf"])])
OVELHA_ORELHA = remenda(OVELHA_BASE, [(15, 4, ["k,", "wk"])])
OVELHA = Bicho(
    "ovelha",
    {"w": ("ffffff", "ffffff", "c0cbdc"), "W": "c0cbdc", "f": ("ead4aa", "e8b796", "c28569"),
     "k": "c28569", "m": "733e39", "l": ("e8b796", "c28569", "c28569"), "d": "733e39", "h": "3e2731", "O": "3e2731",
     "e": "181425", "z": "c28569"},
    "262b44", "", 11,
    {"base": OVELHA_BASE, "mastiga": OVELHA_MASTIGA, "orelha": OVELHA_ORELHA},
    ["base", "mastiga", "base", "mastiga", "base+r", "mastiga+r", "base+r", "base",
     "base+p", "base", "orelha", "base", "mastiga", "base+r", "mastiga+r", "base"],
)


# ------------------------------------------------------------ vaca (32x24)
# b couro branco com luz, s mancha preta, H chifre, k orelha, p focinho rosa, n narina,
# c rabo e t tufo (tracos sem contorno), u ubre, l/d pernas, h casco, O risco escuro
VACA_CORPO = [
    "................................",
    "................................",
    "................................",
    ".........................H......",
    ".........................HH.....",
    "........................bbbbb...",
    "......................kkbbbbbb..",
    ".....bbbbbbbbbbbbbbbbbbbbbbebb..",
    "....bbbbsssbbbbbbbbbbbbbbbbbbb..",
    "....bbbsssssbbbbbbssbbbbbbbbppp.",
    "....bbbsssssbbbbbsssbbbbbbbpppp.",
    "....bbbbsssbbbbbbbsbbbbbbbbppnp.",
    "....bbbbbbbbbbbbbbbbbbbbbb.pppp.",
    "....bbbbbbbbbbbbbbbbbbbbbb......",
    "....bbbbbbbbbbbbbbbbbbbbbb......",
    ".....bbbbbbbbbbbbbbbbbbbb.......",
    "......bbbbbuubbbbbbbbbbb........",
    "......bbllOd.uu..llOdbb.........",
    ".......llOd......llOd...........",
    ".......llOd......llOd...........",
    ".......llOd......llOd...........",
    ".......llOd......llOd...........",
    ".......hhOh......hhOh...........",
    "................................",
]


def vaca_rabo(grade, rabo, tufo):
    """Rabo = traco de 1 px (c) saindo do alto da anca, com folga do contorno; tufo (t)."""
    return remenda(grade, [(x, y, ["c"]) for x, y in rabo] + [(x, y, ["t"]) for x, y in tufo])


# parado / balanco para fora / tufo dobrado para cima
VACA_BASE = vaca_rabo(VACA_CORPO, [(3, 8), (2, 9)] + [(1, y) for y in range(10, 16)],
                      [(0, 16), (1, 16), (2, 16), (0, 17), (1, 17), (2, 17), (1, 18)])
VACA_RABO1 = vaca_rabo(VACA_CORPO, [(3, 8), (2, 9), (1, 10), (1, 11), (1, 12)] + [(0, y) for y in range(13, 16)],
                       [(0, 16), (1, 16), (0, 17), (1, 17)])
VACA_RABO2 = vaca_rabo(VACA_CORPO, [(3, 8), (2, 9), (1, 10), (1, 11), (1, 12), (1, 13)],
                       [(0, 14), (0, 15), (1, 14), (1, 15), (2, 15)])
VACA_MASTIGA = remenda(VACA_BASE, [(26, 11, [",,,,,", ",,,,.", ",ppp,"])])
VACA_ORELHA = remenda(VACA_BASE, [(22, 5, ["k,", ".k"])])
VACA = Bicho(
    "vaca",
    {"b": ("ffffff", "ffffff", "c0cbdc"), "s": ("3a4466", "262b44", "262b44"),
     "H": "e4a672", "k": "e8b796", "p": ("e8b796", "f6757a", "f6757a"), "n": "b55088",
     "c": "262b44", "t": "262b44", "u": "f6757a", "l": ("ffffff", "c0cbdc", "8b9bb4"),
     "d": "8b9bb4", "h": "3e2731", "O": "181425", "e": "181425", "z": "c0cbdc"},
    "181425", "ct", 16,
    {"base": VACA_BASE, "mastiga": VACA_MASTIGA, "rabo1": VACA_RABO1, "rabo2": VACA_RABO2,
     "orelha": VACA_ORELHA},
    ["base", "mastiga", "base", "mastiga+r", "base+r", "mastiga", "base", "rabo1",
     "rabo2", "rabo1", "base", "base+p", "mastiga", "base+r", "orelha", "base"],
)

BICHOS = [GALINHA, PORCO, VACA, OVELHA]


def pecas():
    return {b.nome: b.quadros() for b in BICHOS}


# ------------------------------------------------------------ conferencia
PAL = set(tuple(c) for c in ENDESGA32)


def confere(nome, qs):
    """So cores da Endesga 32, nada semitransparente, nenhum pixel solto, pes na ultima linha."""
    erros = []
    for i, q in enumerate(qs):
        for y in range(q.h):
            for x in range(q.w):
                c = q.px[y][x]
                if c is None:
                    continue
                if tuple(c[:3]) not in PAL or c[3] != 255:
                    erros.append("q%d (%d,%d) cor fora da paleta %s" % (i, x, y, c))
                if not any(q.get(x + dx, y + dy) is not None for dx, dy in VIZ4):
                    erros.append("q%d (%d,%d) pixel solto" % (i, x, y))
        if not any(q.px[q.h - 1][x] is not None for x in range(q.w)):
            erros.append("q%d nao pisa na ultima linha" % i)
    return erros


def distintos(qs):
    return len(set(tuple(tuple(r) for r in q.px) for q in qs))


def tira_pil(qs):
    w, h = qs[0].w, qs[0].h
    img = Image.new("RGBA", (w * len(qs), h), (0, 0, 0, 0))
    for i, q in enumerate(qs):
        for y in range(h):
            for x in range(w):
                c = q.px[y][x]
                if c is not None:
                    img.putpixel((i * w + x, y), tuple(c))
    return img


def main():
    p = pecas()
    os.makedirs(OUT_TIRAS, exist_ok=True)
    tiras = {}
    ok = True
    for nome, qs in p.items():
        erros = confere(nome, qs)
        ok = ok and not erros
        for e in erros[:10]:
            print("  ERRO", nome, e)
        print("%-8s %dx%d, %d quadros, %d desenhos diferentes" % (nome, qs[0].w, qs[0].h, len(qs), distintos(qs)))
        t = tira_pil(qs)
        t.save(os.path.join(OUT_TIRAS, nome + ".png"))
        tiras[nome] = t
        save_gif(os.path.join(OUT, "animal_%s.gif" % nome), qs, delay_cs=12, scale=8, bg=(118, 194, 246))
    # folha: cada tira com 1 px entre quadros, fundo de ceu, ampliada 6x
    larg = max(t.width + N for t in tiras.values()) + 4
    alt = sum(t.height + 3 for t in tiras.values()) + 2
    folha = Image.new("RGBA", (larg, alt), (118, 194, 246, 255))
    y = 2
    for nome, t in tiras.items():
        fw = t.width // N
        for i in range(N):
            q = t.crop((i * fw, 0, (i + 1) * fw, t.height))
            folha.alpha_composite(q, (2 + i * (fw + 1), y))
        y += t.height + 3
    folha.resize((folha.width * 6, folha.height * 6), Image.NEAREST).save(os.path.join(OUT, "animais_quadros.png"))
    if "--salvar" in sys.argv:
        for nome, t in tiras.items():
            t.save(os.path.join(ARTE, nome + ".png"))
        print("salvo em assets/sprites/arte/")
    print("ok" if ok else "COM ERROS")


if __name__ == "__main__":
    main()
