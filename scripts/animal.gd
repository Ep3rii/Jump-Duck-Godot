@tool
extends "res://scripts/dica.gd"
## Animal da fazenda (galinha, porco, vaca, ovelha): enfeite sem colisao que conversa com o pato.
## Perto dele aparece um baloezinho "..."; apertando CIMA o animal fala a proxima frase (o
## balao das placas, dica.gd). Afastou, a conversa recomeca do inicio.
## Arte: tools/arte/animais.py (16 quadros parado, olhando para a direita, pe na ultima linha).
## Origem = pe do animal, no chao.

@export_enum("galinha", "porco", "vaca", "ovelha") var bicho := "galinha":
	set(v):
		bicho = v
		queue_redraw()
@export var olha_esquerda := false:
	set(v):
		olha_esquerda = v
		queue_redraw()
## Frases, na ordem (use "|" para quebrar linha).
@export var falas: PackedStringArray = PackedStringArray(["CÓ CÓ!"])

const QUADROS := 16
const FPS := 8.0

## O pato esta perto o bastante para conversar (player.gd nao olha para cima com CIMA aqui).
var perto := false
var fala_atual := -1  # -1 = ainda nao falou nesta visita
var _t := 0.0
var _corpo: Node2D


func _ready() -> void:
	super._ready()
	add_to_group("falante")
	remove_from_group("dica")
	alcance = 30.0
	# a placa de madeira da dica sai; no lugar dela, o bicho
	for c in get_children(true):
		if c.name == "Placa":
			c.queue_free()
	_corpo = Node2D.new()
	_corpo.name = "Corpo"
	_corpo.z_index = Z_PLACA
	_corpo.draw.connect(_desenha_corpo)
	add_child(_corpo, false, Node.INTERNAL_MODE_FRONT)
	_t = fposmod(position.x * 0.37, 10.0)  # cada bicho num ponto do ciclo


func _desenha_corpo() -> void:
	var arte := bicho
	if not Sprites.has_art(arte):
		return
	var tam := Sprites.art_size(arte, QUADROS)
	var q := int(_t * FPS) % QUADROS
	# pivo: meio da largura e a ultima linha (o contorno dos pes) sobre a borda do chao
	Sprites.draw_bicho(_corpo, arte, q, QUADROS, Vector2(floorf(tam.x * 0.5), tam.y - 1.0), olha_esquerda)
	if perto and fala_atual < 0 and not Engine.is_editor_hint():
		# baloezinho "..." chamando para conversar
		var y := -tam.y - 12.0 - floorf(absf(sin(_t * 4.0)) * 2.0)
		_corpo.draw_rect(Rect2(-8, y, 16, 9), COL_BUBBLE_EDGE)
		_corpo.draw_rect(Rect2(-7, y + 1, 14, 7), COL_BUBBLE)
		for i in 3:
			_corpo.draw_rect(Rect2(-5 + i * 4, y + 4, 2, 2), Color.WHITE)
		_corpo.draw_rect(Rect2(-1, y + 9, 3, 1), COL_BUBBLE_EDGE)
		_corpo.draw_rect(Rect2(0, y + 10, 1, 1), COL_BUBBLE_EDGE)


func _lines() -> PackedStringArray:
	if fala_atual < 0 or falas.is_empty():
		return PackedStringArray([""])
	return falas[fala_atual].replace("\n", "|").split("|")


func _process(delta: float) -> void:
	_t += delta
	if _corpo != null:
		_corpo.queue_redraw()
	var target := 0.0
	if Engine.is_editor_hint():
		perto = false
		fala_atual = 0
		target = 1.0
	else:
		var p := get_tree().get_first_node_in_group("player")
		perto = p != null and Game.game_state == "playing" \
			and absf(p.position.x - position.x) < alcance and absf(p.position.y - position.y) < 32.0
		if not perto:
			fala_atual = -1
		elif Input.is_action_just_pressed("up") and not falas.is_empty():
			fala_atual = (fala_atual + 1) % falas.size()
			Game.play_sfx("select")
		if perto and fala_atual >= 0:
			target = 1.0
	var before := _show
	_show = move_toward(_show, target, delta * 6.0)
	if _balao != null:
		_balao.visible = is_visible_in_tree()
		if _show > 0.0 or before > 0.0:
			_balao.global_transform = global_transform
			_balao.queue_redraw()
	elif _show != before or Engine.is_editor_hint():
		queue_redraw()


## O balao fica acima da cabeca do bicho (a dica o poe acima da placa, 22 px).
func _desenha_balao(n: CanvasItem) -> void:
	var dy := 0.0
	if Sprites.has_art(bicho):
		dy = Sprites.art_size(bicho, QUADROS).y - 20.0
	n.draw_set_transform(Vector2(0, -dy))
	super._desenha_balao(n)
	n.draw_set_transform(Vector2.ZERO)
