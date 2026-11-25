extends Node2D
## Sala "menu": so o fundo em paralaxe; os menus sao desenhados por ui.gd (autoload Game).


func _enter_tree() -> void:
	Game.room = "menu"
	Game.room_width = 320
	Game.room_height = 180
	Game.cam_pos = Vector2.ZERO
