extends Enemy
## obj_raposa: inimigo que patrulha ate 64 px para cada lado da posicao inicial.
## Vira antes de bater numa parede ou de cair de uma beirada. Morre com um pisao.
## Arte: assets/sprites/arte/raposa.png (6 quadros de trote, tools/arte/inimigos.py), um pouco
## maior que o pato; a mascara de colisao continua do tamanho da do pato.

const Solids := preload("res://scripts/solids.gd")

var start_x := 0.0
var patrol_range := 64.0
var walk_speed := 0.5
var dir := -1
var xscale := 1  # image_xscale: 1 = olhando p/ esquerda (como o sprite original)

const Sprites := preload("res://scripts/sprites.gd")
const QUADROS := 6
const PIVO := Vector2(12, 17)  # pes da raposa, no quadro (px do jogo)

var _t := 0.0


func _enemy_ready() -> void:
	add_to_group("raposa")
	effect_offset = Vector2(0, -8)
	particula_derrota = "pelo"
	start_x = position.x
	dir = 1 if xscale < 0 else -1


## Mascara de colisao: do tamanho da do pato (16x14), em pe no chao.
func get_mask() -> Rect2:
	return Rect2(roundf(position.x) - 8.0, roundf(position.y) - 14.0, 16.0, 14.0)


## Parede logo a frente, ou (estando no chao) buraco logo a frente.
func _blocked_ahead() -> bool:
	var snap := Solids.snapshot(get_tree())
	var x := roundf(position.x)
	var y := roundf(position.y)
	# Parede: coluna de 1 px logo depois da borda da mascara (8 px para o lado em que olha).
	var wall_x := x - 9.0 if dir < 0 else x + 8.0
	if Solids.hits(snap, Rect2(wall_x, y - 14.0, 1.0, 13.0)):
		return true
	# Beirada: chao logo a frente das patas (6 px).
	var grounded := Solids.hits(snap, Rect2(x, y + 1.0, 1.0, 1.0))
	return grounded and not Solids.hits(snap, Rect2(x + dir * 6.0, y + 1.0, 1.0, 1.0))


func _physics_process(_delta: float) -> void:
	if Game.game_state != "playing":
		return

	if _blocked_ahead():
		dir = -dir
	else:
		position.x += dir * walk_speed
	if position.x <= start_x - patrol_range:
		dir = 1
	elif position.x >= start_x + patrol_range:
		dir = -1
	xscale = 1 if dir < 0 else -1
	_t += 1.0
	queue_redraw()


func _draw() -> void:
	# xscale 1 = olhando para a esquerda (como no original)
	Sprites.draw_bicho(self, "raposa", int(_t / 7.0), QUADROS, PIVO, xscale > 0)
