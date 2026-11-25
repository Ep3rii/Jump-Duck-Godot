extends Node2D
## obj_player do GameMaker. A logica de movimento e colisao foi portada passo a passo
## (60 passos por segundo = _physics_process) para manter exatamente a mesma sensacao:
## gravidade 0.25, pulo -4, pulo duplo, buffer de pulo, dano por queda longa etc.
##
## Colisao: o GameMaker usa a mascara de colisao do sprite. Aqui a mascara e um Rect2
## equivalente (bbox 9..23 x 8..22 do sprite 32x32 com origem 16,23), espelhada quando
## o jogador olha para a esquerda, e testada contra os blocos do grupo "solid".

const SPR_ORIGIN := Vector2(16, 23)

var spdh := 0.0
var spdv := 0.0
var spd_player := 2.0

var gravidade := 0.25
var spd_pulo := -4.0
var max_fall_speed := 6.0
var jump_buffer := 0
var start_x := 0.0
var start_y := 0.0

var pulos := 2
var var_flor01 := 0
var is_aiming := false
var player_state := "alive"  # alive | hurt | dead
var invulnerability_timer := 0
var state_timer := 0
var fall_start_y := -1.0
var spr_posicao := 1
var xscale := 1  # image_xscale: 1 = olhando p/ direita, -1 = esquerda
var move := 0

var _anim := "idle"
var _solids: Array = []

@onready var sprite: AnimatedSprite2D = $Sprite
const EfeitoScene := preload("res://scenes/efeito.tscn")


func _ready() -> void:
	add_to_group("player")
	start_x = position.x
	start_y = position.y
	invulnerability_timer = Game.invulnerability_remaining
	sprite.play(_anim)


# ------------------------------------------------------------------ colisao
## Mascara de colisao em (px, py). O GameMaker arredonda a posicao para pixels inteiros.
func _mask(px: float, py: float) -> Rect2:
	var rx := roundf(px)
	var ry := roundf(py)
	if xscale >= 0:
		return Rect2(rx - 7.0, ry - 15.0, 15.0, 15.0)
	return Rect2(rx - 8.0, ry - 15.0, 15.0, 15.0)


func _place_meeting(px: float, py: float) -> bool:
	var m := _mask(px, py)
	for block in _solids:
		if m.intersects(block.get_rect()):
			return true
	return false


# --------------------------------------------------------------------- dano
func take_damage() -> void:
	if Game.game_state != "playing" or player_state != "alive" or invulnerability_timer > 0:
		return

	Game.player_lives = maxi(0, Game.player_lives - 1)
	state_timer = 0
	player_state = "dead" if Game.player_lives == 0 else "hurt"
	sprite.modulate.a = 1.0
	if player_state == "hurt":
		invulnerability_timer = 120
		Game.invulnerability_remaining = 120
	_set_anim("dead" if player_state == "dead" else "hurt")
	sprite.frame = 0  # image_index = 0


func _set_anim(anim_name: String) -> void:
	if anim_name != _anim:
		_anim = anim_name
		sprite.play(anim_name)


# --------------------------------------------------------------------- Step
func _physics_process(_delta: float) -> void:
	_step()
	if is_queued_for_deletion():
		return
	_collisions()


func _step() -> void:
	if Game.game_state != "playing":
		return

	if player_state != "alive":
		state_timer += 1
		if invulnerability_timer > 0:
			invulnerability_timer -= 1
			Game.invulnerability_remaining = invulnerability_timer
		spdh = 0.0
		spdv = 0.0
		_set_anim("dead" if player_state == "dead" else "hurt")
		sprite.speed_scale = 0.2
		if player_state == "dead" and sprite.frame >= sprite.sprite_frames.get_frame_count("dead") - 1:
			sprite.frame = sprite.sprite_frames.get_frame_count("dead") - 1
			sprite.speed_scale = 0.0

		if player_state == "hurt" and state_timer >= 30:
			player_state = "alive"
			state_timer = 0
			_set_anim("idle")
			sprite.frame = 0
			sprite.speed_scale = 1.0
		if player_state == "dead" and state_timer >= 60:
			Game.game_state = "gameover"
			Game.ui_selection = 0
			queue_free()
		return

	_solids = get_tree().get_nodes_in_group("solid")

	if invulnerability_timer > 0:
		invulnerability_timer -= 1
		Game.invulnerability_remaining = invulnerability_timer

	move = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	spdh = move * spd_player

	if spdh != 0.0 and _place_meeting(position.x + spdh, position.y):
		var guard := 0
		while not _place_meeting(position.x + signf(spdh), position.y) and guard < 256:
			position.x += signf(spdh)
			guard += 1
		spdh = 0.0

	position.x += spdh

	var grounded := _place_meeting(position.x, position.y + 1.0)
	if grounded:
		if fall_start_y >= 0.0:
			if position.y - fall_start_y >= 96.0:
				take_damage()
			fall_start_y = -1.0
		pulos = 2
	else:
		if spdv >= 0.0 and fall_start_y < 0.0:
			fall_start_y = position.y
		spdv = minf(spdv + gravidade, max_fall_speed)

	# Buffer de pulo: aperta um pouco antes de pousar e o pulo sai ao tocar o chao
	jump_buffer = 6 if Input.is_action_just_pressed("jump") else maxi(0, jump_buffer - 1)
	if jump_buffer > 0 and pulos > 0:
		spdv = spd_pulo
		pulos -= 1
		jump_buffer = 0

	if _place_meeting(position.x, position.y + spdv):
		var guard_v := 0
		while not _place_meeting(position.x, position.y + signf(spdv)) and guard_v < 256:
			position.y += signf(spdv)
			guard_v += 1
		spdv = 0.0

	position.y += spdv

	# Rede de seguranca caso o jogador saia do mapa
	if position.y > Game.room_height + 96 or position.x < -64 or position.x > Game.room_width + 64:
		position.x = start_x
		position.y = start_y
		spdv = 0.0
		fall_start_y = -1.0
		take_damage()

	if player_state != "alive":
		return

	is_aiming = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

	var next_anim := "idle"
	if move != 0:
		spr_posicao = move
		xscale = spr_posicao
		next_anim = "run"

	if spdv < 0.0:
		next_anim = "jump"
	elif spdv > 0.0:
		next_anim = "fall"

	_set_anim(next_anim)
	sprite.speed_scale = 1.0
	sprite.flip_h = xscale < 0
	var blink := invulnerability_timer > 0 and invulnerability_timer % 12 < 6
	sprite.modulate.a = 0.35 if blink else 1.0


# ---------------------------------------------------------- eventos de colisao
func _collisions() -> void:
	for flor in get_tree().get_nodes_in_group("flor"):
		if not flor.is_queued_for_deletion() and _mask(position.x, position.y).intersects(flor.get_mask()):
			_on_flor(flor)

	for raposa in get_tree().get_nodes_in_group("raposa"):
		if not raposa.is_queued_for_deletion() and _mask(position.x, position.y).intersects(raposa.get_mask()):
			_on_raposa(raposa)


func _spawn_efeito(pos: Vector2) -> void:
	var fx = EfeitoScene.instantiate()
	fx.position = pos
	get_parent().add_child(fx)


# Collision_obj_flor01
func _on_flor(flor) -> void:
	if Game.game_state != "playing":
		return

	var_flor01 += 1
	Game.current_collectibles += 1
	_spawn_efeito(Vector2(flor.position.x, flor.position.y - 6.0))
	flor.queue_free()

	if Game.current_collectibles >= Game.total_collectibles:
		Game.finish_level()


# Collision_obj_raposa: pisar derrota o inimigo; encostar de lado causa dano
func _on_raposa(raposa) -> void:
	if Game.game_state != "playing":
		return

	var bbox_bottom := roundf(position.y) - 1.0
	if spdv > 0.0 and (bbox_bottom - spdv) < raposa.position.y - 6.0:
		_spawn_efeito(Vector2(raposa.position.x, raposa.position.y - 16.0))
		raposa.queue_free()
		spdv = spd_pulo * 0.8
		pulos = 1
		fall_start_y = -1.0
	else:
		take_damage()
