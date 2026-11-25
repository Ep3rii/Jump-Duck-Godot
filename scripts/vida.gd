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
	# bate como um coracao: duas batidas rapidas e uma pausa
	var beat := fposmod(_time, 1.2)
	var pulse := 1.0 + (0.12 if beat < 0.1 or (beat > 0.22 and beat < 0.32) else 0.0)
	var s := 0.5 * pulse
	Sprites.draw(self, "spr_vidaCheia", 0, 0.0, -10.0 + bob, s, s)
