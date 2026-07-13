extends Control

@onready var w = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/PanelContainer/wGlow
@onready var s = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/PanelContainer/sGlow
@onready var a = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/PanelContainer/aGlow
@onready var d = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/PanelContainer/dGlow
@onready var up = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/PanelContainer2/upGlow
@onready var down = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/PanelContainer2/downGlow
@onready var left = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/PanelContainer2/leftGlow
@onready var right = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/PanelContainer2/rightGlow

@onready var play_button = $MarginContainer/VBoxContainer/Panel/PlayButton

var p1_last_key := "w"
var p2_last_key := "up"

func _ready() -> void:
	get_tree().paused = true
	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.tween_property(self, "position:y", position.y - 50, 0.5)
	
	w.visible = true
	up.visible = true

	a.visible = false
	s.visible = false
	d.visible = false
	

	down.visible = false
	left.visible = false
	right.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	if Input.is_action_just_pressed("p1_up"):
		p1_last_key = "w"
	elif Input.is_action_just_pressed("p1_left"):
		p1_last_key = "a"
	elif Input.is_action_just_pressed("p1_down"):
		p1_last_key = "s"
	elif Input.is_action_just_pressed("p1_right"):
		p1_last_key = "d"

	w.visible = p1_last_key == "w"
	a.visible = p1_last_key == "a"
	s.visible = p1_last_key == "s"
	d.visible = p1_last_key == "d"


	# -------- Player 2 --------
	if Input.is_action_just_pressed("p2_up"):
		p2_last_key = "up"
	elif Input.is_action_just_pressed("p2_left"):
		p2_last_key = "left"
	elif Input.is_action_just_pressed("p2_down"):
		p2_last_key = "down"
	elif Input.is_action_just_pressed("p2_right"):
		p2_last_key = "right"

	up.visible = p2_last_key == "up"
	left.visible = p2_last_key == "left"
	down.visible = p2_last_key == "down"
	right.visible = p2_last_key == "right"


func _on_play_button_pressed() -> void:
	get_tree().paused = false
	queue_free()
	

func _on_play_button_mouse_entered() -> void:
	create_tween().tween_property($PlayButton, "scale", Vector2(1.1, 1.1), 0.15)


func _on_play_button_mouse_exited() -> void:
	create_tween().tween_property($PlayButton, "scale", Vector2.ONE, 0.15)
