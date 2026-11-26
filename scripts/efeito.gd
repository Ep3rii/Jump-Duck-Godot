extends Node2D
## obj_efeito: brilho que toca uma vez e se destroi (evento Animation End do GameMaker).
## Arte: assets/sprites/arte/brilho.png (5 quadros, tools/arte/objetos.py).

const Sprites := preload("res://scripts/sprites.gd")
const ANIMS := {"default": ["res://assets/sprites/arte/brilho.png", 5, 12.0, false]}

var sprite: AnimatedSprite2D


func _ready() -> void:
	sprite = Sprites.make_art_sprite(Sprites.art_frames(ANIMS), Vector2(16, 16))
	sprite.name = "Sprite"
	add_child(sprite)
	sprite.animation_finished.connect(queue_free)
	sprite.play("default")
