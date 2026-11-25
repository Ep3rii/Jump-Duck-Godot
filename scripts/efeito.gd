extends Node2D
## obj_efeito: brilho que toca uma vez e se destroi (evento Animation End do GameMaker).

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	sprite.sprite_frames.set_animation_loop("default", false)
	sprite.animation_finished.connect(queue_free)
	sprite.play("default")
