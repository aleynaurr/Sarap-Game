extends Node2D

# Attach this script (or extend it) on any minigame scene's root node.
# Emits "finished" when the player presses E to return to the kitchen.

signal finished

func _process(_delta):
	if Input.is_action_just_pressed("return_to_kitchen"):
		finished.emit()
