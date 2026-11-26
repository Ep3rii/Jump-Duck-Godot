extends Node2D
## Sala "menu": um cantinho da fazenda atras dos menus (que sao desenhados por ui.gd, no
## autoload Game). Montado em codigo: chao do tileset de grama novo, moinho, arvore, arbusto,
## bichinhos (ambiente.gd) e o pato novo passeando. O pato da um pulinho toda vez que a
## selecao do menu muda.

const Sprites := preload("res://scripts/sprites.gd")
const PlayerScript := preload("res://scripts/player.gd")
const DecoScene := preload("res://scenes/decoracao.tscn")
const GrassTiles := preload("res://assets/tilesets/grama_solida.tres")

const GROUND_Y := 164.0  # topo do chao (o pe do pato)
const WALK_MIN := 78.0
const WALK_MAX := 244.0
const WALK_SPEED := 0.6  # px por frame (passeando)
const GRAVITY := 0.25
const HOP_SPEED := -3.0

var _duck: AnimatedSprite2D
var _x := 120.0
var _y := 0.0  # altura do pulinho (negativo = no ar)
var _vy := 0.0
var _dir := 1
var _pause := 0.0  # segundos parado antes de voltar a andar
var _last_sel := -1
var _last_state := ""


func _enter_tree() -> void:
	Game.leave_level()
	Game.room = "menu"
	Game.room_width = 320
	Game.room_height = 180
	Game.cam_pos = Vector2.ZERO
	Game.view_size = Vector2(320, 180)
	Game.camera_offset_y = -50.0


func _ready() -> void:
	_build_ground()
	_add_deco(0, Vector2(26, GROUND_Y))   # moinho
	_add_deco(3, Vector2(292, GROUND_Y))  # arvore
	_add_deco(4, Vector2(236, GROUND_Y))  # arbusto
	var amb := Node2D.new()
	amb.name = "Ambiente"
	amb.set_script(preload("res://scripts/ambiente.gd"))
	add_child(amb)
	var sombras := Node2D.new()
	sombras.name = "Sombras"
	sombras.z_index = -690
	sombras.set_script(preload("res://scripts/sombras.gd"))
	add_child(sombras)
	_duck = Sprites.make_art_sprite(Sprites.art_frames(PlayerScript.ART_ANIMS), PlayerScript.ART_ORIGIN)
	_duck.name = "Pato"
	_duck.z_index = 5
	add_child(_duck)
	_duck.play("run")
	_update_duck()


func _build_ground() -> void:
	var layer := TileMapLayer.new()
	layer.name = "Chao"
	layer.tile_set = GrassTiles
	layer.scale = Vector2(0.5, 0.5)
	layer.position = Vector2(0, GROUND_Y - 160.0)
	layer.z_index = -800
	layer.add_to_group("solid_tiles")  # o ambiente poe tufos de grama e florzinhas em cima
	add_child(layer)
	var cells := {}
	for cx in range(-1, 21):
		cells[Vector2i(cx, 10)] = true
		cells[Vector2i(cx, 11)] = true
	for c: Vector2i in cells:
		var idx := Level._grass_tile_for(cells, c, 12)
		layer.set_cell(c, 0, Vector2i(idx % 4, idx / 4))


func _add_deco(tipo: int, pos: Vector2) -> void:
	var d: Node2D = DecoScene.instantiate()
	d.set("tipo", tipo)
	d.position = pos
	d.z_index = -900
	add_child(d)


func _process(delta: float) -> void:
	var f := delta * 60.0
	# pulinho quando a selecao muda (so no menu principal, e nao ao entrar na tela)
	var sel: int = Game.ui_selection
	var state: String = Game.game_state
	if state == "main" and _last_state == "main" and sel != _last_sel and _y >= 0.0:
		_vy = HOP_SPEED
	_last_sel = sel
	_last_state = state

	if _vy != 0.0 or _y < 0.0:
		_y += _vy * f
		_vy += GRAVITY * f
		if _y >= 0.0:
			_y = 0.0
			_vy = 0.0
	if _pause > 0.0:
		_pause -= delta
	else:
		_x += _dir * WALK_SPEED * f
		if _x >= WALK_MAX or _x <= WALK_MIN:
			_x = clampf(_x, WALK_MIN, WALK_MAX)
			_dir = -_dir
			_pause = 1.6
	_update_duck()


func _update_duck() -> void:
	_duck.position = Vector2(floorf(_x), GROUND_Y + floorf(_y))
	_duck.flip_h = _dir < 0
	var anim := "idle" if _pause > 0.0 else "run"
	if _y < 0.0:
		anim = "jump" if _vy < -PlayerScript.APEX_SPEED else ("fall" if _vy > PlayerScript.APEX_SPEED else "apex")
	if _duck.animation != anim:
		_duck.play(anim)
	_duck.speed_scale = 0.6 if anim == "run" else 1.0
