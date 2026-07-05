class_name Player extends CharacterBody2D
@export var player_id := 1

func interact_pressed(event: InputEvent) -> bool:
	match player_id:
		1:
			return event.is_action_pressed("p1_interact")
		2:
			return event.is_action_pressed("p2_interact")

	return false
