extends Control
## Menus e HUD, desenhados em codigo numa grade de 320x180 (equivale ao Draw_64 do
## obj_game_manager). A fonte e a de pixel_font.gd (assets/sprites/arte/fonte.png).
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

const PixelFont := preload("res://scripts/pixel_font.gd")
const Chave := preload("res://scripts/chave.gd")

const LEFT := PixelFont.LEFT
const CENTER := PixelFont.CENTER
const RIGHT := PixelFont.RIGHT


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


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
	PixelFont.draw_plain(self, x, y, s, col, halign, scale_)


## ui_text: texto com sombra escura deslocada em 'scale_' pixels.
func _text(x: float, y: float, s: String, col: Color, halign: int, scale_: float = 1.0) -> void:
	_text_plain(x + scale_, y + scale_, s, COL_DARK, halign, scale_)
	_text_plain(x, y, s, col, halign, scale_)


## Retangulo de cantos arredondados (em degraus de pixel), incluindo x2/y2.
func _round(x1: float, y1: float, x2: float, y2: float, col: Color, r: int = 2) -> void:
	if y2 - y1 < r * 2.0 or x2 - x1 < r * 2.0:
		_fill(x1, y1, x2, y2, col)
		return
	_fill(x1, y1 + r, x2, y2 - r, col)
	for i in r:
		var inset := float(r - i)
		_fill(x1 + inset, y1 + i, x2 - inset, y1 + i, col)
		_fill(x1 + inset, y2 - i, x2 - inset, y2 - i, col)


## Botao "almofadinha": arredondado, com sombra embaixo; o selecionado fica amarelo e ganha
## uma florzinha pulando ao lado.
func _button(r: Dictionary, selected: bool, now: int) -> void:
	var x1: float = r["x1"]
	var y1: float = r["y1"]
	var x2: float = r["x2"]
	var y2: float = r["y2"]
	var small := y2 - y1 < 13.0
	var rad := 1 if small else 2
	var drop := 1.0 if small else 2.0
	_round(x1, y1 + drop, x2, y2 + drop, COL_DARK, rad)  # sombra
	_round(x1, y1, x2, y2, COL_YELLOW_DARK if selected else COL_DARK, rad)  # borda
	_round(x1 + 1, y1 + 1, x2 - 1, y2 - 1, COL_YELLOW if selected else COL_MID, rad)
	_fill(x1 + 1 + rad, y1 + 1, x2 - 1 - rad, y1 + 1, Color(1, 1, 1, 0.9) if selected else COL_LIGHT)
	if selected:
		var hop := floorf(absf(sin(now / 180.0)) * 3.0)
		var fs := 0.75 if small else 1.0
		Sprites.draw(self, "spr_flor01", (now / 200) % Sprites.frame_count("spr_flor01"),
			x1 - 10.0, (y1 + y2) / 2.0 + 7.0 * fs - hop, fs, fs)


## Botao com o texto centralizado (texto em dobro nos botoes marcados com "big").
func _plain_button(r: Dictionary, on: bool, now: int) -> void:
	_button(r, on, now)
	var ty: float = (r["y1"] + r["y2"]) / 2.0
	var tx: float = (r["x1"] + r["x2"] + 1.0) / 2.0
	var sc := 2.0 if r.get("big", false) else 1.0
	if on:
		_text_plain(tx, ty, r["label"], COL_YELLOW_DARK, CENTER, sc)
	else:
		_text(tx, ty, r["label"], Color.WHITE, CENTER, sc)


func _panel(x1: float, y1: float, x2: float, y2: float) -> void:
	var fill := COL_DARK
	fill.a = 0.9
	_round(x1, y1, x2, y2, COL_HI, 3)
	_round(x1 + 1, y1 + 1, x2 - 1, y2 - 1, COL_MID, 3)
	_round(x1 + 2, y1 + 2, x2 - 2, y2 - 2, Color8(13, 80, 0), 2)
	_round(x1 + 2, y1 + 2, x2 - 2, y2 - 2, fill, 2)


## Titulo da tela: plaquinha amarela arredondada.
func _title_banner(y: float, title: String) -> void:
	var half := PixelFont.width(title) / 2.0 + 12.0
	_round(160 - half, y + 6, 160 + half, y + 24, COL_DARK, 3)
	_round(160 - half, y + 4, 160 + half, y + 22, COL_YELLOW_DARK, 3)
	_round(160 - half + 1, y + 5, 160 + half - 1, y + 21, COL_YELLOW, 3)
	_fill(160 - half + 4, y + 5, 160 + half - 4, y + 5, Color(1, 1, 1, 0.9))
	_text_plain(160, y + 13, title, COL_YELLOW_DARK, CENTER)


## Titulo do jogo: letras grandes balancando em onda ("JUMP" branco, "DUCK" amarelo).
func _game_title(cx: float, y: float, now: int) -> void:
	var title := "JUMP DUCK"
	var sc := 3.0
	var x := cx - PixelFont.width(title, sc) / 2.0
	for i in title.length():
		var ch := title[i]
		if ch != " ":
			var wave := floorf(sin(now / 260.0 + i * 0.7) * 2.0)
			var col := Color.WHITE if i < 4 else COL_YELLOW
			# contorno escuro em volta (le bem em cima das nuvens) e sombra embaixo
			for o in [Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0),
					Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1), Vector2(0, 2), Vector2(1, 2), Vector2(-1, 2),
					Vector2(0, 3)]:
				_text_plain(x + o.x, y + wave + o.y, ch, COL_DARK, LEFT, sc)
			_text_plain(x, y + wave, ch, col, LEFT, sc)
		x += (PixelFont.width(ch, sc) + PixelFont.SPACING * sc)


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
			or (state in ["settings", "controls", "credits"] and Game.pause_origin == "pause")):
		_draw_hud(w, h)

	# ---------- Menus ----------
	if state == "playing" or state == "cutscene":
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
			# o cenario (chao, pato andando, moinho) e da cena do menu (menu.gd)
			_game_title(cx, 28, now)

		"levels":
			_panel(30, 2, 290, 178)
			_title_banner(2, "FASES")
			for i in layout.size() - 1:
				var r: Dictionary = layout[i]
				var on := sel == i
				var ty: float = (r["y1"] + r["y2"]) / 2.0
				if r.has("room"):  # laboratorio (so em debug)
					_button(r, on, now)
					_text_plain(r["x1"] + 10, ty + 1, r["label"] + " (TESTE)",
						COL_YELLOW_DARK if on else COL_HINT, LEFT)
					continue
				var unlocked: bool = Game.is_level_unlocked(r["level"])
				_button(r, on, now)
				var fg := COL_YELLOW_DARK if on else (Color.WHITE if unlocked else COL_DIM)
				_text_plain(r["x1"] + 10, ty + 1, "%d. %s" % [i + 1, r["label"]], fg, LEFT)
				var rec: Dictionary = Game.best.get(Game.levels[r["level"]]["id"], {})
				if not rec.is_empty():
					_text_plain(r["x2"] - 52, ty + 1, str(rec["score"]), fg, RIGHT)
					for s in 3:
						Sprites.draw(self, "spr_estrela", 0 if s < int(rec["stars"]) else 1,
							r["x2"] - 40 + s * 12, ty, 0.7, 0.7)
			generic_from = layout.size() - 1

		"credits":
			_panel(30, 6, 290, 176)
			_title_banner(10, "CRÉDITOS")
			_text(cx, 48, "JUMP DUCK", COL_YELLOW, CENTER, 2.0)
			_text(cx, 66, "UM PATO EM BUSCA DO SEU AMOR", Color.WHITE, CENTER)
			_text(cx, 86, "FEITO POR", COL_YELLOW, CENTER)
			_text(cx, 98, "EUZÉBIO P. DA SILVA FILHO", Color.WHITE, CENTER)
			_text(cx, 116, "MÚSICA: GRASSLANDS", Color.WHITE, CENTER)
			_text(cx, 128, "MOTOR: GODOT", Color.WHITE, CENTER)
			if Game.credits_after_ending:
				_text(cx, 143, "FIM! OBRIGADO POR JOGAR!", COL_HI, CENTER)

		"controls":
			_panel(30, 6, 290, 176)
			_title_banner(10, "CONTROLES")
			var rows := [["ANDAR", "SETAS OU A E D"], ["PULAR", "ESPAÇO"],
				["PULO DUPLO", "ESPAÇO NO AR"], ["PEGAR E JOGAR A CAIXA", "X OU J"],
				["SOLTAR A CAIXA", "BAIXO + X"], ["SUBIR NO CIPÓ", "CIMA E BAIXO"],
				["MERGULHAR", "BAIXO NA ÁGUA"], ["VENCER UM INIMIGO", "PULE EM CIMA"],
				["PAUSAR", "ESC"]]
			for i in rows.size():
				var y := 42 + i * 11
				_text(52, y, rows[i][0], Color.WHITE, LEFT)
				_text(268, y, rows[i][1], COL_YELLOW, RIGHT)
			_text_plain(cx, 143, "NOS MENUS: SETAS, ENTER OU MOUSE", COL_HINT, CENTER)

		"settings":
			_panel(30, 6, 290, 176)
			_title_banner(10, "OPÇÕES")
			_draw_settings_rows(layout, sel, now)
			generic_from = Game.SETTINGS_ADJUST_ROWS
			if sel == 1 and Game.screen_mode == "fullscreen":
				_text_plain(cx, 165, "O TAMANHO SÓ MUDA NO MODO JANELA", Color.WHITE, CENTER)
			else:
				_text_plain(cx, 165, "ESQUERDA E DIREITA MUDAM   ESC VOLTA", COL_HINT, CENTER)

		"pause":
			_panel(70, 22, 250, 156)
			_title_banner(28, "PAUSA")

		"complete":
			_panel(50, 8, 270, 176 if layout.size() > 2 else 170)
			_title_banner(12, "VOCÊ CONSEGUIU!")
			_draw_result(now)

		"gameover":
			var wob := floorf(sin(now / 200.0) * 2.0)
			_text(cx, 46 + wob, "QUACK!", COL_YELLOW, CENTER, 4.0)
			_text(cx, 82, "NÃO FOI DESSA VEZ...", Color.WHITE, CENTER, 1.0)
			_text(cx, 98, "FLORES: %d DE %d" % [Game.current_collectibles, Game.total_collectibles],
				COL_YELLOW, CENTER)

	for i in range(generic_from, layout.size()):
		_plain_button(layout[i], sel == i, now)


func _draw_hud(w: int, h: int) -> void:
	var hud_bg := COL_DARK
	hud_bg.a = 0.6
	var hearts_x2 := 5 + Game.max_lives * 18
	_fill(2, 2, hearts_x2, 21, hud_bg)
	_fill(w - 76, 2, w - 2, 29, hud_bg)
	_outline(2, 2, hearts_x2, 21, COL_MID)
	_outline(w - 76, 2, w - 2, 29, COL_MID)

	if Game.debug_invincible:
		_text(4, h - 8, "TESTE: INVENCÍVEL", COL_YELLOW, LEFT)

	if Game.boss_visible and Game.boss_max > 0:
		# barra de vida do chefe, no topo entre os coracoes e as flores (embaixo fica a agua)
		_fill(66, 2, 222, 23, hud_bg)
		_outline(66, 2, 222, 23, COL_MID)
		_text(144, 9, Game.boss_label, Color.WHITE, CENTER)
		var seg_w := floorf(146.0 / Game.boss_max)
		for i in Game.boss_max:
			var x := 72.0 + i * seg_w
			_fill(x, 15, x + seg_w - 3, 20, COL_DARK)
			if i < Game.boss_hp:
				_fill(x + 1, 16, x + seg_w - 4, 19, Color8(220, 60, 50))

	var row_y := 23.0  # proxima linha livre embaixo dos coracoes
	if Game.keys > 0:
		# chaves no bolso: uma chave desenhada por unidade (cabem 4)
		_fill(2, row_y, 55, row_y + 11, hud_bg)
		_outline(2, row_y, 55, row_y + 11, COL_MID)
		for i in mini(Game.keys, 4):
			Chave.draw_key(self, Vector2(10 + i * 13, row_y + 5.5))
		row_y += 13.0

	if Game.show_air:
		# folego: 5 bolhas que somem conforme o ar acaba (piscam no fim)
		_fill(2, row_y, 55, row_y + 11, hud_bg)
		_outline(2, row_y, 55, row_y + 11, COL_MID)
		var left := ceili(Game.air_ratio * 5.0 - 0.001)
		var blink := Game.air_ratio < 0.25 and (Time.get_ticks_msec() / 150) % 2 == 0
		for i in 5:
			var c := Vector2(9 + i * 10, row_y + 5.5)
			if i < left and not blink:
				draw_circle(c, 3.5, Color8(200, 235, 255))
				draw_circle(c + Vector2(-1, -1), 1.0, Color.WHITE)
			else:
				draw_arc(c, 3.0, 0.0, TAU, 12, Color8(70, 110, 140), 1.0)

	for heart in Game.max_lives:
		var heart_sprite := "spr_vidaCheia" if heart < Game.player_lives else "spr_vidaVazia"
		Sprites.draw_tl(self, heart_sprite, 0, 5 + heart * 18, 5, 0.5)

	var sec := floori(Game.level_elapsed_seconds)
	var sec_text := str(sec % 60)
	if sec % 60 < 10:
		sec_text = "0" + sec_text
	_text(w - 71, 10, "FLORES %d/%d" % [Game.current_collectibles, Game.total_collectibles],
		Color.WHITE, LEFT)
	_text(w - 71, 22, "TEMPO %d:%s" % [sec / 60, sec_text], COL_YELLOW, LEFT)


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
		_text(cx, 47, "NOVO RECORDE!", COL_YELLOW if blink else Color.WHITE, CENTER)
	var stars := Game.stars_for(result["score"])
	for s in 3:
		var bounce := 0.0
		if s < stars:
			bounce = floorf(sin(now / 220.0 + s) * 1.5)
		Sprites.draw(self, "spr_estrela", 0 if s < stars else 1,
			cx - 40 + s * 40, 70 + bounce, 2.0, 2.0)
	_text(cx, 90, "TEMPO: %.1f S   +%d" % [result["time_seconds"], result["time_points"]],
		Color.WHITE, CENTER)
	_text(cx, 101, "FLORES: %d DE %d   +%d" % [result["collectibles"],
		result["collectible_total"], result["collectible_points"]], Color.WHITE, CENTER)
	# Pontos da fase (0..100); com mais de uma fase jogada, mostra tambem o total do jogo.
	if Game.level_history.size() > 1:
		_text(cx, 113, "PONTOS: %d DE 100   TOTAL: %d" % [result["score"], Game.total_score],
			COL_YELLOW, CENTER)
	else:
		_text(cx, 113, "PONTOS: %d DE 100" % result["score"], COL_YELLOW, CENTER)
