@tool
extends Node2D
## Porta de madeira reforcada: solida quando fechada. Abre com set_active(true) vindo de uma
## placa de pressao (ou de qualquer script). Com "abre_com_sinal" desligado faz o contrario
## (fica aberta e o sinal fecha). So fecha quando nada esta no caminho.
## Com "trancada" ela ignora sinais: abre (para sempre) quando o pato encosta tendo uma chave
## (chave.gd), gastando a chave.
## Origem no canto INFERIOR esquerdo (como o Block), tamanho em tiles de 16 px.

@export var tiles_w: int = 1:
	set(v):
		tiles_w = v
		queue_redraw()
@export var tiles_h: int = 3:
	set(v):
		tiles_h = v
		queue_redraw()
## Ligado: o sinal abre. Desligado: comeca aberta e o sinal fecha.
@export var abre_com_sinal := true
## Porta com fechadura: so abre encostando com uma chave.
@export var trancada := false:
	set(v):
		trancada = v
		queue_redraw()

const COL_DARK := Color8(46, 46, 58)
const COL_STONE := Color8(118, 118, 132)
const COL_LIGHT := Color8(170, 170, 184)
const COL_WOOD_DARK := Color8(60, 30, 12)
const COL_WOOD := Color8(140, 82, 36)
const COL_WOOD_LIGHT := Color8(180, 116, 60)
const COL_IRON := Color8(70, 70, 84)
const COL_IRON_LIGHT := Color8(130, 130, 146)
const COL_LOCK_OUT := Color8(90, 60, 0)
const COL_LOCK := Color8(255, 206, 60)

var is_open := false
var _want_open := false
var _touching := false  # pato encostado sem chave (para o "negado" tocar uma vez so)


func _ready() -> void:
	add_to_group("porta")
	_want_open = not abre_com_sinal and not trancada
	_apply(_want_open, true)


func get_rect() -> Rect2:
	return Rect2(global_position.x, global_position.y - 16.0 * tiles_h,
		16.0 * tiles_w, 16.0 * tiles_h)


func set_active(on: bool) -> void:
	if trancada:
		return
	_want_open = on if abre_com_sinal else not on


## Trancada: o pato encostado de lado (1 px) com uma chave abre a porta.
func _try_unlock() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p == null or p.player_state == "dead":
		_touching = false
		return
	var touching: bool = p.get_mask().grow_individual(1, 0, 1, 0).intersects(get_rect())
	if touching and Game.keys > 0:
		Game.keys -= 1
		trancada = false
		_want_open = true
		Game.play_sfx("unlock")
	elif touching and not _touching:
		Game.play_sfx("denied")
	_touching = touching


func _apply(open: bool, silent := false) -> void:
	is_open = open
	if open:
		if is_in_group("solid"):
			remove_from_group("solid")
	else:
		add_to_group("solid")
	if not silent and not Engine.is_editor_hint():
		Game.play_sfx("door")
	queue_redraw()


func _blocked() -> bool:
	var r := get_rect()
	for group_name in ["weight", "enemy"]:
		for n in get_tree().get_nodes_in_group(group_name):
			if not n.is_queued_for_deletion() and r.intersects(n.get_mask()):
				return true
	return false


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or Game.game_state != "playing":
		return
	if trancada and not is_open:
		_try_unlock()
	if _want_open and not is_open:
		_apply(true)
	elif not _want_open and is_open and not _blocked():
		_apply(false)


func _draw() -> void:
	var w := 16.0 * tiles_w
	var h := 16.0 * tiles_h
	if is_open and not Engine.is_editor_hint():
		# aberta: so o batente de cima e um contorno apagado
		draw_rect(Rect2(0, -h, w, 3), COL_DARK)
		draw_rect(Rect2(0, -h, w, h), Color(COL_STONE, 0.18), false)
		return
	# madeira em tabuas verticais com faixas de ferro (contrasta com grama e com pedra)
	draw_rect(Rect2(0, -h, w, h), COL_WOOD_DARK)
	var plank := 0.0
	while plank < w:
		draw_rect(Rect2(plank + 1, -h + 1, minf(4.0, w - plank - 2.0), h - 2), COL_WOOD)
		draw_rect(Rect2(plank + 1, -h + 1, 1, h - 2), COL_WOOD_LIGHT)
		plank += 5.0
	var band := -h + 4.0
	while band < -2.0:
		draw_rect(Rect2(0, band, w, 3), COL_IRON)
		draw_rect(Rect2(0, band, w, 1), COL_IRON_LIGHT)
		draw_rect(Rect2(2, band + 1, 1, 1), COL_DARK)
		draw_rect(Rect2(w - 3, band + 1, 1, 1), COL_DARK)
		band += 16.0
	if trancada:
		# fechadura dourada no meio da porta
		var lx := w * 0.5 - 5.0
		var ly := -h * 0.5 - 6.0
		draw_rect(Rect2(lx, ly, 10, 12), COL_LOCK_OUT)
		draw_rect(Rect2(lx + 1, ly + 1, 8, 10), COL_LOCK)
		draw_rect(Rect2(lx + 4, ly + 3, 2, 3), COL_LOCK_OUT)
		draw_rect(Rect2(lx + 3, ly + 4, 4, 1), COL_LOCK_OUT)
		draw_rect(Rect2(lx + 4, ly + 6, 2, 3), COL_LOCK_OUT)
