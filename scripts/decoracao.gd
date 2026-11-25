@tool
extends Node2D
## Decoracao de cenario. Moinho, celeiro, cerca, arvores e arbusto usam a arte de
## assets/sprites/arte/cenario/ (tools/arte/cenario.py), na ESCALA DO PATO: o pato e pequeno e
## o cenario e grande. Placa de saida, junco e pilar ainda sao desenhados em codigo.
## Nao colide com nada. Origem = base, no chao (centro para moinho/celeiro/arvore/arbusto,
## canto esquerdo para a cerca). Nao use 'scale': a arte so fica nitida no tamanho dela.

@export_enum("Moinho", "Celeiro", "Cerca", "Árvore", "Arbusto", "Placa de saída", "Junco", "Pilar de pedra", "Árvore jovem") var tipo := 0:
	set(v):
		tipo = v
		queue_redraw()
## Largura da cerca / do pilar em tiles de 16 px.
@export var tiles_w := 3:
	set(v):
		tiles_w = v
		queue_redraw()
## Altura do pilar de pedra em tiles (o pilar cobre por cima um paredao de terra do mapa).
@export var tiles_h := 4:
	set(v):
		tiles_h = v
		queue_redraw()

const Sprites := preload("res://scripts/sprites.gd")

## A ultima linha da arte (contorno de baixo) fica em cima da borda do chao, como o pe do pato.
const BASE := 0.5
const MOINHO_CUBO_Y := 26.0  # centro das pas, a partir do topo do corpo (px do jogo)
## Comprimento da sombra deitada no chao de cada tipo (0 = sem sombra), em px.
const SOMBRA := {0: 70.0, 1: 120.0, 3: 64.0, 4: 34.0, 8: 40.0}

const OUTLINE := Color8(40, 28, 20)
const STONE := Color8(196, 186, 160)
const STONE_DARK := Color8(150, 140, 116)
const WOOD := Color8(150, 92, 44)
const WOOD_DARK := Color8(104, 60, 28)
const WOOD_LIGHT := Color8(196, 136, 74)
const LEAF := Color8(71, 160, 40)
const LEAF_DARK := Color8(40, 110, 30)

var _time := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if tipo in [3, 8]:
		add_to_group("decoracao_arvore")  # ambiente.gd solta folhas delas
	if SOMBRA.has(tipo):
		add_to_group("sombra_cenario")


func _process(delta: float) -> void:
	if tipo in [0, 3, 6, 8]:  # moinho gira; arvores e junco balancam com o vento
		_time += delta
		queue_redraw()


## Balanco suave (px) com fase diferente para cada objeto.
func _sway(speed: float, amount: float) -> float:
	return floorf(sin(_time * speed + position.x * 0.07) * amount + 0.5)


func _draw() -> void:
	match tipo:
		0:
			_draw_moinho()
		1:
			_draw_celeiro()
		2:
			_draw_cerca()
		3:
			_draw_arvore("cenario/arvore")
		8:
			_draw_arvore("cenario/arvore_jovem")
		4:
			_draw_arbusto()
		5:
			_draw_placa_saida()
		6:
			_draw_junco()
		7:
			_draw_pilar()


## Faixa de sombra no chao (sombras.gd): comeca embaixo da peca e se estende para a direita,
## porque a luz vem de cima e da esquerda. Rect2(x inicial, y do chao, comprimento, 0).
func sombra_chao() -> Rect2:
	var comp: float = SOMBRA.get(tipo, 0.0)
	return Rect2(global_position.x - comp * 0.3, global_position.y, comp, 0.0)


## Altura da copa (px acima da base): ambiente.gd solta as folhas dali.
func altura_copa() -> float:
	return 78.0 if tipo == 3 else 46.0


func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), c)


func _draw_moinho() -> void:
	var tam := Sprites.art_size("cenario/moinho_corpo")
	var topo := -tam.y + BASE
	Sprites.draw_art(self, "cenario/moinho_corpo", -tam.x * 0.5, topo)
	# pas: 8 quadros desenhados para um quarto de volta (as 4 pas sao iguais), sem girar pixel
	var quadro := int(_time * 6.0) % 8
	var pas := Sprites.art_size("cenario/moinho_pas", 8)
	Sprites.draw_art(self, "cenario/moinho_pas", -pas.x * 0.5, topo + MOINHO_CUBO_Y - pas.y * 0.5, quadro, 8)


func _draw_celeiro() -> void:
	var tam := Sprites.art_size("cenario/celeiro")
	Sprites.draw_art(self, "cenario/celeiro", -tam.x * 0.5, -tam.y + BASE)


## Um mourao por bloco; as pontas fecham as tabuas.
func _draw_cerca() -> void:
	for i in tiles_w:
		var quadro := 1
		if tiles_w > 1 and i == 0:
			quadro = 0
		elif tiles_w > 1 and i == tiles_w - 1:
			quadro = 2
		Sprites.draw_art(self, "cenario/cerca", i * 16.0, -24.0 + BASE, quadro, 3)


## Tronco parado e copa balancando de leve (meio pixel por vez, sempre na grade da arte).
func _draw_arvore(nome: String) -> void:
	var tam := Sprites.art_size(nome + "_copa")
	var x := -tam.x * 0.5
	var y := -tam.y + BASE
	Sprites.draw_art(self, nome + "_tronco", x, y)
	Sprites.draw_art(self, nome + "_copa", x + _sway(1.1, 1.0) * 0.5, y)


func _draw_arbusto() -> void:
	var tam := Sprites.art_size("cenario/arbusto")
	Sprites.draw_art(self, "cenario/arbusto", -tam.x * 0.5, -tam.y + BASE)


func _draw_placa_saida() -> void:
	# seta de madeira apontando para a direita
	_r(-1, -20, 3, 20, WOOD_DARK)
	_r(-10, -26, 18, 9, OUTLINE)
	_r(-9, -25, 16, 7, WOOD)
	for i in 5:
		_r(8 + i, -26 + i, 1, 9 - i * 2, OUTLINE if i == 4 else WOOD)
	_r(-6, -22, 10, 1, WOOD_LIGHT)


func _draw_junco() -> void:
	# moita de juncos/taboas da beira do lago
	# cada haste se curva com o vento, mais na ponta
	var stems := [[-6, 22], [-3, 28], [0, 20], [3, 26], [6, 18]]
	for i in stems.size():
		var st: Array = stems[i]
		var h: int = st[1]
		for seg in 4:
			var y0 := -h + seg * h / 4.0
			var bend := sin(_time * 1.8 + i * 0.9 + position.x * 0.05) * 1.5 * (1.0 - seg / 4.0)
			var x: float = st[0] + floorf(bend + 0.5)
			_r(x, y0, 1, ceilf(h / 4.0), LEAF_DARK)
			_r(x + 1, y0 + 1, 1, ceilf(h / 4.0) - 1, LEAF)
	for i in [1, 3]:
		var st: Array = stems[i]
		var bend := floorf(sin(_time * 1.8 + i * 0.9 + position.x * 0.05) * 1.5 + 0.5)
		_r(st[0] - 1 + bend, -st[1] - 1, 3, 7, OUTLINE)
		_r(st[0] + bend, -st[1], 1, 5, WOOD)


## Pilar de pedra com musgo (cobre os paredoes no meio dos lagos, que no tileset de grama
## pareciam uma coluna de terra). Origem no canto inferior esquerdo.
func _draw_pilar() -> void:
	var w := 16.0 * tiles_w
	var h := 16.0 * tiles_h
	_r(0, -h, w, h, Color8(60, 58, 70))
	for row in int(h / 8.0):
		var y := -h + row * 8.0
		var shift := 6.0 if row % 2 == 1 else 0.0
		var x := -shift
		var n := 0
		while x < w:
			var bx := maxf(x, 0.0) + 1.0
			var bw := minf(x + 12.0, w) - bx - 1.0
			if bw > 0.0:
				var hsh := posmod(row * 7 + n * 13 + int(position.x), 5)
				var c := STONE if hsh > 1 else STONE_DARK
				var wet := clampf((y + h) / h, 0.0, 1.0)  # mais escuro e molhado embaixo
				c = c.darkened(wet * 0.35)
				_r(bx, y + 1, bw, 6, c)
				_r(bx, y + 1, bw, 1, c.lightened(0.25))
			x += 12.0
			n += 1
	# musgo descendo do alto e em manchas
	for i in tiles_w * 4:
		var mx := float(i * 4)
		var drip := 3.0 + posmod(i * 5 + int(position.x), 7)
		_r(mx, -h, 4, drip, LEAF_DARK)
		_r(mx, -h, 4, 2, LEAF)
	for i in int(h / 24.0):
		var my := -h + 12.0 + i * 24.0
		var mx := float(posmod(i * 11 + int(position.x), int(w) - 6))
		_r(mx, my, 6, 3, LEAF_DARK)
		_r(mx + 1, my, 4, 1, LEAF)
	_r(0, -h, 1, h, OUTLINE)
	_r(w - 1, -h, 1, h, OUTLINE)
