extends Node2D
## obj_efeito: brilho que toca uma vez e se destroi (evento Animation End do GameMaker).
## A animacao "default" de spr_brilho.tres ja vem com loop desligado.

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	sprite.animation_finished.connect(queue_free)
	sprite.play("default")
