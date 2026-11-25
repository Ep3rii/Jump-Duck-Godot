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
	var flag := COL_OFF.lerp(COL_ON, _raise)
	var flag_dark := COL_OFF_DARK.lerp(COL_ON_DARK, _raise)
	draw_rect(Rect2(-4, -2, 8, 2), COL_POLE)
	draw_rect(Rect2(-1, -24, 2, 22), COL_POLE)
	draw_rect(Rect2(-2, -26, 4, 2), flag_dark)
	# apagada: bandeira murcha embaixo; acesa: sobe e tremula no vento
	var top := lerpf(-12.0, -23.0, _raise)
	var wave_amp := lerpf(0.0, 1.0, _raise)
	for col in 9:
		var h := 7 - int(col * 0.7)
		var droop := (1.0 - _raise) * col * 0.6
		var y := top + (7 - h) * 0.5 + floorf(sin(_time * 7.0 + col * 0.6) * wave_amp + droop)
		draw_rect(Rect2(1 + col, y, 1, h), flag if col < 7 else flag_dark)
