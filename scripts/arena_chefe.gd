@tool
extends Node2D
## Arena de chefe: transforma um trecho da fase numa "fase unica" fechada.
##
## Coloque o no em qualquer lugar da fase (a posicao do no nao importa: TODAS as coordenadas
## abaixo sao em pixels do MUNDO) e configure:
## - retangulo: a area da arena. Quando o pato entra INTEIRO nele (e ja passou dos portoes), a
##   arena fecha: a camera fica presa ao retangulo (Game.camera_limit, camera.gd) e nunca mostra
##   nada fora dele, nem o que havia antes. Use um retangulo de pelo menos 384x216 (a tela);
##   se for menor, a sobra da tela vira parede escura em pixel art (tijolos da torre ou terra
##   da fazenda, ver _desenha_cortina) enquanto a arena esta fechada.
## - tipo_portao: "fazenda" (barranco de grama que sobe do chao, lagoa do jacare) ou "torre"
##   (grade de ferro que desce do teto, torre do gaviao). Arte: tools/arte/objetos.py.
## - portoes_entrada / portoes_saida: canto INFERIOR esquerdo de cada portao (como Block e
##   Porta). Cada portao tem 16x48 px; empilhe/enfileire varios para passagens maiores. Ponha
##   os portoes DENTRO do retangulo, encostados na borda (assim a camera presa mostra o portao
##   fechando), com o chao logo embaixo (fazenda) ou o teto/lintel logo em cima (torre).
## - chefe: o no do chefe. Quando os portoes terminam de fechar, a arena chama
##   chefe.comecar_luta(arena) (se existir) e emite luta_comecou. A vitoria e detectada pelo
##   sinal 'defeated' do Enemy, pelo chefe sumir da arvore ou chefe.hp <= 0 (ou chame vencer(),
##   ou ponha a arena em alvos_ao_derrotar do chefe: set_active(true) = vencer()).
##
## Fechamento natural: a camera nao pula para o retangulo; desliza (fechar_quadros, pixels
## inteiros, camera.gd) enquanto os portoes fecham, e a parte de fora que aparece so diminui.
## Depois da vitoria: espera espera_saida quadros, abre a saida (animacao reversa) e, com ela
## aberta, solta a camera com uma transicao suave (soltar_quadros) ate seguir o pato de novo.
## Se o pato voltar para fora da arena com ela fechada (caiu num buraco e reapareceu no
## checkpoint), tudo volta ao estado de antes: portoes abertos na hora, camera solta e
## chefe.reiniciar_luta() (se existir). Depois da vitoria, se ele reaparecer do lado de fora
## da entrada, a entrada abre na hora (o pato nunca fica preso do lado de fora). Game over
## recarrega a fase inteira (Game.restart_level).
## "Reapareceu fora" = o pato esta fora do retangulo E (teleportou neste quadro, o que so o
## respawn faz, OU esta alem das bordas laterais, por onde so passaria atravessando um portao
## fechado). Assim um checkpoint colado na arena nao atrapalha, e pular acima do topo nao conta.
##
## Os portoes sao solidos de verdade (grupo "solid" com get_rect(), ver solids.gd) desde que
## comecam a fechar ate terminarem de abrir. Pixel-perfect: posicoes arredondadas.

signal fechou  ## o pato entrou: camera presa e portoes fechando
signal luta_comecou  ## portoes fechados; o chefe foi avisado
signal vencida  ## chefe derrotado (a saida abre depois de espera_saida quadros)
signal liberada  ## saida aberta e camera solta
signal reiniciada  ## o pato voltou para fora com a arena fechada: tudo reaberto

const Sprites := preload("res://scripts/sprites.gd")

@export var retangulo := Rect2(0, 0, 384, 216):
	set(v):
		retangulo = v
		queue_redraw()
@export_enum("fazenda", "torre") var tipo_portao := "fazenda":
	set(v):
		tipo_portao = v
		queue_redraw()
## Canto inferior esquerdo (mundo) de cada portao de 16x48 da entrada.
@export var portoes_entrada := PackedVector2Array():
	set(v):
		portoes_entrada = v
		queue_redraw()
## Canto inferior esquerdo (mundo) de cada portao de 16x48 da saida.
@export var portoes_saida := PackedVector2Array():
	set(v):
		portoes_saida = v
		queue_redraw()
@export var chefe: NodePath
## Quadros entre a derrota do chefe e a saida comecar a abrir.
@export var espera_saida := 40
## Abre tambem a entrada depois da vitoria (padrao: ela fica fechada).
@export var reabrir_entrada := false
## Quadros da transicao suave da camera ao soltar (camera.gd).
@export var soltar_quadros := 45
## Quadros da camera deslizando para dentro do retangulo ao fechar (camera.gd). Deixe menor
## ou igual ao tempo dos portoes fecharem (Portao.FECHADO * Portao.PASSO = 30).
@export var fechar_quadros := 30

## Paredes escuras da sobra da tela (Endesga 32): fundo, juntas/veios e brilho de 1 px.
const COR_CORTINA := Color("181425")
const COR_TIJOLO := Color("262b44")
const COR_TIJOLO_LUZ := Color("3a4466")
const COR_TERRA := Color("3e2731")
const COR_TERRA_LUZ := Color("733e39")
## Distancia (px) que conta como teleporte num quadro: o pato nunca anda tanto sozinho.
const TELEPORTE := 40.0
const CameraScript := preload("res://scripts/camera.gd")

var estado := "aberta"  # aberta | fechando | luta | vencida | liberada
var _entrada: Array = []  # Portao
var _saida: Array = []
var _timer := 0
var _chefe: Node = null
var _tem_chefe := false
var _derrotado := false
var _cortina: Node2D = null
var _pos_antes := Vector2.INF  # posicao do pato no quadro anterior (detecta o respawn)
var _teleportou := false


# ------------------------------------------------------------------------- portao
## Portao de 16x48 com 16 quadros (0 = aberto, 15 = fechado). Solido enquanto nao esta aberto.
class Portao extends Node2D:
	## px da barreira visiveis em cada quadro (igual a PORTAO_ALTURAS em tools/arte/objetos.py)
	const ALTURAS := [2, 3, 5, 8, 12, 17, 23, 30, 38, 47, 48, 44, 48, 46, 48, 48]
	const FECHADO := 15
	const PASSO := 2  # quadros de fisica por quadro da animacao (16 quadros = ~0,53 s)

	var tipo := "fazenda"
	var quadro := 0
	var alvo := 0
	var _passo := 0

	func _init(t: String, canto: Vector2) -> void:
		tipo = t
		top_level = true
		position = canto.round()
		z_as_relative = false
		z_index = -745  # na frente do terreno (-800/-900), atras de itens, bichos e pato
		texture_filter = Sprites.ART_FILTER
		name = "Portao"

	## Caixa solida = parte cheia do desenho FECHADO (portao_*.png, quadro 15): na fazenda os
	## 4 px de cima sao so juncos (o pato nao pode ficar em cima deles flutuando); na torre a
	## ultima linha e vazia (vao de 1 px entre a grade e o chao).
	const CAIXA := {"fazenda": [4.0, 44.0], "torre": [0.0, 47.0]}  # [topo, altura] em px

	func get_rect() -> Rect2:
		var c: Array = CAIXA.get(tipo, [0.0, Sprites.PORTAO_TAM.y])
		return Rect2(position.x, position.y - Sprites.PORTAO_TAM.y + c[0],
			Sprites.PORTAO_TAM.x, c[1])

	func fechado() -> bool:
		return quadro == FECHADO and alvo == FECHADO

	func aberto() -> bool:
		return quadro == 0 and alvo == 0

	func fechar(na_hora := false) -> void:
		alvo = FECHADO
		if na_hora:
			quadro = FECHADO
		if na_hora or not _bloqueado():
			add_to_group("solid")  # solido desde o primeiro quadro do fechamento
		queue_redraw()

	func abrir(na_hora := false) -> void:
		alvo = 0
		if na_hora:
			quadro = 0
			_passo = 0
			if is_in_group("solid"):
				remove_from_group("solid")
		queue_redraw()

	## Algo (pato, inimigo, caixa) dentro do portao: espera para nao prender ninguem.
	func _bloqueado() -> bool:
		var r := get_rect()
		for g in ["player", "enemy", "weight"]:
			for n in get_tree().get_nodes_in_group(g):
				if n.is_queued_for_deletion() or not n.has_method("get_mask"):
					continue
				if r.intersects(n.get_mask()):
					return true
		return false

	## Um passo de fisica (chamado pela arena).
	func passo() -> void:
		if quadro == alvo:
			return
		if alvo > quadro and not is_in_group("solid"):
			if _bloqueado():
				return
			add_to_group("solid")
		_passo += 1
		if _passo < PASSO:
			return
		_passo = 0
		quadro += 1 if alvo > quadro else -1
		if quadro == 0 and is_in_group("solid"):
			remove_from_group("solid")
		queue_redraw()

	func _draw() -> void:
		var nome: String = Sprites.PORTOES.get(tipo, "portao_fazenda")
		var tam := Sprites.PORTAO_TAM
		if Sprites.has_art(nome):
			Sprites.draw_art(self, nome, 0.0, -tam.y, quadro, Sprites.PORTAO_QUADROS)
			return
		# reserva (arte ainda nao gravada): blocos lisos com a mesma altura da animacao
		var h := float(ALTURAS[quadro])
		if tipo == "torre":
			draw_rect(Rect2(0, -tam.y, tam.x, h), Color("262b44"))
			for x in [2.0, 7.0, 12.0]:
				draw_rect(Rect2(x, -tam.y, 2, h - 1.0), Color("8b9bb4"))
		else:
			draw_rect(Rect2(1, -h, tam.x - 2.0, h), Color("b86f50"))
			draw_rect(Rect2(1, -h, tam.x - 2.0, minf(h, 5.0)), Color("63c74d"))


# ------------------------------------------------------------------------- arena
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("arena_chefe")
	for c in portoes_entrada:
		var p := Portao.new(tipo_portao, c)
		add_child(p)
		_entrada.append(p)
	for c in portoes_saida:
		var p := Portao.new(tipo_portao, c)
		add_child(p)
		_saida.append(p)
	_cortina = Node2D.new()
	_cortina.name = "Cortina"
	_cortina.top_level = true
	_cortina.z_as_relative = false
	_cortina.z_index = 4000
	_cortina.draw.connect(_desenha_cortina)
	add_child(_cortina)
	_ligar_chefe.call_deferred()


func _ligar_chefe() -> void:
	if chefe.is_empty():
		return
	_chefe = get_node_or_null(chefe)
	_tem_chefe = _chefe != null
	if _chefe != null and _chefe.has_signal("defeated"):
		_chefe.connect("defeated", vencer)


func _portoes() -> Array:
	return _entrada + _saida


func _player() -> Node2D:
	var p = get_tree().get_first_node_in_group("player")
	if p == null or p.is_queued_for_deletion():
		return null
	return p


## Pato vivo inteiro dentro do retangulo e fora dos portoes.
func _pato_dentro(p: Node2D) -> bool:
	if p == null or ("player_state" in p and p.player_state == "dead"):
		return false
	var m: Rect2 = p.get_mask()
	if not retangulo.encloses(m):
		return false
	for g: Portao in _portoes():
		if g.get_rect().grow(2.0).intersects(m):
			return false
	return true


## O pato reapareceu fora da arena (checkpoint) com ela fechada: esta fora do retangulo e
## teleportou neste quadro (respawn) ou esta alem das bordas laterais (atras de um portao).
func _pato_fora(p: Node2D) -> bool:
	if p == null or ("player_state" in p and p.player_state == "dead"):
		return false
	var pos := p.global_position
	if retangulo.grow(2.0).has_point(pos):  # folga: os pes podem estar na borda de baixo
		return false
	return _teleportou or pos.x < retangulo.position.x or pos.x > retangulo.end.x


## Pato do lado de fora da entrada (do lado em que ficam os portoes de entrada).
func _pato_lado_entrada(p: Node2D) -> bool:
	if p == null or _entrada.is_empty() or retangulo.grow(2.0).has_point(p.global_position):
		return false
	var gx := 0.0
	for g: Portao in _entrada:
		gx += g.position.x + Sprites.PORTAO_TAM.x * 0.5
	gx /= _entrada.size()
	var x := p.global_position.x
	if gx < retangulo.get_center().x:
		return x < retangulo.position.x or (_teleportou and x < gx)
	return x > retangulo.end.x or (_teleportou and x > gx)


## Guarda a posicao do pato a cada quadro: um salto grande de um quadro para o outro e respawn.
func _rastreia(p: Node2D) -> void:
	if p == null:
		_teleportou = false
		_pos_antes = Vector2.INF
		return
	var pos := p.global_position
	_teleportou = _pos_antes != Vector2.INF and pos.distance_to(_pos_antes) > TELEPORTE
	_pos_antes = pos


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if Game.game_state != "playing":
		return
	for g: Portao in _portoes():
		g.passo()
	var p := _player()
	_rastreia(p)
	match estado:
		"aberta":
			if _pato_dentro(p):
				fechar()
		"fechando":
			if _pato_fora(p):
				reiniciar()
			elif _portoes().all(func(g): return g.fechado()):
				estado = "luta"
				if _chefe != null and is_instance_valid(_chefe) and _chefe.has_method("comecar_luta"):
					_chefe.comecar_luta(self)
				luta_comecou.emit()
		"luta":
			if _pato_fora(p):
				reiniciar()
			elif _chefe_derrotado():
				vencer()
		"vencida":
			if _pato_fora(p):  # caiu depois da vitoria: abre tudo (entrada tambem) de uma vez
				for g: Portao in _portoes():
					g.abrir(true)
				_liberar(1)
				return
			_timer -= 1
			if _timer == 0:
				for g: Portao in _saida:
					g.abrir()
				if reabrir_entrada:
					for g: Portao in _entrada:
						g.abrir()
				Game.play_sfx("door")
			elif _timer < 0 and _saida.all(func(g): return g.aberto()):
				_liberar(soltar_quadros)
		"liberada":
			# a entrada ficou fechada (reabrir_entrada falso) e o pato reapareceu do lado de fora
			# dela (checkpoint antes da arena): abre na hora para ele nunca ficar preso
			if _pato_lado_entrada(p) and not _entrada.all(func(g): return g.aberto()):
				for g: Portao in _entrada:
					g.abrir(true)
	_atualiza_cortina()


func _chefe_derrotado() -> bool:
	if _derrotado:
		return true
	if not _tem_chefe:
		return false
	if _chefe == null or not is_instance_valid(_chefe) or _chefe.is_queued_for_deletion():
		return true
	return "hp" in _chefe and _chefe.hp <= 0


# --------------------------------------------------------------------- API publica
## Fecha a arena (chamado sozinho quando o pato entra; os testes podem chamar direto).
func fechar() -> void:
	if estado != "aberta":
		return
	estado = "fechando"
	Game.camera_fechar_quadros = maxi(1, fechar_quadros)
	Game.camera_limit = retangulo
	Game.arena_chefe = self
	for g: Portao in _portoes():
		g.fechar()
	Game.play_sfx("door")
	fechou.emit()


## Chefe derrotado: a saida abre depois de espera_saida quadros.
func vencer() -> void:
	if estado != "luta" and estado != "fechando":
		_derrotado = true  # derrotado antes de fechar (testes): marca e segue
		return
	_derrotado = true
	estado = "vencida"
	_timer = maxi(1, espera_saida)
	vencida.emit()


## Para usar a arena em alvos_ao_derrotar (Enemy) ou numa placa: true = vencer().
func set_active(on: bool) -> void:
	if on:
		vencer()


## Volta tudo ao estado de antes de entrar (pato reapareceu fora da arena).
func reiniciar() -> void:
	for g: Portao in _portoes():
		g.abrir(true)
	estado = "aberta"
	Game.camera_soltar_quadros = 1  # corte seco: o pato acabou de reaparecer no checkpoint
	Game.camera_limit = Rect2()
	if Game.arena_chefe == self:
		Game.arena_chefe = null
	if _chefe != null and is_instance_valid(_chefe) and _chefe.has_method("reiniciar_luta"):
		_chefe.reiniciar_luta()
	_atualiza_cortina()
	reiniciada.emit()


func fechada() -> bool:
	return estado == "fechando" or estado == "luta" or estado == "vencida"


func _liberar(quadros: int) -> void:
	estado = "liberada"
	Game.camera_soltar_quadros = quadros
	Game.camera_limit = Rect2()
	if Game.arena_chefe == self:
		Game.arena_chefe = null
	_atualiza_cortina()
	liberada.emit()


# ------------------------------------------------------------------------- cortina
## So aparece quando o retangulo e menor que a tela: vira parede na sobra enquanto esta fechada.
func _atualiza_cortina() -> void:
	if _cortina == null:
		return
	var vis := fechada() and (retangulo.size.x < Game.view_size.x or retangulo.size.y < Game.view_size.y)
	_cortina.visible = vis
	if vis:
		_cortina.queue_redraw()


## Cobre a parte de fora do retangulo que a camera presa mostraria no fim do fechamento (a
## sobra de uma arena menor que a tela). Durante o deslize do fechamento, o que esta alem dessa
## sobra ainda e o mundo de verdade, que vai saindo da tela. A sobra vira parede em pixel art:
## tijolos escuros da torre ou terra escura com pedrinhas na fazenda, presos ao mundo, com uma
## linha de luz de 1 px na borda da arena.
func _desenha_cortina() -> void:
	var tela := Rect2(Game.cam_pos, Game.view_size)
	var v := Rect2(CameraScript.preso(Game.cam_pos, retangulo, Game.view_size), Game.view_size)
	var r := Rect2(retangulo.position.round(), retangulo.size.round())
	var faixas: Array[Rect2] = []
	if v.position.x < r.position.x:
		faixas.append(Rect2(v.position.x, v.position.y, r.position.x - v.position.x, v.size.y))
	if v.end.x > r.end.x:
		faixas.append(Rect2(r.end.x, v.position.y, v.end.x - r.end.x, v.size.y))
	if v.position.y < r.position.y:
		faixas.append(Rect2(r.position.x, v.position.y, r.size.x, r.position.y - v.position.y))
	if v.end.y > r.end.y:
		faixas.append(Rect2(r.position.x, r.end.y, r.size.x, v.end.y - r.end.y))
	for f in faixas:
		_parede(f.intersection(tela))
	# borda de 1 px encostada na arena (so nos lados que tem parede)
	var luz := COR_TIJOLO_LUZ if tipo_portao == "torre" else COR_TERRA_LUZ
	if v.position.x < r.position.x:
		_cortina.draw_rect(Rect2(r.position.x - 1, v.position.y, 1, v.size.y).intersection(tela), luz)
	if v.end.x > r.end.x:
		_cortina.draw_rect(Rect2(r.end.x, v.position.y, 1, v.size.y).intersection(tela), luz)


## Preenche 'f' (mundo) com a parede escura do tipo da arena, em pixels inteiros.
func _parede(f: Rect2) -> void:
	if not f.has_area():
		return
	f = Rect2(f.position.floor(), f.size.ceil())
	_cortina.draw_rect(f, COR_CORTINA)
	var x0 := int(f.position.x)
	var y0 := int(f.position.y)
	var x1 := int(f.end.x)
	var y1 := int(f.end.y)
	if tipo_portao == "torre":
		# tijolos 16x8 em amarracao: junta de 1 px em cima e a esquerda, desencontrada por fileira
		for y in range(y0 - posmod(y0, 8), y1, 8):
			var desloca := 8 if posmod(floori(y / 8.0), 2) == 1 else 0
			_risco(Rect2(x0, y, x1 - x0, 1), f, COR_TIJOLO)
			for x in range(x0 - posmod(x0 - desloca, 16), x1, 16):
				_risco(Rect2(x, y + 1, 1, 7), f, COR_TIJOLO)
				_risco(Rect2(x + 1, y + 1, 3, 1), f, COR_TIJOLO_LUZ)
	else:
		# terra escura: pedrinhas de 2x1 e pontinhos de 1 px numa grade de 8 (fixos no mundo)
		for y in range(y0 - posmod(y0, 8), y1, 8):
			for x in range(x0 - posmod(x0, 8), x1, 8):
				var h := posmod(x * 73 + y * 151, 17)
				if h < 5:
					_risco(Rect2(x + h, y + posmod(h * 3, 7), 2, 1), f, COR_TERRA)
				elif h == 9:
					_risco(Rect2(x + 3, y + 5, 1, 1), f, COR_TERRA_LUZ)


func _risco(r: Rect2, f: Rect2, cor: Color) -> void:
	var i := r.intersection(f)
	if i.has_area():
		_cortina.draw_rect(i, cor)


# ------------------------------------------------------------------------- editor
func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var o := global_position
	draw_rect(Rect2(retangulo.position - o, retangulo.size), Color(1, 0.3, 0.2), false, 1.0)
	var tam := Sprites.PORTAO_TAM
	for c in portoes_entrada:
		draw_rect(Rect2(c - o - Vector2(0, tam.y), tam), Color(0.3, 1, 0.3), false, 1.0)
	for c in portoes_saida:
		draw_rect(Rect2(c - o - Vector2(0, tam.y), tam), Color(0.3, 0.6, 1), false, 1.0)
