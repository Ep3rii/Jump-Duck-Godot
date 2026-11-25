"""Mini biblioteca de pixel art em Python puro (sem PIL): tela RGBA, formas, sombreado com
rampas da paleta e pontilhado Bayer, contorno seletivo e PNG."""
import math
import struct
import zlib

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


def load_png(path):
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
