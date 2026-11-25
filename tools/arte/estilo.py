"""Base de estilo do Jump Duck: pixel art plana "crocante", tirada do pato e do tileset de grama
aprovados. TODO sprite novo (cenario, fundos, inimigos, itens, chefes) deve ser desenhado com
este arquivo, para sair igual aos outros.

Regras (ver "Categoria de arte" no ROTEIRO_FASES.md):
  - GRADE: 2 pixels do desenho = 1 pixel do jogo (o pato tem 32 de altura na grade, 16 no jogo).
    Blocos e bichos sao gravados ampliados 4x (128x128; chefes 256x256). Cenario grande e fundos
    sao gravados direto na grade (sem ampliar), para nao pesar: a densidade de pixel e a mesma.
  - CONTORNO: 1 pixel, continuo, so na borda da silhueta, na cor escura do proprio material
    (nunca preto). Aqui o contorno e o anel de fora da propria forma (Desenho.contorno).
  - COR: chapada, com no maximo 2 tons a mais (1 de luz, 1 de sombra). Sem degrade, sem
    pontilhado, sem suavizacao.
  - LUZ: vem de cima e da ESQUERDA (o sol fica a esquerda no ceu). Tom claro em cima/esquerda,
    tom de sombra embaixo/direita. Sombra projetada cai para baixo e para a direita.
  - ESCALA: o pato e pequeno e o cenario e grande. Medidas em "patos" (1 pato = 32 px da grade):
    cerca 1,5 | arbusto 1,5 | arvore 7 | celeiro 6,5 | moinho 9 (12 com as pas) | torre 20+.
  - DISTANCIA (fundos): quanto mais longe, mais claro e azulado, sem contorno e com menos
    detalhe; so o plano do jogo usa as cores vivas inteiras.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas, hexc  # noqa: E402

PATO = 32  # altura do pato na grade (a regua de tudo)

# ------------------------------------------------------------------ paleta (a do original)
P = {
    # pato
    "branco": hexc("ffffff"), "branco_sombra": hexc("e2e2e2"), "contorno_cinza": hexc("636363"),
    "amarelo": hexc("ffff00"), "amarelo_sombra": hexc("fff200"), "amarelo_escuro": hexc("e8d600"),
    # grama e folhas
    "folha_luz": hexc("31dc31"), "folha": hexc("2ecf2e"), "folha_sombra": hexc("28b228"),
    "folha_escura": hexc("2ba024"), "contorno_verde": hexc("1d6b22"),
    # terra
    "terra": hexc("e49e42"), "terra_sombra": hexc("cc8d3d"), "terra_escura": hexc("b98035"),
    "terra_base": hexc("99692c"),
    # madeira (o tronco e a ponte do tileset)
    "madeira_luz": hexc("c88448"), "madeira": hexc("a86834"), "madeira_sombra": hexc("7a4822"),
    "contorno_madeira": hexc("4a2a14"),
    # flor do tileset
    "petala": hexc("fefefe"), "miolo": hexc("f28b57"),
    # tinta (celeiro, telhados, cogumelo)
    "vermelho_luz": hexc("f25f4c"), "vermelho": hexc("e0453a"), "vermelho_sombra": hexc("bd342e"),
    "contorno_vermelho": hexc("7a1f1f"),
    # parede clara (moinho)
    "creme_luz": hexc("fff6dc"), "creme": hexc("f5e4b8"), "creme_sombra": hexc("dcc48c"),
    "contorno_creme": hexc("8a6e3c"),
    # pedra (torre de perto, pedras)
    "pedra_luz": hexc("d5d9e6"), "pedra": hexc("b4bacd"), "pedra_sombra": hexc("8f96ae"),
    "contorno_pedra": hexc("555b73"),
    # vidro / janela
    "janela": hexc("3d4a6b"), "janela_luz": hexc("ffe76a"),
    # ceu de dia
    "nuvem": hexc("ffffff"), "nuvem_sombra": hexc("d3ebfb"),
}


def dist(cor, k, alvo=(196, 226, 250)):
    """Cor vista de longe: mistura com o azul claro do ar (k = 0 perto ... 1 some no ceu)."""
    return tuple(int(round(cor[i] + (alvo[i] - cor[i]) * k)) for i in range(3)) + (255,)


class Desenho:
    """Tela com 'partes' (materiais): cada forma desenhada guarda de que parte e, para o
    contorno e as sombras saberem a cor certa."""

    def __init__(self, w, h):
        self.w, self.h = w, h
        self.cv = Canvas(w, h)

    # ---------------------------------------------------------------- formas
    def _fill(self, mask, cor, parte, so=None):
        cv = self.cv
        for x, y in mask:
            if 0 <= x < self.w and 0 <= y < self.h:
                if so is not None and cv.part[y][x] not in so:
                    continue
                cv.px[y][x] = cor
                if parte is not None:
                    cv.part[y][x] = parte

    def rect(self, x, y, w, h, cor, parte=None, so=None):
        self._fill(self.cv.mask_rect(int(x), int(y), int(w), int(h)), cor, parte, so)

    def elipse(self, cx, cy, rx, ry, cor, parte=None, so=None):
        self._fill(self.cv.mask_ellipse(cx, cy, rx, ry), cor, parte, so)

    def poli(self, pts, cor, parte=None, so=None):
        self._fill(self.cv.mask_poly(pts), cor, parte, so)

    def linha(self, x0, y0, x1, y1, cor, so=None, grossura=1):
        tmp = Canvas(self.w, self.h)
        tmp.line(x0, y0, x1, y1, (0, 0, 0, 255))
        mask = []
        for y in range(self.h):
            for x in range(self.w):
                if tmp.px[y][x] is not None:
                    for dy in range(grossura):
                        for dx in range(grossura):
                            mask.append((x + dx, y + dy))
        self._fill(mask, cor, None, so)

    def apaga(self, mask):
        for x, y in mask:
            if 0 <= x < self.w and 0 <= y < self.h:
                self.cv.px[y][x] = None
                self.cv.part[y][x] = None

    def parte(self, nome):
        return [(x, y) for y in range(self.h) for x in range(self.w) if self.cv.part[y][x] == nome]

    # ---------------------------------------------------------------- luz e sombra
    def sombra(self, parte, cor, dx=4, dy=4):
        """Tom de sombra na borda de baixo/direita da parte (luz de cima/esquerda): pinta os
        pixels da parte que ficam a menos de (dx, dy) da borda de baixo ou da direita."""
        cv = self.cv
        pts = []
        for x, y in self.parte(parte):
            fora_dir = dx > 0 and not self._mesma(x + dx, y, parte)
            fora_baixo = dy > 0 and not self._mesma(x, y + dy, parte)
            if fora_dir or fora_baixo:
                pts.append((x, y))
        for x, y in pts:
            cv.px[y][x] = cor

    def luz(self, parte, cor, dx=4, dy=4):
        """Tom de luz na borda de cima/esquerda da parte."""
        cv = self.cv
        pts = []
        for x, y in self.parte(parte):
            fora_esq = dx > 0 and not self._mesma(x - dx, y, parte)
            fora_cima = dy > 0 and not self._mesma(x, y - dy, parte)
            if fora_esq or fora_cima:
                pts.append((x, y))
        for x, y in pts:
            cv.px[y][x] = cor

    def _mesma(self, x, y, parte):
        return 0 <= x < self.w and 0 <= y < self.h and self.cv.part[y][x] == parte

    # ---------------------------------------------------------------- contorno
    def contorno(self, escuros, juntas=()):
        """Contorno de 1 px: o anel de fora da silhueta vira a cor escura da parte daquele
        pixel (escuros = {parte: cor}). 'juntas' = pares (parte_de_cima, parte_de_baixo) que
        ganham linha entre si, na cor escura da primeira."""
        cv = self.cv

        def cheio(x, y):
            return 0 <= x < self.w and 0 <= y < self.h and cv.px[y][x] is not None
        borda = []
        for y in range(self.h):
            for x in range(self.w):
                if cv.px[y][x] is None:
                    continue
                if not (cheio(x - 1, y) and cheio(x + 1, y) and cheio(x, y - 1) and cheio(x, y + 1)):
                    borda.append((x, y))
                    continue
                p = cv.part[y][x]
                for a, b in juntas:
                    if p != a:
                        continue
                    if any(cv.part[y + dy][x + dx] == b for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                        borda.append((x, y))
                        break
        for x, y in borda:
            c = escuros.get(cv.part[y][x])
            if c is not None:
                cv.px[y][x] = c

    # ---------------------------------------------------------------- pecas prontas
    def flor(self, x, y):
        """Florzinha do tileset (6x6): petalas brancas, miolo laranja."""
        rows = ["..WW..", ".WWWW.", "WWOOWW", "WWOOWW", ".WWWW.", "..WW.."]
        for j, r in enumerate(rows):
            for i, ch in enumerate(r):
                if ch != "." and 0 <= x + i < self.w and 0 <= y + j < self.h:
                    self.cv.px[y + j][x + i] = P["petala"] if ch == "W" else P["miolo"]

    def salvar(self, caminho, escala=1):
        if escala == 1:
            self.cv.save(caminho)
            return
        big = Canvas(self.w * escala, self.h * escala)
        big.blit(self.cv, 0, 0, escala)
        big.save(caminho)


def conferir(cv):
    """Erros de estilo: pixel solto (sem vizinho nenhum) e meio-transparente. Devolve a lista."""
    probs = []
    for y in range(cv.h):
        for x in range(cv.w):
            c = cv.px[y][x]
            if c is None:
                continue
            if len(c) == 4 and c[3] != 255:
                probs.append(("alfa", x, y))
            viz = 0
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    if (dx or dy) and 0 <= x + dx < cv.w and 0 <= y + dy < cv.h and cv.px[y + dy][x + dx] is not None:
                        viz += 1
            if viz == 0:
                probs.append(("solto", x, y))
    return probs
