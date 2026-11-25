"""Gera as animacoes do pato na categoria "plana crocante" a partir dos sprites originais
(assets/sprites/spr_player*.png, quadros de 32x32 com origem 16,23):
  1. dobra cada quadro (grade 32 -> 64 px de "meio pixel");
  2. tira o contorno de fora (pixels de contorno que encostam no vazio, inclusive na diagonal)
     e desenha um contorno novo de 1 px em volta do miolo, seguindo so as bordas;
  3. arredonda os degraus de 2 px das curvas (a ponta da cauda fica viva);
  4. encaixa todos os quadros no mesmo ponto do pato parado aprovado (sem tremer) e amplia 4x.
Uso: python tools/arte/pato.py correndo   (gera a tira em assets/sprites/arte/ so com --salvar;
     sem isso, so as previas em tools/arte/saida/)."""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelkit import Canvas, load_png, save_gif  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
SPR = os.path.join(ROOT, "assets", "sprites")
OUT = os.path.join(HERE, "saida")
ARTE = os.path.join(SPR, "arte")
os.makedirs(OUT, exist_ok=True)

OUTLINE = (99, 99, 99, 255)

# animacao -> (sprite original, quadros, fps no jogo)
ANIMS = {
    "parado": ("spr_playerAnima", 3, 3.0),
    "correndo": ("spr_playerCorrendo", 4, 10.0),
    "pulando": ("spr_playerPulando", 2, 10.0),
    "dano": ("spr_playerDano", 4, 24.0),
    "morte": ("spr_playerMorte", 4, 24.0),
}


def frame(sheet, i):
    c = Canvas(32, 32)
    for y in range(32):
        for x in range(32):
            c.px[y][x] = sheet.px[y][i * 32 + x]
    return c


def smooth_edges(g, W, H):
    """Arredonda cantos de fora dos degraus de 2 px e preenche os dentes de dentro (so na
    borda, so no corpo branco/cinza-claro). A ponta da cauda (canto de cima/esquerda, na parte
    de tras do pato) fica viva."""
    WHITE = {(255, 255, 255, 255), (226, 226, 226, 255)}

    def full(x, y):
        return 0 <= x < W and 0 <= y < H and g[y][x] is not None
    out = [r[:] for r in g]
    for y in range(H):
        for x in range(W):
            for sx, sy in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
                if full(x, y):
                    if (not full(x + sx, y) and not full(x, y + sy) and not full(x + sx, y + sy)
                            and full(x - sx, y) and full(x, y - sy) and full(x - sx, y - sy)
                            and full(x - 2 * sx, y) and full(x, y - 2 * sy)
                            and g[y][x] in WHITE
                            and not (sx < 0 and sy < 0 and x < 24)):
                        out[y][x] = None
                else:
                    if (full(x + sx, y) and full(x, y + sy) and full(x + sx, y + sy)
                            and not full(x - sx, y) and not full(x, y - sy)
                            and g[y][x + sx] in WHITE and g[y + sy][x] in WHITE):
                        out[y][x] = g[y][x + sx]
    return out


def rebuild(fr):
    """Quadro original 32x32 -> grade 64x64 com contorno novo de 1 px (sem recortar)."""
    w = h = 32

    def empty(x, y):
        return not (0 <= x < w and 0 <= y < h) or fr.px[y][x] is None

    W, H = 64, 64
    inner = [[None] * W for _ in range(H)]
    for y in range(h):
        for x in range(w):
            c = fr.px[y][x]
            if c is None:
                continue
            outer = c == OUTLINE and any(empty(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1))
            if not outer:
                for dy in (0, 1):
                    for dx in (0, 1):
                        inner[y * 2 + dy][x * 2 + dx] = c
    inner = smooth_edges(inner, W, H)
    out = [r[:] for r in inner]
    for y in range(H):
        for x in range(W):
            if inner[y][x] is None:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and inner[ny][nx] is not None:
                        out[y][x] = OUTLINE
                        break
    return out


def bbox(g):
    ys = [y for y in range(64) if any(g[y])]
    xs = [x for x in range(64) if any(g[y][x] for y in range(64))]
    return min(xs), min(ys), max(xs), max(ys)


def registration():
    """Deslocamento que leva a grade 64 do quadro 0 do pato parado ao lugar aprovado na grade
    de 32 (centralizado, contorno de baixo na ultima linha)."""
    idle = rebuild(frame(load_png(os.path.join(SPR, "spr_playerAnima.png")), 0))
    x0, y0, x1, y1 = bbox(idle)
    ox = (32 - (x1 - x0 + 1)) // 2
    oy = 31 - (y1 - y0)
    return ox - x0, oy - y0


def to_grid32(g, dx, dy):
    cv = Canvas(32, 32)
    for y in range(64):
        for x in range(64):
            if g[y][x] is not None:
                cv.set(x + dx, y + dy, g[y][x])
    return cv


def upscale(src, f):
    out = Canvas(src.w * f, src.h * f)
    out.blit(src, 0, 0, f)
    return out


def build(anim):
    name, n, fps = ANIMS[anim]
    sheet = load_png(os.path.join(SPR, name + ".png"))
    dx, dy = registration()
    frames = [to_grid32(rebuild(frame(sheet, i)), dx, dy) for i in range(n)]
    return frames, fps


def main():
    anim = sys.argv[1] if len(sys.argv) > 1 else "correndo"
    frames, fps = build(anim)
    big = [upscale(f, 4) for f in frames]
    strip = Canvas(128 * len(big), 128)
    for i, b in enumerate(big):
        strip.blit(b, i * 128, 0)
    strip.save(os.path.join(OUT, "pato_%s.png" % anim))
    prev = Canvas(strip.w * 2 + 16 * (len(big) - 1), 256)
    for i, b in enumerate(big):
        prev.blit(b, i * (256 + 16), 0, 2)
    prev.save(os.path.join(OUT, "pato_%s_quadros_2x.png" % anim))
    save_gif(os.path.join(OUT, "pato_%s.gif" % anim), big, delay_cs=int(round(100 / fps)), scale=2,
             bg=(191, 228, 250))
    if "--salvar" in sys.argv:
        strip.save(os.path.join(ARTE, "pato_%s.png" % anim))
        print("salvo em assets/sprites/arte/pato_%s.png" % anim)
    print("ok", anim, len(frames), "quadros a", fps, "fps")


if __name__ == "__main__":
    main()


# ------------------------------------------------------------ corrida redesenhada (8 quadros)
YELLOW = (255, 255, 0, 255)
YELLOW_DARK = (255, 242, 0, 255)
YELLOW_BACK = (232, 214, 0, 255)  # pe de tras um pouco mais escuro (profundidade)

# por quadro: (dx_frente, ergue_frente, dx_tras, ergue_tras, balanco_do_corpo)
RUN_CYCLE = [
    (4, 0, -4, 0, 0),    # contato: pe da frente na frente, o de tras atras
    (2, 0, -3, 2, 0),
    (0, 0, -1, 3, -1),   # passagem: corpo sobe
    (-2, 0, 2, 2, -1),
    (-4, 0, 4, 0, 0),    # contato trocado
    (-3, 2, 2, 0, 0),
    (-1, 3, 0, 0, -1),
    (2, 2, -2, 0, -1),
]
HIP_X = 13
LEG_TOP = 25  # primeira linha abaixo da barriga


def idle_body():
    """Corpo e cabeca do pato parado aprovado (grade 32), sem os pes."""
    dx, dy = registration()
    g = to_grid32(rebuild(frame(load_png(os.path.join(SPR, "spr_playerAnima.png")), 0)), dx, dy)
    body = Canvas(32, 32)
    for y in range(LEG_TOP):
        for x in range(32):
            body.px[y][x] = g.px[y][x]
    return body


def foot_pixels(dx, lift, bob):
    """Perna curta e grossa (3 px) do quadril ate o pe; pe de 6x3 com o dedo para a frente
    (pes gordinhos, como no original). Erguido, o pe fica colado na barriga."""
    hx = HIP_X + dx
    bottom = 30 - lift            # ultima linha do miolo do pe
    top = LEG_TOP + bob
    px = set()
    for y in range(top, bottom - 2):
        for x in range(hx, hx + 3):
            px.add((x, y))
    for y in range(bottom - 2, bottom + 1):
        for x in range(hx - 1, hx + 5):
            px.add((x, y))
    return px, bottom


def run_frame(body, cyc):
    dxf, lf, dxb, lb, bob = cyc
    cv = Canvas(32, 32)
    # corpo (com o balanco)
    for y in range(32):
        for x in range(32):
            c = body.px[y][x]
            if c is not None:
                cv.set(x, y + bob, c)
    body_px = {(x, y) for y in range(32) for x in range(32) if cv.px[y][x] is not None}
    feet_order = [(dxb, lb, YELLOW_BACK, YELLOW_BACK), (dxf, lf, YELLOW, YELLOW_DARK)]
    drawn_feet = set()
    for dx, lift, col, col_shade in feet_order:
        px, bottom = foot_pixels(dx, lift, bob)
        px -= body_px
        ring = set()
        for (x, y) in px:
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if (nx, ny) not in px and (nx, ny) not in body_px:
                    ring.add((nx, ny))
        for (x, y) in ring:
            if 0 <= x < 32 and 0 <= y < 32:
                cv.set(x, y, OUTLINE)
        for (x, y) in px:
            # sombra: perna e parte de tras do pe no tom escuro
            shade = col_shade if (y < bottom - 2 or x <= HIP_X + dx) else col
            cv.set(x, y, shade)
        drawn_feet |= px
    # contorno de baixo da barriga onde nao ha perna
    for (x, y) in list(body_px):
        c = cv.px[y][x]
        if c is not None and c != OUTLINE and (y + 1 < 32) and cv.px[y + 1][x] is None:
            cv.set(x, y + 1, OUTLINE)
    return cv


def look_forward(body):
    """Correndo ele olha para a frente (como na corrida original): fica so o olho perto do bico;
    o pontinho de tras vira branco."""
    b = Canvas(32, 32)
    for y in range(32):
        for x in range(32):
            b.px[y][x] = body.px[y][x]
    eyes = []
    for y in range(4, 12):
        for x in range(12, 24):
            if body.px[y][x] == OUTLINE and all(body.px[y + dy][x + dx] is not None
                                                 for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                eyes.append((x, y))
    if eyes:
        cut = (min(x for x, _ in eyes) + max(x for x, _ in eyes)) / 2.0
        for x, y in eyes:
            if x < cut:
                b.px[y][x] = (255, 255, 255, 255)
    return b


def build_run8():
    body = look_forward(idle_body())
    return [run_frame(body, c) for c in RUN_CYCLE]


def main_run8():
    frames = [upscale(f, 4) for f in build_run8()]
    strip = Canvas(128 * len(frames), 128)
    for i, b in enumerate(frames):
        strip.blit(b, i * 128, 0)
    strip.save(os.path.join(OUT, "pato_correndo8.png"))
    prev = Canvas(len(frames) * (256 + 8), 256)
    for i, b in enumerate(frames):
        prev.blit(b, i * (256 + 8), 0, 2)
    prev.save(os.path.join(OUT, "pato_correndo8_quadros_2x.png"))
    for nome, fps in (("lenta", 12), ("media", 16), ("rapida", 20)):
        save_gif(os.path.join(OUT, "pato_correndo8_%s.gif" % nome), frames,
                 delay_cs=int(round(100 / fps)), scale=2, bg=(191, 228, 250))
    if "--salvar" in sys.argv:
        strip.save(os.path.join(ARTE, "pato_correndo.png"))
        print("salvo em assets/sprites/arte/pato_correndo.png")
    print("ok correndo8")


# ------------------------------------------------------------ pulo e queda
# subindo: perna de tras esticada para tras/baixo, pe da frente encolhendo (2 quadros)
JUMP_CYCLE = [
    (3, 3, -4, 0, 0),
    (3, 4, -5, 1, 0),
]
# caindo: pes "pedalando" no ar, um de cada vez (4 quadros)
FALL_CYCLE = [
    (2, 0, -2, 0, 0),
    (3, 0, -2, 2, 0),
    (1, 1, -1, 1, 0),
    (2, 2, -3, 0, 0),
]


def build_cycle(cycle):
    body = look_forward(idle_body())
    return [run_frame(body, c) for c in cycle]


def save_strip(frames, name, salvar):
    big = [upscale(f, 4) for f in frames]
    strip = Canvas(128 * len(big), 128)
    for i, b in enumerate(big):
        strip.blit(b, i * 128, 0)
    strip.save(os.path.join(OUT, name + ".png"))
    if salvar:
        strip.save(os.path.join(ARTE, name + ".png"))
        print("salvo em assets/sprites/arte/%s.png" % name)
    return big


def main_jump_fall():
    salvar = "--salvar" in sys.argv
    jump = save_strip(build_cycle(JUMP_CYCLE), "pato_pulando", salvar)
    fall = save_strip(build_cycle(FALL_CYCLE), "pato_caindo", salvar)
    idle = upscale(build("parado")[0][0], 4)
    # quadros lado a lado (2x) com um espaco entre subindo e caindo
    allf = jump + [None] + fall
    prev = Canvas(len(allf) * (256 + 8), 256)
    for i, b in enumerate(allf):
        if b is not None:
            prev.blit(b, i * (256 + 8), 0, 2)
    prev.save(os.path.join(OUT, "pato_pulo_quadros_2x.png"))
    # GIF de um pulo inteiro: sobe (pulando), cai (caindo), pousa (parado); 60 fps simulados
    H = 128 + 96
    seq = []
    vy, y = -4.0 * 8, 0.0  # em pixels do desenho (8 por pixel do jogo)
    t = 0
    while True:
        y += vy
        vy += 0.25 * 8
        landed = y >= 0
        if landed:
            y = 0
        if vy < 0:
            img = jump[(t // 8) % len(jump)]   # 8 fps
        else:
            img = fall[(t // 5) % len(fall)]   # 12 fps
        fr = Canvas(128, H)
        fr.blit(idle if landed else img, 0, int(H - 128 + y))
        seq.append(fr)
        t += 1
        if landed:
            break
    for _ in range(20):
        fr = Canvas(128, H)
        fr.blit(idle, 0, H - 128)
        seq.append(fr)
    # GIF a 50 fps (2 cs por quadro) e 1 quadro de jogo a cada 1
    save_gif(os.path.join(OUT, "pato_pulo.gif"), seq, delay_cs=2, scale=1, bg=(191, 228, 250))
    print("ok pulo/queda")


def fill_holes(cv):
    """Fecha buracos transparentes de 1 px cercados nos 4 lados (viram contorno)."""
    holes = []
    for y in range(1, 31):
        for x in range(1, 31):
            if cv.px[y][x] is None and all(cv.px[y + dy][x + dx] is not None
                                           for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                holes.append((x, y))
    for x, y in holes:
        cv.px[y][x] = OUTLINE
    return cv


def outline_problems(cv):
    """Conta buracos de 1 px cercados e manchas 2x2 de contorno (excesso de contorno)."""
    holes = sum(1 for y in range(1, 31) for x in range(1, 31)
                if cv.px[y][x] is None and all(cv.px[y + dy][x + dx] is not None
                                               for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))))
    blobs = sum(1 for y in range(31) for x in range(31)
                if all(cv.px[y + dy][x + dx] == OUTLINE for dx in (0, 1) for dy in (0, 1)))
    return holes, blobs


FEET_COLORS = {YELLOW, YELLOW_DARK, YELLOW_BACK, (255, 242, 0, 255)}


def clean_feet_outline(cv):
    """Limpa o contorno na regiao dos pes:
    - contorno solto (sem encostar em nenhum pixel colorido) sai;
    - entre dois pes, qualquer sequencia de 2-3 pixels de contorno/vazio vira UMA linha de
      contorno (o resto e preenchido com a cor de cada pe)."""
    top = LEG_TOP - 2
    changed = True
    while changed:
        changed = False
        for y in range(top, 32):
            for x in range(32):
                if cv.px[y][x] != OUTLINE:
                    continue
                nb = [cv.px[y + dy][x + dx] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                      if 0 <= x + dx < 32 and 0 <= y + dy < 32]
                if not any(c is not None and c != OUTLINE for c in nb):
                    cv.px[y][x] = None
                    changed = True
    for y in range(top, 32):
        x = 0
        while x < 32:
            a = cv.px[y][x]
            if a in FEET_COLORS:
                j = x + 1
                while j < 32 and (cv.px[y][j] is None or cv.px[y][j] == OUTLINE):
                    j += 1
                gap = j - x - 1
                if j < 32 and cv.px[y][j] in FEET_COLORS and 2 <= gap <= 3:
                    b = cv.px[y][j]
                    mid = x + 1 + gap // 2
                    for k in range(x + 1, j):
                        cv.px[y][k] = a if k < mid else (OUTLINE if k == mid else b)
                x = j
            else:
                x += 1
    return cv


def build_cycle(cycle):  # noqa: F811
    body = look_forward(idle_body())
    return [clean_feet_outline(run_frame(body, c)) for c in cycle]


def build_run8():  # noqa: F811
    return build_cycle(RUN_CYCLE)


WHITE_SET = {(255, 255, 255, 255), (226, 226, 226, 255)}


def thin_blocks(cv):
    """Desfaz quadradinhos 2x2 de contorno (fora o olho, que e cercado de branco): um pixel do
    bloco que encosta num pe vira a cor desse pe; senao, o que encosta no corpo vira branco."""
    for _ in range(20):
        found = False
        for y in range(LEG_TOP - 3, 31):  # so na regiao dos pes (o olho fica intacto)
            for x in range(31):
                block = [(x, y), (x + 1, y), (x, y + 1), (x + 1, y + 1)]
                if not all(cv.px[by][bx] == OUTLINE for bx, by in block):
                    continue
                ring = [cv.px[y + dy][x + dx] for dx in (-1, 0, 1, 2) for dy in (-1, 0, 1, 2)
                        if (dx in (-1, 2) or dy in (-1, 2)) and 0 <= x + dx < 32 and 0 <= y + dy < 32]
                if all(c in WHITE_SET for c in ring):
                    continue  # e o olho
                best = None
                for pref in (FEET_COLORS, WHITE_SET):
                    for bx, by in block:
                        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                            nx, ny = bx + dx, by + dy
                            if (nx, ny) in block or not (0 <= nx < 32 and 0 <= ny < 32):
                                continue
                            if cv.px[ny][nx] in pref:
                                best = (bx, by, cv.px[ny][nx])
                                break
                        if best:
                            break
                    if best:
                        break
                if best:
                    cv.px[best[1]][best[0]] = best[2]
                    found = True
        if not found:
            break
    return cv


_clean_feet_outline_v1 = clean_feet_outline


def clean_feet_outline(cv):  # noqa: F811
    cv = _clean_feet_outline_v1(cv)
    # vaos de 4 px entre os pes tambem viram uma linha so
    top = LEG_TOP - 2
    for y in range(top, 32):
        x = 0
        while x < 32:
            a = cv.px[y][x]
            if a in FEET_COLORS:
                j = x + 1
                while j < 32 and (cv.px[y][j] is None or cv.px[y][j] == OUTLINE):
                    j += 1
                gap = j - x - 1
                if j < 32 and cv.px[y][j] in FEET_COLORS and gap == 4:
                    b = cv.px[y][j]
                    mid = x + 1 + gap // 2
                    for k in range(x + 1, j):
                        cv.px[y][k] = a if k < mid else (OUTLINE if k == mid else b)
                x = j
            else:
                x += 1
    return thin_blocks(cv)


# ------------------------------------------------------------ pato parado com os pes limpos
def idle_fixed():
    """Pato parado aprovado com a mesma limpeza de contorno dos pes da corrida: a linha entre
    os dois pes (que ficou com 2 px ao ampliar) vira 1 px e sem quadradinhos de contorno."""
    dx, dy = registration()
    g = to_grid32(rebuild(frame(load_png(os.path.join(SPR, "spr_playerAnima.png")), 0)), dx, dy)
    return clean_feet_outline(g)


def main_idle_fixed():
    old = upscale(build("parado")[0][0], 4)
    new = upscale(idle_fixed(), 4)
    # antes (esquerda) e depois (direita), ampliados 2x
    comp = Canvas(256 * 2 + 32, 256)
    comp.blit(old, 0, 0, 2)
    comp.blit(new, 256 + 32, 0, 2)
    comp.save(os.path.join(OUT, "pato_parado_antes_depois_2x.png"))
    new.save(os.path.join(OUT, "pato_parado_corrigido.png"))
    if "--salvar" in sys.argv:
        new.save(os.path.join(ARTE, "pato_parado.png"))
        print("salvo em assets/sprites/arte/pato_parado.png")
    print("ok parado corrigido", outline_problems(idle_fixed()))
