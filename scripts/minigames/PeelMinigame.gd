extends MinigameBase

# ── Eggplant sprite stages (0=unpeeled .. 7=fully peeled) ────────────────────
const EGGPLANT_TEX_PATHS = [
	"res://assets/sprites/minigames/Dish1PeelMinigame/eggplantpeel_00.png",
	"res://assets/sprites/minigames/Dish1PeelMinigame/eggplantpeel_01.png",
	"res://assets/sprites/minigames/Dish1PeelMinigame/eggplantpeel_02.png",
	"res://assets/sprites/minigames/Dish1PeelMinigame/eggplantpeel_03.png",
	"res://assets/sprites/minigames/Dish1PeelMinigame/eggplantpeel_04.png",
	"res://assets/sprites/minigames/Dish1PeelMinigame/eggplantpeel_05.png",
	"res://assets/sprites/minigames/Dish1PeelMinigame/eggplantpeel_06.png",
	"res://assets/sprites/minigames/Dish1PeelMinigame/eggplantpeel_07.png",
]

const HAND_OPEN_PATH  := "res://assets/sprites/minigames/Dish1PeelMinigame/hand_open.png"
const HAND_PINCH_PATH := "res://assets/sprites/minigames/Dish1PeelMinigame/hand_pinch.png"

const POPUP_BAD_PATH     := "res://assets/sprites/minigames/Dish1PeelMinigame/popup_bad.png"
const POPUP_GOOD_PATH    := "res://assets/sprites/minigames/Dish1PeelMinigame/popup_good.png"
const POPUP_AWESOME_PATH := "res://assets/sprites/minigames/Dish1PeelMinigame/popup_awesome.png"
const POPUP_DONE_PATH    := "res://assets/sprites/minigames/Dish1PeelMinigame/popup_done.png"

# 7 peel actions take the eggplant from stage 0 -> stage 7 (4 right + 3 left)
const NUM_PEELS := 7

const MOVE_SPEED := 220.0

# Hand movement bounds (EggplantArea local coords)
const HAND_X_MIN := 0.0
const HAND_X_MAX := 420.0
const HAND_Y_MIN := 0.0
const HAND_Y_MAX := 420.0

# How close (px) the hand must be to a path point to count it as "traced"
const TRACE_RADIUS := 22.0

# Score thresholds (coverage fraction of the path that was traced while pinching)
const THRESHOLD_GOOD    := 0.45
const THRESHOLD_AWESOME := 0.80

const POPUP_DURATION := 1.5
const POPUP_POP_TIME := 0.18  # scale-in pop animation duration

# Eggplant display rect (EggplantArea local coords) — where the eggplant texture sits
const EGG_LEFT   := 110.0
const EGG_TOP    := 10.0
const EGG_WIDTH  := 220.0
const EGG_HEIGHT := 420.0

# PathDraw configuration
const PATH_PAD_TOP := 10.0      # Padding from top of PathDraw to first point
const PATH_PAD_BOTTOM := 10.0   # Padding from bottom of PathDraw to last point
const PATH_PAD_LEFT := 15.0     # Padding from left edge of PathDraw
const PATH_PAD_RIGHT := 15.0    # Padding from right edge of PathDraw
const MIN_POINT_DISTANCE := 20.0 # Minimum vertical distance between consecutive path points

var _hand_tex_open: Texture2D
var _hand_tex_pinch: Texture2D
var _eggplant_tex: Array = []
var _popup_tex: Dictionary = {}

var _hand_pos: Vector2 = Vector2(200, 0)
var _is_pinching: bool  = false

var _peel_index: int = 0          # 0..NUM_PEELS-1, which transition we're on
var _done: bool       = false
var _finish_timer: float = 0.0

# Path-tracing state for the current peel action
var _current_path: Array = []     # Array[Vector2] in EggplantArea local coords
var _path_traced: Array  = []     # parallel Array[bool], whether each point has been traced
var _was_pinching_last_frame: bool = false
var _has_started_this_peel: bool = false

# Popup animation state
var _popup_active: bool   = false
var _popup_timer: float   = 0.0
var _popup_kind: String   = ""    # "bad" / "good" / "awesome" / "done"

@onready var _lbl_timer:    Label       = $TimerLabel
@onready var _lbl_hint:     Label       = $HintLabel
@onready var _progress_bg:  ColorRect   = $ProgressBg
@onready var _progress_fill: ColorRect  = $ProgressFill
@onready var _eggplant_area: Control    = $EggplantArea
@onready var _eggplant_img: TextureRect = $EggplantArea/EggplantSprite
@onready var _path_draw:    Control     = $EggplantArea/PathDraw
@onready var _hand_img:     TextureRect = $EggplantArea/HandSprite
@onready var _popup_img:    TextureRect = $PopupSprite


# Progress bar bounds (root coords) — mirrors the vertical bar style from the wash minigame
const BAR_LEFT   := 20.0
const BAR_RIGHT  := 70.0
const BAR_TOP    := 90.0
const BAR_BOTTOM := 490.0

var _peel_scores: Array = []

func _on_init() -> void:
	_hand_pos      = Vector2(EGG_LEFT + EGG_WIDTH * 0.5 - 50, EGG_TOP - 60)
	_is_pinching   = false
	_peel_index    = 0
	_done          = false
	_finish_timer  = 0.0
	_popup_active  = false
	_popup_timer   = 0.0
	_was_pinching_last_frame = false
	_has_started_this_peel   = false
	_peel_scores   = []

	_time_limit = 45.0
	_lbl_timer.text = "Time: %.1f" % _time_limit

	_hand_tex_open  = load(HAND_OPEN_PATH)
	_hand_tex_pinch = load(HAND_PINCH_PATH)

	_eggplant_tex.clear()
	for p in EGGPLANT_TEX_PATHS:
		_eggplant_tex.append(load(p))

	_popup_tex = {
		"bad": load(POPUP_BAD_PATH),
		"good": load(POPUP_GOOD_PATH),
		"awesome": load(POPUP_AWESOME_PATH),
		"done": load(POPUP_DONE_PATH),
	}


	_popup_img.visible    = false
	_popup_img.pivot_offset = _popup_img.size * 0.5

	_eggplant_img.texture = _eggplant_tex[0]
	_hand_img.texture     = _hand_tex_open
	_apply_hand_pos()

	_refresh_progress_bar()
	_generate_path_for_peel(_peel_index)
	_lbl_hint.text = "WASD/Arrows move hand | Hold Q/÷ to pinch & peel"


func _on_update(delta: float, _remaining: float) -> void:
	if _done:
		_finish_timer -= delta
		if _finish_timer <= 0.0:
			_finish_with_score()
		return

	if _popup_active:
		_update_popup(delta)
		return

	_handle_movement(delta)
	_handle_pinch_and_trace(delta)


func _handle_movement(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("move_up"):    dir.y -= 1
	if Input.is_action_pressed("move_down"):  dir.y += 1
	if Input.is_action_pressed("move_left"):  dir.x -= 1
	if Input.is_action_pressed("move_right"): dir.x += 1
	if dir != Vector2.ZERO:
		_hand_pos += dir.normalized() * MOVE_SPEED * delta
		_hand_pos.x = clampf(_hand_pos.x, HAND_X_MIN, HAND_X_MAX)
		_hand_pos.y = clampf(_hand_pos.y, HAND_Y_MIN, HAND_Y_MAX)
		_apply_hand_pos()


func _handle_pinch_and_trace(_delta: float) -> void:
	var pinching := Input.is_action_pressed("wash_faucet")  # Q / ÷ (reused action)

	if pinching and not _was_pinching_last_frame:
		_has_started_this_peel = true
	_is_pinching = pinching
	_hand_img.texture = _hand_tex_pinch if pinching else _hand_tex_open

	if pinching:
		_trace_path_near_hand()

	# Release: if the player had pinched at all during this peel attempt, score it now.
	if _was_pinching_last_frame and not pinching and _has_started_this_peel:
		_finish_current_peel()

	_was_pinching_last_frame = pinching


func _trace_path_near_hand() -> void:
	var hand_center := _hand_pos + Vector2(50, 50)  # hand sprite is 100x100, use its center
	var changed := false
	for i in range(_current_path.size()):
		if not _path_traced[i]:
			# Only allow tracing if it's the first point, or the previous point is already traced
			var can_trace: bool = (i == 0) or _path_traced[i - 1]
			if can_trace and hand_center.distance_to(_current_path[i]) <= TRACE_RADIUS:
				_path_traced[i] = true
				changed = true
	if changed:
		_path_draw.queue_redraw()


func _finish_current_peel() -> void:
	var traced_count := 0
	for t in _path_traced:
		if t: traced_count += 1
	var coverage := 0.0
	if _current_path.size() > 0:
		coverage = float(traced_count) / float(_current_path.size())

	_peel_scores.append(coverage)

	var kind := "bad"
	if coverage >= THRESHOLD_AWESOME:
		kind = "awesome"
	elif coverage >= THRESHOLD_GOOD:
		kind = "good"

	_peel_index += 1
	_eggplant_img.texture = _eggplant_tex[clampi(_peel_index, 0, _eggplant_tex.size() - 1)]
	_refresh_progress_bar()

	_has_started_this_peel = false
	_current_path = []
	_path_traced  = []
	_path_draw.queue_redraw()

	_show_popup(kind)


func _show_popup(kind: String) -> void:
	_popup_kind   = kind
	_popup_active = true
	_popup_timer  = 0.0
	_popup_img.texture = _popup_tex[kind]
	_popup_img.visible = true
	_popup_img.scale   = Vector2(0.2, 0.2)
	_popup_img.pivot_offset = _popup_img.size * 0.5


func _update_popup(delta: float) -> void:
	_popup_timer += delta
	if _popup_timer <= POPUP_POP_TIME:
		# pop-in: ease-out overshoot
		var t = _popup_timer / POPUP_POP_TIME
		var s = 2.0 + sin(t * PI) * 0.5
		_popup_img.scale = Vector2.ONE * lerpf(0.2, s, t)
	elif _popup_timer >= POPUP_DURATION - POPUP_POP_TIME:
		# pop-out
		var t = clampf((_popup_timer - (POPUP_DURATION - POPUP_POP_TIME)) / POPUP_POP_TIME, 0.0, 1.0)
		_popup_img.scale = Vector2.ONE * lerpf(2.0, 0.2, t)
	else:
		_popup_img.scale = Vector2(2.0, 2.0)

	if _popup_timer >= POPUP_DURATION:
		_popup_img.visible = false
		_popup_active = false

		if _popup_kind == "done":
			_done = true
			_finish_timer = 1.5
			return

		if _peel_index >= NUM_PEELS:
			_show_done_popup()
		else:
			_generate_path_for_peel(_peel_index)


func _show_done_popup() -> void:
	
	_show_popup("done")


# ── Broken-line path generation ───────────────────────────────────────────
# Picks one of a few preset wavy/zigzag pattern shapes, scaled into PathDraw's
# bounds with configurable padding, ensuring minimum vertical distance between points
func _generate_path_for_peel(peel_idx: int) -> void:
	# Get PathDraw's position and size in EggplantArea local coordinates
	var pd_left := _path_draw.offset_left
	var pd_top := _path_draw.offset_top
	var pd_width := _path_draw.offset_right - _path_draw.offset_left
	var pd_height := _path_draw.offset_bottom - _path_draw.offset_top
	
	# Calculate usable area inside PathDraw with padding
	var usable_left := pd_left + PATH_PAD_LEFT
	var usable_right := pd_left + pd_width - PATH_PAD_RIGHT
	var usable_top := pd_top + PATH_PAD_TOP
	var usable_bottom := pd_top + pd_height - PATH_PAD_BOTTOM
	var usable_height := usable_bottom - usable_top
	var usable_width := usable_right - usable_left
	
	# Calculate number of points to fit within usable height with min distance
	var num_points: int = max(5, int(usable_height / MIN_POINT_DISTANCE) + 1)
	
	# Calculate center X of usable area
	var cx := usable_left + usable_width * 0.5

	var presets := [
		"wavy",
		"zigzag",
		"steep_wave",
	]
	var pattern: String = presets[randi() % presets.size()]

	var pts: Array = []
	for i in range(num_points):
		var t := float(i) / float(num_points - 1)
		var y := lerpf(usable_top, usable_bottom, t)
		var x := cx
		match pattern:
			"wavy":
				x = cx + sin(t * TAU * 1.5) * (usable_width * 0.35)
			"zigzag":
				x = cx + (usable_width * 0.35 if int(t * 6) % 2 == 0 else -usable_width * 0.35)
			"steep_wave":
				x = cx + sin(t * PI * 3.0) * (usable_width * 0.25) + (t - 0.5) * (usable_width * 0.2)
		pts.append(Vector2(x, y))

	# Convert to a broken (dashed) line: keep alternating segments only,
	# but for tracing purposes we sample points only from the "on" dashes.
	_current_path = []
	var dash_on := true
	var dash_len := 2  # Adjusted for new num points
	for i in range(pts.size()):
		if i % dash_len == 0:
			dash_on = not dash_on
		if dash_on:
			_current_path.append(pts[i])

	if _current_path.is_empty():
		_current_path = pts

	_path_traced = []
	for p in _current_path:
		_path_traced.append(false)

	_path_draw.queue_redraw()

	# Move hand to the start of the new path so the player has a clear entry point
	_hand_pos = _current_path[0] - Vector2(50, 50)
	_hand_pos.x = clampf(_hand_pos.x, HAND_X_MIN, HAND_X_MAX)
	_hand_pos.y = clampf(_hand_pos.y, HAND_Y_MIN, HAND_Y_MAX)
	_apply_hand_pos()


func _apply_hand_pos() -> void:
	_hand_img.offset_left   = _hand_pos.x
	_hand_img.offset_top    = _hand_pos.y
	_hand_img.offset_right  = _hand_pos.x + 100
	_hand_img.offset_bottom = _hand_pos.y + 100


func _refresh_progress_bar() -> void:
	var frac := float(_peel_index) / float(NUM_PEELS)
	var bar_h := (BAR_BOTTOM - BAR_TOP) * frac
	_progress_fill.offset_left   = BAR_LEFT
	_progress_fill.offset_right  = BAR_RIGHT
	_progress_fill.offset_bottom = BAR_BOTTOM
	_progress_fill.offset_top    = BAR_BOTTOM - bar_h


func _finish_with_score() -> void:
	var total := 0.0
	for s in _peel_scores:
		total += s
	var avg := 0.0
	if _peel_scores.size() > 0:
		avg = total / float(_peel_scores.size())
	complete_minigame(clampf(avg, 0.0, 1.0))


func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)
		if remaining < 5.0:
			_lbl_timer.add_theme_color_override("font_color", Color(1, 0.2, 0.2))


func _force_finish() -> void:
	_finish_with_score()


# ── Public accessors used by PathDraw.gd (child node custom drawing) ─────────
func get_path_points() -> Array:
	return _current_path

func get_path_traced() -> Array:
	return _path_traced
