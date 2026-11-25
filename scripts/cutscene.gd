extends Node2D
## Cutscene final (cena "cutscene_final"): no topo da torre o pato encontra a Pata e os dois
## olham o por do sol. Tudo desenhado em codigo (provisorio ate existir a arte): ceu, sol,
## montanhas, o alto da torre, o ninho e a Pata; o pato usa os sprites do jogador.
## Linha do tempo em segundos (DURATION no total); ENTER / ESPACO / ESC pulam.
## No fim chama Game.finish_ending() (vai para os creditos).

const Sprites := preload("res://scripts/sprites.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")

const DURATION := 22.0
const FLOOR_Y := 140.0
const DUCK_STOP_X := 150.0
const PATA_START_X := 262.0
const PATA_STOP_X := 168.0
const PATA_SCALE := 0.7  # a Pata do tamanho do pato

const SKY_TOP_DAY := Color8(250, 150, 96)
const SKY_TOP_NIGHT := Color8(54, 36, 88)
const SKY_LOW_DAY := Color8(255, 206, 120)
const SKY_LOW_NIGHT := Color8(196, 88, 96)
const SUN := Color8(255, 224, 120)
const STONE := Color8(150, 140, 160)
const STONE_DARK := Color8(100, 92, 116)
const TWIG := Color8(120, 78, 40)
const TWIG_DARK := Color8(80, 50, 24)
const PATA_BODY := Color8(250, 250, 244)
const PATA_SHADE := Color8(214, 214, 206)
const PATA_OUT := Color8(60, 50, 50)
const BEAK := Color8(250, 160, 40)
const BOW := Color8(240, 90, 140)
const HEART := Color8(240, 60, 80)

var t := 0.0
var _done := false
var _duck: AnimatedSprite2D
var _overlay: Node2D
var _sfx_heart := false
var _sfx_love := false


func _enter_tree() -> void:
	Game.leave_level()
	Game.room = "cutscene_final"
	Game.room_width = 320
	Game.room_height = 180
	Game.cam_pos = Vector2.ZERO


func _ready() -> void:
	if Game.game_state != "cutscene":
		Game.game_state = "cutscene"
	_duck = AnimatedSprite2D.new()
	_duck.sprite_frames = load("res://assets/frames/player.tres")
	_duck.centered = false
	_duck.offset = Vector2(-16, -23)
	_duck.position = Vector2(-16, FLOOR_Y)
	_duck.play("run")
	add_child(_duck)
	_overlay = Node2D.new()
	_overlay.z_index = 10
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


func _process(delta: float) -> void:
	if _done:
		return
	t += delta
	_duck.position.x = floorf(duck_x())
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
	var k := sunset()
	_draw_sky(k)
	_draw_stars(k)
	_draw_sun(k)
	var dusk := Color(lerpf(0.75, 0.35, k), lerpf(0.5, 0.25, k), lerpf(0.7, 0.45, k))
	Sprites.draw(self, "spr_bgMontanhas", 0, 0.0, 154.0, 1.0, 1.0, dusk)
	var clouds := Color(1.0, lerpf(0.75, 0.45, k), lerpf(0.8, 0.6, k), 0.8)
	Sprites.draw(self, "spr_bgNuvens", 0, floorf(-40.0 + t * 2.0), 22.0, 1.0, 1.0, clouds)
	Sprites.draw(self, "spr_bgNuvens", 0, floorf(150.0 + t * 1.2), 46.0, 1.0, 1.0, clouds)
	_draw_tower_top(k)
	_draw_nest()
	_draw_pata()


func _draw_sky(k: float) -> void:
	var top := SKY_TOP_DAY.lerp(SKY_TOP_NIGHT, k)
	var low := SKY_LOW_DAY.lerp(SKY_LOW_NIGHT, k)
	for i in 18:
		draw_rect(Rect2(0, i * 10, 320, 10), top.lerp(low, i / 17.0))


func _draw_stars(k: float) -> void:
	var a := clampf((k - 0.5) * 2.0, 0.0, 1.0)
	if a <= 0.0:
		return
	for i in 24:
		var x := fposmod(i * 67.0 + 13.0, 320.0)
		var y := fposmod(i * 29.0 + 7.0, 90.0)
		var tw := 0.6 + 0.4 * sin(t * 3.0 + i)
		draw_rect(Rect2(floorf(x), floorf(y), 1, 1), Color(1, 1, 0.9, a * tw))


func _draw_sun(k: float) -> void:
	var c := Vector2(252, lerpf(62.0, 132.0, k))
	draw_circle(c, 30.0, Color(SUN, 0.18))
	draw_circle(c, 23.0, Color(SUN, 0.3))
	draw_circle(c, 18.0, SUN.lerp(Color8(255, 140, 80), k))


func _draw_tower_top(k: float) -> void:
	var shade := lerpf(1.0, 0.55, k)
	var stone := Color(STONE.r * shade, STONE.g * shade, STONE.b * shade)
	var dark := Color(STONE_DARK.r * shade, STONE_DARK.g * shade, STONE_DARK.b * shade)
	# muro baixo do fundo (com ameias) e o piso do topo da torre
	draw_rect(Rect2(0, FLOOR_Y - 10, 320, 10), dark)
	for i in 14:
		draw_rect(Rect2(i * 24 + 4, FLOOR_Y - 18, 12, 8), dark)
	draw_rect(Rect2(0, FLOOR_Y, 320, 40), stone)
	draw_rect(Rect2(0, FLOOR_Y, 320, 2), Color(1, 1, 1, 0.25 * shade))
	for row in 5:
		var off := 8.0 if row % 2 == 1 else 0.0
		for c in 21:
			draw_rect(Rect2(c * 16 - off, FLOOR_Y + 2 + row * 8, 1, 8), dark)
		draw_rect(Rect2(0, FLOOR_Y + 9 + row * 8, 320, 1), dark)


func _draw_nest() -> void:
	var cx := 270.0
	for i in 9:
		var y := FLOOR_Y - 2.0 - (i % 3) * 2.0
		var x := cx - 18.0 + i * 4.0
		draw_rect(Rect2(x, y, 7, 2), TWIG if i % 2 == 0 else TWIG_DARK)
	draw_rect(Rect2(cx - 16, FLOOR_Y - 1, 32, 1), TWIG_DARK)


## A Pata: pata branca com laco rosa e cilios; pula quando ve o pato e vem andando.
func _draw_pata() -> void:
	var x := floorf(pata_x())
	var walking := t > 5.0 and t < 7.0
	var hop := 0.0
	if t > 4.2 and t < 4.8:
		hop = -floorf(sin(_phase(4.2, 4.8) * PI) * 8.0)
	elif walking:
		hop = -floorf(absf(sin(t * 10.0)) * 2.0)
	var face := -1.0 if t < 9.0 else 1.0  # olha para o pato; depois para o sol
	var y := FLOOR_Y + hop
	# do tamanho do pato: desenha reduzida a partir dos pes
	var k := PATA_SCALE
	draw_set_transform(Vector2(x * (1.0 - k), FLOOR_Y * (1.0 - k)), 0.0, Vector2(k, k))
	# pes: ciclo de 4 quadros andando (passo, junto, outro passo, junto)
	var frame := int(t * 10.0) % 4 if walking else 1
	var step: float = [2.0, 0.0, -2.0, 0.0][frame]
	draw_rect(Rect2(x - 4 + step, y - 2, 3, 2), BEAK)
	draw_rect(Rect2(x + 1 - step, y - 2, 3, 2), BEAK)
	if walking and frame % 2 == 0:
		y -= 1.0  # sobe um pouco a cada passo
	# corpo
	draw_rect(Rect2(x - 8, y - 12, 15, 11), PATA_OUT)
	draw_rect(Rect2(x - 7, y - 11, 13, 9), PATA_BODY)
	draw_rect(Rect2(x - 7, y - 5, 13, 3), PATA_SHADE)
	# asa (bate de alegria quando encontra o pato)
	var happy := t > 7.0 and t < 9.5
	var flap := -2.0 if happy and int(t * 12.0) % 2 == 0 else 0.0
	draw_rect(Rect2(x - 3 * face - 2, y - 9 + flap, 6, 4), PATA_SHADE)
	if flap < 0.0:
		draw_rect(Rect2(x - 3 * face - 3, y - 11, 3, 2), PATA_BODY)
	# cauda
	var tail := x - 9.0 if face > 0 else x + 6.0
	draw_rect(Rect2(tail, y - 12, 3, 3), PATA_OUT)
	# cabeca
	var hx := x + (2.0 if face > 0 else -9.0)
	draw_rect(Rect2(hx, y - 20, 8, 9), PATA_OUT)
	draw_rect(Rect2(hx + 1, y - 19, 6, 7), PATA_BODY)
	# bico, olho e cilios
	var bx := hx + 7.0 if face > 0 else hx - 3.0
	draw_rect(Rect2(bx, y - 15, 4, 2), BEAK)
	var ex := hx + (4.0 if face > 0 else 2.0)
	var blink := fposmod(t, 2.6) < 0.12
	if blink:
		draw_rect(Rect2(ex, y - 16, 2, 1), PATA_OUT)
	elif happy:  # olhinho feliz (arco)
		draw_rect(Rect2(ex, y - 16, 2, 1), PATA_OUT)
		draw_rect(Rect2(ex, y - 17, 1, 1), PATA_OUT)
	else:
		draw_rect(Rect2(ex, y - 17, 2, 2), PATA_OUT)
	# bochecha rosada
	draw_rect(Rect2(ex + (1.0 if face < 0 else -1.0), y - 14, 2, 1), Color8(255, 170, 190))
	draw_rect(Rect2(ex - 1 if face > 0 else ex + 1, y - 19, 1, 1), PATA_OUT)
	draw_rect(Rect2(ex + 1 if face > 0 else ex, y - 19, 1, 1), PATA_OUT)
	# laco rosa
	var lx := hx + (1.0 if face > 0 else 3.0)
	draw_rect(Rect2(lx - 2, y - 23, 3, 3), BOW)
	draw_rect(Rect2(lx + 2, y - 23, 3, 3), BOW)
	draw_rect(Rect2(lx + 1, y - 22, 1, 1), Color8(170, 40, 90))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# --------------------------------------------------------- textos e coracoes
func _draw_overlay() -> void:
	# coracaozinho quando ela ve o pato e coracao grande quando se encontram
	if t > 4.5 and t < 6.5:
		var p := _phase(4.5, 6.5)
		_heart(_overlay, Vector2(pata_x(), FLOOR_Y - 30 - p * 14.0), 1.0, 1.0 - p)
	if t > 7.0:
		var p := _phase(7.0, 9.0)
		var mid := (DUCK_STOP_X + PATA_STOP_X) * 0.5
		var a := 1.0 if t < 16.0 else 1.0 - _phase(16.0, 18.0)
		_heart(_overlay, Vector2(mid, FLOOR_Y - 34 - p * 10.0), 1.0 + p, a)
	if t > 11.0:
		var a := _phase(11.0, 12.5) * (1.0 - _phase(17.0, 18.0))
		_fading_text(Vector2(160, 164), "JUNTOS, ENFIM.", Color.WHITE, a, 1.0)
	if t > 18.5:
		_fading_text(Vector2(160, 92), "FIM", Color(1, 0.86, 0.3), _phase(18.5, 19.5), 3.0)
	if t > 1.0:
		PixelFont.draw_plain(_overlay, 316, 174, "ENTER: PULAR", Color(1, 1, 1, 0.5), PixelFont.RIGHT)


## Texto centralizado com sombra que tambem desbota (a sombra da fonte e opaca).
func _fading_text(at: Vector2, text: String, col: Color, alpha: float, scale: float) -> void:
	if alpha <= 0.01:
		return
	var sh := Color(PixelFont.SHADOW, alpha)
	PixelFont.draw_plain(_overlay, at.x + scale, at.y + scale, text, sh, PixelFont.CENTER, scale)
	PixelFont.draw_plain(_overlay, at.x, at.y, text, Color(col, alpha), PixelFont.CENTER, scale)


## Coracao de pixels (9x8 vezes a escala) centrado em c.
static func _heart(ci: CanvasItem, c: Vector2, scale: float, alpha: float) -> void:
	var rows := ["011000110", "111101111", "111111111", "111111111", "011111110", "001111100",
		"000111000", "000010000"]
	var s := floorf(scale)
	if s < 1.0:
		s = 1.0
	var col := Color(HEART, alpha)
	var x0 := floorf(c.x - 4.5 * s)
	var y0 := floorf(c.y - 4.0 * s)
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] == "1":
				ci.draw_rect(Rect2(x0 + x * s, y0 + y * s, s, s), col)
