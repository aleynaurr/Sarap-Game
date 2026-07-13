extends MarginContainer

@onready var label = $MarginContainer/Label
@onready var timer = $DisplayTimer

signal finished_displaying()

var text := ""
var index := 0

const width_max := 900


var time_letter := 0.03
var time_space := 0.06
var time_symbol := 0.2

func _ready():
	timer.timeout.connect(_on_display_timer_timeout)

func display_text(text_for_display: String):
	index = 0
	text = text_for_display

	label.text = text

	await get_tree().process_frame

	custom_minimum_size.x = min(size.x, width_max)

	if size.x > width_max:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		await get_tree().process_frame
		custom_minimum_size.y = size.y

	label.text = ""

	_display_letter()

func _display_letter():
	label.text += text[index]
	index += 1

	if index >= text.length():
		finished_displaying.emit()
		return

	match text[index]:
		".", ",", "!", "?":
			timer.start(time_symbol)
		" ":
			timer.start(time_space)
		_:
			timer.start(time_letter)

func _on_display_timer_timeout():
	_display_letter()
