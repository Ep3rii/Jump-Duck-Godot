@tool
extends Node2D
## Cipo escalavel: com o pato encostado, CIMA/BAIXO sobe e desce (sem gravidade).
## PULO solta. No topo o pato para com o pe na altura do topo do cipo, entao alinhe o topo
## com o chao/plataforma de cima para ele sair andando para o lado.
## Origem no canto INFERIOR esquerdo, 1 tile de largura, altura em tiles de 16 px.

const Sprites := preload("res://scripts/sprites.gd")

@export var tiles_h: int = 4:
	set(v):
		tiles_h = v
		queue_redraw()
## Desloca so o DESENHO do cipo (px, sem mexer na area de escalada) para o caule encostar
## numa parede ao lado: negativo = parede a esquerda (-7 cola o caule na borda do tile),
## positivo = parede/plataforma a direita (+6 cola o caule na borda direita).
@export_range(-8, 8) var encosto_x: int = 0:
	set(v):
		encosto_x = v
		queue_redraw()

var _time := 0.0


## Camada absoluta logo atras do terreno (blocos e TileMap ficam em -800): as folhas que passam
## da borda do tile somem atras da parede/plataforma em que o cipo encosta, em vez de ficarem
## pregadas na frente dela. Continua na frente do fundo e da decoracao (-900 e abaixo).
const Z_CIPO := -810


func _ready() -> void:
	add_to_group("escalavel")
	z_as_relative = false
	z_index = Z_CIPO


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	queue_redraw()


func get_rect() -> Rect2:
	return Rect2(global_position.x, global_position.y - 16.0 * tiles_h, 16.0, 16.0 * tiles_h)


func top_y() -> float:
	return global_position.y - 16.0 * tiles_h


func _draw() -> void:
	# trechos de cipo de 16 px empilhados (cipo.png, 2 quadros de folhas balancando)
	var q := int(_time * 17.6) % 16
	for j in tiles_h:
		Sprites.draw_frame(self, "cipo", Rect2(encosto_x, -16.0 * (j + 1), 16, 16), (q + j * 8) % 16)
