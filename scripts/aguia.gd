extends Enemy
## Aguia (Fases 5 a 8): ave de rapina grande. Circula no alto em volta da posicao inicial.
## Quando o pato chega perto (abaixo dela), grita e treme por meio segundo, mira onde ele esta
## e MERGULHA EM DIAGONAL em linha reta. Se bate no chao ou numa parede, fica com o bico
## preso um tempo (a melhor hora para pisar nela); depois sobe de volta para o alto.
## Precisa de 2 golpes (pisao ou caixa arremessada). Origem = meio do corpo.
## Arte: assets/sprites/arte/aguia.png (16 quadros de voo, 16 de mergulho e 16 de bico preso).

const Solids := preload("res://scripts/solids.gd")
const Sprites := preload("res://scripts/sprites.gd")
const QUADROS := 48  # voo 0..15, mergulho 16..31, bico preso 32..47
const PIVO := Vector2(14, 13)  # meio do corpo, no quadro (px do jogo)
## Bico preso no chao (quadros 32..47): a ponta do bico e o pixel mais baixo do desenho e fica
## fixa em (19, 18) em todos os quadros; ela vai no ponto em que o bico encosta no piso.
const PIVO_PRESA := Vector2(19, 18)

const WARN_TIME := 32
const DIVE_SPEED := 3.4
const STUCK_TIME := 50
const RISE_SPEED := 1.2
const COOLDOWN := 110
const SEE_RANGE := 150.0
const CIRCLE := Vector2(28, 8)  # raio do voo em circulo (x, y)

const COL_STAR := Color("#fee761")  # amarelo da Endesga 32

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
## Bico preso: true = bateu no chao (pose de bico para baixo); false = bateu numa parede.
var _presa_chao := true
## Onde a ponta do bico encosta no piso, relativo a position (so com _presa_chao).
var _bico := Vector2.ZERO


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
		_prende(snap)
		return
	position = next
	_travel += DIVE_SPEED
	if _travel >= _max_travel or position.y > Game.room_height:
		state = "subindo"


## Caixa de colisao do mergulho com o centro em p.
func _caixa(p: Vector2) -> Rect2:
	return Rect2(roundf(p.x) - 6.0, roundf(p.y) - 4.0, 12.0, 8.0)


## Bateu em algo no mergulho: fica de bico preso. Se o choque foi embaixo (o passo so em y ja
## colide), encosta a ave no topo do solido, com a ponta do bico no piso; se foi de lado
## (parede), encosta na parede e nao usa a pose de bico para baixo.
func _prende(snap: Array) -> void:
	state = "presa"
	_timer = STUCK_TIME
	Game.play_sfx("thud")
	var so_y := Solids.hits(snap, _caixa(position + Vector2(0.0, _vel.y)))
	var so_x := Solids.hits(snap, _caixa(position + Vector2(_vel.x, 0.0)))
	_presa_chao = _vel.y > 0.0 and (so_y or not so_x)
	position = Vector2(roundf(position.x), roundf(position.y))
	if _presa_chao:
		# desce de 1 em 1 px ate a caixa encostar no topo do solido (sem entrar nele)
		for i in 8:
			if Solids.hits(snap, _caixa(position + Vector2(0, 1))):
				break
			position.y += 1.0
		# a base da caixa (position.y + 4) e o topo do piso: o pixel do bico fica logo acima
		_bico = Vector2(0.0, 3.0)
	else:
		var sx := signf(_vel.x)
		for i in 8:
			if sx == 0.0 or Solids.hits(snap, _caixa(position + Vector2(sx, 0))):
				break
			position.x += sx
		if sx != 0.0:
			dir = 1 if sx > 0.0 else -1


# ---------------------------------------------------------------- desenho
func _draw() -> void:
	# circulando/subindo: voo 0..15; aviso: bate mais rapido e treme; mergulho: 16..31;
	# bico preso no chao: 32..47 (tentando se soltar) com estrelinhas girando acima do corpo;
	# preso numa parede: o voo batendo rapido, encostado nela (nada de bico para baixo)
	var q := int(_anim * 16.0 / 36.0) % 16
	var tremor := Vector2.ZERO
	var pivo := PIVO
	if state == "aviso":
		q = int(_anim * 16.0 / 18.0) % 16
		tremor.x = 1.0 if int(_anim / 2.0) % 2 == 0 else -1.0
	elif state == "mergulho":
		q = 16 + int(_anim / 2.0) % 16
	elif state == "presa":
		if _presa_chao:
			q = 32 + int(_anim / 2.0) % 16
			pivo = PIVO_PRESA
			tremor = _bico
		else:
			q = int(_anim * 16.0 / 12.0) % 16
	Sprites.draw_bicho(self, "aguia", q, QUADROS, pivo, dir < 0, Color.WHITE, tremor)
	if state == "presa":
		# o corpo fica acima e atras do bico (no chao) ou em volta da origem (parede)
		var s := -1.0 if dir < 0 else 1.0
		var meio := Vector2(-5.0 * s, -20.0) + _bico if _presa_chao else Vector2(0.0, -14.0)
		for i in 3:
			var ang := _anim * 0.15 + i * TAU / 3.0
			var c := (meio + Vector2(cos(ang) * 9.0, sin(ang) * 2.0)).floor()
			draw_rect(Rect2(c.x, c.y - 1, 1, 3), COL_STAR)
			draw_rect(Rect2(c.x - 1, c.y, 3, 1), COL_STAR)
