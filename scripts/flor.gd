extends Node2D
## obj_flor01: item coletavel. Vale pontos no fim da fase (nao conclui a fase sozinha).

const EfeitoScene := preload("res://scenes/efeito.tscn")

const Sprites := preload("res://scripts/sprites.gd")
## A rosa original com o dobro de detalhe (assets/sprites/arte/flor.png, 4 quadros).
const ART_ANIMS := {"default": ["res://assets/sprites/arte/flor.png", 4, 5.0]}
const ART_ORIGIN := Vector2(16, 28)  # o mesmo ponto do original (8, 14), em px do desenho

var sprite: AnimatedSprite2D


func _ready() -> void:
	add_to_group("flor")
	add_to_group("item")
	add_to_group("sombra")
	sprite = Sprites.make_art_sprite(Sprites.art_frames(ART_ANIMS), ART_ORIGIN)
	sprite.name = "Sprite"
	add_child(sprite)
	sprite.play("default")


## Mascara de colisao (bbox 5..10 x 3..13 do sprite 16x16 com origem 8,14).
func get_mask() -> Rect2:
	return Rect2(roundf(position.x) - 3.0, roundf(position.y) - 11.0, 6.0, 11.0)


func collect(_player: Node) -> void:
	var fx := EfeitoScene.instantiate()
	fx.position = Vector2(position.x, position.y - 6.0)
	get_parent().add_child(fx)
	queue_free()
	Game.play_sfx("flower")
	Game.collect_flower()
