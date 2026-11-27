@tool
extends Node2D
## Agua em que da para nadar (Fases 2 e 3). Diferente do perigo.tscn: aqui o pato boia na
## superficie, mergulha com BAIXO e tem folego limitado. Caixas boiam; jacares vivem aqui.
## Origem no canto INFERIOR esquerdo (como o Block), tamanho em tiles de 16 px.
## O veu da frente e um quadriculado (dither ordenado) na cor do fundo do lago: no fundo ele
## some (mesma cor) e no pato/jacare mergulhado vira pontinhos de agua -- "dentro" d'agua sem alfa.

const Sprites := preload("res://scripts/sprites.gd")
const PixelFx := preload("res://scripts/pixelfx.gd")

@export var tiles_w: int = 4:
	set(v):
		tiles_w = v
		queue_redraw()
@export var tiles_h: int = 3:
	set(v):
		tiles_h = v
		queue_redraw()

## Fundo opaco do lago (atras de tudo, na frente do parallax): sem ele os morros do fundo
## apareciam "dentro" d'agua. As mesmas duas faixas de azul de antes (metade de cima e metade
## funda), agora chapadas: o veu da frente usa estas cores e some por cima delas.
const COL_BACK := Color8(64, 134, 209)
const COL_BACK_DEEP := Color8(38, 100, 183)
## Veu da frente: fracao de pixels acesos (Bayer 4x4, os limiares mais baixos) na cor do fundo
## daquela altura. Leve (2/16, pontinhos em diagonal) para o pato mergulhado manter o contorno
## escuro e o laranja do bico.
const VEU_COBERTURA := 2.0 / 16.0
## Grama do fundo do lago: o mesmo quadriculado, mais denso (4/16), no azul fundo por cima da
## faixa de grama do chao submerso, para ela ficar "dentro" d'agua (sem ele parecia gramado seco).
const FUNDO_COBERTURA := 4.0 / 16.0
const FUNDO_ALTURA := 6.0  # px da faixa de grama do tile de topo
## Tiles de topo de grama com flores/cogumelo (5 margaridas, 17 flores amarelas, 19 cogumelo):
## debaixo d'agua viram o 16 (grama lisa, sem flores) do mesmo tileset.
const TOPO_COM_FLORES := [Vector2i(1, 1), Vector2i(1, 4), Vector2i(3, 4)]
const TOPO_LISO := Vector2i(0, 4)
## Brilhos e raios: cores opacas da Endesga 32 (o raio e um azul so um pouco mais claro que a
## agua; quanto se ve dele e a fracao de pixels acesos no dither, RAIO_COBERTURA = 3/16).
const BRILHO := Color("#ffffff")
const BRILHO_FRACO := Color("#c0cbdc")
const RAIO := Color("#0099db")
const RAIO_COBERTURA := 3.0 / 16.0
## Fundo do lago + raios de luz num shader so (atras do pato): os raios sao faixas inclinadas de
## pixels soltos em dither ordenado (Bayer 4x4, preso ao mundo), opacos e da paleta; a forca
## muda em degraus de 1/16, nunca por alfa. Um raio a cada 48 px, que balanca devagar. Os raios
## acendem os limiares MAIS ALTOS do Bayer (o veu usa os mais baixos): o veu nao os apaga.
const SHADER_FUNDO := """
shader_type canvas_item;
uniform float tempo = 0.0;
uniform vec2 origem = vec2(0.0);
uniform float largura = 64.0;
uniform float altura = 48.0;
uniform float cobertura = 0.1875;
uniform vec4 raio : source_color = vec4(1.0);
varying vec2 px;

//BAYER

void vertex() {
	px = VERTEX;
}

void fragment() {
	vec2 p = floor(px);
	float y0 = floor(-altura + 6.0);
	float y1 = -4.0;
	if (p.y >= y0 && p.y < y1) {
		float i = floor(p.x / 48.0);  // o raio i fica todo dentro de [48 i, 48 i + 48)
		if (i < floor(largura / 48.0)) {
			float rx = floor(i * 48.0 + 12.0 + sin(tempo * 0.6 + i) * 6.0);
			float t = (p.y - y0) / (y1 - y0);
			float l = floor(mix(rx, rx + 4.0, t));
			float r = floor(mix(rx + 6.0, rx + 14.0, t));
			float forca = cobertura + floor(sin(tempo + i) + 0.5) / 16.0;
			// mais ralo no pe do raio (some em degraus, nao em degrade)
			float cob = forca * (t < 0.6 ? 1.0 : 0.5);
			if (p.x >= l && p.x < r && bayer4(origem + p) >= 1.0 - cob) {
				COLOR = raio;
			}
		}
	}
}
"""

static var _sh_fundo: Shader

var _time := 0.0
var _mat_fundo: ShaderMaterial
var _veu: Node2D


func _ready() -> void:
	add_to_group("agua")
	var fundo := Node2D.new()
	fundo.name = "Fundo"
	fundo.z_as_relative = false
	fundo.z_index = -980
	if _sh_fundo == null:
		_sh_fundo = Shader.new()
		_sh_fundo.code = PixelFx.com_bayer(SHADER_FUNDO)
	_mat_fundo = ShaderMaterial.new()
	_mat_fundo.shader = _sh_fundo
	_mat_fundo.set_shader_parameter("cobertura", RAIO_COBERTURA)
	_mat_fundo.set_shader_parameter("raio", RAIO)
	fundo.material = _mat_fundo
	fundo.draw.connect(func() -> void:
		var w := 16.0 * tiles_w
		var h := 16.0 * tiles_h
		fundo.draw_rect(Rect2(0, -h + 4, w, h - 4), COL_BACK)
		fundo.draw_rect(Rect2(0, -h * 0.5, w, h * 0.5), COL_BACK_DEEP))
	add_child(fundo)
	# veu da frente (filho: desenha depois da agua, por cima do pato mergulhado); o alfa da cor
	# vira cobertura do quadriculado no PixelFx.material_dither(), pixel cheio ou vazio
	_veu = Node2D.new()
	_veu.name = "Veu"
	_veu.material = PixelFx.material_dither()
	_veu.draw.connect(_draw_veu)
	add_child(_veu)
	_atualiza_fundo()
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
	_atualiza_fundo()
	queue_redraw()


func _atualiza_fundo() -> void:
	if _mat_fundo == null:
		return
	_mat_fundo.set_shader_parameter("tempo", _time)
	_mat_fundo.set_shader_parameter("origem", global_position.floor())
	_mat_fundo.set_shader_parameter("largura", 16.0 * tiles_w)
	_mat_fundo.set_shader_parameter("altura", 16.0 * tiles_h)
	if _veu != null:
		_veu.queue_redraw()


## Veu em quadriculado: abaixo da espuma (opaca, 16 px) ate o fundo, na cor do fundo de cada
## metade (no fundo nao aparece; no que esta mergulhado vira pontinhos de agua).
func _draw_veu() -> void:
	var w := 16.0 * tiles_w
	var h := 16.0 * tiles_h
	if h > 16.0:
		var meio := -h * 0.5
		var topo := -h + 16.0
		if topo < meio:
			_veu.draw_rect(Rect2(0, topo, w, meio - topo), Color(COL_BACK, VEU_COBERTURA))
		_veu.draw_rect(Rect2(0, maxf(topo, meio), w, -maxf(topo, meio)), Color(COL_BACK_DEEP, VEU_COBERTURA))
	# grama do fundo (passa 3 px para os lados: a curva da grama no pe das margens)
	_veu.draw_rect(Rect2(-3.0, 0.0, w + 6.0, FUNDO_ALTURA), Color(COL_BACK_DEEP, FUNDO_COBERTURA))


func _draw() -> void:
	var w := 16.0 * tiles_w
	var h := 16.0 * tiles_h
	var frame := int(_time * 16.0)  # 16 quadros por segundo (uma volta da espuma)
	for i in tiles_w:
		Sprites.draw_frame(self, "agua", Rect2(i * 16.0, -h, 16.0, 16.0), posmod(frame + i * 4, 16))
	# brilhinhos na superficie: opacos e da paleta, em degraus (ponto -> cruz -> ponto), sem alfa
	for i in tiles_w * 2:
		var ph := _time * 1.7 + i * 2.39
		var s := sin(ph)
		if s > 0.82:
			var gx := fposmod(i * 8.0 + i * i * 3.0, w - 4.0)
			gx = floorf(gx)
			if s > 0.93:  # no pico, a cruzinha
				draw_rect(Rect2(gx, -h + 5, 3, 1), BRILHO)
				draw_rect(Rect2(gx + 1, -h + 4, 1, 3), BRILHO)
			else:
				draw_rect(Rect2(gx + 1, -h + 5, 1, 1), BRILHO_FRACO)
