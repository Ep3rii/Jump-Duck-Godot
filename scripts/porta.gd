@tool
extends Node2D
## Porta de madeira reforcada: solida quando fechada. Abre com set_active(true) vindo de uma
## placa de pressao (ou de qualquer script). Com "abre_com_sinal" desligado faz o contrario
## (fica aberta e o sinal fecha). So fecha quando nada esta no caminho.
## Com "trancada" ela ignora sinais: abre (para sempre) quando o pato encosta tendo uma chave
## (chave.gd), gastando a chave.
## Origem no canto INFERIOR esquerdo (como o Block), tamanho em tiles de 16 px.

const Sprites := preload("res://scripts/sprites.gd")

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

const Particulas := preload("res://scripts/particulas.gd")

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
		Particulas.emit(get_tree(), "brilho", get_rect().get_center(), 14)
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
	# arte: assets/sprites/arte/porta.png (topo, meio, base, fechadura, batente aberto)
	var w := 16.0 * tiles_w
	var h := 16.0 * tiles_h
	if is_open and not Engine.is_editor_hint():
		for i in tiles_w:
			Sprites.draw_frame(self, "porta", Rect2(i * 16.0, -h, 16, 16), 4)
		return
	for j in tiles_h:
		var peca := 1
		if j == 0:
			peca = 0
		elif j == tiles_h - 1:
			peca = 2
		for i in tiles_w:
			Sprites.draw_frame(self, "porta", Rect2(i * 16.0, -h + j * 16.0, 16, 16), peca)
	if trancada:
		Sprites.draw_frame(self, "porta", Rect2(w * 0.5 - 8.0, -h * 0.5 - 8.0, 16, 16), 3)
