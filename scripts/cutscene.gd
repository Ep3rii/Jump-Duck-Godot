extends Node2D
## Cutscene final (cena "cutscene_final"): no topo da torre o pato encontra a Pata e os dois
## olham o por do sol. Tudo desenhado em codigo (provisorio ate existir a arte): ceu, sol,
## montanhas, o alto da torre, o ninho e a Pata; o pato usa os sprites do jogador.
## Linha do tempo em segundos (DURATION no total); ENTER / ESPACO / ESC pulam.
## No fim chama Game.finish_ending() (vai para os creditos).

const Sprites := preload("res://scripts/sprites.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")
const PlayerScript := preload("res://scripts/player.gd")
const PixelFx := preload("res://scripts/pixelfx.gd")
## O por do sol escurece o cenario em degraus (PASSOS_LUZ tons), nao num degrade continuo.
const PASSOS_LUZ := 6

const DURATION := 22.0
const FLOOR_Y := 140.0
const DUCK_STOP_X := 150.0
const PATA_START_X := 262.0
const PATA_STOP_X := 168.0
const PATA_PIVO := Vector2(8, 15)  # pes da Pata no quadro de 16 px (como o pato)

const SKY_TOP_DAY := Color8(250, 150, 96)
const SKY_TOP_NIGHT := Color8(54, 36, 88)
const SKY_LOW_DAY := Color8(255, 206, 120)
const SKY_LOW_NIGHT := Color8(196, 88, 96)
## A tela tem 384x216 (Game.TELA) e a cena foi montada em 320x180: a camera mostra a cena
## centrada na horizontal e encostada embaixo; ceu, montanhas e torre cobrem a tela toda.
const CAM_POS := Vector2(-32, -36)
const ESQ := -32.0  # borda esquerda da tela, no mundo
const DIR := 352.0  # borda direita

var t := 0.0
var _done := false
var _duck: AnimatedSprite2D
var _overlay: Node2D
var _sfx_heart := false
var _sfx_love := false
## O que o pato traz para a Pata (Game.buque_nivel, pelas flores colhidas): 0 nada, 1 uma flor,
## 2 buque pequeno, 3 buque grande.
var buque := 0
const BUQUE_ARTE := ["", "flor_unica", "buque_pequeno", "buque_grande"]
const BUQUE_TEXTO := ["SEM FLORES... MAS COM AMOR", "UMA FLOR PARA A PATA",
	"UM BUQUÊ PARA A PATA", "UM GRANDE BUQUÊ PARA A PATA!"]
const BUQUE_PIVO := Vector2(8, 15)


func _enter_tree() -> void:
	Game.leave_level()
	Game.room = "cutscene_final"
	Game.room_width = 320
	Game.room_height = 180
	Game.cam_pos = CAM_POS
	Game.view_size = Vector2(Game.TELA)


func _ready() -> void:
	if Game.game_state != "cutscene":
		Game.game_state = "cutscene"
	var fl := Game.flores_colhidas()
	buque = Game.buque_nivel(fl.x, fl.y)
	var cam := Camera2D.new()
	cam.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	cam.position = CAM_POS
	add_child(cam)
	cam.make_current()
	# o pato com a arte nova (as mesmas animacoes do jogador)
	_duck = Sprites.make_art_sprite(Sprites.art_frames(PlayerScript.ART_ANIMS), PlayerScript.ART_ORIGIN)
	_duck.position = Vector2(-16, FLOOR_Y)
	_duck.play("run")
	add_child(_duck)
	_overlay = Node2D.new()
	_overlay.z_index = 10
	# coracoes e textos desbotam em quadriculado (dither de Bayer), nunca por alfa
	_overlay.material = PixelFx.material_dither()
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)


# ------------------------------------------------------------- linha do tempo
func _phase(a: float, b: float) -> float:
	return clampf((t - a) / (b - a), 0.0, 1.0)


func duck_x() -> float:
	return lerpf(-16.0, DUCK_STOP_X, _phase(0.5, 4.0))


func pata_x() -> float:
	return lerpf(PATA_START_X, PATA_STOP_X, _phase(5.0, 7.0))


## Quanto o sol ja se pos (0 = alto, 1 = atras das montanhas).
func sunset() -> float:
	return _phase(5.0, 18.0)


## O tom da luz do por do sol em degraus (0, 1/5 .. 1): o cenario escurece de tom em tom.
static func luz_degrau(k: float) -> float:
	return floorf(k * (PASSOS_LUZ - 1) + 0.5) / float(PASSOS_LUZ - 1)


func _process(delta: float) -> void:
	if _done:
		return
	t += delta
	_duck.position.x = floorf(duck_x())
	_duck.modulate = _tinta_bicho(luz_degrau(sunset()))
	_duck.play("run" if t > 0.5 and t < 4.0 else "idle")
	if t >= 4.5 and not _sfx_heart:
		_sfx_heart = true
		Game.play_sfx("life")
	if t >= 7.0 and not _sfx_love:
		_sfx_love = true
		Game.play_sfx("flower")
	var skip := t > 0.5 and (Input.is_action_just_pressed("confirm")
		or Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("jump"))
	if t >= DURATION or skip:
		_finish()
		return
	queue_redraw()
	_overlay.queue_redraw()


func _finish() -> void:
	if _done:
		return
	_done = true
	Game.finish_ending()


# ------------------------------------------------------------------- desenho
func _draw() -> void:
	var sol := sunset()
	var k := luz_degrau(sol)  # tons do cenario em degraus; o sol desce liso
	_draw_sky(k)
	_draw_stars(k)
	_draw_sun(sol)
	var dusk := Color(lerpf(0.75, 0.35, k), lerpf(0.5, 0.25, k), lerpf(0.7, 0.45, k))
	Sprites.draw_art(self, "fundo/montanhas", -96.0, 24.0, 0, 1, dusk)
	# nuvens opacas (so o tom muda): nada do ceu ou das estrelas aparece atraves delas
	var clouds := Color(1.0, lerpf(0.68, 0.42, k), lerpf(0.75, 0.58, k), 1.0)
	Sprites.draw_art(self, "fundo/nuvem_grande", floorf(-40.0 + t * 2.0), 14.0, 0, 1, clouds)
	Sprites.draw_art(self, "fundo/nuvem_media", floorf(150.0 + t * 1.2), 38.0, 0, 1, clouds)
	_draw_tower_top(k)
	_draw_nest(k)
	_draw_pata(k)
	_draw_buque(k)


## Onde fica o buque: na frente do pato ate ele entregar (7,4 s a 8,2 s), depois com a Pata
## (na frente dela: olhando para o pato ate 9 s, depois para o sol). x, y = pivo (pe do cabo).
func buque_pos() -> Vector2:
	var com_pato := Vector2(floorf(duck_x()) + 7.0, FLOOR_Y - 2.0)
	var frente := -7.0 if t < 9.0 else 7.0
	var com_pata := Vector2(floorf(pata_x()) + frente, FLOOR_Y - 2.0)
	return com_pato.lerp(com_pata, _phase(7.4, 8.2)).floor()


func _draw_buque(k: float) -> void:
	if buque <= 0 or t < 0.5:
		return
	var arte: String = BUQUE_ARTE[buque]
	if not Sprites.has_art(arte):
		return
	var q := int(t * 12.0) % 16
	var olha_esq := t >= 8.2 and t < 9.0  # com a Pata, virado para o lado dela
	Sprites.draw_bicho(self, arte, q, 16, BUQUE_PIVO, olha_esq, _tinta_bicho(k), buque_pos())


## Tom do casal (e do pato) no por do sol: escurece menos que o cenario (ate 0.8, as pedras
## vao ate 0.55) com um leve rosado no fim, para os dois nao parecerem colados por cima.
static func _tinta_bicho(k: float) -> Color:
	var s := lerpf(1.0, 0.8, k)
	return Color(s, s * lerpf(1.0, 0.88, k), s * lerpf(1.0, 0.95, k))


func _draw_sky(k: float) -> void:
	# 6 faixas chapadas (como o ceu das fases), do alto para o horizonte
	var top := SKY_TOP_DAY.lerp(SKY_TOP_NIGHT, k)
	var low := SKY_LOW_DAY.lerp(SKY_LOW_NIGHT, k)
	for i in 6:
		draw_rect(Rect2(ESQ, CAM_POS.y + i * 36, DIR - ESQ, 36), top.lerp(low, i / 5.0))


func _draw_stars(k: float) -> void:
	# estrelas opacas: com a noite chegando acendem mais delas (e nao mais forte); cada uma
	# pisca entre branco e cinza-azulado da paleta, e no apagar some de vez
	var a := clampf((k - 0.5) * 2.0, 0.0, 1.0)
	if a <= 0.0:
		return
	for i in 24:
		if a <= float((i * 7) % 24) / 24.0:
			continue
		var x := ESQ + fposmod(i * 67.0 + 13.0, DIR - ESQ)
		var y := CAM_POS.y + fposmod(i * 29.0 + 7.0, 90.0 - CAM_POS.y)
		var tw := sin(t * 3.0 + i)
		if tw > -0.6:
			draw_rect(Rect2(floorf(x), floorf(y), 1, 1), ESTRELA if tw > 0.2 else ESTRELA_FRACA)


## Sol da arte dos fundos (16 quadros), descendo. Nada de tingir por um lerp de cor qualquer:
## ate k = 0.6 fica com as cores do proprio sprite; no fim do por do sol passa de uma vez para
## o laranja da paleta (#feae34, Endesga 32).
const SOL_POENTE := Color("#feae34")
const ESTRELA := Color("#ffffff")
const ESTRELA_FRACA := Color("#8b9bb4")


func _draw_sun(k: float) -> void:
	var c := Vector2(252, floorf(lerpf(62.0, 132.0, k)))
	var cor := SOL_POENTE if k > 0.6 else Color.WHITE
	Sprites.draw_art(self, "fundo/sol", c.x - 24.0, c.y - 24.0, int(t * 4.5) % 16, 16, cor)


## Topo da torre com o tileset de pedra das fases: muro baixo com ameias ao fundo (mais
## escuro) e o piso em lajes.
func _draw_tower_top(k: float) -> void:
	var shade := lerpf(1.0, 0.55, k)
	var claro := Color(shade, shade, shade)
	var fundo := Color(shade * 0.62, shade * 0.62, shade * 0.7)
	var tiles := Sprites.art("tileset_pedra")
	for i in range(-2, 22):
		var x := i * 16.0
		if posmod(i, 2) == 0:
			# ameia: continua o muro (tile de miolo embaixo) e tem contorno em cima e dos
			# lados, sem linha na base (tile 25, topo de coluna)
			_bloco_pedra(tiles, 13, x, FLOOR_Y - 16.0, fundo)
			_bloco_pedra(tiles, 25, x, FLOOR_Y - 32.0, fundo)
		else:
			# vao entre ameias: o muro tem a capa de cima (tile 5)
			_bloco_pedra(tiles, 5, x, FLOOR_Y - 16.0, fundo)
		_bloco_pedra(tiles, 5, x, FLOOR_Y, claro)  # laje do piso
		_bloco_pedra(tiles, 13, x, FLOOR_Y + 16.0, claro)
		_bloco_pedra(tiles, 13, x, FLOOR_Y + 32.0, claro)


func _bloco_pedra(tiles: Texture2D, idx: int, x: float, y: float, cor: Color) -> void:
	draw_texture_rect_region(tiles, Rect2(x, y, 16, 16), Rect2((idx % 4) * 16.0, (idx / 4) * 16.0, 16, 16), cor)


func _draw_nest(k: float) -> void:
	# ninho de 20x8, apoiado no piso (escurece com o piso)
	var shade := lerpf(1.0, 0.7, k)
	Sprites.draw_art(self, "ninho", 260.0, FLOOR_Y - 8.0, 0, 1, Color(shade, shade, shade))


## A Pata (assets/sprites/arte/pata.png: o pato com laco, cilios e bochecha): parada,
## andando e feliz batendo a asa, 16 quadros cada. Pula quando ve o pato.
func _draw_pata(k: float) -> void:
	var x := floorf(pata_x())
	var walking := t > 5.0 and t < 7.0
	var happy := t > 7.0 and t < 9.5
	var hop := 0.0
	if t > 4.2 and t < 4.8:
		hop = -floorf(sin(_phase(4.2, 4.8) * PI) * 8.0)
	# pata.png: 0..15 parada, 16..31 andando, 32..47 feliz (16 quadros por animacao)
	var q := int(t * 8.0) % 16
	if walking:
		q = 16 + int(t * 20.0) % 16
	elif happy:
		q = 32 + int(t * 24.0) % 16
	var face := -1.0 if t < 9.0 else 1.0  # olha para o pato; depois para o sol
	# draw_bicho poe o pivo (os pes) no ponto do deslocamento
	Sprites.draw_bicho(self, "pata", q, 48, PATA_PIVO, face < 0.0, _tinta_bicho(k), Vector2(x, FLOOR_Y + hop))


# --------------------------------------------------------- textos e coracoes
func _draw_overlay() -> void:
	# coracaozinho quando ela ve o pato e coracao grande quando se encontram
	if t > 4.5 and t < 6.5:
		var p := _phase(4.5, 6.5)
		_heart(_overlay, Vector2(pata_x(), FLOOR_Y - 30 - p * 14.0), 1.0 - p)
	if t > 7.0:
		var p := _phase(7.0, 9.0)
		var mid := (DUCK_STOP_X + PATA_STOP_X) * 0.5
		var a := 1.0 if t < 16.0 else 1.0 - _phase(16.0, 18.0)
		_big_heart(_overlay, Vector2(mid, FLOOR_Y - 34 - p * 10.0), p, a)
	if t > 8.3 and t < 11.0:
		var ab := _phase(8.3, 8.9) * (1.0 - _phase(10.3, 10.9))
		_fading_text(Vector2(160, 164), BUQUE_TEXTO[buque], Color.WHITE, ab, 1.0)
	if t > 11.0:
		var a := _phase(11.0, 12.5) * (1.0 - _phase(17.0, 18.0))
		_fading_text(Vector2(160, 164), "JUNTOS, ENFIM.", Color.WHITE, a, 1.0)
	if t > 18.5:
		_fading_text(Vector2(160, 92), "FIM", Color(1, 0.86, 0.3), _phase(18.5, 19.5), 3.0)
	if t > 1.0:
		_dica_pular()


## "ENTER: PULAR" no canto de baixo: sobre as lajes claras do piso o texto sumia, entao vai
## numa faixa escura (#181425, Endesga 32) encostada no canto, em branco opaco com sombra.
## A faixa e opaca (o overlay transforma alfa em quadriculado).
const DICA := "ENTER: PULAR"
const DICA_FUNDO := Color("#181425")
const DICA_SOMBRA := Color("#181425")


func _dica_pular() -> void:
	var w := PixelFont.width(DICA)
	var x := DIR - 4.0
	_overlay.draw_rect(Rect2(floorf(x - w - 3.0), 168.0, DIR - floorf(x - w - 3.0), 180.0 - 168.0), DICA_FUNDO)
	PixelFont.draw_plain(_overlay, x + 1.0, 175.0, DICA, DICA_SOMBRA, PixelFont.RIGHT)
	PixelFont.draw_plain(_overlay, x, 174.0, DICA, Color.WHITE, PixelFont.RIGHT)


## Texto centralizado com sombra que tambem desbota (a sombra da fonte e opaca); no overlay o
## alfa vira dither: o texto some/aparece em quadriculado de 1 px.
func _fading_text(at: Vector2, text: String, col: Color, alpha: float, scale: float) -> void:
	if alpha <= 0.01:
		return
	var sh := Color(PixelFont.SHADOW, alpha)
	PixelFont.draw_plain(_overlay, at.x + scale, at.y + scale, text, sh, PixelFont.CENTER, scale)
	PixelFont.draw_plain(_overlay, at.x, at.y, text, Color(col, alpha), PixelFont.CENTER, scale)


## Coracaozinho (a mesma arte do HUD, 16x16, 1:1) centrado em c.
static func _heart(ci: CanvasItem, c: Vector2, alpha: float) -> void:
	Sprites.draw_frame(ci, "coracao", Rect2(floorf(c.x - 8.0), floorf(c.y - 8.0), 16, 16), 0,
		Color(1, 1, 1, alpha))


## Coracao grande crescendo (p de 0 a 1): o sprite coracao_grande (16 quadros de 32x32,
## sempre 1:1), quadro = p * 15. Sem o PNG ainda, usa o coracaozinho do HUD.
static func _big_heart(ci: CanvasItem, c: Vector2, p: float, alpha: float) -> void:
	if not Sprites.has_art(Sprites.CORACAO_GRANDE):
		_heart(ci, c, alpha)
		return
	Sprites.draw_coracao_grande(ci, c.floor(), clampi(int(p * 15.0), 0, 15), Color(1, 1, 1, alpha))
