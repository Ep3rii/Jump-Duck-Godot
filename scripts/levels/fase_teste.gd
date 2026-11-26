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
	fill_layer_art(tiles_grama, "tileset_grama", LevelTiles.GRAMA)
