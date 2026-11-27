extends Node
const PixelFx := preload("res://scripts/pixelfx.gd")
## Equivalente ao obj_game_manager do GameMaker (autoload "Game").
## Guarda o estado global, cuida de menus, pausa, pontuacao, progresso salvo,
## configuracoes de tela/volume, musica e efeitos sonoros. O desenho fica em ui.gd.
##
## Pausa: numa fase, fora do estado "playing", a arvore inteira e pausada
## (get_tree().paused). O Game e a UI rodam com PROCESS_MODE_ALWAYS; jogador, inimigos,
## itens, efeitos e paralaxe param sozinhos. Durante o fade entre cenas tambem.

const UIScript := preload("res://scripts/ui.gd")
const Sfx := preload("res://scripts/sfx.gd")
const ToqueScript := preload("res://scripts/toque.gd")

## Tela do jogo: 384x216 pixels do jogo (o mundo visivel), ampliada por um fator INTEIRO
## (Window.CONTENT_SCALE_STRETCH_INTEGER): 3x com faixas pretas em 1280x720, 5x em 1920x1080,
## 6x com faixas em 2560x1440, 10x em 4K. Assim cada pixel da arte tem sempre o mesmo numero
## de pixels da tela (nada de contorno de 3 e 4 px, nem a arte tremendo com a camera), e o HUD
## tem o mesmo pixel do mundo.
const TELA := Vector2i(384, 216)
## Os menus foram desenhados numa grade de 320x180: ficam centrados na tela de 384x216.
const UI_DESIGN := Vector2(320, 180)
const UI_OFS := (Vector2(TELA) - UI_DESIGN) / 2.0

## Ordem das fases do jogo. "id" = caminho da cena a partir de res://scenes/ (sem .tscn);
## "name" = nome nas telas. (E "var" so para os testes trocarem pela fase de testes.)
## Para adicionar uma fase: crie a cena (ver README) e acrescente uma linha aqui.
var levels: Array = [
	{"id": "tutorial", "name": "A FAZENDA"},        # tutorial
	{"id": "fase1", "name": "O CAMINHO"},
	{"id": "fase2", "name": "O LAGO"},
	{"id": "fase3", "name": "O JACARÉ GIGANTE"},
	{"id": "fase4", "name": "A PORTA DA TORRE"},
	{"id": "fase5", "name": "A ÁGUIA"},
	{"id": "fase6", "name": "VENTO FORTE"},
	{"id": "fase7", "name": "O POÇO ALTO"},
	{"id": "fase8", "name": "QUASE NO TOPO"},
	{"id": "fase_final", "name": "O GAVIÃO"},
]

## Fase de testes com todas as mecanicas (nao conta progresso; so aparece em build de debug).
const LAB_LEVEL := "laboratorio"
## Ultima fase do jogo: a tela de fase concluida dela leva a cutscene final.
const FINAL_LEVEL := "fase_final"
const ENDING_SCENE := "cutscene_final"
## Cutscene do comeco (o Rei Gaviao leva a Pata): abre o jogo novo e termina no tutorial.
const INTRO_SCENE := "cutscene_inicial"

const FADE_TIME := 0.2
const SETTINGS_ADJUST_ROWS := 4  # TELA, JANELA, MUSICA, EFEITOS (ajustaveis com esq/dir)

const ACTIONS := {
	"left": [KEY_LEFT, KEY_A],
	"right": [KEY_RIGHT, KEY_D],
	"up": [KEY_UP, KEY_W],
	"down": [KEY_DOWN, KEY_S],
	"jump": [KEY_SPACE],
	"grab": [KEY_X, KEY_J],  # pegar / arremessar caixa
	"confirm": [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE],
	"pause": [KEY_ESCAPE],
}
## Teclas que o jogador pode trocar (CONTROLES): 2 por acao, na ordem da tela. 0 = vazio.
## O padrao vem de ACTIONS (a pausa troca ESC, que e fixo, pela tecla P).
const TECLAS_ACOES := ["left", "right", "up", "down", "jump", "grab", "pause"]
const TECLAS_NOMES := {"left": "ESQUERDA", "right": "DIREITA", "up": "CIMA / OLHAR",
	"down": "BAIXO / OLHAR", "jump": "PULAR", "grab": "PEGAR CAIXA", "pause": "PAUSAR"}
const TECLAS_PADRAO := {"left": [KEY_LEFT, KEY_A], "right": [KEY_RIGHT, KEY_D],
	"up": [KEY_UP, KEY_W], "down": [KEY_DOWN, KEY_S], "jump": [KEY_SPACE, KEY_K],
	"grab": [KEY_X, KEY_J], "pause": [KEY_P, 0]}
## Fixas (nao aparecem para trocar): ESC pausa e volta nos menus; ENTER confirma (com as teclas
## de pular).
const TECLAS_FIXAS := {"pause": [KEY_ESCAPE], "confirm": [KEY_ENTER, KEY_KP_ENTER]}
## Controle (gamepad): botoes de cada acao e eixo do analogico esquerdo [eixo, sentido].
const JOY_BOTOES := {
	"left": [JOY_BUTTON_DPAD_LEFT],
	"right": [JOY_BUTTON_DPAD_RIGHT],
	"up": [JOY_BUTTON_DPAD_UP],
	"down": [JOY_BUTTON_DPAD_DOWN],
	"jump": [JOY_BUTTON_A],
	"grab": [JOY_BUTTON_X, JOY_BUTTON_Y],
	"confirm": [JOY_BUTTON_A, JOY_BUTTON_START],
	"pause": [JOY_BUTTON_START, JOY_BUTTON_BACK],
}
const JOY_EIXOS := {
	"left": [JOY_AXIS_LEFT_X, -1.0],
	"right": [JOY_AXIS_LEFT_X, 1.0],
	"up": [JOY_AXIS_LEFT_Y, -1.0],
	"down": [JOY_AXIS_LEFT_Y, 1.0],
}

# --- arquivos (variaveis para os testes usarem arquivos proprios) -----------
var settings_path := "user://jump_duck_settings.cfg"
var save_path := "user://jump_duck_save.cfg"

# --- estado global ----------------------------------------------------------
## main | levels | credits | settings | controls | pause | playing | complete | gameover
var game_state := "main":
	set(value):
		if value == "playing" and game_state != "playing":
			# O mesmo aperto de ESPACO que confirmou o menu nao pode virar pulo.
			resume_frame = Engine.get_physics_frames()
		game_state = value
		_update_pause()
var credits_after_ending := false  # creditos abertos pelo fim da cutscene (mostra "FIM")
var pause_origin := "playing"  # de onde as configuracoes foram abertas: "pause" ou "main"
var max_lives := 3
var player_lives := 3
var invulnerability_remaining := 0
var current_collectibles := 0
var total_collectibles := 3
var level_elapsed_seconds := 0.0
var level_started := false  # fase em andamento (ainda nao concluida)
var level_history: Array = []  # resultados das fases desta partida
var total_score := 0
var last_result_is_record := false
var ui_selection := 0
var resolution_index := 2
var music_volume := 8
var sfx_volume := 8
var screen_mode := "fullscreen"  # fullscreen | borderless | windowed

## Frame de fisica em que o jogo voltou para "playing" (o jogador ignora o pulo nesse frame).
var resume_frame := -1

# --- progresso salvo --------------------------------------------------------
## Ja terminou a aventura (viu a cutscene final): libera FASES no menu principal.
var zerado := false
var unlocked_count := 1  # quantas fases (na ordem de levels) estao liberadas
var best := {}  # id da fase -> {"score": int, "stars": int, "time": float}

# --- depuracao (so em builds de debug: F1..F4) ------------------------------
var debug_invincible := false

# --- folego do pato (player.gd escreve; ui.gd desenha as bolhas) -------------
var air_ratio := 1.0
var show_air := false

# --- chaves no bolso do pato (chave.gd soma; porta trancada gasta; ui.gd desenha) ---
var keys := 0

# --- vida do chefe da fase (o chefe chama set_boss / clear_boss) ------------
# Nao ha mais barra no HUD (ui.gd): estes valores ficam para os chefes, a arena e os testes.
var boss_visible := false
var boss_label := ""
var boss_hp := 0
var boss_max := 0

# --- sala atual (preenchido por menu.gd / level.gd) ------------------------
var room := "menu"
var room_width := 320
var room_height := 180
var cam_pos := Vector2.ZERO  # canto superior esquerdo da "view" (camera.gd)
var view_size := Vector2(TELA)  # area do mundo que a tela mostra (384x216, ver TELA)
## Px a mais que a camera mostra acima (<0) ou abaixo (>0) com o pato olhando (player.gd).
var camera_olhar := 0.0
var camera_offset_y := -50.0  # Level.camera_offset_y da fase atual
## Retangulo da sala que a camera pode mostrar (vazio = a sala toda). A arena do chefe
## (arena_chefe.gd) prende a camera nele: nada fora dele aparece, em x e em y.
var camera_limit := Rect2()
## Quadros da transicao suave quando camera_limit volta a ficar vazio (camera.gd le e zera).
## 0 = usa o padrao da camera (camera.gd SOLTAR_QUADROS).
var camera_soltar_quadros := 0
## Quadros do deslize suave quando camera_limit liga (arena fechando; camera.gd le e zera).
## 0 = usa o padrao da camera (camera.gd FECHAR_QUADROS).
var camera_fechar_quadros := 0
## Arena de chefe fechada agora (arena_chefe.gd), ou null.
var arena_chefe: Node = null
var in_level := false  # true enquanto uma cena de fase (level.gd) esta ativa
var current_level_name := ""
var has_checkpoint := false
var checkpoint_pos := Vector2.ZERO
var transitioning := false
## Teclas escolhidas: acao -> [tecla 1, tecla 2] (physical keycode; 0 = vazio).
var teclas := {}
## CONTROLES: acao esperando a tecla nova ("" = nenhuma) e qual das 2 colunas (0 ou 1).
var tecla_esperando := ""
var tecla_coluna := 0
var _tecla_ate_quadro := -1  # ignora o menu ate este quadro (a tecla nova nao vale como comando)
var toque: Node2D = null  # controles de toque na tela (toque.gd)

var pending_resize := false
var pending_window_size := Vector2i(1920, 1080)

var _ui_last_mouse := Vector2(-1, -1)
var _mouse_prev := false
var _prev_state := ""
var _prev_selection := -1
var _music: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_next := 0
var _fade: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_setup_buses()
	_load_settings()
	load_progress()

	var screen := DisplayServer.screen_get_size()
	DisplayServer.window_set_min_size(Vector2i(mini(960, screen.x), mini(540, screen.y)))
	_setup_screen()

	# Camada de GUI onde menus e HUD sao desenhados (menus na grade de 320x180, centrada).
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	layer.add_child(UIScript.new())

	# Controles de toque (celular): acima do HUD, abaixo do fade.
	var toque_layer := CanvasLayer.new()
	toque_layer.layer = 15
	add_child(toque_layer)
	toque = ToqueScript.new()
	toque_layer.add_child(toque)

	# Cortina preta do fade entre cenas, acima de tudo.
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 20
	add_child(fade_layer)
	_fade = ColorRect.new()
	# fade pixelado: o alfa vira cortina de blocos 2x2 em dither (PixelFx), na cor mais escura da paleta
	_fade.color = Color(PixelFx.COR_CORTINA, 0.0)
	_fade.material = PixelFx.material_cortina()
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(_fade)

	# Musica de fundo em loop.
	_music = AudioStreamPlayer.new()
	var stream: AudioStream = load("res://assets/audio/MP3_SND_Grasslands.mp3")
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	_music.stream = stream
	_music.volume_db = linear_to_db(0.6)
	_music.bus = "Music"
	add_child(_music)
	_music.play()

	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)

	apply_settings()


## Tela de 384x216 ampliada so por fatores inteiros (ver TELA).
func _setup_screen() -> void:
	var root := get_tree().root
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = TELA
	root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER


func _setup_input() -> void:
	for action: String in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.5)
		for b: int in JOY_BOTOES.get(action, []):
			var jb := InputEventJoypadButton.new()
			jb.button_index = b as JoyButton
			InputMap.action_add_event(action, jb)
		if JOY_EIXOS.has(action):
			var jm := InputEventJoypadMotion.new()
			jm.axis = JOY_EIXOS[action][0] as JoyAxis
			jm.axis_value = JOY_EIXOS[action][1]
			InputMap.action_add_event(action, jm)
	teclas_padrao()


# ------------------------------------------------------------ teclas (CONTROLES)
func teclas_padrao() -> void:
	teclas = {}
	for a: String in TECLAS_ACOES:
		teclas[a] = (TECLAS_PADRAO[a] as Array).duplicate()
	aplicar_teclas()


## Poe as teclas escolhidas (e as fixas) no InputMap; os eventos do controle ficam como estao.
func aplicar_teclas() -> void:
	for action: String in ACTIONS:
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				InputMap.action_erase_event(action, ev)
		var lista: Array = (TECLAS_FIXAS.get(action, []) as Array).duplicate()
		lista.append_array(teclas.get(action, []))
		if action == "confirm":
			lista.append_array(teclas.get("jump", []))
		for k: int in lista:
			if k == 0:
				continue
			var ev := InputEventKey.new()
			ev.physical_keycode = k as Key
			InputMap.action_add_event(action, ev)


## Troca a tecla da coluna 'col' de 'action' por 'key'. Se a tecla ja era de outra acao (ou da
## outra coluna), as duas trocam de lugar: nenhuma tecla faz duas coisas.
func definir_tecla(action: String, col: int, key: int) -> void:
	var antiga: int = teclas[action][col]
	for a: String in TECLAS_ACOES:
		for c in 2:
			if teclas[a][c] == key and not (a == action and c == col):
				teclas[a][c] = antiga
	teclas[action][col] = key
	aplicar_teclas()
	save_settings()


## Tecla fixa ou proibida de escolher (ESC cancela a escolha).
static func tecla_reservada(key: int) -> bool:
	return key == KEY_ESCAPE or key == KEY_NONE


## Nome curto da tecla para a tela (so letras que a fonte tem).
static func nome_tecla(key: int) -> String:
	match key:
		0:
			return "-"
		KEY_LEFT:
			return "SETA <"
		KEY_RIGHT:
			return "SETA >"
		KEY_UP:
			return "SETA CIMA"
		KEY_DOWN:
			return "SETA BAIXO"
		KEY_SPACE:
			return "ESPAÇO"
		KEY_ENTER, KEY_KP_ENTER:
			return "ENTER"
		KEY_SHIFT:
			return "SHIFT"
		KEY_CTRL:
			return "CTRL"
		KEY_ALT:
			return "ALT"
		KEY_TAB:
			return "TAB"
		KEY_BACKSPACE:
			return "APAGAR"
	var nome := OS.get_keycode_string(key as Key).to_upper()
	var ok := ""
	for ch in nome:
		ok += ch if PixelFont_tem(ch) else ""
	return ok if not ok.is_empty() else "TECLA %d" % key


static func PixelFont_tem(ch: String) -> bool:
	return ch == " " or (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9") or ch in ".,-+/*"


func _input_tecla(event: InputEvent) -> bool:
	if tecla_esperando.is_empty():
		return false
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return event is InputEventKey
	var code := int(key.physical_keycode)
	if code == KEY_ESCAPE:
		play_sfx("denied")
	elif not tecla_reservada(code):
		definir_tecla(tecla_esperando, tecla_coluna, code)
		play_sfx("confirm")
	tecla_esperando = ""
	_tecla_ate_quadro = Engine.get_physics_frames() + 2
	get_viewport().set_input_as_handled()
	return true


func _setup_buses() -> void:
	for bus_name: String in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


func play_sfx(sfx_name: String) -> void:
	if _sfx_players.is_empty():
		return
	var p := _sfx_players[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_players.size()
	p.stream = Sfx.get_stream(sfx_name)
	p.play()


func _update_pause() -> void:
	if is_inside_tree():
		get_tree().paused = transitioning or (in_level and game_state != "playing")


# ------------------------------------------------------------------- fases
func level_index(id: String) -> int:
	for i in levels.size():
		if levels[i]["id"] == id:
			return i
	return -1


func level_display_name(id: String) -> String:
	var i := level_index(id)
	return levels[i]["name"] if i >= 0 else id.to_upper()


## Proxima fase depois da atual ("" = era a ultima).
func next_level_id() -> String:
	var i := level_index(current_level_name)
	if i >= 0 and i + 1 < levels.size():
		return levels[i + 1]["id"]
	return ""


func is_level_unlocked(index: int) -> bool:
	return index < unlocked_count


# ---------------------------------------------------------------- utilidades
## Troca de cena com fade. Pausa tudo enquanto a tela esta escura.
func room_goto(room_name: String) -> void:
	if transitioning:
		return
	transitioning = true
	in_level = false
	level_started = false
	_update_pause()
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, FADE_TIME)
	await tw.finished
	get_tree().change_scene_to_file("res://scenes/%s.tscn" % room_name)
	await get_tree().scene_changed
	transitioning = false
	_update_pause()
	var tw_in := create_tween()
	tw_in.tween_property(_fade, "color:a", 0.0, FADE_TIME)


func _reset_run() -> void:
	player_lives = max_lives
	invulnerability_remaining = 0
	current_collectibles = 0
	total_score = 0
	level_history.clear()


func start_new_game() -> void:
	_reset_run()
	game_state = "cutscene"
	ui_selection = 0
	room_goto(INTRO_SCENE)


## Fim da cutscene inicial (ou pulou): comeca o tutorial.
func finish_intro() -> void:
	play_level(0)


## Comeca uma partida a partir da fase 'index' (selecao de fases / continuar).
func play_level(index: int) -> void:
	if index < 0 or index >= levels.size():
		return
	_reset_run()
	game_state = "playing"
	room_goto(levels[index]["id"])


## Continua da fase liberada mais adiante.
func continue_game() -> void:
	play_level(clampi(unlocked_count - 1, 0, levels.size() - 1))


func has_progress() -> bool:
	return unlocked_count > 1 or not best.is_empty()


## NOVO JOGO confirmado: apaga fases liberadas, recordes, flores e o "zerado" e comeca do zero.
func apagar_progresso() -> void:
	unlocked_count = 1
	best = {}
	zerado = false
	save_progress()


## Recomeca a fase atual (fim de jogo, pausa, "jogar novamente", F3).
## Vidas cheias se tinham acabado; um resultado ja registrado desta fase e descartado.
func restart_level() -> void:
	if current_level_name.is_empty():
		return
	if level_history.size() > 0 and level_history[-1]["level_name"] == current_level_name:
		level_history.pop_back()
		_recount_total_score()
	if player_lives <= 0:
		player_lives = max_lives
	invulnerability_remaining = 0
	game_state = "playing"
	room_goto(current_level_name)


func go_to_next_level() -> void:
	var next := next_level_id()
	if next.is_empty():
		go_to_menu()
		return
	invulnerability_remaining = 0
	game_state = "playing"
	room_goto(next)


## Cutscene final (o pato encontra a Pata no topo da torre).
func play_ending() -> void:
	game_state = "cutscene"
	ui_selection = 0
	room_goto(ENDING_SCENE)


## Fim da cutscene (ou pulou): creditos com "FIM" sobre o menu.
func finish_ending() -> void:
	if not zerado:
		zerado = true
		save_progress()
	credits_after_ending = true
	game_state = "credits"
	ui_selection = 0
	room_goto("menu")


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
	level_elapsed_seconds = 0.0
	air_ratio = 1.0
	show_air = false
	boss_visible = false
	keys = 0
	camera_limit = Rect2()
	camera_olhar = 0.0
	camera_soltar_quadros = 0
	camera_fechar_quadros = 0
	arena_chefe = null
	current_collectibles = 0
	has_checkpoint = false
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


func set_boss(label: String, hp: int, hp_max: int) -> void:
	boss_visible = true
	boss_label = label
	boss_hp = hp
	boss_max = hp_max


func clear_boss() -> void:
	boss_visible = false


func set_checkpoint(pos: Vector2) -> void:
	has_checkpoint = true
	checkpoint_pos = pos


func collect_flower() -> void:
	current_collectibles += 1


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
	_record_progress(level_score)

	level_started = false
	ui_selection = 0
	game_state = "complete"
	play_sfx("complete")


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


## Flores colhidas (o melhor de cada fase) e o total das fases ja jogadas: [colhidas, total].
func flores_colhidas() -> Vector2i:
	var out := Vector2i.ZERO
	for lv: Dictionary in levels:
		var reg: Dictionary = best.get(lv["id"], {})
		out.x += int(reg.get("flores", 0))
		out.y += int(reg.get("flores_total", 0))
	return out


## O que o pato entrega a Pata na cutscene final, pelas flores colhidas na aventura:
## 0 = nenhuma flor, 1 = uma flor so (poucas), 2 = buque pequeno (metade ou mais),
## 3 = buque grande (todas).
static func buque_nivel(colhidas: int, total: int) -> int:
	if colhidas <= 0 or total <= 0:
		return 0
	if colhidas >= total:
		return 3
	if colhidas * 2 >= total:
		return 2
	return 1


# ------------------------------------------------------------ progresso salvo
func _record_progress(score: int) -> void:
	if level_index(current_level_name) < 0:
		last_result_is_record = false  # laboratorio / cena fora de levels: nao salva nada
		return
	var prev: Dictionary = best.get(current_level_name, {})
	last_result_is_record = prev.is_empty() or score > int(prev.get("score", 0))
	if last_result_is_record:
		best[current_level_name] = {
			"score": score,
			"stars": stars_for(score),
			"time": level_elapsed_seconds,
		}
	# flores: o melhor de cada fase fica guardado a parte (vale para o buque da cutscene final)
	var reg: Dictionary = best.get(current_level_name, {})
	reg["flores"] = maxi(int(prev.get("flores", 0)), current_collectibles)
	reg["flores_total"] = total_collectibles
	best[current_level_name] = reg
	var i := level_index(current_level_name)
	if i >= 0:
		unlocked_count = clampi(maxi(unlocked_count, i + 2), 1, levels.size())
	save_progress()


func load_progress() -> void:
	unlocked_count = 1
	best = {}
	zerado = false
	var cfg := ConfigFile.new()
	if cfg.load(save_path) == OK:
		unlocked_count = clampi(int(cfg.get_value("progress", "unlocked", 1)), 1, levels.size())
		zerado = bool(cfg.get_value("progress", "zerado", false))
		var saved = cfg.get_value("progress", "best", {})
		if saved is Dictionary:
			best = saved


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked_count)
	cfg.set_value("progress", "best", best)
	cfg.set_value("progress", "zerado", zerado)
	cfg.save(save_path)


# ------------------------------------------------------------- configuracoes
func _load_settings() -> void:
	# Rodando pelo editor abre em janela; o jogo exportado abre em tela cheia.
	screen_mode = "windowed" if OS.has_feature("editor") else "fullscreen"
	var cfg := ConfigFile.new()
	if cfg.load(settings_path) == OK:
		# "volume" era o volume unico das versoes anteriores.
		var old_volume := int(cfg.get_value("audio", "volume", 8))
		music_volume = clampi(int(cfg.get_value("audio", "music", old_volume)), 0, 10)
		sfx_volume = clampi(int(cfg.get_value("audio", "sfx", old_volume)), 0, 10)
		screen_mode = str(cfg.get_value("display", "mode", screen_mode))
		resolution_index = clampi(int(cfg.get_value("display", "resolution", 2)), 0, 2)
		for a: String in TECLAS_ACOES:
			var v: Variant = cfg.get_value("teclas", a) if cfg.has_section_key("teclas", a) else null
			if v is Array and (v as Array).size() == 2:
				teclas[a] = [int(v[0]), int(v[1])]
		aplicar_teclas()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("display", "mode", screen_mode)
	cfg.set_value("display", "resolution", resolution_index)
	for a: String in TECLAS_ACOES:
		cfg.set_value("teclas", a, teclas[a])
	cfg.save(settings_path)


func _apply_bus_volume(bus_name: String, level: int) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_mute(idx, level == 0)
	if level > 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(level / 10.0))


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

	_apply_bus_volume("Music", music_volume)
	_apply_bus_volume("SFX", sfx_volume)

	match screen_mode:
		"fullscreen":
			pending_resize = false
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			# Tela cheia "sem borda" do sistema: alt-tab funciona no Windows.
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
func ui_rect(cy: int, w: int, h: int, label: String, extra: Dictionary = {}) -> Dictionary:
	var half_w := floori(w / 2.0)
	var half_h := floori(h / 2.0)
	var r := {
		"x1": 160 - half_w,
		"y1": cy - half_h,
		"x2": 160 + half_w,
		"y2": cy + half_h,
		"label": label,
	}
	r.merge(extra)
	return r


## Layout unico usado pelo Step (mouse/teclado) e pelo desenho (ui.gd), para nunca desalinhar.
## As acoes dos botoes sao escolhidas pelo texto (label), nao pela posicao.
func ui_layout() -> Array:
	match game_state:
		"main":
			# Instalacao nova: JOGAR, OPCOES, SAIR. Com progresso: CONTINUAR, NOVO JOGO (apaga
			# tudo, com confirmacao), OPCOES, SAIR. FASES so depois de zerar o jogo (ver a
			# cutscene final). Creditos ficam em OPCOES.
			var nomes: Array = ["OPÇÕES", "SAIR"]
			if has_progress():
				nomes = ["NOVO JOGO", "FASES", "OPÇÕES", "SAIR"] if zerado else ["NOVO JOGO", "OPÇÕES", "SAIR"]
			var out := [ui_rect(70, 164, 24, "CONTINUAR" if has_progress() else "JOGAR", {"big": true})]
			var passo := 18 if nomes.size() > 3 else 20
			for i in nomes.size():
				out.append(ui_rect(97 + i * passo, 112, 16, nomes[i]))
			return out
		"confirmar_novo":
			return [ui_rect(118, 70, 16, "NÃO"), ui_rect(138, 70, 16, "SIM")]
		"levels":
			var out := []
			# linhas compactas: cabem as 10 fases + o laboratorio acima do VOLTAR
			for i in levels.size():
				var label: String = levels[i]["name"] if is_level_unlocked(i) else "BLOQUEADA"
				out.append(ui_rect(35 + i * 12, 220, 11, label, {"level": i}))
			if OS.is_debug_build():
				out.append(ui_rect(35 + levels.size() * 12, 220, 11, "LABORATÓRIO",
					{"room": LAB_LEVEL}))
			out.append(ui_rect(169, 120, 12, "VOLTAR"))
			return out
		"credits":
			return [ui_rect(158, 120, 16, "VOLTAR")]
		"controls":
			var linhas := []
			for i in TECLAS_ACOES.size():
				linhas.append(ui_rect(38 + i * 13, 236, 12, TECLAS_NOMES[TECLAS_ACOES[i]],
					{"tecla": TECLAS_ACOES[i]}))
			linhas.append(ui_rect(134, 110, 12, "PADRÃO"))
			linhas.append(ui_rect(150, 110, 12, "VOLTAR"))
			return linhas
		"settings":
			return [ui_rect(46, 220, 14, "TELA"),
				ui_rect(62, 220, 14, "TAMANHO"),
				ui_rect(78, 220, 14, "MÚSICA"),
				ui_rect(94, 220, 14, "SONS"),
				ui_rect(112, 120, 14, "CONTROLES"),
				ui_rect(128, 120, 14, "CRÉDITOS"),
				ui_rect(146, 120, 14, "VOLTAR")]
		"pause":
			return [ui_rect(76, 150, 18, "CONTINUAR"),
				ui_rect(98, 150, 18, "RECOMEÇAR"),
				ui_rect(120, 150, 18, "OPÇÕES"),
				ui_rect(142, 150, 18, "MENU")]
		"complete":
			if not next_level_id().is_empty():
				return [ui_rect(128, 150, 16, "PRÓXIMA FASE"),
					ui_rect(146, 150, 16, "JOGAR DE NOVO"),
					ui_rect(164, 150, 16, "MENU")]
			if current_level_name == FINAL_LEVEL:
				return [ui_rect(128, 150, 16, "VER O FINAL"),
					ui_rect(146, 150, 16, "JOGAR DE NOVO"),
					ui_rect(164, 150, 16, "MENU")]
			return [ui_rect(137, 150, 18, "MENU"),
				ui_rect(158, 150, 18, "JOGAR DE NOVO")]
		"gameover":
			return [ui_rect(118, 150, 20, "TENTAR DE NOVO"),
				ui_rect(142, 150, 20, "MENU")]
	return []


# ----------------------------------------------------------- teclas de debug
func _input(event: InputEvent) -> void:
	if _input_tecla(event):
		return
	if not OS.is_debug_build() or not in_level or transitioning:
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

	if transitioning:
		return

	# CONTROLES esperando a tecla nova (ou a tecla acabou de chegar): o menu nao reage a ela
	if not tecla_esperando.is_empty() or Engine.get_physics_frames() <= _tecla_ate_quadro:
		_mouse_prev = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		return

	if in_level and level_started and game_state == "playing":
		level_elapsed_seconds += delta

	var esc := Input.is_action_just_pressed("pause")

	if in_level and game_state == "playing" and esc:
		pause_origin = "playing"
		ui_selection = 0
		game_state = "pause"
		return

	if esc and _handle_back():
		return

	# o mouse vem em pixels da tela do jogo (384x216); os botoes estao na grade de 320x180
	var mp := get_viewport().get_mouse_position() - UI_OFS
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
	var adjusting := game_state == "settings"

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
					if r.has("tecla"):  # coluna da tecla clicada (as caixas comecam em x 149 e 214)
						tecla_coluna = 0 if mp.x < 212.0 else 1
					# Nas linhas de ajuste, clicar na metade esquerda diminui e na direita aumenta.
					if adjusting and i < SETTINGS_ADJUST_ROWS:
						if mp.x < (r["x1"] + r["x2"]) / 2.0:
							left = true
						else:
							right = true
						action = -1

		if activate:
			if adjusting and ui_selection < SETTINGS_ADJUST_ROWS:
				right = true
			else:
				action = ui_selection

	# Bipe ao mudar a selecao (nao ao trocar de tela).
	if game_state == _prev_state and ui_selection != _prev_selection and rows > 0:
		play_sfx("select")
	_prev_state = game_state
	_prev_selection = ui_selection

	if game_state == "controls" and (left or right) and ui_selection < TECLAS_ACOES.size():
		if tecla_coluna != (1 if right else 0):
			tecla_coluna = 1 if right else 0
			play_sfx("select")

	if adjusting and (left or right) and ui_selection < SETTINGS_ADJUST_ROWS:
		_adjust_setting(ui_selection, 1 if right else -1)

	if action < 0:
		return
	var chosen: Dictionary = layout[action]
	if chosen.has("tecla"):
		play_sfx("confirm")
		tecla_esperando = chosen["tecla"]
		return
	if chosen.has("room"):
		play_sfx("confirm")
		_reset_run()
		game_state = "playing"
		room_goto(chosen["room"])
		return
	if chosen.has("level"):
		if is_level_unlocked(chosen["level"]):
			play_sfx("confirm")
			play_level(chosen["level"])
		else:
			play_sfx("denied")
		return
	play_sfx("confirm")
	_run_menu_action(chosen["label"])


## ESC / VOLTAR: sobe um nivel nos menus. Devolve true se tratou.
func _handle_back() -> bool:
	match game_state:
		"pause":
			game_state = "playing"
		"settings":
			game_state = "pause" if pause_origin == "pause" else "main"
			ui_selection = 2  # volta em cima de OPCOES
		"controls":
			game_state = "settings"
			ui_selection = 4
		"levels":
			game_state = "main"
			ui_selection = 2  # volta em cima de FASES
		"confirmar_novo":
			game_state = "main"
			ui_selection = 1  # volta em cima de NOVO JOGO
		"credits":
			if credits_after_ending:  # veio do fim da cutscene: volta ao menu principal
				credits_after_ending = false
				game_state = "main"
				ui_selection = 0
			else:  # veio de OPCOES
				game_state = "settings"
				ui_selection = 5
		"gameover", "complete":
			go_to_menu()
		_:
			return false
	return true


func _adjust_setting(row: int, dir: int) -> void:
	match row:
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
		1:
			resolution_index = (resolution_index + dir + 3) % 3
			if screen_mode != "fullscreen":
				apply_settings()
		2:
			music_volume = clampi(music_volume + dir, 0, 10)
			apply_settings()
		3:
			sfx_volume = clampi(sfx_volume + dir, 0, 10)
			apply_settings()
			play_sfx("flower")  # amostra do volume escolhido
	save_settings()


func _run_menu_action(label: String) -> void:
	match label:
		"CONTINUAR":
			if game_state == "pause":
				game_state = "playing"
			else:
				continue_game()
		"JOGAR":
			start_new_game()
		"NOVO JOGO":
			ui_selection = 0  # NAO ja selecionado: apagar tudo pede um aperto a mais
			game_state = "confirmar_novo"
		"SIM":
			if game_state == "confirmar_novo":
				apagar_progresso()
				start_new_game()
		"NÃO":
			_handle_back()
		"FASES":
			ui_selection = 0
			game_state = "levels"
		"CRÉDITOS":
			ui_selection = 0
			game_state = "credits"
		"OPÇÕES", "CONFIGURAÇÕES":
			pause_origin = "pause" if game_state == "pause" else "main"
			ui_selection = 0
			game_state = "settings"
		"CONTROLES":
			ui_selection = 0
			tecla_coluna = 0
			game_state = "controls"
		"PADRÃO":
			teclas_padrao()
			save_settings()
		"SAIR":
			get_tree().quit()
		"VOLTAR":
			_handle_back()
		"RECOMEÇAR", "JOGAR DE NOVO", "TENTAR DE NOVO":
			# Fim de jogo recomeca a fase com vidas cheias (decisao D3).
			restart_level()
		"MENU":
			go_to_menu()
		"PRÓXIMA FASE":
			go_to_next_level()
		"VER O FINAL":
			play_ending()
