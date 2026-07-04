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
	InventoryManager.inventory_changed.connect(on_inventory_change)
	on_inventory_change(player_id)


func on_inventory_change(changed_player: int):
	if changed_player != player_id:
		return
		
	var inventory = InventoryManager.inventories[player_id]

	eggplant_label.text = str(inventory.get("eggplant", 0))
	chili_label.text = str(inventory.get("chili", 0))
	shallots_label.text = str(inventory.get("shallots", 0))
	springonions_label.text = str(inventory.get("springonions", 0))
	garlic_label.text = str(inventory.get("garlic", 0))
	desiccatedcoconut_label.text = str(inventory.get("desiccatedcoconut", 0))
	coconutmilk_label.text = str(inventory.get("coconutmilk", 0))
	
	
