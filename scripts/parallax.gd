extends Node2D
## Fundo das fases em camadas (parallax), com a arte de assets/sprites/arte/fundo/ (gerada por
## tools/arte/fundos.py). Desenha relativo ao canto superior esquerdo da camera (Game.cam_pos).
##
## Ceu aberto, do fundo para a frente: ceu em faixas chapadas, estrelas (a noite), sol ou lua,
## nuvens de longe, montanhas, nuvens de perto, torre do gaviao (opcional), colinas de longe,
## passaros e colinas de perto. Cada camada anda numa velocidade (quanto mais longe, mais
## devagar), na horizontal e na vertical.
## Torre por dentro: parede de tijolos com janelas, tochas e estandartes, e colunas na frente.
##
## 'hora' muda as cores do ceu, o tom das camadas e a luz da fase (ver luz.gd): o sol fica
## sempre a esquerda, de onde vem a luz dos desenhos.

const Sprites := preload("res://scripts/sprites.gd")

## Torre do gaviao ao fundo (fases do caminho ate a torre).
@export var mostrar_torre := false
## Ceu aberto (fazenda e caminho) ou parede de pedra por dentro da torre (Fases 4 a 8).
@export_enum("Céu", "Torre por dentro") var cenario := 0
## Hora do dia: cores do ceu, tom das camadas e luz ambiente da fase.
@export_enum("Manhã", "Dia", "Tarde", "Entardecer", "Noite") var hora := 1
## Tamanho da torre ao fundo: ela cresce de fase em fase, conforme o pato chega perto.
@export_enum("Longe", "Média", "Perto") var torre_distancia := 0

## Por hora: 5 faixas do ceu (de cima para baixo), tom das camadas, tom das nuvens, astro
## (sol/lua), posicao dele na tela (fracao), tom dele e luz ambiente da fase.
## As faixas do ceu usam so cores da ENDESGA 32 (a paleta da arte); como ela tem poucos
## azuis, faixas vizinhas podem repetir a cor. A faixa de baixo nunca e a cor das montanhas.
const HORAS := [
	{"ceu": [0x0099db, 0x0099db, 0x2ce8f5, 0xc0cbdc, 0xffffff], "tinta": Color(1, 1, 1),
		"nuvem": Color(1, 1, 1), "astro": "sol", "pos": Vector2(0.3, 0.37),
		"astro_tinta": Color(1, 1, 1), "ambiente": Color(1, 1, 1)},
	{"ceu": [0x0099db, 0x0099db, 0x0099db, 0x2ce8f5, 0xc0cbdc], "tinta": Color(1, 1, 1),
		"nuvem": Color(1, 1, 1), "astro": "sol", "pos": Vector2(0.23, 0.3),
		"astro_tinta": Color(1, 1, 1), "ambiente": Color(1, 1, 1)},
	{"ceu": [0x0099db, 0x0099db, 0xc0cbdc, 0xead4aa, 0xe8b796], "tinta": Color(1.0, 0.97, 0.9),
		"nuvem": Color(1.0, 0.97, 0.9), "astro": "sol", "pos": Vector2(0.3, 0.36),
		"astro_tinta": Color(1.0, 0.92, 0.72), "ambiente": Color(1, 1, 1)},
	{"ceu": [0x3a4466, 0x68386c, 0xb55088, 0xf77622, 0xfeae34], "tinta": Color(0.95, 0.7, 0.74),
		"nuvem": Color(1.0, 0.74, 0.68), "astro": "sol", "pos": Vector2(0.2, 0.6),
		"astro_tinta": Color(1.0, 0.66, 0.4), "ambiente": Color(1.0, 0.9, 0.82)},
	{"ceu": [0x181425, 0x181425, 0x262b44, 0x262b44, 0x3a4466], "tinta": Color(0.42, 0.5, 0.8),
		"nuvem": Color(0.5, 0.56, 0.86), "astro": "lua", "pos": Vector2(0.24, 0.2),
		"astro_tinta": Color(1, 1, 1), "ambiente": Color(0.66, 0.72, 0.96)},
]
## Onde cada faixa do ceu comeca (fracao da altura da tela).
const FAIXAS := [0.0, 0.24, 0.44, 0.6, 0.74]

## Camadas de morro: [arte, velocidade x, velocidade y, px acima da base da tela].
const MONTANHAS := ["fundo/montanhas", 0.12, 0.15, 56.0]
const COLINAS_LONGE := ["fundo/colinas_longe", 0.25, 0.3, 54.0]
const COLINAS_PERTO := ["fundo/colinas_perto", 0.45, 0.55, 22.0]
## Nuvens: [arte, deslocamento x dentro do periodo, y na tela].
const NUVENS_LONGE := [["fundo/nuvem_pequena", 0.0, 34.0], ["fundo/nuvem_media", 150.0, 20.0],
	["fundo/nuvem_pequena", 310.0, 50.0]]
const NUVENS_PERTO := [["fundo/nuvem_grande", 40.0, 58.0], ["fundo/nuvem_media", 300.0, 82.0]]
const TORRES := ["fundo/torre_longe", "fundo/torre_media", "fundo/torre_perto"]
## Quanto da base da torre fica escondido atras das colinas (px acima da base da tela).
const TORRE_BASE := [92.0, 82.0, 62.0]

# --- por dentro da torre
const FUNDO_FATOR := 0.5  # a parede anda na metade da velocidade da camera
const COLUNA_FATOR := 0.72
const CELULA := Vector2(160.0, 144.0)  # uma janela e uma tocha a cada celula da parede
const COLUNA_PASSO := 224.0
const LUZ_TOCHA := Color(1.0, 0.86, 0.6)
const LUZ_JANELA := [Color(0.9, 0.95, 1.0), Color(0.9, 0.95, 1.0), Color(1.0, 0.92, 0.8),
	Color(1.0, 0.78, 0.7), Color(0.7, 0.8, 1.0)]
const AMBIENTE_TORRE := [Color(0.72, 0.72, 0.86), Color(0.72, 0.72, 0.86), Color(0.7, 0.68, 0.82),
	Color(0.66, 0.62, 0.8), Color(0.6, 0.62, 0.85)]

## Tempo proprio (para de contar quando o jogo pausa; as nuvens nao "pulam" ao despausar).
var _time_ms := 0.0
var _base_cor := {}


func _ready() -> void:
	add_to_group("luz")


func _process(delta: float) -> void:
	_time_ms += delta * 1000.0
	queue_redraw()


static func _cor(hex: int) -> Color:
	return Color8((hex >> 16) & 0xff, (hex >> 8) & 0xff, hex & 0xff)


## 1 pixel do jogo = 1 pixel da arte: as camadas param sempre na grade.
static func _grade(v: float) -> float:
	return floorf(v)


## So ha fontes de luz (tochas, janelas, brilho do pato e da chave) no escuro da torre; ao ar
## livre a hora do dia so da o tom da cena.
func usa_luzes() -> bool:
	return cenario == 1


## Luz ambiente da fase (luz.gd multiplica a cena por ela).
func luz_ambiente() -> Color:
	if cenario == 1:
		return AMBIENTE_TORRE[hora]
	return HORAS[hora]["ambiente"]


func _draw() -> void:
	var vx := floorf(Game.cam_pos.x)
	var vy := floorf(Game.cam_pos.y)
	var vw: float = Game.view_size.x
	var vh: float = Game.view_size.y
	if cenario == 1:
		_draw_tower_inside(vx, vy, vw, vh)
		return
	var h: Dictionary = HORAS[hora]
	var tinta: Color = h["tinta"]
	_draw_sky(vx, vy, vw, vh, h["ceu"])
	if h["astro"] == "lua":
		_draw_stars(vx, vy, vw, vh)
	_draw_astro(vx, vy, vw, vh, h)
	_draw_clouds(NUVENS_LONGE, vx, vy, vw, 0.04, 0.003, 420.0, h["nuvem"].lerp(tinta, 0.35))
	_draw_strip(MONTANHAS, vx, vy, vw, vh, tinta)
	_draw_clouds(NUVENS_PERTO, vx, vy, vw, 0.08, 0.006, 520.0, h["nuvem"])
	if mostrar_torre:
		_draw_tower(vx, vy, vw, vh, tinta)
	_draw_strip(COLINAS_LONGE, vx, vy, vw, vh, tinta)
	_draw_birds(vx, vy, vw)
	_draw_strip(COLINAS_PERTO, vx, vy, vw, vh, tinta)


func _draw_sky(vx: float, vy: float, vw: float, vh: float, ceu: Array) -> void:
	for i in FAIXAS.size():
		var y0 := floorf(vh * FAIXAS[i])
		var y1 := vh if i == FAIXAS.size() - 1 else floorf(vh * FAIXAS[i + 1])
		draw_rect(Rect2(vx, vy + y0, vw, y1 - y0), _cor(ceu[i]))


func _draw_stars(vx: float, vy: float, vw: float, vh: float) -> void:
	for i in 46:
		var sx := float((i * 97 + 31) % int(vw))
		var sy := float((i * 53 + 17) % int(vh * 0.6))
		var on := int(_time_ms / 600.0 + i * 3) % 5 != 0
		var s := 1.0
		draw_rect(Rect2(vx + sx, vy + sy, s, s), Color(1, 1, 1, 1.0 if on else 0.45))


func _draw_astro(vx: float, vy: float, vw: float, vh: float, h: Dictionary) -> void:
	var pos: Vector2 = h["pos"]
	var c := Vector2(vx + floorf(vw * pos.x), vy + floorf(vh * pos.y))
	if h["astro"] == "lua":
		Sprites.draw_art(self, "fundo/lua", c.x - 16.0, c.y - 16.0)
	else:
		var quadro := int(_time_ms / 220.0) % 16
		Sprites.draw_art(self, "fundo/sol", c.x - 24.0, c.y - 24.0, quadro, 16, h["astro_tinta"])


## Fileira de nuvens que se repete a cada 'periodo' px e anda sozinha com o vento.
func _draw_clouds(lista: Array, vx: float, vy: float, vw: float, fator: float, vento: float,
		periodo: float, cor: Color) -> void:
	var x0 := vx - fposmod(vx * fator + _time_ms * vento, periodo) - periodo
	while x0 < vx + vw:
		for n: Array in lista:
			Sprites.draw_art(self, n[0], _grade(x0 + n[1]), vy + n[2], 0, 1, cor)
		x0 += periodo


## Tira de morros que se repete na horizontal. camada = [arte, fator x, fator y, altura].
func _draw_strip(camada: Array, vx: float, vy: float, vw: float, vh: float, cor: Color) -> void:
	var tam := Sprites.art_size(camada[0])
	var base := _layer_base(vy, vh, camada[2], camada[3])
	var x := vx - fposmod(vx * camada[1], tam.x)
	while x < vx + vw:
		Sprites.draw_art(self, camada[0], _grade(x), _grade(base - tam.y), 0, 1, cor)
		x += tam.x
	# abaixo da tira, a cor da base dela (salas altas mostram mais do morro)
	var fundo := vy + vh - base
	if fundo > 0.0:
		draw_rect(Rect2(vx, _grade(base), vw, fundo + 1.0), _base_color(camada[0]) * cor)


## Cor da ultima linha da tira (lida uma vez so).
func _base_color(arte: String) -> Color:
	if not _base_cor.has(arte):
		var t := Sprites.art(arte)
		_base_cor[arte] = t.get_image().get_pixel(0, t.get_height() - 1)
	return _base_cor[arte]


## Y da base de uma camada: 'acima' px acima da base da tela quando a camera esta no fundo da
## sala; conforme a camera sobe, a camada desce mais devagar que o mundo (fator_y).
func _layer_base(vy: float, vh: float, fator_y: float, acima: float) -> float:
	return vy + vh - acima + (Game.room_height - vh - vy) * fator_y


## Torre ao longe: perto da borda direita no inicio da fase, 90 px mais para o meio no fim.
func _draw_tower(vx: float, vy: float, vw: float, vh: float, cor: Color) -> void:
	var arte: String = TORRES[torre_distancia]
	var tam := Sprites.art_size(arte)
	var progress := clampf(vx / maxf(1.0, Game.room_width - vw), 0.0, 1.0)
	var cx := floorf(vx + vw - 34.0 - 90.0 * progress)
	var base := _layer_base(vy, vh, COLINAS_LONGE[2], TORRE_BASE[torre_distancia])
	Sprites.draw_art(self, arte, cx - tam.x * 0.5, _grade(base - tam.y), 0, 1, cor)


## Bandinhos de passaros ao longe cruzando o ceu (de tempos em tempos).
func _draw_birds(vx: float, vy: float, vw: float) -> void:
	var now := _time_ms
	var period := 14000.0
	var col := _cor(0x3a4466) if hora < 4 else _cor(0x181425)
	for flock in 2:
		var t := fposmod(now + flock * 6100.0, period) / period  # 0..1 atravessando a tela
		var bx := vx - 40.0 + t * (vw + 80.0)
		var by := vy + 26.0 + flock * 18.0 + sin(now * 0.001 + flock) * 4.0
		for i in 3:
			var px := floorf(bx - i * 9.0)
			var py := floorf(by + absf(i - 1) * 4.0 + (i % 2) * 2.0)
			var up := int(now / 180.0 + i) % 2 == 0
			var wy := py - 1.0 if up else py + 1.0
			draw_rect(Rect2(px - 2, wy, 2, 1), col)
			draw_rect(Rect2(px + 1, wy, 2, 1), col)
			draw_rect(Rect2(px, py, 1, 1), col)


# ------------------------------------------------- por dentro da torre
## Enfeites da parede (janelas, tochas e estandartes) ficam presos ao mundo (fator 1.0), e nao
## a parede de tijolos (FUNDO_FATOR): assim cada um tem um lugar fixo e da para escolher esse
## lugar pelo terreno, sem chama pousada no piso, arco de janela nascendo no chao nem
## estandarte atravessado por plataforma.
const ENFEITE_FATOR := 1.0
## Retangulo de cada enfeite em volta do seu ponto (x, y, largura, altura) e quanto precisa
## ficar livre embaixo dele.
const RET_JANELA := Rect2(-18.0, -30.0, 36.0, 60.0)
const LIVRE_JANELA := 16.0
const RET_TOCHA := Rect2(-8.0, -10.0, 16.0, 36.0)
const LIVRE_TOCHA := 24.0
const RET_BANDEIRA := Rect2(-10.0, 0.0, 20.0, 56.0)
const LIVRE_BANDEIRA := 16.0

const Solids := preload("res://scripts/solids.gd")

## Celula da grade (Vector2i) -> [janela, tocha, bandeira] ja testados no terreno (Vector2 no
## mundo, ou null quando nao coube na celula).
var _enfeites := {}
var _solidos: Array = []


## Solidos parados da fase (tiles, blocos, portas) e as placas de pressao. Caixas e
## plataformas moveis ficam de fora: mudam de lugar.
func _solidos_fixos() -> Array:
	if (_solidos.is_empty() or _solidos[1].is_empty()) and is_inside_tree():
		var nos := []
		for n in get_tree().get_nodes_in_group("solid"):
			var movel: bool = (n.is_in_group("caixa") or n.is_in_group("plataforma")
				or n.is_in_group("plataforma_cai"))
			if not movel:
				nos.append(n)
		_solidos = [nos, get_tree().get_nodes_in_group("solid_tiles"),
			get_tree().get_nodes_in_group("placa")]
	return _solidos


func _bate(ret: Rect2) -> bool:
	var snap := _solidos_fixos()
	if snap.is_empty():
		return false
	var nos: Array = (snap[0] as Array).filter(func(n): return is_instance_valid(n) and not n.is_queued_for_deletion())
	if Solids.hits([nos, snap[1]], ret):
		return true
	for p in snap[2]:
		if not is_instance_valid(p):
			continue
		var tw: int = p.get("tiles_w") if p.get("tiles_w") != null else 1
		if ret.intersects(Rect2(p.global_position.x, p.global_position.y - 16.0, 16.0 * tw, 16.0)):
			return true
	return false


## Ponto livre para um enfeite: tenta o lugar original e depois sobe de 16 em 16 px (ate 3
## vezes); se ainda bater em algo solido, o enfeite nao aparece nessa celula.
func _lugar_livre(p: Vector2, ret: Rect2, livre_embaixo: float) -> Variant:
	for i in 4:
		var q := p - Vector2(0.0, 16.0 * i)
		var r := Rect2(q + ret.position, ret.size)
		r.size.y += livre_embaixo
		if not _bate(r):
			return q
	return null


func _enfeites_da_celula(c: int, r: int) -> Array:
	var chave := Vector2i(c, r)
	if _enfeites.has(chave):
		return _enfeites[chave]
	var bx := c * CELULA.x
	var by := r * CELULA.y
	var out := [_lugar_livre(Vector2(bx + 60.0, by + 62.0), RET_JANELA, LIVRE_JANELA),
		_lugar_livre(Vector2(bx + 140.0, by + 74.0), RET_TOCHA, LIVRE_TOCHA), null]
	if posmod(c + r, 2) == 0:
		out[2] = _lugar_livre(Vector2(bx + 96.0, by + 30.0), RET_BANDEIRA, LIVRE_BANDEIRA)
	# so guarda depois que o terreno da fase existe (o teste e feito uma vez por celula)
	if not _solidos_fixos().is_empty() and not _solidos[1].is_empty():
		_enfeites[chave] = out
	return out


## Janelas e tochas da parede que aparecem na tela: [[centro da janela...], [chama da tocha...],
## [canto do estandarte...]], em coordenadas do mundo.
func _wall_points(vx: float, vy: float, vw: float, vh: float) -> Array:
	var ox := vx * ENFEITE_FATOR
	var oy := vy * ENFEITE_FATOR
	var janelas: Array[Vector2] = []
	var tochas: Array[Vector2] = []
	var bandeiras: Array[Vector2] = []
	var c0 := floori((ox - 120.0) / CELULA.x)
	var r0 := floori((oy - 110.0) / CELULA.y)
	for r in range(r0, r0 + int(vh / CELULA.y) + 3):
		for c in range(c0, c0 + int(vw / CELULA.x) + 3):
			var e := _enfeites_da_celula(c, r)
			var d := Vector2(vx - ox, vy - oy).floor()
			if e[0] != null:
				janelas.append(e[0] + d)
			if e[1] != null:
				tochas.append(e[1] + d)
			if e[2] != null:
				bandeiras.append(e[2] + d)
	return [janelas, tochas, bandeiras]


func _draw_tower_inside(vx: float, vy: float, vw: float, vh: float) -> void:
	var now := _time_ms
	# parede de tijolos (bloco de 64 px que emenda nos quatro lados)
	var ox := fposmod(vx * FUNDO_FATOR, 64.0)
	var oy := fposmod(vy * FUNDO_FATOR, 64.0)
	var y := vy - oy
	while y < vy + vh:
		var x := vx - ox
		while x < vx + vw:
			Sprites.draw_art(self, "fundo/parede", floorf(x), floorf(y))
			x += 64.0
		y += 64.0
	var pts := _wall_points(vx, vy, vw, vh)
	var ceu: Array = HORAS[hora]["ceu"]
	for j: Vector2 in pts[0]:
		# o ceu da hora da fase atras do vidro, e a janela de pedra por cima
		draw_rect(Rect2(j.x - 12.0, j.y - 22.0, 24.0, 22.0), _cor(ceu[1]))
		draw_rect(Rect2(j.x - 12.0, j.y, 24.0, 24.0), _cor(ceu[3]))
		if hora == 4:
			for i in 4:
				draw_rect(Rect2(j.x - 9.0 + i * 5.0, j.y - 16.0 + (i * 7) % 26, 1, 1), Color.WHITE)
		Sprites.draw_art(self, "fundo/janela", j.x - 18.0, j.y - 30.0)
	for b: Vector2 in pts[2]:
		Sprites.draw_art(self, "fundo/bandeira", b.x - 10.0, b.y)
	for t: Vector2 in pts[1]:
		var quadro := int(now / 40.0 + t.x * 0.37) % 16
		Sprites.draw_art(self, "fundo/tocha", t.x - 8.0, t.y - 10.0, quadro, 16)
	# colunas na frente da parede (andam um pouco mais rapido: dao profundidade)
	var cx := vx - fposmod(vx * COLUNA_FATOR, COLUNA_PASSO) - COLUNA_PASSO + 100.0
	var coy := fposmod(vy * COLUNA_FATOR, 64.0)
	while cx < vx + vw:
		var cy := vy - coy
		while cy < vy + vh:
			Sprites.draw_art(self, "fundo/coluna", floorf(cx), floorf(cy))
			cy += 64.0
		cx += COLUNA_PASSO


## Luzes da parede da torre para luz.gd: [posicao, raio, cor, forca].
func luzes() -> Array:
	if cenario != 1:
		return []
	var out := []
	var pts := _wall_points(floorf(Game.cam_pos.x), floorf(Game.cam_pos.y), Game.view_size.x,
		Game.view_size.y)
	for t: Vector2 in pts[1]:
		var pisca := 3.0 if int(_time_ms / 170.0 + t.x) % 3 == 0 else 0.0
		out.append([t, 60.0 + pisca, LUZ_TOCHA, 1.0])
	for j: Vector2 in pts[0]:
		out.append([j + Vector2(6.0, 14.0), 44.0, LUZ_JANELA[hora], 0.75])
	return out
