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

	Game.best = {"tutorial_fase1": {"score": 87, "stars": 2, "time": 64.0}}
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
	await frames(20)
	await shot("07_fase_inicio")
	var p := get_tree().get_first_node_in_group("player")
	p.position = Vector2(930, 352)
	await frames(40)
	await shot("08_checkpoint")
	p.position = Vector2(1600, 480)
	await frames(40)
	await shot("09_saida")
	Game.ui_selection = 1
	Game.game_state = "pause"
	await shot("10_pausa")
	Game.game_state = "playing"
	await frames(2)
	Game.current_collectibles = 2
	Game.finish_level()
	await frames(5)
	await shot("11_fase_concluida")
	Game.game_state = "gameover"
	Game.ui_selection = 0
	await shot("12_fim_de_jogo")

	# Laboratorio de mecanicas (Fase 4)
	Game.game_state = "playing"
	Game.room_goto(Game.LAB_LEVEL)
	await wait_ready()
	await frames(20)
	await shot("13_lab_caixa_placa_porta")
	p = get_tree().get_first_node_in_group("player")
	var cx2 := get_tree().current_scene.get_node("Itens/Caixa2")
	p.position = Vector2(256, 336)
	p.xscale = 1
	await frames(5)
	cx2.pick_up(p)
	p.carrying = cx2
	await frames(20)
	await shot("14_lab_carregando")
	p.carrying = null
	cx2.drop()
	p.position = Vector2(470, 288)
	await frames(60)
	await shot("15_lab_cipo_plataforma_agua")
	Game.game_state = "main"
	Game.go_to_menu()
	await wait_ready()
	await frames(20)  # fim do fade
	Game.game_state = "levels"
	await shot("16_fases_com_laboratorio")
	Game.game_state = "controls"
	await shot("17_controles")

	for f in [SHOT_SAVE, SHOT_SETTINGS]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	get_tree().quit()
