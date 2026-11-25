extends RefCounted
## Fonte pixel do jogo (assets/sprites/arte/fonte.png, gerada por tools/arte/fonte.py), usada
## pela UI, pelas placas de dica e pela cutscene.
## Uso: const PixelFont := preload("res://scripts/pixel_font.gd")
##
## Maiusculas de 7 px de altura, largura proporcional (1 px entre as letras) e acentos em cima
## da letra inteira. Minusculas sao desenhadas como maiusculas. O ponto (x, y) de quem desenha
## e o centro vertical das letras; acentos sobem 3 px acima e a cedilha/virgula descem 2.

const Meta := preload("res://scripts/fonte_meta.gd")

const LEFT := 0
const CENTER := 1
const RIGHT := 2
const SHADOW := Color8(13, 80, 0)
const SPACING := 1.0  # px entre as letras
const UNKNOWN_W := 3.0  # caractere que a fonte nao tem: so um espaco

static var _tex: Texture2D


static func _glyph(c: String) -> Array:
	var g: Array = Meta.GLYPHS.get(c, [])
	if g.is_empty():
		g = Meta.GLYPHS.get(c.to_upper(), [])
	return g


static func width(s: String, scale: float = 1.0) -> float:
	var w := 0.0
	for i in s.length():
		var g := _glyph(s[i])
		w += (float(g[1]) if not g.is_empty() else UNKNOWN_W) + SPACING
	return maxf(0.0, w - SPACING) * scale


## Texto sem sombra. (x, y) = ponto de ancoragem, centrado na vertical.
static func draw_plain(ci: CanvasItem, x: float, y: float, s: String, col: Color,
		halign: int = LEFT, scale: float = 1.0) -> void:
	if _tex == null:
		_tex = load("res://assets/sprites/arte/fonte.png")
	var left := x
	if halign == CENTER:
		left = x - width(s, scale) * 0.5
	elif halign == RIGHT:
		left = x - width(s, scale)
	left = floorf(left + 0.5)
	# as letras (7 px) ficam centradas em y; a celula tem Meta.TOP linhas acima para o acento
	var top := floorf(y - 4.0 * scale + 0.5) - Meta.TOP * scale
	var cell_h := float(Meta.CELL.y)
	for i in s.length():
		var g := _glyph(s[i])
		if g.is_empty():
			left += (UNKNOWN_W + SPACING) * scale
			continue
		var gw := float(g[1])
		ci.draw_texture_rect_region(_tex, Rect2(left, top, gw * scale, cell_h * scale),
			Rect2(float(g[0]) * Meta.CELL.x, 0.0, gw, cell_h), col)
		left += (gw + SPACING) * scale


## Texto com sombra escura deslocada em 'scale' pixels.
static func draw(ci: CanvasItem, x: float, y: float, s: String, col: Color,
		halign: int = LEFT, scale: float = 1.0) -> void:
	draw_plain(ci, x + scale, y + scale, s, SHADOW, halign, scale)
	draw_plain(ci, x, y, s, col, halign, scale)
