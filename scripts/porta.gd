@tool
extends Node2D
## Porta / grade de pedra: solida quando fechada. Abre com set_active(true) vindo de uma
## placa de pressao (ou de qualquer script). Com "abre_com_sinal" desligado faz o contrario
## (fica aberta e o sinal fecha). So fecha quando nada esta no caminho.
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

const COL_DARK := Color8(46, 46, 58)
const COL_STONE := Color8(118, 118, 132)
const COL_LIGHT := Color8(170, 170, 184)

var is_open := false
var _want_open := false


func _ready() -> void:
	add_to_group("porta")
	_want_open = not abre_com_sinal
	_apply(_want_open, true)


func get_rect() -> Rect2:
	return Rect2(global_position.x, global_position.y - 16.0 * tiles_h,
		16.0 * tiles_w, 16.0 * tiles_h)


func set_active(on: bool) -> void:
	_want_open = on if abre_com_sinal else not on


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
	draw_rect(Rect2(0, -h, w, h), COL_DARK)
	for row in int(h / 8.0):
		var y := -h + row * 8.0
		var offset := 4.0 if row % 2 == 1 else 0.0
		var x := -offset
		while x < w:
			var bx := maxf(x, 0.0) + 1.0
			var bw := minf(x + 8.0, w) - bx - 1.0
			if bw > 0.0:
				draw_rect(Rect2(bx, y + 1, bw, 6), COL_STONE)
				draw_rect(Rect2(bx, y + 1, bw, 1), COL_LIGHT)
			x += 8.0
