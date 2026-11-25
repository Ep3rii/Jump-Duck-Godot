@tool
extends Node2D
## obj_blocoPiso01: bloco solido. No GameMaker a origem fica no canto INFERIOR esquerdo
## e image_xscale/image_yscale dizem quantos tiles de 16 px ele ocupa; aqui sao
## tiles_w / tiles_h. Ocupa [x, x + 16*w) x [y - 16*h, y).

@export var tiles_w: int = 1:
	set(v):
		tiles_w = v
		queue_redraw()
@export var tiles_h: int = 1:
	set(v):
		tiles_h = v
		queue_redraw()

const TEX := preload("res://assets/sprites/spr_objBPiso01.png")


func _ready() -> void:
	add_to_group("solid")


func get_rect() -> Rect2:
	return Rect2(global_position.x, global_position.y - 16.0 * tiles_h,
		16.0 * tiles_w, 16.0 * tiles_h)


func _draw() -> void:
	draw_texture_rect(TEX, Rect2(0.0, -16.0 * tiles_h, 16.0 * tiles_w, 16.0 * tiles_h), true)
