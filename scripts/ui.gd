extends Control
## Menus e HUD, desenhados em codigo numa grade de 320x180 (equivale ao Draw_64 do
## obj_game_manager). A fonte e o sprite spr_fontPixel (glifos 8x8, largura fixa).

const Sprites := preload("res://scripts/sprites.gd")

const COL_DARK := Color8(13, 80, 0)
const COL_MID := Color8(71, 144, 20)
const COL_LIGHT := Color8(95, 192, 26)
const COL_HI := Color8(133, 242, 56)
const COL_YELLOW := Color8(255, 210, 63)
const COL_YELLOW_DARK := Color8(122, 90, 0)

const LEFT := 0
const CENTER := 1
const RIGHT := 2

# Ordem dos glifos no sprite: ASCII 32..126 + acentos (mesma ordem do GameMaker).
const ACCENTS := [193, 192, 194, 195, 201, 202, 205, 211, 212, 213, 218, 199,
	225, 224, 226, 227, 233, 234, 237, 243, 244, 245, 250, 231]

var _glyphs := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var index := 0
	for c in range(32, 127):
		_glyphs[char(c)] = index
		index += 1
	for c: int in ACCENTS:
		_glyphs[char(c)] = index
		index += 1


func _process(_delta: float) -> void:
	queue_redraw()


# ---------------------------------------------------------------- primitivas
## draw_rectangle(x1, y1, x2, y2, false) do GameMaker: inclui x2/y2.
func _fill(x1: float, y1: float, x2: float, y2: float, col: Color) -> void:
	draw_rect(Rect2(x1, y1, x2 - x1 + 1.0, y2 - y1 + 1.0), col, true)


func _outline(x1: float, y1: float, x2: float, y2: float, col: Color) -> void:
	_fill(x1, y1, x2, y1, col)
	_fill(x1, y2, x2, y2, col)
	_fill(x1, y1, x1, y2, col)
	_fill(x2, y1, x2, y2, col)


## ui_text_plain: texto sem sombra. (x, y) = ponto de ancoragem, centrado na vertical.
func _text_plain(x: float, y: float, s: String, col: Color, halign: int, scale_: float = 1.0) -> void:
	var w := s.length() * 8.0 * scale_
	var left := x
	if halign == CENTER:
		left = x - w * 0.5
	elif halign == RIGHT:
		left = x - w
	var top := y - 4.0 * scale_
	left = floorf(left + 0.5)
	top = floorf(top + 0.5)
	var strip := Sprites.strip("spr_fontPixel")
	for i in s.length():
		var g: int = _glyphs.get(s[i], -1)
		if g < 0:
			continue
		draw_texture_rect_region(strip,
			Rect2(left + i * 8.0 * scale_, top, 8.0 * scale_, 8.0 * scale_),
			Rect2(g * 8.0, 0.0, 8.0, 8.0), col)


## ui_text: texto com sombra escura deslocada em 'scale_' pixels.
func _text(x: float, y: float, s: String, col: Color, halign: int, scale_: float = 1.0) -> void:
	_text_plain(x + scale_, y + scale_, s, COL_DARK, halign, scale_)
	_text_plain(x, y, s, col, halign, scale_)


func _button(r: Dictionary, selected: bool, now: int) -> void:
	var x1: float = r["x1"]
	var y1: float = r["y1"]
	var x2: float = r["x2"]
	var y2: float = r["y2"]
	_fill(x1, y1, x2, y2, COL_DARK)
	_fill(x1 + 1, y1 + 1, x2 - 1, y2 - 1, COL_YELLOW if selected else COL_MID)
	_fill(x1 + 1, y1 + 1, x2 - 1, y1 + 2, Color.WHITE if selected else COL_LIGHT)
	_fill(x1 + 1, y2 - 2, x2 - 1, y2 - 1, COL_YELLOW_DARK if selected else COL_DARK)
	if selected:
		var bob := floorf(sin(now / 140.0) * 1.5 + 1.5)
		_text(x1 - 9 + bob, (y1 + y2) / 2.0, ">", Color.WHITE, CENTER)
		_text(x2 + 10 - bob, (y1 + y2) / 2.0, "<", Color.WHITE, CENTER)


func _panel(x1: float, y1: float, x2: float, y2: float) -> void:
	var fill := COL_DARK
	fill.a = 0.88
	_fill(x1, y1, x2, y2, fill)
	_outline(x1, y1, x2, y2, COL_HI)
	_outline(x1 + 1, y1 + 1, x2 - 1, y2 - 1, COL_MID)


# --------------------------------------------------------------------- Draw_64
func _draw() -> void:
	var w := 320
	var h := 180
	var cx := w * 0.5
	var state: String = Game.game_state
	var now := Time.get_ticks_msec()

	# ---------- HUD ----------
	if Game.in_level and (state == "playing" or state == "pause"
			or (state == "settings" and Game.pause_origin == "pause")):
		var hud_bg := COL_DARK
		hud_bg.a = 0.6
		var hearts_x2 := 5 + Game.max_lives * 18
		_fill(2, 2, hearts_x2, 21, hud_bg)
		_fill(w - 92, 2, w - 2, 29, hud_bg)
		_outline(2, 2, hearts_x2, 21, COL_MID)
		_outline(w - 92, 2, w - 2, 29, COL_MID)

		if Game.debug_invincible:
			_text(4, h - 8, "DEBUG: INVENCÍVEL", COL_YELLOW, LEFT)

		for heart in Game.max_lives:
			var heart_sprite := "spr_vidaCheia" if heart < Game.player_lives else "spr_vidaVazia"
			Sprites.draw_tl(self, heart_sprite, 0, 5 + heart * 18, 5, 0.5)

		var sec := floori(Game.level_elapsed_seconds)
		var sec_text := str(sec % 60)
		if sec % 60 < 10:
			sec_text = "0" + sec_text
		_text(w - 88, 10, "FLORES %d/%d" % [Game.current_collectibles, Game.total_collectibles],
			Color.WHITE, LEFT)
		_text(w - 88, 22, "TEMPO %d:%s" % [sec / 60, sec_text], COL_YELLOW, LEFT)

	# ---------- Menus ----------
	if state == "playing":
		return

	var dim := 0.55
	if state == "main":
		dim = 0.0
	if state == "settings" and Game.pause_origin == "main":
		dim = 0.3
	if dim > 0.0:
		draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, dim), true)

	var layout: Array = Game.ui_layout()
	var sel: int = Game.ui_selection

	match state:
		"main":
			Sprites.draw_tl(self, "spr_bannerVerdeGrande", 0, cx - 129, 6)
			_text(cx, 37, "JUMP DUCK", Color.WHITE, CENTER, 2.0)
			_text(cx, 80, "AVENTURA EM PLATAFORMAS", Color.WHITE, CENTER)
			Sprites.draw(self, "spr_playerAnima", (now / 300) % Sprites.frame_count("spr_playerAnima"),
				40, 150, 2.0, 2.0)
			Sprites.draw(self, "spr_flor01", (now / 200) % Sprites.frame_count("spr_flor01"),
				w - 40, 150, 2.0, 2.0)
			_text(cx, 170, "SETAS MOVER  ESPAÇO PULAR  ESC PAUSA", Color.WHITE, CENTER)

		"settings":
			_panel(30, 6, 290, 168)
			Sprites.draw_tl(self, "spr_banner02", 0, cx - 64, 10)
			_text_plain(cx, 26, "CONFIGURAÇÕES", COL_YELLOW_DARK, CENTER)
			var mode_text := "JANELA"
			if Game.screen_mode == "fullscreen":
				mode_text = "TELA CHEIA"
			if Game.screen_mode == "borderless":
				mode_text = "SEM BORDAS"
			var resolution_text := "1920X1080"
			if Game.resolution_index == 0:
				resolution_text = "1280X720"
			if Game.resolution_index == 1:
				resolution_text = "1600X900"
			var values := [mode_text, resolution_text, ""]
			for i in 3:
				var r: Dictionary = layout[i]
				var on := sel == i
				var ty: float = (r["y1"] + r["y2"]) / 2.0
				var fg := COL_YELLOW_DARK if on else Color.WHITE
				if i == 1 and Game.screen_mode == "fullscreen":
					fg = COL_YELLOW_DARK if on else Color8(150, 190, 130)
				_button(r, on, now)
				_text_plain(r["x1"] + 10, ty, r["label"], fg, LEFT)
				_text_plain(r["x1"] + 68, ty, "<", fg, LEFT)
				_text_plain(r["x2"] - 76 + 66, ty, ">", fg, LEFT)
				if i < 2:
					_text_plain((r["x1"] + 68 + r["x2"] - 10) / 2.0, ty, values[i], fg, CENTER)
				else:
					var bar_x: float = (r["x1"] + 68 + r["x2"] - 10) / 2.0 - 39.0
					for b in 10:
						var bar_col := COL_DARK
						if b < Game.volume_level:
							bar_col = COL_YELLOW_DARK if on else COL_YELLOW
						elif on:
							bar_col = Color8(200, 160, 40)
						_fill(bar_x + b * 8, ty - 4, bar_x + b * 8 + 5, ty + 3, bar_col)
			var back: Dictionary = layout[3]
			_button(back, sel == 3, now)
			_text_plain(cx, (back["y1"] + back["y2"]) / 2.0, back["label"],
				COL_YELLOW_DARK if sel == 3 else Color.WHITE, CENTER)
			if sel == 1 and Game.screen_mode == "fullscreen":
				_text_plain(cx, 158, "RESOLUÇÃO: SOMENTE EM JANELA", Color.WHITE, CENTER)
			else:
				_text_plain(cx, 158, "ESQ/DIR: ALTERAR  ESC: VOLTAR", Color8(215, 237, 183), CENTER)

		"pause":
			_panel(70, 22, 250, 150)
			Sprites.draw_tl(self, "spr_banner02", 0, cx - 64, 28)
			_text_plain(cx, 44, "PAUSADO", COL_YELLOW_DARK, CENTER)

		"complete":
			_panel(50, 8, 270, 176 if layout.size() > 2 else 170)
			Sprites.draw_tl(self, "spr_banner02", 0, cx - 64, 12)
			_text_plain(cx, 28, "FASE CONCLUÍDA", COL_YELLOW_DARK, CENTER)
			var result := {}
			if Game.level_history.size() > 0:
				result = Game.level_history[Game.level_history.size() - 1]
			var stars := Game.stars_for(result.get("score", 0))
			for s in 3:
				var bounce := 0.0
				if s < stars:
					bounce = floorf(sin(now / 220.0 + s) * 1.5)
				Sprites.draw(self, "spr_estrela", 0 if s < stars else 1,
					cx - 40 + s * 40, 66 + bounce, 2.0, 2.0)
			if not result.is_empty():
				_text(cx, 90, "TEMPO: %.1fS  +%d" % [result["time_seconds"], result["time_points"]],
					Color.WHITE, CENTER)
				_text(cx, 103, "FLORES: %d/%d  +%d" % [result["collectibles"],
					result["collectible_total"], result["collectible_points"]], Color.WHITE, CENTER)
				# Pontos da fase (0..100); com mais de uma fase jogada, mostra tambem o total do jogo.
				if Game.level_history.size() > 1:
					_text(cx, 116, "FASE: %d/100  JOGO: %d" % [result["score"], Game.total_score],
						COL_YELLOW, CENTER)
				else:
					_text(cx, 116, "TOTAL: %d / 100" % result["score"], COL_YELLOW, CENTER)

		"gameover":
			Sprites.draw_tl(self, "spr_gameOver", (now / 450) % 2, cx - 32, 8, 0.5)
			_text(cx, 82, "FIM DE JOGO", Color.WHITE, CENTER)
			_text(cx, 96, "FLORES: %d/%d" % [Game.current_collectibles, Game.total_collectibles],
				COL_YELLOW, CENTER)

	if state != "settings":
		for i in layout.size():
			var r: Dictionary = layout[i]
			var on := sel == i
			_button(r, on, now)
			var ty: float = (r["y1"] + r["y2"]) / 2.0
			if on:
				_text_plain(cx, ty, r["label"], COL_YELLOW_DARK, CENTER)
			else:
				_text(cx, ty, r["label"], Color.WHITE, CENTER)
