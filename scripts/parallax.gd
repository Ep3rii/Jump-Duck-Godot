extends Node2D
## Fundo das fases em camadas (parallax), com a arte de assets/sprites/arte/fundo/ (gerada por
## tools/arte/fundos.py). Desenha relativo ao canto superior esquerdo da camera (Game.cam_pos).
##
## Ceu aberto, do fundo para a frente: ceu em faixas chapadas, estrelas (a noite), sol ou lua,
## nuvens de longe, montanhas, nuvens de perto, torre do gaviao (opcional), colinas de longe,
## passaros e colinas de perto. Cada camada anda numa velocidade (quanto mais longe, mais
## devagar), na horizontal e na vertical.
## Torre por dentro: parede de tijolos com janelas, tochas e estandartes, e colunas na frente.
##
## 'hora' muda as cores do ceu, o tom das camadas e a luz da fase (ver luz.gd): o sol fica
## sempre a esquerda, de onde vem a luz dos desenhos.

const Sprites := preload("res://scripts/sprites.gd")

## Torre do gaviao ao fundo (fases do caminho ate a torre).
@export var mostrar_torre := false
## Ceu aberto (fazenda e caminho) ou parede de pedra por dentro da torre (Fases 4 a 8).
@export_enum("Céu", "Torre por dentro") var cenario := 0
## Hora do dia: cores do ceu, tom das camadas e luz ambiente da fase.
@export_enum("Manhã", "Dia", "Tarde", "Entardecer", "Noite") var hora := 1
## Tamanho da torre ao fundo: ela cresce de fase em fase, conforme o pato chega perto.
@export_enum("Longe", "Média", "Perto") var torre_distancia := 0
## Celeiro ao fundo (ceu aberto): uma peca so por fase, na camada mais perto da tela, que passa
## uma vez enquanto o pato anda (nao se repete como as tiras de morro). Fases com celeiro no
## plano do jogo (Decoracao "Celeiro") nao ganham outro ao fundo.
## So na fazenda (tutorial, A FAZENDA, em chao plano ao lado da cerca). Nas outras fases de ceu
## aberto mostrar_celeiro = false: na fase 1 o chao do comeco acaba num buraco logo depois da
## cerca (o pe dele passaria flutuando) e no lago e no pantano do jacare ele boiaria atras da agua.
@export var mostrar_celeiro := true
## X da camera (canto esquerdo) em que o celeiro fica no meio da tela. Negativo = escolhe
## sozinho um trecho de chao firme sem itens, placas e decoracao na frente (_escolhe_celeiro).
@export var celeiro_camera_x := -1.0

## Por hora: 5 faixas do ceu (de cima para baixo), tom das camadas, tom das nuvens, astro
## (sol/lua), posicao dele na tela (fracao), tom dele e luz ambiente da fase.
## As faixas do ceu usam so cores da ENDESGA 32 (a paleta da arte); como ela tem poucos
## azuis, faixas vizinhas podem repetir a cor. A faixa de baixo nunca e a cor das montanhas.
const HORAS := [
	{"ceu": [0x0099db, 0x0099db, 0x2ce8f5, 0xc0cbdc, 0xffffff], "tinta": Color(1, 1, 1),
		"nuvem": Color(1, 1, 1), "astro": "sol", "pos": Vector2(0.3, 0.37),
		"astro_tinta": Color(1, 1, 1), "ambiente": Color(1, 1, 1)},
	{"ceu": [0x0099db, 0x0099db, 0x0099db, 0x2ce8f5, 0xc0cbdc], "tinta": Color(1, 1, 1),
		"nuvem": Color(1, 1, 1), "astro": "sol", "pos": Vector2(0.23, 0.3),
		"astro_tinta": Color(1, 1, 1), "ambiente": Color(1, 1, 1)},
	{"ceu": [0x0099db, 0x0099db, 0xc0cbdc, 0xead4aa, 0xe8b796], "tinta": Color(1.0, 0.97, 0.9),
		"nuvem": Color(1.0, 0.97, 0.9), "astro": "sol", "pos": Vector2(0.3, 0.36),
		"astro_tinta": Color(1.0, 0.92, 0.72), "ambiente": Color(1, 1, 1)},
	{"ceu": [0x3a4466, 0x68386c, 0xb55088, 0xf77622, 0xfeae34], "tinta": Color(0.95, 0.7, 0.74),
		"nuvem": Color(1.0, 0.74, 0.68), "astro": "sol", "pos": Vector2(0.2, 0.6),
		"astro_tinta": Color(1.0, 0.66, 0.4), "ambiente": Color(1.0, 0.9, 0.82),
		"sobre_morros": false},
	{"ceu": [0x181425, 0x181425, 0x262b44, 0x262b44, 0x3a4466], "tinta": Color(0.42, 0.5, 0.8),
		"nuvem": Color(0.5, 0.56, 0.86), "astro": "lua", "pos": Vector2(0.24, 0.2),
		"astro_tinta": Color(1, 1, 1), "ambiente": Color(0.66, 0.72, 0.96)},
]
## Onde cada faixa do ceu comeca (fracao da altura da tela).
const FAIXAS := [0.0, 0.24, 0.44, 0.6, 0.74]

## Camadas de morro: [arte, velocidade x, velocidade y, px acima da base da tela].
const MONTANHAS := ["fundo/montanhas", 0.12, 0.15, 56.0]
const COLINAS_LONGE := ["fundo/colinas_longe", 0.25, 0.3, 54.0]
const COLINAS_PERTO := ["fundo/colinas_perto", 0.45, 0.55, 22.0]
## Nuvens: [arte, deslocamento x dentro do periodo, y na tela].
const NUVENS_LONGE := [["fundo/nuvem_pequena", 0.0, 34.0], ["fundo/nuvem_media", 150.0, 20.0],
	["fundo/nuvem_pequena", 310.0, 50.0]]
const NUVENS_PERTO := [["fundo/nuvem_grande", 40.0, 58.0], ["fundo/nuvem_media", 300.0, 82.0]]
const TORRES := ["fundo/torre_longe", "fundo/torre_media", "fundo/torre_perto"]
## Quanto da base da torre fica escondido atras das colinas (px acima da base da tela).
const TORRE_BASE := [92.0, 82.0, 62.0]

# --- por dentro da torre
const FUNDO_FATOR := 0.5  # a parede anda na metade da velocidade da camera
const COLUNA_FATOR := 0.72
const CELULA := Vector2(160.0, 144.0)  # uma janela e uma tocha a cada celula da parede
const COLUNA_PASSO := 224.0
const LUZ_TOCHA := Color(1.0, 0.86, 0.6)
const LUZ_JANELA := [Color(0.9, 0.95, 1.0), Color(0.9, 0.95, 1.0), Color(1.0, 0.92, 0.8),
	Color(1.0, 0.78, 0.7), Color(0.7, 0.8, 1.0)]
const AMBIENTE_TORRE := [Color(0.72, 0.72, 0.86), Color(0.72, 0.72, 0.86), Color(0.7, 0.68, 0.82),
	Color(0.66, 0.62, 0.8), Color(0.6, 0.62, 0.85)]

## Tempo proprio (para de contar quando o jogo pausa; as nuvens nao "pulam" ao despausar).
var _time_ms := 0.0
var _base_cor := {}


func _ready() -> void:
	add_to_group("luz")


func _process(delta: float) -> void:
	_time_ms += delta * 1000.0
	queue_redraw()


static func _cor(hex: int) -> Color:
	return Color8((hex >> 16) & 0xff, (hex >> 8) & 0xff, hex & 0xff)


## 1 pixel do jogo = 1 pixel da arte: as camadas param sempre na grade.
static func _grade(v: float) -> float:
	return floorf(v)


## So ha fontes de luz (tochas, janelas, brilho do pato e da chave) no escuro da torre; ao ar
## livre a hora do dia so da o tom da cena.
func usa_luzes() -> bool:
	return cenario == 1


## Luz ambiente da fase (luz.gd multiplica a cena por ela).
func luz_ambiente() -> Color:
	if cenario == 1:
		return AMBIENTE_TORRE[hora]
	return HORAS[hora]["ambiente"]


func _draw() -> void:
	var vx := floorf(Game.cam_pos.x)
	var vy := floorf(Game.cam_pos.y)
	var vw: float = Game.view_size.x
	var vh: float = Game.view_size.y
	if cenario == 1:
		_draw_tower_inside(vx, vy, vw, vh)
		return
	var h: Dictionary = HORAS[hora]
	var tinta: Color = h["tinta"]
	_draw_sky(vx, vy, vw, vh, h["ceu"])
	if h["astro"] == "lua":
		_draw_stars(vx, vy, vw, vh)
	_draw_astro(vx, vy, vw, vh, h)
	_draw_clouds(NUVENS_LONGE, vx, vy, vw, 0.04, 0.003, 420.0, h["nuvem"].lerp(tinta, 0.35))
	_draw_strip(MONTANHAS, vx, vy, vw, vh, tinta)
	_draw_clouds(NUVENS_PERTO, vx, vy, vw, 0.08, 0.006, 520.0, h["nuvem"])
	if mostrar_torre:
		_draw_tower(vx, vy, vw, vh, tinta)
	_draw_strip(COLINAS_LONGE, vx, vy, vw, vh, tinta)
	_draw_birds(vx, vy, vw)
	_draw_strip(COLINAS_PERTO, vx, vy, vw, vh, tinta)
	if mostrar_celeiro:
		_draw_celeiro(vx, vy, vw, vh, tinta)


func _draw_sky(vx: float, vy: float, vw: float, vh: float, ceu: Array) -> void:
	for i in FAIXAS.size():
		var y0 := floorf(vh * FAIXAS[i])
		var y1 := vh if i == FAIXAS.size() - 1 else floorf(vh * FAIXAS[i + 1])
		draw_rect(Rect2(vx, vy + y0, vw, y1 - y0), _cor(ceu[i]))


func _draw_stars(vx: float, vy: float, vw: float, vh: float) -> void:
	for i in 46:
		var sx := float((i * 97 + 31) % int(vw))
		var sy := float((i * 53 + 17) % int(vh * 0.6))
		var on := int(_time_ms / 600.0 + i * 3) % 5 != 0
		var s := 1.0
		draw_rect(Rect2(vx + sx, vy + sy, s, s), Color.WHITE if on else Color("#8b9bb4"))  # pisca trocando de cor da paleta, sem alfa


func _draw_astro(vx: float, vy: float, vw: float, vh: float, h: Dictionary) -> void:
	var pos: Vector2 = h["pos"]
	var c := Vector2(vx + floorf(vw * pos.x), vy + floorf(vh * pos.y))
	# o disco fica sempre acima do pico mais alto das montanhas (elas sobem e descem com o
	# parallax vertical): sem sol "se pondo" atras de um pico ao meio-dia. So o sol do
	# entardecer fica baixo de proposito, atras dos morros.
	if h.get("sobre_morros", true):
		var tam := Sprites.art_size(MONTANHAS[0])
		var topo := _layer_base(vy, vh, MONTANHAS[2], MONTANHAS[3]) - tam.y + _topo_arte(MONTANHAS[0])
		# disco do sol: c.y - 11 a c.y + 10; da lua: c.y - 10 a c.y + 11
		c.y = minf(c.y, _grade(topo) - (12.0 if h["astro"] == "lua" else 11.0))
	if h["astro"] == "lua":
		Sprites.draw_art(self, "fundo/lua", c.x - 16.0, c.y - 16.0)
	else:
		var quadro := int(_time_ms / 220.0) % 16
		Sprites.draw_art(self, "fundo/sol", c.x - 24.0, c.y - 24.0, quadro, 16, h["astro_tinta"])


## Fileira de nuvens que se repete a cada 'periodo' px e anda sozinha com o vento.
func _draw_clouds(lista: Array, vx: float, vy: float, vw: float, fator: float, vento: float,
		periodo: float, cor: Color) -> void:
	var x0 := vx - fposmod(vx * fator + _time_ms * vento, periodo) - periodo
	while x0 < vx + vw:
		for n: Array in lista:
			Sprites.draw_art(self, n[0], _grade(x0 + n[1]), vy + n[2], 0, 1, cor)
		x0 += periodo


## Tira de morros que se repete na horizontal. camada = [arte, fator x, fator y, altura].
func _draw_strip(camada: Array, vx: float, vy: float, vw: float, vh: float, cor: Color) -> void:
	var tam := Sprites.art_size(camada[0])
	var base := _layer_base(vy, vh, camada[2], camada[3])
	var x := vx - fposmod(vx * camada[1], tam.x)
	while x < vx + vw:
		Sprites.draw_art(self, camada[0], _grade(x), _grade(base - tam.y), 0, 1, cor)
		x += tam.x
	# abaixo da tira, a cor da base dela (salas altas mostram mais do morro)
	var fundo := vy + vh - base
	if fundo > 0.0:
		draw_rect(Rect2(vx, _grade(base), vw, fundo + 1.0), _base_color(camada[0]) * cor)


## Cor da ultima linha da tira (lida uma vez so).
func _base_color(arte: String) -> Color:
	if not _base_cor.has(arte):
		var t := Sprites.art(arte)
		_base_cor[arte] = t.get_image().get_pixel(0, t.get_height() - 1)
	return _base_cor[arte]


## Primeira linha com pixel da arte (o pico mais alto de uma tira de morros), lida uma vez so.
func _topo_arte(arte: String) -> float:
	var chave := arte + "#topo"
	if not _base_cor.has(chave):
		_base_cor[chave] = float(Sprites.art(arte).get_image().get_used_rect().position.y)
	return _base_cor[chave]


## Y da base de uma camada: 'acima' px acima da base da tela quando a camera esta no fundo da
## sala; conforme a camera sobe, a camada desce mais devagar que o mundo (fator_y).
func _layer_base(vy: float, vh: float, fator_y: float, acima: float) -> float:
	return vy + vh - acima + (Game.room_height - vh - vy) * fator_y


## Torre ao longe: perto da borda direita no inicio da fase, 90 px mais para o meio no fim.
func _draw_tower(vx: float, vy: float, vw: float, vh: float, cor: Color) -> void:
	var arte: String = TORRES[torre_distancia]
	var tam := Sprites.art_size(arte)
	var progress := clampf(vx / maxf(1.0, Game.room_width - vw), 0.0, 1.0)
	var cx := floorf(vx + vw - 34.0 - 90.0 * progress)
	var base := _layer_base(vy, vh, COLINAS_LONGE[2], TORRE_BASE[torre_distancia])
	Sprites.draw_art(self, arte, cx - tam.x * 0.5, _grade(base - tam.y), 0, 1, cor)


## Bandinhos de passaros ao longe cruzando o ceu (de tempos em tempos).
func _draw_birds(vx: float, vy: float, vw: float) -> void:
	var now := _time_ms
	var period := 14000.0
	var col := _cor(0x3a4466) if hora < 4 else _cor(0x181425)
	for flock in 2:
		var t := fposmod(now + flock * 6100.0, period) / period  # 0..1 atravessando a tela
		var bx := vx - 40.0 + t * (vw + 80.0)
		var by := vy + 26.0 + flock * 18.0 + sin(now * 0.001 + flock) * 4.0
		for i in 3:
			var px := floorf(bx - i * 9.0)
			var py := floorf(by + absf(i - 1) * 4.0 + (i % 2) * 2.0)
			var up := int(now / 180.0 + i) % 2 == 0
			var wy := py - 1.0 if up else py + 1.0
			draw_rect(Rect2(px - 2, wy, 2, 1), col)
			draw_rect(Rect2(px + 1, wy, 2, 1), col)
			draw_rect(Rect2(px, py, 1, 1), col)


# ------------------------------------------------- celeiro ao fundo
## Arte do celeiro de fundo (tools/arte/cenario.py: menor e um tom mais apagado que o do jogo,
## para ler como "perto, mas atras"). Enquanto ela nao foi gravada, usa o celeiro do jogo.
const CELEIRO_ARTE := "cenario/celeiro_fundo"
const CELEIRO_ARTE_RESERVA := "cenario/celeiro"
## Velocidade da camada do celeiro: entre as colinas de perto (0.45) e o mundo (1.0).
const CELEIRO_FATOR := 0.78
## Px do pe do celeiro escondidos atras do chao, no ponto mais baixo do chao embaixo dele.
const CELEIRO_AFUNDA := 4.0
## Fracao minima da altura do celeiro que precisa aparecer acima do chao.
const CELEIRO_VISIVEL := 0.55
## Passo da busca do lugar (px de camera) e da leitura do chao (px do mundo).
const CELEIRO_PASSO := 8.0

## [x da camera com o celeiro no meio da tela, y do pe no mundo]; [] = sem celeiro nesta fase;
## null = ainda nao escolhido (espera o terreno da fase existir).
var _celeiro: Variant = null
var _chao_cache := {}


func _celeiro_arte() -> String:
	return CELEIRO_ARTE if Sprites.has_art(CELEIRO_ARTE) else CELEIRO_ARTE_RESERVA


## X na tela do canto esquerdo do celeiro (inteiro: 1 px do jogo) com a camera em vx.
static func _celeiro_x_tela(cam_meio: float, vx: float, vw: float, w: float) -> float:
	return floorf(vw * 0.5 - w * 0.5 + (cam_meio - vx) * CELEIRO_FATOR)


## Camera em que o celeiro aparece (de -> ate): fora dessa faixa ele esta fora da tela.
static func _celeiro_alcance(vw: float, w: float) -> float:
	return (vw + w) * 0.5 / CELEIRO_FATOR


func _draw_celeiro(vx: float, vy: float, vw: float, vh: float, cor: Color) -> void:
	var c := celeiro_lugar()
	if c.is_empty():
		return
	var arte := _celeiro_arte()
	var tam := Sprites.art_size(arte)
	var x := _celeiro_x_tela(c[0], vx, vw, tam.x)
	var y: float = c[1] - tam.y
	if x >= vw or x + tam.x <= 0.0 or y >= vy + vh or c[1] <= vy:
		return
	Sprites.draw_art(self, arte, vx + x, y, 0, 1, cor)


## Lugar do celeiro desta fase ([] = nenhum). Escolhido uma vez, quando o terreno ja existe.
func celeiro_lugar() -> Array:
	if not mostrar_celeiro:
		return []
	if _celeiro == null:
		_celeiro = _escolhe_celeiro()
	return _celeiro if _celeiro != null else []


## Topo do chao firme na coluna x do mundo: o solido que vem de baixo da sala sem buraco (as
## plataformas soltas no ar nao contam); um lago conta pela superficie (o fundo dele e opaco,
## na frente do parallax). INF = buraco (o pe do celeiro apareceria).
func _chao_em(x: float) -> float:
	var chave := int(x)
	if _chao_cache.has(chave):
		return _chao_cache[chave]
	var topo := INF
	var y := float(Game.room_height) - 8.0
	while y > 0.0 and _bate(Rect2(x, y, 1.0, 1.0)):
		topo = floorf(y / 16.0) * 16.0
		y -= 16.0
	if is_inside_tree():
		for a in get_tree().get_nodes_in_group("agua"):
			if a is Node2D and a.get("tiles_w") != null:
				var p: Vector2 = (a as Node2D).global_position
				var sup: float = p.y - 16.0 * float(a.tiles_h) + 4.0
				if x >= p.x and x < p.x + 16.0 * float(a.tiles_w):
					topo = minf(topo, sup)
	_chao_cache[chave] = topo
	return topo


## Retangulos (no mundo) do que o celeiro nao deve ficar atras, com o peso de cada um: itens,
## placas de dica, saida e checkpoints (pesam muito: se misturam com ele) e o moinho e as
## arvores do plano do jogo (pesam menos: escondem o celeiro). Arbusto, cerca e junco na
## frente dele sao naturais.
func _celeiro_obstaculos() -> Array:
	var out := []
	for g in ["item", "dica", "exit", "checkpoint", "chave"]:
		for n in get_tree().get_nodes_in_group(g):
			if n is Node2D:
				var p: Vector2 = (n as Node2D).global_position
				out.append([Rect2(p.x - 12.0, p.y - 28.0, 24.0, 30.0), 100.0])
	for n in get_tree().get_nodes_in_group("sombra_cenario"):
		if n is Node2D and n.get("tipo") in [0, 3, 8]:
			var p: Vector2 = (n as Node2D).global_position
			out.append([Rect2(p.x - 32.0, p.y - 96.0, 64.0, 96.0), 30.0])
	return out


## Escolhe a camera em que o celeiro fica no meio da tela: o trecho em que ele aparece inteiro
## sobre chao firme (sem buraco embaixo, mostrando pelo menos CELEIRO_VISIVEL dele), longe da
## arena do chefe, sem itens nem placas na frente e, de preferencia, fora da tela no comeco
## (ele "passa" uma vez). null = o terreno ainda nao existe; [] = nao ha celeiro nesta fase.
func _escolhe_celeiro() -> Variant:
	if cenario != 0 or not is_inside_tree() or Game.room == "menu":
		return []
	var snap := _solidos_fixos()
	if snap.is_empty() or ((snap[0] as Array).is_empty() and (snap[1] as Array).is_empty()):
		return null
	for n in get_tree().get_nodes_in_group("sombra_cenario"):
		if n.get("tipo") == 1:
			return []  # ja ha um celeiro no plano do jogo
	var tam := Sprites.art_size(_celeiro_arte())
	var vw: float = Game.view_size.x
	var vx_max := maxf(0.0, float(Game.room_width) - vw)
	var alcance := _celeiro_alcance(vw, tam.x)
	# as fases da fazenda comecam na beira esquerda; a conta nao usa o pato (ao voltar de um
	# checkpoint ele nasce mais adiante, e o celeiro tem de ficar no mesmo lugar)
	var vx0 := 0.0
	var limite := vx_max + alcance * 0.5
	# faixas de camera da arena do chefe (arena_chefe.gd): la dentro o celeiro nunca aparece.
	# Sem arena na fase, vale o no do chefe (nada de celeiro dali em diante).
	var arenas := celeiro_faixas_proibidas()
	if arenas.is_empty():
		for ch in get_tree().get_nodes_in_group("chefe"):
			if ch is Node2D:
				limite = minf(limite, (ch as Node2D).global_position.x - vw - alcance)
	var obst := _celeiro_obstaculos()
	var candidatos: Array[float] = []
	if celeiro_camera_x >= 0.0:
		candidatos.append(celeiro_camera_x)
	else:
		var c := vx0 + 64.0
		while c <= limite:
			candidatos.append(c)
			c += CELEIRO_PASSO
	var melhor: Array = []
	var melhor_nota := INF
	for c in candidatos:
		if _celeiro_na_arena(c, alcance, arenas):
			continue
		var r := _avalia_celeiro(c, vx0, vx_max, alcance, tam, obst)
		if not r.is_empty() and (r[2] < melhor_nota or celeiro_camera_x >= 0.0):
			melhor_nota = r[2]
			melhor = [r[0], r[1]]
	return melhor


## Faixas [de, ate] do X da camera em que ela esta dentro de uma arena de chefe da fase (grupo
## "arena_chefe", retangulo no mundo): com a arena fechada a camera fica presa ali.
func celeiro_faixas_proibidas() -> Array:
	var out := []
	if not is_inside_tree():
		return out
	var vw: float = Game.view_size.x
	for a in get_tree().get_nodes_in_group("arena_chefe"):
		var r: Variant = a.get("retangulo")
		if r is Rect2:
			var ret: Rect2 = r
			out.append([ret.position.x, maxf(ret.position.x, ret.end.x - vw)])
	return out


## O celeiro centrado na camera 'c' aparece (c - alcance .. c + alcance) com a camera em alguma
## das faixas proibidas? Uma margem de 8 px evita que a borda dele encoste na tela da arena.
static func _celeiro_na_arena(c: float, alcance: float, faixas: Array) -> bool:
	for f: Array in faixas:
		if c - alcance < f[1] + 8.0 and c + alcance > f[0] - 8.0:
			return true
	return false


## [camera, y do pe, nota] do celeiro centrado na camera 'c' (nota menor = melhor), ou [].
func _avalia_celeiro(c: float, vx0: float, vx_max: float, alcance: float, tam: Vector2,
		obst: Array) -> Array:
	var vw: float = Game.view_size.x
	var a := maxf(0.0, c - alcance)
	var b := minf(vx_max, c + alcance)
	# chao embaixo de tudo o que o celeiro cobre enquanto aparece na tela
	var x_ini := a + _celeiro_x_tela(c, a, vw, tam.x) + 2.0
	var x_fim := b + _celeiro_x_tela(c, b, vw, tam.x) + tam.x - 2.0
	var pe := -INF
	var x := x_ini
	while x <= x_fim:
		var g := _chao_em(x)
		if g == INF:
			return []
		pe = maxf(pe, g)
		x += CELEIRO_PASSO
	if pe == -INF:
		return []
	pe += CELEIRO_AFUNDA
	# quanto dele aparece acima do chao com ele no meio da tela
	var topo := pe - tam.y
	var soma := 0.0
	var n := 0
	var x_meio := c + _celeiro_x_tela(c, c, vw, tam.x)
	x = x_meio + 2.0
	while x <= x_meio + tam.x - 2.0:
		soma += clampf((_chao_em(x) - topo) / tam.y, 0.0, 1.0)
		n += 1
		x += CELEIRO_PASSO
	var visivel := soma / maxf(1.0, n)
	if visivel < CELEIRO_VISIVEL:
		return []
	# itens e placas na frente dele (em cinco pontos da passagem)
	var nota := 0.0
	for i in 5:
		var v := lerpf(a, b, i / 4.0)
		var ret := Rect2(v + _celeiro_x_tela(c, v, vw, tam.x), topo, tam.x, tam.y)
		for o: Array in obst:
			if ret.intersects(o[0]):
				nota += o[1]
	if c - alcance < vx0:
		nota += 50.0 + (vx0 - (c - alcance)) * 0.2  # ja aparece no comeco da fase
	nota += (1.0 - visivel) * 40.0
	nota += absf(c - (vx0 + alcance + 96.0)) * 0.01  # cedo na fase, depois de sair da tela
	return [c, pe, nota]


# ------------------------------------------------- por dentro da torre
## Enfeites da parede (janelas, tochas e estandartes) ficam presos ao mundo (fator 1.0), e nao
## a parede de tijolos (FUNDO_FATOR): assim cada um tem um lugar fixo e da para escolher esse
## lugar pelo terreno, sem chama pousada no piso, arco de janela nascendo no chao nem
## estandarte atravessado por plataforma.
const ENFEITE_FATOR := 1.0
## Retangulo de cada enfeite em volta do seu ponto (x, y, largura, altura) e quanto precisa
## ficar livre embaixo dele.
const RET_JANELA := Rect2(-18.0, -30.0, 36.0, 60.0)
const LIVRE_JANELA := 16.0
const RET_TOCHA := Rect2(-8.0, -10.0, 16.0, 36.0)
const LIVRE_TOCHA := 24.0
## Passos para o lado que a tocha pode dar para nao ficar atras de um item (sem encostar no
## estandarte, que fica 44 px a esquerda dela, nem na janela da celula seguinte).
const TOCHA_DESVIO := [0.0, -24.0, 32.0]
const RET_BANDEIRA := Rect2(-10.0, 0.0, 20.0, 56.0)
const LIVRE_BANDEIRA := 16.0

const Solids := preload("res://scripts/solids.gd")

## Celula da grade (Vector2i) -> [janela, tocha, bandeira] ja testados no terreno (Vector2 no
## mundo, ou null quando nao coube na celula).
var _enfeites := {}
var _solidos: Array = []


## Solidos parados da fase (tiles, blocos, portas) e as placas de pressao. Caixas e
## plataformas moveis ficam de fora: mudam de lugar.
func _solidos_fixos() -> Array:
	if (_solidos.is_empty() or _solidos[1].is_empty()) and is_inside_tree():
		var nos := []
		for n in get_tree().get_nodes_in_group("solid"):
			var movel: bool = (n.is_in_group("caixa") or n.is_in_group("plataforma")
				or n.is_in_group("plataforma_cai"))
			if not movel:
				nos.append(n)
		_solidos = [nos, get_tree().get_nodes_in_group("solid_tiles"),
			get_tree().get_nodes_in_group("placa")]
	return _solidos


func _bate(ret: Rect2) -> bool:
	var snap := _solidos_fixos()
	if snap.is_empty():
		return false
	var nos: Array = (snap[0] as Array).filter(func(n): return is_instance_valid(n) and not n.is_queued_for_deletion())
	if Solids.hits([nos, snap[1]], ret):
		return true
	for p in snap[2]:
		if not is_instance_valid(p):
			continue
		var tw: int = p.get("tiles_w") if p.get("tiles_w") != null else 1
		if ret.intersects(Rect2(p.global_position.x, p.global_position.y - 16.0, 16.0 * tw, 16.0)):
			return true
	return false


## Ponto livre para um enfeite: tenta o lugar original e depois sobe de 16 em 16 px (ate 3
## vezes); se ainda bater em algo solido, o enfeite nao aparece nessa celula.
func _lugar_livre(p: Vector2, ret: Rect2, livre_embaixo: float) -> Variant:
	for i in 4:
		var q := p - Vector2(0.0, 16.0 * i)
		var r := Rect2(q + ret.position, ret.size)
		r.size.y += livre_embaixo
		if not _bate(r):
			return q
	return null


## Tocha: o lugar de sempre (_lugar_livre); se ali ela ficar bem atras de um item (flor,
## coracao, chave), o cabo e a chama se misturam com ele, entao tenta subir mais um pouco ou
## ir um passo para o lado. Se nada servir, fica onde estava.
func _lugar_tocha(p: Vector2) -> Variant:
	var q: Variant = _lugar_livre(p, RET_TOCHA, LIVRE_TOCHA)
	if q == null or not _atras_de_item(q):
		return q
	for dx: float in TOCHA_DESVIO:
		for i in 4:
			var t := p + Vector2(dx, -16.0 * i)
			var r := Rect2(t + RET_TOCHA.position, RET_TOCHA.size)
			r.size.y += LIVRE_TOCHA
			if not _bate(r) and not _atras_de_item(t):
				return t
	return q


func _atras_de_item(t: Vector2) -> bool:
	if not is_inside_tree():
		return false
	var r := Rect2(t + RET_TOCHA.position, RET_TOCHA.size).grow(2.0)
	for n in get_tree().get_nodes_in_group("item"):
		if n is Node2D and not n.is_queued_for_deletion():
			var pos: Vector2 = (n as Node2D).global_position
			if r.intersects(Rect2(pos.x - 8.0, pos.y - 16.0, 16.0, 18.0)):
				return true
	return false


func _enfeites_da_celula(c: int, r: int) -> Array:
	var chave := Vector2i(c, r)
	if _enfeites.has(chave):
		return _enfeites[chave]
	var bx := c * CELULA.x
	var by := r * CELULA.y
	var out := [_lugar_livre(Vector2(bx + 60.0, by + 62.0), RET_JANELA, LIVRE_JANELA),
		_lugar_tocha(Vector2(bx + 140.0, by + 74.0)), null]
	if posmod(c + r, 2) == 0:
		out[2] = _lugar_livre(Vector2(bx + 96.0, by + 30.0), RET_BANDEIRA, LIVRE_BANDEIRA)
	# so guarda depois que o terreno da fase existe (o teste e feito uma vez por celula)
	if not _solidos_fixos().is_empty() and not _solidos[1].is_empty():
		_enfeites[chave] = out
	return out


## Janelas e tochas da parede que aparecem na tela: [[centro da janela...], [chama da tocha...],
## [canto do estandarte...]], em coordenadas do mundo.
func _wall_points(vx: float, vy: float, vw: float, vh: float) -> Array:
	var ox := vx * ENFEITE_FATOR
	var oy := vy * ENFEITE_FATOR
	var janelas: Array[Vector2] = []
	var tochas: Array[Vector2] = []
	var bandeiras: Array[Vector2] = []
	var c0 := floori((ox - 120.0) / CELULA.x)
	var r0 := floori((oy - 110.0) / CELULA.y)
	for r in range(r0, r0 + int(vh / CELULA.y) + 3):
		for c in range(c0, c0 + int(vw / CELULA.x) + 3):
			var e := _enfeites_da_celula(c, r)
			var d := Vector2(vx - ox, vy - oy).floor()
			if e[0] != null:
				janelas.append(e[0] + d)
			if e[1] != null:
				tochas.append(e[1] + d)
			if e[2] != null:
				bandeiras.append(e[2] + d)
	return [janelas, tochas, bandeiras]


func _draw_tower_inside(vx: float, vy: float, vw: float, vh: float) -> void:
	var now := _time_ms
	# parede de tijolos (bloco de 64 px que emenda nos quatro lados)
	var ox := fposmod(vx * FUNDO_FATOR, 64.0)
	var oy := fposmod(vy * FUNDO_FATOR, 64.0)
	var y := vy - oy
	while y < vy + vh:
		var x := vx - ox
		while x < vx + vw:
			Sprites.draw_art(self, "fundo/parede", floorf(x), floorf(y))
			x += 64.0
		y += 64.0
	var pts := _wall_points(vx, vy, vw, vh)
	var ceu: Array = HORAS[hora]["ceu"]
	for j: Vector2 in pts[0]:
		# o ceu da hora da fase atras do vidro, e a janela de pedra por cima
		draw_rect(Rect2(j.x - 12.0, j.y - 22.0, 24.0, 22.0), _cor(ceu[1]))
		draw_rect(Rect2(j.x - 12.0, j.y, 24.0, 24.0), _cor(ceu[3]))
		if hora == 4:
			for i in 4:
				draw_rect(Rect2(j.x - 9.0 + i * 5.0, j.y - 16.0 + (i * 7) % 26, 1, 1), Color.WHITE)
		Sprites.draw_art(self, "fundo/janela", j.x - 18.0, j.y - 30.0)
	for b: Vector2 in pts[2]:
		Sprites.draw_art(self, "fundo/bandeira", b.x - 10.0, b.y)
	for t: Vector2 in pts[1]:
		var quadro := int(now / 40.0 + t.x * 0.37) % 16
		Sprites.draw_art(self, "fundo/tocha", t.x - 8.0, t.y - 10.0, quadro, 16)
	# colunas na frente da parede (andam um pouco mais rapido: dao profundidade)
	var cx := vx - fposmod(vx * COLUNA_FATOR, COLUNA_PASSO) - COLUNA_PASSO + 100.0
	var coy := fposmod(vy * COLUNA_FATOR, 64.0)
	while cx < vx + vw:
		var cy := vy - coy
		while cy < vy + vh:
			Sprites.draw_art(self, "fundo/coluna", floorf(cx), floorf(cy))
			cy += 64.0
		cx += COLUNA_PASSO


## Luzes da parede da torre para luz.gd: [posicao, raio, cor, forca, true]. O ultimo campo
## marca "luz do fundo" (tocha/janela): as pedras que caem nao se deixam clarear por ela.
func luzes() -> Array:
	if cenario != 1:
		return []
	var out := []
	var pts := _wall_points(floorf(Game.cam_pos.x), floorf(Game.cam_pos.y), Game.view_size.x,
		Game.view_size.y)
	for t: Vector2 in pts[1]:
		var pisca := 3.0 if int(_time_ms / 170.0 + t.x) % 3 == 0 else 0.0
		out.append([t, 60.0 + pisca, LUZ_TOCHA, 1.0, true])
	for j: Vector2 in pts[0]:
		out.append([j + Vector2(6.0, 14.0), 44.0, LUZ_JANELA[hora], 0.75, true])
	return out
