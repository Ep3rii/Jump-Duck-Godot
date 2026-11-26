@tool
extends Node2D
## Vento (Fases 6 a 8): area que empurra o pato (e as caixas paradas) numa direcao.
## - Direita / Esquerda: soma na velocidade horizontal (andando contra, o pato quase nao sai
##   do lugar; no ar, o pulo encurta ou alonga). Caixas no chao sao arrastadas.
## - Cima: corrente de ar que levanta o pato (sobe ate o topo da area e fica "boiando" ali);
##   dentro dela cair nao machuca. Use para subir de um andar para outro.
## Com "rajada" liga e desliga (as listras ficam fracas no intervalo e voltam um pouco antes
## da rajada, avisando). Origem no canto INFERIOR esquerdo, tamanho em tiles de 16 px.

const Sprites := preload("res://scripts/sprites.gd")

@export var tiles_w: int = 4:
	set(v):
		tiles_w = v
		queue_redraw()
@export var tiles_h: int = 4:
	set(v):
		tiles_h = v
		queue_redraw()
@export_enum("Direita", "Esquerda", "Cima") var direcao := 0:
	set(v):
		direcao = v
		queue_redraw()
## Empurrao em px por frame (o pato anda a 2). Na corrente para cima, quanto levanta por frame.
@export var forca := 1.2
## Liga e desliga sozinho.
@export var rajada := false
@export var tempo_ligado := 150
@export var tempo_desligado := 120
## Frames de atraso no ciclo (para varias areas nao soprarem juntas).
@export var atraso := 0

const WARN := 40  # frames de aviso antes da rajada
const STREAKS := 14

var _t := 0
var _anim := 0.0


func _ready() -> void:
	add_to_group("vento")
	_t = atraso


func get_rect() -> Rect2:
	return Rect2(global_position.x, global_position.y - 16.0 * tiles_h,
		16.0 * tiles_w, 16.0 * tiles_h)


func _cycle() -> int:
	return tempo_ligado + tempo_desligado


func is_blowing() -> bool:
	if not rajada:
		return true
	return posmod(_t, _cycle()) < tempo_ligado


## Falta pouco para a rajada (as listras aparecem antes do empurrao).
func is_warning() -> bool:
	if not rajada or is_blowing():
		return false
	return posmod(_t, _cycle()) >= _cycle() - WARN


## Empurrao para quem esta dentro da area (Vector2.ZERO sem vento).
func push_for(r: Rect2) -> Vector2:
	if not is_blowing() or not r.intersects(get_rect()):
		return Vector2.ZERO
	match direcao:
		0:
			return Vector2(forca, 0)
		1:
			return Vector2(-forca, 0)
	return Vector2(0, -forca)


## Soma o vento de todas as areas sobre o retangulo r.
static func total(tree: SceneTree, r: Rect2) -> Vector2:
	var sum := Vector2.ZERO
	for v in tree.get_nodes_in_group("vento"):
		sum += v.push_for(r)
	return sum


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or Game.game_state != "playing":
		return
	var was := is_blowing()
	_t += 1
	_anim += 1.0
	if rajada and is_blowing() and not was:
		var p := get_tree().get_first_node_in_group("player")
		if p != null and get_rect().grow(96.0).has_point(p.position):
			Game.play_sfx("wind")
	# caixas paradas no chao sao arrastadas pelo vento horizontal
	if direcao != 2 and is_blowing():
		var dx := forca if direcao == 0 else -forca
		var p := get_tree().get_first_node_in_group("player")
		for box in get_tree().get_nodes_in_group("caixa"):
			if box.state != "idle" or not get_rect().intersects(box.get_rect()):
				continue
			# nao empurra a caixa para dentro do pato
			var moved: Rect2 = box.get_rect()
			moved.position.x += signf(dx) * ceilf(absf(dx))
			if p != null and moved.intersects(p.get_mask()):
				continue
			box.push(dx)
	queue_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	queue_redraw()


func _draw() -> void:
	var w := 16.0 * tiles_w
	var h := 16.0 * tiles_h
	if Engine.is_editor_hint():
		draw_rect(Rect2(0, -h, w, h), Color(0.7, 0.9, 1.0, 0.15))
		draw_rect(Rect2(0, -h, w, h), Color(0.7, 0.9, 1.0, 0.6), false)
	var alpha := 0.55
	if not is_blowing():
		alpha = 0.3 if is_warning() else 0.08
	var speed := 3.0 if is_blowing() else 1.0
	var col := Color(0.86, 0.95, 1.0, alpha)
	var count := int(STREAKS * maxf(1.0, w * h / 4096.0))
	for i in count:
		# cada listra tem uma "faixa" fixa e anda ao longo da direcao do vento
		var lane := fposmod(i * 37.0 + i * i * 13.0, 97.0) / 97.0
		var phase := fposmod(_anim * speed + i * 53.0, 1000.0)
		if direcao == 2:
			var x := floorf(lane * (w - 2.0))
			var y := -fposmod(phase, h)
			Sprites.draw_art(self, "vento", x - 6.0, y - 12.0, 1, 2, col)
		else:
			var y := -floorf(lane * (h - 2.0)) - 1.0
			var x := fposmod(phase, w)
			if direcao == 1:
				# para a esquerda: o quadro horizontal aponta para a direita, entao e espelhado
				# (o risco de 12 px fica no mesmo lugar, centrado em x)
				x = w - x
				draw_set_transform(Vector2(floorf(x), 0.0), 0.0, Vector2(-1, 1))
				Sprites.draw_art(self, "vento", -6.0, y - 6.0, 0, 2, col)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				Sprites.draw_art(self, "vento", x - 6.0, y - 6.0, 0, 2, col)
