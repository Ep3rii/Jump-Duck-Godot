extends CanvasLayer
## Luz da fase: uma pelicula por cima do mundo (e por baixo do HUD) que MULTIPLICA a cena pela
## luz ambiente e abre "clareiras" em volta de cada fonte de luz (tocha, janela, chave, pato).
## Em faixas chapadas e presas a grade da arte, sem degrade: o mesmo estilo dos desenhos.
##
## Quem ilumina: nos do grupo "luz" com a funcao luzes() -> Array de [posicao (mundo), raio (px),
## cor, forca 0..1]. A luz ambiente vem do Parallax da fase (luz_ambiente(), pela 'hora').
## De dia, ao ar livre, a luz ambiente e branca e nao ha luzes: a pelicula fica desligada.

const MAX_LUZES := 32
const SHADER := """
shader_type canvas_item;
render_mode blend_mul, unshaded;

uniform vec3 ambiente = vec3(1.0);
uniform vec2 cam = vec2(0.0);
uniform vec2 vista = vec2(384.0, 216.0);
uniform int n = 0;
uniform vec3 luz_pos[32];  // x, y (mundo) e raio
uniform vec4 luz_cor[32];  // cor e forca

void fragment() {
	// ponto do mundo, preso a grade da arte (1 pixel do jogo)
	vec2 p = cam + floor(UV * vista) + 0.5;
	// cada luz devolve a clareira a cor da propria arte, com so um leve tom da luz (a pedra
	// azul nao vira cinza/caqui e o pato branco nao fica creme); as luzes se juntam pelo
	// maximo de cada canal, entao a luz branca do pato vence a tocha em cima dele
	vec3 res = ambiente;
	for (int i = 0; i < n; i++) {
		float d = distance(p, luz_pos[i].xy) / luz_pos[i].z;
		// tres faixas chapadas: miolo, meio e borda
		float k = d < 0.45 ? 1.0 : (d < 0.75 ? 0.62 : (d < 1.0 ? 0.3 : 0.0));
		k *= luz_cor[i].a;
		vec3 tom = mix(vec3(1.0), luz_cor[i].rgb, 0.3);
		res = max(res, mix(ambiente, tom, k));
	}
	COLOR = vec4(res, 1.0);
}
"""

var _rect: ColorRect
var _mat: ShaderMaterial
var _parallax: Node
## O que a pelicula usa agora (para luz_em()): luz ambiente e luzes enviadas ao shader.
var _amb := Color.WHITE
var _ativas: Array = []


func _ready() -> void:
	add_to_group("pelicula_luz")
	layer = 5  # acima do mundo (0), abaixo do HUD (10)
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	_rect.material = _mat
	add_child(_rect)
	_parallax = get_parent().get_node_or_null("Parallax")
	_update()


func _process(_delta: float) -> void:
	_update()


## Luz ambiente da fase (branco = dia claro).
func ambiente() -> Color:
	if _parallax != null and _parallax.has_method("luz_ambiente"):
		return _parallax.luz_ambiente()
	return Color.WHITE


## Luzes acesas agora: [posicao, raio, cor, forca] de todo no do grupo "luz".
func coletar() -> Array:
	var out := []
	var vista := Rect2(Game.cam_pos, Game.view_size)
	for node in get_tree().get_nodes_in_group("luz"):
		if node.is_queued_for_deletion() or not node.has_method("luzes"):
			continue
		for l: Array in node.luzes():
			# so as que alcancam a tela (o shader aceita ate MAX_LUZES)
			var p: Vector2 = l[0]
			var r: float = l[1]
			if vista.grow(r).has_point(p):
				out.append(l)
	return out


func _update() -> void:
	var amb := ambiente()
	var claro := amb.r > 0.995 and amb.g > 0.995 and amb.b > 0.995
	_rect.visible = not claro
	_ativas = []
	_amb = Color.WHITE if claro else amb
	if claro:
		return
	var luzes := coletar() if _parallax.usa_luzes() else []
	var pos := PackedVector3Array()
	var cor := PackedColorArray()
	for l: Array in luzes:
		if pos.size() >= MAX_LUZES:
			break
		_ativas.append(l)
		var p: Vector2 = l[0]
		var c: Color = l[2]
		pos.append(Vector3(p.x, p.y, l[1]))
		cor.append(Color(c.r, c.g, c.b, l[3]))
	var n := pos.size()
	pos.resize(MAX_LUZES)
	cor.resize(MAX_LUZES)
	_mat.set_shader_parameter("ambiente", Vector3(amb.r, amb.g, amb.b))
	_mat.set_shader_parameter("cam", Game.cam_pos)
	_mat.set_shader_parameter("vista", Game.view_size)
	_mat.set_shader_parameter("n", n)
	_mat.set_shader_parameter("luz_pos", pos)
	_mat.set_shader_parameter("luz_cor", cor)


## A mesma conta do shader para um ponto do mundo: por quanto a pelicula multiplica a cor ali
## (branco = pelicula desligada). Com sem_fundo, ignora as luzes da parede (tochas e janelas,
## marcadas com um 5o campo true): quem nao quer ser clareado por elas (as pedras que caem)
## multiplica a propria cor por luz_em(p, true) / luz_em(p).
## 'lista' (de perto()) limita a conta as luzes que alcancam o objeto.
func luz_em(p: Vector2, sem_fundo := false, lista: Variant = null) -> Color:
	var res := _amb
	for l: Array in (_ativas if lista == null else lista):
		if sem_fundo and _do_fundo(l):
			continue
		var d: float = p.distance_to(l[0]) / float(l[1])
		var k := 1.0 if d < 0.45 else (0.62 if d < 0.75 else (0.3 if d < 1.0 else 0.0))
		k *= float(l[3])
		var tom := Color.WHITE.lerp(l[2] as Color, 0.3)
		var m := _amb.lerp(tom, k)
		res = Color(maxf(res.r, m.r), maxf(res.g, m.g), maxf(res.b, m.b))
	return res


## Luzes acesas que alcancam o retangulo (mundo).
func perto(r: Rect2) -> Array:
	return _ativas.filter(func(l: Array) -> bool: return r.grow(float(l[1])).has_point(l[0]))


## Alguma luz da parede (tocha, janela) alcanca o retangulo (mundo)?
func fundo_ilumina(r: Rect2) -> bool:
	for l: Array in _ativas:
		if _do_fundo(l) and r.grow(float(l[1])).has_point(l[0]):
			return true
	return false


static func _do_fundo(l: Array) -> bool:
	return l.size() > 4 and l[4] is bool and l[4]
