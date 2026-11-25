extends Camera2D
## obj_camera: segue o jogador com suavizacao (lerp 0.8 em X, 0.1 em Y), limitado a sala.
## A altura do enquadramento vem de Level.camera_offset_y (Game.camera_offset_y), e o
## Game.camera_limit (arena do chefe) pode prender a camera numa faixa da sala.
## A posicao do canto superior esquerdo da view vai para Game.cam_pos e o tamanho da area
## mostrada para Game.view_size (paralaxe).
##
## ZOOM < 1 afasta a camera: com 5/6 a tela mostra 384x216 do mundo (20% a mais que os
## 320x180 do original). 5/6 mantem cada pixel do jogo com um numero inteiro de pixels da
## tela em 1080p (5 px) e em 4K (10 px), sem serrilhar a arte atual.

const ZOOM := 5.0 / 6.0
const BASE := Vector2(320, 180)
const OFF_X := 2.0


var _snapped := false
var _cur := Vector2.ZERO


static func view_size() -> Vector2:
	return BASE / ZOOM


func _ready() -> void:
	anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	zoom = Vector2(ZOOM, ZOOM)
	Game.view_size = view_size()
	make_current()
	_update_camera()


func _physics_process(_delta: float) -> void:
	_update_camera()


## Limita a uma faixa [lo, hi] (tamanho da faixa = 'span'); se a view for maior que a faixa,
## centraliza (ou encosta no fim, com align_end).
static func _fit(v: float, lo: float, span: float, view: float, align_end := false) -> float:
	if span <= view:
		return lo + span - view if align_end else lo + (span - view) * 0.5
	return clampf(v, lo, lo + span - view)


func _update_camera() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null or player.is_queued_for_deletion():
		return
	var view := view_size()

	var target := Vector2(
		(player.position.x + OFF_X) - view.x / 2.0,
		(player.position.y + Game.camera_offset_y) - view.y / 2.0)
	if Game.camera_limit.has_area():  # arena do chefe: a camera fica nela
		target.x = _fit(target.x, Game.camera_limit.position.x, Game.camera_limit.size.x, view.x)
	else:
		target.x = _fit(target.x, 0.0, Game.room_width, view.x)
	# sala mais baixa que a view: encosta embaixo (o que sobra aparece acima do teto)
	target.y = _fit(target.y, 0.0, Game.room_height, view.y, true)

	var new_pos := Vector2(lerpf(_cur.x, target.x, 0.8), lerpf(_cur.y, target.y, 0.1))
	if not _snapped:
		_snapped = true
		new_pos = target

	_cur = new_pos
	position = Vector2(floorf(_cur.x), floorf(_cur.y))
	Game.cam_pos = position
