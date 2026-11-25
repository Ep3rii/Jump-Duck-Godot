extends Node2D
## obj_parallax: ceu, sol, nuvens, montanhas e colinas em paralaxe atras de tudo.
## Desenha relativo ao canto superior esquerdo da camera (Game.cam_pos).

const Sprites := preload("res://scripts/sprites.gd")

const VIEW_W := 320.0
const VIEW_H := 180.0


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
	x = vx - fposmod(vx * 0.45, hw)
	while x < vx + vw:
		Sprites.draw(self, "spr_bgColinas", 0, floorf(x), floorf(near_bottom))
		x += hw
