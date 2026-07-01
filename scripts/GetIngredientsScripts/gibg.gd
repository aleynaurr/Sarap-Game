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
