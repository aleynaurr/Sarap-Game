extends Node2D



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


func _ready() -> void:
	AudioManager.play_music("getingredients")
	players["2"].subviewport.world_2d = players["1"].subviewport.world_2d
	
	await get_tree().process_frame

	TextManager.start_dialog([
		"🌱 Race to collect all the ingredients!",
		"🥬 Harvest the crops in the garden.", 
		"🧺 Explore the map to find the remaining ingredients.",
		"🏠 Return to the house when you're done.",
		"⭐ The first player to enter the house earns bonus points!"
	])
