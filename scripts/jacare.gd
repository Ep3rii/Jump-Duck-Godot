extends Enemy
## Jacare comum (Fases 2 e 3): vive numa agua (agua.tscn) e vai e volta nadando.
## - Na superficie, com a cabeca e as costas para fora: pode ser pisado (1 pisao derrota).
## - De tempos em tempos mergulha: ai nao pode ser pisado e so pega quem esta mergulhado.
## - Encostar nele machuca (mordida); ele abre a boca quando o pato chega perto.
## Origem = meio da barriga, embaixo. Arte: assets/sprites/arte/jacare.png (16 quadros nadando
## e 16 de mordida); a mascara continua do tamanho da do pato.

const Solids := preload("res://scripts/solids.gd")

const SURFACE_TIME := 240  # frames na superficie
const DIVE_TIME := 120  # frames mergulhado
const DIVE_DEPTH := 14.0  # quanto afunda (px)
const Z_SUPERFICIE := -475  # absoluto: logo na frente do no Agua (-480), para a parte de fora
const FLOAT_DEPTH := 4.0  # na superficie fica pouco afundado: cabeca, costas e olhos para fora
const HALF_W := 8.0  # meia largura (16 px, como o pato)
const Sprites := preload("res://scripts/sprites.gd")
const QUADROS := 32  # nado 0..15, mordida 16..31 (boca abrindo)
const PIVO := Vector2(16, 11)  # meio da barriga, no quadro (px do jogo)
const BODY_H := 9.0
## meio comprimento do desenho (32 px: focinho de um lado, ponta da cauda do outro). Vira nas
## paredes e nas bordas da agua por ele, nao pela mascara: senao o focinho e, depois de virar,
## a cauda entram uns 8 px no bloco.
const ALCANCE := 16.0


@export var velocidade := 0.4
## Comeca a ciclo ja mergulhado (para varios jacares nao mergulharem juntos).
@export var comeca_mergulhado := false

var dir := -1
var state := "surface"  # surface | dive
var water: Node2D = null
var _timer := 0
var _mouth := 0.0  # 0 fechada .. 1 aberta
var _anim := 0.0
## Parte do desenho ACIMA da linha d'agua, na frente da agua (z absoluto). O proprio no fica
## atras da agua (z relativo, como o pato) e desenha o quadro inteiro: assim barriga e patas
## submersas recebem o veu azul da agua, e cabeca e costas ficam nitidas por cima da faixa.
var _acima: Node2D = null


func sombra_largura() -> float:
	return 0.0


func _enemy_ready() -> void:
	add_to_group("jacare")
	effect_offset = Vector2(0, -6)
	particula_derrota = "respingo"
	for w in get_tree().get_nodes_in_group("agua"):
		if w.get_rect().has_point(position + Vector2(0, -2)):
			water = w
			break
	if comeca_mergulhado:
		state = "dive"
		_timer = DIVE_TIME
	else:
		_timer = SURFACE_TIME
	if water != null:
		position.y = _target_y()
	# o no Agua fica em z -480 e as Entidades em -600: o jacare fica atras da agua (a parte
	# submersa sai tingida) e so o recorte acima da superficie vai para a frente dela
	z_as_relative = true
	z_index = 0
	_acima = Node2D.new()
	_acima.name = "Acima"
	_acima.z_as_relative = false
	_acima.z_index = Z_SUPERFICIE
	_acima.draw.connect(_draw_acima)
	add_child(_acima)


func _target_y() -> float:
	var y: float = water.surface_y() + FLOAT_DEPTH
	return y + DIVE_DEPTH if state == "dive" else y


func get_mask() -> Rect2:
	return Rect2(roundf(position.x) - HALF_W, roundf(position.y) - BODY_H, HALF_W * 2.0, BODY_H)


func _physics_process(_delta: float) -> void:
	if Game.game_state != "playing" or water == null:
		return
	_timer -= 1
	_anim += 1.0
	if state == "dive" and int(_anim) % 40 == 0:
		var Particulas := load("res://scripts/particulas.gd")
		Particulas.emit(get_tree(), "bolha", position + Vector2(dir * 6.0, -4), 1)
	if _timer <= 0:
		state = "dive" if state == "surface" else "surface"
		_timer = DIVE_TIME if state == "dive" else SURFACE_TIME
	position.y = move_toward(position.y, _target_y(), 0.5)
	stompable = state == "surface" and absf(position.y - _target_y()) < 2.0

	# vai e volta dentro da agua, virando nas bordas e em paredes
	var r: Rect2 = water.get_rect()
	var nx := position.x + dir * velocidade
	var snap := Solids.snapshot(get_tree())
	var front := Rect2(nx + (ALCANCE if dir > 0 else -ALCANCE - 1.0), position.y - BODY_H, 1.0, BODY_H)
	if nx - ALCANCE < r.position.x or nx + ALCANCE > r.end.x or Solids.hits(snap, front):
		dir = -dir
	else:
		position.x = nx

	# boca abre com o pato perto (aviso da mordida)
	var p := get_tree().get_first_node_in_group("player")
	var near := p != null and absf(p.position.x - position.x) < 24.0 \
		and absf(p.position.y - position.y) < 16.0
	var before := _mouth
	_mouth = move_toward(_mouth, 1.0 if near else 0.0, 0.15)
	if near and before < 0.5 and _mouth >= 0.5:
		Game.play_sfx("bite")
	queue_redraw()
	if _acima != null:
		_acima.queue_redraw()


## Quadro atual: nadando 0..15; boca abrindo (mordida) 16..31.
func _quadro() -> int:
	var q := int(_anim * 16.0 / 36.0) % 16
	if _mouth > 0.05:
		q = 16 + clampi(int(_mouth * 15.0), 0, 15)
	return q


func _cor() -> Color:
	# mergulhado fica meio apagado
	return Color(1, 1, 1, 1.0 if state == "surface" else 0.55)


func _draw() -> void:
	# so as linhas abaixo da linha d'agua, atras da agua (as de cima ficam com _acima: desenhar
	# o quadro inteiro aqui somaria a transparencia do mergulho na parte de fora)
	var t := Sprites.art("jacare")
	var fw := t.get_width() / float(QUADROS)
	var fh := float(t.get_height())
	var alt := _linhas_acima(fh)
	if alt >= fh:
		return
	if dir < 0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	draw_texture_rect_region(t, Rect2(Vector2(-PIVO.x, alt - PIVO.y), Vector2(fw, fh - alt)),
		Rect2(_quadro() * fw, alt, fw, fh - alt), _cor())
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Quantas linhas do quadro (de cima) ficam acima da linha d'agua, em px inteiros.
func _linhas_acima(fh: float) -> float:
	if water == null:
		return 0.0  # sem agua: o quadro inteiro fica no proprio no
	var corte := roundf(water.surface_y() - global_position.y)  # y local da superficie
	return clampf(corte + PIVO.y, 0.0, fh)


## So as linhas do quadro acima da linha d'agua, na frente da agua.
func _draw_acima() -> void:
	var t := Sprites.art("jacare")
	var fw := t.get_width() / float(QUADROS)
	var alt := _linhas_acima(float(t.get_height()))
	if alt <= 0.0:
		return
	if dir < 0:
		_acima.draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	_acima.draw_texture_rect_region(t, Rect2(-PIVO, Vector2(fw, alt)),
		Rect2(_quadro() * fw, 0.0, fw, alt), _cor())
	_acima.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
