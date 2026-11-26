@tool
extends Node2D
## Agua em que da para nadar (Fases 2 e 3). Diferente do perigo.tscn: aqui o pato boia na
## superficie, mergulha com BAIXO e tem folego limitado. Caixas boiam; jacares vivem aqui.
## Origem no canto INFERIOR esquerdo (como o Block), tamanho em tiles de 16 px.
## Desenhada na frente do pato e translucida: ele aparece "dentro" d'agua.

const Sprites := preload("res://scripts/sprites.gd")

@export var tiles_w: int = 4:
	set(v):
		tiles_w = v
		queue_redraw()
@export var tiles_h: int = 3:
	set(v):
		tiles_h = v
		queue_redraw()

const COL_BODY := Color(0.12, 0.42, 0.80, 0.45)
const COL_DEEP := Color(0.05, 0.25, 0.60, 0.35)
## Fundo opaco do lago (atras de tudo, na frente do parallax): sem ele os morros do fundo
## apareciam "dentro" d'agua.
const COL_BACK := Color8(92, 156, 214)
const COL_BACK_DEEP := Color8(70, 130, 196)

var _time := 0.0


func _ready() -> void:
	add_to_group("agua")
	var fundo := Node2D.new()
	fundo.name = "Fundo"
	fundo.z_as_relative = false
	fundo.z_index = -980
	fundo.draw.connect(func() -> void:
		var w := 16.0 * tiles_w
		var h := 16.0 * tiles_h
		fundo.draw_rect(Rect2(0, -h + 4, w, h - 4), COL_BACK)
		fundo.draw_rect(Rect2(0, -h * 0.5, w, h * 0.5), COL_BACK_DEEP))
	add_child(fundo)


func get_rect() -> Rect2:
	return Rect2(global_position.x, global_position.y - 16.0 * tiles_h,
		16.0 * tiles_w, 16.0 * tiles_h)


func surface_y() -> float:
	return global_position.y - 16.0 * tiles_h


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var w := 16.0 * tiles_w
	var h := 16.0 * tiles_h
	draw_rect(Rect2(0, -h + 4, w, h - 4), COL_BODY)
	draw_rect(Rect2(0, -h * 0.5, w, h * 0.5), COL_DEEP)
	var frame := int(_time * 16.0)  # 16 quadros por segundo (uma volta da espuma)
	for i in tiles_w:
		Sprites.draw_frame(self, "agua", Rect2(i * 16.0, -h, 16.0, 16.0), posmod(frame + i * 4, 16), Color(1, 1, 1, 0.85))
	# brilhinhos na superficie e raios de luz no fundo
	for i in tiles_w * 2:
		var ph := _time * 1.7 + i * 2.39
		var s := sin(ph)
		if s > 0.82:
			var gx := fposmod(i * 8.0 + i * i * 3.0, w - 4.0)
			var a := (s - 0.82) / 0.18
			draw_rect(Rect2(gx, -h + 5, 3, 1), Color(1, 1, 1, a))
			draw_rect(Rect2(gx + 1, -h + 4, 1, 3), Color(1, 1, 1, a * 0.6))
	for i in int(w / 48.0):
		var rx := i * 48.0 + 12.0 + sin(_time * 0.6 + i) * 6.0
		var ray := PackedVector2Array([Vector2(rx, -h + 6), Vector2(rx + 6, -h + 6),
			Vector2(rx + 14, -4.0), Vector2(rx + 4, -4.0)])
		draw_colored_polygon(ray, Color(0.85, 0.95, 1.0, 0.05 + 0.03 * sin(_time + i)))
