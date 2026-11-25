extends Node2D
## Vida no cenario, montada sozinha em cada fase (level.gd cria este no):
## - detalhes no chao: tufos de grama, florzinhas e pedrinhas (ao ar livre) ou musgo, entulho,
##   teias e musgo pendurado (dentro da torre), escolhidos por posicao (sempre iguais);
## - bichinhos: borboletas (fazenda), libelulas (lago) ou poeira flutuando na luz (torre);
## - folhas caindo das arvores.
## Tudo desenhado em codigo e so o que esta perto da camera.

const Particulas := preload("res://scripts/particulas.gd")

const GRASS := Color8(70, 160, 40)
const GRASS_DARK := Color8(40, 110, 30)
const GRASS_LIGHT := Color8(133, 220, 60)
const PETALS := [Color8(255, 255, 255), Color8(255, 220, 80), Color8(250, 140, 190), Color8(170, 150, 255)]
const PEBBLE := Color8(150, 140, 130)
const MOSS := Color8(80, 140, 50)
const MOSS_DARK := Color8(50, 96, 36)
const RUBBLE := Color8(130, 124, 146)
const WEB := Color8(230, 230, 240, 150)

enum Tipo { FAZENDA, LAGO, TORRE }

var tipo := Tipo.FAZENDA
var _details: Array = []  # [pos, kind, seed]
var _bugs: Array = []  # [pos, vel, phase]
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
		_bugs.append([Vector2(-99999, -99999), Vector2.ZERO, i * 1.7])


static func _hash(c: Vector2i, salt: int) -> int:
	return absi((c.x * 73856093) ^ (c.y * 19349663) ^ (salt * 83492791)) % 1000


func _scan_ground() -> void:
	for layer: TileMapLayer in get_tree().get_nodes_in_group("solid_tiles"):
		for cell in layer.get_used_cells():
			var above := layer.get_cell_source_id(cell + Vector2i(0, -1)) != -1
			var below := layer.get_cell_source_id(cell + Vector2i(0, 1)) != -1
			var top_pos := layer.to_global(layer.map_to_local(cell)) + Vector2(-8, -8)
			if not above:
				_add_top(cell, top_pos)
			if not below and tipo == Tipo.TORRE:
				var h := _hash(cell, 7)
				if h < 60:
					_details.append([top_pos + Vector2(0, 16), "teia", h])
				elif h < 160:
					_details.append([top_pos + Vector2(0, 16), "musgo_pendurado", h])


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


func _update_bugs() -> void:
	var v := _view()
	for b: Array in _bugs:
		var pos: Vector2 = b[0]
		b[2] += 0.05
		if not v.grow(60).has_point(pos):
			# entra de novo perto da camera
			var ph: float = b[2]
			pos = v.position + Vector2(fposmod(ph * 97.0, v.size.x), 30.0 + fposmod(ph * 53.0, v.size.y - 60.0))
		var t: float = b[2]
		var vel := Vector2(cos(t * 0.7) * 0.5 + sin(t * 1.9) * 0.3, sin(t * 1.3) * 0.35)
		if tipo == Tipo.TORRE:
			vel *= 0.25
		elif tipo == Tipo.LAGO:
			vel = Vector2(cos(t * 0.5) * 1.2, sin(t * 2.3) * 0.4)
		b[1] = vel
		b[0] = pos + vel


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
				var sway := sin(_time * 2.0 + p.x * 0.1) * 0.8
				var tall := 2.0 + h % 3
				draw_line(p, p + Vector2(-1 + sway, -tall), GRASS_DARK, 1.0)
				draw_line(p + Vector2(1, 0), p + Vector2(1 + sway, -tall - 1), GRASS, 1.0)
				draw_line(p + Vector2(2, 0), p + Vector2(3 + sway, -tall + 1), GRASS_LIGHT, 1.0)
			"flor":
				var sway := sin(_time * 1.6 + p.x * 0.13) * 0.7
				var c: Color = PETALS[h % PETALS.size()]
				draw_line(p, p + Vector2(sway, -4), GRASS_DARK, 1.0)
				draw_rect(Rect2(p.x - 1 + sway, p.y - 6, 3, 2), c)
				draw_rect(Rect2(p.x + sway, p.y - 7, 1, 4), c)
				draw_rect(Rect2(p.x + sway, p.y - 6, 1, 1), Color8(255, 200, 60))
			"pedrinha":
				draw_rect(Rect2(p.x, p.y - 2, 3, 2), PEBBLE)
				draw_rect(Rect2(p.x, p.y - 2, 2, 1), PEBBLE.lightened(0.3))
			"musgo":
				draw_rect(Rect2(p.x - 1, p.y - 1, 5, 2), MOSS_DARK)
				draw_rect(Rect2(p.x, p.y - 2, 3, 1), MOSS)
			"entulho":
				draw_rect(Rect2(p.x, p.y - 2, 2, 2), RUBBLE)
				draw_rect(Rect2(p.x + 2, p.y - 1, 2, 1), RUBBLE.darkened(0.2))
			"teia":
				var x := p.x + (h % 2) * 10.0
				for i in 4:
					draw_line(Vector2(x, p.y), Vector2(x + 6 - i * 2, p.y + i * 2 + 2), WEB, 1.0)
				draw_line(Vector2(x, p.y + 3), Vector2(x + 3, p.y), WEB, 1.0)
			"musgo_pendurado":
				var len := 3.0 + h % 6
				var sway := sin(_time * 1.2 + p.x) * 0.6
				draw_line(p + Vector2(4, 0), p + Vector2(4 + sway, len), MOSS_DARK, 1.0)
				draw_line(p + Vector2(7, 0), p + Vector2(7 + sway, len * 0.6), MOSS, 1.0)
	_draw_bugs()


func _draw_bugs() -> void:
	for b: Array in _bugs:
		var p: Vector2 = b[0]
		var t: float = b[2]
		match tipo:
			Tipo.FAZENDA:  # borboleta: asas abrindo e fechando
				var open := int(_time * 12.0 + t) % 2 == 0
				var c := Color8(255, 200, 60) if int(t) % 2 == 0 else Color8(255, 255, 255)
				var w := 2.0 if open else 1.0
				draw_rect(Rect2(p.x - w, p.y - 1, w, 2), c)
				draw_rect(Rect2(p.x + 1, p.y - 1, w, 2), c)
				draw_rect(Rect2(p.x, p.y - 1, 1, 3), Color8(60, 40, 30))
			Tipo.LAGO:  # libelula azul
				var flick := int(_time * 20.0 + t) % 2 == 0
				draw_rect(Rect2(p.x - 3, p.y, 6, 1), Color8(60, 140, 220))
				draw_rect(Rect2(p.x - 1, p.y - (2 if flick else 1), 1, 1), Color8(220, 240, 255, 180))
				draw_rect(Rect2(p.x + 1, p.y - (1 if flick else 2), 1, 1), Color8(220, 240, 255, 180))
			Tipo.TORRE:  # poeira na luz
				var a := 0.35 + 0.3 * sin(_time * 2.0 + t * 3.0)
				draw_rect(Rect2(floorf(p.x), floorf(p.y), 1, 1), Color(1.0, 0.95, 0.8, a))
