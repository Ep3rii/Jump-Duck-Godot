extends Level
## Fase de testes (1680x640): o tutorial original convertido do GameMaker. Os testes
## automaticos (tests/test_runner.gd) dependem deste layout; nao esta em Game.levels.
## Os tiles (so decoracao) vem de tile_data.gd, convertido da sala do GameMaker.

const LevelTiles := preload("res://scripts/tile_data.gd")

@onready var tiles_agua: TileMapLayer = $TilesAgua
@onready var tiles_grama: TileMapLayer = $TilesGrama


func _build_level() -> void:
	fill_layer(tiles_agua, "spr_objBAgua01", LevelTiles.AGUA)
	fill_layer(tiles_grama, "spr_tileSetGrama01", LevelTiles.GRAMA)
