extends RefCounted
## Acesso aos sprites convertidos do GameMaker (equivalente a sprite_get_* / draw_sprite).
## Uso: const Sprites := preload("res://scripts/sprites.gd")

const Meta := preload("res://scripts/sprites_meta.gd")

static var _frames: Dictionary = {}
static var _strips: Dictionary = {}


static func meta(spr: String) -> Array:
	return Meta.META[spr]


static func frame_count(spr: String) -> int:
	return Meta.META[spr][2]


## Tira horizontal (todos os frames lado a lado).
static func strip(spr: String) -> Texture2D:
	if not _strips.has(spr):
		_strips[spr] = load("res://assets/sprites/%s.png" % spr)
	return _strips[spr]


## SpriteFrames com a animacao "default" (todos os frames do sprite).
static func frames(spr: String) -> SpriteFrames:
	if not _frames.has(spr):
		_frames[spr] = load("res://assets/frames/%s.tres" % spr)
	return _frames[spr]


static func tex(spr: String, index: int) -> Texture2D:
	var n: int = Meta.META[spr][2]
	return frames(spr).get_frame_texture("default", posmod(index, n))


## Equivalente a draw_sprite_ext(): (x, y) e a ORIGEM do sprite no GameMaker.
static func draw(ci: CanvasItem, spr: String, index: int, x: float, y: float,
		sx: float = 1.0, sy: float = 1.0, color: Color = Color.WHITE) -> void:
	var m: Array = Meta.META[spr]
	ci.draw_texture_rect(tex(spr, index),
		Rect2(x - m[3] * sx, y - m[4] * sy, m[0] * sx, m[1] * sy), false, color)


## Desenha com o canto superior esquerdo em (x, y) (ui_draw_tl / ui_draw_tl_ext do original).
static func draw_tl(ci: CanvasItem, spr: String, index: int, x: float, y: float,
		scale: float = 1.0) -> void:
	var m: Array = Meta.META[spr]
	ci.draw_texture_rect(tex(spr, index), Rect2(x, y, m[0] * scale, m[1] * scale), false)
