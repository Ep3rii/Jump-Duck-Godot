extends Node2D
## Sombras projetadas no chao. A luz vem de cima e da ESQUERDA (o sol fica a esquerda no ceu),
## entao a sombra cai embaixo e um pouco a direita de quem a faz, e encolhe conforme o bicho
## sobe. Chapada e meio transparente, sem degrade.
##
## Quem faz sombra:
## - nos do grupo "sombra" (pato, inimigos, caixas, itens): a sombra fica embaixo da mascara
##   de colisao (get_mask); sombra_largura() -> float muda a largura (0 = sem sombra agora);
## - nos do grupo "sombra_cenario" (arvore, moinho, celeiro...) com sombra_chao() -> Rect2
##   (x inicial, y do chao, comprimento): uma faixa de sombra deitada na grama.

const Solids := preload("res://scripts/solids.gd")

const COR := Color(0.03, 0.06, 0.14, 0.3)
const ALCANCE := 112.0  # altura maxima em que ainda aparece sombra no chao
const DESVIO := 0.22  # quanto a sombra anda para a direita por px de altura

var _snap: Array = []


func _process(_delta: float) -> void:
	queue_redraw()


## Y do primeiro chao solido abaixo de (x, y), ou -1 se nao houver ate ALCANCE.
func chao_abaixo(x: float, y: float, exclude: Array) -> float:
	var passo := 8.0
	var d := 0.0
	while d < ALCANCE:
		if Solids.hits(_snap, Rect2(x - 1.0, y + d, 2.0, passo), exclude):
			var fino := 0.0
			while fino < passo and not Solids.hits(_snap, Rect2(x - 1.0, y + d + fino, 2.0, 1.0), exclude):
				fino += 1.0
			return floorf(y + d + fino)
		d += passo
	return -1.0


func _draw() -> void:
	_snap = Solids.snapshot(get_tree())
	var cam := Rect2(Game.cam_pos - Vector2(48, 48), Game.view_size + Vector2(96, 96))
	for node in get_tree().get_nodes_in_group("sombra_cenario"):
		var faixa: Rect2 = node.sombra_chao()
		if faixa.size.x > 0.0 and cam.intersects(Rect2(faixa.position.x, faixa.position.y - 4.0, faixa.size.x, 8.0)):
			_draw_strip(faixa)
	for node in get_tree().get_nodes_in_group("sombra"):
		var n2 := node as Node2D
		if n2 == null or n2.is_queued_for_deletion() or not n2.is_visible_in_tree():
			continue
		var w := 12.0
		var p := n2.global_position
		if n2.has_method("get_mask"):  # embaixo da mascara de colisao (os pes / a base)
			var m: Rect2 = n2.get_mask()
			p = Vector2(m.get_center().x, m.end.y)
			w = minf(m.size.x * 0.85, 14.0)
		if n2.has_method("sombra_largura"):
			w = n2.sombra_largura()
		if w <= 0.0 or not cam.has_point(p):
			continue
		var gy := chao_abaixo(p.x, p.y - 2.0, [n2])
		if gy < 0.0:
			continue
		var alt := maxf(0.0, gy - p.y)
		w = floorf(w * (1.0 - 0.5 * alt / ALCANCE))
		_draw_blob(floorf(p.x + alt * DESVIO), gy, w)


## Sombra de quem esta em cima (ou acima) do chao: uma pilula achatada na superficie.
func _draw_blob(cx: float, gy: float, w: float) -> void:
	if w < 3.0:
		return
	var x := cx - floorf(w * 0.5)
	draw_rect(Rect2(x + 1.0, gy + 0.5, w - 2.0, 0.5), COR)
	draw_rect(Rect2(x, gy + 1.0, w, 1.0), COR)
	draw_rect(Rect2(x + 1.0, gy + 2.0, w - 2.0, 0.5), COR)


## Faixa de sombra do cenario deitada no chao (so onde ha chao embaixo), afinando na ponta.
func _draw_strip(faixa: Rect2) -> void:
	var x := faixa.position.x
	var fim := faixa.end.x
	var y := faixa.position.y
	while x < fim:
		var w := minf(4.0, fim - x)
		if Solids.hits(_snap, Rect2(x, y + 1.0, w, 2.0)) and not Solids.hits(_snap, Rect2(x, y - 3.0, w, 2.0)):
			var ponta := fim - x <= 8.0
			draw_rect(Rect2(x, y + 0.5, w, 1.0 if ponta else 2.0), COR)
		x += 4.0
