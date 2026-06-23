extends CanvasLayer
# MinigameHost sits on top of the Kitchen scene.
# It creates the right MinigameBase subclass, shows it, captures input, then
# reports back to Kitchen when done.

const MINIGAME_SCRIPTS = {
	"wash":     preload("res://scripts/minigames/WashMinigame.gd"),
	"chop":     preload("res://scripts/minigames/ChopMinigame.gd"),
	"mince":    preload("res://scripts/minigames/MinceMinigame.gd"),
	"fry":      preload("res://scripts/minigames/FryMinigame.gd"),
	"simmer":   preload("res://scripts/minigames/SimmmerMinigame.gd"),
	"crack_egg":preload("res://scripts/minigames/CrackEggMinigame.gd"),
	"mix":      preload("res://scripts/minigames/MixMinigame.gd"),
	"roll":     preload("res://scripts/minigames/RollMinigame.gd"),
	"plate":    preload("res://scripts/minigames/PlateMinigame.gd"),
	"add_to_bowl": preload("res://scripts/minigames/AddToBowlMinigame.gd"),
}

var _active_minigame: MinigameBase = null
var _step_index: int = -1

signal minigame_done(step_index: int, skill_ratio: float, time_ratio: float)

func launch(step: Dictionary, step_index: int) -> void:
	if _active_minigame:
		_active_minigame.queue_free()
		_active_minigame = null

	var mg_id: String = step.get("minigame", "plate")
	var mg_script = MINIGAME_SCRIPTS.get(mg_id, MINIGAME_SCRIPTS["plate"])

	var mg = Control.new()
	mg.set_script(mg_script)
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(mg)
	_active_minigame = mg
	_step_index = step_index

	mg.init_step(step)
	mg.minigame_completed.connect(_on_minigame_completed)

	visible = true
	AudioManager.play_sfx(AudioManager.SFX_CLICK)

func _on_minigame_completed(skill_ratio: float, time_ratio: float) -> void:
	visible = false
	if _active_minigame:
		_active_minigame.queue_free()
		_active_minigame = null
	minigame_done.emit(_step_index, skill_ratio, time_ratio)

func close_active() -> void:
	if _active_minigame:
		_active_minigame.queue_free()
		_active_minigame = null
	visible = false
