extends RefCounted
## Acesso aos sprites convertidos do GameMaker (equivalente a sprite_get_* / draw_sprite).
## Uso: const Sprites := preload("res://scripts/sprites.gd")

const Meta := preload("res://scripts/sprites_meta.gd")

## Arte nova (ver "Arte" no ROTEIRO_FASES.md): 8 pixels do desenho = 1 pixel do jogo.
## Bloco e entidade pequena: 128x128 -> 16 px no jogo. Chefe: 256x256 -> 32 px.
const ART_SCALE := 1.0 / 8.0
## Filtro da arte nova: vizinho mais proximo, para os pixels ficarem nitidos ("crocantes",
## como o original). Em 4K cada pixel da grade de 32 vira exatamente 5x5 pixels da tela.
const ART_FILTER := CanvasItem.TEXTURE_FILTER_NEAREST

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


## Sprite animado para a arte nova: frames desenhados em 128/256 px, reduzidos para o tamanho
## do jogo. origin_art = ponto do quadro (em pixels do desenho) que fica na origem do no.
static func make_art_sprite(sprite_frames: SpriteFrames, origin_art: Vector2) -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = sprite_frames
	s.centered = false
	s.offset = -origin_art
	s.scale = Vector2(ART_SCALE, ART_SCALE)
	s.texture_filter = ART_FILTER
	return s


## SpriteFrames da arte nova a partir de tiras horizontais de quadros de 'frame_size' px.
## anims = {"nome": [caminho_png, quadros, fps, repete]}
static func art_frames(anims: Dictionary, frame_size := 128) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim_name: String in anims:
		var a: Array = anims[anim_name]
		var strip_tex: Texture2D = load(a[0])
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, a[2])
		sf.set_animation_loop(anim_name, a[3] if a.size() > 3 else true)
		for i in int(a[1]):
			var at := AtlasTexture.new()
			at.atlas = strip_tex
			at.region = Rect2(i * frame_size, 0, frame_size, frame_size)
			sf.add_frame(anim_name, at)
	return sf
