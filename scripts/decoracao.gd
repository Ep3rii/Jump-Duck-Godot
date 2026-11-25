@tool
extends Node2D
## Decoracao de cenario desenhada em codigo (provisoria ate existir a arte definitiva).
## Nao colide com nada. Origem = base, no chao (centro para moinho/celeiro/arvore/arbusto,
## canto esquerdo para a cerca).

@export_enum("Moinho", "Celeiro", "Cerca", "Árvore", "Arbusto", "Placa de saída", "Junco") var tipo := 0:
	set(v):
		tipo = v
		queue_redraw()
## Largura da cerca em tiles de 16 px.
@export var tiles_w := 3:
	set(v):
		tiles_w = v
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


func _process(delta: float) -> void:
	if tipo == 0:  # so o moinho anima
		_time += delta
		queue_redraw()


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
	for blob in [[0, -44, 20], [-12, -36, 13], [12, -36, 13], [0, -54, 13]]:
		draw_circle(Vector2(blob[0], blob[1]), blob[2] + 1, OUTLINE)
	for blob in [[0, -44, 20], [-12, -36, 13], [12, -36, 13], [0, -54, 13]]:
		draw_circle(Vector2(blob[0], blob[1]), blob[2], LEAF)
	draw_circle(Vector2(-5, -50), 6, LEAF_LIGHT)
	draw_circle(Vector2(8, -34), 5, LEAF_DARK)


func _draw_arbusto() -> void:
	for blob in [[-7, -6, 7], [7, -6, 7], [0, -9, 8]]:
		draw_circle(Vector2(blob[0], blob[1]), blob[2] + 1, OUTLINE)
	for blob in [[-7, -6, 7], [7, -6, 7], [0, -9, 8]]:
		draw_circle(Vector2(blob[0], blob[1]), blob[2], LEAF)
	draw_circle(Vector2(-2, -12), 3, LEAF_LIGHT)
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
	var stems := [[-6, 22], [-3, 28], [0, 20], [3, 26], [6, 18]]
	for s in stems:
		_r(s[0], -s[1], 1, s[1], LEAF_DARK)
		_r(s[0] + 1, -s[1] + 2, 1, s[1] - 2, LEAF)
	for s in [[-3, 28], [3, 26]]:
		_r(s[0] - 1, -s[1] - 1, 3, 7, OUTLINE)
		_r(s[0], -s[1], 1, 5, WOOD)
