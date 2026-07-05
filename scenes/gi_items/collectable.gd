class_name Collectable extends Area2D

@export var item_name: String
var is_collected: bool = false


func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
		
	if body is Player:
		var p_id = body.player_id
		
		# 1. Check if the player actually has room for this item
		if InventoryManager.can_collect(p_id, item_name):
			is_collected = true
			
			# Disable monitoring immediately to protect physics step duplicates
			set_deferred("monitoring", false)
			
			# 2. Safely add the item to the inventory system
			var success = InventoryManager.add_item(p_id, item_name)
			if success:
				print("Successfully collected: ", item_name, " by Player ", p_id)
				get_parent().queue_free() # Deletes the entire crop object cleanly
			else:
				# Reset tracking switch if something failed internally
				is_collected = false
				set_deferred("monitoring", true)
		else:
			# Blocks the pickup! Item stays visible and physical on the ground.
			print("Player ", p_id, " inventory is full for ", item_name, "! Leaving it on floor.")
