extends Level
## Fase de testes (1680x640): o tutorial original convertido do GameMaker. Os testes
## automaticos (tests/test_runner.gd) dependem deste layout; nao esta em Game.levels.
## Os tiles (so decoracao) vem de tile_data.gd, convertido da sala do GameMaker.

const LevelTiles := preload("res://scripts/tile_data.gd")

@onready var tiles_agua: TileMapLayer = $TilesAgua
@onready var tiles_grama: TileMapLayer = $TilesGrama


func _build_level() -> void:
	# agua: o original so usa um bloco (o corpo da agua); grama: os blocos originais ficam
	# nas mesmas posicoes do tileset de grama novo
	fill_layer_art(tiles_agua, "agua", LevelTiles.AGUA, 0)
	_agua_funda(tiles_agua, LevelTiles.AGUA)
	fill_layer_art(tiles_grama, "tileset_grama", LevelTiles.GRAMA)


## Agua funda da Endesga 32 (a mesma cor do fundo do tile de agua).
const COR_AGUA_FUNDA := Color("#124e89")


## So a linha de cima de cada coluna de agua usa o sprite da superficie (agua.png, com a faixa
## de espuma); as celulas de baixo viram agua funda lisa (#124e89), sem repetir a faixa da
## superficie a cada 16 px.
func _agua_funda(layer: TileMapLayer, cells: Array) -> void:
	var ocupadas := {}
	for cell: Array in cells:
		ocupadas[Vector2i(cell[0], cell[1])] = true
	var funda: Array[Vector2i] = []
	for c: Vector2i in ocupadas:
		if ocupadas.has(c + Vector2i.UP):
			funda.append(c)
	if funda.is_empty():
		return
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(COR_AGUA_FUNDA)
	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(img)
	source.texture_region_size = Vector2i(16, 16)
	source.create_tile(Vector2i.ZERO)
	layer.tile_set.add_source(source, 1)
	for c in funda:
		layer.set_cell(c, 1, Vector2i.ZERO)
