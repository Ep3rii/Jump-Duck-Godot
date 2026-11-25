@tool
extends Node2D
## Caixa de madeira 16x16 (decisoes D1/D2): cai com gravidade, e solida (da para subir nela),
## o pato empurra andando contra ela, pega com X/J e arremessa com X/J de novo
## (BAIXO + X/J pousa a caixa na frente). Arremessada, derrota inimigos e pressiona placas.
## Origem = centro da base, no chao (igual ao jogador).
## Se cair para fora do mapa, volta para onde comecou (o puzzle nunca trava).

const Solids := preload("res://scripts/solids.gd")
const Particulas := preload("res://scripts/particulas.gd")

const GRAVITY := 0.25
const MAX_FALL := 6.0
const THROW_SPEED := Vector2(3.5, -2.5)
const CARRY_OFFSET := Vector2(0, -15)  # acima da cabeca do pato

const COL_DARK := Color8(74, 40, 16)
const COL_WOOD := Color8(168, 104, 48)
const COL_LIGHT := Color8(214, 150, 80)
const COL_HAY_DARK := Color8(140, 104, 30)
const COL_HAY := Color8(222, 184, 74)
const COL_HAY_LIGHT := Color8(250, 226, 130)
const COL_STRING := Color8(150, 60, 40)

## So muda o desenho: caixa de madeira ou fardo de feno (fazenda).
@export_enum("Caixa", "Feno") var aparencia := 0:
	set(v):
		aparencia = v
		queue_redraw()

var state := "idle"  # idle | carried | thrown
var vel := Vector2.ZERO
var carrier: Node2D = null
var _start_pos := Vector2.ZERO


func _ready() -> void:
	add_to_group("caixa")
	add_to_group("weight")
	_start_pos = position
	_set_solid(true)


func _set_solid(on: bool) -> void:
	if on:
		add_to_group("solid")
	elif is_in_group("solid"):
		remove_from_group("solid")


func _rect_at(p: Vector2) -> Rect2:
	return Rect2(roundf(p.x) - 8.0, roundf(p.y) - 16.0, 16.0, 16.0)


## Retangulo solido (grupo "solid").
func get_rect() -> Rect2:
	return _rect_at(position)


## Mesma area, para placas de pressao e inimigos.
func get_mask() -> Rect2:
	return _rect_at(position)


## Bloqueado por solidos (menos ela mesma) ou pelo pato (a caixa nao cai "dentro" dele).
func _blocked(r: Rect2, snap: Array) -> bool:
	if Solids.hits(snap, r, [self]):
		return true
	var p := get_tree().get_first_node_in_group("player")
	return p != null and carrier == null and state == "idle" and r.intersects(p.get_mask())


func is_free_at(p: Vector2) -> bool:
	return not Solids.hits(Solids.snapshot(get_tree()), _rect_at(p), [self])


# ---------------------------------------------------------------- jogador
## Empurrada pelo pato: anda dx (pixel a pixel, para encostar certinho). Devolve se andou.
func push(dx: float) -> bool:
	if state != "idle" or dx == 0.0:
		return false
	var snap := Solids.snapshot(get_tree())
	if not Solids.hits(snap, _rect_at(position + Vector2(0, 1)), [self]) and _water_here() == null:
		return false  # caindo: nao empurra (boiando pode)
	var start := position.x
	var step := signf(dx)
	var remaining := absf(dx)
	while remaining > 0.0:
		var s := minf(1.0, remaining) * step
		if Solids.hits(snap, _rect_at(position + Vector2(s, 0)), [self]):
			break
		position.x += s
		remaining -= absf(s)
	return position.x != start


## Levada por uma plataforma movel (plataforma.gd).
func carry_by(d: Vector2, platform: Node) -> void:
	if state != "idle":
		return
	var snap := Solids.snapshot(get_tree())
	if d.x != 0.0 and not Solids.hits(snap, _rect_at(position + Vector2(d.x, 0)), [self, platform]):
		position.x += d.x
	position.y += d.y


func pick_up(by: Node2D) -> void:
	state = "carried"
	carrier = by
	vel = Vector2.ZERO
	_set_solid(false)
	z_as_relative = false
	z_index = -450  # na frente do jogador
	position = by.position + CARRY_OFFSET


## Solta a partir de onde esta (acima da cabeca). dir = -1/1; gentle = so pousar na frente.
## Devolve false se nao havia espaco.
func release(dir: int, gentle: bool) -> bool:
	if gentle:
		var spot := carrier.position + Vector2(dir * 16.0, 0)
		if not is_free_at(spot):
			return false
		position = spot
		vel = Vector2.ZERO
		_land()
		return true
	if not is_free_at(position):
		return false
	vel = Vector2(THROW_SPEED.x * dir, THROW_SPEED.y)
	state = "thrown"
	carrier = null
	z_as_relative = true
	z_index = 0
	Game.play_sfx("throw")
	return true


## Pato machucou/reapareceu: a caixa cai de onde esta (ou volta ao inicio se presa).
func drop() -> void:
	if not is_free_at(position):
		position = _start_pos
	vel = Vector2.ZERO
	_land()


## Volta para onde comecou (pato reapareceu no checkpoint carregando a caixa).
func reset_to_start() -> void:
	position = _start_pos
	vel = Vector2.ZERO
	_land()


func _land() -> void:
	state = "idle"
	carrier = null
	z_as_relative = true
	z_index = 0
	_set_solid(true)


# ---------------------------------------------------------------- fisica
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or Game.game_state != "playing":
		return
	match state:
		"carried":
			if is_instance_valid(carrier):
				position = carrier.position + CARRY_OFFSET
			else:
				drop()
		"thrown":
			_fly()
		_:
			_fall()
	if position.y > Game.room_height + 64:
		position = _start_pos
		vel = Vector2.ZERO
		_land()


## Agua em que a caixa esta (a base 4 px abaixo da linha d'agua ja conta).
func _water_here() -> Node2D:
	var p := position + Vector2(0, -4)
	for w in get_tree().get_nodes_in_group("agua"):
		if w.get_rect().has_point(p):
			return w
	return null


func _fall() -> void:
	var water := _water_here()
	if water != null:
		# boia: a base fica 4 px abaixo da linha d'agua (da para subir nela nadando)
		var target: float = water.surface_y() + 4.0
		position.y = move_toward(position.y, target, 1.0 if position.y > target else maxf(1.0, vel.y))
		vel.y = 0.0
		return
	var snap := Solids.snapshot(get_tree())
	if _blocked(_rect_at(position + Vector2(0, 1)), snap):
		vel.y = 0.0
		return
	vel.y = minf(vel.y + GRAVITY, MAX_FALL)
	_move_y(snap)


func _move_y(snap: Array) -> bool:
	if _blocked(_rect_at(position + Vector2(0, vel.y)), snap):
		position.y = roundf(position.y)
		var guard := 0
		while not _blocked(_rect_at(position + Vector2(0, signf(vel.y))), snap) and guard < 64:
			position.y += signf(vel.y)
			guard += 1
		vel.y = 0.0
		return true
	position.y += vel.y
	return false


func _fly() -> void:
	var snap := Solids.snapshot(get_tree())
	# Inimigos no caminho levam o golpe; a caixa quica para tras.
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not enemy.is_queued_for_deletion() and enemy.hp > 0 \
				and _rect_at(position).intersects(enemy.get_mask()):
			enemy.hit(1)
			vel.x = -vel.x * 0.3
			vel.y = -1.5
			break

	if vel.x != 0.0 and Solids.hits(snap, _rect_at(position + Vector2(vel.x, 0)), [self]):
		var guard := 0
		while not Solids.hits(snap, _rect_at(position + Vector2(signf(vel.x), 0)), [self]) and guard < 16:
			position.x += signf(vel.x)
			guard += 1
		vel.x = 0.0
	position.x += vel.x

	vel.y = minf(vel.y + GRAVITY, MAX_FALL)
	var falling := vel.y > 0.0
	if Solids.hits(snap, _rect_at(position + Vector2(0, vel.y)), [self]):
		var guard := 0
		position.y = roundf(position.y)
		while not Solids.hits(snap, _rect_at(position + Vector2(0, signf(vel.y))), [self]) and guard < 64:
			position.y += signf(vel.y)
			guard += 1
		vel.y = 0.0
		if falling:
			vel = Vector2.ZERO
			_land()
			Particulas.emit(get_tree(), "pouso", position, 6)
			Game.play_sfx("thud")
			return
	position.y += vel.y


# ---------------------------------------------------------------- desenho
func _draw() -> void:
	if aparencia == 1:
		_draw_feno()
		return
	var r := Rect2(-8, -16, 16, 16)
	draw_rect(r, COL_DARK)
	draw_rect(Rect2(-7, -15, 14, 14), COL_WOOD)
	# tabuas e travessa em X
	draw_rect(Rect2(-7, -11, 14, 1), COL_DARK)
	draw_rect(Rect2(-7, -6, 14, 1), COL_DARK)
	for i in 12:
		draw_rect(Rect2(-6 + i, -14 + i, 1, 1), COL_LIGHT)
		draw_rect(Rect2(5 - i, -14 + i, 1, 1), COL_LIGHT)
	draw_rect(Rect2(-7, -15, 14, 1), COL_LIGHT)


func _draw_feno() -> void:
	draw_rect(Rect2(-8, -16, 16, 16), COL_HAY_DARK)
	draw_rect(Rect2(-7, -15, 14, 14), COL_HAY)
	# palha (riscos horizontais) e as duas cordas
	for y in [-13, -10, -7, -4]:
		draw_rect(Rect2(-6, y, 5, 1), COL_HAY_LIGHT)
		draw_rect(Rect2(1, y + 1, 5, 1), COL_HAY_LIGHT)
	draw_rect(Rect2(-4, -15, 1, 14), COL_STRING)
	draw_rect(Rect2(3, -15, 1, 14), COL_STRING)
	draw_rect(Rect2(-7, -15, 14, 1), COL_HAY_LIGHT)
