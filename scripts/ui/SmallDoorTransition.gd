extends CanvasLayer

## Small door-wipe transition confined to a single player's Kitchen
## SubViewport (640x720 local space), used when entering/exiting a minigame.
## Two 320x720 door halves slide in from off-screen left/right until they
## meet at the local center (x=320), fully covering the kitchen view, hold
## briefly, then an injected callback runs (e.g. launching the minigame, or
## re-enabling the player) before the doors slide back out. Frees itself
## when finished.
##
## Usage (add as a child within the Kitchen scene, NOT the global root,
## so it stays confined to this player's own viewport):
##   var door := preload("res://scenes/SmallDoorTransition.tscn").instantiate()
##   add_child(door)
##   door.play_transition(func(): minigame_host.launch(step_dict, step_index))

const PANEL_WIDTH := 640.0   # this player's local Kitchen viewport width
const DOOR_WIDTH := 320.0    # each door half

const CLOSE_DURATION := 1.0
const HOLD_DURATION := 0.4
const OPEN_DURATION := 1.0

@onready var door_left: TextureRect  = $DoorLeft
@onready var door_right: TextureRect = $DoorRight
@onready var closing_sfx: AudioStreamPlayer = $DoorClosingSFX
@onready var opening_sfx: AudioStreamPlayer = $DoorOpeningSFX


func _ready() -> void:
	layer = 100  # render above the kitchen HUD/minigame host within this viewport

	# Start fully off-screen relative to this player's own 640-wide panel.
	door_left.position.x = -DOOR_WIDTH
	door_right.position.x = PANEL_WIDTH


## Runs the full close -> callback -> open sequence, then queue_frees self.
func play_transition(on_midpoint: Callable) -> void:
	await _close_doors()
	await get_tree().create_timer(HOLD_DURATION).timeout

	if on_midpoint.is_valid():
		on_midpoint.call()

	await get_tree().process_frame  # let whatever changed settle in first
	await _open_doors()

	queue_free()


func _close_doors() -> void:
	closing_sfx.play()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(door_left, "position:x", 0.0, CLOSE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(door_right, "position:x", DOOR_WIDTH, CLOSE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished


func _open_doors() -> void:
	opening_sfx.play()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(door_left, "position:x", -DOOR_WIDTH, OPEN_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(door_right, "position:x", PANEL_WIDTH, OPEN_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
