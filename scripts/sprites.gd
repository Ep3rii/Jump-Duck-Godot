extends RefCounted
## Acesso a arte do jogo (assets/sprites/arte/, gerada por tools/arte/ e editavel a mao).
## Uso: const Sprites := preload("res://scripts/sprites.gd")

## Arte nova (ver "Arte" no ROTEIRO_FASES.md): gravada em 1:1, para editar a mao pixel por
## pixel; 2 pixels do desenho = 1 pixel do jogo. Bloco e entidade pequena: 32x32 -> 16 px no
## jogo. Chefe: 64x64 -> 32 px.
const ART_SCALE := 0.5
const QUADRO := 32  # quadro padrao (bloco, pato, item) em px do desenho
## Filtro da arte nova: vizinho mais proximo, para os pixels ficarem nitidos ("crocantes",
## como o original). Em 4K cada pixel da grade de 32 vira exatamente 5x5 pixels da tela.
const ART_FILTER := CanvasItem.TEXTURE_FILTER_NEAREST

## Cenario grande e fundos (assets/sprites/arte/cenario e /fundo) sao gravados direto na grade
## da arte: 2 pixels do desenho = 1 pixel do jogo (a mesma densidade do pato, sem ampliar 4x).
const GRID_SCALE := 0.5

static var _art: Dictionary = {}


## Textura da arte nova pelo nome dentro de assets/sprites/arte/ (ex.: "cenario/celeiro").
static func art(art_name: String) -> Texture2D:
	if not _art.has(art_name):
		_art[art_name] = load("res://assets/sprites/arte/%s.png" % art_name)
	return _art[art_name]


## Tamanho no jogo (px) de uma peca gravada na grade; 'frames' = quadros lado a lado na tira.
static func art_size(art_name: String, frames_n := 1) -> Vector2:
	var t := art(art_name)
	return Vector2(t.get_width() / float(frames_n), t.get_height()) * GRID_SCALE


## Desenha uma peca gravada na grade com o canto superior esquerdo em (x, y).
static func draw_art(ci: CanvasItem, art_name: String, x: float, y: float, frame := 0,
		frames_n := 1, color: Color = Color.WHITE) -> void:
	var t := art(art_name)
	var fw := t.get_width() / float(frames_n)
	var h := float(t.get_height())
	ci.draw_texture_rect_region(t, Rect2(x, y, fw * GRID_SCALE, h * GRID_SCALE),
		Rect2(frame * fw, 0.0, fw, h), color)


## Desenha um quadro de uma tira da arte nova (quadros de 32 px lado a lado) dentro de 'rect'.
static func draw_frame(ci: CanvasItem, art_name: String, rect: Rect2, frame := 0,
		color: Color = Color.WHITE) -> void:
	ci.draw_texture_rect_region(art(art_name), rect, Rect2(frame * QUADRO, 0.0, QUADRO, QUADRO), color)


## Desenha um quadro de uma tira de inimigo/bicho da arte nova (2 px do arquivo = 1 px do jogo). 'pivo' = ponto do quadro (em px do jogo) que fica na origem
## do no. A arte olha para a DIREITA; com olha_esquerda = true ela e espelhada no pivo.
static func draw_bicho(ci: CanvasItem, art_name: String, frame: int, frames_n: int, pivo: Vector2,
		olha_esquerda := false, color: Color = Color.WHITE, desloc := Vector2.ZERO) -> void:
	var t := art(art_name)
	var fw := t.get_width() / float(frames_n)
	var fh := float(t.get_height())
	var tam := Vector2(fw, fh) * ART_SCALE
	if olha_esquerda:
		ci.draw_set_transform(desloc, 0.0, Vector2(-1, 1))
	else:
		ci.draw_set_transform(desloc, 0.0, Vector2.ONE)
	ci.draw_texture_rect_region(t, Rect2(-pivo, tam), Rect2(posmod(frame, frames_n) * fw, 0.0, fw, fh), color)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Sprite animado para a arte nova: frames desenhados em 32/64 px, ampliados para o tamanho
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
static func art_frames(anims: Dictionary, frame_size := QUADRO) -> SpriteFrames:
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
