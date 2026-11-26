extends Node2D
## Cutscene final (cena "cutscene_final"): no topo da torre o pato encontra a Pata e os dois
## olham o por do sol. Tudo desenhado em codigo (provisorio ate existir a arte): ceu, sol,
## montanhas, o alto da torre, o ninho e a Pata; o pato usa os sprites do jogador.
## Linha do tempo em segundos (DURATION no total); ENTER / ESPACO / ESC pulam.
## No fim chama Game.finish_ending() (vai para os creditos).

const Sprites := preload("res://scripts/sprites.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")
const PlayerScript := preload("res://scripts/player.gd")

const DURATION := 22.0
const FLOOR_Y := 140.0
const DUCK_STOP_X := 150.0
const PATA_START_X := 262.0
const PATA_STOP_X := 168.0
const PATA_PIVO := Vector2(8, 15.5)  # pes da Pata no quadro de 32 px (como o pato)

const SKY_TOP_DAY := Color8(250, 150, 96)
const SKY_TOP_NIGHT := Color8(54, 36, 88)
const SKY_LOW_DAY := Color8(255, 206, 120)
const SKY_LOW_NIGHT := Color8(196, 88, 96)

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
	# o pato com a arte nova (as mesmas animacoes do jogador)
	_duck = Sprites.make_art_sprite(Sprites.art_frames(PlayerScript.ART_ANIMS), PlayerScript.ART_ORIGIN)
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
	Sprites.draw_art(self, "fundo/montanhas", 0.0, 24.0, 0, 1, dusk)
	var clouds := Color(1.0, lerpf(0.75, 0.45, k), lerpf(0.8, 0.6, k), 0.8)
	Sprites.draw_art(self, "fundo/nuvem_grande", floorf(-40.0 + t * 2.0), 14.0, 0, 1, clouds)
	Sprites.draw_art(self, "fundo/nuvem_media", floorf(150.0 + t * 1.2), 38.0, 0, 1, clouds)
	_draw_tower_top(k)
	_draw_nest()
	_draw_pata()


func _draw_sky(k: float) -> void:
	# 6 faixas chapadas (como o ceu das fases), do alto para o horizonte
	var top := SKY_TOP_DAY.lerp(SKY_TOP_NIGHT, k)
	var low := SKY_LOW_DAY.lerp(SKY_LOW_NIGHT, k)
	for i in 6:
		draw_rect(Rect2(0, i * 30, 320, 30), top.lerp(low, i / 5.0))


func _draw_stars(k: float) -> void:
	var a := clampf((k - 0.5) * 2.0, 0.0, 1.0)
	if a <= 0.0:
		return
	for i in 24:
		var x := fposmod(i * 67.0 + 13.0, 320.0)
		var y := fposmod(i * 29.0 + 7.0, 90.0)
		var tw := 0.6 + 0.4 * sin(t * 3.0 + i)
		draw_rect(Rect2(floorf(x), floorf(y), 1, 1), Color(1, 1, 0.9, a * tw))


## Sol da arte dos fundos (2 quadros), descendo e ficando laranja.
func _draw_sun(k: float) -> void:
	var c := Vector2(252, floorf(lerpf(62.0, 132.0, k)))
	var cor := Color.WHITE.lerp(Color(1.0, 0.62, 0.4), k)
	Sprites.draw_art(self, "fundo/sol", c.x - 24.0, c.y - 24.0, int(t * 1.2) % 2, 2, cor)


## Topo da torre com o tileset de pedra das fases: muro baixo com ameias ao fundo (mais
## escuro) e o piso em lajes.
func _draw_tower_top(k: float) -> void:
	var shade := lerpf(1.0, 0.55, k)
	var claro := Color(shade, shade, shade)
	var fundo := Color(shade * 0.62, shade * 0.62, shade * 0.7)
	var tiles := Sprites.art("tileset_pedra")
	for i in 20:
		var x := i * 16.0
		_bloco_pedra(tiles, 13, x, FLOOR_Y - 16.0, fundo)  # muro
		if i % 2 == 0:
			_bloco_pedra(tiles, 7, x, FLOOR_Y - 32.0, fundo)  # ameia
		_bloco_pedra(tiles, 5, x, FLOOR_Y, claro)  # laje do piso
		_bloco_pedra(tiles, 13, x, FLOOR_Y + 16.0, claro)
		_bloco_pedra(tiles, 13, x, FLOOR_Y + 32.0, claro)


func _bloco_pedra(tiles: Texture2D, idx: int, x: float, y: float, cor: Color) -> void:
	draw_texture_rect_region(tiles, Rect2(x, y, 16, 16), Rect2((idx % 4) * 32.0, (idx / 4) * 32.0, 32, 32), cor)


func _draw_nest() -> void:
	# ninho de 20x8, apoiado no piso
	Sprites.draw_art(self, "ninho", 260.0, FLOOR_Y - 8.0)


## A Pata (assets/sprites/arte/pata.png: o pato aprovado com laco, cilios e bochecha):
## parada, andando (8 quadros) e feliz batendo a asa (2). Pula quando ve o pato.
func _draw_pata() -> void:
	var x := floorf(pata_x())
	var walking := t > 5.0 and t < 7.0
	var happy := t > 7.0 and t < 9.5
	var hop := 0.0
	if t > 4.2 and t < 4.8:
		hop = -floorf(sin(_phase(4.2, 4.8) * PI) * 8.0)
	var q := 0
	if walking:
		q = 1 + int(t * 10.0) % 8
	elif happy:
		q = 9 + int(t * 12.0) % 2
	var face := -1.0 if t < 9.0 else 1.0  # olha para o pato; depois para o sol
	# draw_bicho poe o pivo (os pes) no ponto do deslocamento
	Sprites.draw_bicho(self, "pata", q, 11, PATA_PIVO, face < 0.0, Color.WHITE, Vector2(x, FLOOR_Y + hop))


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


## Coracao (a mesma arte do HUD, 16 px vezes a escala) centrado em c.
static func _heart(ci: CanvasItem, c: Vector2, scale: float, alpha: float) -> void:
	var s := maxf(1.0, floorf(scale))
	var lado := 16.0 * s
	Sprites.draw_frame(ci, "coracao", Rect2(floorf(c.x - lado * 0.5), floorf(c.y - lado * 0.5), lado, lado), 0,
		Color(1, 1, 1, alpha))
