@tool
extends Node2D
## Chave (Fases 4, 5 e 8): item que vai para o "bolso" do pato (Game.keys, mostrado no HUD).
## Encostar numa porta trancada (porta.gd com "trancada") gasta 1 chave e abre a porta.
## Origem = ponto no chao embaixo da chave. Desenho provisorio em codigo.

const EfeitoScene := preload("res://scenes/efeito.tscn")
const Particulas := preload("res://scripts/particulas.gd")

const Sprites := preload("res://scripts/sprites.gd")
const COL_LIGHT := Color8(255, 244, 170)

var _time := 0.0


func _ready() -> void:
	add_to_group("chave")
	add_to_group("item")
	add_to_group("sombra")
	add_to_group("luz")


## A chave brilha no escuro (luz.gd).
func luzes() -> Array:
	return [[global_position + Vector2(0, -8), 24.0, Color(1.0, 1.0, 0.9), 0.9]]


func get_mask() -> Rect2:
	return Rect2(roundf(position.x) - 6.0, roundf(position.y) - 14.0, 12.0, 12.0)


func collect(_player: Node) -> void:
	var fx := EfeitoScene.instantiate()
	fx.position = position + Vector2(0, -8)
	get_parent().add_child(fx)
	queue_free()
	Particulas.emit(get_tree(), "brilho", position + Vector2(0, -8), 10)
	Game.keys += 1
	Game.play_sfx("key")


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var bob := floorf(sin(_time * 3.0) * 1.5)
	# gira devagar (achata na horizontal e volta)
	var spin := cos(_time * 2.4)
	var sx := maxf(0.15, absf(spin))
	draw_set_transform(Vector2(0, -8 + bob), 0.0, Vector2(sx * (1.0 if spin >= 0.0 else -1.0), 1.0))
	draw_key(self, Vector2.ZERO)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# brilho piscando
	if int(_time * 4.0) % 6 == 0:
		draw_rect(Rect2(3, -14 + bob, 1, 3), COL_LIGHT)
		draw_rect(Rect2(2, -13 + bob, 3, 1), COL_LIGHT)


## Desenha a chave (assets/sprites/arte/chave.png, 16x16) centrada em c; o HUD usa a mesma funcao.
static func draw_key(ci: CanvasItem, c: Vector2) -> void:
	Sprites.draw_frame(ci, "chave", Rect2(c.x - 8.0, c.y - 8.0, 16.0, 16.0))
