class_name Enemy
extends Node2D
const PixelFx := preload("res://scripts/pixelfx.gd")
## Base de todos os inimigos (raposa hoje; jacare, gaviao e o chefe depois).
##
## Contrato com o jogador (player.gd):
## - get_mask(): retangulo que machuca / pode ser atingido (o "hurtbox" do inimigo);
## - encostar caindo de cima, com o pe acima de stomp_line_y() e stompable = true -> pisao (hit);
## - encostar de qualquer outro jeito -> o jogador leva dano (se harmful() for true).
## Objetos arremessados (Fase 4) tambem vao chamar hit().
##
## Para um inimigo novo: extends Enemy, sobrescreva get_mask(), _enemy_ready() e
## _physics_process(); ajuste max_hp / stompable no inspetor.

signal defeated

const EfeitoScene := preload("res://scenes/efeito.tscn")
const Particulas := preload("res://scripts/particulas.gd")

## Golpes para derrotar (pisao e arremesso tiram 1 cada).
@export var max_hp := 1
## Pode ser derrotado pulando em cima.
@export var stompable := true
## Onde aparece o brilho de derrota, relativo a origem.
@export var effect_offset := Vector2(0, -16)
## Frames sem levar novo golpe nem causar dano depois de ser atingido (so importa com max_hp > 1).
@export var hurt_frames := 30
## Nos que recebem set_active(true) quando ele e derrotado (ex.: a porta da saida da arena).
@export var alvos_ao_derrotar: Array[NodePath] = []
## Particulas soltas ao ser derrotado (particulas.gd): poeira, pelo, pena, respingo...
var particula_derrota := "poeira"
var particulas_qtd := 10

## Quadros apagado / aceso no pisca de dano.
const PISCA_QUADROS := 5.0

var hp := 1
var _hurt_until := -1
var _pisca: Tween


## Largura da sombra no chao em px (0 = sem sombra; quem nada sobrescreve).
func sombra_largura() -> float:
	return 12.0


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("sombra")  # sombras.gd
	hp = max_hp
	# transparencia (submerso, pisca de dano) vira quadriculado de pixels cheios ou vazios
	if material == null:
		material = PixelFx.material_dither()
	_enemy_ready()


## Sobrescreva no lugar de _ready().
func _enemy_ready() -> void:
	pass


## Sobrescreva com a mascara do sprite.
func get_mask() -> Rect2:
	return Rect2(position - Vector2(8, 16), Vector2(16, 16))


## O pisao conta se o pe do jogador, no frame anterior, estava acima desta linha.
func stomp_line_y() -> float:
	return position.y - 6.0


func is_hurt() -> bool:
	return Engine.get_physics_frames() < _hurt_until


## Encostar machuca o jogador? (nao enquanto pisca depois de levar golpe)
func harmful() -> bool:
	return hp > 0 and not is_hurt()


func hit(damage: int = 1) -> void:
	if hp <= 0 or is_hurt():
		return
	hp -= damage
	if hp <= 0:
		defeat()
		return
	_hurt_until = Engine.get_physics_frames() + hurt_frames
	Game.play_sfx("stomp")
	_piscar()


## Pisca de dano em pixel: some e volta por quadros inteiros (alfa 0 ou 1, nunca meio
## transparente), 5 quadros apagado e 5 aceso, pelo tempo de hurt_frames.
func _piscar() -> void:
	if _pisca != null and _pisca.is_valid():
		_pisca.kill()
	_pisca = create_tween()
	_pisca.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	for i in maxi(1, int(hurt_frames / 10.0)):
		_pisca.tween_callback(func() -> void: modulate.a = 0.0)
		_pisca.tween_interval(PISCA_QUADROS / 60.0)
		_pisca.tween_callback(func() -> void: modulate.a = 1.0)
		_pisca.tween_interval(PISCA_QUADROS / 60.0)
	_pisca.tween_callback(func() -> void: modulate.a = 1.0)


func defeat() -> void:
	hp = 0
	Game.play_sfx("stomp")
	for path in alvos_ao_derrotar:
		var target := get_node_or_null(path)
		if target != null and target.has_method("set_active"):
			target.set_active(true)
	var fx := EfeitoScene.instantiate()
	fx.position = position + effect_offset
	get_parent().add_child(fx)
	Particulas.emit(get_tree(), particula_derrota, position + effect_offset, particulas_qtd)
	defeated.emit()
	queue_free()
