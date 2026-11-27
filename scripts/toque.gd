extends Node2D
## Controles de toque na tela (celular/tablet), desenhados em pixel art na tela de 384x216.
## - direcional (canto inferior esquerdo): left / right / up / down, com diagonais; o dedo que
##   comecou no direcional continua nele mesmo que escorregue para fora;
## - botao de pulo (A, canto inferior direito) e botao de pegar/arremessar (B);
## - pausa (em cima, no meio).
## Os botoes so apertam as acoes do InputMap (Input.action_press), entao o jogo nao sabe se veio
## do teclado, do controle ou do toque. Os menus ja funcionam tocando: o toque vira clique do
## mouse (emulate_mouse_from_touch, padrao do Godot) e game.gd trata o clique.
## Aparecem so jogando (game_state "playing"); somem quando chega tecla ou controle e voltam no
## proximo toque. Na cutscene, tocar em qualquer lugar pula (acao confirm).
## Transparencia em pixel: modulate.a com o material de dither (pixel cheio ou vazio).

const PixelFx := preload("res://scripts/pixelfx.gd")

const DPAD_C := Vector2(42, 172)  # centro do direcional
const DPAD_BRACO := 13  # do centro ate o fim de cada braco
const DPAD_LARG := 9  # meia largura do braco
const DPAD_ZONA := Rect2(0, 96, 128, 120)  # onde um toque novo pega o direcional
const DPAD_MORTO := 4.0  # zona morta no centro (px)

const PULO_C := Vector2(354, 182)
const PULO_R := 15
const PEGA_C := Vector2(318, 194)
const PEGA_R := 11
const BOTOES_ZONA := Rect2(272, 132, 112, 84)  # toque novo aqui vai para o botao mais perto
const PAUSA := Rect2(185, 3, 14, 14)
const FOLGA := 8.0  # escorregar ate essa distancia para fora ainda segura o botao

const ALFA := 0.7  # quanto do botao aparece (dither) solto; apertado fica cheio

const COR_FUNDO := Color("#262b44")
const COR_FUNDO_ON := Color("#3a4466")
const COR_BORDA := Color("#8b9bb4")
const COR_BORDA_ON := Color("#ffffff")
const COR_ICONE := Color("#c0cbdc")
const COR_PULO := Color("#feae34")
const COR_PEGA := Color("#63c74d")

## Liga os controles mesmo sem tela de toque (testes, ou rodar com --toque no PC).
var forcar := false
## O jogador esta usando toque agora (some quando aperta tecla ou controle).
var usando_toque := false

var _dedos := {}  # indice do dedo -> {"zona": String, "pos": Vector2}
var _apertadas := {}  # acao -> true (as que este script segura apertadas)
var _soltar_pausa := 0
var _visivel_antes := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	material = PixelFx.material_dither()
	forcar = "--toque" in OS.get_cmdline_user_args() or "--toque" in OS.get_cmdline_args()
	usando_toque = disponivel()
	# Voltar do Android pausa (ou volta um menu) em vez de fechar o jogo.
	get_tree().quit_on_go_back = false


## O aparelho tem tela de toque (ou foi forcado)?
func disponivel() -> bool:
	return forcar or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()


func ativo() -> bool:
	return usando_toque and disponivel() and Game.in_level and not Game.transitioning \
		and Game.game_state == "playing"


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_apertar("pause")
		_soltar_pausa = 2


func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventJoypadButton \
			or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		if usando_toque and not (event is InputEventKey and _tecla_debug(event)):
			usando_toque = false
		return
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag):
		return
	if not disponivel():
		return
	usando_toque = true
	var ev := make_input_local(event)
	var idx: int = ev.index
	if Game.game_state == "cutscene":
		# cutscene: tocar em qualquer lugar pula
		if ev is InputEventScreenTouch and ev.pressed:
			_apertar("confirm")
			_soltar_pausa = 2
		return
	if not ativo():
		return
	if ev is InputEventScreenTouch:
		if ev.pressed:
			var zona := _zona_em(ev.position)
			if zona.is_empty():
				return
			_dedos[idx] = {"zona": zona, "pos": ev.position}
		else:
			_dedos.erase(idx)
	elif _dedos.has(idx):
		_dedos[idx]["pos"] = ev.position
	_atualizar()
	get_viewport().set_input_as_handled()


func _tecla_debug(ev: InputEventKey) -> bool:
	return ev.physical_keycode >= KEY_F1 and ev.physical_keycode <= KEY_F12


## Onde um toque novo cai: "dpad", "pulo", "pega", "pausa" ou "" (fora dos controles).
func _zona_em(p: Vector2) -> String:
	if PAUSA.grow(4).has_point(p):
		return "pausa"
	if DPAD_ZONA.has_point(p):
		return "dpad"
	if BOTOES_ZONA.has_point(p) or p.distance_to(PULO_C) <= PULO_R + 4 \
			or p.distance_to(PEGA_C) <= PEGA_R + 4:
		var dp := p.distance_to(PULO_C) - PULO_R
		var dg := p.distance_to(PEGA_C) - PEGA_R
		return "pulo" if dp <= dg else "pega"
	return ""


## Acoes que os dedos na tela querem apertadas agora.
func acoes_desejadas() -> Dictionary:
	var out := {}
	for idx: int in _dedos:
		var d: Dictionary = _dedos[idx]
		var p: Vector2 = d["pos"]
		match d["zona"]:
			"dpad":
				var v := p - DPAD_C
				if v.length() < DPAD_MORTO:
					continue
				# 8 direcoes: setores de 45 graus centrados nos eixos e nas diagonais
				var setor := posmod(roundi(v.angle() / (PI / 4.0)), 8)
				if setor in [7, 0, 1]:
					out["right"] = true
				if setor in [3, 4, 5]:
					out["left"] = true
				if setor in [1, 2, 3]:
					out["down"] = true
				if setor in [5, 6, 7]:
					out["up"] = true
			"pulo":
				if p.distance_to(PULO_C) <= PULO_R + FOLGA:
					out["jump"] = true
			"pega":
				if p.distance_to(PEGA_C) <= PEGA_R + FOLGA:
					out["grab"] = true
			"pausa":
				if PAUSA.grow(FOLGA).has_point(p):
					out["pause"] = true
	return out


func _atualizar() -> void:
	var quer := acoes_desejadas()
	for a: String in _apertadas.keys():
		if not quer.has(a):
			_soltar(a)
	for a: String in quer:
		if not _apertadas.has(a):
			_apertar(a)
	queue_redraw()


func _apertar(acao: String) -> void:
	_apertadas[acao] = true
	Input.action_press(acao)


func _soltar(acao: String) -> void:
	_apertadas.erase(acao)
	Input.action_release(acao)


func soltar_tudo() -> void:
	_dedos.clear()
	for a: String in _apertadas.keys():
		_soltar(a)


func _physics_process(_delta: float) -> void:
	if _soltar_pausa > 0:
		_soltar_pausa -= 1
		if _soltar_pausa == 0:
			for a: String in ["pause", "confirm"]:
				if _apertadas.has(a) and not acoes_desejadas().has(a):
					_soltar(a)
	var vis := ativo()
	if vis != _visivel_antes:
		_visivel_antes = vis
		if not vis:
			# saiu do jogo (pausou, morreu, trocou de fase): nada fica preso apertado
			soltar_tudo()
		queue_redraw()
	visible = vis


# ------------------------------------------------------------------- desenho
func _draw() -> void:
	if not ativo():
		return
	_draw_dpad()
	_draw_botao(PULO_C, PULO_R, _apertadas.has("jump"), COR_PULO, "pulo")
	_draw_botao(PEGA_C, PEGA_R, _apertadas.has("grab"), COR_PEGA, "pega")
	_draw_pausa()


## Cor com o alfa de solto/apertado (o material de dither transforma em pixel cheio ou vazio).
func _c(cor: Color, on: bool) -> Color:
	return Color(cor, 1.0 if on else ALFA)


func _r(x: float, y: float, w: float, h: float, cor: Color) -> void:
	draw_rect(Rect2(floorf(x), floorf(y), w, h), cor)


## Disco de pixels (linhas inteiras, sem antisserrilhado).
func _disco(c: Vector2, r: int, cor: Color) -> void:
	for dy in range(-r, r + 1):
		var w := floori(sqrt(r * r - dy * dy + r * 0.8))
		_r(c.x - w, c.y + dy, w * 2 + 1, 1, cor)


## Triangulo de pixels apontando para 'dir' (seta do direcional), ponta em 'p'.
func _seta(p: Vector2, dir: Vector2, cor: Color) -> void:
	var lado := Vector2(-dir.y, dir.x)
	for i in 4:
		var meio := p - dir * i
		for j in range(-i, i + 1):
			var q := meio + lado * j
			_r(q.x, q.y, 1, 1, cor)


func _draw_dpad() -> void:
	var c := DPAD_C
	var b := DPAD_BRACO
	var l := DPAD_LARG
	var any := false
	for a: String in ["left", "right", "up", "down"]:
		any = any or _apertadas.has(a)
	var borda := _c(COR_BORDA, any)
	# cruz: borda e depois o miolo 1 px para dentro
	_r(c.x - b - l, c.y - l, (b + l) * 2 + 1, l * 2 + 1, borda)
	_r(c.x - l, c.y - b - l, l * 2 + 1, (b + l) * 2 + 1, borda)
	var fundo := _c(COR_FUNDO, any)
	_r(c.x - b - l + 1, c.y - l + 1, (b + l) * 2 - 1, l * 2 - 1, fundo)
	_r(c.x - l + 1, c.y - b - l + 1, l * 2 - 1, (b + l) * 2 - 1, fundo)
	var bracos := {"left": Vector2.LEFT, "right": Vector2.RIGHT, "up": Vector2.UP, "down": Vector2.DOWN}
	for acao: String in bracos:
		var d: Vector2 = bracos[acao]
		var on: bool = _apertadas.has(acao)
		if on:
			# braco apertado acende
			var a := c + d * (l + 1)
			var e := c + d * (b + l - 1)
			var rr := Rect2(a, Vector2.ZERO).expand(e)
			rr = rr.grow_individual(
				0 if d.x != 0 else l - 2, 0 if d.y != 0 else l - 2,
				0 if d.x != 0 else l - 2, 0 if d.y != 0 else l - 2)
			_r(rr.position.x, rr.position.y, rr.size.x + 1, rr.size.y + 1, _c(COR_FUNDO_ON, true))
		var ponta := c + d * (b + l - 4)
		_seta(ponta, d, _c(COR_BORDA_ON if on else COR_ICONE, any))


func _draw_botao(c: Vector2, r: int, on: bool, destaque: Color, icone: String) -> void:
	var dy := 1.0 if on else 0.0  # apertado afunda 1 px
	var cc := c + Vector2(0, dy)
	if not on:
		_disco(c + Vector2(0, 1), r, _c(Color("#181425"), false))  # sombra embaixo
	_disco(cc, r, _c(COR_BORDA_ON if on else COR_BORDA, on))
	_disco(cc, r - 1, _c(COR_FUNDO_ON if on else COR_FUNDO, on))
	var cor := _c(COR_BORDA_ON if on else destaque, on)
	if icone == "pulo":
		# seta para cima com haste
		_seta(cc + Vector2(0, -5), Vector2.UP, cor)
		_r(cc.x - 1, cc.y - 2, 3, 7, cor)
	else:
		# caixinha (pegar / arremessar caixa)
		_r(cc.x - 4, cc.y - 3, 9, 7, cor)
		_r(cc.x - 3, cc.y - 2, 7, 5, _c(COR_FUNDO_ON if on else COR_FUNDO, on))
		_r(cc.x - 3, cc.y, 7, 1, cor)


func _draw_pausa() -> void:
	var on := _apertadas.has("pause")
	var p := PAUSA
	_r(p.position.x, p.position.y, p.size.x, p.size.y, _c(COR_BORDA_ON if on else COR_BORDA, on))
	_r(p.position.x + 1, p.position.y + 1, p.size.x - 2, p.size.y - 2,
		_c(COR_FUNDO_ON if on else COR_FUNDO, on))
	var cor := _c(COR_BORDA_ON if on else COR_ICONE, on)
	_r(p.position.x + 4, p.position.y + 4, 2, 6, cor)
	_r(p.position.x + 8, p.position.y + 4, 2, 6, cor)
