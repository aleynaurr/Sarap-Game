extends CanvasLayer

## Full-screen (1280x720) door-wipe transition.
## Two 640x720 door halves slide in from off-screen left/right until they
## meet at the center (fully covering the screen), hold briefly, then an
## injected callback runs (e.g. changing scene) before the doors slide
## back out to reveal what's underneath. Frees itself when finished.
##
## Usage:
##   var door := preload("res://scenes/DoorTransition.tscn").instantiate()
##   get_tree().root.add_child(door)
##   door.play_transition(func(): GameManager.go_to_main_menu())

const SCREEN_WIDTH := 1280.0
const PANEL_WIDTH := 640.0

const CLOSE_DURATION := 1.0
const HOLD_DURATION := 0.4
const OPEN_DURATION := 1.0

@onready var door_left: TextureRect  = $DoorLeft
@onready var door_right: TextureRect = $DoorRight
@onready var closing_sfx: AudioStreamPlayer = $DoorClosingSFX
@onready var opening_sfx: AudioStreamPlayer = $DoorOpeningSFX


func _ready() -> void:
	layer = 100  # render above everything, including split-screen viewports

	# Start fully off-screen: left door hidden past the left edge,
	# right door hidden past the right edge.
	door_left.position.x = -PANEL_WIDTH
	door_right.position.x = SCREEN_WIDTH


## Runs the full close -> callback -> open sequence, then queue_frees self.
func play_transition(on_midpoint: Callable) -> void:
	await _close_doors()
	await get_tree().create_timer(HOLD_DURATION).timeout

	if on_midpoint.is_valid():
		on_midpoint.call()

	await get_tree().process_frame  # let the new scene settle in first
	await _open_doors()

	queue_free()


func _close_doors() -> void:
	closing_sfx.play()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(door_left, "position:x", 0.0, CLOSE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(door_right, "position:x", PANEL_WIDTH, CLOSE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished


func _open_doors() -> void:
	opening_sfx.play()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(door_left, "position:x", -PANEL_WIDTH, OPEN_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(door_right, "position:x", SCREEN_WIDTH, OPEN_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
