extends MinigameBase

# ════════════════════════════════════════════════════════════════════════
#  MASH MINIGAME
#  Pick up the fork (Q / ÷), move it with WASD/Arrows onto the circle
#  target above the eggplant, hold E / Shift to charge the Mash Power
#  bar, release to score, watch the fork "mash" the eggplant, then
#  repeat for all 4 circles.
# ════════════════════════════════════════════════════════════════════════

const LINE_COUNT := 4

# ── Bar colour segments, left → right (mirrors the reference sketch:
#    red, yellow, small green, red(centre), green, yellow, red) ──────────
const BAR_SEGMENTS := [
	{"color": Color(0.85, 0.2, 0.2, 1), "width": 0.18, "points": 10, "tier": "red"},
	{"color": Color(0.95, 0.8, 0.15, 1), "width": 0.15, "points": 20, "tier": "yellow"},
	{"color": Color(0.2, 0.8, 0.25, 1), "width": 0.07, "points": 50, "tier": "green"},
	{"color": Color(0.85, 0.2, 0.2, 1), "width": 0.20, "points": 10, "tier": "red"},
	{"color": Color(0.2, 0.8, 0.25, 1), "width": 0.10, "points": 50, "tier": "green"},
	{"color": Color(0.95, 0.8, 0.15, 1), "width": 0.15, "points": 20, "tier": "yellow"},
	{"color": Color(0.85, 0.2, 0.2, 1), "width": 0.15, "points": 10, "tier": "red"},
]

const POPUP_IMAGE_PATHS := {
	"red":    "res://assets/sprites/minigames/Dish1MashMinigame/popup_red.png",
	"yellow": "res://assets/sprites/minigames/Dish1MashMinigame/popup_yellow.png",
	"green":  "res://assets/sprites/minigames/Dish1MashMinigame/popup_green.png",
}
const POPUP_DONE_IMAGE_PATH := "res://assets/sprites/minigames/Dish1MashMinigame/popup_done.png"

# ── Marker speed ramps up each line (gets harder) ────────────────────────
const MARKER_BASE_SPEED := 0.55   # fraction of bar per second, line 0
const MARKER_SPEED_STEP := 0.18   # added per subsequent line

# ── Fork grow / bounce ───────────────────────────────────────────────────
const GROWTH_RATE     := 0.55     # scale units per second while holding
const MAX_FORK_SCALE  := 4.0      # Bigger max scale for big fork
const BOUNCE_DIP_SCALE:= 2.0      # Bounce dip scale

# ── Fork movement bounds (root-local coords) ─────────────────────────────
const FORK_X_MIN := 170.0
const FORK_X_MAX := 430.0
const FORK_Y_MIN := 90.0
const FORK_Y_MAX := 430.0
const MOVE_SPEED := 220.0

# ════════════════════════════════════════════════════════════════════════
#  CIRCLE TARGET GEOMETRY
#  ------------------------------------------------------------------------
#  The 4 circle targets live directly in MashMinigame.tscn as
#  $PlateArea/Circle0..Circle3, positioned to match the CircleSample1-4
#  guide markers. This script reads each circle's rect straight off the
#  node at runtime (see _on_init), so there's nothing to keep in sync by
#  hand — move a Circle node in the editor and hover-detection follows.
# ════════════════════════════════════════════════════════════════════════
const CIRCLE_HOVER_RADIUS := 42.0   # how close the fork's centre must be to a circle's centre to count as hovering over it
const CIRCLE_POP_IN_TIME  := 0.18
const CIRCLE_POP_OUT_TIME := 0.14

# ── Mash power bar geometry ───────────────────────────────────────────────
const BAR_LEFT  = 100.0
const BAR_RIGHT = 540.0
const BAR_HEIGHT = 40.0

# ── Left "overall progress" gauge geometry ───────────────────────────────
const GAUGE_LEFT   := 20.0
const GAUGE_RIGHT  := 60.0
const GAUGE_TOP    := 90.0
const GAUGE_BOTTOM := 430.0

var _circle_centers: Array = []

var _fork_picked_up := false
var _fork_pos := Vector2.ZERO
var _fork_base_size := Vector2.ZERO

var _is_hovering := false
var _mashing := false
var _bouncing := false
var _popup_showing := false
var _busy := false   # true while bounce/popup animation is playing (blocks input)

var _marker_progress := 0.0
var _marker_direction := 1.0   # +1 = moving right, -1 = moving left (ping-pong loop)
var _current_line := 0
var _line_scores: Array = [0, 0, 0, 0]
var _total_points := 0

var _last_remaining := 30.0
var _game_done := false
var _finish_timer := 0.0

var _eggplant_tex: Array = []

@onready var _lbl_timer:    Label       = $TimerLabel
@onready var _plate_img:    TextureRect = $PlateArea/Plate
@onready var _eggplant_img: TextureRect = $PlateArea/Eggplant
@onready var _fork_img:     TextureRect = $ForkSprite
@onready var _sample_y_axis: ColorRect = $SampleYAxis

@onready var _circles: Array[TextureRect] = []  # filled in code (4 circle targets)

@onready var _mash_power_area: Control = $MashPowerArea
@onready var _bar_bg:        ColorRect = $MashPowerArea/MashPowerBg
@onready var _bar_segments_box: Control = $MashPowerArea/SegmentsBox
@onready var _bar_marker:    ColorRect = $MashPowerArea/Marker
@onready var _bar_label:     Label     = $MashPowerArea/MashPowerLabel

@onready var _gauge_bg:   ColorRect = $ProgressGauge/GaugeBg
@onready var _gauge_fill: ColorRect = $ProgressGauge/GaugeFill

@onready var _popup:      Control = $Popup
@onready var _popup_img:  TextureRect = $Popup/PopupImage

var _popup_tex: Dictionary = {}
var _popup_done_tex: Texture2D = null


func _on_init() -> void:
	_fork_picked_up  = false
	_is_hovering     = false
	_mashing         = false
	_bouncing        = false
	_popup_showing   = false
	_busy            = false
	_marker_progress = 0.0
	_current_line    = 0
	_line_scores     = [0, 0, 0, 0]
	_total_points    = 0
	_game_done       = false
	_finish_timer    = 0.0

	_time_limit = 30.0
	_lbl_timer.text = "Time: %.1f" % _time_limit

	_eggplant_tex = [
		load("res://assets/sprites/minigames/Dish1MashMinigame/eggplant_00_unmashed.png"),
		load("res://assets/sprites/minigames/Dish1MashMinigame/eggplant_01_mash1.png"),
		load("res://assets/sprites/minigames/Dish1MashMinigame/eggplant_02_mash2.png"),
		load("res://assets/sprites/minigames/Dish1MashMinigame/eggplant_03_mash3.png"),
		load("res://assets/sprites/minigames/Dish1MashMinigame/eggplant_04_fullymashed.png"),
	]
	_eggplant_img.texture = _eggplant_tex[0]

	_circles = [
		$PlateArea/Circle0,
		$PlateArea/Circle1,
		$PlateArea/Circle2,
		$PlateArea/Circle3,
	]
	# Centres derived straight from each Circle node's own tscn rect — move
	# a Circle node in the editor and hover-detection follows automatically.
	_circle_centers.clear()
	for circle in _circles:
		_circle_centers.append(Vector2(
			(circle.offset_left + circle.offset_right) * 0.5,
			(circle.offset_top + circle.offset_bottom) * 0.5
		))
		circle.visible = false
		circle.scale = Vector2(1, 1)
	_pop_in_circle(_circles[0])   # first target pops in right away

	# Fork starts fixed, vertical, parked to the right of the plate — size,
	# position, scale, rotation AND pivot_offset are all whatever's set on
	# the ForkSprite node in the Inspector/tscn. The script only reads the
	# rect here; it never writes pivot_offset until pickup, so the vertical
	# fork renders in exactly the spot you see in the Godot editor.
	_fork_img.texture = load("res://assets/sprites/minigames/Dish1MashMinigame/fork_vertical.png")
	_fork_base_size = Vector2(
		_fork_img.offset_right - _fork_img.offset_left,
		_fork_img.offset_bottom - _fork_img.offset_top
	)
	_fork_pos = Vector2(_fork_img.offset_left, _fork_img.offset_top)
	_apply_fork_rect()

	_build_bar_segments()
	_bar_marker.visible = false
	_mash_power_area.visible = false

	_gauge_fill.offset_top = GAUGE_BOTTOM
	_refresh_gauge(0.0, true)

	_popup_tex = {
		"red":    load(POPUP_IMAGE_PATHS["red"]),
		"yellow": load(POPUP_IMAGE_PATHS["yellow"]),
		"green":  load(POPUP_IMAGE_PATHS["green"]),
	}
	_popup_done_tex = load(POPUP_DONE_IMAGE_PATH)

	_popup.visible = false
	_popup.scale = Vector2(0.1, 0.1)


func _on_update(delta: float, remaining: float) -> void:
	_last_remaining = remaining

	if _game_done:
		_finish_timer -= delta
		if _finish_timer <= 0.0:
			_finish_with_score()
		return

	if _busy:
		return  # bounce / popup animation in progress, ignore input

	if not _fork_picked_up:
		if Input.is_action_just_pressed("wash_faucet"):
			_pickup_fork()
		return

	_handle_fork_movement(delta)
	_update_hover_state()

	if _is_hovering:
		if not _mash_power_area.visible:
			_mash_power_area.visible = true
			_bar_marker.visible = false
			_marker_progress = 0.0
			_update_marker_visual()

		var holding := _is_action_key_held()
		if holding and not _mashing:
			_start_mashing()
		if _mashing:
			_update_mash_marker(delta)
			_grow_fork(delta)
		if not holding and _mashing:
			_release_mash()
	else:
		if _mash_power_area.visible:
			_mash_power_area.visible = false
			_bar_marker.visible = false
		if _mashing:
			_cancel_mashing()


# ════════════════════════════ FORK / MOVEMENT ════════════════════════════

func _pickup_fork() -> void:
	_fork_picked_up = true
	# Centre computed from the vertical fork's logical (unrotated) box —
	# this is the same box math used for movement/hover, so the horizontal
	# fork always spawns from wherever the vertical fork's box currently is.
	var center := _fork_pos + _fork_base_size * 0.5
	_fork_base_size = Vector2(184, 72)  # Horizontal fork size
	_fork_img.texture = load("res://assets/sprites/minigames/Dish1MashMinigame/fork_horizontal.png")
	_fork_img.rotation = 0.0  # No rotation when horizontal
	_fork_pos = center - _fork_base_size * 0.5
	_fork_pos.x = clampf(_fork_pos.x, FORK_X_MIN, FORK_X_MAX)
	_fork_pos.y = clampf(_fork_pos.y, FORK_Y_MIN, FORK_Y_MAX)
	# Recentre the pivot now (only here) so the horizontal fork's grow/shrink
	# mash animation scales around its own middle instead of a corner.
	_fork_img.pivot_offset = _fork_base_size * 0.5
	_apply_fork_rect()


func _handle_fork_movement(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("move_up"):    dir.y -= 1
	if Input.is_action_pressed("move_down"):  dir.y += 1
	if Input.is_action_pressed("move_left"):  dir.x -= 1
	if Input.is_action_pressed("move_right"): dir.x += 1
	if dir == Vector2.ZERO:
		return
	_fork_pos += dir.normalized() * MOVE_SPEED * delta
	_fork_pos.x = clampf(_fork_pos.x, FORK_X_MIN, FORK_X_MAX)
	_fork_pos.y = clampf(_fork_pos.y, FORK_Y_MIN, FORK_Y_MAX)
	_apply_fork_rect()


func _apply_fork_rect() -> void:
	_fork_img.offset_left   = _fork_pos.x
	_fork_img.offset_top    = _fork_pos.y
	_fork_img.offset_right  = _fork_pos.x + _fork_base_size.x
	_fork_img.offset_bottom = _fork_pos.y + _fork_base_size.y
	# NOTE: pivot_offset is intentionally NOT touched here. It's left exactly
	# as set on the ForkSprite node (Inspector / tscn) while vertical, so the
	# rotation+scale in the tscn render in the same place as the editor
	# preview. It's only recentred once, in _pickup_fork(), for the
	# horizontal grow/shrink mash animation.


func _update_hover_state() -> void:
	if _current_line >= LINE_COUNT:
		_is_hovering = false
		return
	var fork_center := _fork_pos + _fork_base_size * 0.5
	var circle_center: Vector2 = _circle_centers[_current_line]
	_is_hovering = fork_center.distance_to(circle_center) <= CIRCLE_HOVER_RADIUS


# ──────────────────────────────────────────────────────────────────────────
#  Circle target pop in/out animations.
# ──────────────────────────────────────────────────────────────────────────
func _pop_in_circle(circle: TextureRect) -> void:
	circle.visible = true
	circle.scale = Vector2(0.1, 0.1)
	var t := create_tween()
	t.tween_property(circle, "scale", Vector2(1.15, 1.15), CIRCLE_POP_IN_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(circle, "scale", Vector2(1.0, 1.0), 0.08)


func _pop_out_circle(circle: TextureRect) -> void:
	var t := create_tween()
	t.tween_property(circle, "scale", Vector2(0.1, 0.1), CIRCLE_POP_OUT_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_callback(Callable(circle, "set").bind("visible", false))


func _is_action_key_held() -> bool:
	return Input.is_action_pressed("interact") or Input.is_action_pressed("wash_next")


# ════════════════════════════ MASH POWER BAR ═════════════════════════════

func _build_bar_segments() -> void:
	for child in _bar_segments_box.get_children():
		child.queue_free()
	var x := 0.0
	var w := BAR_RIGHT - BAR_LEFT
	for seg in BAR_SEGMENTS:
		var seg_w: float = w * float(seg["width"])
		var rect := ColorRect.new()
		rect.color = seg["color"]
		rect.offset_left   = x
		rect.offset_top    = 0
		rect.offset_right  = x + seg_w
		rect.offset_bottom = BAR_HEIGHT
		_bar_segments_box.add_child(rect)
		x += seg_w
	
	# Position the bar exactly at SampleYAxis — no padding/gap.
	var bar_top := _sample_y_axis.offset_top
	_bar_bg.offset_left   = BAR_LEFT - 6.0
	_bar_bg.offset_top    = bar_top - 6.0
	_bar_bg.offset_right  = BAR_RIGHT + 6.0
	_bar_bg.offset_bottom = bar_top + BAR_HEIGHT + 6.0
	_bar_bg.color = Color(0.1, 0.08, 0.05, 1.0)  # Darker background
	
	_bar_label.offset_left = BAR_LEFT - 160.0
	_bar_label.offset_top = bar_top
	_bar_label.offset_right = BAR_LEFT
	_bar_label.offset_bottom = bar_top + BAR_HEIGHT
	
	_bar_segments_box.offset_left  = BAR_LEFT
	_bar_segments_box.offset_top   = bar_top
	_bar_segments_box.offset_right = BAR_RIGHT
	_bar_segments_box.offset_bottom= bar_top + BAR_HEIGHT


func _segment_at(progress: float) -> Dictionary:
	var x := 0.0
	for seg in BAR_SEGMENTS:
		var seg_w: float = float(seg["width"])
		if progress <= x + seg_w or seg == BAR_SEGMENTS[-1]:
			return seg
		x += seg_w
	return BAR_SEGMENTS[-1]


func _start_mashing() -> void:
	_mashing = true
	_marker_progress = 0.0
	_marker_direction = 1.0
	_bar_marker.visible = true
	_update_marker_visual()


func _update_mash_marker(delta: float) -> void:
	# Ping-pong: marker travels left→right, then right→left, repeating, so
	# the player keeps getting fresh chances to release on a good colour.
	var speed: float = MARKER_BASE_SPEED + _current_line * MARKER_SPEED_STEP
	_marker_progress += _marker_direction * speed * delta
	if _marker_progress >= 1.0:
		_marker_progress = 1.0
		_marker_direction = -1.0
	elif _marker_progress <= 0.0:
		_marker_progress = 0.0
		_marker_direction = 1.0
	_update_marker_visual()


func _update_marker_visual() -> void:
	var bar_w := BAR_RIGHT - BAR_LEFT
	var mx := BAR_LEFT + bar_w * _marker_progress
	var bar_top := _sample_y_axis.offset_top
	_bar_marker.offset_left   = mx - 2.0
	_bar_marker.offset_right  = mx + 2.0
	_bar_marker.offset_top    = bar_top - 4.0
	_bar_marker.offset_bottom = bar_top + BAR_HEIGHT + 4.0


func _cancel_mashing() -> void:
	_mashing = false
	_bar_marker.visible = false
	_marker_progress = 0.0
	_shrink_fork_instant()


func _shrink_fork_instant() -> void:
	var t := create_tween()
	t.tween_property(_fork_img, "scale", Vector2(3, 3), 0.15)


func _grow_fork(delta: float) -> void:
	var s: float = clampf(_fork_img.scale.x + GROWTH_RATE * delta, 3.0, MAX_FORK_SCALE)
	_fork_img.scale = Vector2(s, s)


# ════════════════════════════ RELEASE / SCORING ══════════════════════════

func _release_mash() -> void:
	_mashing = true  # stays true through the busy animation, cleared at end of line resolution
	_busy = true
	_mash_power_area.visible = false
	_bar_marker.visible = false

	var seg := _segment_at(_marker_progress)
	var tier: String = seg["tier"]
	var points: int = seg["points"]
	_line_scores[_current_line] = points
	_total_points += points

	var t := create_tween()
	t.tween_property(_fork_img, "scale", Vector2(BOUNCE_DIP_SCALE, BOUNCE_DIP_SCALE), 0.12)
	t.tween_callback(Callable(self, "_on_bounce_dip"))
	t.tween_property(_fork_img, "scale", Vector2(3.0, 3.0), 0.28) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_callback(Callable(self, "_on_bounce_finished").bind(tier))


func _on_bounce_dip() -> void:
	# Fork is at its smallest size here -> "impact" moment: advance eggplant frame.
	var frame_idx: int = mini(_current_line + 1, _eggplant_tex.size() - 1)
	_eggplant_img.texture = _eggplant_tex[frame_idx]
	_pop_out_circle(_circles[_current_line])


func _on_bounce_finished(tier: String) -> void:
	_mashing = false
	_show_popup(_popup_tex[tier])


func _show_popup(tex: Texture2D) -> void:
	_popup_showing = true
	_popup_img.texture = tex
	_popup.visible = true
	_popup.scale = Vector2(0.1, 0.1)

	var t := create_tween()
	t.tween_property(_popup, "scale", Vector2(1.12, 1.12), 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_popup, "scale", Vector2(1.0, 1.0), 0.10)
	t.tween_interval(1.0)
	t.tween_property(_popup, "scale", Vector2(0.1, 0.1), 0.16) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_callback(Callable(self, "_on_popup_closed"))


func _on_popup_closed() -> void:
	_popup.visible = false
	_popup_showing = false
	_busy = false
	_advance_line()


func _advance_line() -> void:
	_current_line += 1
	_refresh_gauge(float(_current_line) / float(LINE_COUNT), false)

	if _current_line >= LINE_COUNT:
		_show_final_popup()
		return

	_pop_in_circle(_circles[_current_line])


func _show_final_popup() -> void:
	_busy = true
	_show_popup_final()


func _show_popup_final() -> void:
	_popup_showing = true
	_popup_img.texture = _popup_done_tex
	_popup.visible = true
	_popup.scale = Vector2(0.1, 0.1)

	var t := create_tween()
	t.tween_property(_popup, "scale", Vector2(1.12, 1.12), 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_popup, "scale", Vector2(1.0, 1.0), 0.10)
	t.tween_interval(1.4)
	t.tween_callback(Callable(self, "_on_final_popup_closed"))


func _on_final_popup_closed() -> void:
	_game_done = true
	_finish_timer = 0.05


# ════════════════════════════ PROGRESS GAUGE ═════════════════════════════

func _refresh_gauge(fraction: float, instant: bool) -> void:
	var gauge_h := GAUGE_BOTTOM - GAUGE_TOP
	var target_top: float = GAUGE_BOTTOM - gauge_h * clampf(fraction, 0.0, 1.0)
	if instant:
		_gauge_fill.offset_top = target_top
	else:
		var t := create_tween()
		t.tween_property(_gauge_fill, "offset_top", target_top, 0.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_gauge_fill.offset_left   = GAUGE_LEFT
	_gauge_fill.offset_right  = GAUGE_RIGHT
	_gauge_fill.offset_bottom = GAUGE_BOTTOM


# ════════════════════════════ TIMER / FINISH ═════════════════════════════

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)
		if remaining < 5.0:
			_lbl_timer.add_theme_color_override("font_color", Color(1, 0.2, 0.2))


func _force_finish() -> void:
	_finish_with_score()


func _finish_with_score() -> void:
	var max_points := float(LINE_COUNT) * 50.0
	var skill: float = float(_total_points) / max_points
	var time_bonus: float = (_last_remaining / _time_limit) * 0.1
	complete_minigame(clampf(skill + time_bonus, 0.0, 1.0))
