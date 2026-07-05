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
	players["2"].subviewport.world_2d = players["1"].subviewport.world_2d

		
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F10:
		get_viewport().set_input_as_handled()
		
		AudioManager.play_sfx(AudioManager.SFX_CLICK)
		GameManager.go_to_kitchen()
