extends Node2D
## obj_player do GameMaker. A logica de movimento e colisao foi portada passo a passo
## (60 passos por segundo = _physics_process) para manter exatamente a mesma sensacao:
## gravidade 0.25, pulo -4, pulo duplo, buffer de pulo, dano por queda longa etc.
##
## Colisao: o GameMaker usa a mascara de colisao do sprite. Aqui a mascara e um Rect2
## equivalente (bbox 9..23 x 8..22 do sprite 32x32 com origem 16,23), espelhada quando
## o jogador olha para a esquerda, e testada contra os solidos (ver solids.gd).

const Solids := preload("res://scripts/solids.gd")
const EfeitoScene := preload("res://scenes/efeito.tscn")

const HURT_TIME := 30  # frames parado no estado "hurt"
const DEATH_TIME := 60  # frames da animacao de morte ate a tela de fim de jogo
const INVULN_TIME := 120  # frames de invulnerabilidade depois do dano
const FALL_DAMAGE_HEIGHT := 96.0  # queda (px) que causa dano ao pousar
const HURT_HOP := -2.0  # pulinho ao levar dano
const KNOCKBACK_SPEED := 1.5  # recuo horizontal inicial ao levar dano

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
var player_state := "alive"  # alive | hurt | dead
var invulnerability_timer := 0
var state_timer := 0
var fall_start_y := -1.0
var xscale := 1  # image_xscale: 1 = olhando p/ direita, -1 = esquerda
var move := 0
var knockback_dir := 0

var _anim := "idle"
var _solids: Array = []

@onready var sprite: AnimatedSprite2D = $Sprite


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
	return Solids.hits(_solids, _mask(px, py))


## Move spdh pixels; encostando numa parede, chega pixel a pixel e zera spdh.
func _move_x() -> void:
	if spdh != 0.0 and _place_meeting(position.x + spdh, position.y):
		var guard := 0
		while not _place_meeting(position.x + signf(spdh), position.y) and guard < 256:
			position.x += signf(spdh)
			guard += 1
		spdh = 0.0
	position.x += spdh


func _move_y() -> void:
	if _place_meeting(position.x, position.y + spdv):
		# Encosta no pixel inteiro (sem isso o pato podia parar 0.3 px dentro do chao).
		position.y = roundf(position.y)
		var guard := 0
		while not _place_meeting(position.x, position.y + signf(spdv)) and guard < 256:
			position.y += signf(spdv)
			guard += 1
		spdv = 0.0
	position.y += spdv


# --------------------------------------------------------------------- dano
## source_x: posicao x de quem causou o dano (para o recuo). NAN = sem recuo (queda etc.).
func take_damage(source_x: float = NAN) -> void:
	if Game.game_state != "playing" or player_state != "alive" or invulnerability_timer > 0:
		return
	if Game.debug_invincible:
		return

	Game.player_lives = maxi(0, Game.player_lives - 1)
	state_timer = 0
	player_state = "dead" if Game.player_lives == 0 else "hurt"
	knockback_dir = 0
	if not is_nan(source_x):
		knockback_dir = 1 if position.x >= source_x else -1
	spdv = HURT_HOP
	jump_buffer = 0
	fall_start_y = -1.0
	sprite.modulate.a = 1.0
	if player_state == "hurt":
		invulnerability_timer = INVULN_TIME
		Game.invulnerability_remaining = INVULN_TIME
	_set_anim("dead" if player_state == "dead" else "hurt")
	sprite.frame = 0  # image_index = 0


func _set_anim(anim_name: String) -> void:
	if anim_name != _anim:
		_anim = anim_name
		sprite.play(anim_name)


# --------------------------------------------------------------------- Step
func _physics_process(_delta: float) -> void:
	if Game.game_state != "playing":
		return

	_solids = Solids.snapshot(get_tree())

	if invulnerability_timer > 0:
		invulnerability_timer -= 1
		Game.invulnerability_remaining = invulnerability_timer

	if player_state == "alive":
		_step_alive()
	else:
		_step_hurt_or_dead()
	if is_queued_for_deletion():
		return

	_check_out_of_bounds()
	_collisions()
	_update_sprite()


func _step_alive() -> void:
	move = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	spdh = move * spd_player
	_move_x()

	if _place_meeting(position.x, position.y + 1.0):
		if fall_start_y >= 0.0:
			if position.y - fall_start_y >= FALL_DAMAGE_HEIGHT:
				take_damage()
			fall_start_y = -1.0
		pulos = 2
	else:
		if spdv >= 0.0 and fall_start_y < 0.0:
			fall_start_y = position.y
		spdv = minf(spdv + gravidade, max_fall_speed)

	if player_state != "alive":  # a queda acabou de machucar
		_move_y()
		return

	# Buffer de pulo: aperta um pouco antes de pousar e o pulo sai ao tocar o chao.
	# O aperto que despausou/confirmou o menu nesse mesmo frame nao conta (B1).
	var jump_pressed := Input.is_action_just_pressed("jump") \
		and Engine.get_physics_frames() != Game.resume_frame
	jump_buffer = 6 if jump_pressed else maxi(0, jump_buffer - 1)
	if jump_buffer > 0 and pulos > 0:
		spdv = spd_pulo
		pulos -= 1
		jump_buffer = 0
		fall_start_y = -1.0  # o pulo duplo "amortece" a queda (B4)

	_move_y()

	if move != 0:
		xscale = move


## Machucado ou morrendo: sem controle, mas com gravidade e recuo (antes congelava no ar, B2).
func _step_hurt_or_dead() -> void:
	state_timer += 1
	move = 0
	if player_state == "hurt":
		spdh = knockback_dir * KNOCKBACK_SPEED * maxf(0.0, 1.0 - float(state_timer) / HURT_TIME)
	else:
		spdh = 0.0
	_move_x()
	if not _place_meeting(position.x, position.y + 1.0):
		spdv = minf(spdv + gravidade, max_fall_speed)
	fall_start_y = -1.0
	_move_y()

	if player_state == "hurt" and state_timer >= HURT_TIME:
		player_state = "alive"
		state_timer = 0
		_set_anim("idle")
		sprite.frame = 0
	elif player_state == "dead" and state_timer >= DEATH_TIME:
		Game.game_state = "gameover"
		Game.ui_selection = 0
		queue_free()


## Rede de seguranca caso o jogador saia do mapa.
func _check_out_of_bounds() -> void:
	if position.y > Game.room_height + 96 or position.x < -64 or position.x > Game.room_width + 64:
		position.x = start_x
		position.y = start_y
		spdv = 0.0
		fall_start_y = -1.0
		take_damage()


func _update_sprite() -> void:
	sprite.flip_h = xscale < 0
	if player_state != "alive":
		_set_anim("dead" if player_state == "dead" else "hurt")
		sprite.speed_scale = 0.2
		sprite.modulate.a = 1.0
		var last := sprite.sprite_frames.get_frame_count("dead") - 1
		if player_state == "dead" and sprite.frame >= last:
			sprite.frame = last
			sprite.speed_scale = 0.0
		return

	var next_anim := "idle"
	if move != 0:
		next_anim = "run"
	if spdv < 0.0:
		next_anim = "jump"
	elif spdv > 0.0:
		next_anim = "fall"

	_set_anim(next_anim)
	sprite.speed_scale = 1.0
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
	_spawn_efeito(Vector2(flor.position.x, flor.position.y - 6.0))
	flor.queue_free()
	Game.collect_flower()


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
		take_damage(raposa.position.x)
