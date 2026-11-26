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
## Fundo da agua e os tracinhos dele: cores da ENDESGA 32 (a paleta da arte).
const COL_WATER_DEEP := Color("#124e89")
const COL_WATER_LINE := Color("#0099db")

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
		# tracinhos horizontais parados no fundo (presos ao tile), para nao ficar chapado
		var linha := 0
		var y := -h + 22.0
		while y < -1.0:
			for i in tiles_w:
				var x := float((i * 7 + linha * 3) % 13)
				draw_rect(Rect2(i * 16.0 + x, y, 3.0, 1.0), COL_WATER_LINE)
			y += 8.0
			linha += 1
		var frame := int(_time * 16.0)
		for i in tiles_w:
			Sprites.draw_frame(self, "agua", Rect2(i * 16.0, -h, 16.0, 16.0), posmod(frame, 16))
		return
	if Engine.is_editor_hint():
		var r := Rect2(0.0, -16.0 * tiles_h, 16.0 * tiles_w, 16.0 * tiles_h)
		draw_rect(r, Color(1, 0, 0, 0.3))
		draw_rect(r, Color(1, 0.2, 0.2, 0.9), false)
