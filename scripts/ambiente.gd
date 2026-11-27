extends Node2D
## Vida no cenario, montada sozinha em cada fase (level.gd cria este no):
## - detalhes no chao: tufos de grama, florzinhas e pedrinhas (ao ar livre) ou musgo, entulho,
##   teias e musgo pendurado (dentro da torre), escolhidos por posicao (sempre iguais);
## - bichinhos: borboletas (fazenda), libelulas (lago) ou poeira flutuando na luz (torre);
## - folhas caindo das arvores.
## Tudo desenhado em codigo e so o que esta perto da camera.

const Particulas := preload("res://scripts/particulas.gd")

# Cores so da ENDESGA 32 (a paleta da arte, ver tools/arte/pixelkit.py), sem clarear/escurecer
# em codigo: o tom de luz e o de sombra sao outra cor da paleta.
const GRASS := Color("#3e8948")
const GRASS_DARK := Color("#265c42")
const GRASS_LIGHT := Color("#63c74d")
const PETALS := [Color("#ffffff"), Color("#fee761"), Color("#f6757a"), Color("#b55088")]
const FLOWER_CORE := Color("#feae34")
const PEBBLE := Color("#8b9bb4")
const PEBBLE_LIGHT := Color("#c0cbdc")
const MOSS := Color("#3e8948")
const MOSS_DARK := Color("#265c42")
const RUBBLE := Color("#8b9bb4")
const RUBBLE_DARK := Color("#5a6988")
const WEB := Color("#c0cbdc")
## Borboletas amarelas e laranjas (a branca sumia nas nuvens): asa e ponta da asa, corpo escuro.
const BUTTERFLY := [[Color("#fee761"), Color("#feae34")], [Color("#feae34"), Color("#f77622")]]
const BUTTERFLY_BODY := Color("#3e2731")
## Borboleta em "V" (corpo em x = 0): asas abertas e fechadas (as duas para cima); as pontas
## das asas (BUTTERFLY_TIP_*) sao do tom mais forte, para ler como bicho ate em cima da nuvem.
const BUTTERFLY_OPEN := [Vector2i(-2, -1), Vector2i(2, -1), Vector2i(-2, 0), Vector2i(-1, 0),
	Vector2i(1, 0), Vector2i(2, 0), Vector2i(-1, 1), Vector2i(1, 1)]
const BUTTERFLY_TIP_OPEN := [Vector2i(-2, -2), Vector2i(2, -2), Vector2i(-1, -1), Vector2i(1, -1)]
const BUTTERFLY_SHUT := [Vector2i(-1, -1), Vector2i(1, -1)]
const BUTTERFLY_TIP_SHUT := [Vector2i(-1, -2), Vector2i(1, -2)]
const DRAGONFLY := Color("#0099db")
const DRAGONFLY_WING := Color("#c0cbdc")
## Cabeca (2 px de altura na frente do corpo de 5 px): da a forma de bicho, e nao de tracinho.
const DRAGONFLY_HEAD := Color("#124e89")
## Dois pares de asas (x para quem voa para a direita; espelha em x): erguidas e abertas.
const DRAGONFLY_WINGS_UP := [Vector2i(-2, -1), Vector2i(-2, -2), Vector2i(0, -1), Vector2i(0, -2)]
const DRAGONFLY_WINGS_OPEN := [Vector2i(-3, -1), Vector2i(-2, -1), Vector2i(0, -1),
	Vector2i(1, -1)]
## Poeira na luz da torre: pisca em degraus (clara -> apagada -> sumida), opaca e da paleta.
const DUST := Color("#ead4aa")
const DUST_DIM := Color("#c28569")
## Teia de canto (so onde parede encontra teto), pixel a pixel (1 px opaco), com o canto em
## (0, 0): um fio na diagonal e dois arcos ligando teto e parede. Sem fio colado no teto nem na
## parede (com eles a teia virava uma letra).
const WEB_PIXELS := [
	Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2), Vector2i(3, 3), Vector2i(4, 4), Vector2i(5, 5),
	Vector2i(6, 6), Vector2i(7, 7),
	Vector2i(3, 0), Vector2i(3, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(1, 3), Vector2i(0, 3),
	Vector2i(6, 0), Vector2i(6, 1), Vector2i(5, 2), Vector2i(5, 3), Vector2i(3, 5), Vector2i(2, 5),
	Vector2i(1, 6), Vector2i(0, 6)]

enum Tipo { FAZENDA, LAGO, TORRE }

var tipo := Tipo.FAZENDA
var _details: Array = []  # [pos, kind, seed]
var _bugs: Array = []  # [pos, vel, phase, sentido]
## Celulas solidas (16 px, coordenadas do mundo) e retangulos dos blocos parados: os bichinhos
## so voam no ar (nunca na frente da terra).
var _solid_cells := {}
var _solid_rects: Array[Rect2] = []
var _time := 0.0
var _leaf_timer := 0


func _ready() -> void:
	z_index = -790  # na frente do terreno, atras de itens e personagens
	var level := get_parent()
	var par := level.get_node_or_null("Parallax")
	if par != null and int(par.get("cenario")) == 1:
		tipo = Tipo.TORRE
	elif not get_tree().get_nodes_in_group("agua").is_empty():
		tipo = Tipo.LAGO
	_scan_ground.call_deferred()
	var n := 16 if tipo == Tipo.TORRE else 5
	for i in n:
		_bugs.append([Vector2(-99999, -99999), Vector2.ZERO, i * 1.7, 1.0])


static func _hash(c: Vector2i, salt: int) -> int:
	return absi((c.x * 73856093) ^ (c.y * 19349663) ^ (salt * 83492791)) % 1000


func _scan_ground() -> void:
	for n in get_tree().get_nodes_in_group("solid"):
		var parado: bool = not (n.is_in_group("caixa") or n.is_in_group("plataforma")
			or n.is_in_group("plataforma_cai") or n.is_in_group("porta"))
		if parado and n.has_method("get_rect"):
			_solid_rects.append(n.get_rect())
	var tetos: Array = []  # [canto de cima do bloco de ar embaixo do teto, hash]
	for layer: TileMapLayer in get_tree().get_nodes_in_group("solid_tiles"):
		for cell in layer.get_used_cells():
			var centro := layer.to_global(layer.map_to_local(cell))
			_solid_cells[Vector2i(floori(centro.x / 16.0), floori(centro.y / 16.0))] = true
			var above := layer.get_cell_source_id(cell + Vector2i(0, -1)) != -1
			var below := layer.get_cell_source_id(cell + Vector2i(0, 1)) != -1
			var top_pos := layer.to_global(layer.map_to_local(cell)) + Vector2(-8, -8)
			if not above:
				_add_top(cell, top_pos)
			if not below and tipo == Tipo.TORRE:
				tetos.append([top_pos + Vector2(0, 16), _hash(cell, 7)])
	# teto: teia so num canto de verdade (parede encostada no bloco de ar embaixo do teto);
	# no meio do teto, so musgo pendurado. Depois de ler todos os solidos (paredes de outra camada).
	for t: Array in tetos:
		var p: Vector2 = t[0]
		var h: int = t[1]
		var meio := p + Vector2(8, 8)
		var esq := _solido(meio + Vector2(-16, 0)) and not _solido(meio)
		var dire := _solido(meio + Vector2(16, 0)) and not _solido(meio)
		if (esq or dire) and h < 700:
			# h par = canto esquerdo, impar = direito (quando so ha um, fica nele)
			var direita := dire and (not esq or h % 2 == 1)
			_details.append([p, "teia", 1 if direita else 0])
		elif h < 100:
			_details.append([p, "musgo_pendurado", h])


func _add_top(cell: Vector2i, p: Vector2) -> void:
	# alguns detalhes por bloco, em pontos diferentes do topo
	for slot in 2:
		var h := _hash(cell, slot)
		var x := p.x + 2.0 + slot * 8.0 + (h % 5)
		if tipo == Tipo.TORRE:
			if h < 220:
				_details.append([Vector2(x, p.y), "musgo", h])
			elif h < 330:
				_details.append([Vector2(x, p.y), "entulho", h])
		else:
			if h < 380:
				_details.append([Vector2(x, p.y), "tufo", h])
			elif h < 500:
				_details.append([Vector2(x, p.y), "flor", h])
			elif h < 560:
				_details.append([Vector2(x, p.y), "pedrinha", h])


func _process(delta: float) -> void:
	_time += delta
	_update_bugs()
	_leaf_timer -= 1
	if _leaf_timer <= 0 and tipo != Tipo.TORRE:
		_leaf_timer = 50
		_drop_leaf()
	queue_redraw()


func _view() -> Rect2:
	return Rect2(Game.cam_pos, Game.view_size)


## Ponto dentro de terra/pedra solida?
func _solido(p: Vector2) -> bool:
	if _solid_cells.has(Vector2i(floori(p.x / 16.0), floori(p.y / 16.0))):
		return true
	for r in _solid_rects:
		if r.has_point(p):
			return true
	return false


## Ponto de ar com folga embaixo (o bicho nao nasce encostado no chao).
func _no_ar(p: Vector2) -> bool:
	return not _solido(p) and not _solido(p + Vector2(0, 4))


func _update_bugs() -> void:
	var v := _view()
	for b: Array in _bugs:
		var pos: Vector2 = b[0]
		b[2] += 0.05
		if not v.grow(60).has_point(pos):
			# entra de novo perto da camera, so num lugar de ar (ate 8 tentativas)
			var ph: float = b[2]
			pos = Vector2(-99999, -99999)
			for k in 8:
				var q := ph + k * 0.37
				var cand := v.position + Vector2(fposmod(q * 97.0, v.size.x),
					30.0 + fposmod(q * 53.0, v.size.y - 60.0))
				if _no_ar(cand):
					pos = cand
					break
			if pos.x < -9999.0:
				b[0] = pos
				continue
		var t: float = b[2]
		var vel := Vector2(cos(t * 0.7) * 0.5 + sin(t * 1.9) * 0.3, sin(t * 1.3) * 0.35)
		if tipo == Tipo.TORRE:
			vel *= 0.25
		elif tipo == Tipo.LAGO:
			vel = Vector2(cos(t * 0.5) * 1.2, sin(t * 2.3) * 0.4)
		vel *= float(b[3])
		var nova := pos + vel
		if _solido(nova):
			# bateu na terra: fica onde esta e volta pelo outro lado
			b[3] = -float(b[3])
			nova = pos
		b[1] = vel
		b[0] = nova


func _drop_leaf() -> void:
	var v := _view()
	for d in get_tree().get_nodes_in_group("decoracao_arvore"):
		if v.grow(40).has_point(d.position) and randf() < 0.5:
			Particulas.emit(get_tree(), "folha", d.position + Vector2(randf_range(-22, 22), -d.altura_copa()), 1)


func _draw() -> void:
	var v := _view().grow(16)
	for d: Array in _details:
		var p: Vector2 = d[0]
		if not v.has_point(p):
			continue
		var h: int = d[2]
		match d[1]:
			"tufo":
				# 3 folhinhas de 1 px; so a ponta balanca, 1 px inteiro por vez
				var sway := roundf(sin(_time * 2.0 + p.x * 0.1) * 0.8)
				var tall := 2.0 + h % 3
				p = p.floor()
				var altos := [tall, tall + 1.0, tall - 1.0]
				var cores := [GRASS_DARK, GRASS, GRASS_LIGHT]
				for f in 3:
					var alto: float = altos[f]
					var cor: Color = cores[f]
					draw_rect(Rect2(p.x + f, p.y - alto + 1.0, 1, alto - 1.0), cor)
					draw_rect(Rect2(p.x + f + sway, p.y - alto, 1, 1), cor)
			"flor":
				var sway := roundf(sin(_time * 1.6 + p.x * 0.13) * 0.7)
				var c: Color = PETALS[h % PETALS.size()]
				p = p.floor()
				draw_rect(Rect2(p.x, p.y - 3, 1, 3), GRASS_DARK)
				draw_rect(Rect2(p.x - 1 + sway, p.y - 6, 3, 2), c)
				draw_rect(Rect2(p.x + sway, p.y - 7, 1, 4), c)
				draw_rect(Rect2(p.x + sway, p.y - 6, 1, 1), FLOWER_CORE)
			"pedrinha":
				draw_rect(Rect2(p.x, p.y - 2, 3, 2), PEBBLE)
				draw_rect(Rect2(p.x, p.y - 2, 2, 1), PEBBLE_LIGHT)
			"musgo":
				draw_rect(Rect2(p.x - 1, p.y - 1, 5, 2), MOSS_DARK)
				draw_rect(Rect2(p.x, p.y - 2, 3, 1), MOSS)
			"entulho":
				draw_rect(Rect2(p.x, p.y - 2, 2, 2), RUBBLE)
				draw_rect(Rect2(p.x + 2, p.y - 1, 2, 1), RUBBLE_DARK)
			"teia":
				# canto esquerdo ou direito do bloco de ar (espelhada em x); h = 1: direito
				var direita := h == 1
				var x0 := floorf(p.x) + (15.0 if direita else 0.0)
				for c: Vector2i in WEB_PIXELS:
					var dx := -c.x if direita else c.x
					draw_rect(Rect2(x0 + dx, floorf(p.y) + c.y, 1, 1), WEB)
			"musgo_pendurado":
				var len := 3.0 + h % 6
				var sway := roundf(sin(_time * 1.2 + p.x) * 0.6)
				p = p.floor()
				draw_rect(Rect2(p.x + 4, p.y, 1, len - 1.0), MOSS_DARK)
				draw_rect(Rect2(p.x + 4 + sway, p.y + len - 1.0, 1, 1), MOSS_DARK)
				var curto := maxf(2.0, floorf(len * 0.6))
				draw_rect(Rect2(p.x + 7, p.y, 1, curto - 1.0), MOSS)
				draw_rect(Rect2(p.x + 7 + sway, p.y + curto - 1.0, 1, 1), MOSS)
	_draw_bugs()


func _draw_bugs() -> void:
	for b: Array in _bugs:
		var p: Vector2 = (b[0] as Vector2).floor()
		var t: float = b[2]
		if p.x < -9999.0 or _solido(p):
			continue
		match tipo:
			Tipo.FAZENDA:  # borboleta: asas abrindo e fechando
				var open := int(_time * 8.0 + t) % 2 == 0
				var cores: Array = BUTTERFLY[int(t) % 2]
				for a: Vector2i in (BUTTERFLY_OPEN if open else BUTTERFLY_SHUT):
					draw_rect(Rect2(p.x + a.x, p.y + a.y, 1, 1), cores[0])
				for a: Vector2i in (BUTTERFLY_TIP_OPEN if open else BUTTERFLY_TIP_SHUT):
					draw_rect(Rect2(p.x + a.x, p.y + a.y, 1, 1), cores[1])
				draw_rect(Rect2(p.x, p.y - (0 if open else 1), 1, 2 if open else 3), BUTTERFLY_BODY)
			Tipo.LAGO:  # libelula azul, olhando para onde voa
				var flick := int(_time * 20.0 + t) % 2 == 0
				var s := 1.0 if (b[1] as Vector2).x >= 0.0 else -1.0
				for a: Vector2i in (DRAGONFLY_WINGS_UP if flick else DRAGONFLY_WINGS_OPEN):
					draw_rect(Rect2(p.x + a.x * s, p.y + a.y, 1, 1), DRAGONFLY_WING)
				draw_rect(Rect2(p.x - 3.0 if s > 0.0 else p.x - 1.0, p.y, 5, 1), DRAGONFLY)
				draw_rect(Rect2(p.x + 2.0 * s, p.y - 1.0, 1, 2), DRAGONFLY_HEAD)
			Tipo.TORRE:  # poeira na luz: dois tons opacos e um tempo sumida, sem alfa
				var s := sin(_time * 2.0 + t * 3.0)
				if s > 0.2:
					draw_rect(Rect2(p.x, p.y, 1, 1), DUST)
				elif s > -0.5:
					draw_rect(Rect2(p.x, p.y, 1, 1), DUST_DIM)
