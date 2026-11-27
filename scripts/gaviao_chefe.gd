extends Enemy
## Chefe gaviao (Fase Final). Grande e gordo (48x48 px). Vive numa arena isolada (arena_chefe.gd,
## grade de ferro da torre) delimitada por limite_esq / limite_dir / chao.
##
## A luta comeca quando a arena termina de fechar (comecar_luta). Ciclo (etapa 1 com 5 de vida,
## etapa 2 com mais 5):
## 1. voo: paira no alto, seguindo o pato;
## 2. sequencia de MERGULHOS: grita (aviso), mira onde o pato esta e mergulha em linha reta;
##    ao bater no chao (ou num ressalto) sobe de volta. 3 mergulhos na etapa 1, 5 na etapa 2;
## 3. INVESTIDA: desce ate a parede do lado oposto ao pato, raspa as garras e atravessa a arena
##    rente ao chao (pule por cima ou suba num ressalto)... e bate na parede da torre;
## 4. atordoado: fica no chao com estrelinhas. So agora leva golpe (pisao ou caixa
##    arremessada). Depois de 2 golpes, ou quando o tempo acaba, levanta voo e recomeca.
## Com 5 de vida perdida passa para a etapa 2 (grita, pisca vermelho, deixa cair um coracao) e
## fica mais rapido. Encostar nele machuca, menos atordoado.
##
## Sem barra de vida: o dano aparece no proprio gaviao e se acumula. A arte tem 5 linhas (uma a
## cada 2 golpes, a 1a ja no 1o golpe; cada uma soma algo novo: topete arrepiado, tres penas
## faltando na asa, cauda depenada e peito/bico sem brilho; olho roxo e a pena do meio da asa
## arrancada; todas as cores apagadas, peito arrepiado e bico lascado; ponta da asa depenada e
## falha de pele), cada golpe solta um punhado de penas, ferido ele perde penas o tempo todo e
## o voo fica mais baixo e pesado.

const DISPLAY_NAME := "GAVIÃO"
const STAGE_HP := 5
const HITS_PER_STUN := 2
const HURT_TIME := 40
const TRANSITION_TIME := 100

const VidaScene := preload("res://scenes/vida.tscn")
const Sprites := preload("res://scripts/sprites.gd")
const ARTE := "chefe_gaviao"
## chefe_gaviao.png (tools/arte/chefes.py): voo, grito, mergulho, investida, atordoado (16 cada)
const QUADROS := 80
const QUADRO := 48  # lado do quadro em px do jogo (G_LADO em chefes.py)
const LINHAS_DANO := 5  # linhas da tira: 0 = inteiro ... 4 = muito machucado (G_NIVEIS)
const PIVO := Vector2(24, 29)  # centro do corpo no quadro de 48 (G_PIVO em chefes.py)
const PIVO_32 := Vector2(16, 15)  # arte antiga de 32x32 (enquanto a nova nao for gravada)
## Distancia do centro ate a parede quando a investida bate (a cauda e o bico tem ~24 px).
const MARGEM_PAREDE := 26.0
const MARGEM_VOO := 28.0
const Solids := preload("res://scripts/solids.gd")


## Paredes e chao da arena (px). A investida termina batendo numa das paredes.
@export var limite_esq := 208.0
@export var limite_dir := 528.0
@export var chao := 192.0
## Altura do centro no voo: o topo da asa (28 px acima do centro) fica abaixo do teto.
@export var altura_voo := 66.0

var state := "espera"  # espera | voo | aviso | mergulho | subida | preparar | carga_aviso | investida | atordoado | transicao
var dir := -1
var stage := 1
var dives_left := 3
var hits_in_stun := 0
var _timer := 0
var _anim := 0.0
var _vel := Vector2.ZERO
var _target := Vector2.ZERO
var _pos_inicial := Vector2.ZERO
var _coracao: Node2D = null  ## coracao solto na etapa 2 (reiniciar_luta o tira)
var _merg_t := 0.0  ## quadros desde o comeco do mergulho (a asa fecha por etapas so uma vez)


func sombra_largura() -> float:
	return 38.0


## Clarao em volta do chefe nas fases escuras (luz.gd): o miolo (raio * 0.45 = 24 px) cobre o
## corpo 48x48 inteiro, entao ele fica com a cor da propria arte em qualquer ponto da arena,
## como o pato. Sem o 5o campo: nao conta como luz da parede.
func luzes() -> Array:
	return [[global_position, 54.0, Color(1.0, 1.0, 1.0), 0.85]]


func _enemy_ready() -> void:
	add_to_group("chefe")
	add_to_group("luz")  # luz.gd: como o pato, o chefe nao escurece longe das tochas
	max_hp = STAGE_HP * 2
	hp = max_hp
	hurt_frames = HURT_TIME
	effect_offset = Vector2(0, -6)
	particula_derrota = "pena"
	particulas_qtd = 48
	_pos_inicial = position


# ------------------------------------------------------------- parametros por etapa
func _hover_time() -> int:
	return 80 if stage == 1 else 50


func _dives() -> int:
	return 3 if stage == 1 else 5


func _warn_time() -> int:
	return 30 if stage == 1 else 20


func _dive_speed() -> float:
	return 4.0 if stage == 1 else 5.2


func _charge_warn() -> int:
	return 40 if stage == 1 else 26


func _charge_speed() -> float:
	return 4.5 if stage == 1 else 6.0


func _stun_time() -> int:
	return 170 if stage == 1 else 140


func _fly_speed() -> float:
	return 2.0 if stage == 1 else 2.8


func _charge_y() -> float:
	return chao - 9.0


## Golpes levados (0..9).
func golpes() -> int:
	return clampi(max_hp - hp, 0, max_hp)


## Linha da arte com o dano acumulado: uma a cada 2 golpes (1 golpe ja muda), 0..4.
func nivel_dano() -> int:
	return clampi(floori((golpes() + 1) / 2.0), 0, LINHAS_DANO - 1)


## Voo mais pesado com o dano: paira mais baixo e balanca mais devagar e mais fundo.
func _altura_pairar() -> float:
	return altura_voo + golpes() * 1.5 + sin(_anim * (0.07 - golpes() * 0.003)) * (4.0 + golpes() * 0.4)


# ---------------------------------------------------------------- contrato Enemy
func get_mask() -> Rect2:
	return Rect2(roundf(position.x) - 18.0, roundf(position.y) - 14.0, 36.0, 22.0)


func stomp_line_y() -> float:
	return position.y - 9.0


func harmful() -> bool:
	return hp > 0 and not state in ["espera", "atordoado", "transicao"]


func hit(damage: int = 1) -> void:
	if state != "atordoado" or is_hurt():
		return
	super(damage)
	if hp <= 0:
		return
	Game.boss_hp = hp
	# penas voando a cada golpe (o dano fica no desenho: nivel_dano)
	Particulas.emit(get_tree(), "pena", position + Vector2(0, -8), 6 + golpes())
	hits_in_stun += 1
	if hp == STAGE_HP:
		_start_transition()
	elif hits_in_stun >= HITS_PER_STUN:
		_take_off()


func defeat() -> void:
	Game.boss_hp = 0
	Game.clear_boss()
	Game.play_sfx("complete")
	super()


## Usado pelos testes para pular direto para um estado.
func force_state(s: String, frames := 999) -> void:
	state = s
	_timer = frames
	if s == "atordoado":
		position.y = chao - 8.0
		hits_in_stun = 0


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


# ---------------------------------------------------------------- arena (arena_chefe.gd)
## A arena terminou de fechar (grade da entrada e da saida descidas): comeca a luta.
func comecar_luta(_arena: Node = null) -> void:
	if state != "espera":
		return
	_start_fight()


## O pato reapareceu fora da arena: tudo volta ao comeco (vida cheia, etapa 1, no lugar).
func reiniciar_luta() -> void:
	state = "espera"
	stage = 1
	hp = max_hp
	_hurt_until = -1
	hits_in_stun = 0
	dives_left = _dives()
	_timer = 0
	_vel = Vector2.ZERO
	position = _pos_inicial
	# o coracao da etapa 2 que ficou no chao some: a luta recomeca do zero (e soltara outro)
	if _coracao_no_chao():
		_coracao.queue_free()
	_coracao = null
	Game.clear_boss()
	queue_redraw()


func _tem_arena() -> bool:
	return get_tree().get_first_node_in_group("arena_chefe") != null


# ------------------------------------------------------------------- logica
func _physics_process(_delta: float) -> void:
	if Game.game_state != "playing":
		return
	_anim += 1.0
	stompable = state == "atordoado"
	var p := _player()
	if state != "espera":
		_timer -= 1
		# ferido, perde penas o tempo todo (mais vezes quanto mais machucado)
		var g := golpes()
		if g >= 3 and int(_anim) % maxi(24, 110 - g * 9) == 0:
			Particulas.emit(get_tree(), "pena", position + Vector2(-dir * 10.0, -4.0), 1)
	match state:
		"espera":
			# sem arena (cena de teste antiga): comeca quando o pato entra entre as paredes
			if not _tem_arena() and p != null and p.position.x > limite_esq + 24.0 and p.position.x < limite_dir:
				_start_fight()
		"voo":
			var tx := clampf(p.position.x if p != null else position.x, limite_esq + MARGEM_VOO, limite_dir - MARGEM_VOO)
			var target := Vector2(tx, _altura_pairar())
			dir = 1 if target.x > position.x else -1
			position = position.move_toward(target, _fly_speed())
			if _timer <= 0:
				if dives_left > 0:
					state = "aviso"
					_timer = _warn_time()
					Game.play_sfx("screech")
				else:
					state = "preparar"
					var side := -1.0 if (p != null and p.position.x > (limite_esq + limite_dir) * 0.5) else 1.0
					_target = Vector2(limite_esq + MARGEM_PAREDE + 8.0 if side < 0 else limite_dir - MARGEM_PAREDE - 8.0, _charge_y())
		"aviso":
			if p != null:
				dir = 1 if p.position.x >= position.x else -1
			if _timer <= 0:
				_start_dive(p)
		"mergulho":
			_dive_step()
		"subida":
			var target := Vector2(clampf(position.x, limite_esq + MARGEM_VOO, limite_dir - MARGEM_VOO), altura_voo + golpes() * 1.5)
			position = position.move_toward(target, 2.5)
			if position.distance_to(target) < 1.0:
				state = "voo"
				_timer = floori(_hover_time() / 2.0)
		"preparar":
			dir = 1 if _target.x > position.x else -1
			position = position.move_toward(_target, 3.0)
			if position.distance_to(_target) < 1.0:
				state = "carga_aviso"
				_timer = _charge_warn()
				dir = 1 if position.x < (limite_esq + limite_dir) * 0.5 else -1
				Game.play_sfx("screech")
		"carga_aviso":
			if _timer <= 0:
				state = "investida"
				_vel = Vector2(dir * _charge_speed(), 0)
				Game.play_sfx("swoop")
		"investida":
			_charge_step()
		"atordoado":
			if _timer <= 0:
				_take_off()
		"transicao":
			var target := Vector2((limite_esq + limite_dir) * 0.5, altura_voo + golpes() * 1.5)
			position = position.move_toward(target, 2.0)
			if _timer <= 0:
				state = "voo"
				_timer = _hover_time()
				dives_left = _dives()
	queue_redraw()


func _start_fight() -> void:
	state = "voo"
	_timer = _hover_time()
	dives_left = _dives()
	Game.set_boss(DISPLAY_NAME, hp, max_hp)  # so os valores: o HUD nao desenha barra de chefe
	Game.play_sfx("screech")


func _start_dive(p: Node2D) -> void:
	_target = (p.position + Vector2(0, -8)) if p != null else Vector2(position.x, chao)
	var d := _target - position
	if d.length() < 1.0:
		d = Vector2(0, 1)
	_vel = d.normalized() * _dive_speed()
	_merg_t = 0.0
	state = "mergulho"
	Game.play_sfx("swoop")


func _dive_step() -> void:
	var snap := Solids.snapshot(get_tree())
	var next := position + _vel
	var r := Rect2(roundf(next.x) - 16.0, roundf(next.y) - 10.0, 32.0, 18.0)
	var out := next.x < limite_esq + 22.0 or next.x > limite_dir - 22.0 or next.y > chao - 8.0
	if out or Solids.hits(snap, r, _boxes()) or _bico_bate(snap, next):
		dives_left -= 1
		state = "subida"
		Game.play_sfx("thud")
		return
	position = next
	_merg_t += 1.0


## A pose de mergulho desce abaixo da caixa de colisao (o bico vai ate ~centro + 9 na arte
## nova, + 15 na antiga): sem isto o bico entrava ~7 px num ressalto antes da caixa bater.
## O chao fica de fora (la quem acerta e o ajuste do desenho em _draw).
func _bico_bate(snap: Array, next: Vector2) -> bool:
	var ponta := _ponta_quadro(_quadro_mergulho())
	if not ponta.has_area():
		return false
	var x0 := roundf(next.x) + (ponta.position.x if dir > 0 else -ponta.end.x)
	var y0 := roundf(next.y) + ponta.position.y
	var y1 := minf(y0 + ponta.size.y, chao)
	if y1 <= y0:
		return false
	return Solids.hits(snap, Rect2(x0, y0, ponta.size.x, y1 - y0), _boxes())


## Quadro da arte no mergulho. Descida rasa: o corpo da investida combina mais com a direcao.
## Senao 0..11 tocam uma vez (a asa fecha por etapas e o corpo inclina) e 12..15 repetem.
func _quadro_mergulho() -> int:
	if absf(_vel.y) < absf(_vel.x) * 0.45:
		return 48 + int(_anim / 1.5) % 16
	var k := int(_merg_t / 1.5)
	if k >= 12:
		k = 12 + (k - 12) % 4
	return 32 + k


func _charge_step() -> void:
	var snap := Solids.snapshot(get_tree())
	var next := position + _vel
	var r := Rect2(roundf(next.x) - 18.0, roundf(next.y) - 14.0, 36.0, 22.0)
	var na_parede := next.x < limite_esq + MARGEM_PAREDE or next.x > limite_dir - MARGEM_PAREDE
	if na_parede or Solids.hits(snap, r):
		# bateu na parede da torre (ou numa caixa no caminho): atordoado no chao
		if na_parede:
			position.x = limite_esq + MARGEM_PAREDE if _vel.x < 0.0 else limite_dir - MARGEM_PAREDE
		position.y = chao - 8.0
		state = "atordoado"
		_timer = _stun_time()
		hits_in_stun = 0
		# pedrinhas da parede e poeira no chao. O no Particulas (z_index -440) desenha NA FRENTE
		# das Entidades e dos portoes, entao a poeira so sai atras do corpo caido, a 34 px do
		# centro (a cauda vai ate ~24 px) e empurrada para longe dele
		Particulas.emit(get_tree(), "pedrinha", Vector2(position.x + dir * 24.0, chao - 2.0), 12,
			Vector2(dir * 1.6, 0.0))
		Particulas.emit(get_tree(), "pouso", Vector2(position.x - dir * 34.0, chao - 1.0), 4,
			Vector2(-dir * 1.0, 0.0))
		if golpes() > 0:  # ferido, a pancada arranca mais penas
			Particulas.emit(get_tree(), "pena", position + Vector2(0, -10), 2 + floori(golpes() / 2.0))
		Game.play_sfx("thud")
		Game.play_sfx("crack")
		return
	position = next


func _take_off() -> void:
	state = "subida"
	dives_left = _dives()
	hits_in_stun = 0


func _start_transition() -> void:
	stage = 2
	state = "transicao"
	_timer = TRANSITION_TIME
	hits_in_stun = 0
	Game.play_sfx("screech")
	# deixa cair um coracao no meio da arena (um so: se o de antes ainda esta la, nao solta outro)
	if _coracao_no_chao():
		return
	var heart := VidaScene.instantiate()
	heart.position = Vector2((limite_esq + limite_dir) * 0.5, chao)
	get_parent().add_child(heart)
	_coracao = heart


func _coracao_no_chao() -> bool:
	return is_instance_valid(_coracao) and not _coracao.is_queued_for_deletion()


## As caixas nao interrompem o mergulho (passa por cima delas).
func _boxes() -> Array:
	return get_tree().get_nodes_in_group("caixa")


# ------------------------------------------------------------------- desenho
## Tamanho do quadro e numero de linhas da tira gravada (a arte antiga de 32x32 tinha 1 linha).
static func _quadro_arte() -> Vector3:
	var t := Sprites.art(ARTE)
	if t == null:
		return Vector3(QUADRO, QUADRO, 1)
	var fw := t.get_width() / float(QUADROS)
	var linhas := maxi(1, roundi(t.get_height() / fw))
	return Vector3(fw, t.get_height() / float(linhas), linhas)


static func _pivo() -> Vector2:
	return PIVO if _quadro_arte().x >= QUADRO else PIVO_32


func _draw() -> void:
	# piscando depois do golpe (some 2 de cada 4 quadros: nada de cor fora da paleta)
	if is_hurt() and int(_anim / 2.0) % 2 == 0:
		return
	var f := float(dir)
	var q := 0
	var cor := Color.WHITE
	match state:
		"mergulho":
			q = _quadro_mergulho()
		"investida":
			q = 48 + int(_anim / 1.5) % 16
		"atordoado":
			q = 64 + int(_anim / 2.0) % 16
		"aviso":
			q = 16 + int(_anim) % 16
			if int(_anim / 3.0) % 2 == 0:
				cor = Color(1.5, 1.4, 1.2)  # pisca claro ao gritar
		"carga_aviso":
			# bloco do grito (asas no alto): nada fica pendurado ate o chao parecendo pernas
			q = 16 + int(_anim) % 16
			cor = Color(1.5, 1.4, 1.2) if int(_anim / 2.0) % 2 == 0 else Color.WHITE
		_:
			# ferido bate as asas mais devagar (voo pesado)
			q = int(_anim / (1.5 + golpes() * 0.08)) % 16
	if stage == 2 and state != "atordoado":
		cor = Color(1.0, 0.55, 0.45) if int(_anim / 6.0) % 4 == 0 else cor
	if state == "transicao":
		cor = Color(1.0, 0.55, 0.45) if int(_anim / 3.0) % 2 == 0 else Color.WHITE
	var pivo := _pivo()
	var tremor := position.round() - position  # desenho preso a grade de pixels
	if state == "carga_aviso":
		tremor.x += 1.0 if int(_anim / 2.0) % 2 == 0 else -1.0
	elif state == "atordoado":
		tremor.y += _ajuste_atordoado()  # caido: a ultima linha da arte encosta no chao
	elif state == "mergulho":
		# o mergulho para com o centro em chao - 8 (a colisao nao muda), mas a pose em diagonal
		# desce ate o bico bem abaixo disso: perto do chao so o desenho sobe, para o bico
		# encostar no piso sem atravessar
		tremor.y += minf(0.0, chao - (roundf(position.y) - pivo.y + _fundo_quadro(q) + 1.0))
	var t := Sprites.art(ARTE)
	if t == null:
		return
	var qa := _quadro_arte()
	var linha := mini(nivel_dano(), int(qa.z) - 1)
	draw_set_transform(tremor, 0.0, Vector2(-1, 1) if f < 0.0 else Vector2.ONE)
	draw_texture_rect_region(t, Rect2(-pivo, Vector2(qa.x, qa.y)),
		Rect2(posmod(q, QUADROS) * qa.x, linha * qa.y, qa.x, qa.y), cor)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Linha opaca mais baixa de cada quadro da 1a linha do chefe_gaviao.png (-1 = quadro vazio).
## Lida uma vez da propria arte (vale mesmo se o PNG for refeito).
static var _fundos := PackedInt32Array()


static func _fundo_quadro(q: int) -> int:
	if _fundos.is_empty():
		_fundos.resize(QUADROS)
		_fundos.fill(-1)
		var t := Sprites.art(ARTE)
		var img := t.get_image() if t != null else null
		if img != null:
			if img.is_compressed():
				img.decompress()
			var qa := _quadro_arte()
			var fw := int(qa.x)
			for k in QUADROS:
				for y in range(int(qa.y) - 1, -1, -1):
					var achou := false
					for x in fw:
						if img.get_pixel(k * fw + x, y).a > 0.5:
							achou = true
							break
					if achou:
						_fundos[k] = y
						break
	return _fundos[posmod(q, QUADROS)]


## Retangulo (relativo ao centro, sem espelhar) da parte opaca de cada quadro da 1a linha que
## fica abaixo da caixa de colisao do mergulho (centro + 8): o bico da pose em diagonal.
## Rect2() = nada passa da caixa. Lido uma vez da propria arte.
static var _pontas := {}


static func _ponta_quadro(q: int) -> Rect2:
	q = posmod(q, QUADROS)
	if _pontas.has(q):
		return _pontas[q]
	var r := Rect2()
	var t := Sprites.art(ARTE)
	var img := t.get_image() if t != null else null
	if img != null:
		if img.is_compressed():
			img.decompress()
		var qa := _quadro_arte()
		var pv := _pivo()
		var fw := int(qa.x)
		var y0 := int(pv.y) + 8
		var x_min := fw
		var x_max := -1
		var y_max := -1
		for y in range(maxi(y0, 0), int(qa.y)):
			for x in fw:
				if img.get_pixel(q * fw + x, y).a > 0.5:
					x_min = mini(x_min, x)
					x_max = maxi(x_max, x)
					y_max = y
		if y_max >= 0:
			r = Rect2(x_min - pv.x, y0 - pv.y, x_max + 1 - x_min, y_max + 1 - y0)
	_pontas[q] = r
	return r


## Atordoado o corpo fica em chao - 8 (a colisao nao muda). Desloca so o desenho para que a
## linha opaca mais baixa dos quadros de atordoado (64..79) termine exatamente no chao, em vez
## de entrar no piso.
static var _ajuste_chao := INF


static func _ajuste_atordoado() -> float:
	if _ajuste_chao == INF:
		_ajuste_chao = 0.0
		var fundo := -1
		for q in range(64, 80):
			fundo = maxi(fundo, _fundo_quadro(q))
		if fundo >= 0:
			# linha y do quadro ocupa [chao - 8 - pivo.y + y, +1): termina no chao com
			# y = pivo.y + 7
			_ajuste_chao = _pivo().y + 7.0 - fundo
	return _ajuste_chao
