extends Label

func _ready() -> void:
	TimeManager.time_changed.connect(_on_time_changed)

func _on_time_changed(min: int, sec: int) -> void:
	text = "%02d:%02d" % [min, sec]
