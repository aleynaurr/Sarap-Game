extends Node

signal inventory_changed(player_id)

var inventories := {
	1: {},
	2: {}
}

func add_item(player_id: int, item_name: String) -> void:
	var inventory = inventories[player_id]

	inventory[item_name] = inventory.get(item_name, 0) + 1

	print("Player", player_id, "Inventory:", inventory)

	inventory_changed.emit(player_id)
