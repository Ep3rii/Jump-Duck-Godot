extends Enemy
## Mini-chefe jacare gigante (Fase 3). Vive na agua da arena (agua.tscn).
##
## Ciclo (vale para os 5 golpes):
## 1. nadando: submerso, vai para baixo do pato;
## 2. aviso: bolhas na superficie marcam o ponto; salto: pula da agua contra as plataformas
##    (de 2 a 4 saltos por ciclo, mais saltos com menos vida);
## 3. mordida_aviso: emerge ao lado do pato e abre a boca; mordida: avanca e morde forte 1 vez;
## 4. dor: fica na superficie "com dor de dente". So agora pode ser pisado.
##    Pisou: perde 1 de vida e mergulha (ferido). Se o tempo acaba, recomeca o ciclo.
## Encostar nele machuca, menos com dor de dente e ferido. 5 pisoes derrotam.
## A barra de vida aparece no HUD quando o pato entra na arena.

const DISPLAY_NAME := "JACARÉ GIGANTE"
const SWIM_SPEED := 2.5
const WARN_TIME := 45
const BITE_WARN_TIME := 50
const BITE_TIME := 14
const PAIN_TIME := 180
const HURT_TIME := 50
const LEAP_GRAVITY := 0.25
const SURFACE_DEPTH := 8.0  # na superficie a barriga fica 8 px abaixo da linha d'agua
const DEEP := 26.0  # submerso
const BITE_DISTANCE := 32.0  # emerge a esta distancia do pato
const HALF_W := 16.0  # 2 blocos de largura (arte de chefe: 256x256 -> 32 px)
const HEIGHT := 10.0
const BITE_REACH := 10.0
const Sprites := preload("res://scripts/sprites.gd")
const QUADROS := 11  # tira assets/sprites/arte/chefe_jacare.png (tools/arte/chefes.py)
const PIVO := Vector2(16, 23)  # ponto da barriga no quadro de 64 px (16 px no jogo)

const COL_OUT := Color8(16, 40, 16)
const COL_BODY := Color8(60, 112, 44)
const COL_BELLY := Color8(176, 190, 112)
const COL_SCUTE := Color8(38, 82, 30)
const COL_TOOTH := Color8(250, 250, 240)
const COL_MOUTH := Color8(150, 40, 40)
const COL_SWELL := Color8(220, 110, 100)
const COL_STAR := Color8(255, 220, 80)

var state := "espera"  # espera | nadando | aviso | salto | mordida_aviso | mordida | dor | ferido
var water: Node2D = null
var dir := -1
var leaps_left := 2
var _timer := 0
var _target_x := 0.0
var _vy := 0.0
var _mouth := 0.0
var _lunge := 0.0
var _anim := 0.0


func sombra_largura() -> float:
	return 0.0


func _enemy_ready() -> void:
	add_to_group("chefe")
	max_hp = 5
	hp = max_hp
	hurt_frames = HURT_TIME
	effect_offset = Vector2(0, -10)
	particula_derrota = "respingo"
	particulas_qtd = 30
	for w in get_tree().get_nodes_in_group("agua"):
		if w.get_rect().has_point(position + Vector2(0, -2)):
			water = w
			break
	if water != null:
		position.y = _surface() + DEEP


func _surface() -> float:
	return water.surface_y() + SURFACE_DEPTH


func get_mask() -> Rect2:
	var r := Rect2(roundf(position.x) - HALF_W, roundf(position.y) - HEIGHT, HALF_W * 2.0, HEIGHT)
	if state == "mordida":
		# a bocarra avanca para a frente
		var reach_x := r.end.x + BITE_REACH if dir > 0 else r.position.x - BITE_REACH
		r = r.expand(Vector2(reach_x, r.position.y))
	return r


func stomp_line_y() -> float:
	return position.y - 7.0


func harmful() -> bool:
	return hp > 0 and state != "dor" and state != "ferido" and state != "espera"


func hit(damage: int = 1) -> void:
	if state != "dor":
		return
	super(damage)
	if hp > 0:
		state = "ferido"
		_timer = HURT_TIME
		Game.boss_hp = hp


func defeat() -> void:
	Game.boss_hp = 0
	Game.clear_boss()
	Game.play_sfx("complete")
	super()


## Usado pelos testes para pular direto para um estado.
func force_state(s: String, frames := 999) -> void:
	state = s
	_timer = frames
	if s == "dor" or s == "mordida_aviso" or s == "mordida":
		position.y = _surface()


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


func _clamp_x(x: float) -> float:
	var r: Rect2 = water.get_rect()
	return clampf(x, r.position.x + HALF_W + 4.0, r.end.x - HALF_W - 4.0)


func _physics_process(_delta: float) -> void:
	if Game.game_state != "playing" or water == null:
		return
	_anim += 1.0
	var p := _player()
	stompable = state == "dor"
	if state != "espera":
		_timer -= 1

	match state:
		"espera":
			var r: Rect2 = water.get_rect()
			if p != null and p.position.x > r.position.x - 8.0 and p.position.x < r.end.x + 8.0:
				state = "nadando"
				leaps_left = 2
				_pick_leap_target(p)
				Game.set_boss(DISPLAY_NAME, hp, max_hp)
		"nadando":
			position.y = move_toward(position.y, _surface() + DEEP, 1.5)
			var dx := _target_x - position.x
			if absf(dx) > 1.0:
				dir = 1 if dx > 0 else -1
				position.x += clampf(dx, -SWIM_SPEED, SWIM_SPEED)
			elif absf(position.y - (_surface() + DEEP)) < 1.0:
				if leaps_left > 0:
					state = "aviso"
					_timer = WARN_TIME
				else:
					state = "mordida_aviso"
					_timer = BITE_WARN_TIME
					if p != null:
						dir = 1 if p.position.x > position.x else -1
		"aviso":
			if _timer <= 0:
				_start_leap(p)
		"salto":
			_vy += LEAP_GRAVITY
			position.y += _vy
			if _vy > 0.0 and position.y >= _surface():
				Game.play_sfx("splash")
				leaps_left -= 1
				state = "nadando"
				if leaps_left > 0:
					_pick_leap_target(p)
				else:
					_pick_bite_spot(p)
		"mordida_aviso":
			position.y = move_toward(position.y, _surface(), 2.0)
			_mouth = move_toward(_mouth, 1.0, 0.04)
			if _timer <= 0:
				state = "mordida"
				_timer = BITE_TIME
				Game.play_sfx("bite")
		"mordida":
			_lunge = move_toward(_lunge, BITE_REACH, 4.0)
			_mouth = 0.0 if _timer < BITE_TIME - 4 else 1.0
			if _timer <= 0:
				state = "dor"
				_timer = PAIN_TIME
				_lunge = 0.0
		"dor":
			_mouth = 0.4
			if _timer <= 0:
				_restart_cycle(p)
		"ferido":
			position.y = move_toward(position.y, _surface() + DEEP, 1.0)
			if _timer <= 0:
				_restart_cycle(p)
	queue_redraw()


func _restart_cycle(p: Node2D) -> void:
	state = "nadando"
	_mouth = 0.0
	leaps_left = 2 + int((max_hp - hp) / 2.0)  # mais saltos com menos vida
	_pick_leap_target(p)


func _pick_leap_target(p: Node2D) -> void:
	_target_x = _clamp_x(p.position.x if p != null else position.x)


func _pick_bite_spot(p: Node2D) -> void:
	if p == null:
		_target_x = position.x
		return
	var r: Rect2 = water.get_rect()
	var side := -1.0 if p.position.x > r.get_center().x else 1.0
	var x := _clamp_x(p.position.x + side * BITE_DISTANCE)
	if absf(x - p.position.x) < BITE_DISTANCE * 0.6:  # encostado na borda: vai para o outro lado
		x = _clamp_x(p.position.x - side * BITE_DISTANCE)
	_target_x = x


## Salta ate a altura do pato (se ele esta acima da agua) ou um pouco acima da superficie.
func _start_leap(p: Node2D) -> void:
	var peak := _surface() - 48.0
	if p != null and p.position.y < water.surface_y():
		peak = p.position.y + 2.0
	peak = clampf(peak, _surface() - 130.0, _surface() - 32.0)
	position.y = _surface()
	_vy = -sqrt(2.0 * LEAP_GRAVITY * (position.y - peak))
	state = "salto"
	_mouth = 1.0
	Game.play_sfx("splash")


# ---------------------------------------------------------------- desenho
func _draw() -> void:
	# nadando: quadros 0..3; saltando: 4..5; mordida: 6..8 (boca abrindo); dor: 9..10
	var q := int(_anim / 9.0) % 4
	match state:
		"salto":
			q = 4 if _vy < 0.0 else 5
		"mordida_aviso":
			q = 6
		"mordida":
			q = 6 + clampi(int(_mouth * 3.0), 0, 2)
		"dor":
			q = 9 + int(_anim / 8.0) % 2
		"ferido":
			q = 9
	var submerged := state in ["nadando", "aviso", "ferido", "espera"]
	var a := 0.5 if submerged else 1.0
	if state == "ferido" and int(_anim / 5.0) % 2 == 0:
		a = 0.25
	if state == "aviso":
		_draw_bubbles()
	Sprites.draw_bicho(self, "chefe_jacare", q, QUADROS, PIVO, dir < 0, Color(1, 1, 1, a),
		Vector2(_lunge * float(dir), 0.0))


func _draw_bubbles() -> void:
	var t := WARN_TIME - _timer
	var top: float = water.surface_y() - position.y
	for i in 4:
		var k := fposmod(t * 0.6 + i * 9.0, 30.0)
		var bx := -14.0 + i * 9.0 + sin((t + i * 7) * 0.3) * 2.0
		var by := top + 10.0 - k
		draw_circle(Vector2(bx, by), 2.0 + (i % 2), Color(0.85, 0.95, 1.0, 0.9))
	draw_rect(Rect2(-20, top - 1, 40, 2), Color(1, 1, 1, 0.7))
