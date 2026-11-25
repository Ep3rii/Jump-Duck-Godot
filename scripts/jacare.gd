extends Enemy
## Jacare comum (Fases 2 e 3): vive numa agua (agua.tscn) e vai e volta nadando.
## - Na superficie, com a cabeca e as costas para fora: pode ser pisado (1 pisao derrota).
## - De tempos em tempos mergulha: ai nao pode ser pisado e so pega quem esta mergulhado.
## - Encostar nele machuca (mordida); ele abre a boca quando o pato chega perto.
## Origem = meio da barriga, embaixo. Do tamanho do pato (1 bloco); desenho provisorio em
## codigo, reduzido (DRAW_SCALE) ate chegar a arte nova (128x128 -> 16 px).

const Solids := preload("res://scripts/solids.gd")

const SURFACE_TIME := 240  # frames na superficie
const DIVE_TIME := 120  # frames mergulhado
const DIVE_DEPTH := 14.0  # quanto afunda (px)
const FLOAT_DEPTH := 9.0  # na superficie fica meio afundado: costas e olhos para fora
const HALF_W := 8.0  # meia largura (16 px, como o pato)
const DRAW_SCALE := Vector2(0.32, 0.7)  # desenho provisorio (feito em 56x13) reduzido
const BODY_H := 9.0

const COL_OUT := Color8(20, 50, 20)
const COL_BODY := Color8(70, 130, 50)
const COL_BELLY := Color8(170, 190, 110)
const COL_SCUTE := Color8(46, 96, 36)
const COL_TOOTH := Color8(250, 250, 240)
const COL_MOUTH := Color8(150, 40, 40)

@export var velocidade := 0.4
## Comeca a ciclo ja mergulhado (para varios jacares nao mergulharem juntos).
@export var comeca_mergulhado := false

var dir := -1
var state := "surface"  # surface | dive
var water: Node2D = null
var _timer := 0
var _mouth := 0.0  # 0 fechada .. 1 aberta
var _anim := 0.0


func _enemy_ready() -> void:
	add_to_group("jacare")
	effect_offset = Vector2(0, -6)
	particula_derrota = "respingo"
	for w in get_tree().get_nodes_in_group("agua"):
		if w.get_rect().has_point(position + Vector2(0, -2)):
			water = w
			break
	if comeca_mergulhado:
		state = "dive"
		_timer = DIVE_TIME
	else:
		_timer = SURFACE_TIME
	if water != null:
		position.y = _target_y()


func _target_y() -> float:
	var y: float = water.surface_y() + FLOAT_DEPTH
	return y + DIVE_DEPTH if state == "dive" else y


func get_mask() -> Rect2:
	return Rect2(roundf(position.x) - HALF_W, roundf(position.y) - BODY_H, HALF_W * 2.0, BODY_H)


func _physics_process(_delta: float) -> void:
	if Game.game_state != "playing" or water == null:
		return
	_timer -= 1
	_anim += 1.0
	if state == "dive" and int(_anim) % 40 == 0:
		var Particulas := load("res://scripts/particulas.gd")
		Particulas.emit(get_tree(), "bolha", position + Vector2(dir * 6.0, -4), 1)
	if _timer <= 0:
		state = "dive" if state == "surface" else "surface"
		_timer = DIVE_TIME if state == "dive" else SURFACE_TIME
	position.y = move_toward(position.y, _target_y(), 0.5)
	stompable = state == "surface" and absf(position.y - _target_y()) < 2.0

	# vai e volta dentro da agua, virando nas bordas e em paredes
	var r: Rect2 = water.get_rect()
	var nx := position.x + dir * velocidade
	var snap := Solids.snapshot(get_tree())
	var front := Rect2(nx + (HALF_W if dir > 0 else -HALF_W - 1.0), position.y - BODY_H, 1.0, BODY_H)
	if nx - HALF_W < r.position.x or nx + HALF_W > r.end.x or Solids.hits(snap, front):
		dir = -dir
	else:
		position.x = nx

	# boca abre com o pato perto (aviso da mordida)
	var p := get_tree().get_first_node_in_group("player")
	var near := p != null and absf(p.position.x - position.x) < 24.0 \
		and absf(p.position.y - position.y) < 16.0
	var before := _mouth
	_mouth = move_toward(_mouth, 1.0 if near else 0.0, 0.15)
	if near and before < 0.5 and _mouth >= 0.5:
		Game.play_sfx("bite")
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, DRAW_SCALE)
	var a := 1.0 if state == "surface" else 0.55
	var f := float(dir)  # desenha virado para onde nada
	var out := Color(COL_OUT, a)
	# corpo
	draw_rect(Rect2(-22, -10, 36, 10), out)
	draw_rect(Rect2(-21, -9, 34, 8), Color(COL_BODY, a))
	draw_rect(Rect2(-21, -3, 34, 2), Color(COL_BELLY, a))
	for i in 5:
		draw_rect(Rect2(-18 + i * 6, -11, 3, 2), Color(COL_SCUTE, a))
	# cauda (para tras)
	var tail_x := -22.0 if f > 0 else 14.0
	var swish := floorf(sin(_anim * 0.15) * 2.0)  # cauda balancando ao nadar
	draw_rect(Rect2(tail_x - (6 if f > 0 else 0), -7 + swish, 8, 5), out)
	draw_rect(Rect2(tail_x - (5 if f > 0 else -1), -6 + swish, 6, 3), Color(COL_BODY, a))
	# cabeca e focinho (para frente), boca abrindo
	var head_x := 12.0 if f > 0 else -22.0
	var open := floorf(_mouth * 5.0)
	draw_rect(Rect2(head_x, -10 - open, 10, 5), out)  # maxila de cima
	draw_rect(Rect2(head_x + 1, -9 - open, 8, 3), Color(COL_BODY, a))
	draw_rect(Rect2(head_x, -5, 10, 5), out)  # mandibula
	draw_rect(Rect2(head_x + 1, -4, 8, 3), Color(COL_BELLY, a))
	if open > 0:
		draw_rect(Rect2(head_x + 1, -6 - open + 1, 8, open), Color(COL_MOUTH, a))
		for t in 3:
			draw_rect(Rect2(head_x + 2 + t * 3, -6 - open + 1, 1, 2), Color(COL_TOOTH, a))
			draw_rect(Rect2(head_x + 2 + t * 3, -6, 1, 1), Color(COL_TOOTH, a))
	# olho (em cima da cabeca, sempre visivel)
	var eye_x := head_x + (1.0 if f > 0 else 6.0)
	draw_rect(Rect2(eye_x, -13 - open, 4, 3), out)
	var blink := int(_anim) % 180 < 6  # pisca de vez em quando
	if not blink:
		draw_rect(Rect2(eye_x + 1, -12 - open, 2, 1), Color(1, 0.9, 0.2, a))
