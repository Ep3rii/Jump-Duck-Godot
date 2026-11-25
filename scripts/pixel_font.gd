extends RefCounted
## Fonte pixel do jogo (spr_fontPixel: glifos 8x8 de largura fixa), usada pela UI e pelas
## placas de dica do cenario. Uso: const PixelFont := preload("res://scripts/pixel_font.gd")

const Sprites := preload("res://scripts/sprites.gd")

const LEFT := 0
const CENTER := 1
const RIGHT := 2
const SHADOW := Color8(13, 80, 0)

# Ordem dos glifos no sprite: ASCII 32..126 + acentos (mesma ordem do GameMaker).
const ACCENTS := [193, 192, 194, 195, 201, 202, 205, 211, 212, 213, 218, 199,
	225, 224, 226, 227, 233, 234, 237, 243, 244, 245, 250, 231]

static var _glyphs: Dictionary = {}


static func _glyph(c: String) -> int:
	if _glyphs.is_empty():
		var index := 0
		for code in range(32, 127):
			_glyphs[char(code)] = index
			index += 1
		for code: int in ACCENTS:
			_glyphs[char(code)] = index
			index += 1
	return _glyphs.get(c, -1)


static func width(s: String, scale: float = 1.0) -> float:
	return s.length() * 8.0 * scale


## Texto sem sombra. (x, y) = ponto de ancoragem, centrado na vertical.
static func draw_plain(ci: CanvasItem, x: float, y: float, s: String, col: Color,
		halign: int = LEFT, scale: float = 1.0) -> void:
	var w := width(s, scale)
	var left := x
	if halign == CENTER:
		left = x - w * 0.5
	elif halign == RIGHT:
		left = x - w
	var top := floorf(y - 4.0 * scale + 0.5)
	left = floorf(left + 0.5)
	var strip := Sprites.strip("spr_fontPixel")
	for i in s.length():
		var g := _glyph(s[i])
		if g < 0:
			continue
		ci.draw_texture_rect_region(strip,
			Rect2(left + i * 8.0 * scale, top, 8.0 * scale, 8.0 * scale),
			Rect2(g * 8.0, 0.0, 8.0, 8.0), col)


## Texto com sombra escura deslocada em 'scale' pixels.
static func draw(ci: CanvasItem, x: float, y: float, s: String, col: Color,
		halign: int = LEFT, scale: float = 1.0) -> void:
	draw_plain(ci, x + scale, y + scale, s, SHADOW, halign, scale)
	draw_plain(ci, x, y, s, col, halign, scale)
