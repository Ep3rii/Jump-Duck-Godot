extends Enemy
## Gaviaozinho (Fases 4 a 8): ave de rapina pequena. Voa de um lado para o outro num trajeto
## fixo (alcance para cada lado da posicao inicial). Quando ve o pato mais abaixo e um pouco
## a frente, grita, para no ar um instante e da um RASANTE: desce em arco, com o ponto mais
## baixo onde o pato estava, e sobe do outro lado (da para fugir correndo durante o grito). Pisao ou caixa arremessada derrota (1 golpe). Nao atravessa paredes no rasante (so
## mergulha com o caminho livre). Origem = meio do corpo. Desenho provisorio em codigo.

const Solids := preload("res://scripts/solids.gd")

const WARN_TIME := 22
const COOLDOWN := 90
const SWOOP_SPEED := 2.4  # px por frame na horizontal durante o rasante
const SEE_DX_MIN := 32.0  # o pato precisa estar entre 32 e 112 px para o lado
const SEE_DX := 112.0
const SEE_DY := 150.0  # ... e ate esta distancia para baixo

const COL_OUT := Color8(40, 22, 10)
const COL_BODY := Color8(150, 90, 44)
const COL_WING := Color8(112, 64, 30)
const COL_BELLY := Color8(232, 210, 170)
const COL_BEAK := Color8(250, 200, 50)

## Quanto voa para cada lado da posicao inicial (px).
@export var alcance := 64.0:
	set(v):
		alcance = v
		queue_redraw()
@export var velocidade := 0.8

var state := "voo"  # voo | aviso | rasante
var dir := -1
var start_x := 0.0
var cruise_y := 0.0
var _timer := 0
var _cooldown := 30
var _anim := 0.0
var _sx := 0.0
var _span := 0.0
var _depth := 0.0
var _t := 0.0
var _dt := 0.0
var _aim := Vector2.ZERO  # onde o pato estava quando o gaviao gritou


func _enemy_ready() -> void:
	add_to_group("ave")
	start_x = position.x
	cruise_y = position.y
	effect_offset = Vector2.ZERO
	particula_derrota = "pena"


func get_mask() -> Rect2:
	return Rect2(roundf(position.x) - 8.0, roundf(position.y) - 6.0, 16.0, 10.0)


func stomp_line_y() -> float:
	return position.y - 2.0


func _physics_process(_delta: float) -> void:
	if Game.game_state != "playing":
		return
	_anim += 1.0
	_cooldown -= 1
	var p := get_tree().get_first_node_in_group("player")
	match state:
		"voo":
			position.x += dir * velocidade
			if position.x <= start_x - alcance:
				dir = 1
			elif position.x >= start_x + alcance:
				dir = -1
			position.y = move_toward(position.y, cruise_y + sin(_anim * 0.08) * 2.0, 1.0)
			if _cooldown <= 0 and _sees(p):
				state = "aviso"
				_timer = WARN_TIME
				dir = 1 if p.position.x >= position.x else -1
				_aim = p.position
				Game.play_sfx("screech")
		"aviso":
			_timer -= 1
			if _timer <= 0:
				_start_swoop(p)
		"rasante":
			_t += _dt
			var t := minf(_t, 1.0)
			position.x = _sx + dir * _span * t
			position.y = cruise_y + _depth * sin(PI * t)
			if _t >= 1.0:
				state = "voo"
				_cooldown = COOLDOWN
	queue_redraw()


func _sees(p: Node2D) -> bool:
	if p == null or p.player_state != "alive":
		return false
	var dx: float = p.position.x - position.x
	var dy: float = p.position.y - position.y
	return absf(dx) >= SEE_DX_MIN and absf(dx) < SEE_DX and dy > 24.0 and dy < SEE_DY


## Arco cujo ponto mais baixo e onde o pato estava no grito (o pe dele menos 8 px).
func _start_swoop(p: Node2D) -> void:
	state = "voo"
	_cooldown = 30
	if p == null:
		return
	_span = clampf(absf(_aim.x - position.x) * 2.0, 2.0 * SEE_DX_MIN, 2.0 * SEE_DX)
	_depth = maxf(16.0, _aim.y - 8.0 - cruise_y)
	_sx = position.x
	# caminho livre? (amostra o arco)
	var snap := Solids.snapshot(get_tree())
	var prev := position
	for i in range(1, 11):
		var t := i / 10.0
		var q := Vector2(_sx + dir * _span * t, cruise_y + _depth * sin(PI * t))
		if not Solids.line_clear(snap, prev, q, 5.0):
			return
		prev = q
	state = "rasante"
	_t = 0.0
	_dt = SWOOP_SPEED / _span
	Game.play_sfx("swoop")


# ---------------------------------------------------------------- desenho
func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.85, 0.85))  # do tamanho do pato
	var f := float(dir)
	var flash := state == "aviso" and int(_anim / 3.0) % 2 == 0
	var body := COL_BELLY if flash else COL_BODY
	if state == "rasante":
		# asas fechadas para tras, corpo inclinado
		_wing_back(f)
	else:
		var pose := int(_anim / (3.0 if state == "aviso" else 5.0)) % 4
		_wings(pose)
	# corpo
	draw_rect(Rect2(-6, -4, 12, 7), COL_OUT)
	draw_rect(Rect2(-5, -3, 10, 5), body)
	draw_rect(Rect2(-4, 0, 8, 2), COL_BELLY)
	# cauda
	var tail_x := -10.0 if f > 0 else 6.0
	draw_rect(Rect2(tail_x, -2, 4, 3), COL_OUT)
	# cabeca, olho e bico (para onde voa)
	var hx := 4.0 if f > 0 else -9.0
	draw_rect(Rect2(hx, -6, 5, 5), COL_OUT)
	draw_rect(Rect2(hx + 1, -5, 3, 3), body)
	draw_rect(Rect2(hx + (2.0 if f > 0 else 1.0), -5, 1, 1), Color.WHITE)
	var bx := hx + 5.0 if f > 0 else hx - 2.0
	draw_rect(Rect2(bx, -4, 2, 2), COL_BEAK)
	# garras
	draw_rect(Rect2(-2, 3, 1, 2), COL_BEAK)
	draw_rect(Rect2(1, 3, 1, 2), COL_BEAK)


## pose 0 = asas em cima, 1 e 3 = no meio (abertas), 2 = embaixo.
func _wings(pose: int) -> void:
	var y: float = [-9.0, -5.0, -1.0, -5.0][pose]
	var reach: float = [9.0, 11.0, 9.0, 11.0][pose]  # abertas no meio ficam mais compridas
	draw_rect(Rect2(-2 - reach, y, reach, 4), COL_OUT)
	draw_rect(Rect2(-1 - reach, y + 1, reach - 2, 2), COL_WING)
	draw_rect(Rect2(-1 - reach, y + 1, 2, 2), COL_OUT.lightened(0.15))
	draw_rect(Rect2(2, y, reach, 4), COL_OUT)
	draw_rect(Rect2(3, y + 1, reach - 2, 2), COL_WING)
	draw_rect(Rect2(reach - 1, y + 1, 2, 2), COL_OUT.lightened(0.15))


func _wing_back(f: float) -> void:
	var x := -12.0 if f > 0 else 2.0
	draw_rect(Rect2(x, -6, 10, 4), COL_OUT)
	draw_rect(Rect2(x + 1, -5, 8, 2), COL_WING)
