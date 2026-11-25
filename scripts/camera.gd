extends Camera2D
## obj_camera: segue o jogador com suavizacao (lerp 0.8 em X, 0.1 em Y), limitado a sala.
## A altura do enquadramento vem de Level.camera_offset_y (Game.camera_offset_y).
## A posicao do canto superior esquerdo da view tambem vai para Game.cam_pos (parallax).

const VIEW_W := 320.0
const VIEW_H := 180.0
const OFF_X := 2.0


var _snapped := false
var _cur := Vector2.ZERO


func _ready() -> void:
	anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	make_current()
	_update_camera()


func _physics_process(_delta: float) -> void:
	_update_camera()


func _update_camera() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null or player.is_queued_for_deletion():
		return

	var target := Vector2(
		(player.position.x + OFF_X) - VIEW_W / 2.0,
		(player.position.y + Game.camera_offset_y) - VIEW_H / 2.0)
	target.x = clampf(target.x, 0.0, Game.room_width - VIEW_W)
	target.y = clampf(target.y, 0.0, Game.room_height - VIEW_H)

	var new_pos := Vector2(lerpf(_cur.x, target.x, 0.8), lerpf(_cur.y, target.y, 0.1))
	if not _snapped:
		_snapped = true
		new_pos = target

	_cur = new_pos
	position = Vector2(floorf(_cur.x), floorf(_cur.y))
	Game.cam_pos = position
