class_name Collectable extends Area2D

@export var item_name: String

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		InventoryManager.add_item(body.player_id, item_name)
		print("Collected:", item_name, "by Player", body.player_id)
		get_parent().queue_free()
