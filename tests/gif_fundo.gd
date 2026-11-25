extends Node
## Grava quadros do pato andando (para montar GIFs do parallax, da luz e das sombras):
##   godot --path . res://tests/gif_fundo.tscn
## (precisa de janela). Salva em user://gif/<nome>/NNN.png; tools/arte/gif_jogo.py monta o GIF.

const CENAS := [["tutorial", Vector2(40, 304), 150], ["fase3", Vector2(40, 0), 90],
	["fase4", Vector2(40, 0), 150]]
const TAM := Vector2i(480, 270)


func _ready() -> void:
	if get_parent() != get_tree().root or name != "Gravador":
		var driver := Node.new()
		driver.name = "Gravador"
		driver.set_script(get_script())
		driver.process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().root.add_child.call_deferred(driver)
		return
	_run.call_deferred()


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func wait_ready() -> void:
	for i in 300:
		await frames(1)
		if not Game.transitioning and Game.in_level:
			return


func key(code: int, down: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = down
	Input.parse_input_event(ev)


func _run() -> void:
	Game.save_path = "user://gif_save.cfg"
	Game.settings_path = "user://gif_settings.cfg"
	for cena: Array in CENAS:
		Game.game_state = "playing"
		Game.room_goto(cena[0])
		await wait_ready()
		await frames(40)
		var dir := "user://gif/%s" % cena[0]
		DirAccess.make_dir_recursive_absolute(dir)
		key(KEY_RIGHT, true)
		var n := 0
		for f in int(cena[2]):
			if f % 30 == 20:
				key(KEY_SPACE, true)
			if f % 30 == 26:
				key(KEY_SPACE, false)
			await get_tree().process_frame
			if f % 3 == 0:
				await RenderingServer.frame_post_draw
				var img := get_viewport().get_texture().get_image()
				img.resize(TAM.x, TAM.y, Image.INTERPOLATE_NEAREST)
				img.save_png("%s/%03d.png" % [dir, n])
				n += 1
		key(KEY_RIGHT, false)
		key(KEY_SPACE, false)
		print("gravado: ", cena[0], " ", n, " quadros")
	get_tree().quit()
