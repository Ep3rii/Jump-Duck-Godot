@tool
extends Node2D
## obj_blocoPiso01: bloco solido. No GameMaker a origem fica no canto INFERIOR esquerdo
## e image_xscale/image_yscale dizem quantos tiles de 16 px ele ocupa; aqui sao
## tiles_w / tiles_h. Ocupa [x, x + 16*w) x [y - 16*h, y).

@export var tiles_w: int = 1:
	set(v):
		tiles_w = v
		_coberto.clear()
		queue_redraw()
@export var tiles_h: int = 1:
	set(v):
		tiles_h = v
		queue_redraw()

const TEX := preload("res://assets/sprites/arte/bloco.png")

## Linhas de bloco.png (16x16): 0..6 grama com o contorno de cima, 8..13 so terra (com os
## riscos), 14 faixa escura do fundo e 15 o contorno de baixo. As celulas de baixo da pilha
## (e o topo coberto por outro bloco) usam so a terra, para a coluna nao virar uma pilha de
## "tampas" de grama.
const TERRA_Y := 8
const TERRA_H := 6
const FUNDO_Y := 14

## Colunas (i) cujo topo esta coberto por outro bloco: desenham terra no lugar da grama.
var _coberto := PackedByteArray()


func _ready() -> void:
	add_to_group("solid")
	_checar_cobertura.call_deferred()


func get_rect() -> Rect2:
	return Rect2(global_position.x, global_position.y - 16.0 * tiles_h,
		16.0 * tiles_w, 16.0 * tiles_h)


## Marca as colunas que tem outro bloco (block.gd) logo em cima, encostado no topo.
func _checar_cobertura() -> void:
	if not is_inside_tree():
		return
	var r := get_rect()
	var cob := PackedByteArray()
	cob.resize(tiles_w)
	var algum := false
	for n in get_tree().get_nodes_in_group("solid"):
		if n == self or n.get_script() != get_script():
			continue
		var o: Rect2 = n.get_rect()
		for i in tiles_w:
			var faixa := Rect2(r.position.x + 16.0 * i + 1.0, r.position.y - 1.0, 14.0, 1.0)
			if faixa.intersects(o):
				cob[i] = 1
				algum = true
	_coberto = cob if algum else PackedByteArray()
	queue_redraw()


func _draw() -> void:
	# bloco de 16 px repetido na area (a arte e 32 px, reduzida pela metade); grama so no topo
	for j in tiles_h:
		var y := -16.0 * (j + 1)
		for i in tiles_w:
			var topo := j == tiles_h - 1 and not (i < _coberto.size() and _coberto[i] == 1)
			if topo:
				if j == 0:
					draw_texture_rect(TEX, Rect2(i * 16.0, y, 16.0, 16.0), false)
				else:  # grama e terra; embaixo continua a terra da celula de baixo
					_faixa(i, y, 0.0, 0.0, 14.0)
					_faixa(i, y, 14.0, TERRA_Y, 2.0)
			else:
				_terra(i, y, j == 0)


## Celula so de terra; a de baixo da pilha fecha com a faixa escura e o contorno.
func _terra(i: int, y: float, fundo: bool) -> void:
	_faixa(i, y, 0.0, TERRA_Y, TERRA_H)
	_faixa(i, y, TERRA_H, TERRA_Y, TERRA_H)
	if fundo:
		_faixa(i, y, 12.0, TERRA_Y, 2.0)
		_faixa(i, y, 14.0, FUNDO_Y, 2.0)
	else:
		_faixa(i, y, 12.0, TERRA_Y, 4.0)


## Copia as linhas [src_y, src_y + h) de bloco.png para a linha dy da celula (i, y).
func _faixa(i: int, y: float, dy: float, src_y: float, h: float) -> void:
	draw_texture_rect_region(TEX, Rect2(i * 16.0, y + dy, 16.0, h), Rect2(0.0, src_y, 16.0, h))
