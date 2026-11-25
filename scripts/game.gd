extends Node
## Equivalente ao obj_game_manager do GameMaker (autoload "Game").
## Guarda o estado global (global.* no GML), cuida de menus, pausa, pontuacao,
## configuracoes de tela/volume e da musica. O desenho dos menus/HUD fica em ui.gd.
##
## Pausa: quando estamos numa fase e o estado nao e "playing", a arvore inteira e pausada
## (get_tree().paused). O Game e a UI rodam com PROCESS_MODE_ALWAYS; jogador, inimigos,
## itens, efeitos e paralaxe param sozinhos.

const UIScript := preload("res://scripts/ui.gd")
const SETTINGS_PATH := "user://jump_duck_settings.cfg"
const FIRST_LEVEL := "tutorial_fase1"

const ACTIONS := {
	"left": [KEY_LEFT, KEY_A],
	"right": [KEY_RIGHT, KEY_D],
	"up": [KEY_UP, KEY_W],
	"down": [KEY_DOWN, KEY_S],
	"jump": [KEY_SPACE],
	"confirm": [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE],
	"pause": [KEY_ESCAPE],
}

# --- estado global (global.* no GML) ---------------------------------------
## main | settings | pause | playing | complete | gameover
var game_state := "main":
	set(value):
		if value == "playing" and game_state != "playing":
			# O mesmo aperto de ESPACO que confirmou o menu nao pode virar pulo (B1).
			resume_frame = Engine.get_physics_frames()
		game_state = value
		_update_pause()
var pause_origin := "playing"
var max_lives := 3
var player_lives := 3
var invulnerability_remaining := 0
var current_collectibles := 0
var total_collectibles := 3
var level_elapsed_seconds := 0.0
var level_started := false  # fase em andamento (ainda nao concluida)
var level_history: Array = []
var total_score := 0
var ui_selection := 0
var resolution_index := 2
var volume_level := 8
var screen_mode := "fullscreen"  # fullscreen | borderless | windowed

## Frame de fisica em que o jogo voltou para "playing" (o jogador ignora o pulo nesse frame).
var resume_frame := -1

# --- depuracao (so em builds de debug: F1..F4) ------------------------------
var debug_invincible := false

# --- sala atual (preenchido por menu.gd / level.gd) ------------------------
var room := "menu"
var room_width := 320
var room_height := 180
var cam_pos := Vector2.ZERO  # canto superior esquerdo da "view" (camera.gd)
var in_level := false  # true enquanto uma cena de fase (level.gd) esta ativa
var current_level_name := ""
var next_level := ""

var pending_resize := false
var pending_window_size := Vector2i(1920, 1080)

var _ui_last_mouse := Vector2(-1, -1)
var _mouse_prev := false
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_load_settings()

	var screen := DisplayServer.screen_get_size()
	DisplayServer.window_set_min_size(Vector2i(mini(960, screen.x), mini(540, screen.y)))

	# Camada de GUI 320x180 (display_set_gui_size) onde menus e HUD sao desenhados.
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var ui := UIScript.new()
	layer.add_child(ui)

	# Musica de fundo em loop (audio_play_sound(..., true, 0.6)).
	_music = AudioStreamPlayer.new()
	var stream: AudioStream = load("res://assets/audio/MP3_SND_Grasslands.mp3")
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	_music.stream = stream
	_music.volume_db = linear_to_db(0.6)
	add_child(_music)
	_music.play()

	apply_settings()


func _setup_input() -> void:
	for action: String in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: int in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key as Key
			InputMap.action_add_event(action, ev)


func _update_pause() -> void:
	if is_inside_tree():
		get_tree().paused = in_level and game_state != "playing"


# ---------------------------------------------------------------- utilidades
func room_goto(room_name: String) -> void:
	# Sai da fase atual ja: nada da cena antiga roda pausado/contado ate a troca acontecer.
	in_level = false
	level_started = false
	_update_pause()
	get_tree().change_scene_to_file("res://scenes/%s.tscn" % room_name)


func start_new_game() -> void:
	player_lives = max_lives
	invulnerability_remaining = 0
	current_collectibles = 0
	total_score = 0
	level_history.clear()
	game_state = "playing"
	room_goto(FIRST_LEVEL)


## Recomeca a fase atual. Se ela ja tinha sido concluida, descarta aquele resultado.
func restart_level() -> void:
	if level_history.size() > 0 and level_history[-1]["level_name"] == current_level_name:
		level_history.pop_back()
		_recount_total_score()
	if player_lives <= 0:
		player_lives = max_lives
	invulnerability_remaining = 0
	game_state = "playing"
	room_goto(current_level_name)


func go_to_next_level() -> void:
	if next_level.is_empty():
		go_to_menu()
		return
	invulnerability_remaining = 0
	game_state = "playing"
	room_goto(next_level)


func go_to_menu() -> void:
	game_state = "main"
	ui_selection = 0
	room_goto("menu")


## Chamado pela cena de menu (menu.gd).
func leave_level() -> void:
	in_level = false
	level_started = false
	_update_pause()


## Chamado por level.gd quando a fase esta pronta (todos os filhos ja rodaram _ready).
func begin_level(level: Level) -> void:
	in_level = true
	current_level_name = level.level_id
	next_level = level.next_level
	level_elapsed_seconds = 0.0
	current_collectibles = 0
	var flowers := 0
	for f in get_tree().get_nodes_in_group("flor"):
		if level.is_ancestor_of(f):
			flowers += 1
	total_collectibles = maxi(1, flowers)
	level_started = true
	# Rodar a cena da fase direto pelo editor (F6) cai aqui com o estado "main".
	if game_state == "main":
		game_state = "playing"
	_update_pause()


func collect_flower() -> void:
	current_collectibles += 1
	if current_collectibles >= total_collectibles:
		finish_level()


func finish_level() -> void:
	if not level_started:
		return

	var time_points := roundi(clampf(
		50.0 * (1.0 - maxf(0.0, level_elapsed_seconds - 30.0) / 270.0), 0.0, 50.0))
	var collectible_points := floori(
		50.0 * current_collectibles / maxf(1.0, float(total_collectibles)))
	var level_score := time_points + collectible_points

	level_history.append({
		"level_name": current_level_name,
		"time_seconds": level_elapsed_seconds,
		"collectibles": current_collectibles,
		"collectible_total": total_collectibles,
		"time_points": time_points,
		"collectible_points": collectible_points,
		"score": level_score,
	})
	_recount_total_score()

	level_started = false
	ui_selection = 0
	game_state = "complete"


func _recount_total_score() -> void:
	total_score = 0
	for entry: Dictionary in level_history:
		total_score += entry["score"]


## Estrelas de uma pontuacao de fase (0..100).
static func stars_for(score: int) -> int:
	if score >= 90:
		return 3
	if score >= 60:
		return 2
	return 1


# ------------------------------------------------------------- configuracoes
func _load_settings() -> void:
	# Rodando pelo editor abre em janela; o jogo exportado abre em tela cheia (B6).
	screen_mode = "windowed" if OS.has_feature("editor") else "fullscreen"
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		volume_level = clampi(roundi(float(cfg.get_value("audio", "volume", 8))), 0, 10)
		screen_mode = str(cfg.get_value("display", "mode", screen_mode))
		resolution_index = clampi(roundi(float(cfg.get_value("display", "resolution", 2))), 0, 2)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", volume_level)
	cfg.set_value("display", "mode", screen_mode)
	cfg.set_value("display", "resolution", resolution_index)
	cfg.save(SETTINGS_PATH)


func apply_settings() -> void:
	var w := 1920
	var h := 1080
	match resolution_index:
		0:
			w = 1280
			h = 720
		1:
			w = 1600
			h = 900
	var screen := DisplayServer.screen_get_size()
	var display_scale := minf(1.0, minf(float(screen.x) / w, float(screen.y) / h))
	w = floori(w * display_scale)
	h = floori(h * display_scale)

	# audio_master_gain(volume / 10)
	AudioServer.set_bus_mute(0, volume_level == 0)
	if volume_level > 0:
		AudioServer.set_bus_volume_db(0, linear_to_db(volume_level / 10.0))

	match screen_mode:
		"fullscreen":
			pending_resize = false
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			# Tela cheia "sem borda" do sistema: alt-tab funciona no Windows (B6).
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			pending_window_size = Vector2i(w, h)
			pending_resize = true
		_:
			screen_mode = "windowed"
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			pending_window_size = Vector2i(w, h)
			pending_resize = true


# ----------------------------------------------------------------- layout UI
func ui_rect(cy: int, w: int, h: int, label: String) -> Dictionary:
	var half_w := floori(w / 2.0)
	var half_h := floori(h / 2.0)
	return {
		"x1": 160 - half_w,
		"y1": cy - half_h,
		"x2": 160 + half_w,
		"y2": cy + half_h,
		"label": label,
	}


## Layout unico usado pelo Step (mouse) e pelo desenho (ui.gd), para nunca desalinhar.
## As acoes dos botoes sao escolhidas pelo texto (label), nao pela posicao.
func ui_layout() -> Array:
	match game_state:
		"main":
			return [ui_rect(100, 150, 20, "JOGAR"),
				ui_rect(124, 150, 20, "CONFIGURAÇÕES"),
				ui_rect(148, 150, 20, "SAIR")]
		"settings":
			return [ui_rect(58, 220, 20, "TELA"),
				ui_rect(82, 220, 20, "JANELA"),
				ui_rect(106, 220, 20, "VOLUME"),
				ui_rect(136, 120, 20, "VOLTAR")]
		"pause":
			return [ui_rect(84, 150, 20, "CONTINUAR"),
				ui_rect(108, 150, 20, "CONFIGURAÇÕES"),
				ui_rect(132, 150, 20, "MENU PRINCIPAL")]
		"complete":
			if not next_level.is_empty():
				return [ui_rect(128, 150, 16, "PRÓXIMA FASE"),
					ui_rect(146, 150, 16, "JOGAR NOVAMENTE"),
					ui_rect(164, 150, 16, "MENU PRINCIPAL")]
			return [ui_rect(137, 150, 18, "MENU PRINCIPAL"),
				ui_rect(158, 150, 18, "JOGAR NOVAMENTE")]
		"gameover":
			return [ui_rect(118, 150, 20, "TENTAR NOVAMENTE"),
				ui_rect(142, 150, 20, "MENU PRINCIPAL")]
	return []


# ----------------------------------------------------------- teclas de debug
func _input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not in_level:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_F1:  # invencivel
			debug_invincible = not debug_invincible
		KEY_F2:  # +1 vida
			player_lives = mini(max_lives, player_lives + 1)
		KEY_F3:  # recomecar a fase
			restart_level()
		KEY_F4:  # concluir a fase agora
			if game_state == "playing":
				finish_level()


# ------------------------------------------------------------ Step do manager
func _physics_process(delta: float) -> void:
	if pending_resize:
		DisplayServer.window_set_size(pending_window_size)
		var screen := DisplayServer.screen_get_size()
		DisplayServer.window_set_position(Vector2i(
			maxi(0, floori((screen.x - pending_window_size.x) / 2.0)),
			maxi(0, floori((screen.y - pending_window_size.y) / 2.0))))
		pending_resize = false

	if in_level and level_started and game_state == "playing":
		level_elapsed_seconds += delta

	var esc := Input.is_action_just_pressed("pause")

	if in_level and game_state == "playing" and esc:
		pause_origin = "playing"
		ui_selection = 0
		game_state = "pause"
		return

	if esc:
		if game_state == "pause":
			game_state = "playing"
			return
		if game_state == "settings":
			game_state = "pause" if pause_origin == "pause" else "main"
			ui_selection = 0
			return
		if game_state == "gameover" or game_state == "complete":
			go_to_menu()
			return

	var mp := get_viewport().get_mouse_position()
	var mouse_moved := mp != _ui_last_mouse
	_ui_last_mouse = mp

	var mouse_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var mouse_pressed := mouse_down and not _mouse_prev
	_mouse_prev = mouse_down

	var activate := Input.is_action_just_pressed("confirm")
	var left := Input.is_action_just_pressed("left")
	var right := Input.is_action_just_pressed("right")
	var up := Input.is_action_just_pressed("up")
	var down := Input.is_action_just_pressed("down")
	var action := -1

	var layout := ui_layout()
	var rows := layout.size()

	if rows > 0:
		if up:
			ui_selection = (ui_selection + rows - 1) % rows
		if down:
			ui_selection = (ui_selection + 1) % rows
		ui_selection = clampi(ui_selection, 0, rows - 1)

		for i in rows:
			var r: Dictionary = layout[i]
			if mp.x >= r["x1"] and mp.x <= r["x2"] and mp.y >= r["y1"] and mp.y <= r["y2"]:
				if mouse_moved or mouse_pressed:
					ui_selection = i
				if mouse_pressed:
					action = i
					# Nas linhas de ajuste, clicar na metade esquerda diminui e na direita aumenta
					if game_state == "settings" and i <= 2:
						if mp.x < (r["x1"] + r["x2"]) / 2.0:
							left = true
						else:
							right = true
						action = -1

		if activate:
			if game_state == "settings" and ui_selection <= 2:
				right = true
			else:
				action = ui_selection

	if game_state == "settings" and (left or right) and ui_selection <= 2:
		var dir := 1 if right else -1
		match ui_selection:
			0:
				var modes := ["windowed", "fullscreen", "borderless"]
				var mode_index := 1
				if screen_mode == "windowed":
					mode_index = 0
				if screen_mode == "borderless":
					mode_index = 2
				mode_index = (mode_index + dir + 3) % 3
				screen_mode = modes[mode_index]
				apply_settings()
				save_settings()
			1:
				resolution_index = (resolution_index + dir + 3) % 3
				if screen_mode != "fullscreen":
					apply_settings()
				save_settings()
			2:
				volume_level = clampi(volume_level + dir, 0, 10)
				apply_settings()
				save_settings()

	if action < 0:
		return
	_run_menu_action(layout[action]["label"])


func _run_menu_action(label: String) -> void:
	match label:
		"JOGAR":
			start_new_game()
		"CONFIGURAÇÕES":
			pause_origin = "pause" if game_state == "pause" else "main"
			ui_selection = 0
			game_state = "settings"
		"SAIR":
			get_tree().quit()
		"VOLTAR":
			game_state = "pause" if pause_origin == "pause" else "main"
			ui_selection = 0
		"CONTINUAR":
			game_state = "playing"
		"MENU PRINCIPAL":
			go_to_menu()
		"PRÓXIMA FASE":
			go_to_next_level()
		"JOGAR NOVAMENTE":
			restart_level()
		"TENTAR NOVAMENTE":
			# Por enquanto recomeca o jogo todo, como antes (decisao D3 do PLANO.md).
			start_new_game()
