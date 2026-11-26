@tool
extends Node2D
## Placa de madeira com dica: quando o pato chega perto, mostra o texto num balao acima dela.
## Use "|" para quebrar linha (ex.: "ESPAÇO NO AR:|PULO DUPLO").
## Origem = pe da placa, no chao.

const Sprites := preload("res://scripts/sprites.gd")

const PixelFont := preload("res://scripts/pixel_font.gd")

@export_multiline var texto := "DICA":
	set(v):
		texto = v
		queue_redraw()
## Distancia (px) em que o balao aparece.
@export var alcance := 56.0

const COL_BUBBLE := Color("#193c3e")  # Endesga 32, igual ao painel da UI
const COL_BUBBLE_EDGE := Color("#63c74d")

var _show := 0.0  # 0..1 (aparece/desaparece suave)
## A placa de madeira fica num filho interno com z relativo -100 (Dicas -450 -> -550): atras
## do pato (Jogador -500), na frente do terreno. So o balao fica neste no, acima do pato.
const Z_PLACA := -100


## O balao e desenhado num CanvasLayer interno (camada 6, seguindo a camera): acima da
## pelicula de luz (luz.gd, camada 5) para o texto sair em branco puro, e abaixo do HUD (10).
const CAMADA_BALAO := 6
## Margem (px de jogo) entre o balao e a borda da tela.
const MARGEM_TELA := 2.0

var _balao: Node2D = null


func _ready() -> void:
	add_to_group("dica")
	var placa := Node2D.new()
	placa.name = "Placa"
	placa.z_index = Z_PLACA
	placa.draw.connect(func() -> void:
		# placa de madeira (dica.png, 16x20 no jogo); o pe do poste fica na origem
		Sprites.draw_art(placa, "dica", -8.0, -20.0))
	add_child(placa, false, Node.INTERNAL_MODE_FRONT)
	if not Engine.is_editor_hint():
		# no editor o CanvasLayer nao aparece na vista 2D: la o balao vai direto no _draw()
		var cl := CanvasLayer.new()
		cl.name = "CamadaBalao"
		cl.layer = CAMADA_BALAO
		cl.follow_viewport_enabled = true
		add_child(cl, false, Node.INTERNAL_MODE_FRONT)
		_balao = Node2D.new()
		_balao.name = "Balao"
		_balao.draw.connect(func() -> void: _desenha_balao(_balao))
		cl.add_child(_balao)


func _lines() -> PackedStringArray:
	return texto.replace("\n", "|").split("|")


func _process(delta: float) -> void:
	var target := 0.0
	if Engine.is_editor_hint():
		target = 1.0
	else:
		var p := get_tree().get_first_node_in_group("player")
		if p != null and absf(p.position.x - position.x) < alcance \
				and absf(p.position.y - position.y) < 48.0:
			target = 1.0
	var before := _show
	_show = move_toward(_show, target, delta * 6.0)
	if _balao != null:
		_balao.visible = is_visible_in_tree()
		if _show > 0.0 or before > 0.0:
			# acompanha a placa e a camera (o balao se prende a borda da tela)
			_balao.global_transform = global_transform
			_balao.queue_redraw()
	elif _show != before or Engine.is_editor_hint():
		queue_redraw()


func is_showing() -> bool:
	return _show > 0.5


func _draw() -> void:
	if _balao == null:
		_desenha_balao(self)


## Desenha o balao em `n` (mesmas coordenadas locais da placa: origem no pe do poste).
func _desenha_balao(n: CanvasItem) -> void:
	if _show <= 0.01:
		return
	var lines := _lines()
	var w := 0.0
	for l in lines:
		w = maxf(w, PixelFont.width(l))
	var h := lines.size() * 11.0 + 6.0
	var bw := w + 8.0
	var x0 := floorf(-w * 0.5) - 4.0
	var y0 := -22.0 - h - floorf((1.0 - _show) * 6.0)
	if not Engine.is_editor_hint() and is_inside_tree():
		# prende o balao dentro da area visivel da camera (coordenadas locais da placa)
		var inv := get_global_transform_with_canvas().affine_inverse()
		var vr := get_viewport_rect()
		var tl := inv * (vr.position + Vector2(MARGEM_TELA, MARGEM_TELA))
		var br := inv * (vr.end - Vector2(MARGEM_TELA, MARGEM_TELA))
		var left := minf(tl.x, br.x)
		var right := maxf(tl.x, br.x)
		var top := minf(tl.y, br.y)
		if right - left >= bw:
			x0 = floorf(clampf(x0, left, right - bw))
		if y0 < top:
			y0 = ceilf(top)
	# sempre na grade de pixels do jogo (inclusive durante o fade)
	x0 = floorf(x0)
	y0 = floorf(y0)
	# a caixa fica opaca por mais tempo que o texto: no fade o texto some primeiro, sobre o
	# fundo escuro, e nunca fica translucido por cima do cenario claro
	var a_caixa := minf(1.0, _show * 2.0)
	var a_texto := clampf(_show * 2.0 - 1.0, 0.0, 1.0)
	var bubble := COL_BUBBLE
	bubble.a *= a_caixa
	var edge := COL_BUBBLE_EDGE
	edge.a *= a_caixa
	# fundo so no miolo e borda em 4 tiras cheias de 1 px de jogo (como a moldura do HUD);
	# draw_rect com filled=false sairia com 1 px de tela, fino demais e fora da grade
	n.draw_rect(Rect2(x0 + 1.0, y0 + 1.0, bw - 2.0, h - 2.0), bubble)
	n.draw_rect(Rect2(x0, y0, bw, 1), edge)
	n.draw_rect(Rect2(x0, y0 + h - 1.0, bw, 1), edge)
	n.draw_rect(Rect2(x0, y0 + 1.0, 1, h - 2.0), edge)
	n.draw_rect(Rect2(x0 + bw - 1.0, y0 + 1.0, 1, h - 2.0), edge)
	# ponta sobre a placa, mas sempre encostada no balao: degrau de 4 px e depois 2 px, saindo
	# por inteiro abaixo da borda (le como bico do balao, e nao como um bloco cortado)
	var px := clampf(-2.0, x0 + 1.0, x0 + bw - 5.0)
	n.draw_rect(Rect2(px, y0 + h, 4, 1), edge)
	n.draw_rect(Rect2(px + 1.0, y0 + h + 1.0, 2, 1), edge)
	if a_texto <= 0.0:
		return
	var white := Color(1, 1, 1, a_texto)
	var cx := x0 + bw * 0.5
	for i in lines.size():
		PixelFont.draw_plain(n, cx, y0 + 9.0 + i * 11.0, lines[i], white, PixelFont.CENTER)
