class_name Collectable extends Area2D

@export var item_name: String
var is_collected: bool = false


func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
		
	if body is Player:
		var p_id = body.player_id

		if InventoryManager.can_collect(p_id, item_name):
			is_collected = true
			
		
			set_deferred("monitoring", false)

			var success = InventoryManager.add_item(p_id, item_name)
			if success:
				print("Successfully collected: ", item_name, " by Player ", p_id)
				get_parent().queue_free() 
			else:
				
				is_collected = false
				set_deferred("monitoring", true)
		else:
			
			print("Player ", p_id, " inventory is full for ", item_name, "! Leaving it on floor.")
