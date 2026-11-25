@tool
extends Node2D
## Placa de pressao: afunda quando o pato ou uma caixa esta em cima e avisa os "alvos"
## (portas, plataformas moveis...) chamando set_active(true/false) neles.
## Origem no canto INFERIOR esquerdo (como o Block), largura em tiles de 16 px.
## Para ligar: no inspetor, em "alvos", aponte para os nos que devem reagir.

signal changed(pressed: bool)

@export var tiles_w: int = 1:
	set(v):
		tiles_w = v
		queue_redraw()
## Nos que recebem set_active(pressionada).
@export var alvos: Array[NodePath] = []

const COL_BASE := Color8(90, 90, 100)
const COL_BASE_DARK := Color8(50, 50, 60)
const COL_TOP := Color8(220, 60, 50)
const COL_TOP_DARK := Color8(140, 30, 30)

var pressed := false


func _ready() -> void:
	add_to_group("placa")


## Area que detecta peso: faixa de 4 px logo acima do chao.
func get_trigger() -> Rect2:
	return Rect2(roundf(global_position.x) + 1.0, roundf(global_position.y) - 4.0,
		16.0 * tiles_w - 2.0, 4.0)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or Game.game_state != "playing":
		return
	var now := false
	var area := get_trigger()
	for w in get_tree().get_nodes_in_group("weight"):
		if w.is_queued_for_deletion():
			continue
		if w.is_in_group("caixa") and w.state == "carried":
			continue
		if area.intersects(w.get_mask()):
			now = true
			break
	if now != pressed:
		pressed = now
		queue_redraw()
		Game.play_sfx("plate")
		changed.emit(pressed)
		for path in alvos:
			var target := get_node_or_null(path)
			if target != null and target.has_method("set_active"):
				target.set_active(pressed)


func _draw() -> void:
	var w := 16.0 * tiles_w
	draw_rect(Rect2(0, -2, w, 2), COL_BASE_DARK)
	draw_rect(Rect2(1, -3, w - 2, 1), COL_BASE)
	var top_h := 1.0 if pressed else 3.0
	draw_rect(Rect2(2, -3 - top_h, w - 4, top_h), COL_TOP_DARK if pressed else COL_TOP)
	if not pressed:
		draw_rect(Rect2(2, -6, w - 4, 1), Color8(255, 120, 100))
