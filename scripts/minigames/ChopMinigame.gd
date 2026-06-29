extends MinigameBase

const VEGGIES = [
	["chili",  "Chili",  6],
	["ginger", "Ginger", 12],
	["onion",  "Onion",  6],
	["garlic", "Garlic", 9],
]

var _veg_idx: int = 0
var _frame: int   = 0
var _total_cuts: int = 0
var _max_cuts: int   = 0
var _flash_timer: float = 0.0
var _done: bool = false
var _finish_timer: float = 0.0
var _board_frames: Array = []
var _bowl_tex: Array = []

# Progress bar constants — matches the scene node positions
const PROG_TOP    := 38.0   # top of ProgressBarBg (offset_top)
const PROG_BOTTOM := 310.0  # bottom of ProgressBarBg (offset_bottom)
const PROG_LEFT   := 20.0
const PROG_RIGHT  := 50.0

@onready var _lbl_timer:    Label       = $TimerLabel
@onready var _lbl_veg_name: Label       = $VegNameLabel
@onready var _lbl_cut_count:Label       = $CutCountLabel
@onready var _board_img:    TextureRect = $CuttingBoard/BoardImage
@onready var _chop_flash:   ColorRect   = $CuttingBoard/ChopFlash
@onready var _prog_fill:    ColorRect   = $CuttingBoard/ProgressFill
@onready var _result_label: Label       = $ResultLabel

@onready var _bowls: Array[TextureRect] = [
	$BowlRow/BowlChili,
	$BowlRow/BowlGinger,
	$BowlRow/BowlOnion,
	$BowlRow/BowlGarlic,
]
@onready var _icons: Array[TextureRect] = [
	$TopRow/IconChili,
	$TopRow/IconGinger,
	$TopRow/IconOnion,
	$TopRow/IconGarlic,
]

func _on_init() -> void:
	_veg_idx = 0
	_frame   = 0
	_total_cuts = 0
	_flash_timer = 0.0
	_done = false
	_finish_timer = 0.0
	_result_label.visible = false
	_chop_flash.color.a = 0.0
	_lbl_timer.text = "Time: %.1f" % _time_limit

	_board_frames.clear()
	_bowl_tex.clear()
	_max_cuts = 0

	for veg in VEGGIES:
		var vid: String = veg[0]
		var frames: int = veg[2]
		_max_cuts += frames - 1

		var veg_frames: Array = []
		for f in range(frames):
			veg_frames.append(load("res://assets/sprites/minigames/Dish1ChopMinigame/board_%s_%02d.png" % [vid, f]))
		_board_frames.append(veg_frames)

		_bowl_tex.append([
			load("res://assets/sprites/minigames/Dish1ChopMinigame/bowl_%s_empty.png" % vid),
			load("res://assets/sprites/minigames/Dish1ChopMinigame/bowl_%s_filled.png" % vid),
		])

	_refresh_board()

func _on_update(delta: float, _remaining: float) -> void:
	if _done:
		_finish_timer -= delta
		if _finish_timer <= 0.0:
			var skill = float(_total_cuts) / float(max(1, _max_cuts))
			complete_minigame(clampf(skill, 0.0, 1.0))
		return

	if _flash_timer > 0.0:
		_flash_timer -= delta
		_chop_flash.color.a = _flash_timer * 4.0

	if Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("ui_down"):
		_do_chop()

func _do_chop() -> void:
	if _done: return
	var cuts_needed: int = VEGGIES[_veg_idx][2] - 1

	_frame += 1
	_total_cuts += 1
	_chop_flash.color.a = 0.55
	_flash_timer = 0.18
	AudioManager.play_sfx(AudioManager.SFX_CHOP)
	_refresh_board()

	if _frame >= cuts_needed:
		_bowls[_veg_idx].texture = _bowl_tex[_veg_idx][1]
		_icons[_veg_idx].modulate = Color(0.5, 0.5, 0.5, 0.5)
		_veg_idx += 1
		_frame = 0

		if _veg_idx >= VEGGIES.size():
			_done = true
			_finish_timer = 1.5
			_result_label.text = "✨ Tadtad na lahat! (All chopped!) ✨"
			_result_label.visible = true
			return
		else:
			_refresh_board()

func _refresh_board() -> void:
	if _veg_idx >= VEGGIES.size(): return

	# Swap board image
	_board_img.texture = _board_frames[_veg_idx][_frame]

	# Update veg name label
	_lbl_veg_name.text = VEGGIES[_veg_idx][1]

	# Update cut count label
	var cuts_needed: int = VEGGIES[_veg_idx][2] - 1
	_lbl_cut_count.text = "Cut Count: %d / %d" % [_frame, cuts_needed]

	# Progress bar: grows UPWARD from bottom
	# When ratio=0 → fill height=0 (top == bottom), ratio=1 → fill covers full bar
	var ratio: float = float(_frame) / float(max(1, cuts_needed))
	var bar_height: float = (PROG_BOTTOM - PROG_TOP) * ratio
	_prog_fill.offset_top    = PROG_BOTTOM - bar_height
	_prog_fill.offset_bottom = PROG_BOTTOM
	_prog_fill.offset_left   = PROG_LEFT
	_prog_fill.offset_right  = PROG_RIGHT

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)
		if remaining < 5.0:
			_lbl_timer.add_theme_color_override("font_color", Color(1, 0.2, 0.2))

func _force_finish() -> void:
	var skill = float(_total_cuts) / float(max(1, _max_cuts))
	complete_minigame(clampf(skill, 0.0, 1.0))
