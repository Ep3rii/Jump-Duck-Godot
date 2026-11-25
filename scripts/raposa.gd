extends Node2D
## obj_raposa: inimigo que patrulha 64 px para cada lado da posicao inicial.

var start_x := 0.0
var patrol_range := 64.0
var walk_speed := 0.5
var dir := -1
var xscale := 1  # image_xscale: 1 = olhando p/ esquerda (como o sprite original)

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	add_to_group("raposa")
	start_x = position.x
	dir = 1 if xscale < 0 else -1
	sprite.speed_scale = 0.0
	sprite.play("default")


## Mascara de colisao (bbox 8..44 x 30..57 do sprite 64x64 com origem 32,48).
func get_mask() -> Rect2:
	var rx := roundf(position.x)
	var ry := roundf(position.y)
	if xscale >= 0:
		return Rect2(rx - 24.0, ry - 18.0, 37.0, 28.0)
	return Rect2(rx - 13.0, ry - 18.0, 37.0, 28.0)


func _physics_process(_delta: float) -> void:
	if Game.game_state != "playing":
		sprite.speed_scale = 0.0
		return

	sprite.speed_scale = 1.0
	position.x += dir * walk_speed
	if position.x <= start_x - patrol_range:
		dir = 1
	if position.x >= start_x + patrol_range:
		dir = -1
	xscale = 1 if dir < 0 else -1
	sprite.flip_h = xscale < 0
