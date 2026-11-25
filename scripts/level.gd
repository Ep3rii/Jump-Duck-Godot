class_name Level
extends Node2D
## Base de toda fase. Cada fase e uma cena cujo no raiz usa este script (ou um que herda dele).
## Ela avisa o Game quando entra (tamanho da sala) e quando fica pronta (begin_level),
## entao o Game nao precisa saber o nome de nenhuma fase.
##
## Para uma fase nova: duplique uma cena de fase, ajuste os @export abaixo e, se precisar
## montar algo em codigo (tiles gerados etc.), sobrescreva _build_level().

const Sprites := preload("res://scripts/sprites.gd")

## Identificador da fase (padrao: nome do arquivo da cena, ex. "tutorial_fase1").
@export var level_id := ""
## Nome mostrado nas telas (ex. "TUTORIAL").
@export var display_name := ""
## Tamanho da sala em pixels (limite da camera e da rede de seguranca do jogador).
@export var room_size := Vector2i(320, 180)
## Nome da cena da proxima fase em res://scenes/ (vazio = ultima fase).
@export var next_level := ""


# _enter_tree roda antes do _ready dos filhos (a camera precisa do tamanho da sala).
func _enter_tree() -> void:
	if level_id.is_empty():
		level_id = scene_file_path.get_file().get_basename()
	Game.room = level_id
	Game.room_width = room_size.x
	Game.room_height = room_size.y


func _ready() -> void:
	_build_level()
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
