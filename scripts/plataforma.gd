@tool
extends Node2D
## Plataforma movel (solida): vai e volta entre a posicao inicial e inicial + deslocamento,
## levando junto o pato e as caixas que estiverem em cima. Pode ficar parada ate receber
## set_active(true) de uma placa de pressao (desligue "ativa" no inspetor).
## Origem no canto INFERIOR esquerdo, 1 tile de altura, largura em tiles de 16 px.

const Sprites := preload("res://scripts/sprites.gd")

@export var tiles_w: int = 3:
	set(v):
		tiles_w = v
		queue_redraw()
## Ponto final, relativo a posicao inicial (px).
@export var deslocamento := Vector2(96, 0):
	set(v):
		deslocamento = v
		queue_redraw()
## Pixels por frame (60 frames por segundo).
@export var velocidade := 0.5
## Frames parada em cada ponta.
@export var espera := 30
## Desligada: so anda enquanto receber set_active(true).
@export var ativa := true

## Blocos do tileset de grama (linha * 4 + coluna): plataforma fina e bloquinho sozinho.
const TILE_ESQ := 8
const TILE_MEIO := 9
const TILE_DIR := 10
const TILE_SOZINHO := 7

var last_delta := Vector2.ZERO
var _origin := Vector2.ZERO
var _t := 0.0  # 0 = inicio, 1 = fim
var _dir := 1.0
var _wait := 0


func _ready() -> void:
	add_to_group("solid")
	add_to_group("plataforma")
	_origin = position


func get_rect() -> Rect2:
	return Rect2(position.x, position.y - 16.0, 16.0 * tiles_w, 16.0)


func set_active(on: bool) -> void:
	ativa = on


## Quem esta em cima (pato e caixas paradas): pe encostando no topo da plataforma.
func _riders() -> Array:
	var r := get_rect()
	var probe := Rect2(r.position.x, r.position.y - 1.0, r.size.x, 1.0)
	var out := []
	for p in get_tree().get_nodes_in_group("player"):
		if p.player_state != "dead" and probe.intersects(p.get_mask()) and not r.intersects(p.get_mask()):
			out.append(p)
	for c in get_tree().get_nodes_in_group("caixa"):
		if c.state == "idle" and probe.intersects(c.get_rect()) and not r.intersects(c.get_rect()):
			out.append(c)
	return out


func _physics_process(_delta: float) -> void:
	last_delta = Vector2.ZERO
	if Engine.is_editor_hint() or Game.game_state != "playing" or not ativa:
		return
	if _wait > 0:
		_wait -= 1
		return
	var length := deslocamento.length()
	if length <= 0.0:
		return
	var riders := _riders()
	var old := position
	_t = clampf(_t + _dir * velocidade / length, 0.0, 1.0)
	if _t == 0.0 or _t == 1.0:
		_dir = -_dir
		_wait = espera
	position = _origin + deslocamento * _t
	last_delta = position - old
	for rider in riders:
		rider.carry_by(last_delta, self)


## Desenhada com os blocos de plataforma fina do tileset de grama (ponta esquerda, meio e
## ponta direita; o bloquinho sozinho quando tem 1 tile).
func _draw() -> void:
	var tiles := Sprites.art("tileset_grama")
	for i in tiles_w:
		var idx := TILE_MEIO
		if tiles_w == 1:
			idx = TILE_SOZINHO
		elif i == 0:
			idx = TILE_ESQ
		elif i == tiles_w - 1:
			idx = TILE_DIR
		draw_texture_rect_region(tiles, Rect2(i * 16.0, -16.0, 16.0, 16.0),
			Rect2((idx % 4) * 32.0, (idx / 4) * 32.0, 32.0, 32.0))
	if Engine.is_editor_hint():
		# caminho e posicao final
		var end := deslocamento
		draw_line(Vector2(8 * tiles_w, -8), end + Vector2(8 * tiles_w, -8), Color(1, 1, 0, 0.8))
		draw_rect(Rect2(end.x, end.y - 16, 16 * tiles_w, 16), Color(1, 1, 0, 0.8), false)
