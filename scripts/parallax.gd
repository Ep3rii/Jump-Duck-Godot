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
