extends Control
## Menus e HUD, desenhados em codigo (equivale ao Draw_64 do obj_game_manager). A tela tem
## 384x216 pixels do jogo (Game.TELA): o HUD usa os cantos dela e os menus continuam numa grade
## de 320x180, centrada (Game.UI_OFS), sempre em pixels inteiros. A fonte e a de pixel_font.gd (assets/sprites/arte/fonte.png).
## O layout dos botoes vem de Game.ui_layout(); aqui so se desenha.

const Sprites := preload("res://scripts/sprites.gd")

## Cores da UI, todas da paleta Endesga 32 (a mesma da arte; ver tools/arte/pixelkit.py).
const COL_DARK := Color("193c3e")  # fundo dos paineis e do HUD, sombra do texto
const COL_MID := Color("3e8948")  # botao, moldura dos paineis (o verde do cenario)
const COL_LIGHT := Color("63c74d")  # brilho do botao (a grama)
const COL_HI := Color("63c74d")  # borda de fora dos paineis
const COL_YELLOW := Color("fee761")
const COL_YELLOW_DARK := Color("733e39")
const COL_ORANGE := Color("feae34")
const COL_DIM := Color("8b9bb4")
const COL_HINT := Color("c0cbdc")
const COL_RED := Color("e43b44")  # vida do chefe
const COL_RED_DARK := Color("3e2731")  # encaixe vazio da vida do chefe
const COL_BUBBLE := Color("2ce8f5")  # bolha de folego (miolo)
const COL_BUBBLE_EDGE := Color("0099db")  # contorno da bolha cheia
const COL_BUBBLE_OFF := Color("5a6988")  # anel da bolha vazia

const PixelFont := preload("res://scripts/pixel_font.gd")
const PixelFx := preload("res://scripts/pixelfx.gd")
## Escurecimento atras dos menus: quadriculado (dither ordenado, PixelFx.material_dither) no tom
## mais escuro da paleta, em degraus: 1/2 dos pixels na pausa, 1/4 nos menus fora da fase.
const COL_ESCURO := Color("181425")
const ESCURO_PAUSA := 0.5
const ESCURO_LEVE := 0.25
const Chave := preload("res://scripts/chave.gd")

const LEFT := PixelFont.LEFT
const CENTER := PixelFont.CENTER
const RIGHT := PixelFont.RIGHT


var _escuro := 0.0
var _escurecer: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# atras do desenho da UI (show_behind_parent): escurece o jogo, nao os menus
	_escurecer = Control.new()
	_escurecer.name = "Escurecer"
	_escurecer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_escurecer.show_behind_parent = true
	_escurecer.material = PixelFx.material_dither()
	_escurecer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_escurecer.draw.connect(func() -> void:
		if _escuro > 0.0:
			_escurecer.draw_rect(Rect2(Vector2.ZERO, Vector2(Game.TELA)), Color(COL_ESCURO, _escuro)))
	add_child(_escurecer)


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
	_fill(x1 + 1 + rad, y1 + 1, x2 - 1 - rad, y1 + 1, Color.WHITE if selected else COL_LIGHT)
	if selected:
		# flor-cursor sempre 1:1 (16x16) e em pixels inteiros, a esquerda do botao
		var hop := floorf(absf(sin(now / 180.0)) * 3.0)
		Sprites.draw_frame(self, "flor", Rect2(floorf(x1 - 18.0),
			floorf((y1 + y2) / 2.0 - 7.0 - hop), 16.0, 16.0), (now / 50) % 16)


## Altura (centro vertical) do texto de escala 1 dentro do botao 'r': centrado, mas com as
## letras comecando no minimo 5 linhas abaixo da borda de cima (borda, brilho, 2 linhas do
## acento e 1 de folga), para o acento de "PRÓXIMA" ou "MÚSICA" nao invadir a borda. So vale
## para botoes de 14 px ou mais (cabem acento + letra + cedilha); os menores ficam centrados.
func _button_text_y(r: Dictionary) -> float:
	var ty: float = (r["y1"] + r["y2"]) / 2.0
	if r["y2"] - r["y1"] < 14:
		return ty
	return maxf(ty, r["y1"] + 8.5)  # topo das letras = floor(y - 3.5)


## Botao com o texto centralizado (texto em dobro nos botoes marcados com "big").
func _plain_button(r: Dictionary, on: bool, now: int) -> void:
	_button(r, on, now)
	var ty: float = (r["y1"] + r["y2"]) / 2.0
	if not r.get("big", false):
		ty = _button_text_y(r)
	var tx: float = (r["x1"] + r["x2"] + 1.0) / 2.0
	var sc := 2.0 if r.get("big", false) else 1.0
	if on:
		_text_plain(tx, ty, r["label"], COL_YELLOW_DARK, CENTER, sc)
	else:
		_text(tx, ty, r["label"], Color.WHITE, CENTER, sc)


## Painel opaco (nada do cenario aparece atras do texto), so com cores da Endesga 32.
func _panel(x1: float, y1: float, x2: float, y2: float) -> void:
	_round(x1, y1, x2, y2, COL_HI, 3)
	_round(x1 + 1, y1 + 1, x2 - 1, y2 - 1, COL_MID, 3)
	_round(x1 + 2, y1 + 2, x2 - 2, y2 - 2, COL_DARK, 2)


## Titulo da tela: plaquinha amarela arredondada.
func _title_banner(y: float, title: String) -> void:
	var half := PixelFont.width(title) / 2.0 + 12.0
	_round(160 - half, y + 6, 160 + half, y + 24, COL_DARK, 3)
	_round(160 - half, y + 4, 160 + half, y + 22, COL_YELLOW_DARK, 3)
	_round(160 - half + 1, y + 5, 160 + half - 1, y + 21, COL_YELLOW, 3)
	_fill(160 - half + 4, y + 5, 160 + half - 4, y + 5, Color.WHITE)
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


## Estrela pequena (9x9) do menu de fases com o canto em (x, y), em pixels inteiros. Se a
## peca estrela_mini ainda nao foi gravada/importada, desenha uma cruzinha no lugar.
func _mini_star(x: float, y: float, cheia: bool) -> void:
	var x0 := floorf(x)
	var y0 := floorf(y)
	if Sprites.has_art("estrela_mini"):
		Sprites.draw_frame(self, "estrela_mini", Rect2(x0, y0, 9.0, 9.0), 0 if cheia else 1)
		return
	var cont := COL_YELLOW_DARK if cheia else Color("3a4466")
	var cor := COL_YELLOW if cheia else COL_DIM
	_fill(x0 + 3, y0, x0 + 5, y0 + 8, cont)
	_fill(x0, y0 + 3, x0 + 8, y0 + 5, cont)
	_fill(x0 + 4, y0 + 1, x0 + 4, y0 + 7, cor)
	_fill(x0 + 1, y0 + 4, x0 + 7, y0 + 4, cor)


## Bolha de folego do HUD em pixel art (7x7, contorno de 1 px, cores da Endesga 32) com o
## canto em (x, y). Cheia: azul-claro com brilho branco; vazia: so o anel apagado.
func _air_bubble(x: float, y: float, cheia: bool) -> void:
	var edge := COL_BUBBLE_EDGE if cheia else COL_BUBBLE_OFF
	if cheia:
		_fill(x + 1, y + 2, x + 5, y + 4, COL_BUBBLE)
		_fill(x + 2, y + 1, x + 4, y + 5, COL_BUBBLE)
		_fill(x + 2, y + 2, x + 2, y + 2, Color.WHITE)  # brilho
	_fill(x + 2, y, x + 4, y, edge)  # topo
	_fill(x + 2, y + 6, x + 4, y + 6, edge)  # base
	_fill(x, y + 2, x, y + 4, edge)  # esquerda
	_fill(x + 6, y + 2, x + 6, y + 4, edge)  # direita
	for c in [Vector2(1, 1), Vector2(5, 1), Vector2(1, 5), Vector2(5, 5)]:  # cantos
		_fill(x + c.x, y + c.y, x + c.x, y + c.y, edge)


## Barra de volume: 10 segmentos, cheios amarelos e vazios escuros. Na linha selecionada
## (amarela) a barra ganha uma moldura marrom atras, para manter a mesma leitura das outras.
func _volume_bar(x: float, ty: float, level: int, on: bool) -> void:
	if on:
		_fill(x - 1, ty - 5, x + 78, ty + 4, COL_YELLOW_DARK)
	for b in 10:
		var bar_col := COL_YELLOW if b < level else COL_DARK
		_fill(x + b * 8, ty - 4, x + b * 8 + 5, ty + 3, bar_col)


# --------------------------------------------------------------------- Draw_64
func _draw() -> void:
	var tela := Vector2(Game.TELA)
	var state: String = Game.game_state
	var now := Time.get_ticks_msec()

	# ---------- HUD (nos cantos da tela inteira) ----------
	if Game.in_level and (state == "playing" or state == "pause"
			or (state in ["settings", "controls", "credits"] and Game.pause_origin == "pause")):
		_draw_hud(int(tela.x), int(tela.y))

	# ---------- Menus ----------
	var dim := ESCURO_PAUSA
	if state == "playing" or state == "cutscene" or state == "main":
		dim = 0.0
	elif state in ["settings", "controls", "levels", "credits"] and not Game.in_level:
		dim = ESCURO_LEVE
	if dim != _escuro:
		_escuro = dim
		_escurecer.queue_redraw()
	if state == "playing" or state == "cutscene":
		return

	# os menus usam a grade de 320x180, centrada na tela
	draw_set_transform(Game.UI_OFS)
	_draw_menus(state, now)
	draw_set_transform(Vector2.ZERO)


func _draw_menus(state: String, now: int) -> void:
	var w := 320
	var cx := w * 0.5

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
					_text_plain(r["x2"] - 40, ty + 1, str(rec["score"]), fg, RIGHT)
					# estrelas pequenas (9x9, estrela_mini) de 11 em 11 px (2 px de folga): cabem
					# dentro da linha de 11 px, entre a borda de cima e a de baixo do botao.
					# Na linha selecionada (amarela) elas ganham uma plaquinha escura atras: o
					# miolo da estrela cheia e do mesmo amarelo e sumiria no fundo.
					if on:
						_round(r["x2"] - 38.0, ty - 4.0, r["x2"] - 4.0, ty + 4.0, COL_DARK, 1)
					for s in 3:
						_mini_star(r["x2"] - 36.0 + s * 11.0, ty - 4.0, s < int(rec["stars"]))
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
			_draw_teclas(layout, sel, now)
			generic_from = Game.TECLAS_ACOES.size()
			var dica := "ENTER TROCA   < > COLUNA   ESC VOLTA"
			if not Game.tecla_esperando.is_empty():
				dica = "APERTE A NOVA TECLA   ESC CANCELA"
			_text_plain(cx, 165, dica, COL_HINT, CENTER)

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
			# 10 px mais largo de cada lado que os botoes + flor-cursor: a flor fica dentro do painel
			_panel(60, 22, 260, 156)
			_title_banner(28, "PAUSA")

		"complete":
			_panel(50, 8, 270, 176 if layout.size() > 2 else 170)
			_title_banner(12, "VOCÊ CONSEGUIU!")
			_draw_result(now)

		"gameover":
			# painel como nas outras telas: o cenario nao aparece atras do texto
			_panel(50, 14, 270, 164)
			var wob := floorf(sin(now / 200.0) * 2.0)
			_text(cx, 46 + wob, "QUACK!", COL_YELLOW, CENTER, 4.0)
			_text(cx, 82, "NÃO FOI DESSA VEZ...", Color.WHITE, CENTER, 1.0)
			_text(cx, 98, "FLORES: %d DE %d" % [Game.current_collectibles, Game.total_collectibles],
				COL_YELLOW, CENTER)

	for i in range(generic_from, layout.size()):
		_plain_button(layout[i], sel == i, now)


func _draw_hud(w: int, h: int) -> void:
	# HUD limpo (pedido do dono): sem caixas nem tempo na tela; so os coracoes (vida) no canto
	# esquerdo e as flores coletadas no direito. O contorno escuro da arte e a sombra do texto
	# bastam para ler contra o cenario.
	if Game.debug_invincible:
		_text(4, h - 8, "TESTE: INVENCÍVEL", COL_YELLOW, LEFT)

	# Sem barra de vida nem nome do chefe no HUD: o dano acumulado aparece so no proprio chefe.

	for heart in Game.max_lives:
		var cheio := heart < Game.player_lives
		Sprites.draw_frame(self, "coracao", Rect2(4 + heart * 17, 3, 16, 16), 0 if cheio else 1)

	# flores: a flor do jogo (parada no 1o quadro) e "coletadas/total"
	var txt := "%d/%d" % [Game.current_collectibles, Game.total_collectibles]
	var tw := PixelFont.width(txt)
	var tx := float(w) - 5.0 - tw
	Sprites.draw_frame(self, "flor", Rect2(floorf(tx - 17.0), 3, 16, 16), 0)
	_text(tx, 11, txt, COL_YELLOW if Game.current_collectibles >= Game.total_collectibles else Color.WHITE, LEFT)

	var row_y := 21.0  # proxima linha livre embaixo dos coracoes
	if Game.keys > 0:
		# chaves no bolso: uma chave desenhada por unidade (cabem 4)
		for i in mini(Game.keys, 4):
			Chave.draw_key(self, Vector2(10 + i * 13, row_y + 5.5))
		row_y += 13.0

	if Game.show_air:
		# folego: 5 bolhas que somem conforme o ar acaba (piscam no fim)
		var left := ceili(Game.air_ratio * 5.0 - 0.001)
		var blink := Game.air_ratio < 0.25 and (Time.get_ticks_msec() / 150) % 2 == 0
		for i in 5:
			_air_bubble(6.0 + i * 10.0, row_y + 2.0, i < left and not blink)


## CONTROLES: uma linha por acao com as 2 teclas dela (Game.teclas); a coluna escolhida fica
## destacada e, esperando a tecla nova, pisca "...".
func _draw_teclas(layout: Array, sel: int, now: int) -> void:
	for i in Game.TECLAS_ACOES.size():
		var r: Dictionary = layout[i]
		var on := sel == i
		var ty: float = (r["y1"] + r["y2"]) / 2.0
		_button(r, on, now)
		_text_plain(r["x1"] + 7, ty + 1, r["label"], COL_YELLOW_DARK if on else Color.WHITE, LEFT)
		var acao: String = r["tecla"]
		for c in 2:
			var bx1 := 149.0 + c * 65.0
			var bx2 := bx1 + 61.0
			var escolhida := on and Game.tecla_coluna == c
			var esperando := escolhida and Game.tecla_esperando == acao
			_fill(bx1, r["y1"] + 2, bx2, r["y2"] - 2, COL_DARK)
			if escolhida:
				_outline(bx1, r["y1"] + 2, bx2, r["y2"] - 2, Color.WHITE)
			var nome: String = Game.nome_tecla(Game.teclas[acao][c])
			if esperando:
				nome = "..." if (now / 250) % 2 == 0 else ""
			var cor := COL_YELLOW if escolhida else COL_HINT
			_text_plain((bx1 + bx2) / 2.0, ty + 1, nome, cor, CENTER)


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
		var ty := _button_text_y(r)
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
			# a barra (8 linhas) fica no meio da area livre do botao, nao do texto
			_volume_bar(mid - 39.0, floorf((r["y1"] + r["y2"]) / 2.0) + 1.0, volumes[i - 2], on)


## Tela de fase concluida: recorde, estrelas, tempo, flores e pontos.
func _draw_result(now: int) -> void:
	var cx := 160.0
	var result := {}
	if Game.level_history.size() > 0:
		result = Game.level_history[Game.level_history.size() - 1]
	if result.is_empty():
		return
	# sem "NOVO RECORDE!" o resto sobe 6 px: nao sobra vao embaixo do titulo e os pontos
	# ficam com folga acima dos botoes (que comecam em y = 120)
	var oy := 0.0
	if Game.last_result_is_record:
		var blink := (now / 300) % 2 == 0
		_text(cx, 45, "NOVO RECORDE!", COL_YELLOW if blink else Color.WHITE, CENTER)
	else:
		oy = -6.0
	var stars := Game.stars_for(result["score"])
	for s in 3:
		var bounce := 0.0
		if s < stars:
			bounce = floorf(sin(now / 220.0 + s) * 1.5)
		# 1:1 (16x16), de 24 em 24 px, centradas em cx, em pixels inteiros
		Sprites.draw_frame(self, "estrela", Rect2(floorf(cx - 24.0 + s * 24.0 - 8.0),
			floorf(66.0 + oy + bounce - 8.0), 16.0, 16.0), 0 if s < stars else 1)
	_text(cx, 86 + oy, "TEMPO: %.1f S   +%d" % [result["time_seconds"], result["time_points"]],
		Color.WHITE, CENTER)
	_text(cx, 97 + oy, "FLORES: %d DE %d   +%d" % [result["collectibles"],
		result["collectible_total"], result["collectible_points"]], Color.WHITE, CENTER)
	# Pontos da fase (0..100); com mais de uma fase jogada, mostra tambem o total do jogo.
	if Game.level_history.size() > 1:
		_text(cx, 108 + oy, "PONTOS: %d DE 100   TOTAL: %d" % [result["score"], Game.total_score],
			COL_YELLOW, CENTER)
	else:
		_text(cx, 108 + oy, "PONTOS: %d DE 100" % result["score"], COL_YELLOW, CENTER)
