extends Node

signal time_changed(min: int, sec: int)
signal time_up()

const START_TIME := 120.0

var time_left := START_TIME
var running := true

func _process(delta: float) -> void:
	if !running:
		return

	time_left -= delta

	if time_left <= 0:
		time_left = 0
		running = false
		time_up.emit()

	var minutes := int(time_left) / 60
	var seconds := int(time_left) % 60

	time_changed.emit(minutes, seconds)
