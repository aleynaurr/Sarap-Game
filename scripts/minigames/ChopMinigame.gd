extends MinigameBase

const VEGGIES = [
	["chili",  "Chili",  6],
	["ginger", "Ginger", 12],
	["onion",  "Onion",  6],
	["garlic", "Garlic", 9],
]

const POPUP_START_PATH := "res://assets/sprites/minigames/Dish1ChopMinigame/popup_start.png"
const POPUP_DONE_PATH  := "res://assets/sprites/minigames/Dish1ChopMinigame/popup_done.png"
const POPUP_FAIL_PATH  := "res://assets/sprites/minigames/Dish1ChopMinigame/popup_fail.png"
const POPUP_POP_TIME := 0.18
const POPUP_HOLD_TIME := 1.4

const NOMINAL_TIME_LIMIT := 120.0
const TIME_LIMIT_BUFFER  := 2.0

const DIRECTIONS = [
	["north", Vector2(0, -1), preload("res://assets/sprites/minigames/Dish1ChopMinigame/arrow_north.png")],
	["east",  Vector2(1,  0), preload("res://assets/sprites/minigames/Dish1ChopMinigame/arrow_east.png")],
	["south", Vector2(0,  1), preload("res://assets/sprites/minigames/Dish1ChopMinigame/arrow_south.png")],
	["west",  Vector2(-1, 0), preload("res://assets/sprites/minigames/Dish1ChopMinigame/arrow_west.png")],
]

const PROGRESS_FILL_TIME := 0.40
const PROGRESS_DRAIN_TIME := 1.2
const HAND_SPEED := 400.0
const HAND_SIZE := Vector2(80, 80)

var _veg_idx: int = 0
var _frame: int = 0
var _total_cuts: int = 0
var _max_cuts: int = 0
var _chop_flash_timer: float = 0.0
var _done: bool = false
var _finish_timer: float = 0.0
var _board_frames: Array = []
var _bowl_tex: Array = []

var _popup_tex: Dictionary = {}
var _popup_active: bool = false
var _popup_timer: float = 0.0
var _popup_kind: String = ""
var _failed: bool = false

const PROG_TOP := 38.0
const PROG_BOTTOM := 310.0
const PROG_LEFT := 20.0
const PROG_RIGHT := 50.0

const HOLD_LEFT := 459.0
const HOLD_RIGHT := 491.0

var _hand_pos: Vector2 = Vector2(320, 360)
var _is_pinching: bool = false

var _current_dir_idx: int = 0
var _arrow_progress: float = 0.0
var _arrow_visible: bool = false
var _arrow_state: int = 0
var _arrow_timer: float = 0.0
var _arrow_flash: float = 0.0

@onready var _lbl_timer: Label = $TimerLabel
@onready var _lbl_veg_name: Label = $VegNameLabel
@onready var _lbl_cut_count: Label = $CutCountLabel
@onready var _board_img: TextureRect = $CuttingBoard/BoardImage
@onready var _chop_flash: ColorRect = $CuttingBoard/ChopFlash
@onready var _prog_fill: ColorRect = $CuttingBoard/ProgressFill
@onready var _result_label: Label = $ResultLabel

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

@onready var _start_popup: Control = $StartPopup
@onready var _popup: Control = $EndPopup
@onready var _popup_img: TextureRect = $EndPopup/EndPopupImage

@onready var _hand: TextureRect = $Hand
@onready var _hand_tex_open: Texture2D = preload("res://assets/sprites/minigames/Dish1ChopMinigame/hand_open.png")
@onready var _hand_tex_pinch: Texture2D = preload("res://assets/sprites/minigames/Dish1ChopMinigame/hand_pinching.png")

@onready var _arrow_container: Control = $CuttingBoard/ArrowContainer
@onready var _arrow_img: TextureRect = $CuttingBoard/ArrowContainer/ArrowImage
@onready var _arrow_flash_node: ColorRect = $CuttingBoard/ArrowContainer/ArrowFlash
@onready var _hold_fill: ColorRect = $CuttingBoard/HoldBarFill

func _on_init() -> void:
	_veg_idx = 0
	_frame = 0
	_total_cuts = 0
	_chop_flash_timer = 0.0
	_done = false
	_finish_timer = 0.0
	_result_label.visible = false
	_chop_flash.color.a = 0.0
	_time_limit = NOMINAL_TIME_LIMIT + TIME_LIMIT_BUFFER
	_lbl_timer.text = "Time: %.1f" % NOMINAL_TIME_LIMIT

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

	_hand_pos = Vector2(320, 360)
	_update_hand_position()

	_arrow_visible = false
	_arrow_state = 0
	_arrow_progress = 0.0
	_arrow_timer = 0.0
	_arrow_flash = 0.0
	_arrow_container.visible = false

	_refresh_board()
	_update_overall_progress()
	_update_hold_fill()

	_popup_active = false
	_popup_timer = 0.0
	_popup_kind = ""
	_failed = false

	_popup_tex = {
		"done": load(POPUP_DONE_PATH),
		"fail": load(POPUP_FAIL_PATH),
	}
	_popup.visible = false
	_popup.scale = Vector2(0.1, 0.1)

	_show_start_popup()

func _on_update(delta: float, remaining: float) -> void:
	if _done:
		_finish_timer -= delta
		if _finish_timer <= 0.0:
			var skill = float(_total_cuts) / float(max(1, _max_cuts))
			complete_minigame(clampf(skill, 0.0, 1.0))
		return

	if _popup_active:
		_update_end_popup(delta)
		return

	if not _failed and remaining <= TIME_LIMIT_BUFFER:
		_failed = true
		_hide_start_popup_now()
		_show_end_popup("fail")
		return

	if _chop_flash_timer > 0.0:
		_chop_flash_timer -= delta
		_chop_flash.color.a = _chop_flash_timer * 4.0

	_update_hand(delta)
	_update_arrow(delta)
	_check_arrow_spawn()

func _update_hand(delta: float) -> void:
	var move_dir = Vector2.ZERO

	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		move_dir.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		move_dir.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		move_dir.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		move_dir.x += 1

	if move_dir.length_squared() > 0:
		move_dir = move_dir.normalized()
		_hand_pos += move_dir * HAND_SPEED * delta

	_hand_pos.x = clamp(_hand_pos.x, HAND_SIZE.x / 2, 640 - HAND_SIZE.x / 2)
	_hand_pos.y = clamp(_hand_pos.y, HAND_SIZE.y / 2, 720 - HAND_SIZE.y / 2)
	_update_hand_position()

	_is_pinching = Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_SLASH)
	_hand.texture = _hand_tex_pinch if _is_pinching else _hand_tex_open

func _update_hand_position() -> void:
	_hand.offset_left = _hand_pos.x - HAND_SIZE.x / 2
	_hand.offset_top = _hand_pos.y - HAND_SIZE.y / 2
	_hand.offset_right = _hand_pos.x + HAND_SIZE.x / 2
	_hand.offset_bottom = _hand_pos.y + HAND_SIZE.y / 2

func _check_arrow_spawn() -> void:
	if _done or _failed or _veg_idx >= VEGGIES.size():
		return
	if _arrow_visible or _arrow_state > 0:
		return

	var cuts_needed = VEGGIES[_veg_idx][2] - 1
	if _frame < cuts_needed:
		_spawn_new_arrow()

func _spawn_new_arrow() -> void:
	_current_dir_idx = randi() % DIRECTIONS.size()
	_arrow_img.texture = DIRECTIONS[_current_dir_idx][2]
	_arrow_progress = 0.0
	_arrow_visible = true
	_arrow_state = 1
	_arrow_timer = 0.0
	_arrow_container.visible = true
	_arrow_container.scale = Vector2(0.1, 0.1)
	_update_hold_fill()

func _update_arrow(delta: float) -> void:
	if _arrow_state == 0:
		return

	_arrow_timer += delta

	if _arrow_state == 1:
		var t = min(_arrow_timer / POPUP_POP_TIME, 1.0)
		var s = 1.0 + sin(t * PI) * 0.25
		_arrow_container.scale = Vector2.ONE * lerpf(0.1, s, t)
		if t >= 1.0:
			_arrow_state = 2
			_arrow_timer = 0.0
		return

	if _arrow_state == 2:
		_arrow_container.scale = Vector2.ONE
		if _is_pinching:
			var input_dir = _get_input_direction()
			var target_dir = DIRECTIONS[_current_dir_idx][1]
			if input_dir.dot(target_dir) > 0.7:
				_arrow_progress += delta / PROGRESS_FILL_TIME
				if _arrow_progress >= 1.0:
					_arrow_progress = 1.0
					_arrow_state = 3
					_arrow_timer = 0.0
					_arrow_flash = 1.0
			else:
				_arrow_progress -= delta / PROGRESS_DRAIN_TIME
		else:
			_arrow_progress -= delta / PROGRESS_DRAIN_TIME
		_arrow_progress = clamp(_arrow_progress, 0.0, 1.0)
		_update_hold_fill()
		return

	if _arrow_state == 3:
		_arrow_flash = max(0.0, _arrow_flash - delta * 4.0)
		_arrow_flash_node.color.a = _arrow_flash
		if _arrow_timer < 0.2:
			var t = _arrow_timer / 0.2
			_arrow_container.scale = Vector2.ONE * lerpf(1.0, 1.3, t)
		elif _arrow_timer < 0.4:
			var t = (_arrow_timer - 0.2) / 0.2
			_arrow_container.scale = Vector2.ONE * lerpf(1.3, 0.9, t)
		elif _arrow_timer < 0.6:
			var t = (_arrow_timer - 0.4) / 0.2
			_arrow_container.scale = Vector2.ONE * lerpf(0.9, 1.0, t)
		elif _arrow_timer < 0.8:
			var t = (_arrow_timer - 0.6) / 0.2
			_arrow_container.scale = Vector2.ONE * lerpf(1.0, 0.1, t)
		if _arrow_timer >= 0.8:
			_arrow_visible = false
			_arrow_state = 0
			_arrow_container.visible = false
			_arrow_flash_node.color.a = 0.0
			_do_chop()
		return

func _get_input_direction() -> Vector2:
	var dir = Vector2.ZERO
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		dir.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		dir.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		dir.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		dir.x += 1
	if dir.length_squared() > 0:
		return dir.normalized()
	return Vector2.ZERO

func _update_hold_fill() -> void:
	var ratio: float = _arrow_progress
	var bar_height: float = (PROG_BOTTOM - PROG_TOP) * ratio
	_hold_fill.offset_top = PROG_BOTTOM - bar_height - 2
	_hold_fill.offset_bottom = PROG_BOTTOM - 2
	_hold_fill.offset_left = HOLD_LEFT
	_hold_fill.offset_right = HOLD_RIGHT

func _do_chop() -> void:
	if _done: return
	_hide_start_popup_now()
	var cuts_needed: int = VEGGIES[_veg_idx][2] - 1

	_frame += 1
	_total_cuts += 1
	_chop_flash.color.a = 0.55
	_chop_flash_timer = 0.18
	AudioManager.play_sfx(AudioManager.SFX_CHOP)
	_refresh_board()
	_update_overall_progress()

	if _frame >= cuts_needed:
		_bowls[_veg_idx].texture = _bowl_tex[_veg_idx][1]
		_icons[_veg_idx].modulate = Color(0.0, 0.0, 0.0, 0.0)
		_veg_idx += 1
		_frame = 0

		if _veg_idx >= VEGGIES.size():
			_show_end_popup("done")
			return
		else:
			_refresh_board()

func _refresh_board() -> void:
	if _veg_idx >= VEGGIES.size(): return

	_board_img.texture = _board_frames[_veg_idx][_frame]
	_lbl_veg_name.text = VEGGIES[_veg_idx][1]
	var cuts_needed: int = VEGGIES[_veg_idx][2] - 1
	_lbl_cut_count.text = "Cut Count: %d / %d" % [_frame, cuts_needed]

func _update_overall_progress() -> void:
	var ratio: float = float(_total_cuts) / float(max(1, _max_cuts))
	var bar_height: float = (PROG_BOTTOM - PROG_TOP) * ratio
	_prog_fill.offset_top = PROG_BOTTOM - bar_height
	_prog_fill.offset_bottom = PROG_BOTTOM
	_prog_fill.offset_left = PROG_LEFT + 43
	_prog_fill.offset_right = PROG_RIGHT + 43

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		var shown := minf(remaining, NOMINAL_TIME_LIMIT)
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, shown)
		if shown < 5.0:
			_lbl_timer.add_theme_color_override("font_color", Color(1, 0.2, 0.2))

func _force_finish() -> void:
	var skill = float(_total_cuts) / float(max(1, _max_cuts))
	complete_minigame(clampf(skill, 0.0, 1.0))

func _show_start_popup() -> void:
	_start_popup.visible = true
	_start_popup.scale = Vector2(0.1, 0.1)

	var tw := create_tween()
	tw.tween_property(_start_popup, "scale", Vector2(1.12, 1.12), 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_start_popup, "scale", Vector2(1.0, 1.0), 0.10)

	var hide_tw := create_tween()
	hide_tw.tween_interval(3.0)
	hide_tw.tween_property(_start_popup, "scale", Vector2(0.1, 0.1), 0.16) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	hide_tw.tween_callback(func(): _start_popup.visible = false)

func _hide_start_popup_now() -> void:
	if not _start_popup.visible:
		return
	var tw := create_tween()
	tw.tween_property(_start_popup, "scale", Vector2(0.1, 0.1), 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): _start_popup.visible = false)

func _show_end_popup(kind: String) -> void:
	_popup_kind = kind
	_popup_active = true
	_popup_timer = 0.0
	_popup_img.texture = _popup_tex[kind]
	_popup.visible = true
	_popup.scale = Vector2(0.1, 0.1)

func _update_end_popup(delta: float) -> void:
	_popup_timer += delta
	if _popup_timer <= POPUP_POP_TIME:
		var t = _popup_timer / POPUP_POP_TIME
		var s = 1.0 + sin(t * PI) * 0.25
		_popup.scale = Vector2.ONE * lerpf(0.1, s, t)
	elif _popup_timer >= POPUP_POP_TIME + POPUP_HOLD_TIME:
		var t = clampf((_popup_timer - (POPUP_POP_TIME + POPUP_HOLD_TIME)) / POPUP_POP_TIME, 0.0, 1.0)
		_popup.scale = Vector2.ONE * lerpf(1.0, 0.1, t)
	else:
		_popup.scale = Vector2(1.0, 1.0)

	if _popup_timer >= POPUP_POP_TIME * 2.0 + POPUP_HOLD_TIME:
		_popup.visible = false
		_popup_active = false
		_done = true
		_finish_timer = 0.05
