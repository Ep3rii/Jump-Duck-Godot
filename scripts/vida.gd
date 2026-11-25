extends Node2D
## Vida extra: devolve 1 coracao (ate o maximo). Com a vida cheia, fica onde esta.
## Usa o sprite do coracao do HUD (32x32) desenhado pela metade, flutuando.

const Sprites := preload("res://scripts/sprites.gd")
const EfeitoScene := preload("res://scenes/efeito.tscn")

var _time := 0.0


func _ready() -> void:
	add_to_group("item")


## Origem = ponto no chao embaixo do coracao.
func get_mask() -> Rect2:
	return Rect2(roundf(position.x) - 6.0, roundf(position.y) - 16.0, 12.0, 12.0)


func collect(_player: Node) -> void:
	if Game.player_lives >= Game.max_lives:
		return
	Game.player_lives += 1
	Game.play_sfx("life")
	var fx := EfeitoScene.instantiate()
	fx.position = position + Vector2(0, -10)
	get_parent().add_child(fx)
	queue_free()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var bob := floorf(sin(_time * 3.0) * 1.5)
	Sprites.draw(self, "spr_vidaCheia", 0, 0.0, -10.0 + bob, 0.5, 0.5)
