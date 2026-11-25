extends Level
## Fase "tutorial_fase1" (1680x640). Blocos, flores, raposa e jogador estao na propria cena;
## os tiles (so decoracao) vem de tile_data.gd, convertido da sala do GameMaker.

const LevelTiles := preload("res://scripts/tile_data.gd")

@onready var tiles_agua: TileMapLayer = $TilesAgua
@onready var tiles_grama: TileMapLayer = $TilesGrama


func _build_level() -> void:
	fill_layer(tiles_agua, "spr_objBAgua01", LevelTiles.AGUA)
	fill_layer(tiles_grama, "spr_tileSetGrama01", LevelTiles.GRAMA)
