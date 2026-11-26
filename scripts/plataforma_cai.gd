@tool
extends Node2D
## Plataforma que cai (Fases 6 a 8): solida, com rachaduras. Pisou (o pato ou uma caixa),
## ela treme por meio segundo, despenca (deixa de ser solida) e volta para o lugar alguns
## segundos depois (so volta se nada estiver no caminho).
## Origem no canto INFERIOR esquerdo, 1 tile de altura, largura em tiles de 16 px.

const Sprites := preload("res://scripts/sprites.gd")

@export var tiles_w: int = 2:
	set(v):
		tiles_w = v
		queue_redraw()
## Frames tremendo antes de cair.
@export var tempo_tremendo := 30
## Frames ate voltar depois de cair.
@export var tempo_volta := 180

const Particulas := preload("res://scripts/particulas.gd")
const FALL_SHOW_PX := 120.0  # depois de cair isso, some (ate voltar)

const COL_LIGHT := Color8(214, 198, 160)

var state := "parada"  # parada | tremendo | caindo | voltando
var _timer := 0
var _fall_y := 0.0
var _fall_v := 0.0
var _fade := 1.0
var _anim := 0.0


func _ready() -> void:
	add_to_group("plataforma_cai")
	if not Engine.is_editor_hint():
		add_to_group("solid")


func get_rect() -> Rect2:
	return Rect2(global_position.x, global_position.y - 16.0, 16.0 * tiles_w, 16.0)


## Algo com peso (pato, caixa) em pe em cima: o pe na altura do topo, encostando.
func _stepped_on() -> bool:
	var r := get_rect()
	for n in get_tree().get_nodes_in_group("weight"):
		if n.is_queued_for_deletion():
			continue
		if n.has_method("get_mask"):
			var m: Rect2 = n.get_mask()
			var feet := Rect2(m.position.x, m.end.y, m.size.x, 1.0)
			if absf(m.end.y - r.position.y) < 0.6 and feet.intersects(r):
				if n.is_in_group("player") and n.player_state == "dead":
					continue
				return true
	return false


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
	_anim += 1.0
	match state:
		"parada":
			if _stepped_on():
				state = "tremendo"
				_timer = tempo_tremendo
				Game.play_sfx("crack")
		"tremendo":
			_timer -= 1
			if _timer <= 0:
				state = "caindo"
				_timer = tempo_volta
				_fall_y = 0.0
				_fall_v = 0.0
				remove_from_group("solid")
				Particulas.emit(get_tree(), "pedrinha", get_rect().get_center(), 6)
				Game.play_sfx("fall")
		"caindo":
			_timer -= 1
			_fall_v = minf(_fall_v + 0.3, 6.0)
			_fall_y += _fall_v
			if _timer <= 0 and not _blocked():
				state = "voltando"
				_fade = 0.0
				add_to_group("solid")
		"voltando":
			_fade = minf(1.0, _fade + 0.05)
			if _fade >= 1.0:
				state = "parada"
	queue_redraw()


func _draw() -> void:
	var w := 16.0 * tiles_w
	var o := Vector2.ZERO
	var a := 1.0
	if state == "tremendo":
		o.x = 1.0 if int(_anim / 2.0) % 2 == 0 else -1.0
	elif state == "caindo":
		if _fall_y > FALL_SHOW_PX:
			return
		o.y = floorf(_fall_y)
		a = clampf(1.0 - _fall_y / 120.0, 0.0, 1.0)
	elif state == "voltando":
		a = _fade
	# pedra inteira parada; rachada tremendo, caindo e voltando (pedra_cai.png)
	var q := 0 if state == "parada" else 1
	for k in tiles_w:
		Sprites.draw_frame(self, "pedra_cai", Rect2(o.x + k * 16.0, o.y - 16.0, 16, 16), q, Color(1, 1, 1, a))
	# poeira caindo enquanto treme
	if state == "tremendo":
		for i in 3:
			var px := fposmod(i * 11.0 + _anim * 0.7, w)
			var py := fposmod(_anim * 1.5 + i * 7.0, 14.0)
			draw_rect(Rect2(px, py + 1.0, 1, 1), Color(COL_LIGHT, 0.8))
