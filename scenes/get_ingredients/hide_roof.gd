extends Node2D

func _ready() -> void:

	for child in get_children():
		if child is Area2D:
			child.body_entered.connect(_on_door_body_entered.bind(child))
			child.body_exited.connect(_on_door_body_exited.bind(child))


func _on_door_body_entered(body: Node2D, door: Area2D) -> void:

	if body is Player:
		determine_roof_visibility(door, false)


func _on_door_body_exited(body: Node2D, door: Area2D) -> void:
	if body is Player:
		determine_roof_visibility(door, true)



func determine_roof_visibility(door: Area2D, make_visible: bool) -> void:
	if door.name == "HouseDoor":

		fade_roof($House_Roof, make_visible)
		
	elif door.name == "SMDoor1" or door.name == "SMDoor2":

		fade_roof($SM_Roof,make_visible)


func fade_roof(roof_node: TileMapLayer, make_visible: bool) -> void:
	if roof_node:
		var target_alpha = 1.0 if make_visible else 0.0
		var tween = create_tween()
		tween.tween_property(roof_node, "modulate:a", target_alpha, 0.25)
