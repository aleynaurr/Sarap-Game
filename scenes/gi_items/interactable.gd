class_name Interactable
extends Area2D


signal interact_activated(player)
signal interact_deactivated(player)


func _on_body_entered(_body: Node2D) -> void:
	if _body is Player:
		interact_activated.emit(_body)


func _on_body_exited(_body: Node2D) -> void:
	if _body is Player:
		interact_deactivated.emit(_body)
