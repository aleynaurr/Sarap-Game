extends Area2D

const DOOR_TRANSITION_SCENE := preload("res://scenes/DoorTransition.tscn")

var player1_inside := false
var player2_inside := false

func _ready() -> void:

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is Player:
		if body.player_id == 1:
			player1_inside = true
		elif body.player_id == 2:
			player2_inside = true
			
		print("P1 Inside: ", player1_inside, " | P2 Inside: ", player2_inside)
		check_finish()

func _on_body_exited(body):
	if body is Player:
		if body.player_id == 1:
			player1_inside = false
		elif body.player_id == 2:
			player2_inside = false
		
		print("P1 Inside: ", player1_inside, " | P2 Inside: ", player2_inside)

func ingredients_complete() -> bool:
	return true
	
func check_finish():
	if player1_inside and player2_inside and ingredients_complete():
		GameManager.versus_video_playing = true
		await get_tree().create_timer(0.5).timeout
		var door := DOOR_TRANSITION_SCENE.instantiate()
		get_tree().root.add_child(door)
		door.play_transition(func(): get_tree().change_scene_to_file("res://scenes/SplitScreen.tscn"))
