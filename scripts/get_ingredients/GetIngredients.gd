extends Node2D

@onready var intro_scene = preload("res://scenes/get_ingredients/IntroductionScene.tscn")

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
	if not GameManager.versus_video_playing:
		AudioManager.play_music("getingredients")
		music_playing = true
	players["2"].subviewport.world_2d = players["1"].subviewport.world_2d
	

	var intro = intro_scene.instantiate()
	add_child(intro)
	
	await get_tree().process_frame

	if not GameManager.versus_video_playing:
		TextManager.start_dialog([
			"For Movement, Player 1: WASD, Player 2: Arrow Keys", 
			"For Interact, Player 1: E, Player 2: RShift",
			"🌱 Race to collect all the ingredients!",
			"🥬 Harvest the crops in the garden.", 
			"🧺 Explore the map to find the remaining ingredients.",
			"🏠 Return to the house when you're done.",
			"⭐ The first player to enter the house earns bonus points!"
		])

func _process(delta):
	if GameManager.versus_video_playing and music_playing:
		AudioManager.stop_music()
		music_playing = false
