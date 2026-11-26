extends Enemy
## Jacare comum (Fases 2 e 3): vive numa agua (agua.tscn) e vai e volta nadando.
## - Na superficie, com a cabeca e as costas para fora: pode ser pisado (1 pisao derrota).
## - De tempos em tempos mergulha: ai nao pode ser pisado e so pega quem esta mergulhado.
## - Encostar nele machuca (mordida); ele abre a boca quando o pato chega perto.
## Origem = meio da barriga, embaixo. Arte: assets/sprites/arte/jacare.png (4 quadros nadando
## e 2 de mordida); a mascara continua do tamanho da do pato.

const Solids := preload("res://scripts/solids.gd")

const SURFACE_TIME := 240  # frames na superficie
const DIVE_TIME := 120  # frames mergulhado
const DIVE_DEPTH := 14.0  # quanto afunda (px)
const FLOAT_DEPTH := 9.0  # na superficie fica meio afundado: costas e olhos para fora
const HALF_W := 8.0  # meia largura (16 px, como o pato)
const Sprites := preload("res://scripts/sprites.gd")
const QUADROS := 6
const PIVO := Vector2(16, 11)  # meio da barriga, no quadro (px do jogo)
const BODY_H := 9.0


@export var velocidade := 0.4
## Comeca a ciclo ja mergulhado (para varios jacares nao mergulharem juntos).
@export var comeca_mergulhado := false

var dir := -1
var state := "surface"  # surface | dive
var water: Node2D = null
var _timer := 0
var _mouth := 0.0  # 0 fechada .. 1 aberta
var _anim := 0.0


func sombra_largura() -> float:
	return 0.0


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
	# nadando: quadros 0..3; boca abrindo (mordida): 4 e 5. Mergulhado fica meio apagado.
	var q := int(_anim / 9.0) % 4
	if _mouth > 0.6:
		q = 5
	elif _mouth > 0.2:
		q = 4
	var a := 1.0 if state == "surface" else 0.55
	Sprites.draw_bicho(self, "jacare", q, QUADROS, PIVO, dir < 0, Color(1, 1, 1, a))
