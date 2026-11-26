@tool
extends Node2D
## Checkpoint: ao passar por aqui, cair num perigo ou sair do mapa leva o pato de volta
## para este ponto (em vez do inicio da fase). Reinicia a cada tentativa da fase.
## A origem e o pe do mastro, no chao (o pato reaparece exatamente aqui).

const Sprites := preload("res://scripts/sprites.gd")


var active := false
var _time := 0.0
var _raise := 0.0  # 0 = bandeira embaixo (apagada) .. 1 = no alto (acesa)


func _ready() -> void:
	add_to_group("checkpoint")


func get_mask() -> Rect2:
	return Rect2(roundf(position.x) - 6.0, roundf(position.y) - 24.0, 12.0, 24.0)


## Chamado pelo jogador ao encostar. Devolve true se acabou de ativar.
func activate() -> bool:
	if active:
		return false
	for other in get_tree().get_nodes_in_group("checkpoint"):
		if other != self:
			other.active = false
			other.queue_redraw()
	active = true
	Game.set_checkpoint(position)
	var Particulas := load("res://scripts/particulas.gd")
	Particulas.emit(get_tree(), "brilho", position + Vector2(4, -20), 8)
	queue_redraw()
	return true


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	_raise = move_toward(_raise, 1.0 if active else 0.0, delta * 3.0)
	queue_redraw()


func _draw() -> void:
	# apagado: bandeira cinza murcha; aceso: verde no alto, tremulando (checkpoint.png)
	var q := 0 if _raise < 0.5 else 1 + int(_time * 7.0) % 3
	Sprites.draw_bicho(self, "checkpoint", q, 4, Vector2(4, 28))
