extends Node
## Testes automaticos de jogabilidade (rodam sem janela).
##   godot --headless --path . res://tests/test_runner.tscn
## A cena so cria o "Driver" (um no filho da raiz, que sobrevive as trocas de cena)
## e ele joga a fase sozinho, conferindo cada correcao do PLANO.md.
## Codigo de saida = numero de falhas.

const BlockScene := preload("res://scenes/block.tscn")

var _fails := 0
var _passes := 0


func _ready() -> void:
	if get_parent() != get_tree().root or name != "Driver":
		var driver := Node.new()
		driver.name = "Driver"
		driver.set_script(get_script())
		driver.process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().root.add_child.call_deferred(driver)
		return
	_run.call_deferred()


# ------------------------------------------------------------------ apoio
func check(cond: bool, msg: String) -> void:
	if cond:
		_passes += 1
		print("  ok    ", msg)
	else:
		_fails += 1
		print("  FALHA ", msg)


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func press_key(key: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	ev.pressed = true
	Input.parse_input_event(ev)
	await frames(1)
	var up := InputEventKey.new()
	up.physical_keycode = key
	up.pressed = false
	Input.parse_input_event(up)
	await frames(1)


func player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


func raposa() -> Node2D:
	return get_tree().get_first_node_in_group("raposa")


func reset_player(pos: Vector2) -> void:
	var p := player()
	p.position = pos
	p.spdv = 0.0
	p.fall_start_y = -1.0
	p.player_state = "alive"
	p.invulnerability_timer = 0
	p.pulos = 2
	Game.invulnerability_remaining = 0
	Game.player_lives = Game.max_lives


func wait_level() -> void:
	for i in 120:
		await frames(1)
		if Game.in_level and player() != null:
			return


# ------------------------------------------------------------------ testes
func _run() -> void:
	print("== Jump Duck: testes")
	await frames(5)

	print("-- inicio do jogo (E1/E2)")
	Game.start_new_game()
	await wait_level()
	check(Game.in_level, "fase ativa depois de JOGAR")
	check(Game.current_level_name == "tutorial_fase1", "nome da fase vem da cena")
	check(Game.total_collectibles == 3, "3 flores contadas pela fase (veio %d)" % Game.total_collectibles)
	check(not get_tree().paused, "arvore nao pausada jogando")
	await frames(30)
	check(Game.level_elapsed_seconds > 0.3, "cronometro andando")

	print("-- pausa real (B3)")
	await press_key(KEY_ESCAPE)
	check(Game.game_state == "pause", "ESC pausa a fase")
	check(get_tree().paused, "arvore pausada")
	var p_pos := player().position
	var r_pos := raposa().position
	var t := Game.level_elapsed_seconds
	await frames(30)
	check(raposa().position == r_pos, "raposa parada na pausa")
	check(player().position == p_pos, "jogador parado na pausa")
	check(is_equal_approx(Game.level_elapsed_seconds, t), "cronometro parado na pausa")

	print("-- despausar com ESPACO nao pula (B1)")
	Game.ui_selection = 0  # CONTINUAR
	var y0 := player().position.y
	await press_key(KEY_SPACE)
	check(Game.game_state == "playing", "ESPACO em CONTINUAR volta ao jogo")
	check(not get_tree().paused, "arvore despausada")
	await frames(10)
	check(player().position.y == y0, "pato continua no chao (y %.1f -> %.1f)" % [y0, player().position.y])
	await press_key(KEY_SPACE)
	await frames(3)
	check(player().position.y < y0, "ESPACO depois disso pula normalmente")
	await frames(60)

	print("-- dano nao congela no ar e tem recuo (B2)")
	reset_player(Vector2(200, 560))
	await frames(1)
	var x_before := player().position.x
	player().take_damage(x_before - 10.0)
	check(Game.player_lives == Game.max_lives - 1, "perdeu 1 vida")
	await frames(15)
	check(player().position.x > x_before, "recuo para longe da fonte do dano")
	await frames(40)
	check(player().position.y == 624.0, "caiu ate o chao durante o dano (y=%.1f)" % player().position.y)
	check(player().player_state == "alive", "voltou ao estado normal")

	print("-- dano de queda e pulo duplo (B4)")
	reset_player(Vector2(100, 470))  # queda livre de 154 px
	await frames(90)
	check(Game.player_lives == Game.max_lives - 1, "queda de 154 px machuca")
	reset_player(Vector2(100, 494))  # cai 80, pulo duplo, cai mais ~80
	for i in 200:
		await frames(1)
		if player().position.y >= 574.0:
			break
	await press_key(KEY_SPACE)
	await frames(90)
	check(Game.player_lives == Game.max_lives, "pulo duplo no meio da queda evita o dano")

	print("-- colisao por tile com custom data 'solid' (E6)")
	var layer := TileMapLayer.new()
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(0, "solid")
	ts.set_custom_data_layer_type(0, TYPE_BOOL)
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/sprites/spr_objBPiso01.png")
	src.texture_region_size = Vector2i(16, 16)
	src.create_tile(Vector2i.ZERO)
	ts.add_source(src, 0)
	src.get_tile_data(Vector2i.ZERO, 0).set_custom_data("solid", true)
	layer.tile_set = ts
	layer.add_to_group("solid_tiles")
	get_tree().current_scene.add_child(layer)
	for cx in range(10, 16):
		layer.set_cell(Vector2i(cx, 25), 0, Vector2i.ZERO)  # chao em y = 400
	reset_player(Vector2(200, 370))
	await frames(60)
	check(player().position.y == 400.0, "pousa em cima do tile solido (y=%.1f)" % player().position.y)
	layer.queue_free()
	await frames(1)

	print("-- raposa respeita parede e beirada (B5)")
	var fox := raposa()
	reset_player(Vector2(29, 624))
	fox.position = Vector2(1440, 480)
	fox.start_x = 1440.0
	fox.dir = -1
	var wall := BlockScene.instantiate()
	wall.position = Vector2(1380, 480.0)  # parede de 1380 a 1396
	wall.tiles_w = 1
	wall.tiles_h = 2
	get_tree().current_scene.add_child(wall)
	var fox_min := 9999.0
	for i in 200:
		await frames(1)
		fox_min = minf(fox_min, fox.position.x)
	check(fox_min - 24.0 >= 1396.0 and fox_min - 24.0 <= 1398.0,
		"vira encostando na parede (menor x=%.1f)" % fox_min)
	check(fox.position.x > fox_min, "depois de virar volta a andar")
	wall.queue_free()
	fox.position = Vector2(992, 576)  # plataforma de 976 a 1008
	fox.start_x = 992.0
	var min_x := 9999.0
	var max_x := -9999.0
	for i in 300:
		await frames(1)
		min_x = minf(min_x, fox.position.x)
		max_x = maxf(max_x, fox.position.x)
	check(min_x >= 976.0 - 10.0 and max_x <= 1008.0 + 10.0 and max_x - min_x > 4.0,
		"nao sai da plataforma (%.1f..%.1f)" % [min_x, max_x])

	print("-- concluir a fase (E2/E3)")
	reset_player(Vector2(29, 624))
	for f in get_tree().get_nodes_in_group("flor"):
		player().position = f.position
		await frames(2)
	await frames(2)
	check(Game.game_state == "complete", "pegar as 3 flores conclui a fase")
	check(get_tree().paused, "tela de fase concluida pausa a fase")
	check(Game.level_history.size() == 1, "resultado registrado")
	var score: int = Game.level_history[0]["score"]
	check(score >= 50 and score <= 100, "pontuacao da fase entre 50 e 100 (veio %d)" % score)
	check(Game.ui_layout().size() == 2, "ultima fase: sem botao PROXIMA FASE")

	Game._run_menu_action("JOGAR NOVAMENTE")
	await frames(3)
	await wait_level()
	check(Game.in_level and Game.game_state == "playing", "JOGAR NOVAMENTE recomeca a fase")
	check(Game.level_history.size() == 0, "resultado anterior descartado")
	check(Game.current_collectibles == 0 and Game.total_collectibles == 3, "flores zeradas")

	print("-- morte e fim de jogo")
	Game.player_lives = 1
	player().invulnerability_timer = 0
	player().take_damage()
	await frames(DEATH_FRAMES)
	check(Game.game_state == "gameover", "sem vidas -> FIM DE JOGO")
	check(get_tree().paused, "fim de jogo pausa a fase")
	Game._run_menu_action("TENTAR NOVAMENTE")
	await frames(3)
	await wait_level()
	check(Game.player_lives == Game.max_lives and Game.game_state == "playing", "TENTAR NOVAMENTE com vidas cheias")

	print("-- teclas de debug")
	await press_key(KEY_F1)
	check(Game.debug_invincible, "F1 liga invencivel")
	var lives := Game.player_lives
	player().take_damage()
	check(Game.player_lives == lives, "invencivel nao perde vida")
	await press_key(KEY_F1)
	await press_key(KEY_F4)
	check(Game.game_state == "complete", "F4 conclui a fase")

	print("-- voltar ao menu")
	Game.go_to_menu()
	await frames(5)
	check(not Game.in_level and not get_tree().paused, "menu: fora da fase e sem pausa")
	check(Game.room == "menu", "cena do menu carregada")

	print("== %d ok, %d falha(s)" % [_passes, _fails])
	get_tree().quit(_fails)


const DEATH_FRAMES := 75
