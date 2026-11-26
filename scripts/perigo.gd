@tool
extends Node2D
## Area de perigo (agua funda, espinhos, buraco): encostar custa 1 vida e o pato volta ao
## ultimo checkpoint (ou ao inicio da fase). Mesmo esquema do Block: origem no canto INFERIOR
## esquerdo, tamanho em tiles de 16 px. Nao desenha nada no jogo (use tiles/sprites por cima);
## no editor aparece como um retangulo vermelho translucido.

@export var tiles_w: int = 1:
	set(v):
		tiles_w = v
		queue_redraw()
@export var tiles_h: int = 1:
	set(v):
		tiles_h = v
		queue_redraw()
## Invisivel (desenhe por cima com tiles) ou agua animada desenhada aqui mesmo.
@export_enum("Invisível", "Água") var aparencia := 0:
	set(v):
		aparencia = v
		queue_redraw()

const Sprites := preload("res://scripts/sprites.gd")
const COL_WATER_DEEP := Color8(20, 70, 150)

var _time := 0.0


func _ready() -> void:
	add_to_group("hazard")


func _process(delta: float) -> void:
	if aparencia == 1:
		_time += delta
		queue_redraw()


func get_rect() -> Rect2:
	return Rect2(global_position.x, global_position.y - 16.0 * tiles_h,
		16.0 * tiles_w, 16.0 * tiles_h)


func _draw() -> void:
	if aparencia == 1:
		var h := 16.0 * tiles_h
		draw_rect(Rect2(0, -h, 16.0 * tiles_w, h), COL_WATER_DEEP)
		var frame := int(_time * 4.0)
		for i in tiles_w:
			Sprites.draw_frame(self, "agua", Rect2(i * 16.0, -h, 16.0, 16.0), posmod(frame, 4))
		return
	if Engine.is_editor_hint():
		var r := Rect2(0.0, -16.0 * tiles_h, 16.0 * tiles_w, 16.0 * tiles_h)
		draw_rect(r, Color(1, 0, 0, 0.3))
		draw_rect(r, Color(1, 0.2, 0.2, 0.9), false)
