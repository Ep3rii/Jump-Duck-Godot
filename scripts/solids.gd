extends RefCounted
## Consulta de colisao compartilhada (jogador, inimigos e, no futuro, objetos arrastaveis).
## Uso: const Solids := preload("res://scripts/solids.gd")
##
## E solido:
## - todo no do grupo "solid" com get_rect() (block.gd, caixa.gd parada, porta.gd fechada,
##   plataforma.gd);
## - toda celula de um TileMapLayer do grupo "solid_tiles" cujo tile tenha o custom data
##   "solid" = true no TileSet. Assim da para desenhar o chao das fases novas direto no editor.
##
## A colisao e por retangulos (como a mascara do GameMaker): bordas que so se encostam
## NAO contam como colisao.


## Foto dos solidos do frame atual; evita varrer os grupos a cada pixel testado.
static func snapshot(tree: SceneTree) -> Array:
	return [tree.get_nodes_in_group("solid"), tree.get_nodes_in_group("solid_tiles")]


## exclude: solidos que nao contam (ex.: a propria caixa testando o proprio movimento).
static func hits(snap: Array, r: Rect2, exclude: Array = []) -> bool:
	for block in snap[0]:
		if not exclude.has(block) and r.intersects(block.get_rect()):
			return true
	for layer: TileMapLayer in snap[1]:
		if _layer_hits(layer, r):
			return true
	return false


static func _layer_hits(layer: TileMapLayer, r: Rect2) -> bool:
	var ts := layer.tile_set
	if ts == null or ts.get_custom_data_layer_by_name("solid") < 0:
		return false
	# Recuo minimo no fim do retangulo: encostar na borda do tile nao conta.
	var a := layer.local_to_map(layer.to_local(r.position))
	var b := layer.local_to_map(layer.to_local(r.end - Vector2(0.01, 0.01)))
	for y in range(a.y, b.y + 1):
		for x in range(a.x, b.x + 1):
			var data := layer.get_cell_tile_data(Vector2i(x, y))
			if data != null and data.get_custom_data("solid"):
				return true
	return false
