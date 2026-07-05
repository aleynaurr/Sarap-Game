extends Node


const INGREDIENT_GOAL := 4


var inventories := {
	1: {
		"eggplant": 0, "chili": 0, "shallots": 0, 
		"springonions": 0, "garlic": 0, "desiccatedcoconut": 0, "coconutmilk": 0
	},
	2: {
		"eggplant": 0, "chili": 0, "shallots": 0, 
		"springonions": 0, "garlic": 0, "desiccatedcoconut": 0, "coconutmilk": 0
	}
}

signal inventory_changed(player_id: int)

func can_collect(player_id: int, item_type: String) -> bool:
	if inventories.has(player_id) and inventories[player_id].has(item_type):
		return inventories[player_id][item_type] < INGREDIENT_GOAL
	return false

func add_item(player_id: int, item_type: String) -> bool:

	if not can_collect(player_id, item_type):
		return false 
		
	inventories[player_id][item_type] += 1
	inventory_changed.emit(player_id)
	return true
