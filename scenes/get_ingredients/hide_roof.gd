extends Node2D

var players_in_door := {}


func _ready() -> void:

	for child in get_children():
		if child is Area2D:
			child.body_entered.connect(_on_door_body_entered.bind(child))
			child.body_exited.connect(_on_door_body_exited.bind(child))


func _on_door_body_entered(body: Node2D, door: Area2D) -> void:

	if body is Player:
		if !players_in_door.has(door):
			players_in_door[door] = []

		if !players_in_door[door].has(body):
			players_in_door[door].append(body)

		determine_roof_visibility(door, false)


func _on_door_body_exited(body: Node2D, door: Area2D) -> void:
	if body is Player and players_in_door.has(door):
		players_in_door[door].erase(body)

		if players_in_door[door].is_empty():
			players_in_door.erase(door)
			determine_roof_visibility(door, true)



func determine_roof_visibility(door: Area2D, make_visible: bool) -> void:
	if door.name == "HouseDoor":
		fade_node($House_Roof, make_visible)
		fade_node($wallunderhouse, make_visible)
		fade_node($HouseDoor/Sprite2D, make_visible)
		fade_node($HouseDoor/Sprite2D2, make_visible)

	elif door.name == "SMDoor1" or door.name == "SMDoor2":
		fade_node($SM_Roof, make_visible)
		fade_node($wallundersm, make_visible)
		fade_node($SMDoor1/Sprite2D, make_visible)
		fade_node($SMDoor2/Sprite2D, make_visible)


func fade_node(node: CanvasItem, make_visible: bool) -> void:
	if node:
		var target_alpha := 1.0 if make_visible else 0.0
		var tween := create_tween()
		tween.tween_property(node, "modulate:a", target_alpha, 0.25)
