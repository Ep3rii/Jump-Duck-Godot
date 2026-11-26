extends Enemy
## Aguia (Fases 5 a 8): ave de rapina grande. Circula no alto em volta da posicao inicial.
## Quando o pato chega perto (abaixo dela), grita e treme por meio segundo, mira onde ele esta
## e MERGULHA EM DIAGONAL em linha reta. Se bate no chao ou numa parede, fica com o bico
## preso um tempo (a melhor hora para pisar nela); depois sobe de volta para o alto.
## Precisa de 2 golpes (pisao ou caixa arremessada). Origem = meio do corpo.
## Arte: assets/sprites/arte/aguia.png (6 quadros de voo e 1 de mergulho).

const Solids := preload("res://scripts/solids.gd")
const Sprites := preload("res://scripts/sprites.gd")
const QUADROS := 7
const PIVO := Vector2(14, 13)  # meio do corpo, no quadro (px do jogo)

const WARN_TIME := 32
const DIVE_SPEED := 3.4
const STUCK_TIME := 50
const RISE_SPEED := 1.2
const COOLDOWN := 110
const SEE_RANGE := 150.0
const CIRCLE := Vector2(28, 8)  # raio do voo em circulo (x, y)

const COL_STAR := Color8(255, 220, 80)

var state := "circulo"  # circulo | aviso | mergulho | presa | subindo
var home := Vector2.ZERO
var dir := -1
var _a := 0.0
var _timer := 0
var _cooldown := 40
var _anim := 0.0
var _vel := Vector2.ZERO
var _target := Vector2.ZERO
var _travel := 0.0
var _max_travel := 0.0


func _enemy_ready() -> void:
	add_to_group("ave")
	max_hp = 2
	hp = max_hp
	hurt_frames = 40
	home = position
	effect_offset = Vector2.ZERO
	particula_derrota = "pena"
	particulas_qtd = 14


func get_mask() -> Rect2:
	return Rect2(roundf(position.x) - 8.0, roundf(position.y) - 6.0, 16.0, 10.0)


func stomp_line_y() -> float:
	return position.y - 3.0


func _circle_point() -> Vector2:
	return home + Vector2(cos(_a) * CIRCLE.x, sin(_a * 2.0) * CIRCLE.y)


func hit(damage: int = 1) -> void:
	var before := hp
	super(damage)
	if hp > 0 and hp < before:
		state = "subindo"  # levou o golpe: volta para o alto


func _physics_process(_delta: float) -> void:
	if Game.game_state != "playing":
		return
	_anim += 1.0
	_cooldown -= 1
	var p := get_tree().get_first_node_in_group("player")
	match state:
		"circulo":
			_a += 0.025
			var c := _circle_point()
			dir = 1 if c.x > position.x else -1
			position = position.move_toward(c, 1.5)
			if _cooldown <= 0 and _sees(p):
				state = "aviso"
				_timer = WARN_TIME
				Game.play_sfx("screech")
		"aviso":
			_timer -= 1
			if p != null:
				dir = 1 if p.position.x >= position.x else -1
			if _timer <= 0:
				_start_dive(p)
		"mergulho":
			_dive_step()
		"presa":
			_timer -= 1
			if _timer <= 0:
				state = "subindo"
		"subindo":
			var c := _circle_point()
			dir = 1 if c.x > position.x else -1
			position = position.move_toward(c, RISE_SPEED)
			if position.distance_to(c) < 1.0:
				state = "circulo"
				_cooldown = COOLDOWN
	queue_redraw()


func _sees(p: Node2D) -> bool:
	if p == null or p.player_state != "alive":
		return false
	var d: Vector2 = p.position + Vector2(0, -8) - position
	return d.y > 16.0 and d.length() < SEE_RANGE \
		and Solids.line_clear(Solids.snapshot(get_tree()), position, p.position + Vector2(0, -8), 5.0)


## Mira o meio do pato e segue reto ate passar 40 px do alvo ou bater em algo.
func _start_dive(p: Node2D) -> void:
	if p == null:
		state = "subindo"
		return
	_target = p.position + Vector2(0, -8)
	var d := _target - position
	if d.length() < 1.0:
		state = "subindo"
		return
	_vel = d.normalized() * DIVE_SPEED
	_travel = 0.0
	_max_travel = d.length() + 40.0
	state = "mergulho"
	Game.play_sfx("swoop")


func _dive_step() -> void:
	var snap := Solids.snapshot(get_tree())
	var next := position + _vel
	var r := Rect2(roundf(next.x) - 6.0, roundf(next.y) - 4.0, 12.0, 8.0)
	if Solids.hits(snap, r):
		state = "presa"
		_timer = STUCK_TIME
		Game.play_sfx("thud")
		return
	position = next
	_travel += DIVE_SPEED
	if _travel >= _max_travel or position.y > Game.room_height:
		state = "subindo"


# ---------------------------------------------------------------- desenho
func _draw() -> void:
	# circulando/subindo: quadros 0..5; aviso: bate mais rapido e treme; mergulho: 6;
	# bico preso: asa caida (quadro 3) com estrelinhas girando
	var q := int(_anim / 6.0) % 6
	var tremor := Vector2.ZERO
	if state == "aviso":
		q = int(_anim / 3.0) % 6
		tremor.x = 1.0 if int(_anim / 2.0) % 2 == 0 else -1.0
	elif state == "mergulho":
		q = 6
	elif state == "presa":
		q = 3
	Sprites.draw_bicho(self, "aguia", q, QUADROS, PIVO, dir < 0, Color.WHITE, tremor)
	if state == "presa":
		for i in 3:
			var ang := _anim * 0.15 + i * TAU / 3.0
			var c := Vector2(cos(ang) * 10.0, -16 + sin(ang) * 3.0)
			draw_rect(Rect2(c.x - 1, c.y - 2, 2, 4), COL_STAR)
			draw_rect(Rect2(c.x - 2, c.y - 1, 4, 2), COL_STAR)
