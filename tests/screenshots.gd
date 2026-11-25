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


func _wait_state(n: Node, s: String) -> void:
	for i in 300:
		if not is_instance_valid(n) or n.state == s:
			return
		await frames(1)


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

	# Fase 3: arena do jacare gigante
	Game.game_state = "playing"
	Game.room_goto("fase3")
	await wait_ready()
	await frames(30)
	await shot("22g_fase3_inicio")
	p = get_tree().get_first_node_in_group("player")
	var boss := get_tree().current_scene.get_node("Entidades/JacareGigante")
	Game.debug_invincible = true
	p.position = Vector2(1072, 256)
	await frames(60)
	boss.position.x = 1010.0
	boss.force_state("aviso", 999)
	boss.position.y = boss._surface() + boss.DEEP
	await frames(20)
	await shot("22h_fase3_bolhas")
	boss._target_x = 1072.0
	boss.position.x = 1072.0
	boss._start_leap(p)
	await frames(14)
	await shot("22i_fase3_salto")
	p.position = Vector2(944, 256)
	boss.position.x = 1010.0
	boss.dir = -1
	boss.force_state("mordida_aviso", 999)
	await frames(50)
	await shot("22j_fase3_mordida")
	boss.force_state("dor", 999)
	await frames(10)
	await shot("22k_fase3_dor_de_dente")

	# Fase 4: torre por dentro, chave e gaviaozinho
	Game.game_state = "playing"
	Game.room_goto("fase4")
	await wait_ready()
	await frames(30)
	await shot("22l_fase4_inicio")
	p = get_tree().get_first_node_in_group("player")
	Game.keys = 1
	p.position = Vector2(232, 768)
	await frames(40)
	await shot("22m_fase4_porta_trancada")
	Game.keys = 0
	var g := get_tree().current_scene.get_node("Entidades/Gaviao1")
	g._cooldown = 0
	p.position = Vector2(450, 768)
	await _wait_state(g, "aviso")
	await shot("22n_fase4_gaviao_grito")
	await _wait_state(g, "rasante")
	await frames(14)
	await shot("22o_fase4_rasante")
	p.position = Vector2(440, 592)
	await frames(40)
	await shot("22p_fase4_caixa_placa")
	p.position = Vector2(120, 96)
	await frames(60)
	await shot("22q_fase4_sacada")

	# Fase 5: aguia e caixas
	Game.game_state = "playing"
	Game.room_goto("fase5")
	await wait_ready()
	await frames(30)
	await shot("22r_fase5_inicio")
	p = get_tree().get_first_node_in_group("player")
	var a := get_tree().current_scene.get_node("Entidades/Aguia1")
	p.position = Vector2(300, 768)
	a._cooldown = 0
	await _wait_state(a, "aviso")
	await frames(10)
	await shot("22s_fase5_aguia_grito")
	await _wait_state(a, "mergulho")
	await frames(8)
	await shot("22t_fase5_mergulho")
	await _wait_state(a, "presa")
	await frames(10)
	await shot("22u_fase5_bico_preso")
	p.position = Vector2(264, 592)
	await frames(40)
	await shot("22v_fase5_chave_ressalto")
	p.position = Vector2(392, 352)
	await frames(40)
	await shot("22w_fase5_caixa_ressalto")

	# Fases 6 a 8: vento e pedras que caem
	Game.game_state = "playing"
	Game.room_goto("fase6")
	await wait_ready()
	await frames(30)
	await shot("22x_fase6_inicio")
	p = get_tree().get_first_node_in_group("player")
	p.position = Vector2(240, 768)  # em cima da pedra 1
	await frames(15)
	await shot("22y_fase6_pedra_tremendo")
	var raj := get_tree().current_scene.get_node("Mecanicas/Rajada1")
	raj._t = 0
	p.position = Vector2(400, 768)
	await frames(20)
	await shot("22z_fase6_rajada")
	p.position = Vector2(584, 768)
	await frames(70)
	await shot("23a_fase6_corrente")

	Game.game_state = "playing"
	Game.room_goto("fase7")
	await wait_ready()
	await frames(30)
	await shot("23b_fase7_inicio")
	p = get_tree().get_first_node_in_group("player")
	p.position = Vector2(136, 640)
	await frames(40)
	await shot("23c_fase7_vento_a_favor")

	Game.game_state = "playing"
	Game.room_goto("fase8")
	await wait_ready()
	await frames(30)
	await shot("23d_fase8_inicio")
	p = get_tree().get_first_node_in_group("player")
	p.position = Vector2(440, 576)
	await frames(40)
	await shot("23e_fase8_porta_pedras")
	p.position = Vector2(200, 192)
	await frames(40)
	await shot("23f_fase8_vao_final")

	# Fase Final: chefe gaviao
	Game.game_state = "playing"
	Game.room_goto("fase_final")
	await wait_ready()
	await frames(30)
	await shot("23g_final_corredor")
	p = get_tree().get_first_node_in_group("player")
	var hawk := get_tree().current_scene.get_node("Entidades/Gaviao")
	p.position = Vector2(300, 160)
	await _wait_state(hawk, "aviso")
	await frames(10)
	await shot("23h_final_aviso_mergulho")
	await _wait_state(hawk, "mergulho")
	await frames(8)
	await shot("23i_final_mergulho")
	hawk.position = Vector2(222, 151)
	hawk.dir = 1
	hawk.force_state("carga_aviso", 20)
	p.position = Vector2(248, 112)
	await frames(10)
	await shot("23j_final_carga_aviso")
	await _wait_state(hawk, "investida")
	await frames(16)
	await shot("23k_final_investida")
	await _wait_state(hawk, "atordoado")
	await frames(10)
	await shot("23l_final_atordoado")
	hawk.hp = 6
	hawk._hurt_until = -1
	hawk.force_state("atordoado", 999)
	p.position = Vector2(hawk.position.x, 118)
	p.spdv = 2.0
	await frames(30)
	await shot("23m_final_etapa2")
	Game.debug_invincible = false

	# Cutscene final
	Game.play_ending()
	for i in 300:
		await frames(1)
		if not Game.transitioning and Game.room == "cutscene_final":
			break
	await frames(20)
	var cs := get_tree().current_scene
	for moment in [[2.5, "23n_cutscene_chegada"], [4.6, "23o_cutscene_pata_ve"],
			[8.5, "23p_cutscene_encontro"], [13.0, "23q_cutscene_por_do_sol"], [19.8, "23r_cutscene_fim"]]:
		cs.t = moment[0]
		await shot(moment[1])
	cs.t = 21.95
	for i in 300:
		await frames(1)
		if not Game.transitioning and Game.room == "menu":
			break
	await frames(20)
	await shot("23s_creditos_fim")
	Game.credits_after_ending = false

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
