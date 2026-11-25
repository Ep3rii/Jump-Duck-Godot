extends Enemy
## Aguia (Fases 5 a 8): ave de rapina grande. Circula no alto em volta da posicao inicial.
## Quando o pato chega perto (abaixo dela), grita e treme por meio segundo, mira onde ele esta
## e MERGULHA EM DIAGONAL em linha reta. Se bate no chao ou numa parede, fica com o bico
## preso um tempo (a melhor hora para pisar nela); depois sobe de volta para o alto.
## Precisa de 2 golpes (pisao ou caixa arremessada). Origem = meio do corpo.
## Desenho provisorio em codigo.

const Solids := preload("res://scripts/solids.gd")

const WARN_TIME := 32
const DIVE_SPEED := 3.4
const STUCK_TIME := 50
const RISE_SPEED := 1.2
const COOLDOWN := 110
const SEE_RANGE := 150.0
const CIRCLE := Vector2(28, 8)  # raio do voo em circulo (x, y)

const COL_OUT := Color8(30, 18, 10)
const COL_BODY := Color8(92, 56, 30)
const COL_WING := Color8(70, 40, 20)
const COL_HEAD := Color8(245, 240, 225)
const COL_BEAK := Color8(250, 196, 40)
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
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.7, 0.7))  # do tamanho do pato
	var f := float(dir)
	var shake := 0.0
	if state == "aviso":
		shake = 1.0 if int(_anim / 2.0) % 2 == 0 else -1.0
	var o := Vector2(shake, 0)
	if state == "mergulho":
		_draw_diving(f)
		return
	var up := int(_anim / 8.0) % 2 == 0 and state != "presa"
	# asas abertas (grandes)
	if up:
		draw_rect(Rect2(o.x - 15, -12, 12, 5), COL_OUT)
		draw_rect(Rect2(o.x - 14, -11, 10, 3), COL_WING)
		draw_rect(Rect2(o.x + 3, -12, 12, 5), COL_OUT)
		draw_rect(Rect2(o.x + 4, -11, 10, 3), COL_WING)
	else:
		draw_rect(Rect2(o.x - 16, -2, 12, 5), COL_OUT)
		draw_rect(Rect2(o.x - 15, -1, 10, 3), COL_WING)
		draw_rect(Rect2(o.x + 4, -2, 12, 5), COL_OUT)
		draw_rect(Rect2(o.x + 5, -1, 10, 3), COL_WING)
	# corpo e cauda branca
	draw_rect(Rect2(o.x - 8, -5, 16, 9), COL_OUT)
	draw_rect(Rect2(o.x - 7, -4, 14, 7), COL_BODY)
	var tail_x := -13.0 if f > 0 else 8.0
	draw_rect(Rect2(o.x + tail_x, -3, 5, 4), COL_OUT)
	draw_rect(Rect2(o.x + tail_x + 1, -2, 3, 2), COL_HEAD)
	# cabeca branca, olho bravo, bico amarelo curvo
	var hx := 5.0 if f > 0 else -12.0
	draw_rect(Rect2(o.x + hx, -9, 7, 7), COL_OUT)
	draw_rect(Rect2(o.x + hx + 1, -8, 5, 5), COL_HEAD)
	var ex := hx + (3.0 if f > 0 else 2.0)
	draw_rect(Rect2(o.x + ex, -7, 2, 1), COL_OUT)
	var bx := hx + 7.0 if f > 0 else hx - 3.0
	draw_rect(Rect2(o.x + bx, -6, 3, 2), COL_BEAK)
	draw_rect(Rect2(o.x + bx + (2.0 if f > 0 else 0.0), -4, 1, 1), COL_BEAK)
	# garras
	draw_rect(Rect2(o.x - 3, 4, 2, 2), COL_BEAK)
	draw_rect(Rect2(o.x + 1, 4, 2, 2), COL_BEAK)
	if state == "presa":
		for i in 3:
			var ang := _anim * 0.15 + i * TAU / 3.0
			var c := Vector2(cos(ang) * 10.0, -14 + sin(ang) * 3.0)
			draw_rect(Rect2(c.x - 1, c.y - 2, 2, 4), COL_STAR)
			draw_rect(Rect2(c.x - 2, c.y - 1, 4, 2), COL_STAR)


## Mergulhando: asas coladas, corpo apontado na direcao do mergulho.
func _draw_diving(f: float) -> void:
	var d := _vel.normalized()
	for i in 4:
		var c := -d * (i * 4.0)
		var s := 8.0 - i * 1.5
		draw_rect(Rect2(c.x - s * 0.5 - 1, c.y - s * 0.5 - 1, s + 2, s + 2), COL_OUT)
		draw_rect(Rect2(c.x - s * 0.5, c.y - s * 0.5, s, s), COL_WING if i > 0 else COL_BODY)
	var h := d * 7.0
	draw_rect(Rect2(h.x - 4, h.y - 4, 8, 8), COL_OUT)
	draw_rect(Rect2(h.x - 3, h.y - 3, 6, 6), COL_HEAD)
	var b := d * 12.0
	draw_rect(Rect2(b.x - 1.5, b.y - 1.5, 3, 3), COL_BEAK)
	draw_rect(Rect2(h.x + (1.0 if f > 0 else -2.0), h.y - 2, 1, 1), COL_OUT)
