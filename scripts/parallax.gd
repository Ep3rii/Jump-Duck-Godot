extends Node2D
## obj_parallax: ceu, sol, nuvens, montanhas e colinas em paralaxe atras de tudo.
## Desenha relativo ao canto superior esquerdo da camera (Game.cam_pos).
## Com mostrar_torre, a torre do gaviao aparece ao longe e "chega mais perto" conforme o
## pato avanca na fase (fases do caminho ate a torre).

const Sprites := preload("res://scripts/sprites.gd")

const VIEW_W := 320.0
const VIEW_H := 180.0

const TOWER := Color8(120, 130, 160)
const TOWER_DARK := Color8(96, 104, 136)
const TOWER_ROOF := Color8(110, 80, 110)
const TOWER_WINDOW := Color8(255, 220, 120)

## Torre do gaviao ao fundo (silhueta azulada, perto das montanhas).
@export var mostrar_torre := false
## Ceu aberto (fazenda e caminho) ou parede de pedra por dentro da torre (Fases 4 a 8).
@export_enum("Céu", "Torre por dentro") var cenario := 0

const WALL_MORTAR := Color8(30, 27, 42)
const WALL_BRICK := Color8(54, 50, 72)
const WALL_BRICK_HI := Color8(64, 60, 84)
const WALL_BRICK_LO := Color8(46, 42, 62)
const WINDOW_FRAME := Color8(28, 24, 38)
const WINDOW_SKY := Color8(120, 190, 240)
const WINDOW_SKY_LOW := Color8(180, 220, 245)
const TORCH_FIRE := Color8(255, 170, 60)
const TORCH_CORE := Color8(255, 236, 140)

## Tempo proprio (para de contar quando o jogo pausa; as nuvens nao "pulam" ao despausar).
var _time_ms := 0.0


func _process(delta: float) -> void:
	_time_ms += delta * 1000.0
	queue_redraw()


func _draw() -> void:
	var vx := floorf(Game.cam_pos.x)
	var vy := floorf(Game.cam_pos.y)
	var vw := VIEW_W
	var vh := VIEW_H
	var now := _time_ms
	if cenario == 1:
		_draw_tower_inside(vx, vy, now)
		return

	draw_texture_rect(Sprites.tex("spr_bgCeu", 0), Rect2(vx, vy, vw, vh), false)
	Sprites.draw(self, "spr_bgSol", 0, vx + vw - 56.0, vy + 34.0)

	var drift := now * 0.004
	var cw := 192.0  # largura de spr_bgNuvens
	var x := vx - fposmod(vx * 0.12 + drift, cw)
	while x < vx + vw:
		Sprites.draw(self, "spr_bgNuvens", 0, floorf(x), vy + 10.0)
		x += cw
	x = vx - fposmod(vx * 0.2 + drift * 1.6 + 96.0, cw)
	while x < vx + vw:
		Sprites.draw(self, "spr_bgNuvens", 0, floorf(x), vy + 52.0, 1.0, 1.0, Color(1, 1, 1, 0.75))
		x += cw

	var far_bottom := vy + vh + (Game.room_height - vh - vy) * 0.4
	var near_bottom := vy + vh + (Game.room_height - vh - vy) * 0.75
	var hw := 320.0  # largura de spr_bgMontanhas / spr_bgColinas

	x = vx - fposmod(vx * 0.2, hw)
	while x < vx + vw:
		Sprites.draw(self, "spr_bgMontanhas", 0, floorf(x), floorf(far_bottom))
		x += hw
	if mostrar_torre:
		_draw_tower(vx, floorf(far_bottom))
	x = vx - fposmod(vx * 0.45, hw)
	while x < vx + vw:
		Sprites.draw(self, "spr_bgColinas", 0, floorf(x), floorf(near_bottom))
		x += hw


## Torre ao longe: na tela vai de x~300 (inicio da fase) ate x~210 (fim da fase).
func _draw_tower(vx: float, bottom: float) -> void:
	var progress := clampf(vx / maxf(1.0, Game.room_width - VIEW_W), 0.0, 1.0)
	var cx := floorf(vx + 300.0 - 90.0 * progress)
	var w := 22.0
	var h := 118.0
	var top := bottom - h
	draw_rect(Rect2(cx - w * 0.5, top, w, h), TOWER)
	draw_rect(Rect2(cx + 3, top, w * 0.5 - 3, h), TOWER_DARK)
	# ameias
	for i in 4:
		draw_rect(Rect2(cx - w * 0.5 - 2 + i * 7, top - 4, 4, 4), TOWER)
	draw_rect(Rect2(cx - w * 0.5 - 2, top, w + 4, 3), TOWER_DARK)
	# telhado pontudo
	for i in 9:
		var half := 10.0 - i * 1.1
		draw_rect(Rect2(cx - half, top - 6 - i * 2.0, half * 2, 2), TOWER_ROOF)
	# janelas (a de cima acesa: e onde a Pata esta)
	draw_rect(Rect2(cx - 2, top + 8, 4, 6), TOWER_WINDOW)
	for i in 3:
		draw_rect(Rect2(cx - 1, top + 34 + i * 26, 2, 5), TOWER_DARK)


# ------------------------------------------------- por dentro da torre
## Parede de tijolos ao fundo (anda na metade da velocidade da camera), com janelas em arco
## mostrando o ceu e tochas entre elas.
func _draw_tower_inside(vx: float, vy: float, now: float) -> void:
	draw_rect(Rect2(vx, vy, VIEW_W, VIEW_H), WALL_MORTAR)
	var ox := vx * 0.5
	var oy := vy * 0.5
	var row0 := floori(oy / 8.0)
	for r in range(row0, row0 + 24):
		var sy := r * 8.0 - oy
		var shift := 8.0 if posmod(r, 2) == 1 else 0.0
		var col0 := floori((ox - shift) / 16.0)
		for c in range(col0, col0 + 22):
			var sx := c * 16.0 + shift - ox
			var h := posmod(c * 31 + r * 17, 7)
			var col := WALL_BRICK_HI if h == 0 else (WALL_BRICK_LO if h == 3 else WALL_BRICK)
			draw_rect(Rect2(vx + floorf(sx) + 1, vy + floorf(sy) + 1, 14, 6), col)
	# janelas a cada 160 x 144 px do fundo; tochas no meio do caminho
	var wc0 := floori((ox - 40.0) / 160.0)
	var wr0 := floori((oy - 60.0) / 144.0)
	for wr in range(wr0, wr0 + 3):
		for wc in range(wc0, wc0 + 4):
			var wx := vx + floorf(wc * 160.0 + 60.0 - ox)
			var wy := vy + floorf(wr * 144.0 + 40.0 - oy)
			_window(wx, wy)
			_torch(wx + 80.0, wy + 30.0, now)


func _window(x: float, y: float) -> void:
	draw_rect(Rect2(x - 2, y - 2, 24, 40), WINDOW_FRAME)
	draw_rect(Rect2(x, y + 4, 20, 32), WINDOW_SKY)
	draw_rect(Rect2(x, y + 24, 20, 12), WINDOW_SKY_LOW)
	# arco
	draw_rect(Rect2(x + 3, y + 1, 14, 3), WINDOW_SKY)
	draw_rect(Rect2(x + 6, y - 1, 8, 2), WINDOW_SKY)
	# grade
	draw_rect(Rect2(x + 9, y, 2, 36), WINDOW_FRAME)
	draw_rect(Rect2(x, y + 18, 20, 2), WINDOW_FRAME)


func _torch(x: float, y: float, now: float) -> void:
	draw_rect(Rect2(x - 1, y, 3, 8), Color8(90, 60, 30))
	draw_rect(Rect2(x - 3, y - 1, 7, 2), Color8(60, 60, 70))
	var flick := floorf(sin(now * 0.02 + x) * 1.5)
	draw_rect(Rect2(x - 2, y - 6 + flick, 5, 5), TORCH_FIRE)
	draw_rect(Rect2(x - 1, y - 4 + flick, 3, 3), TORCH_CORE)
