extends Node2D
## obj_flor01: item coletavel.

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	add_to_group("flor")
	sprite.play("default")


## Mascara de colisao (bbox 5..10 x 3..13 do sprite 16x16 com origem 8,14).
func get_mask() -> Rect2:
	return Rect2(roundf(position.x) - 3.0, roundf(position.y) - 11.0, 6.0, 11.0)
