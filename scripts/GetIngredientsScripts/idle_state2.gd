extends NodeState
@export var player: CharacterBody2D
@export var animated_sprite_2d: AnimatedSprite2D
@export var speed: int = 100
var direction: Vector2


func _on_process(_delta : float) -> void:
	pass


func _on_physics_process(_delta : float) -> void:
	GI_Input_Events2.movement_input()
	var direction = GI_Input_Events2.last_direction

	if direction == Vector2.UP:
		animated_sprite_2d.play("idle_back")
	elif direction == Vector2.DOWN:
		animated_sprite_2d.play("idle_front")
	elif direction == Vector2.RIGHT:
		animated_sprite_2d.play("idle_right")
	elif direction == Vector2.LEFT:
		animated_sprite_2d.play("idle_left")
	
	pass

func _on_next_transitions() -> void:
	GI_Input_Events2.movement_input()
	
	if GI_Input_Events2.is_movement_input():
		transition.emit("Walk")
	pass


func _on_enter() -> void:
	pass


func _on_exit() -> void:
	pass
