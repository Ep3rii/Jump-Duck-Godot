extends Node2D
## Particulas leves desenhadas em codigo (poeira, respingos, bolhas, penas, folhas, brilhos,
## pedrinhas). Um no "Particulas" por cena, criado sob demanda; para junto com a pausa.
## Uso: Particulas.emit(get_tree(), "poeira", posicao, quantidade)

const MAX := 400

## [cor, cor alternativa, gravidade, arrasto, vida (frames), tamanho]
## Todas opacas e da Endesga 32 (tools/arte/pixelkit.py): nada de alfa nem cor fora da paleta.
## No desenho a posicao e arredondada e o tamanho e inteiro (bloquinhos presos a grade).
const KINDS := {
	"poeira": [Color("#ead4aa"), Color("#c0cbdc"), -0.02, 0.90, 24, 3.0],
	"pouso": [Color("#ead4aa"), Color("#c0cbdc"), -0.01, 0.88, 22, 2.5],
	"anel": [Color("#ffffff"), Color("#c0cbdc"), 0.0, 0.86, 16, 2.0],
	"respingo": [Color("#ffffff"), Color("#2ce8f5"), 0.22, 0.98, 40, 2.0],
	"bolha": [Color("#ffffff"), Color("#2ce8f5"), -0.04, 0.97, 50, 2.0],
	"pena": [Color("#b86f50"), Color("#ead4aa"), 0.03, 0.95, 90, 3.0],
	"pelo": [Color("#f77622"), Color("#ffffff"), 0.05, 0.93, 40, 2.0],
	"folha": [Color("#63c74d"), Color("#feae34"), 0.015, 0.97, 220, 2.0],
	"brilho": [Color("#fee761"), Color("#ffffff"), -0.01, 0.93, 34, 2.0],
	"pedrinha": [Color("#8b9bb4"), Color("#5a6988"), 0.25, 0.98, 50, 2.0],
	"vento": [Color("#ffffff"), Color("#c0cbdc"), 0.0, 1.0, 60, 1.0],
}

var _parts: Array = []  # cada uma: [pos, vel, vida, vida_max, tipo, cor, tamanho, fase]
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	z_index = -440
	_rng.seed = 4242


## Solta 'count' particulas do tipo 'kind' em 'pos'. 'dir' empurra todas numa direcao.
static func emit(tree: SceneTree, kind: String, pos: Vector2, count := 6, dir := Vector2.ZERO) -> void:
	var scene := tree.current_scene
	if scene == null or not KINDS.has(kind):
		return
	var node := scene.get_node_or_null("Particulas")
	if node == null:
		node = Node2D.new()
		node.name = "Particulas"
		node.set_script(load("res://scripts/particulas.gd"))
		scene.add_child(node)
	node.spawn(kind, pos, count, dir)


func spawn(kind: String, pos: Vector2, count: int, dir: Vector2) -> void:
	var k: Array = KINDS[kind]
	for i in count:
		if _parts.size() >= MAX:
			_parts.pop_front()
		var v := Vector2.ZERO
		match kind:
			"poeira":
				v = Vector2(_rng.randf_range(-0.6, 0.6), _rng.randf_range(-0.6, -0.1))
			"pouso":
				var side := -1.0 if i % 2 == 0 else 1.0
				v = Vector2(side * _rng.randf_range(0.6, 1.6), _rng.randf_range(-0.4, -0.1))
			"anel":
				var a := TAU * i / maxf(1.0, count)
				v = Vector2(cos(a), sin(a) * 0.5) * 1.6
			"respingo":
				v = Vector2(_rng.randf_range(-1.4, 1.4), _rng.randf_range(-3.2, -1.2))
			"bolha":
				v = Vector2(_rng.randf_range(-0.2, 0.2), _rng.randf_range(-0.8, -0.4))
			"pena", "pelo":
				v = Vector2(_rng.randf_range(-1.6, 1.6), _rng.randf_range(-2.0, -0.4))
			"folha":
				v = Vector2(_rng.randf_range(-0.3, 0.3), _rng.randf_range(0.1, 0.3))
			"brilho":
				var a := _rng.randf() * TAU
				v = Vector2(cos(a), sin(a)) * _rng.randf_range(0.5, 1.6)
			"pedrinha":
				v = Vector2(_rng.randf_range(-1.5, 1.5), _rng.randf_range(-2.5, -0.5))
			"vento":
				v = Vector2.ZERO
		v += dir
		var col: Color = k[0] if _rng.randf() < 0.6 else k[1]
		var life: int = int(k[4] * _rng.randf_range(0.75, 1.25))
		_parts.append([pos + Vector2(_rng.randf_range(-2, 2), _rng.randf_range(-1, 1)), v, life,
			life, kind, col, k[5] * _rng.randf_range(0.7, 1.3), _rng.randf() * TAU])


func _process(_delta: float) -> void:
	var i := 0
	while i < _parts.size():
		var p: Array = _parts[i]
		var k: Array = KINDS[p[4]]
		p[2] -= 1
		if p[2] <= 0:
			_parts.remove_at(i)
			continue
		var v: Vector2 = p[1]
		v.y += k[2]
		v *= k[3]
		if p[4] in ["pena", "folha"]:
			# cai balancando de um lado para o outro
			p[7] += 0.08
			v.x += sin(p[7]) * 0.05
			v.y = minf(v.y, 0.6)
		p[1] = v
		p[0] += v
		i += 1
	queue_redraw()


func _draw() -> void:
	for p: Array in _parts:
		var t: float = float(p[2]) / float(p[3])  # 1 -> 0
		var c: Color = p[5]
		var o: Vector2 = (p[0] as Vector2).round()
		var s: float = p[6]
		match p[4]:
			"poeira", "pouso":
				# bloquinho que encolhe em degraus (3 -> 2 -> 1 px)
				var q := clampi(int(ceil(s * t * 1.2)), 1, 3)
				if q == 3:  # "+" de 3x3 (bolinha de poeira)
					draw_rect(Rect2(o.x - 1, o.y, 3, 1), c)
					draw_rect(Rect2(o.x, o.y - 1, 1, 3), c)
				else:
					draw_rect(Rect2(o.x, o.y, q, q), c)
			"anel":
				var q := 2 if t > 0.5 else 1
				draw_rect(Rect2(o.x - 1, o.y - 1, q, q), c)
			"bolha":
				# anel de 3x3 sem o meio (bolinha oca); no fim, 1 px
				var b := o + Vector2(roundf(sin(p[7] + p[2] * 0.15)), 0.0)
				if s >= 1.5 and t > 0.25:
					draw_rect(Rect2(b.x - 1, b.y, 1, 1), c)
					draw_rect(Rect2(b.x + 1, b.y, 1, 1), c)
					draw_rect(Rect2(b.x, b.y - 1, 1, 1), c)
					draw_rect(Rect2(b.x, b.y + 1, 1, 1), c)
				else:
					draw_rect(Rect2(b.x, b.y, 1, 1), c)
			"pena", "folha":
				# gira no ar: a largura vai de 3 a 1 px (inteira), sempre 2 de altura
				var giro: float = p[7] * (1.0 if p[4] == "pena" else 1.3)
				var w := clampi(roundi(absf(3.0 * cos(giro))), 1, 3)
				draw_rect(Rect2(o.x - floorf(w * 0.5), o.y - 1, w, 2), c)
			"brilho":
				if t > 0.35:
					draw_rect(Rect2(o.x - 1, o.y, 3, 1), c)
					draw_rect(Rect2(o.x, o.y - 1, 1, 3), c)
				else:
					draw_rect(Rect2(o.x, o.y, 1, 1), c)
			"vento":
				draw_rect(Rect2(o.x - 3, o.y, 6 if t > 0.3 else 3, 1), c)
			_:
				var q := clampi(roundi(s * (1.0 if t > 0.3 else 0.5)), 1, 3)
				draw_rect(Rect2(o.x - floorf(q * 0.5), o.y - floorf(q * 0.5), q, q), c)
