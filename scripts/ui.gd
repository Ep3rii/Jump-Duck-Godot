extends Control
## Menus e HUD, desenhados em codigo numa grade de 320x180 (equivale ao Draw_64 do
## obj_game_manager). A fonte e o sprite spr_fontPixel (glifos 8x8, largura fixa).
## O layout dos botoes vem de Game.ui_layout(); aqui so se desenha.

const Sprites := preload("res://scripts/sprites.gd")

const COL_DARK := Color8(13, 80, 0)
const COL_MID := Color8(71, 144, 20)
const COL_LIGHT := Color8(95, 192, 26)
const COL_HI := Color8(133, 242, 56)
const COL_YELLOW := Color8(255, 210, 63)
const COL_YELLOW_DARK := Color8(122, 90, 0)
const COL_DIM := Color8(150, 190, 130)
const COL_HINT := Color8(215, 237, 183)

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


## Botao com o texto centralizado.
func _plain_button(r: Dictionary, on: bool, now: int) -> void:
	_button(r, on, now)
	var ty: float = (r["y1"] + r["y2"]) / 2.0
	if on:
		_text_plain(160, ty, r["label"], COL_YELLOW_DARK, CENTER)
	else:
		_text(160, ty, r["label"], Color.WHITE, CENTER)


func _panel(x1: float, y1: float, x2: float, y2: float) -> void:
	var fill := COL_DARK
	fill.a = 0.88
	_fill(x1, y1, x2, y2, fill)
	_outline(x1, y1, x2, y2, COL_HI)
	_outline(x1 + 1, y1 + 1, x2 - 1, y2 - 1, COL_MID)


func _title_banner(y: float, title: String) -> void:
	Sprites.draw_tl(self, "spr_banner02", 0, 160 - 64, y)
	_text_plain(160, y + 16, title, COL_YELLOW_DARK, CENTER)


func _volume_bar(x: float, ty: float, level: int, on: bool) -> void:
	for b in 10:
		var bar_col := COL_DARK
		if b < level:
			bar_col = COL_YELLOW_DARK if on else COL_YELLOW
		elif on:
			bar_col = Color8(200, 160, 40)
		_fill(x + b * 8, ty - 4, x + b * 8 + 5, ty + 3, bar_col)


# --------------------------------------------------------------------- Draw_64
func _draw() -> void:
	var w := 320
	var h := 180
	var cx := w * 0.5
	var state: String = Game.game_state
	var now := Time.get_ticks_msec()

	# ---------- HUD ----------
	if Game.in_level and (state == "playing" or state == "pause"
			or (state in ["settings", "controls"] and Game.pause_origin == "pause")):
		_draw_hud(w, h)

	# ---------- Menus ----------
	if state == "playing":
		return

	var dim := 0.55
	if state == "main":
		dim = 0.0
	elif state in ["settings", "controls", "levels", "credits"] and not Game.in_level:
		dim = 0.3
	if dim > 0.0:
		draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, dim), true)

	var layout: Array = Game.ui_layout()
	var sel: int = Game.ui_selection
	var generic_from := 0  # a partir de qual botao o laco generico do fim desenha

	match state:
		"main":
			Sprites.draw_tl(self, "spr_bannerVerdeGrande", 0, cx - 129, 6)
			_text(cx, 37, "JUMP DUCK", Color.WHITE, CENTER, 2.0)
			Sprites.draw(self, "spr_playerAnima", (now / 300) % Sprites.frame_count("spr_playerAnima"),
				40, 150, 2.0, 2.0)
			Sprites.draw(self, "spr_flor01", (now / 200) % Sprites.frame_count("spr_flor01"),
				w - 40, 150, 2.0, 2.0)
			_text_plain(cx, 175, "SETAS: ESCOLHER  ENTER: CONFIRMAR", COL_HINT, CENTER)

		"levels":
			_panel(30, 6, 290, 176)
			_title_banner(10, "FASES")
			for i in layout.size() - 1:
				var r: Dictionary = layout[i]
				var on := sel == i
				var ty: float = (r["y1"] + r["y2"]) / 2.0
				if r.has("room"):  # laboratorio (so em debug)
					_button(r, on, now)
					_text_plain(r["x1"] + 10, ty, r["label"] + " (DEBUG)",
						COL_YELLOW_DARK if on else COL_HINT, LEFT)
					continue
				var unlocked: bool = Game.is_level_unlocked(r["level"])
				_button(r, on, now)
				var fg := COL_YELLOW_DARK if on else (Color.WHITE if unlocked else COL_DIM)
				_text_plain(r["x1"] + 10, ty, "%d. %s" % [i + 1, r["label"]], fg, LEFT)
				var rec: Dictionary = Game.best.get(Game.LEVELS[r["level"]]["id"], {})
				if not rec.is_empty():
					_text_plain(r["x2"] - 60, ty, str(rec["score"]), fg, RIGHT)
					for s in 3:
						Sprites.draw(self, "spr_estrela", 0 if s < int(rec["stars"]) else 1,
							r["x2"] - 48 + s * 16, ty)
			generic_from = layout.size() - 1

		"credits":
			_panel(30, 6, 290, 176)
			_title_banner(10, "CRÉDITOS")
			_text(cx, 56, "JUMP DUCK", COL_YELLOW, CENTER)
			_text(cx, 68, "UM PATO EM BUSCA DE SUA AMADA", Color.WHITE, CENTER)
			_text(cx, 88, "CRIAÇÃO E DESENVOLVIMENTO", COL_YELLOW, CENTER)
			_text(cx, 100, "EUZÉBIO P. DA SILVA FILHO", Color.WHITE, CENTER)
			_text(cx, 120, "FEITO COM GODOT ENGINE", Color.WHITE, CENTER)
			_text(cx, 132, "MÚSICA: GRASSLANDS", Color.WHITE, CENTER)

		"controls":
			_panel(30, 6, 290, 176)
			_title_banner(10, "CONTROLES")
			var rows := [["MOVER", "SETAS OU A/D"], ["PULAR", "ESPAÇO"], ["PULO DUPLO", "ESPAÇO NO AR"],
				["PEGAR/ARREMESSAR", "X OU J"], ["POUSAR CAIXA", "BAIXO + X"],
				["ESCALAR CIPÓ", "CIMA/BAIXO"], ["DERROTAR INIMIGO", "PULE EM CIMA"], ["PAUSAR", "ESC"]]
			for i in rows.size():
				var y := 48 + i * 11
				_text(44, y, rows[i][0], Color.WHITE, LEFT)
				_text(276, y, rows[i][1], COL_YELLOW, RIGHT)
			_text_plain(cx, 139, "MENUS: SETAS, ENTER OU MOUSE", COL_HINT, CENTER)

		"settings":
			_panel(30, 6, 290, 176)
			_title_banner(10, "CONFIGURAÇÕES")
			_draw_settings_rows(layout, sel, now)
			generic_from = Game.SETTINGS_ADJUST_ROWS
			if sel == 1 and Game.screen_mode == "fullscreen":
				_text_plain(cx, 168, "RESOLUÇÃO: SOMENTE EM JANELA", Color.WHITE, CENTER)
			else:
				_text_plain(cx, 168, "ESQ/DIR: ALTERAR  ESC: VOLTAR", COL_HINT, CENTER)

		"pause":
			_panel(70, 22, 250, 156)
			_title_banner(28, "PAUSADO")

		"complete":
			_panel(50, 8, 270, 176 if layout.size() > 2 else 170)
			_title_banner(12, "FASE CONCLUÍDA")
			_draw_result(now)

		"gameover":
			Sprites.draw_tl(self, "spr_gameOver", (now / 450) % 2, cx - 32, 8, 0.5)
			_text(cx, 82, "FIM DE JOGO", Color.WHITE, CENTER)
			_text(cx, 96, "FLORES: %d/%d" % [Game.current_collectibles, Game.total_collectibles],
				COL_YELLOW, CENTER)

	for i in range(generic_from, layout.size()):
		_plain_button(layout[i], sel == i, now)


func _draw_hud(w: int, h: int) -> void:
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


## Linhas ajustaveis das configuracoes: TELA, JANELA (texto) e MUSICA, EFEITOS (barras).
func _draw_settings_rows(layout: Array, sel: int, now: int) -> void:
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
	var values := [mode_text, resolution_text]
	var volumes := [Game.music_volume, Game.sfx_volume]
	for i in Game.SETTINGS_ADJUST_ROWS:
		var r: Dictionary = layout[i]
		var on := sel == i
		var ty: float = (r["y1"] + r["y2"]) / 2.0
		var fg := COL_YELLOW_DARK if on else Color.WHITE
		if i == 1 and Game.screen_mode == "fullscreen":
			fg = COL_YELLOW_DARK if on else COL_DIM
		_button(r, on, now)
		_text_plain(r["x1"] + 10, ty, r["label"], fg, LEFT)
		_text_plain(r["x1"] + 76, ty, "<", fg, LEFT)
		_text_plain(r["x2"] - 18, ty, ">", fg, LEFT)
		var mid: float = (r["x1"] + 84 + r["x2"] - 18) / 2.0
		if i < 2:
			_text_plain(mid, ty, values[i], fg, CENTER)
		else:
			_volume_bar(mid - 39.0, ty, volumes[i - 2], on)


## Tela de fase concluida: recorde, estrelas, tempo, flores e pontos.
func _draw_result(now: int) -> void:
	var cx := 160.0
	var result := {}
	if Game.level_history.size() > 0:
		result = Game.level_history[Game.level_history.size() - 1]
	if result.is_empty():
		return
	if Game.last_result_is_record:
		var blink := (now / 300) % 2 == 0
		_text(cx, 49, "NOVO RECORDE!", COL_YELLOW if blink else Color.WHITE, CENTER)
	var stars := Game.stars_for(result["score"])
	for s in 3:
		var bounce := 0.0
		if s < stars:
			bounce = floorf(sin(now / 220.0 + s) * 1.5)
		Sprites.draw(self, "spr_estrela", 0 if s < stars else 1,
			cx - 40 + s * 40, 70 + bounce, 2.0, 2.0)
	_text(cx, 92, "TEMPO: %.1fS  +%d" % [result["time_seconds"], result["time_points"]],
		Color.WHITE, CENTER)
	_text(cx, 104, "FLORES: %d/%d  +%d" % [result["collectibles"],
		result["collectible_total"], result["collectible_points"]], Color.WHITE, CENTER)
	# Pontos da fase (0..100); com mais de uma fase jogada, mostra tambem o total do jogo.
	if Game.level_history.size() > 1:
		_text(cx, 116, "FASE: %d/100  JOGO: %d" % [result["score"], Game.total_score],
			COL_YELLOW, CENTER)
	else:
		_text(cx, 116, "TOTAL: %d / 100" % result["score"], COL_YELLOW, CENTER)
