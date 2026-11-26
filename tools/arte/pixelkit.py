"""Mini biblioteca de pixel art em Python puro (sem PIL): tela RGBA, formas, sombreado com
rampas da paleta e pontilhado Bayer, contorno seletivo e PNG."""
import hashlib
import json
import math
import os
import struct
import sys
import zlib

# ---------------------------------------------------------------- arte do jogo (1:1 e protegida)
# A arte em assets/sprites/arte/ e gravada em 1:1 (1 pixel do arquivo = 1 pixel do desenho;
# o jogo amplia sozinho), para dar para editar a mao pixel por pixel.
# Os geradores antigos trabalham ampliados 4x por dentro; para eles nao precisarem mudar,
# load_png() amplia 4x ao ler estes arquivos e Canvas.save() reduz 4x ao gravar.
# PROTECAO: tools/arte/gerados.json guarda a impressao (sha1) de cada PNG como o gerador o
# gravou. Se o arquivo foi editado a mao depois, o gerador NAO sobrescreve (avisa e pula),
# a nao ser que se rode com --forcar.
_AQUI = os.path.dirname(os.path.abspath(__file__))
_RAIZ = os.path.dirname(os.path.dirname(_AQUI))
ARTE_DIR = os.path.normcase(os.path.join(_RAIZ, "assets", "sprites", "arte"))
MANIFESTO = os.path.join(_AQUI, "gerados.json")
AMPLIADOS_4X = {"pato_parado", "pato_mergulhando", "pato_correndo", "pato_pulando", "pato_apice", "pato_caindo", "pato_dano",
                "pato_morte", "tileset_grama", "tileset_pedra", "flor", "estrela", "chave", "caixa", "feno",
                "raposa", "jacare", "gaviaozinho", "aguia"}
FORCAR = "--forcar" in sys.argv

# ---------------------------------------------------------------- 16x16 + Endesga 32 (26/11/2026)
# A arte do jogo e gravada em 16x16 por bloco (1 pixel do arquivo = 1 pixel do jogo; chefes 32x32).
# Os geradores continuam desenhando na grade de 32 (ou 4x dela) e o save() reduz pela metade com
# reduz2(), que refaz o contorno de 1 px, e depois troca cada cor pela mais proxima da Endesga 32.
# load_png() devolve esses arquivos ampliados para a grade que os geradores esperam.
SEM_REDUCAO = {"fonte"}  # a fonte ja e desenhada em pixels do jogo
# largura e altura de cada quadro NA GRADE DE 32 (para reduzir quadro a quadro); sem entrada = 1 quadro
QUADRO_32 = {
    "tileset_grama": (32, 32), "tileset_pedra": (32, 32),
    "pato_parado": 32, "pato_mergulhando": 32, "pato_correndo": 32, "pato_pulando": 32, "pato_apice": 32, "pato_caindo": 32,
    "pato_dano": 32, "pato_morte": 32, "flor": 32, "estrela": 32, "chave": 32, "caixa": 32, "feno": 32,
    "coracao": 32, "agua": 32, "bloco": 32, "pata": 32, "porta": 32, "placa": 32, "cipo": 32,
    "pedra_cai": 32, "brilho": 32, "junco": 32,
    "raposa": 46, "jacare": 64, "gaviaozinho": 46, "aguia": 62,
    "chefe_jacare": 64, "chefe_gaviao": 64,
    "saida": 40, "checkpoint": 28, "vento": 24,
    "cenario/cerca": 32, "cenario/moinho_pas": 192, "fundo/sol": 96, "fundo/tocha": 32,
}
# pecas que emendam com a vizinha (blocos, texturas que repetem): a borda do quadro conta como
# continuacao; nas outras a borda do quadro conta como vazio (o contorno fecha ali)
EMENDA = {"tileset_grama", "tileset_pedra", "agua", "bloco", "cipo", "porta", "fundo/parede",
          "fundo/coluna", "fundo/montanhas", "fundo/colinas_longe", "fundo/colinas_perto", "cenario/cerca"}
ENDESGA32 = [tuple(int(c[i:i + 2], 16) for i in (0, 2, 4)) for c in (
    "be4a2f d77643 ead4aa e4a672 b86f50 733e39 3e2731 a22633 e43b44 f77622 feae34 fee761 "
    "63c74d 3e8948 265c42 193c3e 124e89 0099db 2ce8f5 ffffff c0cbdc 8b9bb4 5a6988 3a4466 "
    "262b44 181425 ff0044 68386c b55088 f6757a e8b796 c28569").split()]
_PAL_CACHE = {}


def _linear(v):
    v = v / 255.0
    return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4


def oklab(c):
    """Cor em OKLab (luminosidade L, eixos de cor a e b): distancias aqui seguem o olho."""
    r, g, b = (_linear(v) for v in c[:3])
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3.0)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3.0)
    s_ = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3.0)
    return (0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s_,
            1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s_,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s_)


_PAL_LAB = None


def _candidatas(c):
    """Cores da paleta da mais parecida para a menos (OKLab, o tom pesa o dobro da luz: um
    verde claro vira verde, nao cinza)."""
    global _PAL_LAB
    if _PAL_LAB is None:
        _PAL_LAB = [(p, oklab(p)) for p in ENDESGA32]
    L, a, b = oklab(c)
    return sorted(_PAL_LAB, key=lambda q: (q[1][0] - L) ** 2 + 2.0 * ((q[1][1] - a) ** 2 + (q[1][2] - b) ** 2))


def na_paleta(c):
    """Cor mais proxima da Endesga 32."""
    if c is None:
        return None
    k = c[:3]
    r = _PAL_CACHE.get(k)
    if r is None:
        r = _PAL_CACHE[k] = _candidatas(k)[0][0] + (255,)
    return r


def _matiz_ok(c, cand):
    """A candidata tem o mesmo matiz da cor (cores acinzentadas so aceitam cinzas)."""
    import math
    _, a1, b1 = oklab(c)
    _, a2, b2 = oklab(cand)
    c1, c2 = math.hypot(a1, b1), math.hypot(a2, b2)
    if c1 < 0.04:
        return c2 < 0.07
    if c2 < 0.03:
        return False
    d = abs(math.atan2(b1, a1) - math.atan2(b2, a2))
    return min(d, 2 * math.pi - d) < math.radians(35)


def mapa_paleta(cores, contagem=None):
    """Mapeia as cores de UM desenho para a paleta preservando a rampa de luz e sombra: quando
    tons diferentes do mesmo material caem na mesma cor, o tom mais usado fica com ela e os
    outros vao para a vizinha da rampa (mais escura ou mais clara) DO MESMO MATIZ, para o
    volume nao sumir; sem vizinha boa, juntam."""
    cores = [c[:3] for c in cores]
    contagem = contagem or {}
    alvo = {c: na_paleta(c)[:3] for c in cores}
    grupos = {}
    for c in cores:
        grupos.setdefault(alvo[c], []).append(c)
    usados = set(alvo.values())
    for t, fontes in grupos.items():
        if len(fontes) < 2:
            continue
        Lt = oklab(t)[0]
        fica = max(fontes, key=lambda c: (contagem.get(c, 0), -abs(oklab(c)[0] - Lt)))
        Lf = oklab(fica)[0]
        for c in sorted(fontes, key=lambda c: abs(oklab(c)[0] - Lf)):
            Lc = oklab(c)[0]
            if c == fica or abs(Lc - Lf) < 0.05:
                continue
            escuro = Lc < Lf
            for p, lab in _candidatas(c)[1:10]:
                if p in usados and p != t:
                    continue
                if not ((lab[0] < Lt - 0.03) if escuro else (lab[0] > Lt + 0.03)):
                    continue
                if _matiz_ok(c, p):
                    alvo[c] = p
                    usados.add(p)
                    break
    return {c: alvo[c] + (255,) for c in cores}


def _lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def emenda(rel):
    chave = rel[:-4] if rel.endswith(".png") else rel
    return chave in EMENDA or _nome(rel) in EMENDA


def _quadro_de(rel, w, h):
    q = QUADRO_32.get(rel[:-4] if rel.endswith(".png") else rel, QUADRO_32.get(_nome(rel)))
    if q is None:
        return w, h
    if isinstance(q, int):
        return q, h
    return q


def _rel_arte(path):
    p = os.path.normcase(os.path.abspath(path))
    if p.startswith(ARTE_DIR + os.sep):
        return os.path.relpath(p, ARTE_DIR).replace(os.sep, "/")
    return None


def _nome(rel):
    return os.path.splitext(os.path.basename(rel))[0]


def _sha1(path):
    return hashlib.sha1(open(path, "rb").read()).hexdigest()


def _manifesto():
    try:
        return json.load(open(MANIFESTO, encoding="utf-8"))
    except (OSError, ValueError):
        return {}


def _grava_manifesto(m):
    with open(MANIFESTO, "w", encoding="utf-8", newline="\n") as f:
        json.dump(m, f, indent=1, sort_keys=True, ensure_ascii=False)
        f.write("\n")


def editado_a_mao(path):
    """True se o PNG da arte existe e nao e mais o que o gerador gravou."""
    rel = _rel_arte(path)
    if rel is None or not os.path.exists(path):
        return False
    return _manifesto().get(rel) != _sha1(path)

BAYER4 = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def hexc(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px = [[None] * w for _ in range(h)]
        self.part = [[None] * w for _ in range(h)]  # nome da parte de cada pixel

    def inside(self, x, y):
        return 0 <= x < self.w and 0 <= y < self.h

    def set(self, x, y, c, part=None):
        x, y = int(x), int(y)
        if self.inside(x, y):
            self.px[y][x] = c
            if part is not None:
                self.part[y][x] = part

    def get(self, x, y):
        if self.inside(x, y):
            return self.px[y][x]
        return None

    # ------------------------------------------------------------ formas (mascaras)
    def mask_ellipse(self, cx, cy, rx, ry):
        pts = []
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                dx = (x + 0.5 - cx) / rx
                dy = (y + 0.5 - cy) / ry
                if dx * dx + dy * dy <= 1.0:
                    pts.append((x, y))
        return pts

    def mask_poly(self, pts_in):
        ys = [p[1] for p in pts_in]
        out = []
        n = len(pts_in)
        for y in range(int(min(ys)), int(max(ys)) + 1):
            yc = y + 0.5
            xs = []
            for i in range(n):
                x1, y1 = pts_in[i]
                x2, y2 = pts_in[(i + 1) % n]
                if (y1 <= yc < y2) or (y2 <= yc < y1):
                    xs.append(x1 + (yc - y1) * (x2 - x1) / (y2 - y1))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                for x in range(int(math.ceil(xs[i] - 0.5)), int(math.floor(xs[i + 1] - 0.5)) + 1):
                    out.append((x, y))
        return out

    def mask_rect(self, x, y, w, h):
        return [(xx, yy) for yy in range(y, y + h) for xx in range(x, x + w)]

    def fill(self, mask, c, part=None):
        for x, y in mask:
            self.set(x, y, c, part)

    # ------------------------------------------------------------ sombreado
    def shade_sphere(self, mask, cx, cy, rx, ry, ramp, part=None, light=(-0.55, -0.65, 0.52),
                     bias=0.0, dither=True):
        """Sombreia uma forma como se fosse uma bola (normal da elipse), escolhendo a cor na
        rampa (escura -> clara) com pontilhado nas transicoes."""
        lx, ly, lz = light
        ln = math.sqrt(lx * lx + ly * ly + lz * lz)
        lx, ly, lz = lx / ln, ly / ln, lz / ln
        for x, y in mask:
            nx = (x + 0.5 - cx) / rx
            ny = (y + 0.5 - cy) / ry
            d = nx * nx + ny * ny
            nz = math.sqrt(max(0.0, 1.0 - min(d, 1.0)))
            i = nx * lx + ny * ly + nz * lz  # -1..1
            v = (i * 0.5 + 0.5) + bias
            v = max(0.0, min(0.999, v))
            k = len(ramp)
            f = v * k
            idx = int(f)
            frac = f - idx
            if dither and idx < k - 1:
                th = (BAYER4[y % 4][x % 4] + 0.5) / 16.0
                if frac > 0.5 + (th - 0.5) * 0.9 and frac > 0.62:
                    idx += 1
            self.set(x, y, ramp[min(idx, k - 1)], part)

    def shade_vertical(self, mask, y0, y1, ramp, part=None, dither=True):
        """Degrade de cima (claro) para baixo (escuro)."""
        k = len(ramp)
        for x, y in mask:
            t = (y - y0) / max(1.0, (y1 - y0))
            v = 1.0 - max(0.0, min(0.999, t))
            f = v * k
            idx = int(f)
            frac = f - idx
            if dither and idx < k - 1:
                th = (BAYER4[y % 4][x % 4] + 0.5) / 16.0
                if frac > th:
                    idx += 1
            self.set(x, y, ramp[min(idx, k - 1)], part)

    # ------------------------------------------------------------ linhas
    def line(self, x0, y0, x1, y1, c, part=None):
        x0, y0, x1, y1 = int(x0), int(y0), int(x1), int(y1)
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx = 1 if x0 < x1 else -1
        sy = 1 if y0 < y1 else -1
        err = dx + dy
        while True:
            self.set(x0, y0, c, part)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    # ------------------------------------------------------------ contorno
    def outline(self, dark, light=None, thickness=2):
        """Contorno externo. Com 'light', o lado de cima/esquerda (iluminado) fica mais claro
        (contorno seletivo)."""
        for _ in range(thickness):
            add = []
            for y in range(self.h):
                for x in range(self.w):
                    if self.px[y][x] is not None:
                        continue
                    nb = [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]
                    hit = [p for p in nb if self.inside(*p) and self.px[p[1]][p[0]] is not None
                           and self.px[p[1]][p[0]] not in ("_o",)]
                    if hit:
                        lit = light is not None and any(p == (x + 1, y) or p == (x, y + 1) for p in hit) \
                            and not any(p == (x - 1, y) or p == (x, y - 1) for p in hit)
                        add.append((x, y, light if lit else dark))
            for x, y, c in add:
                self.px[y][x] = c

    def inner_lines(self, dark, parts_pairs):
        """Linha escura onde duas partes diferentes se encostam (ex.: asa sobre o corpo)."""
        out = []
        for y in range(self.h):
            for x in range(self.w):
                p = self.part[y][x]
                if p is None:
                    continue
                for nx_, ny_ in ((x + 1, y), (x, y + 1)):
                    if not self.inside(nx_, ny_):
                        continue
                    q = self.part[ny_][nx_]
                    if q is not None and q != p and ((p, q) in parts_pairs or (q, p) in parts_pairs):
                        out.append((x, y) if p in [a for a, b in parts_pairs] else (nx_, ny_))
        for x, y in out:
            self.px[y][x] = dark

    # ------------------------------------------------------------ saida
    def blit(self, other, ox, oy, scale=1):
        for y in range(other.h):
            for x in range(other.w):
                c = other.px[y][x]
                if c is None:
                    continue
                for sy in range(scale):
                    for sx in range(scale):
                        self.set(ox + x * scale + sx, oy + y * scale + sy, c)

    def downscale(self, f):
        """Reduz por 'f' pegando a cor mais comum de cada bloco (preve o tamanho no jogo)."""
        out = Canvas(self.w // f, self.h // f)
        for y in range(out.h):
            for x in range(out.w):
                cnt = {}
                for yy in range(f):
                    for xx in range(f):
                        c = self.px[y * f + yy][x * f + xx]
                        cnt[c] = cnt.get(c, 0) + 1
                best = max(cnt.items(), key=lambda kv: kv[1])[0]
                out.px[y][x] = best
        return out

    def save(self, path):
        rel = _rel_arte(path)
        if rel is None:
            return self._write(path)
        img = self._reduz(4) if _nome(rel) in AMPLIADOS_4X else self
        if _nome(rel) not in SEM_REDUCAO:
            fw, fh = _quadro_de(rel, img.w, img.h)
            img = img.reduz2(fw, fh, emenda(rel)).paleta()
        if editado_a_mao(path) and not FORCAR:
            print("PROTEGIDO: assets/sprites/arte/%s foi editado a mao; nao sobrescrevi "
                  "(rode com --forcar para trocar pela versao do gerador)" % rel)
            return False
        img._write(path)
        m = _manifesto()
        m[rel] = _sha1(path)
        _grava_manifesto(m)
        return True

    def _reduz(self, f):
        """Desfaz a ampliacao f x f (cada bloco f x f precisa ser de uma cor so)."""
        assert self.w % f == 0 and self.h % f == 0, "tamanho nao divide por %d" % f
        out = Canvas(self.w // f, self.h // f)
        for y in range(out.h):
            for x in range(out.w):
                c = self.px[y * f][x * f]
                for yy in range(f):
                    for xx in range(f):
                        assert self.px[y * f + yy][x * f + xx] == c, \
                            "bloco %dx%d com mais de uma cor em (%d, %d)" % (f, f, x * f, y * f)
                out.px[y][x] = c
        return out

    def paleta(self):
        contagem = {}
        for row in self.px:
            for c in row:
                if c is not None:
                    contagem[c[:3]] = contagem.get(c[:3], 0) + 1
        m = mapa_paleta(list(contagem), contagem)
        out = Canvas(self.w, self.h)
        for y in range(self.h):
            for x in range(self.w):
                c = self.px[y][x]
                out.px[y][x] = None if c is None else m[c[:3]]
        return out

    def reduz2(self, fw=None, fh=None, emenda=False):
        """Reduz pela metade (grade de 32 -> 16) quadro a quadro, refazendo o contorno de 1 px:
        a silhueta vale onde metade ou mais do bloco 2x2 esta preenchido; o miolo leva a cor mais
        comum (empate: a mais escura); linhas escuras que ocupam metade do bloco ficam; detalhes
        pequenos que sumiriam (olho, narina, dente) viram 1 pixel; e a borda da silhueta nova
        recebe a cor do contorno original. A borda do quadro conta como continuacao (blocos de
        tileset emendam)."""
        fw = fw or self.w
        fh = fh or self.h
        assert self.w % fw == 0 and self.h % fh == 0 and fw % 2 == 0 and fh % 2 == 0, (self.w, self.h, fw, fh)
        out = Canvas(self.w // 2, self.h // 2)
        for fy in range(0, self.h, fh):
            for fx in range(0, self.w, fw):
                self._reduz2_quadro(out, fx, fy, fw, fh, emenda)
        return out

    def _reduz2_quadro(self, out, fx, fy, W, H, emenda=False):
        px = self.px

        def g(x, y):
            return px[fy + y][fx + x]
        w2, h2 = W // 2, H // 2
        # ja e uma ampliacao 2x (blocos 2x2 de uma cor so): so amostra, sem mudar nada
        if all(g(x, y) == g(x + 1, y) == g(x, y + 1) == g(x + 1, y + 1) for y in range(0, H, 2) for x in range(0, W, 2)):
            for y in range(h2):
                for x in range(w2):
                    out.px[fy // 2 + y][fx // 2 + x] = g(x * 2, y * 2)
            return
        # anel de contorno na grade de 32: pixel cheio com vizinho vazio DENTRO do quadro
        borda = set()
        for y in range(H):
            for x in range(W):
                if g(x, y) is None:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    fora = not (0 <= nx < W and 0 <= ny < H)
                    if (fora and not emenda) or (not fora and g(nx, ny) is None):
                        borda.add((x, y))
                        break
        res = [[None] * w2 for _ in range(h2)]
        cor_borda = [[None] * w2 for _ in range(h2)]
        for by in range(h2):
            for bx in range(w2):
                pts = [(bx * 2 + i, by * 2 + j) for j in (0, 1) for i in (0, 1)]
                cheios = [p for p in pts if g(*p) is not None]
                bs = [g(*p) for p in cheios if p in borda]
                if bs:
                    cor_borda[by][bx] = min(bs, key=_lum)
                if len(cheios) < 2:
                    continue
                miolo = [g(*p) for p in cheios if p not in borda] or bs
                conta = {}
                for c in miolo:
                    conta[c] = conta.get(c, 0) + 1
                cor = max(conta, key=lambda c: (conta[c], -_lum(c)))
                escuras = [c for c in conta if _lum(c) < 0.6 * _lum(cor) and conta[c] >= 2]
                if escuras:
                    cor = min(escuras, key=_lum)
                res[by][bx] = cor
        # detalhes pequenos (componentes de pixels que contrastam com o bloco onde cairam e que
        # nao apareceram na reducao) viram 1 pixel no centro deles
        visto = set()
        for y in range(H):
            for x in range(W):
                c = g(x, y)
                if c is None or (x, y) in borda or (x, y) in visto:
                    continue
                r = res[y // 2][x // 2]
                if r is None or c == r or abs(_lum(c) - _lum(r)) < 90:
                    continue
                comp, pilha = [], [(x, y)]
                visto.add((x, y))
                while pilha:
                    cx, cy = pilha.pop()
                    comp.append((cx, cy))
                    for dx in (-1, 0, 1):
                        for dy in (-1, 0, 1):
                            nx, ny = cx + dx, cy + dy
                            if (0 <= nx < W and 0 <= ny < H and (nx, ny) not in visto
                                    and g(nx, ny) == c and (nx, ny) not in borda):
                                visto.add((nx, ny))
                                pilha.append((nx, ny))
                if len(comp) > 12:
                    continue
                if any(res[py // 2][px_ // 2] == c for px_, py in comp):
                    continue
                mx = sum(p[0] for p in comp) // len(comp) // 2
                my = sum(p[1] for p in comp) // len(comp) // 2
                if res[my][mx] is not None:
                    res[my][mx] = c
        # contorno novo de 1 px: pixel cheio com vizinho vazio (dentro do quadro) leva a cor do
        # contorno original mais perto
        for by in range(h2):
            for bx in range(w2):
                if res[by][bx] is None:
                    continue
                aberto = False
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = bx + dx, by + dy
                    if not (0 <= nx < w2 and 0 <= ny < h2):
                        aberto = aberto or not emenda
                    elif res[ny][nx] is None:
                        aberto = True
                if not aberto:
                    continue
                cb = None
                for raio in (0, 1, 2):
                    cands = [cor_borda[yy][xx] for yy in range(by - raio, by + raio + 1)
                             for xx in range(bx - raio, bx + raio + 1)
                             if 0 <= xx < w2 and 0 <= yy < h2 and cor_borda[yy][xx] is not None]
                    if cands:
                        cb = min(cands, key=_lum)
                        break
                if cb is not None:
                    res[by][bx] = cb
        for y in range(h2):
            for x in range(w2):
                out.px[fy // 2 + y][fx // 2 + x] = res[y][x]

    def _write(self, path):
        raw = bytearray()
        for row in self.px:
            raw.append(0)
            for c in row:
                if c is None:
                    raw += b"\x00\x00\x00\x00"
                else:
                    raw += bytes(c[:4]) if len(c) == 4 else bytes(c) + b"\xff"
        def chunk(t, d):
            return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
        png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", self.w, self.h, 8, 6, 0, 0, 0))
        png += chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
        with open(path, "wb") as f:
            f.write(png)


def load_png(path, ampliar=True):
    """Le um PNG de 8 bits (RGB ou RGBA, sem entrelacamento) e devolve uma Canvas."""
    data = open(path, "rb").read()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", "nao e PNG"
    pos = 8
    idat = b""
    w = h = 0
    ctype = 6
    palette = None
    trns = None
    while pos < len(data):
        ln = struct.unpack(">I", data[pos:pos + 4])[0]
        typ = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + ln]
        if typ == b"IHDR":
            w, h, depth, ctype, _, _, inter = struct.unpack(">IIBBBBB", body)
            assert depth == 8 and inter == 0, "so PNG de 8 bits sem entrelacamento"
        elif typ == b"PLTE":
            palette = [tuple(body[i:i + 3]) for i in range(0, len(body), 3)]
        elif typ == b"tRNS":
            trns = body
        elif typ == b"IDAT":
            idat += body
        pos += 12 + ln
    bpp = {6: 4, 2: 3, 3: 1, 0: 1, 4: 2}[ctype]
    raw = zlib.decompress(idat)
    stride = w * bpp
    rows = []
    prev = bytearray(stride)
    i = 0
    for _ in range(h):
        f = raw[i]
        line = bytearray(raw[i + 1:i + 1 + stride])
        i += 1 + stride
        for x in range(stride):
            a = line[x - bpp] if x >= bpp else 0
            b = prev[x]
            c = prev[x - bpp] if x >= bpp else 0
            if f == 1:
                line[x] = (line[x] + a) & 255
            elif f == 2:
                line[x] = (line[x] + b) & 255
            elif f == 3:
                line[x] = (line[x] + ((a + b) >> 1)) & 255
            elif f == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                line[x] = (line[x] + pr) & 255
        rows.append(line)
        prev = line
    cv = Canvas(w, h)
    for y in range(h):
        for x in range(w):
            if ctype == 6:
                r, g, b, al = rows[y][x * 4:x * 4 + 4]
            elif ctype == 2:
                r, g, b = rows[y][x * 3:x * 3 + 3]
                al = 255
            elif ctype == 3:
                idx = rows[y][x]
                r, g, b = palette[idx]
                al = trns[idx] if trns and idx < len(trns) else 255
            elif ctype == 4:
                r = g = b = rows[y][x * 2]
                al = rows[y][x * 2 + 1]
            else:
                r = g = b = rows[y][x]
                al = 255
            if al > 127:
                cv.px[y][x] = (r, g, b, 255)
    rel = _rel_arte(path)
    if rel is not None and ampliar and _nome(rel) not in SEM_REDUCAO:
        # arquivo em 16x16: devolve na grade que os geradores usam (32, ou 4x dela)
        f = 8 if _nome(rel) in AMPLIADOS_4X else 2
        big = Canvas(w * f, h * f)
        big.blit(cv, 0, 0, f)
        return big
    return cv


def save_gif(path, frames, delay_cs=10, scale=1, bg=(255, 255, 255)):
    """GIF animado (laco infinito) a partir de Canvases do mesmo tamanho. delay_cs = centesimos
    de segundo por quadro. Transparente vira 'bg'. Ate 255 cores."""
    w, h = frames[0].w * scale, frames[0].h * scale
    pal = [bg]
    idx_frames = []
    for fr in frames:
        idx = []
        for y in range(h):
            for x in range(w):
                c = fr.px[y // scale][x // scale]
                rgb = bg if c is None else tuple(c[:3])
                if rgb not in pal:
                    pal.append(rgb)
                idx.append(pal.index(rgb))
        idx_frames.append(idx)
    bits = max(2, (len(pal) - 1).bit_length())
    size = 1 << bits
    pal += [(0, 0, 0)] * (size - len(pal))
    out = bytearray(b"GIF89a")
    out += struct.pack("<HHBBB", w, h, 0x80 | ((bits - 1) << 4) | (bits - 1), 0, 0)
    for c in pal:
        out += bytes(c)
    out += b"\x21\xff\x0bNETSCAPE2.0\x03\x01\x00\x00\x00"
    for idx in idx_frames:
        out += b"\x21\xf9\x04\x00" + struct.pack("<H", delay_cs) + b"\x00\x00"
        out += b"\x2c" + struct.pack("<HHHHB", 0, 0, w, h, 0)
        out += bytes([bits])
        data = _lzw(idx, bits)
        for i in range(0, len(data), 255):
            chunk = data[i:i + 255]
            out += bytes([len(chunk)]) + chunk
        out += b"\x00"
    out += b"\x3b"
    with open(path, "wb") as f:
        f.write(out)


def _lzw(indices, min_bits):
    clear = 1 << min_bits
    eoi = clear + 1
    out = bytearray()
    buf = 0
    nbits = 0
    code_size = min_bits + 1

    def emit(code):
        nonlocal buf, nbits
        buf |= code << nbits
        nbits += code_size
        while nbits >= 8:
            out.append(buf & 255)
            buf >>= 8
            nbits -= 8

    table = {(i,): i for i in range(clear)}
    nxt = eoi + 1
    emit(clear)
    w = ()
    for k in indices:
        wk = w + (k,)
        if wk in table:
            w = wk
            continue
        emit(table[w])
        if nxt < 4096:
            table[wk] = nxt
            nxt += 1
            if nxt - 1 == (1 << code_size) and code_size < 12:
                code_size += 1
        else:
            emit(clear)
            table = {(i,): i for i in range(clear)}
            nxt = eoi + 1
            code_size = min_bits + 1
        w = (k,)
    if w:
        emit(table[w])
    emit(eoi)
    if nbits:
        out.append(buf & 255)
    return bytes(out)
