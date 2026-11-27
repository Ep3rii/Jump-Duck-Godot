extends Node2D
## Cutscene inicial (cena "cutscene_inicial"): numa manha na fazenda o pato e a Pata passeiam
## juntos; o Rei Gaviao mergulha do ceu, leva a Pata para a torre e o pato, depois do susto,
## toma coragem e parte para salva-la. Abre o jogo novo (Game.start_new_game) e termina no
## tutorial (Game.finish_intro).
## Cenario: o fundo das fases (parallax.gd, manha, torre ao longe), chao de grama, celeiro,
## cerca e arvore; pato e Pata com a arte do jogo; o Rei Gaviao com a arte do chefe.
## Linha do tempo em segundos (DURATION); ENTER / ESPACO / ESC pulam.

const Sprites := preload("res://scripts/sprites.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")
const PlayerScript := preload("res://scripts/player.gd")
const PixelFx := preload("res://scripts/pixelfx.gd")
const ParallaxScript := preload("res://scripts/parallax.gd")

const DURATION := 16.0
const FLOOR_Y := 176.0  # topo do chao (px do mundo = px da tela: a camera fica parada em 0,0)
const DUCK_START := -20.0
const DUCK_STOP := 150.0
const PATA_GAP := 20.0  # a Pata anda ao lado, um pouco a frente
const PATA_PIVO := Vector2(8, 15)
## Rei Gaviao: chefe_gaviao.png, 80 quadros de 48 (voo 0..15, grito 16..31, mergulho 32..47).
const GAVIAO := "chefe_gaviao"
const GAVIAO_QUADROS := 80
const GAVIAO_PIVO := Vector2(24, 29)
const GAVIAO_INICIO := Vector2(430, -40)
const GAVIAO_SAIDA := Vector2(330, -60)  # para o alto, rumo a torre ao fundo (a direita)
## Pata pendurada nas garras: abaixo do centro do gaviao.
const GARRAS := Vector2(0, 20)

const TEXTOS := [
	[0.6, 4.4, "UMA MANHÃ TRANQUILA NA FAZENDA..."],
	[8.8, 11.2, "O REI GAVIÃO LEVOU A PATA PARA A TORRE!"],
	[11.6, 14.0, "O PATO REUNIU TODA A SUA CORAGEM..."],
	[14.2, 16.0, "...E PARTIU PARA SALVAR A PATA!"],
]

var t := 0.0
var _done := false
var _duck: AnimatedSprite2D
var _overlay: Node2D
var _sfx := {}


func _enter_tree() -> void:
	Game.leave_level()
	Game.room = "cutscene_inicial"
	Game.room_width = Game.TELA.x
	Game.room_height = Game.TELA.y
	Game.cam_pos = Vector2.ZERO
	Game.view_size = Vector2(Game.TELA)


func _ready() -> void:
	if Game.game_state != "cutscene":
		Game.game_state = "cutscene"
	var cam := Camera2D.new()
	cam.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(cam)
	cam.make_current()
	# o mesmo fundo das fases de ceu aberto: manha, torre do gaviao ao longe
	var fundo := ParallaxScript.new()
	fundo.hora = 0
	fundo.mostrar_torre = true
	fundo.torre_distancia = 0
	fundo.mostrar_celeiro = false
	fundo.z_index = -10
	add_child(fundo)
	var anims := PlayerScript.ART_ANIMS.duplicate()
	anims["coragem"] = ["res://assets/sprites/arte/pato_coragem.png", 16, 12.0, false]
	_duck = Sprites.make_art_sprite(Sprites.art_frames(anims), PlayerScript.ART_ORIGIN)
	_duck.position = Vector2(DUCK_START, FLOOR_Y)
	_duck.z_index = 5
	_duck.play("run")
	add_child(_duck)
	_overlay = Node2D.new()
	_overlay.z_index = 20
	_overlay.material = PixelFx.material_dither()  # textos desbotam em quadriculado
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)


# ------------------------------------------------------------- linha do tempo
func _phase(a: float, b: float) -> float:
	return clampf((t - a) / (b - a), 0.0, 1.0)


func duck_x() -> float:
	var x := lerpf(DUCK_START, DUCK_STOP, _phase(0.3, 4.4))
	x += 70.0 * _phase(7.2, 8.4)  # corre atras do gaviao e para
	x += 260.0 * _phase(14.0, 15.6)  # parte para a aventura
	return x


func duck_anim() -> String:
	if t < 4.4 or (t > 7.2 and t < 8.4) or t > 14.0:
		return "run"
	if t > 5.6 and t < 7.2:
		return "look_up"  # o susto: olha o gaviao chegando
	if t > 8.4 and t < 11.4:
		return "look_up"  # olha a torre la longe
	if t >= 11.4:
		return "coragem"
	return "idle"


## A Pata: anda junto ate 4,4 s; dai e agarrada (6,6 s) e levada pelo gaviao.
func pata_pos() -> Vector2:
	if t < 6.6:
		return Vector2(floorf(lerpf(DUCK_START, DUCK_STOP, _phase(0.3, 4.4)) + PATA_GAP), FLOOR_Y)
	return gaviao_pos() + GARRAS


func gaviao_pos() -> Vector2:
	var alvo := Vector2(DUCK_STOP + PATA_GAP, FLOOR_Y - GARRAS.y)
	if t < 6.6:
		var k := _phase(5.4, 6.6)
		return GAVIAO_INICIO.lerp(alvo, k * k).floor()  # mergulho acelerando
	if t < 7.1:
		return alvo  # agarra (asas abertas, gritando)
	var s := _phase(7.1, 8.8)
	var p := alvo.lerp(GAVIAO_SAIDA, s)
	p.y -= sin(s * PI) * 30.0  # sobe em arco
	return p.floor()


func _process(delta: float) -> void:
	if _done:
		return
	t += delta
	_duck.position.x = floorf(duck_x())
	var a := duck_anim()
	if _duck.animation != a:
		_duck.play(a)
	_som(4.6, "life")
	_som(5.4, "screech")
	_som(6.6, "swoop")
	_som(11.4, "checkpoint")
	var skip := t > 0.5 and (Input.is_action_just_pressed("confirm")
		or Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("jump"))
	if t >= DURATION or skip:
		_finish()
		return
	queue_redraw()
	_overlay.queue_redraw()


func _som(em: float, nome: String) -> void:
	if t >= em and not _sfx.has(em):
		_sfx[em] = true
		Game.play_sfx(nome)


func _finish() -> void:
	if _done:
		return
	_done = true
	Game.finish_intro()


# ------------------------------------------------------------------- desenho
func _draw() -> void:
	_draw_cenario()
	_draw_pata()
	_draw_gaviao()


func _draw_cenario() -> void:
	# celeiro, arvore e cerca da fazenda, atras do casal
	Sprites.draw_art(self, "cenario/celeiro", 8.0, FLOOR_Y - Sprites.art_size("cenario/celeiro").y)
	# tronco e copa sao do mesmo tamanho e vao no mesmo ponto (como decoracao.gd)
	var arv := Sprites.art_size("cenario/arvore_copa")
	Sprites.draw_art(self, "cenario/arvore_tronco", 300.0, FLOOR_Y - arv.y)
	Sprites.draw_art(self, "cenario/arvore_copa", 300.0, FLOOR_Y - arv.y)
	var cerca := Sprites.art_size("cenario/cerca")
	for i in 3:
		Sprites.draw_art(self, "cenario/cerca", 200.0 + i * 32.0, FLOOR_Y - cerca.y, i, 3)
	# chao de grama do tileset (topo na linha 1, terra na 3)
	var tiles := Sprites.art("tileset_grama")
	if tiles == null:
		return
	for x in range(0, Game.TELA.x + 16, 16):
		draw_texture_rect_region(tiles, Rect2(x, FLOOR_Y, 16, 16), Rect2(16, 16, 16, 16))
		for y in range(int(FLOOR_Y) + 16, Game.TELA.y + 16, 16):
			draw_texture_rect_region(tiles, Rect2(x, y, 16, 16), Rect2(16, 48, 16, 16))


func _draw_pata() -> void:
	var p := pata_pos()
	# pata.png: 0..15 parada, 16..31 andando, 32..47 feliz
	var q := int(t * 8.0) % 16
	if t < 4.4:
		q = 16 + int(t * 20.0) % 16
	elif t < 5.4:
		q = 32 + int(t * 24.0) % 16  # feliz ao lado do pato
	elif t >= 6.6:
		q = 16 + int(t * 30.0) % 16  # esperneando nas garras
	var olha_esq := t > 4.6 and t < 6.6  # vira para o pato antes do mergulho
	Sprites.draw_bicho(self, "pata", q, 48, PATA_PIVO, olha_esq, Color.WHITE, p)


func _draw_gaviao() -> void:
	if t < 5.4 or t > 8.9:
		return
	var tex := Sprites.art(GAVIAO)
	if tex == null:
		return
	var fw := tex.get_width() / float(GAVIAO_QUADROS)
	var fh := fw
	var q: int
	if t < 6.6:
		q = 32 + mini(11, int(_phase(5.4, 6.6) * 12.0))  # mergulho: a asa fecha
	elif t < 7.1:
		q = 16 + int(t * 16.0) % 16  # grito com a Pata nas garras
	else:
		q = int(t * 14.0) % 16  # voo
	var esquerda := t < 7.1  # desce vindo da direita; sobe indo para a torre (direita)
	var pivo := GAVIAO_PIVO * (fw / 48.0)
	draw_set_transform(gaviao_pos(), 0.0, Vector2(-1, 1) if esquerda else Vector2.ONE)
	draw_texture_rect_region(tex, Rect2(-pivo, Vector2(fw, fh)), Rect2(q * fw, 0, fw, fh))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_overlay() -> void:
	# o susto: "!" amarelo sobre o pato
	if t > 5.6 and t < 7.2:
		var pulo := floorf(absf(sin(t * 10.0)) * 2.0)
		PixelFont.draw_plain(_overlay, duck_x() + 1.0, FLOOR_Y - 26.0 - pulo + 1.0, "!", PixelFont.SHADOW, PixelFont.CENTER, 2.0)
		PixelFont.draw_plain(_overlay, duck_x(), FLOOR_Y - 26.0 - pulo, "!", Color("#fee761"), PixelFont.CENTER, 2.0)
	for tx: Array in TEXTOS:
		if t > tx[0] and t < tx[1]:
			var a := _phase(tx[0], tx[0] + 0.5) * (1.0 - _phase(tx[1] - 0.5, tx[1]))
			_texto(Vector2(Game.TELA.x * 0.5, 40.0), tx[2], a)
	if t > 1.0:
		var dica := "ENTER: PULAR"
		var x := Game.TELA.x - 4.0
		var w := PixelFont.width(dica)
		_overlay.draw_rect(Rect2(floorf(x - w - 3.0), Game.TELA.y - 12.0, w + 7.0, 12.0), Color("#181425"))
		PixelFont.draw_plain(_overlay, x, Game.TELA.y - 6.0, dica, Color.WHITE, PixelFont.RIGHT)


## Texto centralizado numa faixa escura (le contra o ceu), desbotando em quadriculado.
func _texto(at: Vector2, s: String, alpha: float) -> void:
	if alpha <= 0.01:
		return
	var w := PixelFont.width(s)
	_overlay.draw_rect(Rect2(floorf(at.x - w * 0.5 - 6.0), at.y - 8.0, w + 12.0, 16.0), Color(Color("#193c3e"), alpha))
	PixelFont.draw_plain(_overlay, at.x + 1.0, at.y + 1.0, s, Color(PixelFont.SHADOW, alpha), PixelFont.CENTER)
	PixelFont.draw_plain(_overlay, at.x, at.y, s, Color(Color.WHITE, alpha), PixelFont.CENTER)
