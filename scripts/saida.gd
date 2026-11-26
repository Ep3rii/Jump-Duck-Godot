@tool
extends Node2D
## Saida da fase (decisao D4): encostar aqui conclui a fase. As flores viram pontuacao.
## Arte: assets/sprites/arte/saida.png; a origem e a base do mastro, no chao.

const Sprites := preload("res://scripts/sprites.gd")

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
	# bandeira de saida (assets/sprites/arte/saida.png, 4 quadros tremulando); pe do mastro na origem
	Sprites.draw_bicho(self, "saida", int(_time * 6.0) % 4, 4, Vector2(5, 48))
