@tool
extends Node2D
## Placa de madeira com dica: quando o pato chega perto, mostra o texto num balao acima dela.
## Use "|" para quebrar linha (ex.: "ESPAÇO NO AR:|PULO DUPLO").
## Origem = pe da placa, no chao.

const Sprites := preload("res://scripts/sprites.gd")

const PixelFont := preload("res://scripts/pixel_font.gd")

@export_multiline var texto := "DICA":
	set(v):
		texto = v
		queue_redraw()
## Distancia (px) em que o balao aparece.
@export var alcance := 56.0

const COL_BUBBLE := Color8(13, 80, 0, 230)
const COL_BUBBLE_EDGE := Color8(133, 242, 56)

var _show := 0.0  # 0..1 (aparece/desaparece suave)


func _ready() -> void:
	add_to_group("dica")


func _lines() -> PackedStringArray:
	return texto.replace("\n", "|").split("|")


func _process(delta: float) -> void:
	var target := 0.0
	if Engine.is_editor_hint():
		target = 1.0
	else:
		var p := get_tree().get_first_node_in_group("player")
		if p != null and absf(p.position.x - position.x) < alcance \
				and absf(p.position.y - position.y) < 48.0:
			target = 1.0
	var before := _show
	_show = move_toward(_show, target, delta * 6.0)
	if _show != before or Engine.is_editor_hint():
		queue_redraw()


func is_showing() -> bool:
	return _show > 0.5


func _draw() -> void:
	# placa de madeira (dica.png, 16x20 no jogo); o pe do poste fica na origem
	Sprites.draw_art(self, "dica", -8.0, -20.0)
	if _show <= 0.01:
		return
	# balao
	var lines := _lines()
	var w := 0.0
	for l in lines:
		w = maxf(w, PixelFont.width(l))
	var h := lines.size() * 11.0 + 6.0
	var x0 := floorf(-w * 0.5) - 4.0
	var y0 := -22.0 - h - floorf((1.0 - _show) * 6.0)
	var bubble := COL_BUBBLE
	bubble.a *= _show
	var edge := COL_BUBBLE_EDGE
	edge.a *= _show
	draw_rect(Rect2(x0, y0, w + 8.0, h), bubble)
	draw_rect(Rect2(x0, y0, w + 8.0, h), edge, false)
	draw_rect(Rect2(-2, y0 + h, 4, 2), edge)
	var white := Color(1, 1, 1, _show)
	for i in lines.size():
		PixelFont.draw_plain(self, 0.0, y0 + 9.0 + i * 11.0, lines[i], white, PixelFont.CENTER)
