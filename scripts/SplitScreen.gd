extends Control

const DOOR_TRANSITION_SCENE := preload("res://scenes/DoorTransition.tscn")

func _ready() -> void:
	GameManager.start_shared_timer()
	GameManager.all_players_finished.connect(_on_all_players_finished)
	GameManager.shared_timer_up.connect(_on_all_players_finished)
	
func _on_all_players_finished() -> void:
	await get_tree().create_timer(0.5).timeout
	var door := DOOR_TRANSITION_SCENE.instantiate()
	get_tree().root.add_child(door)
	door.play_transition(func(): get_tree().change_scene_to_file("res://scenes/SplitScreenResults.tscn"))
