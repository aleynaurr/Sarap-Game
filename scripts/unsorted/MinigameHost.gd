extends CanvasLayer

const MINIGAME_SCENES = {
	"wash":           preload("res://scenes/minigames/WashMinigame.tscn"),
	"chop":           preload("res://scenes/minigames/ChopMinigame.tscn"),
	"mince":          preload("res://scenes/minigames/MinceMinigame.tscn"),
	"fry":            preload("res://scenes/minigames/FryMinigame.tscn"),
	"simmer":         preload("res://scenes/minigames/SimmmerMinigame.tscn"),
	"crack_egg":      preload("res://scenes/minigames/CrackEggMinigame.tscn"),
	"mix":            preload("res://scenes/minigames/MixMinigame.tscn"),
	"roll":           preload("res://scenes/minigames/RollMinigame.tscn"),
	"plate":          preload("res://scenes/minigames/PlateMinigame.tscn"),
	"add_to_bowl":    preload("res://scenes/minigames/AddToBowlMinigame.tscn"),
	"cook_rice":      preload("res://scenes/minigames/CookRiceMinigame.tscn"),
	"prick_season":   preload("res://scenes/minigames/PrickSeasonMinigame.tscn"),
}

var _active_minigame: MinigameBase = null
var _step_index: int = -1

signal minigame_done(step_index: int, skill_ratio: float, time_ratio: float)

func launch(step: Dictionary, step_index: int) -> void:
	if _active_minigame:
		_active_minigame.queue_free()
		_active_minigame = null

	var mg_id: String = step.get("minigame", "plate")
	var mg_scene = MINIGAME_SCENES.get(mg_id, MINIGAME_SCENES["plate"])

	var mg = mg_scene.instantiate()
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
