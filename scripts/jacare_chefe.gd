extends Enemy
## Mini-chefe jacare gigante (Fase 3). Vive na agua da arena (agua.tscn).
##
## Ciclo (vale para os 5 golpes):
## 1. nadando: submerso, vai para baixo do pato;
## 2. aviso: bolhas na superficie marcam o ponto; salto: pula da agua contra as plataformas
##    (de 2 a 4 saltos por ciclo, mais saltos com menos vida);
## 3. mordida_aviso: emerge ao lado do pato e abre a boca; mordida: avanca e morde forte 1 vez;
## 4. dor: fica na superficie "com dor de dente". So agora pode ser pisado.
##    Pisou: perde 1 de vida e mergulha (ferido). Se o tempo acaba, recomeca o ciclo.
## Encostar nele machuca, menos com dor de dente e ferido. 5 pisoes derrotam.
## Sem barra de vida: cada golpe deixa uma marca que fica ate o fim da luta (linha da tira =
## golpes levados: curativo, dente a menos, olho roxo, suor...) e ele fica mais lento para nadar
## e se mexer. A luta comeca pela arena (arena_chefe.gd, Mecanicas/ArenaChefe da fase 3): quando
## os portoes fecham ela chama comecar_luta(); se o pato reaparece fora, reiniciar_luta().

const DISPLAY_NAME := "JACARÉ GIGANTE"
const SWIM_SPEED := 2.5
const WARN_TIME := 45
const BITE_WARN_TIME := 50
const BITE_TIME := 14
const PAIN_TIME := 180
const HURT_TIME := 50
const LEAP_GRAVITY := 0.25
const SURFACE_DEPTH := 8.0  # na superficie a barriga fica 8 px abaixo da linha d'agua
const PAIN_DEPTH := 2.0  # com dor de dente boia mais alto: bochecha e boca ficam fora d'agua
const DEEP := 26.0  # submerso
const BITE_DISTANCE := 46.0  # emerge a esta distancia do pato (8 px de folga com HALF_W + meio pato)
const HALF_W := 30.0  # 60 px de colisao (a arte tem 72: a ponta fina da cauda e o focinho ficam de fora)
const HEIGHT := 16.0  # corpo de ~16 px acima da barriga (cabeca e cristas mais altas)
const BITE_REACH := 10.0
const Z_SALTO := -470  # absoluto: na frente do Jogador (-500) e da Agua (-480), atras das Dicas
const Z_BOLHAS := -479  # absoluto: logo na frente da Agua (-480), que cobriria as bolhas do aviso
const Sprites := preload("res://scripts/sprites.gd")
const QUADROS := 64  # chefe_jacare.png: nado, salto, mordida e dor, 16 quadros cada
## Cada linha da tira (32 px de altura) e um estagio de dano: linha 0 inteiro, 1..4 = golpes levados
## (JG_ESTAGIOS em tools/arte/chefes.py). Uma tira de 1 linha so (arte antiga) tambem funciona.
const LINHA_H := 32.0
## Ponto da barriga no quadro de 72x32 px (JG_W / 2 e JG_BARRIGA em tools/arte/chefes.py). O X e
## recalculado pela largura real do quadro (_pivo), entao uma tira de outra largura nao desalinha.
const PIVO := Vector2(36, 28)


var state := "espera"  # espera | nadando | aviso | salto | mordida_aviso | mordida | dor | ferido
var water: Node2D = null
var dir := -1
var leaps_left := 2
var _timer := 0
var _target_x := 0.0
var _vy := 0.0
var _mouth := 0.0
var _lunge := 0.0
var _anim := 0.0
var _bolhas: Node2D = null  # filho que desenha as bolhas do aviso na frente da agua
var _pos0 := Vector2.ZERO  # posicao inicial (reiniciar_luta)


func sombra_largura() -> float:
	return 0.0


func _enemy_ready() -> void:
	add_to_group("chefe")
	max_hp = 5
	hp = max_hp
	hurt_frames = HURT_TIME
	effect_offset = Vector2(0, -10)
	particula_derrota = "respingo"
	particulas_qtd = 30
	_bolhas = Node2D.new()
	_bolhas.z_as_relative = false
	_bolhas.z_index = Z_BOLHAS
	_bolhas.visible = false
	_bolhas.draw.connect(_draw_bubbles)
	add_child(_bolhas)
	for w in get_tree().get_nodes_in_group("agua"):
		if w.get_rect().has_point(position + Vector2(0, -2)):
			water = w
			break
	if water != null:
		position.y = _surface() + DEEP
	_pos0 = position


## Golpes ja levados (0..4): escolhe a linha de dano da tira e deixa o bicho mais lento.
func dano() -> int:
	return clampi(max_hp - hp, 0, max_hp - 1)


## Chamado pela arena quando os portoes terminam de fechar.
func comecar_luta(_arena: Node = null) -> void:
	if state != "espera" or water == null:
		return
	state = "nadando"
	leaps_left = 2
	_pick_leap_target(_player())
	Game.set_boss(DISPLAY_NAME, hp, max_hp)  # so os valores: o HUD nao desenha mais barra
	Game.play_sfx("splash")


## Chamado pela arena quando o pato reaparece fora dela (checkpoint): tudo como no inicio.
func reiniciar_luta() -> void:
	state = "espera"
	hp = max_hp
	_hurt_until = -1
	modulate.a = 1.0
	position = _pos0
	if water != null:
		position.y = _surface() + DEEP
	dir = -1
	_timer = 0
	_vy = 0.0
	_mouth = 0.0
	_lunge = 0.0
	leaps_left = 2
	Game.clear_boss()
	queue_redraw()


func _surface() -> float:
	return water.surface_y() + SURFACE_DEPTH


func _pain_surface() -> float:
	return water.surface_y() + PAIN_DEPTH


func get_mask() -> Rect2:
	var r := Rect2(roundf(position.x) - HALF_W, roundf(position.y) - HEIGHT, HALF_W * 2.0, HEIGHT)
	if state == "mordida":
		# a bocarra avanca para a frente
		var reach_x := r.end.x + BITE_REACH if dir > 0 else r.position.x - BITE_REACH
		r = r.expand(Vector2(reach_x, r.position.y))
	return r


func stomp_line_y() -> float:
	return position.y - 11.0


func harmful() -> bool:
	return hp > 0 and state != "dor" and state != "ferido" and state != "espera"


func hit(damage: int = 1) -> void:
	if state != "dor":
		return
	super(damage)
	if hp > 0:
		state = "ferido"
		_timer = HURT_TIME
		Game.boss_hp = hp


func defeat() -> void:
	Game.boss_hp = 0
	Game.clear_boss()
	Game.play_sfx("complete")
	super()


## Usado pelos testes para pular direto para um estado.
func force_state(s: String, frames := 999) -> void:
	state = s
	_timer = frames
	if s == "dor":
		position.y = _pain_surface()
	elif s == "mordida_aviso" or s == "mordida":
		position.y = _surface()


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


func _clamp_x(x: float) -> float:
	var r: Rect2 = water.get_rect()
	return clampf(x, r.position.x + HALF_W + 4.0, r.end.x - HALF_W - 4.0)


func _physics_process(_delta: float) -> void:
	if Game.game_state != "playing" or water == null:
		return
	_anim += 1.0
	var p := _player()
	stompable = state == "dor"
	if state != "espera":
		_timer -= 1

	match state:
		"espera":
			pass  # quem acorda o chefe e a arena (comecar_luta)
		"nadando":
			position.y = move_toward(position.y, _surface() + DEEP, 1.5)
			var dx := _target_x - position.x
			var vel := SWIM_SPEED - 0.25 * dano()  # cansado: nada mais devagar a cada golpe
			if absf(dx) > 1.0:
				dir = 1 if dx > 0 else -1
				position.x += clampf(dx, -vel, vel)
			elif absf(position.y - (_surface() + DEEP)) < 1.0:
				if leaps_left > 0:
					state = "aviso"
					_timer = WARN_TIME
				else:
					state = "mordida_aviso"
					_timer = BITE_WARN_TIME
					if p != null:
						dir = 1 if p.position.x > position.x else -1
		"aviso":
			if _timer <= 0:
				_start_leap(p)
		"salto":
			_vy += LEAP_GRAVITY
			position.y += _vy
			if _vy > 0.0 and position.y >= _surface():
				Game.play_sfx("splash")
				leaps_left -= 1
				state = "nadando"
				if leaps_left > 0:
					_pick_leap_target(p)
				else:
					_pick_bite_spot(p)
		"mordida_aviso":
			position.y = move_toward(position.y, _surface(), 2.0)
			_mouth = move_toward(_mouth, 1.0, 0.04)
			if _timer <= 0:
				state = "mordida"
				_timer = BITE_TIME
				Game.play_sfx("bite")
		"mordida":
			_lunge = move_toward(_lunge, BITE_REACH, 4.0)
			_mouth = 0.0 if _timer < BITE_TIME - 4 else 1.0
			if _timer <= 0:
				state = "dor"
				_timer = PAIN_TIME
				_lunge = 0.0
		"dor":
			_mouth = 0.4
			position.y = move_toward(position.y, _pain_surface(), 1.5)
			if _timer <= 0:
				_restart_cycle(p)
		"ferido":
			position.y = move_toward(position.y, _surface() + DEEP, 1.0)
			if _timer <= 0:
				_restart_cycle(p)
	# no salto o chefe passa na frente do pato (Jogador -500) e da agua (-480), para o ataque ficar
	# legivel; nos outros estados volta para o z das Entidades (o pato fica na frente e a agua
	# cobre o que esta submerso)
	z_as_relative = state != "salto"
	z_index = Z_SALTO if state == "salto" else 0
	_bolhas.visible = state == "aviso"
	if _bolhas.visible:
		_bolhas.queue_redraw()
	queue_redraw()


func _restart_cycle(p: Node2D) -> void:
	state = "nadando"
	_mouth = 0.0
	leaps_left = 2 + int((max_hp - hp) / 2.0)  # mais saltos com menos vida
	_pick_leap_target(p)


func _pick_leap_target(p: Node2D) -> void:
	_target_x = _clamp_x(p.position.x if p != null else position.x)


func _pick_bite_spot(p: Node2D) -> void:
	if p == null:
		_target_x = position.x
		return
	var r: Rect2 = water.get_rect()
	var side := -1.0 if p.position.x > r.get_center().x else 1.0
	var x := _clamp_x(p.position.x + side * BITE_DISTANCE)
	if absf(x - p.position.x) < BITE_DISTANCE * 0.6:  # encostado na borda: vai para o outro lado
		x = _clamp_x(p.position.x - side * BITE_DISTANCE)
	_target_x = x


## Salta ate a altura do pato (se ele esta acima da agua) ou um pouco acima da superficie.
func _start_leap(p: Node2D) -> void:
	var peak := _surface() - 48.0
	if p != null and p.position.y < water.surface_y():
		peak = p.position.y + 2.0
	peak = clampf(peak, _surface() - 130.0, _surface() - 32.0)
	position.y = _surface()
	_vy = -sqrt(2.0 * LEAP_GRAVITY * (position.y - peak))
	state = "salto"
	_mouth = 1.0
	Game.play_sfx("splash")


# ---------------------------------------------------------------- desenho
func _draw() -> void:
	# nadando: 0..15; salto: 16..23 subindo (focinho para cima), 24..31 descendo; mordida:
	# 32..47 (boca abrindo); dor: 48..63
	var q := int(_anim * 16.0 / (36.0 + 6.0 * dano())) % 16  # cansado: nada com mais calma
	match state:
		"salto":
			q = (16 if _vy < 0.0 else 24) + int(_anim / 3.0) % 8
		"mordida_aviso", "mordida":
			q = 32 + clampi(int(_mouth * 15.0), 0, 15)
		"dor":
			q = 48 + int(_anim / 3.0) % 16
		"ferido":
			q = 48
	var submerged := state in ["nadando", "aviso", "ferido", "espera"]
	if submerged:
		# o que passa da linha d'agua fica opaco; o que esta debaixo, translucido (a agua cobre)
		var pisca := state == "ferido" and int(_anim / 5.0) % 2 == 0
		_draw_cortado(q, Color(1, 1, 1, 0.25 if pisca else 1.0), Color(1, 1, 1, 0.25 if pisca else 0.6))
	elif state == "salto":
		# no salto o chefe fica NA FRENTE da agua (Z_SALTO): a parte ainda debaixo d'agua (no
		# primeiro e no ultimo quadro) e tingida como se a agua a cobrisse, em vez de aparecer
		# opaca e sumir de repente quando ele volta para tras da agua
		_draw_cortado(q, Color.WHITE, COR_DEBAIXO_DAGUA)
	else:
		_draw_cortado(q, Color.WHITE, Color.WHITE, Vector2(_lunge * float(dir), 0.0))


## Tinta da parte submersa quando o chefe esta na frente da agua: parecida com o sprite a 0.6
## atras da agua translucida (Agua.COL_BODY).
const COR_DEBAIXO_DAGUA := Color(0.55, 0.72, 0.95, 0.6)


## Pivo do quadro pela largura real da tira (centro em X, barriga em Y), em px inteiros.
func _pivo(fw: float) -> Vector2:
	return Vector2(floorf(fw * Sprites.ART_SCALE * 0.5), PIVO.y)


## Desenha o quadro q (na linha do dano acumulado) dividido na linha d'agua: acima com 'cima',
## abaixo com 'baixo'. 'desloc' empurra o desenho (bote da mordida), em px inteiros.
func _draw_cortado(q: int, cima: Color, baixo: Color, desloc := Vector2.ZERO) -> void:
	var t := Sprites.art("chefe_jacare")
	var fw := t.get_width() / float(QUADROS)
	var linhas := maxi(1, int(t.get_height() / LINHA_H))
	var fh := float(t.get_height()) / linhas
	var sy := fh * mini(dano(), linhas - 1)
	var esc := Sprites.ART_SCALE
	var pv := _pivo(fw)
	# linha do quadro (em px da textura) que fica na linha d'agua
	var corte := clampf(roundf((water.surface_y() - global_position.y + pv.y) / esc), 0.0, fh)
	var sx := posmod(q, QUADROS) * fw
	draw_set_transform(desloc.round(), 0.0, Vector2(-1, 1) if dir < 0 else Vector2.ONE)
	if corte > 0.0:
		draw_texture_rect_region(t, Rect2(-pv, Vector2(fw, corte) * esc), Rect2(sx, sy, fw, corte), cima)
	if corte < fh:
		draw_texture_rect_region(t, Rect2(Vector2(-pv.x, -pv.y + corte * esc), Vector2(fw, fh - corte) * esc),
			Rect2(sx, sy + corte, fw, fh - corte), baixo)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Bolhas do aviso em pixel art (cores da ENDESGA 32): aneis brancos de 5x5 e 3x3 com contorno
## escuro de 1 px (leem contra o ciano da superficie e o azul da agua), presos a grade, que sobem
## na frente do jacare e estouram na linha da agua (nunca passam dela). Na superficie, meias-bolhas
## que brotam e somem no ponto do salto. Quem desenha e o filho _bolhas (Z_BOLHAS): no proprio
## chefe elas ficariam atras do corpo e debaixo da agua, que as apagava.
const COR_BOLHA := Color("#2ce8f5")
const COR_BRILHO := Color("#ffffff")
const COR_CONTORNO_BOLHA := Color("#124e89")
const BOLHA_GRANDE := [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(0, 1), Vector2i(4, 1),
	Vector2i(0, 2), Vector2i(4, 2), Vector2i(0, 3), Vector2i(4, 3), Vector2i(1, 4), Vector2i(2, 4),
	Vector2i(3, 4)]
const BOLHA_GRANDE_CONTORNO := [Vector2i(1, -1), Vector2i(2, -1), Vector2i(3, -1), Vector2i(0, 0),
	Vector2i(4, 0), Vector2i(-1, 1), Vector2i(5, 1), Vector2i(-1, 2), Vector2i(5, 2), Vector2i(-1, 3),
	Vector2i(5, 3), Vector2i(0, 4), Vector2i(4, 4), Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5)]
const BOLHA_PEQUENA := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(2, 1), Vector2i(1, 2)]
const BOLHA_PEQUENA_CONTORNO := [Vector2i(1, -1), Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 1),
	Vector2i(3, 1), Vector2i(0, 2), Vector2i(2, 2), Vector2i(1, 3)]
## meia-bolha na linha da agua (base em y = 0, que fica na linha da agua): miolo ciano
const DOMO := [Vector2i(1, -2), Vector2i(0, -1), Vector2i(2, -1)]
const DOMO_MIOLO := [Vector2i(1, -1)]
const DOMO_CONTORNO := [Vector2i(1, -3), Vector2i(0, -2), Vector2i(2, -2), Vector2i(-1, -1), Vector2i(3, -1)]


func _pixels(o: Vector2, forma: Array, cor: Color) -> void:
	for c: Vector2i in forma:
		_bolhas.draw_rect(Rect2(o.x + c.x, o.y + c.y, 1, 1), cor)


func _draw_bubbles() -> void:
	var t := WARN_TIME - _timer
	var top := roundf(water.surface_y() - position.y)
	for i in 4:
		var k := fposmod(t * 0.6 + i * 9.0, 30.0)
		var bx := roundf(-10.0 + i * 6.0 + sin((t + i * 7) * 0.3) * 1.0)
		var by := roundf(top + 22.0 - k)
		if by >= top + 3.0:
			var grande := i % 2 == 1
			var lado := 5.0 if grande else 3.0
			var o := Vector2(bx - floorf(lado * 0.5), by - lado)
			_pixels(o, BOLHA_GRANDE_CONTORNO if grande else BOLHA_PEQUENA_CONTORNO, COR_CONTORNO_BOLHA)
			_pixels(o, BOLHA_GRANDE if grande else BOLHA_PEQUENA, COR_BRILHO)
			if grande:
				_bolhas.draw_rect(Rect2(o.x + 1, o.y + 1, 1, 1), COR_BOLHA)
		elif k < 26.0:
			# estouro na linha da agua: 4 pingos simetricos que se afastam e somem
			var d := 2.0 if k < 24.0 else 3.0
			for v: Vector2 in [Vector2(-d, 0), Vector2(d, 0), Vector2(-1, -d + 1), Vector2(1, -d + 1)]:
				_bolhas.draw_rect(Rect2(bx + v.x, top - 1.0 + v.y, 1, 1), COR_BRILHO)
	# meias-bolhas na linha da agua, juntas no ponto do salto: cada uma brota e some por vez
	for j in 3:
		if int((t + j * 5) / 6.0) % 3 == 0:
			continue
		var o := Vector2(-9.0 + j * 7.0, top)
		_pixels(o, DOMO_CONTORNO, COR_CONTORNO_BOLHA)
		_pixels(o, DOMO, COR_BRILHO)
		_pixels(o, DOMO_MIOLO, COR_BOLHA)
