"""Monta GIFs a partir dos quadros gravados por tests/gif_fundo.tscn
(%APPDATA%/Godot/app_userdata/Jump Duck/gif/<cena>/NNN.png) -> tools/arte/saida/jogo_<cena>.gif
Uso: python tools/arte/gif_jogo.py [cena ...]"""
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import load_png, _lzw  # noqa: E402

SRC = os.path.join(os.environ.get("APPDATA", ""), "Godot", "app_userdata", "Jump Duck", "gif")
OUT = os.path.join(HERE, "saida")


def monta(cena, delay_cs=5):
    pasta = os.path.join(SRC, cena)
    nomes = sorted(f for f in os.listdir(pasta) if f.endswith(".png"))
    quadros = [load_png(os.path.join(pasta, f)) for f in nomes]
    w, h = quadros[0].w, quadros[0].h
    # paleta: as 255 cores mais comuns (com 5 bits por canal); o resto vai para a mais proxima
    conta = {}
    for q in quadros:
        for row in q.px:
            for c in row:
                k = (c[0] & 0xf8, c[1] & 0xf8, c[2] & 0xf8) if c else (0, 0, 0)
                conta[k] = conta.get(k, 0) + 1
    pal = [k for k, _ in sorted(conta.items(), key=lambda kv: -kv[1])[:256]]
    idx = {k: i for i, k in enumerate(pal)}

    def perto(k):
        i = idx.get(k)
        if i is None:
            i = min(range(len(pal)), key=lambda j: (pal[j][0] - k[0]) ** 2 + (pal[j][1] - k[1]) ** 2 + (pal[j][2] - k[2]) ** 2)
            idx[k] = i
        return i
    bits = 8
    pal_out = pal + [(0, 0, 0)] * (256 - len(pal))
    out = bytearray(b"GIF89a")
    out += struct.pack("<HHBBB", w, h, 0x80 | ((bits - 1) << 4) | (bits - 1), 0, 0)
    for c in pal_out:
        out += bytes(c)
    out += b"\x21\xff\x0bNETSCAPE2.0\x03\x01\x00\x00\x00"
    for q in quadros:
        ind = [perto((c[0] & 0xf8, c[1] & 0xf8, c[2] & 0xf8) if c else (0, 0, 0)) for row in q.px for c in row]
        out += b"\x21\xf9\x04\x00" + struct.pack("<H", delay_cs) + b"\x00\x00"
        out += b"\x2c" + struct.pack("<HHHHB", 0, 0, w, h, 0)
        out += bytes([bits])
        data = _lzw(ind, bits)
        for i in range(0, len(data), 255):
            chunk = data[i:i + 255]
            out += bytes([len(chunk)]) + chunk
        out += b"\x00"
    out += b"\x3b"
    destino = os.path.join(OUT, "jogo_%s.gif" % cena)
    with open(destino, "wb") as f:
        f.write(out)
    print(cena, len(quadros), "quadros,", len(out) // 1024, "KB")


if __name__ == "__main__":
    for cena in (sys.argv[1:] or sorted(os.listdir(SRC))):
        monta(cena)
