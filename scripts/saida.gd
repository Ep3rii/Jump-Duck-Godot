@tool
extends Node2D
## Saida da fase (decisao D4): encostar aqui conclui a fase. As flores viram pontuacao.
## Desenho provisorio em codigo (mastro + bandeira); a origem e a base do mastro, no chao.

const COL_POLE := Color8(13, 80, 0)
const COL_POLE_HI := Color8(95, 192, 26)
const COL_FLAG := Color8(255, 210, 63)
const COL_FLAG_DARK := Color8(122, 90, 0)

var _time := 0.0


func _ready() -> void:
	add_to_group("exit")
	add_to_group("luz")


## A saida fica clara no escuro (luz.gd).
func luzes() -> Array:
	return [[global_position + Vector2(0, -24), 34.0, Color(1.0, 1.0, 0.92), 0.8]]


## Area que conclui a fase: o mastro e um pouco em volta.
func get_mask() -> Rect2:
	return Rect2(roundf(position.x) - 6.0, roundf(position.y) - 40.0, 12.0, 40.0)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	# base
	draw_rect(Rect2(-5, -3, 10, 3), COL_POLE)
	# mastro
	draw_rect(Rect2(-1, -40, 3, 38), COL_POLE)
	draw_rect(Rect2(0, -40, 1, 38), COL_POLE_HI)
	draw_rect(Rect2(-2, -43, 5, 3), COL_FLAG)
	# bandeira tremulando (cada coluna de 1 px sobe/desce com uma onda)
	for col in 14:
		var h := 10 - int(col * 0.5)
		var y := -39.0 + floorf(sin(_time * 6.0 + col * 0.5))
		var c := COL_FLAG_DARK if col == 0 or col % 4 == 3 else COL_FLAG
		draw_rect(Rect2(2 + col, y + floorf((10 - h) * 0.5), 1, h), c)
