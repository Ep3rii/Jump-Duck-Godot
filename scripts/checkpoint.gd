@tool
extends Node2D
## Checkpoint: ao passar por aqui, cair num perigo ou sair do mapa leva o pato de volta
## para este ponto (em vez do inicio da fase). Reinicia a cada tentativa da fase.
## A origem e o pe do mastro, no chao (o pato reaparece exatamente aqui).

const COL_POLE := Color8(13, 80, 0)
const COL_OFF := Color8(150, 160, 150)
const COL_OFF_DARK := Color8(90, 100, 90)
const COL_ON := Color8(133, 242, 56)
const COL_ON_DARK := Color8(71, 144, 20)

var active := false


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
	queue_redraw()
	return true


func _draw() -> void:
	var flag := COL_ON if active else COL_OFF
	var flag_dark := COL_ON_DARK if active else COL_OFF_DARK
	draw_rect(Rect2(-4, -2, 8, 2), COL_POLE)
	draw_rect(Rect2(-1, -24, 2, 22), COL_POLE)
	for col in 9:
		var h := 7 - int(col * 0.7)
		draw_rect(Rect2(1 + col, -23 + (7 - h) * 0.5, 1, h), flag if col < 7 else flag_dark)
