extends Camera2D
## obj_camera: segue o jogador com suavizacao (lerp 0.8 em X, 0.1 em Y), limitado a sala.
## A altura do enquadramento vem de Level.camera_offset_y (Game.camera_offset_y).
## Limite temporario: Game.camera_limit (Rect2 em pixels do mundo; a arena do chefe,
## arena_chefe.gd, poe ali o retangulo dela) prende a camera nesse retangulo, em X e em Y: a
## posicao seguida e presa todo quadro (nao so o alvo). Quando o limite liga, a camera nao pula:
## desliza ate o enquadramento preso em Game.camera_fechar_quadros quadros (ou FECHAR_QUADROS),
## em pixels inteiros, e a parte de fora do retangulo que aparece so diminui (nunca mostra mais
## do que ja mostrava); depois disso nada fora dele aparece. Se o retangulo for menor que a
## view, ela centraliza em X e encosta embaixo em Y (a arena cobre o que sobrar). Quando o
## limite volta a ficar vazio, a camera tambem nao pula:
## faz uma transicao suave (Game.camera_soltar_quadros quadros, ou SOLTAR_QUADROS) do ultimo
## enquadramento preso ate voltar a seguir o pato normalmente.
## A posicao do canto superior esquerdo da view vai para Game.cam_pos e o tamanho da area
## mostrada para Game.view_size (paralaxe).
##
## A tela do jogo ja tem 384x216 pixels (Game.TELA: 20% a mais que os 320x180 do original) e
## e ampliada so por fatores inteiros, entao a camera nao afasta (ZOOM 1): cada pixel do jogo
## vira sempre um quadrado inteiro de pixels da tela em qualquer resolucao (3x em 720p, 5x em
## 1080p, 6x em 1440p). A posicao fica em pixels inteiros para a arte nao tremer.

const ZOOM := 1.0
const BASE := Vector2(384, 216)
const OFF_X := 2.0
## Duracao padrao (quadros de fisica) da transicao ao soltar o limite.
const SOLTAR_QUADROS := 45
## Duracao padrao (quadros de fisica) do deslize para dentro do limite quando ele liga.
const FECHAR_QUADROS := 30


var _snapped := false
var _cur := Vector2.ZERO
var _tinha_limite := false
var _soltar_de := Vector2.ZERO  # enquadramento no momento em que o limite foi solto
var _soltar_t := 0
var _soltar_n := 0
var _fechar_off := Vector2.ZERO  # quanto a view estava fora do limite quando ele ligou
var _fechar_t := 0
var _fechar_n := 0


static func view_size() -> Vector2:
	return BASE / ZOOM


func _ready() -> void:
	anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	zoom = Vector2(ZOOM, ZOOM)
	Game.view_size = view_size()
	make_current()
	_update_camera()


func _physics_process(_delta: float) -> void:
	_update_camera()


## Limita a uma faixa [lo, hi] (tamanho da faixa = 'span'); se a view for maior que a faixa,
## centraliza (ou encosta no fim, com align_end).
static func _fit(v: float, lo: float, span: float, view: float, align_end := false) -> float:
	if span <= view:
		return lo + span - view if align_end else lo + (span - view) * 0.5
	return clampf(v, lo, lo + span - view)


## Prende um canto superior esquerdo de view no retangulo 'lim' (regra de _fit nos 2 eixos).
static func preso(pos: Vector2, lim: Rect2, view: Vector2) -> Vector2:
	return Vector2(_fit(pos.x, lim.position.x, lim.size.x, view.x),
		_fit(pos.y, lim.position.y, lim.size.y, view.y, true))


## Enquadramento normal (sem limite temporario): a sala toda.
func _alvo_livre(player: Node2D, view: Vector2) -> Vector2:
	var t := Vector2(
		(player.position.x + OFF_X) - view.x / 2.0,
		(player.position.y + Game.camera_offset_y + Game.camera_olhar) - view.y / 2.0)
	t.x = _fit(t.x, 0.0, Game.room_width, view.x)
	# sala mais baixa que a view: encosta embaixo (o que sobra aparece acima do teto)
	t.y = _fit(t.y, 0.0, Game.room_height, view.y, true)
	return t


func _update_camera() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null or player.is_queued_for_deletion():
		return
	var view := view_size()
	var lim: Rect2 = Game.camera_limit
	var com_limite := lim.has_area()

	if _tinha_limite and not com_limite:
		# o limite acabou de ser solto: transicao suave a partir de onde a camera esta
		_soltar_de = _cur
		_soltar_t = 0
		_soltar_n = Game.camera_soltar_quadros if Game.camera_soltar_quadros > 0 else SOLTAR_QUADROS
		Game.camera_soltar_quadros = 0
		_fechar_n = 0
	elif com_limite and not _tinha_limite:
		# o limite acabou de ligar: em vez de pular, desliza a partir do que a tela mostra agora
		_soltar_n = 0
		_fechar_n = Game.camera_fechar_quadros if Game.camera_fechar_quadros > 0 else FECHAR_QUADROS
		Game.camera_fechar_quadros = 0
		_fechar_t = 0
		_fechar_off = position - preso(position, lim, view) if _snapped else Vector2.ZERO
		if _fechar_off == Vector2.ZERO:
			_fechar_n = 0
	_tinha_limite = com_limite

	var target := _alvo_livre(player, view)
	if com_limite:
		target = preso(target, lim, view)

	var new_pos := Vector2(lerpf(_cur.x, target.x, 0.8), lerpf(_cur.y, target.y, 0.1))
	if not _snapped:
		_snapped = true
		new_pos = target
	if com_limite:
		new_pos = preso(new_pos, lim, view)  # nunca mostra nada fora do retangulo
	_cur = new_pos

	var mostra := _cur
	if _fechar_n > 0:
		# o que sobrava fora do limite encolhe ate zero (smoothstep); a parte de fora que aparece
		# so diminui, e o seguir preso (_cur) continua por baixo
		_fechar_t += 1
		var kf := clampf(float(_fechar_t) / _fechar_n, 0.0, 1.0)
		var off := _fechar_off * (1.0 - kf * kf * (3.0 - 2.0 * kf))
		mostra = _cur + off.round()
		if _fechar_t >= _fechar_n:
			_fechar_n = 0
	elif _soltar_n > 0:
		# do enquadramento preso ate o normal, com aceleracao e freio (smoothstep)
		_soltar_t += 1
		var k := clampf(float(_soltar_t) / _soltar_n, 0.0, 1.0)
		mostra = _soltar_de.lerp(_cur, k * k * (3.0 - 2.0 * k))
		if _soltar_t >= _soltar_n:
			_soltar_n = 0
		# o seguir normal (_cur) continua por baixo; so a exibicao e misturada
	position = Vector2(floorf(mostra.x), floorf(mostra.y))
	Game.cam_pos = position
