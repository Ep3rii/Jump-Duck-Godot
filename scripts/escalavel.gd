@tool
extends Node2D
## Cipo escalavel: com o pato encostado, CIMA/BAIXO sobe e desce (sem gravidade).
## PULO solta. No topo o pato para com o pe na altura do topo do cipo, entao alinhe o topo
## com o chao/plataforma de cima para ele sair andando para o lado.
## Origem no canto INFERIOR esquerdo, 1 tile de largura, altura em tiles de 16 px.

@export var tiles_h: int = 4:
	set(v):
		tiles_h = v
		queue_redraw()

const COL_STEM := Color8(40, 110, 30)
const COL_STEM_HI := Color8(95, 192, 26)
const COL_LEAF := Color8(71, 160, 40)


var _time := 0.0


func _ready() -> void:
	add_to_group("escalavel")


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	queue_redraw()


func get_rect() -> Rect2:
	return Rect2(global_position.x, global_position.y - 16.0 * tiles_h, 16.0, 16.0 * tiles_h)


func top_y() -> float:
	return global_position.y - 16.0 * tiles_h


func _draw() -> void:
	var h := 16.0 * tiles_h
	for y in int(h):
		var x := 7.0 + floorf(sin(y * 0.35) * 2.0)
		draw_rect(Rect2(x, -h + y, 2, 1), COL_STEM)
		draw_rect(Rect2(x, -h + y, 1, 1), COL_STEM_HI)
	for i in tiles_h * 2:
		var ly := -h + 4.0 + i * 8.0
		var left := i % 2 == 0
		var flap := floorf(sin(_time * 2.2 + i * 0.8) * 0.8 + 0.5)
		draw_rect(Rect2((3 if left else 10) + flap, ly, 4, 2), COL_LEAF)
		draw_rect(Rect2((4 if left else 11) + flap, ly - 1 + (flap if left else -flap), 2, 1), COL_STEM_HI)
		if i % 3 == 1:  # florzinha de vez em quando
			draw_rect(Rect2(8 if left else 5, ly + 2, 2, 2), Color8(255, 240, 240))
