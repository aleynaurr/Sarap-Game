extends Node2D

@onready var intro_scene = preload("res://scenes/get_ingredients/IntroductionScene.tscn")
const DOOR_TRANSITION_SCENE := preload("res://scenes/DoorTransition.tscn")


@onready var p1_banner = $GameScreen/Control/TextureRect
@onready var p2_banner = $GameScreen/Control2/TextureRect



@onready var players := {
	"1": {
		"subviewport": $HBoxContainer/SubViewportContainer/SubViewport,
		"camera": $HBoxContainer/SubViewportContainer/SubViewport/Player1/Camera2D,
		"player": $HBoxContainer/SubViewportContainer/SubViewport/Player1
	},
	"2": {
		"subviewport": $HBoxContainer/SubViewportContainer2/SubViewport,
		"camera": $HBoxContainer/SubViewportContainer2/SubViewport/Player2/Camera2D,
		"player": $HBoxContainer/SubViewportContainer2/SubViewport/Player2
	}
}

var music_playing := false


func _ready() -> void:
	p1_banner.visible = false
	p2_banner.visible = false
	
	if not GameManager.versus_video_playing:
		AudioManager.play_music("getingredients")
		music_playing = true
	players["2"].subviewport.world_2d = players["1"].subviewport.world_2d
	

	var intro = intro_scene.instantiate()
	add_child(intro)
	
	await get_tree().process_frame
	
	if not GameManager.versus_video_playing:
		TextManager.start_dialog([
			"🌱 Race to collect all the ingredients!",
			"🥬 Harvest the crops in the garden.", 
			"🧺 Explore the map to find the remaining ingredients.",
			"🏠 Return to the house when you're done.",
			"⭐ The first player to enter the house earns bonus points!"
		])
	TimeManager.time_up.connect(_on_time_up)
	
func _on_time_up() -> void:
	p1_banner.visible = true
	p2_banner.visible = true


	await get_tree().create_timer(2.5).timeout
	
	
	GameManager.versus_video_playing = true
	await get_tree().create_timer(0.5).timeout
	var door := DOOR_TRANSITION_SCENE.instantiate()
	get_tree().root.add_child(door)
	door.play_transition(func(): get_tree().change_scene_to_file("res://scenes/SplitScreen.tscn"))
	
	
	
func _process(delta):
	if GameManager.versus_video_playing and music_playing:
		AudioManager.stop_music()
		music_playing = false
