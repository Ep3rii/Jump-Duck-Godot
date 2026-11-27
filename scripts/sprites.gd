extends RefCounted
## Acesso a arte do jogo (assets/sprites/arte/, gerada por tools/arte/ e editavel a mao).
## Uso: const Sprites := preload("res://scripts/sprites.gd")

## Arte (ver "Arte" no ROTEIRO_FASES.md): pixel art 16x16 na paleta Endesga 32, gravada em
## 1:1 (1 pixel do arquivo = 1 pixel do jogo) para editar a mao. Bloco, pato, itens e bichos:
## 16x16; chefes: 32x32.
const ART_SCALE := 1.0
const QUADRO := 16  # quadro padrao (bloco, pato, item) em px
## Filtro da arte nova: vizinho mais proximo, para os pixels ficarem nitidos ("crocantes",
## como o original). Em 4K cada pixel da grade de 32 vira exatamente 5x5 pixels da tela.
const ART_FILTER := CanvasItem.TEXTURE_FILTER_NEAREST

## Cenario grande e fundos (assets/sprites/arte/cenario e /fundo): a mesma densidade (1:1).
const GRID_SCALE := 1.0

## Pecas cujo quadro nao e de 16 px (lado do quadro, em px do jogo). estrela_mini: 2 quadros
## de 9x9 (cheia e vazia), a estrela pequena do menu de fases (tools/arte/itens.py).
const QUADRO_DE := {"estrela_mini": 9}

## Portoes das arenas de chefe (tools/arte/objetos.py, usados por scripts/arena_chefe.gd):
## tipo do portao -> peca. Tiras de PORTAO_QUADROS quadros de PORTAO_TAM px; quadro 0 = aberto
## (so um indicio), o ultimo = fechado. 'fazenda' sobe do chao, 'torre' desce do teto.
const PORTOES := {"fazenda": "portao_fazenda", "torre": "portao_torre"}
const PORTAO_QUADROS := 16
const PORTAO_TAM := Vector2(16, 48)

static var _art: Dictionary = {}


## Textura da arte nova pelo nome dentro de assets/sprites/arte/ (ex.: "cenario/celeiro").
static func art(art_name: String) -> Texture2D:
	if not _art.has(art_name):
		_art[art_name] = load("res://assets/sprites/arte/%s.png" % art_name)
	return _art[art_name]


## true se a peca existe em assets/sprites/arte/ (para pecas novas que ainda podem faltar).
static func has_art(art_name: String) -> bool:
	return _art.get(art_name) != null or ResourceLoader.exists("res://assets/sprites/arte/%s.png" % art_name)


## Coracao grande da cutscene final (assets/sprites/arte/coracao_grande.png, de
## tools/arte/lote_base.py): 16 quadros de 32x32 lado a lado, crescendo de 16 a 30 px. Sempre
## desenhado 1:1 (cada tamanho e redesenhado, nada de ampliar o coracao do HUD).
const CORACAO_GRANDE := "coracao_grande"
const CORACAO_GRANDE_QUADRO := 32
const CORACAO_GRANDE_QUADROS := 16


## Desenha o quadro 'frame' do coracao grande 1:1 com o centro em c (em pixels inteiros).
static func draw_coracao_grande(ci: CanvasItem, c: Vector2, frame: int,
		color: Color = Color.WHITE) -> void:
	var lado := float(CORACAO_GRANDE_QUADRO)
	var q := clampi(frame, 0, CORACAO_GRANDE_QUADROS - 1)
	ci.draw_texture_rect_region(art(CORACAO_GRANDE),
		Rect2(floorf(c.x - lado * 0.5), floorf(c.y - lado * 0.5), lado, lado),
		Rect2(q * lado, 0.0, lado, lado), color)


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


## Desenha um quadro de uma tira da arte (quadros de 16 px lado a lado, ou o lado de
## QUADRO_DE) dentro de 'rect'.
static func draw_frame(ci: CanvasItem, art_name: String, rect: Rect2, frame := 0,
		color: Color = Color.WHITE) -> void:
	var q := float(QUADRO_DE.get(art_name, QUADRO))
	ci.draw_texture_rect_region(art(art_name), rect, Rect2(frame * q, 0.0, q, q), color)


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
