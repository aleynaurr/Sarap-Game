extends Node

@onready var text_box_scene = preload("res://scenes/get_ingredients/dialog_box.tscn")

var lines: Array[String] = []
var current_index = 0

var dialog_box

var is_dialog_active = false

func start_dialog(dialog_lines: Array[String]):
	if is_dialog_active:
		return

	lines = dialog_lines
	current_index = 0
	is_dialog_active = true

	_show_text_box()

func _show_text_box():
	dialog_box = text_box_scene.instantiate()
	dialog_box.finished_displaying.connect(_on_dialog_box_finished_displaying)

	get_tree().root.add_child(dialog_box)

	await get_tree().process_frame

	var viewport_size = get_viewport().get_visible_rect().size

	dialog_box.position = Vector2(
		(viewport_size.x - dialog_box.size.x) / 2,
		viewport_size.y - dialog_box.size.y - 30
	)

	dialog_box.display_text(lines[current_index])

func _on_dialog_box_finished_displaying():
	await get_tree().create_timer(2.0).timeout

	dialog_box.queue_free()

	current_index += 1

	if current_index >= lines.size():
		is_dialog_active = false
		current_index = 0
		return

	_show_text_box()
