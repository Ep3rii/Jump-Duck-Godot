@tool
extends Node2D
## Saida da fase (decisao D4): encostar aqui conclui a fase. As flores viram pontuacao.
## Arte: assets/sprites/arte/saida.png; a origem e a base do mastro, no chao.

const Sprites := preload("res://scripts/sprites.gd")


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
	Sprites.draw_bicho(self, "saida", int(_time * 24.0) % 16, 16, Vector2(5, 48))
