extends Node2D
## obj_flor01: item coletavel. Vale pontos no fim da fase (nao conclui a fase sozinha).

const EfeitoScene := preload("res://scenes/efeito.tscn")

const Sprites := preload("res://scripts/sprites.gd")
## A rosa original com o dobro de detalhe (assets/sprites/arte/flor.png, 4 quadros).
const ART_ANIMS := {"default": ["res://assets/sprites/arte/flor.png", 16, 20.0]}
const ART_ORIGIN := Vector2(8, 14)  # o mesmo ponto do original, em px
## Brilho de item (Endesga 32 #fee761 e #ffffff): a flor balanca e pisca como a chave, para
## ler como coletavel mesmo quando fica no ar (sem parecer planta solta da terra).
const COL_BRILHO := Color8(254, 231, 97)
const COL_BRILHO_MEIO := Color8(255, 255, 255)
## Pontos (px do jogo, relativos a origem) onde a estrelinha aparece, um de cada vez.
const PONTOS_BRILHO := [Vector2(-6, -12), Vector2(5, -9), Vector2(-5, -6), Vector2(6, -13)]

var sprite: AnimatedSprite2D
var _time := 0.0
var _fase := 0.0


func _ready() -> void:
	add_to_group("flor")
	add_to_group("item")
	add_to_group("sombra")
	sprite = Sprites.make_art_sprite(Sprites.art_frames(ART_ANIMS), ART_ORIGIN)
	sprite.name = "Sprite"
	add_child(sprite)
	sprite.play("default")
	# cada flor balanca num tempo proprio (nao sobem e descem todas juntas)
	_fase = fposmod(position.x * 0.071 + position.y * 0.037, TAU)


func _process(delta: float) -> void:
	_time += delta
	# sobe e desce ate 2 px (nunca abaixo da posicao original: nao afunda na grama)
	var bob := floorf((sin(_time * 2.6 + _fase) - 1.0) * 1.2)
	if sprite != null and sprite.position.y != bob:
		sprite.position.y = bob
	queue_redraw()


func _draw() -> void:
	# estrelinha de brilho: aparece em 3 de cada 8 passos (~0,6 s ligada, ~1 s apagada)
	var passo := int(_time * 5.0 + _fase * 4.0)
	if passo % 8 >= 3:
		return
	var c: Vector2 = PONTOS_BRILHO[(passo >> 3) % PONTOS_BRILHO.size()]
	c.y += sprite.position.y if sprite != null else 0.0
	if passo % 8 == 1:
		# meio do piscar: cruz de 3x3 com miolo branco
		draw_rect(Rect2(c.x - 1.0, c.y, 3, 1), COL_BRILHO)
		draw_rect(Rect2(c.x, c.y - 1.0, 1, 3), COL_BRILHO)
		draw_rect(Rect2(c.x, c.y, 1, 1), COL_BRILHO_MEIO)
	else:
		draw_rect(Rect2(c.x, c.y, 1, 1), COL_BRILHO)


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
