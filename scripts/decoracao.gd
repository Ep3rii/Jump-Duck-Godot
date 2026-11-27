@tool
extends Node2D
## Decoracao de cenario. Moinho, celeiro, cerca, arvores e arbusto usam a arte de
## assets/sprites/arte/cenario/ (tools/arte/cenario.py), na ESCALA DO PATO: o pato e pequeno e
## o cenario e grande. Placa de saida, junco e pilar usam objetos.py e o tileset de pedra.
## Nao colide com nada. Origem = base, no chao (centro para moinho/celeiro/arvore/arbusto,
## canto esquerdo para a cerca). Nao use 'scale': a arte so fica nitida no tamanho dela.

@export_enum("Moinho", "Celeiro", "Cerca", "Árvore", "Arbusto", "Placa de saída", "Junco", "Pilar de pedra", "Árvore jovem", "Milho", "Repolho", "Cenoura", "Espantalho") var tipo := 0:
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

## A ultima linha da arte (contorno de baixo) fica inteira em cima da borda do chao, como o pe
## do pato (arte 1:1: 1 pixel do arquivo = 1 pixel do jogo, sem meio pixel).
const BASE := 0.0
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
	if tipo in [0, 3, 6, 8, 9, 10, 11, 12]:  # moinho gira; arvores, junco e plantacoes balancam
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
		9, 10, 11, 12:
			_draw_plantacao()


## Plantacoes e espantalho da fazenda (tools/arte/fazenda.py): 16 quadros de vento, centradas
## na origem, com o pe na borda do chao. Cada peca balanca num tempo proprio.
const PLANTACOES := {9: "cenario/plantacao_milho", 10: "cenario/plantacao_repolho",
	11: "cenario/plantacao_cenoura", 12: "cenario/espantalho"}


func _draw_plantacao() -> void:
	var arte: String = PLANTACOES[tipo]
	if not Sprites.has_art(arte):
		return
	var tam := Sprites.art_size(arte, 16)
	var q := int(_time * 8.0 + position.x * 0.13) % 16
	for i in maxi(1, tiles_w if tipo != 12 else 1):
		var x := -floorf(tam.x * 0.5) + i * tam.x
		Sprites.draw_art(self, arte, x, -tam.y + BASE, (q + i * 5) % 16, 16)


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
	Sprites.draw_art(self, "cenario/moinho_corpo", -floorf(tam.x * 0.5), topo)
	# pas: 16 quadros desenhados para um quarto de volta (as 4 pas sao iguais), sem girar pixel
	var quadro := int(_time * 12.0) % 16
	var pas := Sprites.art_size("cenario/moinho_pas", 16)
	Sprites.draw_art(self, "cenario/moinho_pas", -floorf(pas.x * 0.5), topo + MOINHO_CUBO_Y - floorf(pas.y * 0.5), quadro, 16)


func _draw_celeiro() -> void:
	var tam := Sprites.art_size("cenario/celeiro")
	Sprites.draw_art(self, "cenario/celeiro", -floorf(tam.x * 0.5), -tam.y + BASE)


## Um mourao por bloco; as pontas fecham as tabuas.
func _draw_cerca() -> void:
	for i in tiles_w:
		var quadro := 1
		if tiles_w > 1 and i == 0:
			quadro = 0
		elif tiles_w > 1 and i == tiles_w - 1:
			quadro = 2
		Sprites.draw_art(self, "cenario/cerca", i * 16.0, -24.0 + BASE, quadro, 3)


## Tronco parado e copa balancando de leve (1 pixel por vez, sempre na grade da arte).
func _draw_arvore(nome: String) -> void:
	var tam := Sprites.art_size(nome + "_copa")
	var x := -floorf(tam.x * 0.5)
	var y := -tam.y + BASE
	Sprites.draw_art(self, nome + "_tronco", x, y)
	Sprites.draw_art(self, nome + "_copa", x + _sway(1.1, 1.0), y)


func _draw_arbusto() -> void:
	var tam := Sprites.art_size("cenario/arbusto")
	Sprites.draw_art(self, "cenario/arbusto", -floorf(tam.x * 0.5), -tam.y + BASE)


func _draw_placa_saida() -> void:
	Sprites.draw_art(self, "seta", -10.0, -24.0 + BASE)


func _draw_junco() -> void:
	# moita de juncos com taboas, balancando com o vento (junco.png, 16 quadros)
	var q := int(fposmod(_time * 4.6 + position.x * 0.13, 16.0))
	Sprites.draw_art(self, "junco", -8.0, -28.0 + BASE, q, 16)


## Pilar de pedra com musgo (cobre os paredoes no meio dos lagos, que no tileset de grama
## pareciam uma coluna de terra). Origem no canto inferior esquerdo.
func _draw_pilar() -> void:
	# pilar de pedra com os blocos do tileset de pedra (topo com laje, miolo em alvenaria)
	var tiles := Sprites.art("tileset_pedra")
	var h := 16.0 * tiles_h
	for j in tiles_h:
		for i in tiles_w:
			var idx := 13
			if tiles_w == 1:
				idx = 25 if j == 0 else 26
			else:
				var lado := 0 if i == 0 else (2 if i == tiles_w - 1 else 1)
				idx = (4 if j == 0 else 12) + lado
			draw_texture_rect_region(tiles, Rect2(i * 16.0, -h + j * 16.0, 16, 16),
				Rect2((idx % 4) * 16.0, (idx / 4) * 16.0, 16, 16))
