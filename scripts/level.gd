class_name Level
extends Node2D
## Base de toda fase. Cada fase e uma cena cujo no raiz usa este script (ou um que herda dele).
## Ela avisa o Game quando entra (tamanho da sala) e quando fica pronta (begin_level).
## A ordem das fases e o nome mostrado nas telas ficam em Game.levels.
##
## Para uma fase nova: duplique uma cena de fase, ajuste os @export abaixo e, se precisar
## montar algo em codigo (tiles gerados etc.), sobrescreva _build_level().

const Sprites := preload("res://scripts/sprites.gd")

## Identificador da fase = id em Game.levels (padrao: nome do arquivo da cena; fases em
## subpastas de scenes/ precisam do caminho, ex. "testes/fase_teste").
@export var level_id := ""
## Tamanho da sala em pixels (limite da camera e da rede de seguranca do jogador).
@export var room_size := Vector2i(320, 180)
## Quanto a camera olha acima (negativo) ou abaixo (positivo) do pato. O original usa -50
## (mais ceu); fases com agua embaixo das plataformas ficam melhores com 0.
@export var camera_offset_y := -50.0


# _enter_tree roda antes do _ready dos filhos (a camera precisa do tamanho da sala).
func _enter_tree() -> void:
	if level_id.is_empty():
		level_id = scene_file_path.get_file().get_basename()
	Game.room = level_id
	Game.room_width = room_size.x
	Game.room_height = room_size.y
	Game.camera_offset_y = camera_offset_y


func _ready() -> void:
	_build_level()
	_retile_grass()
	# a moldura (paredes e teto fora da sala) so segura o pato; com a camera afastada ela
	# aparecia nas salas mais baixas que a tela
	var frame := get_node_or_null("Moldura")
	if frame != null:
		frame.visible = false
	var amb := Node2D.new()
	amb.name = "Ambiente"
	amb.set_script(preload("res://scripts/ambiente.gd"))
	add_child(amb)
	# luz e sombra: sombras no chao (acima do terreno e das plataformas, abaixo dos bichos) e
	# a pelicula de luz ambiente / tochas (acima do mundo, abaixo do HUD)
	var sombras := Node2D.new()
	sombras.name = "Sombras"
	sombras.z_index = -690
	sombras.set_script(preload("res://scripts/sombras.gd"))
	add_child(sombras)
	var luz := CanvasLayer.new()
	luz.name = "Luz"
	luz.set_script(preload("res://scripts/luz.gd"))
	add_child(luz)
	Game.begin_level(self)


## Sobrescreva para montar partes da fase em codigo.
func _build_level() -> void:
	pass


## Cria um TileSet (tiles de 16x16, 4 colunas) a partir do sprite e preenche a camada.
## Cada celula de 'cells' e [coluna, linha, indice]; indice -> atlas (indice % 4, indice / 4).
func fill_layer(layer: TileMapLayer, sprite_name: String, cells: Array) -> void:
	var source := TileSetAtlasSource.new()
	source.texture = Sprites.strip(sprite_name)
	source.texture_region_size = Vector2i(16, 16)
	for ty in 4:
		for tx in 4:
			source.create_tile(Vector2i(tx, ty))

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(16, 16)
	tile_set.add_source(source, 0)
	layer.tile_set = tile_set

	for cell: Array in cells:
		var index: int = cell[2]
		layer.set_cell(Vector2i(cell[0], cell[1]), 0, Vector2i(index % 4, index / 4))



# ------------------------------------------------------------- auto-tile do tileset de grama
## Indices (linha*4 + coluna) das variacoes do tileset de grama novo (assets/sprites/arte/).
const GRASS_TOP_VARIANTS := [16, 17, 18, 19]
const GRASS_DIRT_VARIANTS := [20, 21, 22, 23]
const GRASS_PLATFORM_ROW := 8  # tronco e ponte: colocados a mao, o auto-tile nao mexe


## Escolhe de novo o bloco de cada celula das camadas de grama pelos vizinhos: pontas, topo,
## interior, plataformas, coluna de 1 bloco, teto de terra, canto interno no pe dos degraus e
## variacoes (topo e terra) escolhidas pela posicao (sempre as mesmas).
func _retile_grass() -> void:
	var rows := int(room_size.y / 16)
	for layer: TileMapLayer in get_tree().get_nodes_in_group("solid_tiles"):
		if not is_ancestor_of(layer) or layer.tile_set == null:
			continue
		if layer.tile_set.tile_size != Vector2i(32, 32):
			continue  # so os tilesets novos (grama e pedra, blocos de 32 em 1:1)
		var cells := {}
		for c in layer.get_used_cells():
			if layer.get_cell_atlas_coords(c).y != GRASS_PLATFORM_ROW:
				cells[c] = true
		for c: Vector2i in cells:
			var idx := _grass_tile_for(cells, c, rows)
			layer.set_cell(c, 0, Vector2i(idx % 4, idx / 4))


static func _grass_hash(x: int, y: int, salt: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)) % 100


static func _grass_has(cells: Dictionary, c: Vector2i, rows: int) -> bool:
	return c.y >= rows or cells.has(c)  # abaixo da sala conta como cheio


static func _grass_tile_for(cells: Dictionary, c: Vector2i, rows: int) -> int:
	var up := _grass_has(cells, c + Vector2i(0, -1), rows)
	var dn := _grass_has(cells, c + Vector2i(0, 1), rows)
	var lf := _grass_has(cells, c + Vector2i(-1, 0), rows)
	var rt := _grass_has(cells, c + Vector2i(1, 0), rows)
	if not up:
		if not dn:
			if not lf and not rt:
				return 7
			if not lf:
				return 8
			if not rt:
				return 10
			return 9
		if not lf and not rt:
			return 25  # topo de coluna de 1 bloco
		if not lf:
			return 4
		if not rt:
			return 6
		var h := _grass_hash(c.x, c.y, 0)
		return GRASS_TOP_VARIANTS[h % 4] if h < 35 else 5
	if not dn:  # fundo exposto: teto de terra
		if not lf and not rt:
			return 27
		if not lf:
			return 28
		if not rt:
			return 30
		return 29
	if not lf and not rt:
		return 26  # meio de coluna de 1 bloco
	if not lf:
		return 12
	if not rt:
		return 14
	if not _grass_has(cells, c + Vector2i(-1, -1), rows):
		return 11  # canto interno: a grama do chao mais baixo faz a curva
	if not _grass_has(cells, c + Vector2i(1, -1), rows):
		return 24
	var h2 := _grass_hash(c.x, c.y, 7)
	return GRASS_DIRT_VARIANTS[h2 % 4] if h2 < 22 else 13
