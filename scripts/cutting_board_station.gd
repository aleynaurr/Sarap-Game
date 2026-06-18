extends Area2D

var player_in_range = false

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		print("Player entered cutting board area")

func _on_body_exited(body):
	if body.name =='Player':
		player_in_range = false
		print("Player left the cutting board area")
		

func _process(delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		print("Shift is pressed")
