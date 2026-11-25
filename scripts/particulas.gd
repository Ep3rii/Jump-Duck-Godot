extends Node2D
## Particulas leves desenhadas em codigo (poeira, respingos, bolhas, penas, folhas, brilhos,
## pedrinhas). Um no "Particulas" por cena, criado sob demanda; para junto com a pausa.
## Uso: Particulas.emit(get_tree(), "poeira", posicao, quantidade)

const MAX := 400

## [cor, cor alternativa, gravidade, arrasto, vida (frames), tamanho]
const KINDS := {
	"poeira": [Color8(214, 196, 160, 200), Color8(180, 160, 128, 200), -0.02, 0.90, 24, 3.0],
	"pouso": [Color8(214, 196, 160, 210), Color8(170, 150, 120, 210), -0.01, 0.88, 22, 2.5],
	"anel": [Color8(255, 255, 255, 200), Color8(200, 240, 255, 200), 0.0, 0.86, 16, 2.0],
	"respingo": [Color8(200, 235, 255, 230), Color8(110, 180, 240, 230), 0.22, 0.98, 40, 2.0],
	"bolha": [Color8(220, 245, 255, 210), Color8(170, 220, 250, 210), -0.04, 0.97, 50, 2.0],
	"pena": [Color8(150, 92, 46), Color8(236, 214, 170), 0.03, 0.95, 90, 3.0],
	"pelo": [Color8(230, 120, 50), Color8(250, 230, 210), 0.05, 0.93, 40, 2.0],
	"folha": [Color8(96, 170, 50), Color8(200, 150, 40), 0.015, 0.97, 220, 2.0],
	"brilho": [Color8(255, 236, 120), Color8(255, 255, 255), -0.01, 0.93, 34, 2.0],
	"pedrinha": [Color8(150, 140, 160), Color8(110, 100, 120), 0.25, 0.98, 50, 2.0],
	"vento": [Color8(240, 250, 255, 170), Color8(200, 230, 245, 170), 0.0, 1.0, 60, 1.0],
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
		var pos: Vector2 = p[0]
		var s: float = p[6]
		match p[4]:
			"poeira", "pouso":
				var r := s * (1.6 - t * 0.6)
				draw_circle(pos, r, Color(c, c.a * t))
			"anel":
				draw_rect(Rect2(pos.x - 1, pos.y - 1, 2, 2), Color(c, c.a * t))
			"bolha":
				draw_arc(pos + Vector2(sin(p[7] + p[2] * 0.15) * 1.0, 0), s, 0.0, TAU, 8, Color(c, c.a * minf(1.0, t * 2.0)), 1.0)
			"pena":
				var w := 3.0 * cos(p[7])
				draw_rect(Rect2(pos.x - absf(w) * 0.5, pos.y - 1, maxf(1.0, absf(w)), 2), Color(c, minf(1.0, t * 3.0)))
			"folha":
				var w := 3.0 * cos(p[7] * 1.3)
				draw_rect(Rect2(pos.x - absf(w) * 0.5, pos.y - 1, maxf(1.0, absf(w)), 2), Color(c, minf(1.0, t * 4.0)))
			"brilho":
				var a := minf(1.0, t * 2.0)
				draw_rect(Rect2(pos.x - 1, pos.y - 0.5, 3, 1), Color(c, a))
				draw_rect(Rect2(pos.x - 0.5, pos.y - 1, 1, 3), Color(c, a))
			"vento":
				draw_rect(Rect2(pos.x - 3, pos.y, 6, 1), Color(c, c.a * t))
			_:
				draw_rect(Rect2(pos.x - s * 0.5, pos.y - s * 0.5, s, s), Color(c, c.a * minf(1.0, t * 2.0)))
