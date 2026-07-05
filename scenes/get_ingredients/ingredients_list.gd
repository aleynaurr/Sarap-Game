extends PanelContainer

@onready var eggplant_label: Label = $MarginContainer/VBoxContainer/Eggplant/EggplantLabel
@onready var chili_label: Label = $MarginContainer/VBoxContainer/Chili/ChiliLabel
@onready var shallots_label: Label = $MarginContainer/VBoxContainer/Shallots/ShallotsLabel
@onready var springonions_label: Label = $MarginContainer/VBoxContainer/Spring_Onions/SpringOnionsLabel
@onready var garlic_label: Label = $MarginContainer/VBoxContainer/Garlic/GarlicLabel
@onready var desiccatedcoconut_label: Label = $MarginContainer/VBoxContainer/Desiccated_Coconut/DesiccatedCoconutLabel
@onready var coconutmilk_label: Label = $MarginContainer/VBoxContainer/Coconut_Milk/CoconutMilkLabel

@export var player_id := 1

func _ready():

	if InventoryManager.inventory_changed.is_connected(on_inventory_change):
		InventoryManager.inventory_changed.disconnect(on_inventory_change)
		
	InventoryManager.inventory_changed.connect(on_inventory_change)
	on_inventory_change(player_id)

func on_inventory_change(changed_player: int):
	if changed_player != player_id:
		return
		
	var inventory = InventoryManager.inventories[player_id]
	var goal = InventoryManager.INGREDIENT_GOAL

	eggplant_label.text = str(inventory.get("eggplant", 0)) + "/" + str(goal)
	chili_label.text = str(inventory.get("chili", 0)) + "/" + str(goal)
	shallots_label.text = str(inventory.get("shallots", 0)) + "/" + str(goal)
	springonions_label.text = str(inventory.get("springonions", 0)) + "/" + str(goal)
	garlic_label.text = str(inventory.get("garlic", 0)) + "/" + str(goal)
	desiccatedcoconut_label.text = str(inventory.get("desiccatedcoconut", 0)) + "/" + str(goal)
	coconutmilk_label.text = str(inventory.get("coconutmilk", 0)) + "/" + str(goal)
