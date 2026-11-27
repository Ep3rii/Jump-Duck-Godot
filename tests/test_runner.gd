extends Node
## Testes automaticos de jogabilidade (rodam sem janela).
##   godot --headless --path . res://tests/test_runner.tscn
## A cena so cria o "Driver" (um no filho da raiz, que sobrevive as trocas de cena)
## e ele joga a fase sozinho, conferindo cada item do PLANO.md.
## Usa arquivos de save/configuracao proprios (nao mexe no save de quem joga).
## Codigo de saida = numero de falhas.

const BlockScene := preload("res://scenes/block.tscn")
const PerigoScene := preload("res://scenes/perigo.tscn")
const VidaScene := preload("res://scenes/vida.tscn")
const Sfx := preload("res://scripts/sfx.gd")
const Solids := preload("res://scripts/solids.gd")
const CaixaScene := preload("res://scenes/caixa.tscn")

const TEST_SAVE := "user://test_save.cfg"
const TEST_SETTINGS := "user://test_settings.cfg"
const DEATH_FRAMES := 75
const FIXTURE := "testes/fase_teste"

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


## Tecla de debug (Game._input). Input.parse_input_event so entrega o evento no proximo quadro
## de PROCESSO, e logo depois de carregar uma fase (ou com a maquina ocupada) o Godot roda
## varios quadros de fisica num quadro de processo so: esperar 1 quadro de fisica (press_key)
## nao garante que a tecla ja chegou. Aqui espera os quadros de processo.
func _tecla_debug(key: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	await get_tree().process_frame
	var up := InputEventKey.new()
	up.physical_keycode = key
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame
	await get_tree().process_frame


## Segura uma tecla por n frames.
func hold(key: Key, n: int) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	ev.pressed = true
	Input.parse_input_event(ev)
	await frames(n)
	var up := InputEventKey.new()
	up.physical_keycode = key
	up.pressed = false
	Input.parse_input_event(up)
	await frames(1)


func node(path: String) -> Node:
	return get_tree().current_scene.get_node(path)


func player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


func raposa() -> Node2D:
	return get_tree().get_first_node_in_group("raposa")


func reset_player(pos: Vector2) -> void:
	var p := player()
	p.position = pos
	p.spdh = 0.0
	p.spdv = 0.0
	p.fall_start_y = -1.0
	p.player_state = "alive"
	p.invulnerability_timer = 0
	p.pulos = 2
	Game.invulnerability_remaining = 0
	Game.player_lives = Game.max_lives


func wait_level() -> void:
	for i in 180:
		await frames(1)
		if Game.in_level and not Game.transitioning and player() != null:
			return


func wait_room(room_name: String) -> void:
	for i in 180:
		await frames(1)
		if Game.room == room_name and not Game.transitioning:
			return


func _delete(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


# ------------------------------------------------------------------ testes
func _run() -> void:
	print("== Jump Duck: testes")
	Game.save_path = TEST_SAVE
	Game.settings_path = TEST_SETTINGS
	_delete(TEST_SAVE)
	_delete(TEST_SETTINGS)
	# A maior parte dos testes usa a fase de testes (o tutorial antigo do GameMaker).
	var real_levels: Array = Game.levels
	Game.levels = [{"id": FIXTURE, "name": "TUTORIAL"}]
	Game.load_progress()
	await frames(5)

	print("-- sons sintetizados")
	var all_sfx := true
	for s: String in ["jump", "flower", "stomp", "hurt", "death", "checkpoint", "life",
			"complete", "select", "confirm", "denied", "key", "unlock", "screech", "swoop", "wind", "crack", "fall"]:
		all_sfx = all_sfx and Sfx.get_stream(s).data.size() > 1000
	check(all_sfx, "todos os efeitos geram audio")
	check(AudioServer.get_bus_index("Music") >= 0 and AudioServer.get_bus_index("SFX") >= 0,
		"buses Music e SFX criados")

	print("-- menu sem progresso")
	check(not Game.has_progress(), "save novo: sem progresso")
	var labels := Game.ui_layout().map(func(r): return r["label"])
	check(labels == ["JOGAR", "FASES", "OPÇÕES", "SAIR"],
		"menu principal: %s" % [labels])

	print("-- jogo novo: cutscene inicial e depois a primeira fase")
	Game.start_new_game()
	await frames(3)
	check(Game.transitioning and get_tree().paused, "fade: tudo pausado durante a troca")
	await wait_room("cutscene_inicial")
	await frames(5)
	var intro: Node2D = get_tree().current_scene
	check(Game.game_state == "cutscene" and not Game.in_level and intro.t > 0.0, "jogo novo abre a cutscene inicial")
	intro.t = 6.9
	await frames(2)
	check(intro.pata_pos().distance_to(intro.gaviao_pos() + intro.GARRAS) < 1.0 and intro.duck_anim() == "look_up",
		"o Rei Gaviao agarra a Pata e o pato leva um susto")
	intro.t = 12.0
	await frames(2)
	check(intro.duck_anim() == "coragem" and intro._duck.sprite_frames.get_frame_count("coragem") == 16,
		"o pato toma coragem (animacao de 16 quadros)")
	await press_key(KEY_ENTER)
	await wait_level()
	check(Game.in_level and not Game.transitioning, "fase ativa depois do fade")
	check(Game.current_level_name == FIXTURE, "nome da fase vem da cena")
	check(Game.total_collectibles == 3, "3 flores contadas pela fase (veio %d)" % Game.total_collectibles)
	check(not get_tree().paused, "arvore nao pausada jogando")
	await frames(30)
	check(Game.level_elapsed_seconds > 0.3, "cronometro andando")

	print("-- pausa real")
	await press_key(KEY_ESCAPE)
	check(Game.game_state == "pause", "ESC pausa a fase")
	check(get_tree().paused, "arvore pausada")
	check(Game.ui_layout().map(func(r): return r["label"]).has("RECOMEÇAR"),
		"pausa tem REINICIAR FASE")
	var p_pos := player().position
	var r_pos := raposa().position
	var t := Game.level_elapsed_seconds
	await frames(30)
	check(raposa().position == r_pos, "raposa parada na pausa")
	check(player().position == p_pos, "jogador parado na pausa")
	check(is_equal_approx(Game.level_elapsed_seconds, t), "cronometro parado na pausa")

	print("-- despausar com ESPACO nao pula")
	Game.ui_selection = 0  # CONTINUAR
	var y0 := player().position.y
	await press_key(KEY_SPACE)
	check(Game.game_state == "playing", "ESPACO em CONTINUAR volta ao jogo")
	await frames(10)
	check(player().position.y == y0, "pato continua no chao (y %.1f -> %.1f)" % [y0, player().position.y])
	await press_key(KEY_SPACE)
	await frames(3)
	check(player().position.y < y0, "ESPACO depois disso pula normalmente")
	await frames(60)

	print("-- dano nao congela no ar e tem recuo")
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

	print("-- dano de queda e pulo duplo")
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

	print("-- colisao por tile com custom data 'solid'")
	var layer := TileMapLayer.new()
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(0, "solid")
	ts.set_custom_data_layer_type(0, TYPE_BOOL)
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/sprites/arte/bloco.png")
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

	print("-- vida extra")
	reset_player(Vector2(29, 624))
	var vida := VidaScene.instantiate()
	vida.position = Vector2(200, 624)
	get_tree().current_scene.add_child(vida)
	player().position = Vector2(200, 624)
	await frames(3)
	check(is_instance_valid(vida) and not vida.is_queued_for_deletion(), "com vida cheia o coracao fica")
	player().position = Vector2(29, 624)
	Game.player_lives = 2
	await frames(2)
	player().position = Vector2(200, 624)
	await frames(3)
	check(Game.player_lives == 3, "coracao devolve 1 vida")
	check(not is_instance_valid(vida) or vida.is_queued_for_deletion(), "coracao some ao ser pego")

	print("-- checkpoint e perigo")
	reset_player(Vector2(29, 624))
	check(not Game.has_checkpoint, "comeca sem checkpoint")
	player().position = Vector2(960, 352)
	await frames(3)
	check(Game.has_checkpoint and Game.checkpoint_pos == Vector2(960, 352), "passar no checkpoint ativa")
	var hz := PerigoScene.instantiate()
	hz.position = Vector2(300, 624)  # 300..348 x 608..624, em cima do chao
	hz.tiles_w = 3
	get_tree().current_scene.add_child(hz)
	reset_player(Vector2(320, 624))
	await frames(3)
	check(Game.player_lives == Game.max_lives - 1, "perigo custa 1 vida")
	check(player().position.distance_to(Vector2(960, 352)) < 4.0,
		"perigo leva ao checkpoint (%s)" % [player().position])
	hz.queue_free()
	await frames(1)

	print("-- raposa: parede, beirada, encostar e pisao")
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
	check(fox_min - 8.0 >= 1396.0 and fox_min - 8.0 <= 1398.0,
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

	fox.position = Vector2(1440, 480)
	fox.start_x = 1440.0
	fox.dir = -1  # andando na direcao do pato
	reset_player(Vector2(1420, 480))
	await frames(40)
	check(Game.player_lives == Game.max_lives - 1, "encostar de lado machuca")
	reset_player(Vector2(fox.position.x, 440))
	player().spdv = 3.0
	await frames(8)
	check(not is_instance_valid(fox) or fox.is_queued_for_deletion(), "pisao derrota a raposa")
	check(player().spdv < 0.0 or player().position.y < 440.0, "pato quica depois do pisao")
	check(Game.player_lives == Game.max_lives, "pisao nao machuca")

	print("-- flores nao concluem; a saida conclui (D4)")
	reset_player(Vector2(29, 624))
	for f in get_tree().get_nodes_in_group("flor"):
		player().position = f.position
		await frames(2)
	await frames(2)
	check(Game.current_collectibles == 3, "3 flores coletadas")
	check(Game.game_state == "playing", "pegar as flores nao conclui a fase")
	player().position = Vector2(1640, 480)
	await frames(3)
	check(Game.game_state == "complete", "encostar na saida conclui a fase")
	check(get_tree().paused, "tela de fase concluida pausa a fase")
	check(Game.level_history.size() == 1, "resultado registrado")
	var score: int = Game.level_history[0]["score"]
	check(score >= 50 and score <= 100, "pontuacao da fase entre 50 e 100 (veio %d)" % score)
	check(Game.ui_layout().size() == 2, "ultima fase: sem botao PROXIMA FASE")

	print("-- progresso salvo")
	check(Game.last_result_is_record, "primeiro resultado e recorde")
	check(Game.best.has(FIXTURE) and Game.best[FIXTURE]["score"] == score,
		"recorde da fase guardado")
	check(FileAccess.file_exists(TEST_SAVE), "arquivo de save gravado")
	var saved_best: Dictionary = Game.best.duplicate(true)
	Game.best = {}
	Game.load_progress()
	check(Game.best == saved_best, "save carregado de volta igual")
	check(Game.has_progress(), "agora ha progresso")

	Game._run_menu_action("JOGAR DE NOVO")
	await wait_level()
	check(Game.in_level and Game.game_state == "playing", "JOGAR NOVAMENTE recomeca a fase")
	check(Game.level_history.size() == 0, "resultado anterior descartado da partida")
	check(Game.current_collectibles == 0 and Game.total_collectibles == 3, "flores zeradas")
	check(not Game.has_checkpoint, "checkpoint zerado ao recomecar")
	player().position = Vector2(1640, 480)
	await frames(3)
	check(not Game.last_result_is_record, "resultado pior nao e recorde")
	check(Game.best[FIXTURE]["score"] == score, "recorde mantido")
	Game._run_menu_action("JOGAR DE NOVO")
	await wait_level()

	print("-- morte e fim de jogo (D3)")
	Game.player_lives = 1
	player().invulnerability_timer = 0
	player().take_damage()
	await frames(DEATH_FRAMES)
	check(Game.game_state == "gameover", "sem vidas -> FIM DE JOGO")
	check(get_tree().paused, "fim de jogo pausa a fase")
	Game._run_menu_action("TENTAR DE NOVO")
	await wait_level()
	check(Game.current_level_name == FIXTURE, "TENTAR NOVAMENTE fica na mesma fase")
	check(Game.player_lives == Game.max_lives and Game.game_state == "playing", "com vidas cheias")

	print("-- teclas de debug")
	await _tecla_debug(KEY_F1)
	check(Game.debug_invincible, "F1 liga invencivel")
	var lives := Game.player_lives
	player().take_damage()
	check(Game.player_lives == lives, "invencivel nao perde vida")
	await _tecla_debug(KEY_F1)
	check(not Game.debug_invincible, "F1 de novo desliga")
	await _tecla_debug(KEY_F4)
	check(Game.game_state == "complete", "F4 conclui a fase")

	await _test_mechanics()
	await _test_arena()
	await _test_toque()
	await _test_olhar()
	await _test_fazenda()
	await _test_teclas()
	await _test_flores_no_chao()

	print("-- menus")
	Game.go_to_menu()
	await wait_room("menu")
	check(not Game.in_level and not get_tree().paused, "menu: fora da fase e sem pausa")
	labels = Game.ui_layout().map(func(r): return r["label"])
	check(labels == ["CONTINUAR", "FASES", "OPÇÕES", "SAIR"], "com progresso: CONTINUAR no lugar de JOGAR (%s)" % [labels])
	Game._run_menu_action("FASES")
	check(Game.game_state == "levels", "FASES abre a selecao")
	var lv: Array = Game.ui_layout()
	var extra := 1 if OS.is_debug_build() else 0  # LABORATÓRIO
	check(lv.size() == Game.levels.size() + 1 + extra and lv[0]["label"] == "TUTORIAL",
		"lista de fases (+ laboratorio em debug) + VOLTAR")
	Game._handle_back()
	check(Game.game_state == "main", "ESC na selecao volta ao menu")
	Game._run_menu_action("OPÇÕES")
	check(Game.ui_layout().map(func(r): return r["label"]) == ["TELA", "TAMANHO", "MÚSICA", "SONS",
		"CONTROLES", "CRÉDITOS", "VOLTAR"], "OPÇÕES: ajustes, CONTROLES, CRÉDITOS e VOLTAR")
	Game._run_menu_action("CONTROLES")
	check(Game.game_state == "controls", "CONTROLES abre pelas configuracoes")
	Game._handle_back()
	check(Game.game_state == "settings" and Game.ui_selection == 4, "ESC em controles volta as configuracoes")
	var music_before := Game.music_volume
	Game._adjust_setting(2, -1)
	check(Game.music_volume == music_before - 1, "volume da musica ajustavel")
	check(Game.sfx_volume == 8, "volume dos efeitos separado")
	Game._run_menu_action("CRÉDITOS")
	check(Game.game_state == "credits", "CRÉDITOS abre pelas opcoes")
	Game._handle_back()
	check(Game.game_state == "settings" and Game.ui_selection == 5, "ESC nos creditos volta as opcoes")
	Game._handle_back()
	check(Game.game_state == "main", "ESC nas opcoes volta ao menu")
	Game._run_menu_action("CONTINUAR")
	await wait_level()
	check(Game.in_level and Game.current_level_name == FIXTURE, "CONTINUAR entra na fase")
	Game.go_to_menu()
	await wait_room("menu")

	# Fases de verdade (tutorial e fase 1), com save zerado.
	Game.levels = real_levels
	_delete(TEST_SAVE)
	Game.load_progress()
	await _test_levels()

	_delete(TEST_SAVE)
	_delete(TEST_SETTINGS)
	print("== %d ok, %d falha(s)" % [_passes, _fails])
	get_tree().quit(_fails)


# -------------------------------------------------- fases do jogo
func key_event(key: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	ev.pressed = pressed
	Input.parse_input_event(ev)


## Joga n frames segurando 'hold' e dando toques em 'taps' ({frame: tecla}).
func play(n: int, hold_keys: Array = [], taps := {}) -> void:
	for k in hold_keys:
		key_event(k, true)
	for i in n:
		if taps.has(i):
			key_event(taps[i], true)
		await frames(1)
		if taps.has(i):
			key_event(taps[i], false)
	for k in hold_keys:
		key_event(k, false)
	await frames(2)


## Corre para a direita dando pulo duplo (2 toques de ESPACO).
func double_jump_right(n := 70) -> void:
	await play(n, [KEY_RIGHT], {2: KEY_SPACE, 18: KEY_SPACE})


func _test_levels() -> void:
	print("-- tutorial (fazenda)")
	Game.play_level(0)
	await wait_level()
	check(Game.current_level_name == "tutorial", "JOGAR comeca pelo tutorial")
	check(Game.total_collectibles == 3, "tutorial tem 3 flores (veio %d)" % Game.total_collectibles)
	var placas := get_tree().get_nodes_in_group("dica")
	check(placas.size() >= 1 and placas.size() <= 3, "poucas placas no tutorial (%d)" % placas.size())
	var de_controle := placas.filter(func(d): return ["ESPAÇO", "SETAS", "APERTE", "PULE", "X OU J"].any(
		func(w): return w in d.texto))
	check(de_controle.is_empty(), "placas contam a historia, nao os controles")

	print("-- cenario na escala do pato, parallax e luz (ceu aberto)")
	var spr = load("res://scripts/sprites.gd")
	for peca in ["cenario/arvore_copa", "cenario/arvore_tronco", "cenario/arvore_jovem_copa",
			"cenario/arbusto", "cenario/cerca", "cenario/celeiro", "cenario/moinho_corpo",
			"cenario/moinho_pas", "fundo/montanhas", "fundo/colinas_longe", "fundo/colinas_perto",
			"fundo/torre_longe", "fundo/torre_media", "fundo/torre_perto", "fundo/parede",
			"fundo/janela", "fundo/tocha", "fundo/coluna", "fundo/sol", "fundo/lua"]:
		var tex: Texture2D = spr.art(peca)
		check(tex != null and tex.get_width() > 0 and tex.get_height() > 0,
			"%s existe (16x16, 1 pixel do arquivo = 1 pixel do jogo)" % peca)
	# o pato e pequeno e o cenario e grande: alturas em "patos" (16 px)
	check(spr.art_size("cenario/arvore_copa").y >= 16.0 * 6.0, "arvore tem 6 patos ou mais de altura")
	check(spr.art_size("cenario/celeiro").y >= 16.0 * 6.0, "celeiro tem 6 patos ou mais de altura")
	check(spr.art_size("cenario/moinho_corpo").y >= 16.0 * 7.0, "moinho tem 7 patos ou mais de altura")
	check(spr.art_size("cenario/cerca", 3) == Vector2(16, 24), "cerca: 1 bloco de largura e 1,5 pato de altura")
	var par0: Node = node("Parallax")
	check(par0.hora == 0 and par0.cenario == 0, "tutorial: manha, ceu aberto")
	check(node("Sombras") != null and node("Luz") != null, "fase cria as sombras e a luz")
	check(node("Luz").ambiente() == Color.WHITE and not node("Luz").get_child(0).visible,
		"de dia a luz ambiente e branca e a pelicula fica desligada")
	check(not par0.usa_luzes() and par0.luzes().is_empty(), "ao ar livre nao ha fontes de luz")
	check(player().is_in_group("sombra"), "o pato faz sombra")
	var som: Node2D = node("Sombras")
	som._snap = load("res://scripts/solids.gd").snapshot(get_tree())
	var chao_y: float = som.chao_abaixo(player().position.x, player().position.y - 2.0, [player()])
	check(absf(chao_y - player().position.y) <= 1.0, "sombra do pato cai no chao embaixo dele (y %.0f)" % chao_y)
	check(som.chao_abaixo(player().position.x, player().position.y - 300.0, []) < 0.0,
		"muito alto nao ha sombra")
	var decos := get_tree().get_nodes_in_group("sombra_cenario")
	check(decos.size() >= 4, "arvores, moinho e arbustos fazem sombra no chao (%d)" % decos.size())
	# o celeiro do tutorial e de fundo (parallax), pontual, num trecho limpo da fase
	check(get_tree().current_scene.get_node_or_null("Decoracao/Celeiro") == null,"tutorial sem celeiro no plano do jogo")
	var cel: Array = par0.celeiro_lugar()
	check(cel.size() == 2 and cel[0] > 0.0 and cel[0] < float(Game.room_width),
		"tutorial ganha o celeiro de fundo no parallax (%s)" % [cel])
	check(par0._celeiro_na_arena(500.0, 100.0, [[550.0, 700.0]])
		and not par0._celeiro_na_arena(300.0, 100.0, [[550.0, 700.0]]),
		"celeiro de fundo nunca aparece com a camera presa na arena do chefe")
	var faixa: Rect2 = node("Decoracao/Moinho").sombra_chao()
	check(faixa.size.x > 40.0 and faixa.get_center().x > node("Decoracao/Moinho").position.x,
		"sombra do moinho cai para a direita (luz da esquerda)")
	# as camadas de longe andam mais devagar que as de perto
	check(par0.MONTANHAS[1] < par0.COLINAS_LONGE[1] and par0.COLINAS_LONGE[1] < par0.COLINAS_PERTO[1]
		and par0.COLINAS_PERTO[1] < 1.0, "parallax: montanhas < colinas de longe < colinas de perto < mundo")
	var base_baixo: float = par0._layer_base(144.0, 216.0, 0.3, 54.0)
	var base_alto: float = par0._layer_base(44.0, 216.0, 0.3, 54.0)
	check(base_alto - 44.0 > base_baixo - 144.0, "camera sobe: a camada desce na tela (parallax vertical)")

	print("-- tileset de grama novo (auto-tile com variacoes)")
	var terreno: TileMapLayer = node("Terreno")
	var used := {}
	for c in terreno.get_used_cells():
		var a := terreno.get_cell_atlas_coords(c)
		used[a.y * 4 + a.x] = true
	check(used.has(5) and (used.has(16) or used.has(17) or used.has(18) or used.has(19)),
		"topos com variacoes (%s)" % [used.keys()])
	check(used.has(20) or used.has(21) or used.has(22) or used.has(23), "terra com variacoes")
	check(used.has(11) or used.has(24), "canto interno no pe dos degraus")

	print("-- arte nova do pato (parado, pulo: subida, apice, queda)")
	reset_player(Vector2(150, 304))
	await frames(5)
	var art: AnimatedSprite2D = player().get_node("Arte")
	check(art.visible and art.animation == "idle", "parado: arte nova")
	var anims := {}
	key_event(KEY_SPACE, true)
	for i in 70:
		await frames(1)
		if i == 2:
			key_event(KEY_SPACE, false)
		anims[player()._anim] = art.visible
	check(anims.has("jump") and anims.has("apex") and anims.has("fall"),
		"um pulo passa por subida, apice e queda (%s)" % [anims.keys()])
	check(anims.values().all(func(v): return v), "todas com a arte nova")
	reset_player(Vector2(150, 304))
	await frames(5)
	player().take_damage(140.0)
	await frames(2)
	check(art.visible and art.animation == "hurt", "dano: arte nova")
	await frames(40)
	reset_player(Vector2(150, 304))
	reset_player(Vector2(150, 304))
	await frames(2)
	var dica2: Node = node("Dicas/Dica1")
	await frames(20)
	check(dica2.is_showing(), "placa mostra a dica com o pato perto")

	# muro de 2 tiles: um pulo basta
	reset_player(Vector2(290, 304))
	await play(45, [KEY_RIGHT], {2: KEY_SPACE})
	check(player().position.x > 352.0, "pulo simples passa o muro de 2 tiles (x=%.0f)" % player().position.x)

	# muro de 3 tiles: pulo simples nao passa, pulo duplo sim
	reset_player(Vector2(380, 304))
	await play(60, [KEY_RIGHT], {2: KEY_SPACE})
	check(player().position.x < 416.0, "pulo simples nao sobe 3 tiles (x=%.0f)" % player().position.x)
	reset_player(Vector2(380, 304))
	await double_jump_right(60)
	check(player().position.y == 256.0 and player().position.x > 416.0,
		"pulo duplo sobe 3 tiles (%s)" % [player().position])

	# penhasco: pular machuca, descer pelo cipo nao
	reset_player(Vector2(760, 176))
	await play(80, [KEY_RIGHT])
	check(Game.player_lives == Game.max_lives - 1, "pular do penhasco machuca")
	reset_player(Vector2(766, 176))
	await play(10, [KEY_DOWN])
	check(player().climbing, "BAIXO na beira agarra o cipo")
	await play(140, [KEY_DOWN])
	await frames(10)
	check(player().position.y == 304.0 and Game.player_lives == Game.max_lives,
		"desce o cipo ate o chao sem dano (y=%.0f)" % player().position.y)

	# paredao de 5 tiles: so com o feno
	var feno: Node2D = node("Itens/Feno1")
	reset_player(Vector2(950, 304))
	await double_jump_right(70)
	check(player().position.y > 230.0, "sem o feno, pulo duplo nao sobe o paredao (y=%.0f)" % player().position.y)
	reset_player(Vector2(836, 304))
	await play(160, [KEY_RIGHT])
	check(absf(feno.position.x - 968.0) < 1.0, "feno empurrado ate o paredao (x=%.0f)" % feno.position.x)
	reset_player(Vector2(968, 288))  # em cima do feno
	await frames(2)
	await double_jump_right(70)
	check(player().position.y == 224.0 and player().position.x > 976.0,
		"com o feno, sobe o paredao (%s)" % [player().position])

	# saida: conclui, salva e libera a fase 1
	check(is_instance_valid(node("Entidades/Raposa1")), "raposa no fim do tutorial")
	player().position = Vector2(1704, 272)
	await frames(3)
	check(Game.game_state == "complete", "saida conclui o tutorial")
	check(Game.unlocked_count == 2 and Game.best.has("tutorial"), "fase 1 liberada e recorde salvo")
	check(Game.ui_layout()[0]["label"] == "PRÓXIMA FASE", "tela de conclusao oferece PRÓXIMA FASE")
	Game._run_menu_action("PRÓXIMA FASE")
	await wait_level()

	print("-- fase 1 (caminho ate a torre)")
	check(Game.current_level_name == "fase1" and Game.total_collectibles == 4, "fase 1 carregada com 4 flores")
	var par: Node = node("Parallax")
	check(par.mostrar_torre, "torre aparece ao fundo")
	check(par.hora == 1 and par.torre_distancia == 0, "fase 1: dia claro, torre longe")

	# buraco sem fundo: perde vida e volta ao inicio
	reset_player(Vector2(256, 304))
	await play(60, [KEY_RIGHT])
	await frames(60)
	check(Game.player_lives == Game.max_lives - 1 and player().position.x < 100.0,
		"cair no buraco custa 1 vida e volta ao inicio")

	# caixa 1: empurrada do ressalto, cai no chao; paredao so com ela
	var c1: Node2D = node("Itens/Caixa1")
	reset_player(Vector2(500, 288))
	await play(60, [KEY_RIGHT])
	await frames(30)
	check(c1.position.y == 304.0 and c1.position.x > 544.0, "caixa cai do ressalto (%s)" % [c1.position])
	reset_player(Vector2(500, 288))
	await double_jump_right(80)
	check(player().position.y > 230.0, "do ressalto nao alcanca o planalto (y=%.0f)" % player().position.y)
	c1.position = Vector2(632, 304)
	reset_player(Vector2(632, 288))
	await frames(2)
	await double_jump_right(70)
	check(player().position.y == 224.0, "com a caixa no pe do paredao, sobe (y=%.0f)" % player().position.y)

	# porta de 6 tiles: nem pulo duplo nem caixa+pulo duplo passam; a placa abre
	var porta: Node2D = node("Mecanicas/Porta1")
	reset_player(Vector2(840, 224))
	await double_jump_right(70)
	check(player().position.x < 864.0, "porta alta nao se pula (x=%.0f)" % player().position.x)
	var c2: Node2D = node("Itens/Caixa2")
	c2.position = Vector2(856, 224)
	reset_player(Vector2(856, 208))
	await frames(2)
	await double_jump_right(70)
	check(player().position.x < 864.0, "nem de cima da caixa (x=%.0f)" % player().position.x)
	c2.position = Vector2(808, 224)  # em cima da placa (800..816)
	reset_player(Vector2(700, 224))
	await frames(5)
	check(porta.is_open, "caixa na placa abre a porta")

	# raposa 2 guarda o patamar: arremessar a caixa 3
	var fox2: Node2D = node("Entidades/Raposa2")
	var c3: Node2D = node("Itens/Caixa3")
	c3.position = Vector2(1060, 272)
	reset_player(Vector2(1044, 272))
	player().xscale = 1
	fox2.position = Vector2(1150, 256)
	fox2.start_x = 1150.0
	await frames(2)
	await press_key(KEY_X)
	check(player().carrying == c3, "pega a caixa 3")
	reset_player(Vector2(1092, 272))
	player().carrying = c3
	player().xscale = 1
	fox2.position = Vector2(1150, 256)
	await press_key(KEY_X)
	for i in 60:
		await frames(1)
		if not is_instance_valid(fox2) or fox2.is_queued_for_deletion():
			break
	check(not is_instance_valid(fox2) or fox2.is_queued_for_deletion(), "caixa arremessada derrota a raposa do patamar")
	c3.position = Vector2(1000, 272)  # tira a caixa do caminho
	reset_player(Vector2(1100, 272))
	await double_jump_right(70)
	check(player().position.y > 200.0, "do chao baixo nao alcanca o alto (y=%.0f)" % player().position.y)
	reset_player(Vector2(1176, 256))
	await double_jump_right(70)
	check(player().position.y == 192.0, "do patamar alcanca o alto (y=%.0f)" % player().position.y)

	# plataforma movel atravessa o buraco largo
	var plat: Node2D = node("Mecanicas/PlataformaMovel")
	for i in 600:
		await frames(1)
		if plat._t == 0.0 and plat._wait > 0:
			break
	reset_player(Vector2(plat.position.x + 24.0, 192))
	for i in 600:
		await frames(1)
		if plat._t == 1.0:
			break
	await play(40, [KEY_RIGHT])
	await frames(20)
	check(player().position.x > 1616.0 and player().position.y == 192.0,
		"plataforma leva ate o outro lado (%s)" % [player().position])

	# saida: ultima fase, sem PROXIMA FASE
	player().position = Vector2(2152, 256)
	await frames(3)
	check(Game.game_state == "complete" and Game.best.has("fase1"), "saida conclui a fase 1 e salva")
	check(Game.ui_layout()[0]["label"] == "PRÓXIMA FASE", "fase 1 leva a fase 2")
	Game._run_menu_action("PRÓXIMA FASE")
	await wait_level()
	await _test_fase2()
	Game.go_to_menu()
	await wait_room("menu")


func _test_fase2() -> void:
	print("-- fase 2 (lago)")
	check(Game.current_level_name == "fase2" and Game.total_collectibles == 4, "fase 2 carregada com 4 flores")
	var j1: Node2D = node("Entidades/Jacare1")
	var j2: Node2D = node("Entidades/Jacare2")
	# jacares fora do caminho enquanto testa o nado
	for j in [j1, j2]:
		j.set_physics_process(false)
		j.position = Vector2(-500, 0)

	# boiar: cair de 100 px na agua nao machuca e o pato fica na linha d'agua
	reset_player(Vector2(300, 200))
	await frames(90)
	check(player().swim == "surface" and absf(player().position.y - 310.0) < 0.6,
		"cai na agua e boia (y=%.1f, %s)" % [player().position.y, player().swim])
	check(Game.player_lives == Game.max_lives, "cair na agua nao machuca")

	# mergulhar, gastar folego, voltar e respirar
	await play(40, [KEY_DOWN])
	check(player().swim == "dive" and player().position.y > 330.0, "BAIXO mergulha (y=%.0f)" % player().position.y)
	check(player().air < player().AIR_MAX and Game.show_air, "folego gasta mergulhado e aparece no HUD")
	await frames(120)
	check(player().swim == "surface", "sem apertar nada volta a superficie")
	await frames(100)
	check(player().air == player().AIR_MAX, "na superficie o folego volta")

	# flor no fundo do lago
	reset_player(Vector2(328, 310))
	var before := Game.current_collectibles
	await play(80, [KEY_DOWN])
	check(Game.current_collectibles == before + 1, "mergulhando pega a flor do fundo")
	await frames(120)

	# sem folego: perde 1 coracao e volta a superficie
	reset_player(Vector2(250, 310))
	await play(10, [KEY_DOWN])
	player().air = 8
	await play(20, [KEY_DOWN])
	check(Game.player_lives == Game.max_lives - 1, "sem folego perde 1 coracao")
	check(player().swim == "surface" and player().air == player().AIR_MAX, "e volta a superficie com folego")
	await frames(130)

	# sair da agua pulando para a margem
	reset_player(Vector2(220, 310))
	await play(40, [KEY_LEFT], {2: KEY_SPACE})
	check(player().swim == "none" and player().position.y == 304.0 and player().position.x < 208.0,
		"ESPACO sai da agua para a margem (%s)" % [player().position])

	# caixa boia e vira degrau para o patamar
	var cx: Node2D = node("Itens/Caixa1")
	reset_player(Vector2(484, 304))
	await play(70, [KEY_RIGHT])
	await frames(60)
	check(absf(cx.position.y - 308.0) < 0.6 and cx.is_in_group("solid"), "caixa empurrada para o lago boia (y=%.1f)" % cx.position.y)
	reset_player(Vector2(cx.position.x - 15.0, 310))
	await play(260, [KEY_RIGHT])
	check(cx.position.x > 780.0, "nadando empurra a caixa pelo lago (x=%.0f)" % cx.position.x)
	reset_player(Vector2(796, 310))
	cx.position = Vector2(-300, 308)  # tira a caixa para testar sem ela
	await frames(2)
	await double_jump_right(70)
	check(player().position.y > 245.0, "da agua, sem caixa, nao alcanca o patamar (y=%.0f)" % player().position.y)
	cx.position = Vector2(808, 308)
	await frames(10)
	reset_player(Vector2(808, 292))
	await frames(2)
	await double_jump_right(70)
	check(player().position.y == 240.0, "de cima da caixa boiando alcanca o patamar (y=%.0f)" % player().position.y)

	# parede do lago C: so mergulhando
	reset_player(Vector2(1060, 310))
	await play(60, [KEY_RIGHT])
	check(player().position.x < 1082.0, "parede bloqueia na superficie (x=%.0f)" % player().position.x)
	await play(150, [KEY_DOWN, KEY_RIGHT])
	await frames(60)
	check(player().position.x > 1120.0, "mergulhando passa por baixo da parede (x=%.0f)" % player().position.x)

	# jacare: pisao na superficie derrota; mergulhado nao pode ser pisado; encostar morde
	j1.state = "surface"
	j1.position = Vector2(664, j1._target_y())
	j1.set_physics_process(true)
	await frames(3)
	check(j1.stompable, "jacare na superficie pode ser pisado")
	reset_player(Vector2(j1.position.x, 270))
	player().spdv = 3.0
	await frames(10)
	check(not is_instance_valid(j1) or j1.is_queued_for_deletion(), "pisao derrota o jacare")
	check(Game.player_lives == Game.max_lives, "pisao no jacare nao machuca")
	j2.position = Vector2(1208, 310)
	j2.state = "dive"
	j2._timer = 300
	j2.velocidade = 0.0
	j2.set_physics_process(true)
	await frames(60)
	check(not j2.stompable, "jacare mergulhado nao pode ser pisado")
	j2.state = "surface"
	await frames(60)
	reset_player(Vector2(1194, 310))
	await frames(10)
	check(Game.player_lives == Game.max_lives - 1, "encostar no jacare machuca")

	player().position = Vector2(1704, 304)
	await frames(3)
	check(Game.game_state == "complete" and Game.best.has("fase2"), "saida conclui a fase 2 e salva")
	check(Game.ui_layout()[0]["label"] == "PRÓXIMA FASE", "fase 2 leva a fase 3")
	Game._run_menu_action("PRÓXIMA FASE")
	await wait_level()
	await _test_fase3()


func _test_fase3() -> void:
	print("-- fase 3 (mini-chefe jacare)")
	check(Game.current_level_name == "fase3" and Game.total_collectibles == 4, "fase 3 carregada com 4 flores")
	check(node("Parallax").hora == 3 and node("Parallax").torre_distancia == 2, "fase 3: entardecer, torre perto")
	check(not node("Parallax").mostrar_celeiro and node("Parallax").celeiro_lugar().is_empty(),
		"pantano do jacare sem celeiro de fundo (ele boiaria atras da agua)")
	check(node("Luz").ambiente() != Color.WHITE and node("Luz").get_child(0).visible,
		"entardecer: a cena ganha o tom da hora")
	var boss: Node2D = node("Entidades/JacareGigante")
	var arena: Node2D = node("Mecanicas/ArenaChefe")
	for j in [node("Entidades/Jacare1"), node("Entidades/Jacare2")]:
		j.set_physics_process(false)
		j.position = Vector2(-500, 0)
	await frames(5)
	check(arena != null and arena.tipo_portao == "fazenda" and arena._entrada.size() == 1 and arena._saida.size() == 1,
		"arena do jacare com portoes de barranco na entrada e na saida")
	check(arena.retangulo.size.x >= 384.0 and arena.retangulo.size.y >= 216.0
		and arena.retangulo.end.y == 416.0, "arena do tamanho da tela, encostada no fundo da sala")
	# como a do gaviao: a arena inteira cabe numa tela so (camera parada) e e simetrica
	var meio: float = arena.retangulo.get_center().x
	check(arena.retangulo.size.x == 384.0, "arena do jacare cabe inteira na tela (camera parada)")
	check(is_equal_approx(arena.portoes_entrada[0].x + 8.0 - meio, meio - (arena.portoes_saida[0].x + 8.0))
		and is_equal_approx(boss.water.get_rect().get_center().x, meio),
		"portoes e lago espelhados em volta do meio da arena")
	check(not arena.retangulo.grow(64.0).has_point(node("Itens/Checkpoint1").position),
		"checkpoint antes da arena, com folga da margem de deteccao (o pato reaparece fora dela)")
	check(boss.state == "espera" and arena.estado == "aberta" and not Game.camera_limit.has_area(),
		"chefe espera e a arena esta aberta")
	# o boss nunca encosta nos portoes (senao o portao espera para sempre)
	var nado: Rect2 = boss.water.get_rect()
	var mais_esq: float = nado.position.x + 4.0  # _clamp_x: centro a HALF_W + 4 da borda
	var mais_dir: float = nado.end.x - 4.0 + boss.BITE_REACH
	for g in arena._entrada + arena._saida:
		check(mais_dir < g.get_rect().position.x or mais_esq > g.get_rect().end.x,
			"o nado do chefe fica longe do portao em x=%.0f" % g.position.x)
	# barranco de terra suspenso (2 tiles do terreno, borda de baixo) sobre cada portao: ninguem
	# pula por cima, e a entrada/saida parece uma boca de barranco, nao uma coluna solta
	var terreno: TileMapLayer = node("Terreno")
	for col in [50, 51, 72, 73]:
		check(terreno.get_cell_source_id(Vector2i(col, 0)) != -1 and terreno.get_cell_source_id(Vector2i(col, 15)) != -1
			and terreno.get_cell_source_id(Vector2i(col, 16)) == -1
			and terreno.get_cell_atlas_coords(Vector2i(col, 15)).y == 7,
			"barranco solido sobre o portao (coluna %d)" % col)
	check(node("Decoracao/JuncoBarrancoEntrada") != null and node("Decoracao/JuncoBarrancoSaida") != null,
		"juncos ao pe dos barrancos da entrada e da saida")

	# entrar pela entrada fecha a arena atras do pato; a camera so mostra a lagoa
	reset_player(Vector2(838, 304))
	await frames(3)
	check(arena.fechada() and Game.camera_limit == arena.retangulo, "pato passou da entrada: arena fecha")
	await frames(45)
	var ent: Node2D = arena._entrada[0]
	check(ent.fechado() and ent.is_in_group("solid") and not arena._saida[0].aberto(),
		"portao da entrada fechado e solido; saida fechada")
	check(Game.cam_pos.x >= arena.retangulo.position.x and Game.cam_pos.x + 384.0 <= arena.retangulo.end.x,
		"camera nao mostra nada fora da arena (x=%.0f)" % Game.cam_pos.x)
	check(boss.state != "espera" and Game.boss_hp == 5, "portoes fechados: chefe acorda (%s)" % boss.state)
	check(boss.dano() == 0, "chefe inteiro, sem marcas de dano")

	# ciclo completo sozinho (pato invencivel numa plataforma)
	Game.debug_invincible = true
	reset_player(Vector2(1080, 256))
	var seen := {}
	for i in 1200:
		await frames(1)
		seen[boss.state] = true
		if seen.has("dor"):
			break
	Game.debug_invincible = false
	check(seen.has("aviso") and seen.has("salto") and seen.has("mordida_aviso") and seen.has("mordida")
		and seen.has("dor"), "ciclo: bolhas, salto, mordida e dor de dente (%s)" % [seen.keys()])

	# salto acerta quem esta na plataforma
	reset_player(Vector2(904, 256))
	boss.position = Vector2(904, boss.position.y)
	boss._target_x = 904.0
	boss.leaps_left = 1
	boss.force_state("aviso", 1)
	await frames(80)
	check(Game.player_lives == Game.max_lives - 1, "salto do chefe acerta o pato na plataforma")

	# fora da dor de dente, pular nele machuca o pato
	reset_player(Vector2(1040, 230))
	boss.position = Vector2(1040, boss.position.y)
	boss.force_state("mordida_aviso", 999)
	await frames(1)
	player().spdv = 3.0
	await frames(25)
	check(Game.player_lives == Game.max_lives - 1 and boss.hp == 5, "pisar fora da dor de dente machuca o pato")

	# mordida pega quem nada perto
	reset_player(Vector2(1110, 310))
	boss.position = Vector2(1080, boss.position.y)
	boss.dir = 1
	boss.force_state("mordida_aviso", 5)
	await frames(30)
	check(Game.player_lives == Game.max_lives - 1, "mordida pega quem esta perto")

	# 1 pisao deixa marca; reaparecer no checkpoint reabre tudo e o chefe volta inteiro
	boss.position = Vector2(1040, boss.position.y)
	boss.force_state("dor", 999)
	await frames(2)
	reset_player(Vector2(1040, 260))
	player().spdv = 3.0
	await frames(12)
	check(boss.hp == 4 and boss.dano() == 1, "golpe deixa marca de dano (estagio %d)" % boss.dano())
	reset_player(node("Itens/Checkpoint1").position)
	await frames(3)
	check(arena.estado == "aberta" and ent.aberto() and not Game.camera_limit.has_area(),
		"pato no checkpoint: arena reabre e a camera solta")
	check(boss.state == "espera" and boss.hp == 5 and boss.dano() == 0, "chefe volta ao inicio, inteiro")
	reset_player(Vector2(838, 304))
	await frames(50)
	check(arena.estado == "luta" and boss.state != "espera", "entrar de novo recomeca a luta")

	# 5 pisoes com dor de dente derrotam e abrem a saida
	for k in 5:
		if not is_instance_valid(boss) or boss.is_queued_for_deletion():
			break
		boss.position = Vector2(1040, boss.position.y)
		boss.force_state("dor", 999)
		await frames(2)
		reset_player(Vector2(1040, 260))
		player().spdv = 3.0
		await frames(12)
		if k == 0:
			check(boss.hp == 4 and boss.state == "ferido" and Game.boss_hp == 4,
				"pisao com dor de dente tira 1 de vida")
			check(Game.player_lives == Game.max_lives, "pisao certo nao machuca")
		if k > 0 and k < 4:
			check(boss.dano() == k + 1, "as marcas de dano se somam (estagio %d)" % boss.dano())
		if k == 4:
			check(arena.estado == "vencida" and not arena._saida[0].aberto() and Game.camera_limit.has_area(),
				"logo depois da vitoria a camera ainda esta presa")
			break
		await frames(60)
	check(not is_instance_valid(boss) or boss.is_queued_for_deletion(), "5 pisoes derrotam o jacare gigante")
	for i in 200:
		await frames(1)
		if arena.estado == "liberada":
			break
	check(arena.estado == "liberada" and arena._saida[0].aberto() and not arena._saida[0].is_in_group("solid")
		and not Game.camera_limit.has_area() and not Game.boss_visible,
		"saida abre e a camera solta para mostrar a continuacao")

	player().position = Vector2(1320, 304)
	await frames(3)
	check(Game.game_state == "complete" and Game.best.has("fase3"), "saida conclui a fase 3 e salva")
	check(Game.ui_layout()[0]["label"] == "PRÓXIMA FASE", "fase 3 leva a fase 4")
	Game._run_menu_action("PRÓXIMA FASE")
	await wait_level()
	await _test_fase4()


## Para os inimigos da lista (para testar uma coisa de cada vez).
func park(paths_: Array) -> void:
	for path: String in paths_:
		var n: Node2D = node(path)
		n.set_physics_process(false)
		n.position = Vector2(-500, -500)


func _test_fase4() -> void:
	print("-- fase 4 (torre 1/6: chave e gaviaozinho)")
	check(Game.current_level_name == "fase4" and Game.total_collectibles == 4, "fase 4 carregada com 4 flores")
	var porta1: Node2D = node("Mecanicas/Porta1")
	var porta2: Node2D = node("Mecanicas/Porta2")
	var porta3: Node2D = node("Mecanicas/Porta3")
	var caixa: Node2D = node("Itens/Caixa1")
	var placa: Node2D = node("Mecanicas/Placa1")
	var g1: Node2D = node("Entidades/Gaviao1")
	park(["Entidades/Gaviao2", "Entidades/Gaviao3"])
	g1.set_physics_process(false)
	await frames(5)
	check(Game.keys == 0 and porta1.trancada and not porta1.is_open, "comeca sem chave e com a porta trancada")

	print("-- luz e sombra dentro da torre")
	var luz4: Node = node("Luz")
	var amb4: Color = luz4.ambiente()
	check(node("Parallax").cenario == 1 and amb4.r < 0.8 and amb4.b > amb4.r, "torre: luz ambiente escura e azulada")
	var luzes4: Array = luz4.coletar()
	check(luzes4.size() >= 4 and luzes4.size() <= luz4.MAX_LUZES, "tochas, janelas, pato e chave iluminam (%d luzes)" % luzes4.size())
	var perto_pato := false
	for l4: Array in luzes4:
		if (l4[0] as Vector2).distance_to(player().position) < 12.0:
			perto_pato = true
	check(perto_pato, "o pato tem um clarao em volta (nunca some no escuro)")
	check(get_tree().get_nodes_in_group("chave")[0].luzes().size() == 1, "a chave brilha")

	print("-- porta trancada e chave")
	reset_player(Vector2(232, 768))
	await hold(KEY_RIGHT, 40)
	check(not porta1.is_open and player().position.x <= 248.0,
		"sem chave a porta trancada segura o pato (x=%.0f)" % player().position.x)
	porta1.set_active(true)
	await frames(2)
	check(not porta1.is_open, "porta trancada ignora placas/sinais")
	reset_player(Vector2(170, 768))
	await hold(KEY_RIGHT, 10)
	check(Game.keys == 1 and get_tree().get_nodes_in_group("chave").size() == 1, "pega a chave (vai para o HUD)")
	await hold(KEY_RIGHT, 60)
	check(porta1.is_open and Game.keys == 0, "encostar com a chave abre a porta e gasta a chave")
	check(player().position.x > 272.0, "passa pela porta aberta (x=%.0f)" % player().position.x)

	print("-- gaviaozinho")
	g1.set_physics_process(true)
	g1.position = Vector2(384, 672)
	g1.start_x = 384.0
	g1.cruise_y = 672.0
	g1._cooldown = 0
	reset_player(Vector2(450, 768))
	var states := {}
	for i in 150:
		await frames(1)
		states[g1.state] = true
		if Game.player_lives < Game.max_lives:
			break
	check(states.has("aviso") and states.has("rasante"), "ve o pato embaixo, grita e da o rasante (%s)" % [states.keys()])
	check(Game.player_lives == Game.max_lives - 1, "rasante acerta o pato parado")
	# fugir correndo durante o grito escapa
	g1.state = "voo"
	g1.position = Vector2(384, 672)
	g1._cooldown = 0
	reset_player(Vector2(440, 768))
	for i in 60:
		await frames(1)
		if g1.state == "aviso":
			break
	await hold(KEY_LEFT, 70)
	check(Game.player_lives == Game.max_lives, "correndo depois do grito o rasante erra")
	# pisao derrota
	g1.state = "voo"
	g1._cooldown = 999
	g1.velocidade = 0.0
	g1.position = Vector2(400, 700)
	g1.cruise_y = 700.0
	reset_player(Vector2(400, 670))
	player().spdv = 2.0
	await frames(20)
	check(not is_instance_valid(g1) or g1.is_queued_for_deletion(), "pisao derrota o gaviaozinho")
	check(Game.player_lives == Game.max_lives, "pisao no gaviaozinho nao machuca")

	print("-- caixa no buraco segura a placa")
	check(not porta2.is_open, "porta da placa comeca fechada")
	reset_player(Vector2(440, 592))
	key_event(KEY_LEFT, true)
	for i in 200:
		await frames(1)
		if caixa.position.y > 600.0:
			break
	key_event(KEY_LEFT, false)
	await frames(20)
	check(caixa.position == Vector2(328, 608), "caixa cai no buraco (%s)" % caixa.position)
	check(placa.pressed and porta2.is_open, "caixa na placa abre a porta da sala da chave 2")
	reset_player(Vector2(300, 592))
	await hold(KEY_LEFT, 30)
	check(player().position.x < 300.0 and player().position.y == 592.0, "pato passa por cima da caixa no buraco")

	print("-- cipos ligam os andares")
	reset_player(Vector2(568, 768))
	await hold(KEY_UP, 200)
	await hold(KEY_LEFT, 20)
	check(player().position.y == 592.0 and player().position.x < 560.0, "cipo 1 leva ao andar 1")
	reset_player(Vector2(24, 592))
	await hold(KEY_UP, 200)
	await hold(KEY_RIGHT, 20)
	check(player().position.y == 416.0, "cipo 2 leva ao andar 2")
	reset_player(Vector2(616, 416))
	await hold(KEY_UP, 200)
	await hold(KEY_LEFT, 20)
	check(player().position.y == 240.0, "cipo 3 leva ao andar 3")

	print("-- segunda chave e porta 3")
	reset_player(Vector2(56, 592))
	await hold(KEY_RIGHT, 10)
	check(Game.keys == 1, "chave 2 na sala da placa")
	reset_player(Vector2(456, 416))
	await hold(KEY_RIGHT, 30)
	check(porta3.is_open and Game.keys == 0, "chave 2 abre a porta 3")

	print("-- alturas")
	reset_player(Vector2(232, 416))  # andar 2, antes do bloco de 3 tiles
	await play(40, [KEY_RIGHT], {2: KEY_SPACE})
	check(player().position.x < 256.0, "bloco de 3 tiles: pulo simples nao passa")
	reset_player(Vector2(232, 416))
	await double_jump_right(60)
	check(player().position.x > 288.0, "bloco de 3 tiles: pulo duplo passa")
	# ressalto fino 3 tiles acima: pulo duplo parado e depois para o lado
	var flores := Game.current_collectibles
	reset_player(Vector2(504, 416))
	await play(22, [], {2: KEY_SPACE, 16: KEY_SPACE})
	await play(30, [KEY_RIGHT])
	check(Game.current_collectibles == flores + 1, "ressalto fino de 3 tiles alcancavel (flor 3)")

	player().position = Vector2(40, 96)
	await frames(3)
	check(Game.game_state == "complete" and Game.best.has("fase4"), "saida (na sacada) conclui a fase 4")
	check(Game.ui_layout()[0]["label"] == "PRÓXIMA FASE", "fase 4 leva a fase 5")
	Game._run_menu_action("PRÓXIMA FASE")
	await wait_level()
	await _test_fase5()


func _test_fase5() -> void:
	print("-- fase 5 (torre 2/6: aguia e caixas)")
	check(Game.current_level_name == "fase5" and Game.total_collectibles == 4, "fase 5 carregada com 4 flores")
	var a1: Node2D = node("Entidades/Aguia1")
	park(["Entidades/Aguia2", "Entidades/Aguia3", "Entidades/Gaviao1"])
	a1.set_physics_process(false)
	var caixa1: Node2D = node("Itens/Caixa1")
	var caixa2: Node2D = node("Itens/Caixa2")
	var caixa3: Node2D = node("Itens/Caixa3")
	await frames(5)

	print("-- paredao so com a caixa")
	reset_player(Vector2(500, 768))
	await play(60, [KEY_LEFT], {2: KEY_SPACE, 18: KEY_SPACE})
	check(player().position.x > 456.0, "sem a caixa o pulo duplo nao passa o paredao (x=%.0f)" % player().position.x)
	reset_player(Vector2(560, 768))
	key_event(KEY_LEFT, true)
	for i in 200:
		await frames(1)
		if caixa1.position.x <= 472.0:
			break
	key_event(KEY_LEFT, false)
	await frames(5)
	check(caixa1.position.x == 472.0, "caixa empurrada ate o paredao (x=%.0f)" % caixa1.position.x)
	reset_player(Vector2(490, 768))
	await play(30, [KEY_LEFT], {2: KEY_SPACE})  # sobe na caixa
	await play(60, [KEY_LEFT], {2: KEY_SPACE, 18: KEY_SPACE})
	check(player().position.x < 432.0, "de cima da caixa o pulo duplo passa o paredao (x=%.0f)" % player().position.x)

	print("-- aguia")
	a1.set_physics_process(true)
	a1.home = Vector2(240, 672)
	a1.position = Vector2(240, 672)
	a1._cooldown = 0
	reset_player(Vector2(300, 768))
	var states := {}
	for i in 200:
		await frames(1)
		states[a1.state] = true
		if a1.state == "presa":
			break
	check(states.has("aviso") and states.has("mergulho"), "aguia grita e mergulha (%s)" % [states.keys()])
	check(Game.player_lives == Game.max_lives - 1, "mergulho acerta o pato parado")
	check(a1.state == "presa", "depois do mergulho fica com o bico preso no chao")
	reset_player(Vector2(a1.position.x, a1.position.y - 30))
	player().spdv = 2.0
	await frames(15)
	check(a1.hp == 1 and a1.state == "subindo", "pisao tira 1 de vida e ela volta para o alto")
	check(Game.player_lives == Game.max_lives, "pisao na aguia nao machuca")
	# caixa arremessada acerta a aguia
	a1.state = "circulo"
	a1._cooldown = 999
	a1._hurt_until = -1
	a1.home = Vector2(400, 750)
	a1.position = Vector2(400, 750)
	a1.set_physics_process(false)
	caixa1.position = Vector2(344, 768)
	caixa1.vel = Vector2.ZERO
	reset_player(Vector2(328, 768))
	player().xscale = 1
	await frames(2)
	await press_key(KEY_X)
	await frames(2)
	await press_key(KEY_X)
	await frames(30)
	check(not is_instance_valid(a1) or a1.is_queued_for_deletion(), "caixa arremessada derrota a aguia (2o golpe)")

	print("-- chave no ressalto alto (precisa da caixa)")
	reset_player(Vector2(264, 592))
	await double_jump_right(70)
	check(Game.keys == 0, "sem a caixa nao alcanca o ressalto da chave")
	reset_player(Vector2(184, 592))
	key_event(KEY_RIGHT, true)
	for i in 200:
		await frames(1)
		if caixa2.position.x >= 280.0:
			break
	key_event(KEY_RIGHT, false)
	await frames(5)
	check(caixa2.position == Vector2(280, 592), "caixa empurrada para no pilar (%s)" % caixa2.position)
	reset_player(Vector2(280, 576))
	await frames(5)
	check(player().position.y == 576.0, "pato em cima da caixa encostada no pilar")
	await play(70, [KEY_RIGHT], {2: KEY_SPACE, 18: KEY_SPACE})
	check(Game.keys == 1, "de cima da caixa alcanca a chave 1")
	reset_player(Vector2(456, 592))
	await hold(KEY_RIGHT, 30)
	check(node("Mecanicas/Porta1").is_open, "chave 1 abre a porta do andar 1")

	print("-- derrubar a caixa do ressalto ate a placa")
	reset_player(Vector2(392, 368))
	key_event(KEY_LEFT, true)
	for i in 120:
		await frames(1)
		if caixa3.position.y > 400.0:
			break
	key_event(KEY_LEFT, false)
	await frames(20)
	check(roundf(caixa3.position.y) == 416.0, "caixa empurrada cai do ressalto (%s)" % caixa3.position)
	# o pato volta para a direita da caixa e empurra ate a placa
	reset_player(Vector2(caixa3.position.x + 30.0, 416))
	key_event(KEY_LEFT, true)
	for i in 300:
		await frames(1)
		if node("Mecanicas/Placa1").pressed:
			break
	key_event(KEY_LEFT, false)
	await frames(5)
	check(node("Mecanicas/Placa1").pressed, "caixa empurrada ate a placa (%s)" % caixa3.position)
	check(node("Mecanicas/Porta2").is_open, "placa abre a sala da chave 2")
	reset_player(Vector2(56, 416))
	await hold(KEY_RIGHT, 10)
	check(Game.keys == 1, "chave 2 na sala da placa")
	reset_player(Vector2(424, 240))
	await hold(KEY_RIGHT, 30)
	check(node("Mecanicas/Porta3").is_open, "chave 2 abre a ultima porta")

	player().position = Vector2(568, 240)
	await frames(3)
	check(Game.game_state == "complete" and Game.best.has("fase5"), "saida conclui a fase 5 e salva")
	check(Game.ui_layout()[0]["label"] == "PRÓXIMA FASE", "fase 5 leva a fase 6")
	Game._run_menu_action("PRÓXIMA FASE")
	await wait_level()
	await _test_fase6()


# -------------------------------------------------- ajudantes das fases de vento
## Tira todas as aves do caminho.
func park_birds() -> void:
	for b in get_tree().get_nodes_in_group("ave"):
		b.set_physics_process(false)
		b.position = Vector2(-500, -500)


## Coloca uma rajada no comeco da calmaria (ou da rajada, com blowing).
func set_gust(path: String, blowing: bool) -> void:
	var v: Node2D = node(path)
	v._t = 0 if blowing else v.tempo_ligado


func grounded() -> bool:
	var p := player()
	return Solids.hits(Solids.snapshot(get_tree()), Rect2(p.position.x - 7.0, p.position.y, 15.0, 1.0))


## "Robo" que corre para um lado e pula sempre que o chao acaba logo a frente. Para ao
## passar de stop_x (se dado) e espera pousar.
func run_and_hop(key: Key, n: int, stop_x := NAN) -> void:
	var d := 1.0 if key == KEY_RIGHT else -1.0
	key_event(key, true)
	for i in n:
		var p := player()
		if not is_nan(stop_x) and (p.position.x - stop_x) * d >= 0.0:
			break
		var ahead := Solids.hits(Solids.snapshot(get_tree()),
			Rect2(p.position.x + d * 12.0, p.position.y, 2.0, 1.0))
		if grounded() and not ahead:
			key_event(KEY_SPACE, true)
			await frames(1)
			key_event(KEY_SPACE, false)
		else:
			await frames(1)
	key_event(key, false)
	for i in 60:
		await frames(1)
		if grounded():
			break
	await frames(2)


## Pulo duplo mirando o ponto (tx, topo ty): anda para o alvo e para em cima dele.
func hop_to(tx: float, ty: float, n := 60) -> void:
	var held := 0
	for i in n:
		if i == 1 or i == 15:
			key_event(KEY_SPACE, true)
		var dx := tx - player().position.x
		var want := 0
		if absf(dx) > 2.0:
			want = 1 if dx > 0.0 else -1
		if want != held:
			if held != 0:
				key_event(KEY_RIGHT if held > 0 else KEY_LEFT, false)
			if want != 0:
				key_event(KEY_RIGHT if want > 0 else KEY_LEFT, true)
			held = want
		await frames(1)
		if i == 1 or i == 15:
			key_event(KEY_SPACE, false)
		if i > 20 and grounded() and absf(player().position.y - ty) < 0.5 and want == 0:
			break
	if held != 0:
		key_event(KEY_RIGHT if held > 0 else KEY_LEFT, false)
	await frames(2)


func _test_fase6() -> void:
	print("-- fase 6 (torre 3/6: pedras que caem e vento)")
	check(Game.current_level_name == "fase6" and Game.total_collectibles == 4, "fase 6 carregada com 4 flores")
	check(node("Parallax").hora == 4 and node("Luz").ambiente().r < 0.66, "fase 6: noite, mais escura")
	park_birds()
	var pedra: Node2D = node("Mecanicas/Pedra1")
	await frames(5)

	print("-- pedra que cai")
	reset_player(Vector2(240, 768))
	await frames(5)
	check(pedra.state == "tremendo" and pedra.is_in_group("solid"), "pisou: a pedra treme e ainda segura")
	await frames(30)
	check(pedra.state == "caindo" and not pedra.is_in_group("solid"), "depois de meio segundo ela cai")
	await frames(10)
	check(player().position.y > 768.0, "o pato cai junto")
	await frames(120)
	check(Game.player_lives == Game.max_lives - 1, "cair no poco sem fundo custa 1 coracao")
	await frames(80)
	check(pedra.state != "caindo" and pedra.is_in_group("solid"), "a pedra volta para o lugar")

	print("-- atravessar o poco pelas pedras")
	reset_player(Vector2(150, 768))
	await run_and_hop(KEY_RIGHT, 130)
	check(player().position.x > 368.0 and player().position.y == 768.0 and Game.player_lives == Game.max_lives,
		"pedras que caem atravessam o poco (x=%.0f)" % player().position.x)

	print("-- rajada de vento")
	set_gust("Mecanicas/Rajada1", true)
	reset_player(Vector2(424, 768))
	await frames(30)
	check(player().position.x < 410.0, "rajada contra empurra o pato parado (x=%.0f)" % player().position.x)
	set_gust("Mecanicas/Rajada1", false)
	reset_player(Vector2(424, 768))
	await frames(30)
	check(player().position.x == 424.0, "na calmaria nada empurra")
	var box: Node2D = CaixaScene.instantiate()
	box.position = Vector2(424, 768)
	node("Itens").add_child(box)
	reset_player(Vector2(520, 768))
	set_gust("Mecanicas/Rajada1", true)
	await frames(20)
	check(box.position.x < 420.0, "a rajada arrasta a caixa (x=%.0f)" % box.position.x)
	box.queue_free()
	set_gust("Mecanicas/Rajada1", true)
	reset_player(Vector2(400, 768))
	await play(60, [KEY_RIGHT])
	check(player().position.x < 460.0, "contra a rajada o pato quase nao anda (x=%.0f)" % player().position.x)
	set_gust("Mecanicas/Rajada1", false)
	reset_player(Vector2(400, 768))
	await run_and_hop(KEY_RIGHT, 60)
	check(player().position.x > 480.0 and player().position.y == 768.0, "na calmaria passa o vao")

	print("-- corrente de ar")
	reset_player(Vector2(584, 768))
	await frames(120)
	check(player().position.y < 592.0, "a corrente levanta o pato acima do andar 1 (y=%.0f)" % player().position.y)
	await hold(KEY_LEFT, 30)
	await frames(10)
	check(player().position.y == 592.0 and Game.player_lives == Game.max_lives, "sai da corrente no andar 1 sem se machucar")

	print("-- andares 1 a 3")
	reset_player(Vector2(420, 592))
	await run_and_hop(KEY_LEFT, 140, 200.0)
	check(player().position.x < 216.0 and player().position.y == 592.0, "andar 1: pedras sobre o vao (%s)" % player().position)
	set_gust("Mecanicas/Rajada2", false)
	reset_player(Vector2(184, 416))
	await run_and_hop(KEY_RIGHT, 115)
	check(player().position.x > 392.0 and player().position.y == 416.0, "andar 2: vaos na calmaria da rajada (x=%.0f)" % player().position.x)
	reset_player(Vector2(584, 416))
	await frames(120)
	await hold(KEY_LEFT, 30)
	await frames(10)
	check(player().position.y == 240.0, "corrente 2 leva ao andar 3")
	set_gust("Mecanicas/Rajada3", false)
	reset_player(Vector2(440, 240))
	await run_and_hop(KEY_LEFT, 160, 110.0)
	check(player().position.x < 128.0 and player().position.y == 240.0, "andar 3: pedras na calmaria (%s)" % player().position)

	player().position = Vector2(48, 240)
	await frames(3)
	check(Game.game_state == "complete" and Game.best.has("fase6"), "saida conclui a fase 6")
	Game._run_menu_action("PRÓXIMA FASE")
	await wait_level()
	await _test_fase7()


func _test_fase7() -> void:
	print("-- fase 7 (torre 4/6: poco alto)")
	check(Game.current_level_name == "fase7" and Game.total_collectibles == 4, "fase 7 carregada com 4 flores")
	park_birds()
	await frames(5)
	reset_player(Vector2(40, 1088))
	await hop_to(80, 1040)
	await hop_to(160, 992)
	await hop_to(240, 944)
	await hop_to(320, 896)
	check(player().position == Vector2(320, 896), "escada de pedras: chega na 4a pedra (%s)" % player().position)
	await hop_to(264, 848)
	check(player().position.y == 848.0 and Game.player_lives == Game.max_lives, "e no ressalto 1")
	reset_player(Vector2(120, 848))
	await hold(KEY_LEFT, 40)
	await frames(80)
	await hold(KEY_RIGHT, 30)
	await frames(10)
	check(player().position.y == 640.0, "corrente 1 leva ao ressalto 2 (y=%.0f)" % player().position.y)
	reset_player(Vector2(136, 640))
	await run_and_hop(KEY_RIGHT, 100, 316.0)
	check(player().position.x >= 310.0 and player().position.y == 640.0, "vento a favor: pedra ate o ressalto 3 (%s)" % player().position)
	reset_player(Vector2(360, 640))
	await hold(KEY_UP, 220)
	await hold(KEY_LEFT, 20)
	check(player().position.y == 448.0, "cipo leva ao ressalto 4")
	set_gust("Mecanicas/Rajada1", false)
	reset_player(Vector2(232, 448))
	await hop_to(160, 416)
	await hop_to(80, 384)
	await hop_to(24, 336)
	check(player().position.y < 340.0 and player().position.x < 40.0, "pedras com a rajada calma ate o ressalto 5 (%s)" % player().position)
	await frames(120)
	await hold(KEY_RIGHT, 30)
	await frames(10)
	check(player().position.y == 160.0, "corrente 2 leva a sacada da saida (y=%.0f)" % player().position.y)
	player().position = Vector2(328, 160)
	await frames(3)
	check(Game.game_state == "complete" and Game.best.has("fase7"), "saida conclui a fase 7")
	Game._run_menu_action("PRÓXIMA FASE")
	await wait_level()
	await _test_fase8()


func _test_fase8() -> void:
	print("-- fase 8 (torre 5/6: tudo junto)")
	check(Game.current_level_name == "fase8" and Game.total_collectibles == 4, "fase 8 carregada com 4 flores")
	park_birds()
	await frames(5)
	set_gust("Mecanicas/Rajada1", false)
	reset_player(Vector2(120, 576))
	await run_and_hop(KEY_RIGHT, 125, 370.0)
	check(Game.keys == 1 and player().position.y == 576.0, "vaos na calmaria e chave 1 (x=%.0f)" % player().position.x)
	await hold(KEY_RIGHT, 50)
	check(node("Mecanicas/Porta1").is_open, "chave 1 abre a porta 1")
	reset_player(Vector2(440, 576))
	await run_and_hop(KEY_RIGHT, 110, 672.0)
	check(player().position.x >= 660.0 and player().position.y == 576.0, "pedras sobre o poco (%s)" % player().position)
	reset_player(Vector2(712, 576))
	await frames(120)
	await hold(KEY_LEFT, 25)
	await frames(10)
	check(player().position.y == 384.0, "corrente 1 leva ao andar 1")
	set_gust("Mecanicas/Rajada2", false)
	reset_player(Vector2(520, 384))
	await run_and_hop(KEY_LEFT, 150, 280.0)
	check(player().position.x < 290.0 and player().position.y == 384.0, "pedras com a rajada calma (%s)" % player().position)
	reset_player(Vector2(184, 384))
	await play(22, [], {2: KEY_SPACE, 16: KEY_SPACE})
	await play(25, [KEY_RIGHT])
	check(Game.keys == 1, "chave 2 no ressalto")
	reset_player(Vector2(120, 384))
	await hold(KEY_LEFT, 30)
	check(node("Mecanicas/Porta2").is_open, "chave 2 abre a porta 2")
	reset_player(Vector2(40, 384))
	await frames(120)
	await hold(KEY_RIGHT, 30)
	await frames(40)
	check(player().position.y == 192.0, "corrente 2 leva ao andar 2 (%s)" % player().position)
	reset_player(Vector2(180, 192))
	await run_and_hop(KEY_RIGHT, 160, 572.0)
	check(player().position.x > 560.0 and player().position.y == 192.0, "vento a favor: pedras sobre o vao enorme (%s)" % player().position)
	player().position = Vector2(712, 192)
	await frames(3)
	check(Game.game_state == "complete" and Game.best.has("fase8"), "saida conclui a fase 8 e salva")
	check(Game.ui_layout()[0]["label"] == "PRÓXIMA FASE", "fase 8 leva a fase final")
	Game._run_menu_action("PRÓXIMA FASE")
	await wait_level()
	await _test_fase_final()


## Espera o chefe chegar num estado (ate n frames). Devolve se chegou.
func wait_boss(boss: Node2D, s: String, n := 600) -> bool:
	for i in n:
		if not is_instance_valid(boss) or boss.state == s:
			return is_instance_valid(boss)
		await frames(1)
	return false


func _test_fase_final() -> void:
	print("-- fase final (chefe gaviao)")
	check(Game.current_level_name == "fase_final" and Game.total_collectibles == 3, "fase final carregada com 3 flores")
	var boss: Node2D = node("Entidades/Gaviao")
	# arena isolada (arena_chefe.gd): grade da torre na entrada e na saida, no lugar das portas
	var arena: Node2D = node("Mecanicas/ArenaChefe")
	var entrada: Node2D = arena._entrada[0]
	var saida: Node2D = arena._saida[0]
	await frames(5)
	check(boss.state == "espera" and arena.estado == "aberta" and entrada.aberto() and saida.aberto()
		and arena.tipo_portao == "torre", "gaviao espera; arena aberta com a grade da torre")
	check(boss.get_mask().size == Vector2(36, 22) and boss.sombra_largura() >= 38.0,
		"gaviao chefe grande e gordo (quadro 48, corpo 36x22)")

	print("-- comeco da luta")
	reset_player(Vector2(248, 160))
	await frames(10)
	# a camera desliza ate o enquadramento da arena enquanto a grade desce (camera.gd)
	check(arena.fechada() and Game.camera_limit.has_area(),
		"pato na arena: ela fecha e prende a camera (x=%.0f)" % Game.cam_pos.x)
	check(boss.state == "espera" and not entrada.aberto() and not saida.aberto(),
		"a grade desce na entrada e na saida antes da luta")
	for i in 80:
		if boss.state != "espera":
			break
		await frames(1)
	check(boss.state != "espera" and entrada.fechado() and saida.fechado() and boss.hp == 10,
		"grade fechada: a luta comeca (sem barra de vida no HUD)")
	check(Game.cam_pos.x == 160.0, "grade fechada: camera ja presa na arena (x=%.0f)" % Game.cam_pos.x)
	print("-- pato fora da arena: tudo volta ao comeco")
	reset_player(Vector2(32, 160))
	await frames(3)
	check(arena.estado == "aberta" and boss.state == "espera" and boss.hp == 10
		and not Game.camera_limit.has_area() and entrada.aberto(),
		"reaparecer fora reabre a arena e reinicia o gaviao")
	reset_player(Vector2(248, 160))
	for i in 90:
		if boss.state != "espera":
			break
		await frames(1)
	check(boss.state != "espera" and arena.estado == "luta", "entrando de novo a luta recomeca")

	print("-- ciclo de ataques sozinho")
	Game.debug_invincible = true
	var seen := {}
	for i in 1500:
		await frames(1)
		seen[boss.state] = true
		if boss.state == "atordoado":
			break
	Game.debug_invincible = false
	check(seen.has("aviso") and seen.has("mergulho") and seen.has("subida") and seen.has("preparar")
		and seen.has("carga_aviso") and seen.has("investida") and seen.has("atordoado"),
		"mergulhos, investida e atordoado (%s)" % [seen.keys()])
	# gaviao maior: o centro para a 26 px da parede (208 + 26 / 496 - 26), cauda e bico fora da grade
	check(absf(boss.position.x - 234.0) < 2.0 or absf(boss.position.x - 470.0) < 2.0,
		"a investida termina batendo numa parede (x=%.0f)" % boss.position.x)
	await frames(1)
	check(boss.position.y == 152.0 and not boss.harmful() and boss.stompable, "atordoado no chao: nao machuca e pode ser pisado")

	print("-- mergulho e investida acertam o pato")
	# x=310: o mergulho do gaviao grande (32 px de largura) a 300 raspa o ressalto 240..288
	reset_player(Vector2(310, 160))
	boss.position = Vector2(310, 66)
	boss.force_state("aviso", 1)
	await frames(60)
	check(Game.player_lives == Game.max_lives - 1, "mergulho acerta o pato parado")
	# o bico da pose de mergulho (abaixo da caixa de colisao) para no ressalto 240..288 (topo 112)
	boss._vel = Vector2(0, 4)
	boss._merg_t = 18.0
	var ponta: Rect2 = boss._ponta_quadro(boss._quadro_mergulho())
	if ponta.has_area():
		boss.dir = 1
		var nx := 264.0 - roundf(ponta.get_center().x)
		var snap_g := Solids.snapshot(get_tree())
		var y_toca := 112.0 - ponta.position.y - ponta.size.y
		check(boss._bico_bate(snap_g, Vector2(nx, y_toca + 1.0)) and not boss._bico_bate(snap_g, Vector2(nx, y_toca)),
			"o bico do mergulho para no ressalto em vez de entrar nele")
	reset_player(Vector2(370, 160))
	boss.position = Vector2(234, 151)
	boss.dir = 1
	boss.force_state("carga_aviso", 1)
	await frames(60)
	check(Game.player_lives == Game.max_lives - 1, "investida acerta o pato no chao")
	reset_player(Vector2(248, 112))  # em cima do ressalto
	boss.position = Vector2(234, 151)
	boss.dir = 1
	boss.force_state("carga_aviso", 1)
	await frames(90)
	check(Game.player_lives == Game.max_lives, "no ressalto a investida passa por baixo")
	check(boss.state == "atordoado", "e ele bate na parede do outro lado")

	print("-- golpes so com ele atordoado")
	boss.position = Vector2(370, 90)
	boss.force_state("aviso", 999)
	reset_player(Vector2(370, 50))
	player().spdv = 3.0
	await frames(25)
	check(boss.hp == 10 and Game.player_lives == Game.max_lives - 1, "pular nele voando machuca o pato")
	boss.position = Vector2(370, 152)
	boss.force_state("atordoado", 999)
	reset_player(Vector2(370, 118))
	player().spdv = 2.0
	await frames(12)
	check(boss.hp == 9 and Game.boss_hp == 9 and Game.player_lives == Game.max_lives, "pisao com ele atordoado tira 1")
	check(boss.nivel_dano() == 1, "1o golpe ja aparece no gaviao (linha de dano 1)")
	await frames(45)
	reset_player(Vector2(370, 118))
	player().spdv = 2.0
	await frames(12)
	check(boss.hp == 8 and boss.state == "subida", "2o golpe: ele levanta voo")
	# caixa arremessada
	boss.position = Vector2(400, 152)
	boss.force_state("atordoado", 999)
	boss._hurt_until = -1
	var caixa: Node2D = node("Itens/Caixa1")
	caixa.position = Vector2(344, 160)
	caixa.vel = Vector2.ZERO
	caixa.state = "idle"
	reset_player(Vector2(328, 160))
	player().xscale = 1
	await frames(2)
	await press_key(KEY_X)
	await frames(2)
	await press_key(KEY_X)
	await frames(30)
	check(boss.hp == 7, "caixa arremessada acerta o gaviao atordoado (hp %d)" % boss.hp)
	check(boss.nivel_dano() == 2, "o dano se acumula no desenho (linha %d)" % boss.nivel_dano())

	print("-- etapa 2")
	boss.hp = 6
	Game.boss_hp = 6
	boss._hurt_until = -1
	boss.position = Vector2(400, 152)
	boss.force_state("atordoado", 999)
	reset_player(Vector2(400, 118))
	player().spdv = 2.0
	await frames(12)
	check(boss.hp == 5 and boss.state == "transicao" and boss.stage == 2, "com 5 de vida perdida vai para a etapa 2")
	check(get_tree().get_nodes_in_group("item").filter(func(n): return n.get_script() == VidaScene.instantiate().get_script()).size() >= 1,
		"deixa cair um coracao")
	var coracoes := func() -> int:
		return get_tree().get_nodes_in_group("item").filter(
			func(n): return n.scene_file_path == VidaScene.resource_path and not n.is_queued_for_deletion()).size()
	var n_cor: int = coracoes.call()
	boss._start_transition()
	check(coracoes.call() == n_cor, "etapa 2 de novo nao solta um 2o coracao")
	await wait_boss(boss, "voo", 200)
	check(boss.dives_left == 5 and boss._dive_speed() > 4.0, "etapa 2: 5 mergulhos e mais rapido")
	check(boss.nivel_dano() == 3 and boss._altura_pairar() > boss.altura_voo,
		"etapa 2: cores apagadas e voo mais baixo e pesado")

	print("-- derrota")
	for k in 5:
		if not is_instance_valid(boss) or boss.is_queued_for_deletion():
			break
		boss._hurt_until = -1
		boss.position = Vector2(400, 152)
		boss.force_state("atordoado", 999)
		reset_player(Vector2(400, 118))
		player().spdv = 2.0
		await frames(50)
	check(not is_instance_valid(boss) or boss.is_queued_for_deletion(), "10 golpes derrotam o gaviao")
	await frames(5)
	check(Game.camera_limit.has_area() and not saida.aberto(),
		"logo depois da vitoria a camera ainda nao mostra a continuacao")
	for i in 200:
		if arena.estado == "liberada":
			break
		await frames(1)
	check(saida.aberto() and not Game.boss_visible and not Game.camera_limit.has_area(),
		"a grade da saida sobe e a camera solta")
	player().position = Vector2(536, 160)
	await frames(3)
	check(Game.game_state == "complete" and Game.best.has("fase_final"), "saida conclui a fase final e salva")
	check(Game.ui_layout()[0]["label"] == "VER O FINAL", "fase final leva a cutscene")
	await _test_cutscene()


func _test_cutscene() -> void:
	print("-- cutscene final")
	Game._run_menu_action("VER O FINAL")
	await wait_room("cutscene_final")
	await frames(5)
	var scene: Node2D = get_tree().current_scene
	check(Game.game_state == "cutscene" and not get_tree().paused and not Game.in_level,
		"cutscene rodando (sem HUD nem pausa)")
	var x0: float = scene.duck_x()
	await frames(30)
	check(scene.t > 0.3 and scene.duck_x() > x0, "o pato entra andando")
	scene.t = 8.0
	await frames(2)
	check(scene.pata_x() == scene.PATA_STOP_X and scene.duck_x() == scene.DUCK_STOP_X,
		"o pato e a Pata se encontram")
	var fl := Game.flores_colhidas()
	check(scene.buque == Game.buque_nivel(fl.x, fl.y), "buque pelas flores colhidas (%d de %d -> %d)" % [fl.x, fl.y, scene.buque])
	check(Game.buque_nivel(0, 40) == 0 and Game.buque_nivel(5, 40) == 1 and Game.buque_nivel(20, 40) == 2
		and Game.buque_nivel(39, 40) == 2 and Game.buque_nivel(40, 40) == 3,
		"nenhuma flor, uma flor, buque pequeno (metade) e buque grande (todas)")
	check(scene.sunset() > 0.2 and scene.sunset() < 1.0, "o sol esta se pondo")
	scene.t = 21.95
	await wait_room("menu")
	await frames(3)
	check(Game.game_state == "credits" and Game.credits_after_ending, "no fim vao os creditos com FIM")
	await press_key(KEY_ESCAPE)
	check(Game.game_state == "main" and not Game.credits_after_ending, "ESC volta ao menu principal")
	# pular com ENTER
	Game.play_ending()
	await wait_room("cutscene_final")
	await frames(45)
	await press_key(KEY_ENTER)
	await wait_room("menu")
	await frames(3)
	check(Game.game_state == "credits", "ENTER pula a cutscene")
	Game.game_state = "main"
	Game.credits_after_ending = false


# -------------------------------------------------- Fase 4: laboratorio
func _test_mechanics() -> void:
	print("-- laboratorio de mecanicas (Fase 4)")
	Game.game_state = "playing"
	Game.room_goto(Game.LAB_LEVEL)
	await wait_level()
	check(Game.current_level_name == "laboratorio" and Game.total_collectibles == 3, "laboratorio carregado")
	var caixa1: Node2D = node("Itens/Caixa1")
	var caixa2: Node2D = node("Itens/Caixa2")
	var placa: Node2D = node("Mecanicas/Placa1")
	var porta: Node2D = node("Mecanicas/Porta1")
	var fox: Node2D = node("Entidades/Raposa1")
	await frames(10)
	check(caixa1.position.y == 336.0, "caixa parada no chao")
	check(not porta.is_open, "porta comeca fechada")

	print("-- empurrar caixa ate a placa abre a porta")
	reset_player(Vector2(80, 336))
	player().xscale = 1
	var x0 := caixa1.position.x
	var pushed := false
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_RIGHT
	ev.pressed = true
	Input.parse_input_event(ev)
	for i in 200:
		await frames(1)
		if caixa1.position.x >= 184.0:
			pushed = true
			break
	var up := InputEventKey.new()
	up.physical_keycode = KEY_RIGHT
	up.pressed = false
	Input.parse_input_event(up)
	await frames(3)
	check(pushed and caixa1.position.x > x0, "pato empurra a caixa (x %.0f -> %.0f)" % [x0, caixa1.position.x])
	check(placa.pressed, "caixa em cima pressiona a placa")
	check(porta.is_open, "placa abre a porta")
	caixa1.position = Vector2(120, 336)
	reset_player(Vector2(40, 336))
	await frames(3)
	check(not placa.pressed and not porta.is_open, "sem peso a porta fecha")
	reset_player(Vector2(184, 336))
	await frames(3)
	check(placa.pressed and porta.is_open, "o pato em cima tambem pressiona")

	print("-- porta fechada bloqueia")
	reset_player(Vector2(220, 336))
	await frames(3)  # sai da placa: porta fecha
	await hold(KEY_RIGHT, 40)
	check(player().position.x <= 232.0, "nao atravessa a porta fechada (x=%.0f)" % player().position.x)

	print("-- pegar e arremessar (D1/D2)")
	caixa2.position = Vector2(272, 336)
	reset_player(Vector2(256, 336))  # mascara termina em 264 = borda da caixa
	player().xscale = 1
	porta.set_active(true)
	await frames(2)
	await press_key(KEY_X)
	check(player().carrying == caixa2 and caixa2.state == "carried", "X pega a caixa da frente")
	check(not caixa2.is_in_group("solid"), "caixa carregada nao e solida")
	await frames(2)
	check(caixa2.position.y < player().position.y - 10.0, "caixa acima da cabeca")
	fox.position = Vector2(330, 336)
	fox.start_x = 330.0
	fox.dir = -1
	await press_key(KEY_X)
	check(player().carrying == null and caixa2.state == "thrown", "X de novo arremessa")
	for i in 60:
		await frames(1)
		if caixa2.state == "idle":
			break
	check(not is_instance_valid(fox) or fox.is_queued_for_deletion(), "caixa arremessada derrota a raposa")
	check(caixa2.state == "idle" and caixa2.is_in_group("solid"), "caixa pousa e volta a ser solida")

	print("-- pousar com BAIXO + X e sem espaco acima")
	reset_player(Vector2(caixa2.position.x - 16.0, 336))
	player().xscale = 1
	await frames(2)
	await press_key(KEY_X)
	check(player().carrying == caixa2, "pega de novo")
	var down := InputEventKey.new()
	down.physical_keycode = KEY_DOWN
	down.pressed = true
	Input.parse_input_event(down)
	await press_key(KEY_X)
	var down_up := InputEventKey.new()
	down_up.physical_keycode = KEY_DOWN
	down_up.pressed = false
	Input.parse_input_event(down_up)
	await frames(5)
	check(player().carrying == null and caixa2.state == "idle", "BAIXO + X pousa a caixa")
	check(absf(caixa2.position.x - (player().position.x + 16.0)) < 1.0 and caixa2.position.y == 336.0,
		"pousada logo a frente, no chao")
	var teto := BlockScene.instantiate()
	teto.position = Vector2(caixa2.position.x - 40.0, 336.0 - 18.0)  # bloco 2 px acima da cabeca
	teto.tiles_w = 3
	get_tree().current_scene.add_child(teto)
	reset_player(Vector2(caixa2.position.x - 16.0, 336))
	await frames(2)
	await press_key(KEY_X)
	check(player().carrying == null, "sem espaco acima da cabeca nao pega")
	teto.queue_free()
	await frames(1)

	print("-- cipo")
	reset_player(Vector2(448, 336))
	await hold(KEY_UP, 130)
	check(player().climbing, "CIMA no cipo escala")
	check(player().position.y == 288.0, "para no topo do cipo (y=%.1f)" % player().position.y)
	await hold(KEY_RIGHT, 25)
	await frames(20)
	check(not player().climbing and player().position.y == 288.0 and player().position.x > 460.0,
		"sai andando para a plataforma de cima (%s)" % [player().position])
	reset_player(Vector2(448, 288))  # em pe no topo do cipo
	player().climbing = false
	await frames(2)
	await hold(KEY_DOWN, 20)
	check(player().position.y > 300.0, "BAIXO no topo desce o cipo (y=%.1f)" % player().position.y)
	reset_player(Vector2(448, 320))
	player().climbing = true
	await frames(1)
	await press_key(KEY_SPACE)
	await frames(2)
	check(not player().climbing and player().spdv < 0.0, "PULO solta do cipo")

	print("-- plataforma movel")
	var plat: Node2D = node("Mecanicas/PlataformaMovel")
	for i in 400:  # espera a plataforma voltar ao inicio
		await frames(1)
		if plat._t == 0.0 and plat._wait > 0:
			break
	reset_player(Vector2(plat.position.x + 24.0, 288))
	var px0 := player().position.x
	var plat_x0 := plat.position.x
	await frames(plat._wait + 80)
	var moved := plat.position.x - plat_x0
	check(moved > 20.0, "plataforma anda (%.1f px)" % moved)
	check(absf((player().position.x - px0) - moved) < 1.5 and player().position.y == 288.0,
		"leva o pato junto (pato %.1f, plataforma %.1f)" % [player().position.x - px0, moved])

	print("-- agua do laboratorio leva ao checkpoint")
	reset_player(Vector2(504, 288))
	await frames(2)
	check(Game.has_checkpoint, "checkpoint do laboratorio ativo")
	reset_player(Vector2(620, 336))
	await frames(3)
	check(Game.player_lives == Game.max_lives - 1 and player().position.distance_to(Vector2(504, 288)) < 4.0,
		"cair na agua custa 1 vida e volta ao checkpoint")

	print("-- laboratorio nao salva progresso")
	var best_before: Dictionary = Game.best.duplicate(true)
	player().position = Vector2(930, 336)
	await frames(3)
	check(Game.game_state == "complete", "saida do laboratorio conclui")
	check(Game.best == best_before and not Game.best.has("laboratorio"), "nenhum recorde gravado")


## Chefe de mentira para a arena (so o contrato que arena_chefe.gd usa).
func _chefe_falso() -> Node2D:
	var gs := GDScript.new()
	gs.source_code = "extends Node2D\nsignal defeated\nvar hp := 3\nvar comecou := 0\nvar reiniciou := 0\n" \
		+ "func comecar_luta(_arena) -> void:\n\tcomecou += 1\n" \
		+ "func reiniciar_luta() -> void:\n\treiniciou += 1\n"
	gs.reload()
	var n := Node2D.new()
	n.set_script(gs)
	n.name = "ChefeFalso"
	return n


func _test_arena() -> void:
	print("-- arena de chefe (arena_chefe.gd): fecha, prende a camera, reinicia e libera")
	Game.game_state = "playing"
	Game.room_goto(Game.LAB_LEVEL)
	await wait_level()
	var fox := get_tree().current_scene.get_node_or_null("Entidades/Raposa1")
	if fox != null:
		fox.queue_free()
	var chefe := _chefe_falso()
	get_tree().current_scene.add_child(chefe)
	var arena: Node2D = preload("res://scenes/arena_chefe.tscn").instantiate()
	arena.retangulo = Rect2(16, 144, 384, 216)
	arena.tipo_portao = "torre"
	arena.portoes_entrada = PackedVector2Array([Vector2(16, 336)])
	arena.portoes_saida = PackedVector2Array([Vector2(384, 336)])
	arena.chefe = chefe.get_path()
	arena.espera_saida = 10
	reset_player(Vector2(600, 288))  # fora da arena
	get_tree().current_scene.add_child(arena)
	await frames(3)
	var entrada: Node2D = arena._entrada[0]
	var saida: Node2D = arena._saida[0]
	check(arena.estado == "aberta" and not entrada.is_in_group("solid") and not Game.camera_limit.has_area(),
		"arena comeca aberta, portoes nao solidos e camera livre")

	reset_player(Vector2(70, 336))
	await frames(2)
	check(arena.estado == "fechando" and Game.camera_limit == arena.retangulo and Game.arena_chefe == arena,
		"pato inteiro dentro: a arena fecha e prende a camera (%s)" % arena.estado)
	check(entrada.is_in_group("solid") and Solids.hits(Solids.snapshot(get_tree()), Rect2(20, 300, 4, 4)),
		"portao fechando ja e solido")
	check(entrada.get_rect() == Rect2(16, 288, 16, 47),
		"caixa do portao da torre = desenho (sem a linha vazia de baixo): %s" % [entrada.get_rect()])
	var pf: Node2D = preload("res://scripts/arena_chefe.gd").Portao.new("fazenda", Vector2(0, 100))
	check(pf.get_rect() == Rect2(0, 56, 16, 44),
		"caixa do portao da fazenda sem os juncos do topo: %s" % [pf.get_rect()])
	pf.free()
	# fechamento natural: a camera desliza (pixels inteiros) e o que aparece de fora so diminui
	var fora_antes := INF
	var so_diminui := true
	var passo_max := 0.0
	var cam_antes := Game.cam_pos
	for i in 32:
		await frames(1)
		var c := Game.cam_pos
		var fora := maxf(0.0, 16.0 - c.x) + maxf(0.0, c.x + 384.0 - 400.0)
		fora += maxf(0.0, 144.0 - c.y) + maxf(0.0, c.y + 216.0 - 360.0)
		so_diminui = so_diminui and fora <= fora_antes and c == c.floor()
		passo_max = maxf(passo_max, (c - cam_antes).length())
		fora_antes = fora
		cam_antes = c
	check(so_diminui and passo_max < 24.0,
		"camera desliza ao fechar sem mostrar mais do que mostrava (maior passo %.0f px)" % passo_max)
	check(Game.cam_pos == Vector2(16, 144), "fim do deslize: camera presa ao retangulo (%s)" % [Game.cam_pos])
	await frames(8)
	check(arena.estado == "luta" and entrada.fechado() and saida.fechado() and chefe.comecou == 1,
		"portoes fechados (16 quadros) e o chefe avisado")
	await hold(KEY_LEFT, 60)
	check(player().position.x >= 40.0, "o portao da entrada segura o pato (x=%.0f)" % player().position.x)
	var preso := true
	for i in 30:
		await frames(1)
		preso = preso and Game.cam_pos.x >= 16.0 and Game.cam_pos.x + 384.0 <= 400.0 and Game.cam_pos.y >= 144.0
	check(preso, "a camera nunca mostra nada fora da arena")

	print("-- arena: pato reaparece fora (checkpoint) -> tudo volta ao estado de antes")
	reset_player(Vector2(504, 288))
	await frames(2)
	check(arena.estado == "aberta" and entrada.aberto() and saida.aberto() and not entrada.is_in_group("solid"),
		"portoes abertos na hora")
	check(not Game.camera_limit.has_area() and chefe.reiniciou == 1, "camera solta e chefe.reiniciar_luta()")

	print("-- arena: chefe derrotado -> saida abre e a camera volta suave")
	reset_player(Vector2(70, 336))
	await frames(45)
	check(arena.estado == "luta" and chefe.comecou == 2, "fecha de novo ao voltar")
	reset_player(Vector2(360, 336))
	await frames(5)
	chefe.hp = 0
	await frames(2)
	check(arena.estado == "vencida", "chefe com hp 0: arena vencida")
	var xs: Array = []
	for i in 120:
		await frames(1)
		if arena.estado == "liberada" or xs.size() > 0:
			xs.append(Game.cam_pos.x)
		if xs.size() > 60:
			break
	check(saida.aberto() and not saida.is_in_group("solid") and entrada.fechado(),
		"a saida abre (animacao reversa) e a entrada continua fechada")
	check(not Game.camera_limit.has_area() and Game.arena_chefe == null, "camera solta")
	var salto := 0.0
	var inteiro := true
	for i in range(1, xs.size()):
		salto = maxf(salto, absf(xs[i] - xs[i - 1]))
		inteiro = inteiro and xs[i] == floorf(xs[i])
	check(xs.size() > 40 and salto <= 8.0 and inteiro and xs[-1] == 170.0,
		"transicao suave em pixels inteiros (maior passo %.0f px, fim x=%s)" % [salto, xs[-1] if xs.size() > 0 else -1])

	print("-- arena: depois da vitoria o pato reaparece do lado de fora da entrada -> ela abre")
	reset_player(Vector2(4, 336))  # checkpoint antes da arena (respawn)
	await frames(2)
	check(entrada.aberto() and not entrada.is_in_group("solid"), "a entrada abre na hora: o pato nao fica preso")
	arena.queue_free()
	chefe.queue_free()
	await frames(1)

	print("-- arena estreita (352 px): respawn colado/acima da arena e morte depois da vitoria")
	var chefe2 := _chefe_falso()
	get_tree().current_scene.add_child(chefe2)
	var arena2: Node2D = preload("res://scenes/arena_chefe.tscn").instantiate()
	arena2.retangulo = Rect2(32, 144, 352, 216)
	arena2.tipo_portao = "torre"
	arena2.portoes_entrada = PackedVector2Array([Vector2(368, 336)])
	arena2.portoes_saida = PackedVector2Array([Vector2(32, 336)])
	arena2.chefe = chefe2.get_path()
	arena2.espera_saida = 60
	reset_player(Vector2(200, 336))
	get_tree().current_scene.add_child(arena2)
	await frames(45)
	check(arena2.estado == "luta" and Game.cam_pos.x == 16.0,
		"arena estreita fecha com a camera centrada (x=%s)" % Game.cam_pos.x)
	check(arena2._cortina.visible, "a sobra da tela vira parede (cortina) com a arena estreita fechada")
	reset_player(Vector2(200, 120))  # checkpoint logo acima da arena: teleporte para fora
	await frames(2)
	check(arena2.estado == "aberta" and chefe2.reiniciou == 1 and not arena2._cortina.visible,
		"respawn colado na arena (acima dela) reinicia a luta (%s)" % arena2.estado)
	reset_player(Vector2(200, 336))
	await frames(45)
	check(arena2.estado == "luta", "fecha de novo")
	chefe2.hp = 0
	await frames(2)
	check(arena2.estado == "vencida", "vencida")
	reset_player(Vector2(504, 288))  # morreu e reapareceu fora antes da saida abrir
	await frames(2)
	var tudo_aberto := true
	for g: Node2D in arena2._entrada + arena2._saida:
		tudo_aberto = tudo_aberto and g.aberto() and not g.is_in_group("solid")
	check(arena2.estado == "liberada" and tudo_aberto and not Game.camera_limit.has_area(),
		"morte depois da vitoria: entrada e saida abrem e a camera solta (%s)" % arena2.estado)
	arena2.queue_free()
	chefe2.queue_free()
	await frames(1)


func _toque(idx: int, pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = idx
	ev.position = pos
	ev.pressed = pressed
	Game.toque._input(ev)


func _arrasta(idx: int, pos: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = idx
	ev.position = pos
	Game.toque._input(ev)


func _test_toque() -> void:
	print("-- controles de toque (toque.gd)")
	var tq: Node2D = Game.toque
	check(tq != null, "Game cria os controles de toque")
	tq.forcar = true
	Game.game_state = "playing"
	Game.room_goto(Game.LAB_LEVEL)
	await wait_level()
	reset_player(Vector2(600, 288))
	_toque(0, Vector2(10, 10), true)  # um toque qualquer liga o modo toque
	_toque(0, Vector2(10, 10), false)
	await frames(2)
	check(tq.ativo() and tq.visible, "jogando com toque: controles aparecem")

	_toque(1, tq.PULO_C, true)
	check(Input.is_action_pressed("jump"), "botao A aperta pular")
	_toque(1, tq.PULO_C, false)
	check(not Input.is_action_pressed("jump"), "soltar o dedo solta pular")

	_toque(2, tq.PEGA_C, true)
	check(Input.is_action_pressed("grab") and not Input.is_action_pressed("jump"), "botao B aperta pegar")
	_toque(2, tq.PEGA_C, false)

	_toque(3, tq.DPAD_C + Vector2(-12, 0), true)
	check(Input.is_action_pressed("left") and not Input.is_action_pressed("right"), "direcional: esquerda")
	var x0 := player().position.x
	await frames(10)
	check(player().position.x < x0, "segurando esquerda o pato anda para a esquerda")
	_arrasta(3, tq.DPAD_C + Vector2(12, 0))
	check(Input.is_action_pressed("right") and not Input.is_action_pressed("left"),
		"arrastar o dedo para a direita troca a direcao")
	_arrasta(3, tq.DPAD_C + Vector2(10, -10))
	check(Input.is_action_pressed("right") and Input.is_action_pressed("up"), "diagonal direita+cima")
	_arrasta(3, tq.DPAD_C + Vector2(60, 0))
	check(Input.is_action_pressed("right"), "dedo que escorrega para fora continua no direcional")
	# dois dedos ao mesmo tempo: andar e pular
	_toque(4, tq.PULO_C + Vector2(3, 2), true)
	check(Input.is_action_pressed("right") and Input.is_action_pressed("jump"), "dois dedos: andar e pular juntos")
	_toque(4, tq.PULO_C, false)
	_toque(3, tq.DPAD_C, false)
	check(not Input.is_action_pressed("right") and not Input.is_action_pressed("up"), "soltar o direcional solta tudo")

	_toque(5, Vector2(192, 120), true)
	check(not Input.is_action_pressed("jump") and tq._dedos.is_empty(), "toque no meio da tela nao aperta nada")
	_toque(5, Vector2(192, 120), false)

	_toque(6, tq.PAUSA.get_center(), true)
	await frames(2)
	check(Game.game_state == "pause", "botao de pausa pausa o jogo")
	check(not tq.visible and not Input.is_action_pressed("pause"), "na pausa os controles somem e nada fica apertado")
	_toque(6, tq.PAUSA.get_center(), false)
	Game.ui_selection = 0
	await press_key(KEY_ENTER)
	await frames(2)
	check(Game.game_state == "playing" and not tq.usando_toque and not tq.visible,
		"apertar tecla esconde os controles de toque")
	_toque(0, Vector2(10, 10), true)
	_toque(0, Vector2(10, 10), false)
	await frames(2)
	check(tq.visible, "novo toque mostra os controles de novo")

	check(InputMap.action_get_events("jump").any(func(e): return e is InputEventJoypadButton),
		"controle (gamepad): pular mapeado")
	check(InputMap.action_get_events("left").any(func(e): return e is InputEventJoypadMotion),
		"controle: analogico mapeado")
	tq.forcar = false
	tq.usando_toque = false
	tq.soltar_tudo()


func _test_olhar() -> void:
	print("-- olhar para cima e para baixo")
	Game.game_state = "playing"
	Game.room_goto("tutorial")
	await wait_level()
	for e in get_tree().get_nodes_in_group("enemy"):
		e.set_physics_process(false)
		e.position = Vector2(-500, -500)
	reset_player(Vector2(200, 304))
	await frames(40)
	var p := player()
	var y0 := Game.cam_pos.y
	var pos0 := p.position
	Input.action_press("up")
	await frames(6)
	check(p._art.animation == "look_up" and Game.camera_olhar == 0.0, "segurar CIMA parado: o pato olha para cima")
	await frames(60)
	check(Game.camera_olhar < 0.0 and Game.cam_pos.y < y0 - 20.0,
		"segurando um pouco, a camera sobe (%.0f -> %.0f)" % [y0, Game.cam_pos.y])
	check(p.position == pos0, "olhar nao mexe o pato (%s -> %s)" % [pos0, p.position])
	Input.action_release("up")
	await frames(60)
	check(Game.camera_olhar == 0.0 and absf(Game.cam_pos.y - y0) < 2.0, "soltar: a camera volta")
	Input.action_press("down")
	await frames(70)
	# no fundo da sala a camera ja esta no limite de baixo: ela desce so ate onde a sala deixa
	var limite_baixo := float(Game.room_height) - Game.view_size.y
	check(p._art.animation == "look_down" and Game.camera_olhar > 0.0
		and (Game.cam_pos.y > y0 or absf(Game.cam_pos.y - limite_baixo) <= 1.0) and p.position == pos0,
		"segurar BAIXO: olha para baixo e a camera desce (%s, %.0f, %.0f -> %.0f, %s)"
		% [p._art.animation, Game.camera_olhar, y0, Game.cam_pos.y, p.position])
	Input.action_press("right")
	await frames(3)
	check(Game.camera_olhar == 0.0 and p._art.animation != "look_down", "andando nao olha")
	Input.action_release("right")
	Input.action_release("down")
	await frames(30)
	check(p._art.sprite_frames.get_frame_count("look_up") == 16
		and p._art.sprite_frames.get_frame_count("look_down") == 16, "olhar: 16 quadros cada")


func _test_teclas() -> void:
	print("-- trocar teclas (CONTROLES)")
	var tem := func(acao: String, k: int) -> bool:
		return InputMap.action_get_events(acao).any(func(e): return e is InputEventKey and e.physical_keycode == k)
	Game.teclas_padrao()
	check(tem.call("jump", KEY_SPACE) and tem.call("pause", KEY_ESCAPE) and tem.call("confirm", KEY_ENTER),
		"teclas padrao no InputMap")
	Game.definir_tecla("jump", 0, KEY_Z)
	check(tem.call("jump", KEY_Z) and not tem.call("jump", KEY_SPACE) and tem.call("confirm", KEY_Z),
		"PULAR trocado para Z (e Z confirma nos menus)")
	Game.definir_tecla("jump", 0, KEY_X)
	check(Game.teclas["jump"][0] == KEY_X and Game.teclas["grab"][0] == KEY_Z and tem.call("grab", KEY_Z)
		and not tem.call("grab", KEY_X), "tecla de outra acao: as duas trocam de lugar")
	var cfg := ConfigFile.new()
	cfg.load(Game.settings_path)
	check(cfg.get_value("teclas", "jump", []) == [KEY_X, KEY_K], "teclas salvas nas configuracoes")
	Game.teclas_padrao()
	Game._load_settings()
	check(Game.teclas["jump"][0] == KEY_X, "teclas voltam ao abrir o jogo")

	Game.go_to_menu()
	await wait_room("menu")
	Game.game_state = "controls"
	var labels := Game.ui_layout().map(func(r): return r["label"])
	check(labels.size() == 9 and labels[4] == "PULAR" and labels[-2] == "PADRÃO" and labels[-1] == "VOLTAR",
		"CONTROLES: 7 acoes, PADRÃO e VOLTAR (%s)" % [labels])
	Game.ui_selection = 4
	Game.tecla_coluna = 0
	await press_key(KEY_RIGHT)
	await frames(2)
	check(Game.tecla_coluna == 1, "direita escolhe a segunda coluna")
	await press_key(KEY_ENTER)
	await frames(2)
	check(Game.tecla_esperando == "jump", "ENTER: espera a tecla nova")
	await press_key(KEY_L)
	await frames(4)
	check(Game.tecla_esperando.is_empty() and Game.teclas["jump"][1] == KEY_L and tem.call("jump", KEY_L),
		"apertar L: PULAR ganha L na segunda coluna")
	check(Game.game_state == "controls" and Game.ui_selection == 4, "a tecla nova nao mexe no menu")
	await press_key(KEY_ENTER)
	await frames(2)
	await press_key(KEY_ESCAPE)
	await frames(4)
	check(Game.tecla_esperando.is_empty() and Game.teclas["jump"][1] == KEY_L and Game.game_state == "controls",
		"ESC cancela a troca sem sair da tela")
	Game.ui_selection = 7
	await press_key(KEY_ENTER)
	await frames(2)
	check(Game.teclas["jump"] == [KEY_SPACE, KEY_K] and tem.call("jump", KEY_SPACE), "PADRÃO volta as teclas de fabrica")
	await press_key(KEY_ESCAPE)
	await frames(2)
	check(Game.game_state == "settings", "ESC em CONTROLES volta as opcoes")
	check(Game.nome_tecla(KEY_SPACE) == "ESPAÇO" and Game.nome_tecla(KEY_A) == "A" and Game.nome_tecla(KEY_LEFT) == "SETA <",
		"nomes das teclas na tela")
	Game.game_state = "main"


func _test_flores_no_chao() -> void:
	print("-- flores sempre no chao (nenhuma flutuando)")
	var Solids = load("res://scripts/solids.gd")
	var no_ar := []
	var reais: Array = Game.levels
	for lv in ["tutorial", "fase1", "fase2", "fase3", "fase4", "fase5", "fase6", "fase7", "fase8",
			"fase_final", Game.LAB_LEVEL]:
		Game.game_state = "playing"
		Game.room_goto(lv)
		await wait_level()
		var snap = Solids.snapshot(get_tree())
		for fl in get_tree().get_nodes_in_group("flor"):
			var p: Vector2 = fl.position
			if not Solids.hits(snap, Rect2(p.x - 2.0, p.y, 4.0, 1.0)):
				no_ar.append("%s/%s" % [lv, fl.name])
			if fl.sprite.position.y != 0.0:
				no_ar.append("%s/%s balanca" % [lv, fl.name])
	check(no_ar.is_empty(), "todas as flores plantadas no chao %s" % [no_ar])


func _test_fazenda() -> void:
	print("-- fazenda: animais que conversam, plantacoes e porteira")
	Game.game_state = "playing"
	Game.room_goto("tutorial")
	await wait_level()
	for e in get_tree().get_nodes_in_group("enemy"):
		e.set_physics_process(false)
		e.position = Vector2(-500, -500)
	var bichos := get_tree().get_nodes_in_group("falante")
	check(bichos.size() == 4 and bichos.all(func(b): return b.falas.size() >= 2),
		"tutorial com 4 animais, cada um com falas (%d)" % bichos.size())
	var plantas := get_tree().get_nodes_in_group("sombra_cenario").size()
	check(node("Decoracao/Repolho1") != null and node("Decoracao/Espantalho1") != null, "plantacoes e espantalho na fazenda")
	var vaca: Node2D = node("Animais/Vaca")
	reset_player(vaca.position + Vector2(-20, 0))
	await frames(5)
	check(vaca.perto and vaca.fala_atual == -1 and not vaca.is_showing(), "perto da vaca: ela espera a conversa")
	await press_key(KEY_UP)
	await frames(15)
	check(vaca.fala_atual == 0 and vaca.is_showing() and vaca._lines()[0].begins_with("MUUU"),
		"CIMA conversa: primeira fala no balao")
	check(player()._art.animation != "look_up", "perto do animal CIMA nao vira olhar")
	await press_key(KEY_UP)
	await frames(5)
	check(vaca.fala_atual == 1, "CIMA de novo: proxima fala")
	reset_player(vaca.position + Vector2(-120, 0))
	await frames(20)
	check(not vaca.perto and vaca.fala_atual == -1 and not vaca.is_showing(), "afastou: a conversa recomeca")

	Game.room_goto("fase1")
	await wait_level()
	var porta: Node2D = node("Mecanicas/Porta1")
	check(porta.estilo_cerca and porta.is_in_group("solid") and porta._cerca_q == 0.0, "fase 1: porteira de cerca fechada")
	porta.set_active(true)
	await frames(30)
	check(porta.is_open and not porta.is_in_group("solid") and porta._cerca_q == 15.0, "o botao abre a porteira (ela afunda no chao)")
	check(get_tree().get_nodes_in_group("falante").size() >= 2, "animais na parte da fazenda da fase 1")
