extends Node
## Tira capturas (320x180) de cada tela do jogo para revisar o layout sem jogar.
##   godot --path . res://tests/screenshots.tscn
## (precisa de janela; nao funciona com --headless). Salva em user://screenshots/.

const SHOT_SAVE := "user://screenshot_save.cfg"
const SHOT_SETTINGS := "user://screenshot_settings.cfg"


func _ready() -> void:
	if get_parent() != get_tree().root or name != "Shooter":
		var driver := Node.new()
		driver.name = "Shooter"
		driver.set_script(get_script())
		driver.process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().root.add_child.call_deferred(driver)
		return
	_run.call_deferred()


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func shot(file_name: String) -> void:
	await frames(3)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("user://screenshots")
	img.save_png("user://screenshots/%s.png" % file_name)
	print("captura: ", file_name, " ", img.get_size())


func wait_ready() -> void:
	for i in 300:
		await frames(1)
		if not Game.transitioning and (Game.in_level or Game.room == "menu"):
			return


func _run() -> void:
	Game.save_path = SHOT_SAVE
	Game.settings_path = SHOT_SETTINGS
	Game.load_progress()
	Game.go_to_menu()
	await wait_ready()
	await frames(20)  # fim do fade
	await frames(10)
	await shot("01_menu_novo")

	Game.best = {"tutorial": {"score": 87, "stars": 2, "time": 64.0}}
	Game.unlocked_count = 2
	await shot("02_menu_com_progresso")
	Game.game_state = "levels"
	await shot("03_fases")
	Game.game_state = "credits"
	await shot("04_creditos")
	Game.pause_origin = "main"
	Game.game_state = "settings"
	Game.ui_selection = 2
	await shot("05_configuracoes")
	Game.game_state = "controls"
	Game.ui_selection = 0
	await shot("06_controles")

	Game.game_state = "main"
	Game.start_new_game()
	await wait_ready()
	await frames(30)
	await shot("07_tutorial_inicio")
	var p := get_tree().get_first_node_in_group("player")
	for spot in [[Vector2(360, 304), "08_tutorial_pulo_duplo"], [Vector2(740, 176), "09_tutorial_penhasco_cipo"],
			[Vector2(880, 304), "10_tutorial_feno"], [Vector2(1180, 224), "11_tutorial_raposa"],
			[Vector2(1660, 272), "12_tutorial_saida"]]:
		p.position = spot[0]
		await frames(45)
		await shot(spot[1])
	Game.ui_selection = 1
	Game.game_state = "pause"
	await shot("13_pausa")
	Game.game_state = "playing"
	await frames(2)
	Game.current_collectibles = 2
	Game.finish_level()
	await frames(5)
	await shot("14_fase_concluida")

	Game._run_menu_action("PRÓXIMA FASE")
	await wait_ready()
	await frames(30)
	await shot("15_fase1_inicio")
	p = get_tree().get_first_node_in_group("player")
	for spot in [[Vector2(300, 304), "16_fase1_raposa_buracos"], [Vector2(560, 304), "17_fase1_caixa_paredao"],
			[Vector2(780, 224), "18_fase1_placa_porta"], [Vector2(1060, 272), "19_fase1_arremesso"],
			[Vector2(1440, 192), "20_fase1_plataforma"], [Vector2(2080, 256), "21_fase1_saida"]]:
		p.position = spot[0]
		await frames(45)
		await shot(spot[1])
	Game.game_state = "gameover"
	Game.ui_selection = 0
	await shot("22_fim_de_jogo")

	# Fase 2: o lago
	Game.game_state = "playing"
	Game.room_goto("fase2")
	await wait_ready()
	await frames(30)
	await shot("22a_fase2_inicio")
	p = get_tree().get_first_node_in_group("player")
	p.position = Vector2(300, 310)
	await frames(40)
	await shot("22b_fase2_boiando")
	p.swim = "dive"
	p.position = Vector2(320, 360)
	p.air = 140
	await frames(3)
	await shot("22c_fase2_mergulhado")
	p.swim = "none"
	for spot in [[Vector2(480, 304), "22d_fase2_ilha_caixa"], [Vector2(620, 310), "22e_fase2_jacare"],
			[Vector2(1050, 310), "22f_fase2_parede_tunel"]]:
		p.position = spot[0]
		await frames(30)
		await shot(spot[1])

	# Laboratorio de mecanicas (Fase 4)
	Game.game_state = "playing"
	Game.room_goto(Game.LAB_LEVEL)
	await wait_ready()
	await frames(20)
	await shot("23_lab_caixa_placa_porta")
	p = get_tree().get_first_node_in_group("player")
	var cx2 := get_tree().current_scene.get_node("Itens/Caixa2")
	p.position = Vector2(256, 336)
	p.xscale = 1
	await frames(5)
	cx2.pick_up(p)
	p.carrying = cx2
	await frames(20)
	await shot("24_lab_carregando")
	p.carrying = null
	cx2.drop()
	p.position = Vector2(470, 288)
	await frames(60)
	await shot("25_lab_cipo_plataforma_agua")
	Game.game_state = "main"
	Game.go_to_menu()
	await wait_ready()
	await frames(20)  # fim do fade
	Game.game_state = "levels"
	await shot("26_fases")
	Game.game_state = "controls"
	await shot("27_controles")

	for f in [SHOT_SAVE, SHOT_SETTINGS]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	get_tree().quit()
