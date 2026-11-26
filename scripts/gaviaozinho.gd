extends Enemy
## Gaviaozinho (Fases 4 a 8): ave de rapina pequena. Voa de um lado para o outro num trajeto
## fixo (alcance para cada lado da posicao inicial). Quando ve o pato mais abaixo e um pouco
## a frente, grita, para no ar um instante e da um RASANTE: desce em arco, com o ponto mais
## baixo onde o pato estava, e sobe do outro lado (da para fugir correndo durante o grito). Pisao ou caixa arremessada derrota (1 golpe). Nao atravessa paredes no rasante (so
## mergulha com o caminho livre). Origem = meio do corpo. Arte: assets/sprites/arte/
## gaviaozinho.png (6 quadros de voo e 1 de rasante).

const Solids := preload("res://scripts/solids.gd")
const Sprites := preload("res://scripts/sprites.gd")
const QUADROS := 32  # voo 0..15, rasante 16..31
const PIVO := Vector2(10, 10)  # meio do corpo, no quadro (px do jogo)

const WARN_TIME := 22
const COOLDOWN := 90
const SWOOP_SPEED := 2.4  # px por frame na horizontal durante o rasante
const SEE_DX_MIN := 32.0  # o pato precisa estar entre 32 e 112 px para o lado
const SEE_DX := 112.0
const SEE_DY := 150.0  # ... e ate esta distancia para baixo


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
	# voo: quadros 0..5 batendo as asas (mais rapido no aviso, piscando claro); rasante: 6
	var q := 16 + int(_anim / 2.0) % 16
	var cor := Color.WHITE
	if state != "rasante":
		q = int(_anim * 16.0 / (18.0 if state == "aviso" else 30.0)) % 16
		if state == "aviso" and int(_anim / 3.0) % 2 == 0:
			cor = Color(1.6, 1.4, 1.2)
	Sprites.draw_bicho(self, "gaviaozinho", q, QUADROS, PIVO, dir < 0, cor)
