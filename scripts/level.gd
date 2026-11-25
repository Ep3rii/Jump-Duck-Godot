extends Node2D
## Sala "tutorial_fase1" (1680x640). Blocos, flor, raposa e jogador estao na propria cena;
## os tiles vem de tile_data.gd (convertido da sala do GameMaker).

const Sprites := preload("res://scripts/sprites.gd")
const LevelTiles := preload("res://scripts/tile_data.gd")

@onready var tiles_agua: TileMapLayer = $TilesAgua
@onready var tiles_grama: TileMapLayer = $TilesGrama


# _enter_tree roda antes do _ready dos filhos (a camera precisa do tamanho da sala).
func _enter_tree() -> void:
	Game.room = "tutorial_fase1"
	Game.room_width = 1680
	Game.room_height = 640


func _ready() -> void:
	Game.level_started = false
	_fill_layer(tiles_agua, "spr_objBAgua01", LevelTiles.AGUA)
	_fill_layer(tiles_grama, "spr_tileSetGrama01", LevelTiles.GRAMA)


## Cria um TileSet (tiles de 16x16, 4 colunas) a partir do sprite e preenche a camada.
## Indice de tile do GameMaker -> atlas coords (indice % 4, indice / 4).
func _fill_layer(layer: TileMapLayer, sprite_name: String, cells: Array) -> void:
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
