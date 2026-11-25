@tool
extends Node2D
## Decoracao de cenario desenhada em codigo (provisoria ate existir a arte definitiva).
## Nao colide com nada. Origem = base, no chao (centro para moinho/celeiro/arvore/arbusto,
## canto esquerdo para a cerca).

@export_enum("Moinho", "Celeiro", "Cerca", "Árvore", "Arbusto", "Placa de saída", "Junco", "Pilar de pedra") var tipo := 0:
	set(v):
		tipo = v
		queue_redraw()
## Largura da cerca / do pilar em tiles de 16 px.
@export var tiles_w := 3:
	set(v):
		tiles_w = v
		queue_redraw()
## Altura do pilar de pedra em tiles (o pilar cobre por cima um paredao de terra do mapa).
@export var tiles_h := 4:
	set(v):
		tiles_h = v
		queue_redraw()

const OUTLINE := Color8(40, 28, 20)
const STONE := Color8(196, 186, 160)
const STONE_DARK := Color8(150, 140, 116)
const WOOD := Color8(150, 92, 44)
const WOOD_DARK := Color8(104, 60, 28)
const WOOD_LIGHT := Color8(196, 136, 74)
const ROOF := Color8(150, 50, 40)
const ROOF_DARK := Color8(104, 32, 28)
const BARN := Color8(186, 54, 44)
const BARN_DARK := Color8(132, 36, 32)
const WHITE := Color8(240, 236, 220)
const LEAF := Color8(71, 160, 40)
const LEAF_DARK := Color8(40, 110, 30)
const LEAF_LIGHT := Color8(133, 220, 60)

var _time := 0.0


func _ready() -> void:
	if tipo == 3 and not Engine.is_editor_hint():
		add_to_group("decoracao_arvore")  # ambiente.gd solta folhas delas


func _process(delta: float) -> void:
	if tipo in [0, 3, 4, 6]:  # moinho gira; arvore, arbusto e junco balancam com o vento
		_time += delta
		queue_redraw()


## Balanco suave (px) com fase diferente para cada objeto.
func _sway(speed: float, amount: float) -> float:
	return floorf(sin(_time * speed + position.x * 0.07) * amount + 0.5)


func _draw() -> void:
	match tipo:
		0:
			_draw_moinho()
		1:
			_draw_celeiro()
		2:
			_draw_cerca()
		3:
			_draw_arvore()
		4:
			_draw_arbusto()
		5:
			_draw_placa_saida()
		6:
			_draw_junco()
		7:
			_draw_pilar()


func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), c)


func _draw_moinho() -> void:
	# torre de pedra (trapezio em degraus de 4 px)
	for i in 20:
		var y := -4.0 - i * 4.0
		var half := 18.0 - i * 0.5
		_r(-half - 1, y - 4, half * 2 + 2, 5, OUTLINE)
		_r(-half, y - 3, half * 2, 3, STONE if i % 2 == 0 else STONE_DARK)
	# porta e janela
	_r(-5, -18, 10, 18, OUTLINE)
	_r(-4, -17, 8, 17, WOOD_DARK)
	_r(-3, -52, 6, 7, OUTLINE)
	_r(-2, -51, 4, 5, Color8(250, 220, 120))
	# telhado conico
	for i in 10:
		var half := 14.0 - i * 1.4
		_r(-half, -84 - i * 2.0, half * 2, 2, ROOF if i % 2 == 0 else ROOF_DARK)
	# pas girando em volta do eixo
	var hub := Vector2(0, -74)
	var a := _time * 1.2
	for k in 4:
		var ang := a + k * PI * 0.5
		draw_set_transform(hub, ang, Vector2.ONE)
		_r(-1, -40, 3, 40, WOOD_DARK)
		_r(2, -38, 7, 30, WHITE)
		for line in 4:
			_r(2, -36 + line * 7, 7, 1, WOOD_LIGHT)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_r(hub.x - 3, hub.y - 3, 6, 6, OUTLINE)
	_r(hub.x - 2, hub.y - 2, 4, 4, WOOD_LIGHT)


func _draw_celeiro() -> void:
	_r(-33, -41, 66, 41, OUTLINE)
	_r(-32, -40, 64, 40, BARN)
	for x in range(-30, 32, 6):
		_r(x, -40, 1, 40, BARN_DARK)
	# telhado
	for i in 12:
		var half := 36.0 - i * 3.0
		_r(-half, -44 - i * 2.0, half * 2, 2, OUTLINE if i == 0 else (ROOF_DARK if i % 2 else ROOF))
	# portao com X branco
	_r(-13, -26, 26, 26, WHITE)
	_r(-11, -24, 22, 24, BARN_DARK)
	for i in 22:
		_r(-11 + i, -24 + i, 2, 2, WHITE)
		_r(9 - i, -24 + i, 2, 2, WHITE)
	# janela do sotao
	_r(-5, -56, 10, 8, WHITE)
	_r(-4, -55, 8, 6, Color8(60, 40, 30))


func _draw_cerca() -> void:
	var w := 16.0 * tiles_w
	_r(0, -10, w, 2, WOOD_DARK)
	_r(0, -5, w, 2, WOOD_DARK)
	_r(0, -11, w, 1, WOOD_LIGHT)
	_r(0, -6, w, 1, WOOD_LIGHT)
	var x := 2.0
	while x < w:
		_r(x - 1, -14, 4, 14, OUTLINE)
		_r(x, -13, 2, 13, WOOD)
		_r(x, -13, 1, 13, WOOD_LIGHT)
		x += 8.0


func _draw_arvore() -> void:
	_r(-4, -28, 8, 28, OUTLINE)
	_r(-3, -28, 6, 28, WOOD)
	_r(-3, -28, 2, 28, WOOD_LIGHT)
	var sx := _sway(1.1, 1.2)
	var blobs := [[0, -44, 20], [-12, -36, 13], [12, -36, 13], [0, -54, 13]]
	for blob in blobs:
		var k: float = 0.5 if blob[1] > -40 else 1.0  # a copa mexe mais em cima
		draw_circle(Vector2(blob[0] + sx * k, blob[1]), blob[2] + 1, OUTLINE)
	for blob in blobs:
		var k: float = 0.5 if blob[1] > -40 else 1.0
		draw_circle(Vector2(blob[0] + sx * k, blob[1]), blob[2], LEAF)
	draw_circle(Vector2(-12 + sx * 0.5, -32), 7, LEAF_DARK)
	draw_circle(Vector2(-5 + sx, -50), 6, LEAF_LIGHT)
	draw_circle(Vector2(6 + sx, -58), 4, LEAF_LIGHT)
	draw_circle(Vector2(8 + sx * 0.5, -34), 5, LEAF_DARK)
	# frutinhas vermelhas
	for f in [[-8, -44], [9, -48], [2, -38], [-14, -38]]:
		_r(f[0] + sx, f[1], 2, 2, Color8(220, 50, 50))


func _draw_arbusto() -> void:
	var sx := _sway(1.6, 0.6)
	for blob in [[-7, -6, 7], [7, -6, 7], [0, -9, 8]]:
		draw_circle(Vector2(blob[0] + sx, blob[1]), blob[2] + 1, OUTLINE)
	for blob in [[-7, -6, 7], [7, -6, 7], [0, -9, 8]]:
		draw_circle(Vector2(blob[0] + sx, blob[1]), blob[2], LEAF)
	draw_circle(Vector2(-2 + sx, -12), 3, LEAF_LIGHT)
	draw_circle(Vector2(6 + sx, -4), 3, LEAF_DARK)
	# florzinhas no arbusto
	for f in [[-8, -9], [4, -12], [9, -5]]:
		_r(f[0] + sx, f[1], 2, 2, WHITE)
		_r(f[0] + sx, f[1], 1, 1, Color8(255, 220, 80))
	_r(-14, -1, 28, 1, LEAF_DARK)


func _draw_placa_saida() -> void:
	# seta de madeira apontando para a direita
	_r(-1, -20, 3, 20, WOOD_DARK)
	_r(-10, -26, 18, 9, OUTLINE)
	_r(-9, -25, 16, 7, WOOD)
	for i in 5:
		_r(8 + i, -26 + i, 1, 9 - i * 2, OUTLINE if i == 4 else WOOD)
	_r(-6, -22, 10, 1, WOOD_LIGHT)


func _draw_junco() -> void:
	# moita de juncos/taboas da beira do lago
	# cada haste se curva com o vento, mais na ponta
	var stems := [[-6, 22], [-3, 28], [0, 20], [3, 26], [6, 18]]
	for i in stems.size():
		var st: Array = stems[i]
		var h: int = st[1]
		for seg in 4:
			var y0 := -h + seg * h / 4.0
			var bend := sin(_time * 1.8 + i * 0.9 + position.x * 0.05) * 1.5 * (1.0 - seg / 4.0)
			var x: float = st[0] + floorf(bend + 0.5)
			_r(x, y0, 1, ceilf(h / 4.0), LEAF_DARK)
			_r(x + 1, y0 + 1, 1, ceilf(h / 4.0) - 1, LEAF)
	for i in [1, 3]:
		var st: Array = stems[i]
		var bend := floorf(sin(_time * 1.8 + i * 0.9 + position.x * 0.05) * 1.5 + 0.5)
		_r(st[0] - 1 + bend, -st[1] - 1, 3, 7, OUTLINE)
		_r(st[0] + bend, -st[1], 1, 5, WOOD)


## Pilar de pedra com musgo (cobre os paredoes no meio dos lagos, que no tileset de grama
## pareciam uma coluna de terra). Origem no canto inferior esquerdo.
func _draw_pilar() -> void:
	var w := 16.0 * tiles_w
	var h := 16.0 * tiles_h
	_r(0, -h, w, h, Color8(60, 58, 70))
	for row in int(h / 8.0):
		var y := -h + row * 8.0
		var shift := 6.0 if row % 2 == 1 else 0.0
		var x := -shift
		var n := 0
		while x < w:
			var bx := maxf(x, 0.0) + 1.0
			var bw := minf(x + 12.0, w) - bx - 1.0
			if bw > 0.0:
				var hsh := posmod(row * 7 + n * 13 + int(position.x), 5)
				var c := STONE if hsh > 1 else STONE_DARK
				var wet := clampf((y + h) / h, 0.0, 1.0)  # mais escuro e molhado embaixo
				c = c.darkened(wet * 0.35)
				_r(bx, y + 1, bw, 6, c)
				_r(bx, y + 1, bw, 1, c.lightened(0.25))
			x += 12.0
			n += 1
	# musgo descendo do alto e em manchas
	for i in tiles_w * 4:
		var mx := float(i * 4)
		var drip := 3.0 + posmod(i * 5 + int(position.x), 7)
		_r(mx, -h, 4, drip, LEAF_DARK)
		_r(mx, -h, 4, 2, LEAF)
	for i in int(h / 24.0):
		var my := -h + 12.0 + i * 24.0
		var mx := float(posmod(i * 11 + int(position.x), int(w) - 6))
		_r(mx, my, 6, 3, LEAF_DARK)
		_r(mx + 1, my, 4, 1, LEAF)
	_r(0, -h, 1, h, OUTLINE)
	_r(w - 1, -h, 1, h, OUTLINE)
