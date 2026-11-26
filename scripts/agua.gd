@tool
extends Node2D
## Agua em que da para nadar (Fases 2 e 3). Diferente do perigo.tscn: aqui o pato boia na
## superficie, mergulha com BAIXO e tem folego limitado. Caixas boiam; jacares vivem aqui.
## Origem no canto INFERIOR esquerdo (como o Block), tamanho em tiles de 16 px.
## Desenhada na frente do pato e translucida: ele aparece "dentro" d'agua.

const Sprites := preload("res://scripts/sprites.gd")

@export var tiles_w: int = 4:
	set(v):
		tiles_w = v
		queue_redraw()
@export var tiles_h: int = 3:
	set(v):
		tiles_h = v
		queue_redraw()

## Veu da frente: um so e leve (tinta, nao lavagem), para o pato mergulhado manter o contorno
## escuro e o laranja do bico. O tom da agua vem quase todo do fundo opaco abaixo.
const COL_BODY := Color(0.12, 0.42, 0.80, 0.30)
## Fundo opaco do lago (atras de tudo, na frente do parallax): sem ele os morros do fundo
## apareciam "dentro" d'agua. Ja escurecido para que fundo + veu de a mesma cor de antes
## (metade de cima ~(64,134,209), metade funda ~(38,100,183)).
const COL_BACK := Color8(78, 146, 212)
const COL_BACK_DEEP := Color8(41, 97, 174)
## Grama do fundo do lago: um veu azul por cima da faixa de grama do chao submerso, para ela
## ficar "dentro" d'agua como as plantinhas (sem ele parecia gramado seco).
const COL_FUNDO := Color(0.05, 0.25, 0.60, 0.40)
const FUNDO_ALTURA := 6.0  # px da faixa de grama do tile de topo
## Tiles de topo de grama com flores/cogumelo (5 margaridas, 17 flores amarelas, 19 cogumelo):
## debaixo d'agua viram o 16 (grama lisa, sem flores) do mesmo tileset.
const TOPO_COM_FLORES := [Vector2i(1, 1), Vector2i(1, 4), Vector2i(3, 4)]
const TOPO_LISO := Vector2i(0, 4)

var _time := 0.0


func _ready() -> void:
	add_to_group("agua")
	var fundo := Node2D.new()
	fundo.name = "Fundo"
	fundo.z_as_relative = false
	fundo.z_index = -980
	fundo.draw.connect(func() -> void:
		var w := 16.0 * tiles_w
		var h := 16.0 * tiles_h
		fundo.draw_rect(Rect2(0, -h + 4, w, h - 4), COL_BACK)
		fundo.draw_rect(Rect2(0, -h * 0.5, w, h * 0.5), COL_BACK_DEEP))
	add_child(fundo)
	if not Engine.is_editor_hint():
		# o auto-tile da fase (Level._retile_grass) roda no _ready do pai, depois deste
		_fundo_sem_flores.call_deferred()


## Troca, na fileira de tiles logo abaixo do lago, os topos de grama floridos pela grama lisa.
func _fundo_sem_flores() -> void:
	if not is_inside_tree():
		return
	for layer: TileMapLayer in get_tree().get_nodes_in_group("solid_tiles"):
		if layer.tile_set == null or layer.tile_set.tile_size != Vector2i(16, 16) \
				or not layer.tile_set.has_source(0):
			continue
		var src := layer.tile_set.get_source(0) as TileSetAtlasSource
		if src == null or src.texture == null or not src.texture.resource_path.contains("grama"):
			continue
		for i in tiles_w:
			var p := global_position + Vector2(i * 16.0 + 8.0, 8.0)
			var c := layer.local_to_map(layer.to_local(p))
			if layer.get_cell_source_id(c) == 0 and layer.get_cell_atlas_coords(c) in TOPO_COM_FLORES:
				layer.set_cell(c, 0, TOPO_LISO)


func get_rect() -> Rect2:
	return Rect2(global_position.x, global_position.y - 16.0 * tiles_h,
		16.0 * tiles_w, 16.0 * tiles_h)


func surface_y() -> float:
	return global_position.y - 16.0 * tiles_h


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var w := 16.0 * tiles_w
	var h := 16.0 * tiles_h
	draw_rect(Rect2(0, -h + 4, w, h - 4), COL_BODY)
	# veu na grama do fundo (passa 3 px para os lados: a curva da grama no pe das margens)
	draw_rect(Rect2(-3.0, 0.0, w + 6.0, FUNDO_ALTURA), COL_FUNDO)
	var frame := int(_time * 16.0)  # 16 quadros por segundo (uma volta da espuma)
	for i in tiles_w:
		Sprites.draw_frame(self, "agua", Rect2(i * 16.0, -h, 16.0, 16.0), posmod(frame + i * 4, 16), Color(1, 1, 1, 0.85))
	# brilhinhos na superficie e raios de luz no fundo
	for i in tiles_w * 2:
		var ph := _time * 1.7 + i * 2.39
		var s := sin(ph)
		if s > 0.82:
			var gx := fposmod(i * 8.0 + i * i * 3.0, w - 4.0)
			var a := (s - 0.82) / 0.18
			draw_rect(Rect2(gx, -h + 5, 3, 1), Color(1, 1, 1, a))
			draw_rect(Rect2(gx + 1, -h + 4, 1, 3), Color(1, 1, 1, a * 0.6))
	# raios: linha a linha em px inteiros do jogo (um poligono seria rasterizado na resolucao
	# da janela, com bordas em degraus de 1 px da tela e deslizando em subpixel)
	var y0 := int(-h + 6.0)
	var y1 := -4
	for i in int(w / 48.0):
		var rx := floorf(i * 48.0 + 12.0 + sin(_time * 0.6 + i) * 6.0)
		var cor := Color(0.85, 0.95, 1.0, 0.05 + 0.03 * sin(_time + i))
		for y in range(y0, y1):
			var t := float(y - y0) / float(y1 - y0)
			var l := floorf(lerpf(rx, rx + 4.0, t))
			var r := floorf(lerpf(rx + 6.0, rx + 14.0, t))
			draw_rect(Rect2(l, y, r - l, 1.0), cor)
