extends Node2D
## obj_player do GameMaker. A logica de movimento e colisao foi portada passo a passo
## (60 passos por segundo = _physics_process) para manter exatamente a mesma sensacao:
## gravidade 0.25, pulo -4, pulo duplo, buffer de pulo, dano por queda longa etc.
##
## Colisao: o GameMaker usa a mascara de colisao do sprite. Aqui a mascara e um Rect2
## equivalente (bbox 9..23 x 8..22 do sprite 32x32 com origem 16,23), espelhada quando
## o jogador olha para a esquerda, e testada contra os solidos (ver solids.gd).

const Solids := preload("res://scripts/solids.gd")
const Vento := preload("res://scripts/vento.gd")
const Particulas := preload("res://scripts/particulas.gd")
const Sprites := preload("res://scripts/sprites.gd")

## Animacoes do pato (16x16 por quadro, paleta Endesga 32).
## As outras continuam com os quadros antigos ate serem redesenhadas e aprovadas.
const ART_ANIMS := {
	# 16 quadros por animacao (tools/arte/pato16.py); fps escolhido para cada ciclo durar o
	# mesmo que antes (correr 0,5 s, cair 0,75 s, parado 2 s)
	"idle": ["res://assets/sprites/arte/pato_parado.png", 16, 8.0],
	"run": ["res://assets/sprites/arte/pato_correndo.png", 16, 32.0],
	"jump": ["res://assets/sprites/arte/pato_pulando.png", 16, 32.0, false],
	"apex": ["res://assets/sprites/arte/pato_apice.png", 16, 48.0, false],
	"fall": ["res://assets/sprites/arte/pato_caindo.png", 16, 21.0],
	"hurt": ["res://assets/sprites/arte/pato_dano.png", 16, 48.0],
	"dead": ["res://assets/sprites/arte/pato_morte.png", 16, 14.0],
	# olhar para cima / para baixo: vira a cabeca, segura a pose e pisca; para no ultimo quadro
	"look_up": ["res://assets/sprites/arte/pato_olhando_cima.png", 16, 16.0, false],
	"look_down": ["res://assets/sprites/arte/pato_olhando_baixo.png", 16, 16.0, false],
}
## Olhar: quadros segurando CIMA/BAIXO parado no chao antes de a camera deslizar, e quantos px
## ela mostra a mais acima/abaixo (camera.gd soma Game.camera_olhar ao enquadramento).
const OLHAR_ESPERA := 24
const OLHAR_PX := 64.0
## Mergulhado: pato deitado, pes batendo (laco de 1 s). Fica fora de ART_ANIMS porque o menu e a
## cutscene montam o pato com ART_ANIMS e nao precisam dela; so entra se a tira ja foi importada
## (sem ela o pato mergulhado volta a usar a queda).
const DIVE_ANIM := ["res://assets/sprites/arte/pato_mergulhando.png", 16, 16.0]
## Tremor do dano feito aqui (o pato_dano.png tem o pato inteiro, sem deslocar): x do desenho
## em pixels do jogo, pelo quadro da animacao "hurt" ([0, 1, 0, -1][(quadro / 2) % 4]).
const HURT_SHAKE: Array[int] = [0, 1, 0, -1]
## Velocidade vertical abaixo da qual, no ar, o pato esta no "apice" (transicao entre subir e cair).
const APEX_SPEED := 0.8
## Ponto do quadro de 16 que fica nos pes: a ultima linha de contorno cai sobre a borda do chao.
const ART_ORIGIN := Vector2(8, 15)

const HURT_TIME := 30  # frames parado no estado "hurt"

## Olhando: -1 cima, 1 baixo, 0 nao; e ha quantos quadros segura a mesma direcao.
var olhar_dir := 0
var olhar_quadros := 0
const DEATH_TIME := 60  # frames da animacao de morte ate a tela de fim de jogo
const INVULN_TIME := 120  # frames de invulnerabilidade depois do dano
const FALL_DAMAGE_HEIGHT := 96.0  # queda (px) que causa dano ao pousar
const HURT_HOP := -2.0  # pulinho ao levar dano
const KNOCKBACK_SPEED := 1.5  # recuo horizontal inicial ao levar dano
const PUSH_SPEED := 1.0  # velocidade andando contra uma caixa
const CLIMB_SPEED := 1.0  # subindo/descendo cipo
const SWIM_SPEED := 1.5  # nadando na superficie
const DIVE_SPEED := 1.2  # nadando debaixo d'agua
const FLOAT_DEPTH := 6.0  # o pe fica 6 px abaixo da linha d'agua (meio pato submerso)
const AIR_MAX := 300  # folego: 5 s debaixo d'agua
const LIFT_MAX := 2.5  # velocidade maxima subindo numa corrente de ar

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
var carrying: Node2D = null  # caixa acima da cabeca
var climbing := false
var swim := "none"  # none | surface (boiando) | dive (mergulhado)
var air := AIR_MAX

var _anim := "idle"
var _squash := Vector2.ONE  # estica no pulo, achata no pouso (volta sozinho para 1)
var _run_dust := 0
var _solids: Array = []

var _art: AnimatedSprite2D  # sprite do pato (arte nova, assets/sprites/arte/pato_*.png)


func _ready() -> void:
	add_to_group("player")
	add_to_group("weight")  # pressiona placas
	add_to_group("sombra")  # sombras.gd
	add_to_group("luz")  # luz.gd: o pato nunca some no escuro
	start_x = position.x
	start_y = position.y
	invulnerability_timer = Game.invulnerability_remaining
	var anims := ART_ANIMS.duplicate()
	if ResourceLoader.exists(DIVE_ANIM[0]):
		anims["dive"] = DIVE_ANIM
	_art = Sprites.make_art_sprite(Sprites.art_frames(anims), ART_ORIGIN)
	_art.name = "Arte"
	add_child(_art)
	_art.play(_anim)


## Sombra no chao (some quando o pato esta dentro d'agua).
func sombra_largura() -> float:
	return 0.0 if swim != "none" else 13.0


## Um clarao suave em volta do pato nas fases escuras (luz.gd).
func luzes() -> Array:
	return [[global_position + Vector2(0, -8), 28.0, Color(1.0, 1.0, 1.0), 0.85]]


# ------------------------------------------------------------------ colisao
## Mascara de colisao em (px, py). O GameMaker arredonda a posicao para pixels inteiros.
func _mask(px: float, py: float) -> Rect2:
	var rx := roundf(px)
	var ry := roundf(py)
	if xscale >= 0:
		return Rect2(rx - 7.0, ry - 15.0, 15.0, 15.0)
	return Rect2(rx - 8.0, ry - 15.0, 15.0, 15.0)


## Mascara na posicao atual (placas, plataformas, caixas e inimigos usam).
func get_mask() -> Rect2:
	return _mask(position.x, position.y)


func _place_meeting(px: float, py: float) -> bool:
	return Solids.hits(_solids, _mask(px, py))


## Levado por uma plataforma movel (plataforma.gd chama depois de se mover).
func carry_by(d: Vector2, platform: Node) -> void:
	var snap := Solids.snapshot(get_tree())
	if d.x != 0.0 and not Solids.hits(snap, _mask(position.x + d.x, position.y), [platform]):
		position.x += d.x
	position.y += d.y


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
	climbing = false
	_drop_carried()
	_art.visible = true
	if player_state == "hurt":
		invulnerability_timer = INVULN_TIME
		Game.invulnerability_remaining = INVULN_TIME
		Game.play_sfx("hurt")
	else:
		Game.play_sfx("death")
	_set_anim("dead" if player_state == "dead" else "hurt")
	_art.frame = 0  # image_index = 0


func _set_anim(anim_name: String) -> void:
	if anim_name != _anim:
		_anim = anim_name
		_art.play(anim_name)


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

	if swim != "dive":
		air = mini(AIR_MAX, air + 4)  # respira na superficie / fora d'agua
	Game.air_ratio = float(air) / AIR_MAX
	Game.show_air = swim == "dive" or air < AIR_MAX

	_check_out_of_bounds()
	_collisions()
	_update_sprite()


func _step_alive() -> void:
	move = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	var water := _water_here()
	if water != null:
		_step_swim(water)
		return
	swim = "none"
	var wind := Vento.total(get_tree(), get_mask())
	spdh = move * spd_player + wind.x
	if carrying == null and move != 0 and spdh != 0.0:
		_push_boxes()
	_move_x()

	if _step_climb():
		return

	if _place_meeting(position.x, position.y + 1.0):
		if fall_start_y >= 0.0:
			var fell := position.y - fall_start_y
			if fell >= FALL_DAMAGE_HEIGHT:
				take_damage()
			if fell > 10.0:
				Particulas.emit(get_tree(), "pouso", position, 4 if fell < 40.0 else 8)
				_squash = Vector2(1.25, 0.78)
			fall_start_y = -1.0
		pulos = 2
		if move != 0:
			_run_dust -= 1
			if _run_dust <= 0:
				_run_dust = 12
				Particulas.emit(get_tree(), "poeira", position + Vector2(-move * 5.0, 0), 1)
	else:
		if spdv >= 0.0 and fall_start_y < 0.0:
			fall_start_y = position.y
		spdv = minf(spdv + gravidade, max_fall_speed)
	if wind.y < 0.0:
		# corrente de ar para cima: levanta e amortece a queda
		spdv = maxf(spdv + wind.y, -LIFT_MAX)
		fall_start_y = -1.0

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
		Game.play_sfx("jump")
		_squash = Vector2(0.8, 1.22)
		if pulos == 1:
			Particulas.emit(get_tree(), "poeira", position, 3)
		else:  # pulo duplo: anelzinho de ar embaixo do pato
			Particulas.emit(get_tree(), "anel", position + Vector2(0, -2), 8)
		fall_start_y = -1.0  # o pulo duplo "amortece" a queda (B4)

	_move_y()

	if move != 0:
		xscale = move
	_handle_grab()


func _jump_pressed() -> bool:
	return Input.is_action_just_pressed("jump") and Engine.get_physics_frames() != Game.resume_frame


# ------------------------------------------------------------ caixas (D1/D2)
## Andando contra uma caixa parada: anda mais devagar e a empurra.
func _push_boxes() -> void:
	var probe := _mask(position.x + spdh, position.y)
	for box in get_tree().get_nodes_in_group("caixa"):
		if box.state == "idle" and probe.intersects(box.get_rect()):
			spdh = signf(spdh) * PUSH_SPEED
			box.push(spdh)


## Caixa encostada na frente do pato (faixa de 4 px depois da mascara).
func _box_in_reach() -> Node2D:
	var m := get_mask()
	var zone := Rect2(m.end.x, m.position.y, 4.0, m.size.y) if xscale >= 0 \
		else Rect2(m.position.x - 4.0, m.position.y, 4.0, m.size.y)
	for box in get_tree().get_nodes_in_group("caixa"):
		if box.state == "idle" and zone.intersects(box.get_rect()):
			return box
	return null


## X/J: pega a caixa da frente; carregando, arremessa (com BAIXO, pousa na frente).
func _handle_grab() -> void:
	if not Input.is_action_just_pressed("grab"):
		return
	if carrying != null:
		if carrying.release(xscale, Input.is_action_pressed("down")):
			carrying = null
		else:
			Game.play_sfx("denied")
		return
	var box := _box_in_reach()
	if box == null:
		return
	if not box.is_free_at(position + box.CARRY_OFFSET):
		Game.play_sfx("denied")  # sem espaco acima da cabeca
		return
	box.pick_up(self)
	carrying = box
	Game.play_sfx("pickup")


func _drop_carried() -> void:
	if carrying != null and is_instance_valid(carrying):
		carrying.drop()
	carrying = null


# -------------------------------------------------------------------- agua
## Agua em que o pe do pato esta (3 px abaixo da linha d'agua ja conta).
func _water_here() -> Node2D:
	var feet := Vector2(position.x, position.y - 3.0)
	for w in get_tree().get_nodes_in_group("agua"):
		if w.get_rect().has_point(feet):
			return w
	return null


## Nado: boia na superficie (ESPACO sai, BAIXO mergulha); mergulhado nada nas 4 direcoes e,
## sem apertar nada, sobe devagar. O folego so gasta mergulhado; acabou, perde 1 coracao.
func _step_swim(water: Node2D) -> void:
	_drop_carried()
	climbing = false
	fall_start_y = -1.0  # cair na agua nao machuca
	pulos = 2
	var surf: float = water.surface_y() + FLOAT_DEPTH
	var down := Input.is_action_pressed("down")
	var up := Input.is_action_pressed("up")
	if swim == "none":  # acabou de cair na agua
		swim = "dive" if down else "surface"
		spdv = minf(spdv, 1.5)
		Game.play_sfx("splash")
		Particulas.emit(get_tree(), "respingo", Vector2(position.x, water.surface_y()), 10)

	if swim == "surface":
		spdh = move * SWIM_SPEED
		if spdh != 0.0:
			_push_boxes()
		_move_x()
		if _jump_pressed():
			swim = "none"
			spdv = spd_pulo
			pulos = 1
			Game.play_sfx("jump")
			_move_y()
			if move != 0:
				xscale = move
			return
		if down:
			swim = "dive"
			Game.play_sfx("dive")
		else:
			spdv = clampf(surf - position.y, -1.5, 1.5)
			_move_y()
	if swim == "dive":
		spdh = move * DIVE_SPEED
		_move_x()
		spdv = (int(down) - int(up)) * DIVE_SPEED
		if not down and not up:
			spdv = -0.6
		_move_y()
		if position.y <= surf:
			position.y = surf
			swim = "surface"
		air -= 1
		if air % 30 == 0:
			Particulas.emit(get_tree(), "bolha", position + Vector2(xscale * 6.0, -8), 1)  # no bico do pato deitado
		if air <= 0:
			_drown(surf)
	if move != 0:
		xscale = move


## Sem folego: perde 1 coracao e volta a superficie (ou ao checkpoint, se em cima for parede).
func _drown(surf: float) -> void:
	air = AIR_MAX
	if _place_meeting(position.x, surf):
		respawn(true)
		return
	position.y = surf
	swim = "surface"
	spdv = 0.0
	take_damage()


# -------------------------------------------------------------------- cipo
## grow: conta tambem o cipo logo abaixo do pe (no topo o pe so encosta na ponta do cipo).
func _vine_here(grow: bool) -> Node2D:
	var m := get_mask()
	if grow:
		m = m.grow_side(SIDE_BOTTOM, 1.0)
	for v in get_tree().get_nodes_in_group("escalavel"):
		if m.intersects(v.get_rect()):
			return v
	return null


## Escalando (ou comecando a escalar): CIMA/BAIXO movem, PULO solta. Devolve true se tratou.
func _step_climb() -> bool:
	var up := Input.is_action_pressed("up")
	var down := Input.is_action_pressed("down")
	var vine: Node2D = _vine_here(climbing or down) if carrying == null else null
	if vine == null:
		climbing = false
		return false
	if not climbing:
		var grounded := _place_meeting(position.x, position.y + 1.0)
		var at_top: bool = position.y <= vine.top_y()
		# CIMA agarra; BAIXO agarra no ar ou em pe no topo (para descer).
		if not (up or (down and (not grounded or at_top))):
			return false
		climbing = true
	pulos = 2
	fall_start_y = -1.0
	# Sem andar para os lados, o pato vai para o meio do cipo (na beira do penhasco ele
	# agarra ainda meio em cima do chao, que impediria a descida).
	var center: float = vine.get_rect().get_center().x
	if move == 0 and absf(position.x - center) > 0.5:
		var step := signf(center - position.x) * minf(1.0, absf(center - position.x))
		if not _place_meeting(position.x + step, position.y):
			position.x += step
	if _jump_pressed():
		climbing = false
		spdv = spd_pulo
		pulos = 1
		Game.play_sfx("jump")
		_move_y()
		return true
	spdv = (int(down) - int(up)) * CLIMB_SPEED
	# No topo o pe para na altura do topo do cipo.
	if position.y + spdv < vine.top_y():
		spdv = vine.top_y() - position.y
	_move_y()
	if move != 0:
		xscale = move
	return true


## Machucado ou morrendo: sem controle, mas com gravidade e recuo (antes congelava no ar, B2).
func _step_hurt_or_dead() -> void:
	state_timer += 1
	move = 0
	if player_state == "hurt":
		spdh = knockback_dir * KNOCKBACK_SPEED * maxf(0.0, 1.0 - float(state_timer) / HURT_TIME)
	else:
		spdh = 0.0
	_move_x()
	var water := _water_here()
	if water != null:  # machucado na agua: boia ate a superficie
		spdv = clampf(water.surface_y() + FLOAT_DEPTH - position.y, -1.0, 1.0)
	elif not _place_meeting(position.x, position.y + 1.0):
		spdv = minf(spdv + gravidade, max_fall_speed)
	fall_start_y = -1.0
	_move_y()

	if player_state == "hurt" and state_timer >= HURT_TIME:
		player_state = "alive"
		state_timer = 0
		_set_anim("idle")
		_art.frame = 0
	elif player_state == "dead" and state_timer >= DEATH_TIME:
		Game.game_state = "gameover"
		Game.ui_selection = 0
		queue_free()


## Rede de seguranca caso o jogador saia do mapa (buraco sem fundo): volta ao checkpoint.
func _check_out_of_bounds() -> void:
	if position.y > Game.room_height + 96 or position.x < -64 or position.x > Game.room_width + 64:
		respawn(true)


func _update_sprite() -> void:
	_art.flip_h = xscale < 0
	if player_state != "alive":
		olhar_dir = 0
		olhar_quadros = 0
		Game.camera_olhar = 0.0
		_art.scale = Vector2.ONE * Sprites.ART_SCALE
		_art.visible = true
		_art.speed_scale = 1.0
		_set_anim("dead" if player_state == "dead" else "hurt")
		# tremor do dano: so no estado hurt, 1 px para cada lado
		_art.position.x = float(HURT_SHAKE[int(_art.frame / 2.0) % 4]) if player_state == "hurt" else 0.0
		return
	_art.position.x = 0.0

	var next_anim := "idle"
	if move != 0:
		next_anim = "run"
	if swim == "surface":
		pass  # boiando: parado ou "andando" (sem sprite de nado ainda)
	elif swim == "dive":
		next_anim = "dive" if _art.sprite_frames.has_animation("dive") else "fall"
	elif climbing:
		next_anim = "jump"  # sem sprite de escalar ainda: quadro do pulo, parado
	elif spdv < -APEX_SPEED:
		next_anim = "jump"
	elif spdv > APEX_SPEED:
		next_anim = "fall"
	elif spdv != 0.0 and not _place_meeting(position.x, position.y + 1.0):
		next_anim = "apex"  # no alto do pulo: a asa bate e os pes comecam a descer

	# parado no chao segurando CIMA ou BAIXO: olha (e, segurando um pouco, a camera vai junto)
	var olhar := 0
	if next_anim == "idle" and swim == "none" and not climbing and spdv == 0.0 			and _place_meeting(position.x, position.y + 1.0):
		var up := Input.is_action_pressed("up")
		var down := Input.is_action_pressed("down")
		if up != down:
			olhar = -1 if up else 1
	if olhar != 0:
		next_anim = "look_up" if olhar < 0 else "look_down"
	olhar_quadros = olhar_quadros + 1 if olhar != 0 and olhar == olhar_dir else (1 if olhar != 0 else 0)
	olhar_dir = olhar
	Game.camera_olhar = OLHAR_PX * olhar if olhar_quadros >= OLHAR_ESPERA else 0.0

	_set_anim(next_anim)
	if climbing and spdv == 0.0:
		_art.speed_scale = 0.0
	elif next_anim == "dive" and move == 0 and absf(spdv) < DIVE_SPEED:
		_art.speed_scale = 0.5  # parado debaixo d'agua (so subindo devagar): pernada mais lenta
	else:
		_art.speed_scale = 1.0
	# estica/achata a partir dos pes e volta ao normal
	_squash = _squash.lerp(Vector2.ONE, 0.2)
	_art.scale = _squash * Sprites.ART_SCALE
	var blink := invulnerability_timer > 0 and invulnerability_timer % 12 < 6
	# pisca liga/desliga (sem alfa parcial: nada de cor fora da paleta nem contorno sumindo)
	_art.visible = not blink


# ---------------------------------------------------------- eventos de colisao
func _collisions() -> void:
	var m := _mask(position.x, position.y)
	var tree := get_tree()

	for item in tree.get_nodes_in_group("item"):
		if Game.game_state != "playing":
			return
		if not item.is_queued_for_deletion() and m.intersects(item.get_mask()):
			item.collect(self)

	for cp in tree.get_nodes_in_group("checkpoint"):
		if m.intersects(cp.get_mask()) and cp.activate():
			Game.play_sfx("checkpoint")

	for enemy in tree.get_nodes_in_group("enemy"):
		if Game.game_state != "playing" or player_state == "dead":
			return
		if not enemy.is_queued_for_deletion() and m.intersects(enemy.get_mask()):
			_on_enemy(enemy)

	if player_state == "alive":
		for hz in tree.get_nodes_in_group("hazard"):
			if m.intersects(hz.get_rect()):
				respawn(true)
				return

	for ex in tree.get_nodes_in_group("exit"):
		if Game.game_state == "playing" and m.intersects(ex.get_mask()):
			Game.finish_level()
			return


## Pisar (caindo, com o pe acima da linha de pisao) atinge o inimigo; encostar de outro jeito machuca.
func _on_enemy(enemy) -> void:
	var bbox_bottom := roundf(position.y) - 1.0
	if enemy.stompable and spdv > 0.0 and (bbox_bottom - spdv) < enemy.stomp_line_y():
		enemy.hit(1)
		spdv = spd_pulo * 0.8
		pulos = 1
		fall_start_y = -1.0
	elif enemy.harmful():
		take_damage(enemy.position.x)


## Volta ao ultimo checkpoint (ou ao inicio). Com lose_life, custa 1 vida (perigos, sair do mapa).
func respawn(lose_life: bool) -> void:
	var at: Vector2 = Game.checkpoint_pos if Game.has_checkpoint else Vector2(start_x, start_y)
	if carrying != null and is_instance_valid(carrying):
		carrying.reset_to_start()
	carrying = null
	climbing = false
	swim = "none"
	air = AIR_MAX
	position = at
	spdh = 0.0
	spdv = 0.0
	fall_start_y = -1.0
	jump_buffer = 0
	if lose_life:
		take_damage()
	if player_state == "hurt":
		spdv = 0.0  # reaparece parado, sem o pulinho do dano
		knockback_dir = 0
