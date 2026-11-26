extends Enemy
## Chefe gaviao (Fase Final). Vive numa arena delimitada por limite_esq / limite_dir / chao.
##
## Ciclo (etapa 1 com 5 de vida, etapa 2 com mais 5):
## 1. voo: paira no alto, seguindo o pato;
## 2. sequencia de MERGULHOS: grita (aviso), mira onde o pato esta e mergulha em linha reta;
##    ao bater no chao (ou num ressalto) sobe de volta. 3 mergulhos na etapa 1, 5 na etapa 2;
## 3. INVESTIDA: desce ate a parede do lado oposto ao pato, raspa as garras e atravessa a arena
##    rente ao chao (pule por cima ou suba num ressalto)... e bate na parede da torre;
## 4. atordoado: fica no chao com estrelinhas. So agora leva golpe (pisao ou caixa
##    arremessada). Depois de 2 golpes, ou quando o tempo acaba, levanta voo e recomeca.
## Com 5 de vida perdida passa para a etapa 2 (grita, fica vermelho, deixa cair um coracao) e
## fica mais rapido. Encostar nele machuca, menos atordoado.

const DISPLAY_NAME := "GAVIÃO"
const STAGE_HP := 5
const HITS_PER_STUN := 2
const HURT_TIME := 40
const TRANSITION_TIME := 100

const VidaScene := preload("res://scenes/vida.tscn")
const Sprites := preload("res://scripts/sprites.gd")
const QUADROS := 13  # tira assets/sprites/arte/chefe_gaviao.png (tools/arte/chefes.py)
const PIVO := Vector2(16, 15)  # centro do corpo no quadro de 64 px (16 px no jogo)
const Solids := preload("res://scripts/solids.gd")

const COL_OUT := Color8(36, 20, 10)
const COL_BODY := Color8(124, 72, 36)
const COL_WING := Color8(96, 54, 26)
const COL_WING_TIP := Color8(60, 34, 16)
const COL_BELLY := Color8(236, 214, 170)
const COL_STREAK := Color8(150, 96, 50)
const COL_TAIL := Color8(196, 80, 44)
const COL_BEAK := Color8(250, 196, 40)
const COL_EYE := Color8(255, 220, 60)
const COL_STAR := Color8(255, 220, 80)
const COL_RAGE := Color8(255, 70, 50)

## Paredes e chao da arena (px). A investida termina batendo numa das paredes.
@export var limite_esq := 208.0
@export var limite_dir := 528.0
@export var chao := 192.0
@export var altura_voo := 60.0
## Porta da entrada da arena: fecha quando a luta comeca.
@export var porta_entrada: NodePath

var state := "espera"  # espera | voo | aviso | mergulho | subida | preparar | carga_aviso | investida | atordoado | transicao
var dir := -1
var stage := 1
var dives_left := 3
var hits_in_stun := 0
var _timer := 0
var _anim := 0.0
var _vel := Vector2.ZERO
var _target := Vector2.ZERO


func sombra_largura() -> float:
	return 26.0


func _enemy_ready() -> void:
	add_to_group("chefe")
	max_hp = STAGE_HP * 2
	hp = max_hp
	hurt_frames = HURT_TIME
	effect_offset = Vector2(0, -4)
	particula_derrota = "pena"
	particulas_qtd = 40


# ------------------------------------------------------------- parametros por etapa
func _hover_time() -> int:
	return 80 if stage == 1 else 50


func _dives() -> int:
	return 3 if stage == 1 else 5


func _warn_time() -> int:
	return 30 if stage == 1 else 20


func _dive_speed() -> float:
	return 4.0 if stage == 1 else 5.2


func _charge_warn() -> int:
	return 40 if stage == 1 else 26


func _charge_speed() -> float:
	return 4.5 if stage == 1 else 6.0


func _stun_time() -> int:
	return 170 if stage == 1 else 140


func _fly_speed() -> float:
	return 2.0 if stage == 1 else 2.8


func _charge_y() -> float:
	return chao - 9.0


# ---------------------------------------------------------------- contrato Enemy
func get_mask() -> Rect2:
	return Rect2(roundf(position.x) - 14.0, roundf(position.y) - 8.0, 28.0, 16.0)


func stomp_line_y() -> float:
	return position.y - 4.0


func harmful() -> bool:
	return hp > 0 and not state in ["espera", "atordoado", "transicao"]


func hit(damage: int = 1) -> void:
	if state != "atordoado" or is_hurt():
		return
	super(damage)
	if hp <= 0:
		return
	Game.boss_hp = hp
	hits_in_stun += 1
	if hp == STAGE_HP:
		_start_transition()
	elif hits_in_stun >= HITS_PER_STUN:
		_take_off()


func defeat() -> void:
	Game.boss_hp = 0
	Game.clear_boss()
	Game.camera_limit = Rect2()
	Game.play_sfx("complete")
	super()


## Usado pelos testes para pular direto para um estado.
func force_state(s: String, frames := 999) -> void:
	state = s
	_timer = frames
	if s == "atordoado":
		position.y = chao - 8.0
		hits_in_stun = 0


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


# ------------------------------------------------------------------- logica
func _physics_process(_delta: float) -> void:
	if Game.game_state != "playing":
		return
	_anim += 1.0
	stompable = state == "atordoado"
	var p := _player()
	if state != "espera":
		_timer -= 1
	match state:
		"espera":
			if p != null and p.position.x > limite_esq + 24.0 and p.position.x < limite_dir:
				_start_fight()
		"voo":
			var tx := clampf(p.position.x if p != null else position.x, limite_esq + 24.0, limite_dir - 24.0)
			var target := Vector2(tx, altura_voo + sin(_anim * 0.07) * 4.0)
			dir = 1 if target.x > position.x else -1
			position = position.move_toward(target, _fly_speed())
			if _timer <= 0:
				if dives_left > 0:
					state = "aviso"
					_timer = _warn_time()
					Game.play_sfx("screech")
				else:
					state = "preparar"
					var side := -1.0 if (p != null and p.position.x > (limite_esq + limite_dir) * 0.5) else 1.0
					_target = Vector2(limite_esq + 22.0 if side < 0 else limite_dir - 22.0, _charge_y())
		"aviso":
			if p != null:
				dir = 1 if p.position.x >= position.x else -1
			if _timer <= 0:
				_start_dive(p)
		"mergulho":
			_dive_step()
		"subida":
			var target := Vector2(clampf(position.x, limite_esq + 24.0, limite_dir - 24.0), altura_voo)
			position = position.move_toward(target, 2.5)
			if position.distance_to(target) < 1.0:
				state = "voo"
				_timer = _hover_time() / 2
		"preparar":
			dir = 1 if _target.x > position.x else -1
			position = position.move_toward(_target, 3.0)
			if position.distance_to(_target) < 1.0:
				state = "carga_aviso"
				_timer = _charge_warn()
				dir = 1 if position.x < (limite_esq + limite_dir) * 0.5 else -1
				Game.play_sfx("screech")
		"carga_aviso":
			if _timer <= 0:
				state = "investida"
				_vel = Vector2(dir * _charge_speed(), 0)
				Game.play_sfx("swoop")
		"investida":
			_charge_step()
		"atordoado":
			if _timer <= 0:
				_take_off()
		"transicao":
			var target := Vector2((limite_esq + limite_dir) * 0.5, altura_voo)
			position = position.move_toward(target, 2.0)
			if _timer <= 0:
				state = "voo"
				_timer = _hover_time()
				dives_left = _dives()
	queue_redraw()


func _start_fight() -> void:
	state = "voo"
	_timer = _hover_time()
	dives_left = _dives()
	Game.set_boss(DISPLAY_NAME, hp, max_hp)
	Game.camera_limit = Rect2(limite_esq - 16.0, 0.0, limite_dir - limite_esq + 32.0, Game.room_height)
	Game.play_sfx("screech")
	var door := get_node_or_null(porta_entrada)
	if door != null:
		door.set_active(true)


func _start_dive(p: Node2D) -> void:
	_target = (p.position + Vector2(0, -8)) if p != null else Vector2(position.x, chao)
	var d := _target - position
	if d.length() < 1.0:
		d = Vector2(0, 1)
	_vel = d.normalized() * _dive_speed()
	state = "mergulho"
	Game.play_sfx("swoop")


func _dive_step() -> void:
	var snap := Solids.snapshot(get_tree())
	var next := position + _vel
	var r := Rect2(roundf(next.x) - 12.0, roundf(next.y) - 7.0, 24.0, 14.0)
	var out := next.x < limite_esq + 14.0 or next.x > limite_dir - 14.0 or next.y > chao - 8.0
	if out or Solids.hits(snap, r, _boxes()):
		dives_left -= 1
		state = "subida"
		Game.play_sfx("thud")
		return
	position = next


func _charge_step() -> void:
	var snap := Solids.snapshot(get_tree())
	var next := position + _vel
	var r := Rect2(roundf(next.x) - 14.0, roundf(next.y) - 8.0, 28.0, 16.0)
	if Solids.hits(snap, r) or next.x < limite_esq + 14.0 or next.x > limite_dir - 14.0:
		# bateu na parede da torre (ou numa caixa no caminho): atordoado no chao
		position.x = clampf(position.x, limite_esq + 14.0, limite_dir - 14.0)
		position.y = chao - 8.0
		state = "atordoado"
		_timer = _stun_time()
		hits_in_stun = 0
		Particulas.emit(get_tree(), "pedrinha", position + Vector2(dir * 14.0, -6), 10)
		Game.play_sfx("thud")
		Game.play_sfx("crack")
		return
	position = next


func _take_off() -> void:
	state = "subida"
	dives_left = _dives()
	hits_in_stun = 0


func _start_transition() -> void:
	stage = 2
	state = "transicao"
	_timer = TRANSITION_TIME
	hits_in_stun = 0
	Game.play_sfx("screech")
	# deixa cair um coracao no meio da arena
	var heart := VidaScene.instantiate()
	heart.position = Vector2((limite_esq + limite_dir) * 0.5, chao)
	get_parent().add_child(heart)


## As caixas nao interrompem o mergulho (passa por cima delas).
func _boxes() -> Array:
	return get_tree().get_nodes_in_group("caixa")


# ------------------------------------------------------------------- desenho
func _draw() -> void:
	var f := float(dir)
	var q := 0
	var cor := Color.WHITE
	match state:
		"mergulho":
			q = 6 + int(_anim / 6.0) % 2
		"investida":
			q = 8 + int(_anim / 6.0) % 2
		"atordoado":
			q = 10 + int(_anim / 8.0) % 3
		"aviso":
			q = 4 + int(_anim / 3.0) % 2
			if int(_anim / 3.0) % 2 == 0:
				cor = Color(1.5, 1.4, 1.2)  # pisca claro ao gritar
		"carga_aviso":
			q = int(_anim / 3.0) % 4
			cor = Color(1.5, 1.4, 1.2) if int(_anim / 2.0) % 2 == 0 else Color.WHITE
		_:
			q = int(_anim / 6.0) % 4
	if stage == 2 and state != "atordoado":
		cor = Color(1.0, 0.55, 0.45) if int(_anim / 6.0) % 4 == 0 else cor
	if state == "transicao":
		cor = Color(1.0, 0.55, 0.45) if int(_anim / 3.0) % 2 == 0 else Color.WHITE
	var tremor := Vector2.ZERO
	if state == "carga_aviso":
		tremor.x = 1.0 if int(_anim / 2.0) % 2 == 0 else -1.0
	Sprites.draw_bicho(self, "chefe_gaviao", q, QUADROS, PIVO, f < 0.0, cor, tremor)
