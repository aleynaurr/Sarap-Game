extends MinigameBase

const VEGGIES = [
	["pork1", "Pork"],
	["pork2",  "Pork"],
	["pork3", "Pork"],
	["pork4", "Pork"]
]

const MOVE_SPEED       := 180.0
const CLEAN_RATE       := 0.28
const WATER_DRAIN_RATE := 0.06
const FAUCET_ANIM_SPD  := 0.12

# ── Sink movement bounds (SinkArea local coords, from SinkBasin node) ────────
# SinkBasin: left=32 top=150 right=512 bottom=513 | veggie size: 138x124
const SINK_X_MIN := 32.0
const SINK_X_MAX := 374.0   # 512 - 138
const SINK_Y_MIN := 150.0
const SINK_Y_MAX := 389.0   # 513 - 124
const VEG_W      := 138.0
const VEG_H      := 124.0

# Faucet stream zone (SinkArea local, centre of veggie must land here)
# FaucetSprite local: left=30, right=249 → stream roughly centre x=55–175, water y=200–500
const STREAM_X_MIN := 55.0
const STREAM_X_MAX := 200.0
const STREAM_Y_MIN := 200.0
const STREAM_Y_MAX := 500.0

# ── Water bar (root coords, from WaterSupplyBg: left=289 top=83 right=629 bottom=103) ──
const WATER_LEFT   := 291.0
const WATER_RIGHT  := 627.0
const WATER_TOP    := 85.0
const WATER_BOTTOM := 101.0

# ── Cleanliness bar (root coords, from CleanlinessBg: left=289 top=116 right=629 bottom=136) ──
const CLEAN_LEFT   := 291.0
const CLEAN_RIGHT  := 627.0
const CLEAN_TOP    := 118.0
const CLEAN_BOTTOM := 134.0

# ── Queue spawn positions (SinkArea local, one per veggie slot in GridContainer) ──
# Calculated from QueueArea root offset (387,289), scale=1.3, cell=48, sep=6
const QUEUE_SPAWN_POSITIONS = [
	Vector2(332, 175),
	Vector2(402, 175),
	Vector2(332, 245),
	Vector2(402, 245),
]

var _veg_idx: int        = -1
var _faucet_on: bool     = false
var _faucet_frame: int   = 0
var _faucet_timer: float = 0.0
var _cleanliness: float  = 0.0
var _water: float        = 1.0
var _veggie_pos: Vector2 = Vector2.ZERO
var _veggies_done: int   = 0
var _clean_scores: Array = [0.0, 0.0, 0.0, 0.0]
var _done: bool          = false
var _finish_timer: float = 0.0
var _flash_time: float   = 0.0   # drives the veggie pulse animation

var _faucet_tex: Array   = []
var _veggie_large: Array = []
var _bowl_tex: Array     = []

# Popup images (start / done / fail) — placeholders, replace in
# res://assets/sprites/minigames/Dish1WashMinigame/
@export var popup_start_tex: Texture2D = preload("res://assets/sprites/minigames/Dish1WashMinigame/popup_start.png")
@export var popup_done_tex:  Texture2D = preload("res://assets/sprites/minigames/Dish1WashMinigame/popup_done.png")
@export var popup_fail_tex:  Texture2D = preload("res://assets/sprites/minigames/Dish1WashMinigame/popup_fail.png")

var _end_popup_shown: bool = false

@onready var _lbl_timer:       Label       = $TimerLabel
@onready var _lbl_current:     Label       = $CurrentVegLabel
@onready var _lbl_cleanliness: Label       = $CleanlinessLabel
@onready var _lbl_perfect:     Label       = $PerfectCleanLabel
@onready var _result_label:    Label       = $ResultLabel
@onready var _veggie_img:      TextureRect = $SinkArea/VeggieOnSink
@onready var _faucet_img:      TextureRect = $SinkArea/FaucetSprite
@onready var _faucet_label:    Label       = $SinkArea/FaucetOnLabel
@onready var _water_fill:      ColorRect   = $WaterSupplyFill
@onready var _clean_fill:      ColorRect   = $CleanlinessFill
@onready var _bowl_img:        TextureRect = $BowlTexture

@onready var _start_popup:    Control     = $StartPopup
@onready var _end_popup:      Control     = $EndPopup
@onready var _end_popup_bg:   TextureRect = $EndPopup/EndPopupBg

@onready var _queue_icons: Array[TextureRect] = [
	$QueueArea/Pork1,
	$QueueArea/Pork2,
	$QueueArea/Pork3,
	$QueueArea/Pork4
]

func _ready():
	player_number = 1
	_on_init()
	
func _process(delta):
	_on_update(delta, 999.0)

func _on_init() -> void:
	_veg_idx       = -1
	_faucet_on     = false
	_faucet_frame  = 0
	_faucet_timer  = 0.0
	_cleanliness   = 0.0
	_water         = 1.0
	_veggie_pos    = Vector2.ZERO
	_veggies_done  = 0
	_done          = false
	_finish_timer  = 0.0
	_flash_time    = 0.0
	_clean_scores  = [0.0, 0.0, 0.0, 0.0]
	_end_popup_shown = false

	_result_label.visible = false
	_lbl_perfect.visible  = false
	_veggie_img.visible   = false
	_veggie_img.modulate.a = 1.0

	_end_popup.visible = false
	_end_popup.scale   = Vector2(0, 0)

	# Override time limit to 30 seconds
	_time_limit = 30.0
	_lbl_timer.text = "Time: %.1f" % _time_limit

	_lbl_current.text     = "Press E / Shift to start!"

	_faucet_tex = [
		load("res://assets/sprites/minigames/Dish1WashMinigame/faucet_off.png"),
		load("res://assets/sprites/minigames/Dish1WashMinigame/faucet_on_00.png"),
		load("res://assets/sprites/minigames/Dish1WashMinigame/faucet_on_01.png"),
		load("res://assets/sprites/minigames/Dish1WashMinigame/faucet_on_02.png"),
	]
	_veggie_large.clear()
	for veg in VEGGIES:
		_veggie_large.append(load("res://assets/assets/Dish2Assets/%s.png" % veg[0]))
	_bowl_tex.clear()
	for i in range(5):
		_bowl_tex.append(load("res://assets/assets/Dish2Assets/bowl%02d.png" % i))

	for icon in _queue_icons:
		icon.modulate = Color(1, 1, 1, 1)
		icon.visible  = true

	_faucet_img.texture = _faucet_tex[0]
	_bowl_img.texture   = _bowl_tex[0]
	_refresh_water_bar()
	_refresh_clean_bar()

	_show_start_popup()

# ─── Popups (start / done / fail) ────────────────────────────────────────────
func _show_start_popup() -> void:
	_start_popup.visible = true
	_start_popup.scale   = Vector2(0, 0)

	var tw := create_tween()
	tw.tween_property(_start_popup, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_start_popup, "scale", Vector2(1.0, 1.0), 0.1)

	var hide_tw := create_tween()
	hide_tw.tween_interval(3.0)
	hide_tw.tween_property(_start_popup, "scale", Vector2(0, 0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	hide_tw.tween_callback(func(): _start_popup.visible = false)

func _show_end_popup(success: bool) -> void:
	if _end_popup_shown:
		return
	_end_popup_shown = true
	_end_popup_bg.texture = popup_done_tex if success else popup_fail_tex
	_end_popup.visible = true
	_end_popup.scale   = Vector2(0, 0)

	var tw := create_tween()
	tw.tween_property(_end_popup, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_end_popup, "scale", Vector2(1.0, 1.0), 0.1)

func _on_update(delta: float, _remaining: float) -> void:
	if _done:
		_finish_timer -= delta
		if _finish_timer <= 0.0:
			_finish_with_score()
		return

	# Always check for next-veggie press first
	if Input.is_action_just_pressed("interact_p%d" % player_number):
		_advance_veggie()
		return

	# Only handle movement and faucet if a veggie is active
	if _veg_idx >= 0:
		_handle_movement(delta)
		_handle_faucet_toggle()
		_handle_faucet_anim(delta)

		# ── Veggie flash pulse ──────────────────────────────────────────────
		_flash_time += delta
		_veggie_img.modulate.a = 0.6 + 0.4 * sin(_flash_time * TAU * 1.5)
		# ───────────────────────────────────────────────────────────────────

		if _faucet_on:
			_drain_water(delta)
			if _is_under_stream():
				_cleanliness = minf(1.0, _cleanliness + CLEAN_RATE * delta)
				_refresh_clean_bar()
				if _cleanliness >= 1.0:
					_lbl_perfect.visible = true

	if _water <= 0.0 and not _done:
		_result_label.text    = "💧 Naubusan ng tubig!\n(Ran out of water!)"
		_result_label.visible = true
		_faucet_on            = false
		_faucet_img.texture   = _faucet_tex[0]
		_done                 = true
		_finish_timer         = 2.0
		_show_end_popup(false)

func _handle_movement(delta: float) -> void:
	var dir = Vector2.ZERO
	if player_number == 1:
		if Input.is_action_pressed("move_up_p1"):    dir.y -= 1
		if Input.is_action_pressed("move_down_p1"):  dir.y += 1
		if Input.is_action_pressed("move_left_p1"):  dir.x -= 1
		if Input.is_action_pressed("move_right_p1"): dir.x += 1
	else:
		if Input.is_action_pressed("move_up_p2"):    dir.y -= 1
		if Input.is_action_pressed("move_down_p2"):  dir.y += 1
		if Input.is_action_pressed("move_left_p2"):  dir.x -= 1
		if Input.is_action_pressed("move_right_p2"): dir.x += 1
	if dir == Vector2.ZERO: return
	_veggie_pos += dir.normalized() * MOVE_SPEED * delta
	_veggie_pos.x = clampf(_veggie_pos.x, SINK_X_MIN, SINK_X_MAX)
	_veggie_pos.y = clampf(_veggie_pos.y, SINK_Y_MIN, SINK_Y_MAX)
	_apply_veggie_pos()

func _handle_faucet_toggle() -> void:
	if Input.is_action_just_pressed("grab_p%d" % player_number):
		_faucet_on = not _faucet_on
		if not _faucet_on:
			_faucet_img.texture = _faucet_tex[0]
			_faucet_frame       = 0
			_faucet_timer       = 0.0
		var btn_text = "Q" if player_number == 1 else "÷"
		var faucet_state = "OFF" if _faucet_on else "ON"
		_faucet_label.text = "%s  →  faucet %s" % [btn_text, faucet_state]

func _handle_faucet_anim(delta: float) -> void:
	if not _faucet_on: return
	_faucet_timer += delta
	if _faucet_timer >= FAUCET_ANIM_SPD:
		_faucet_timer  -= FAUCET_ANIM_SPD
		_faucet_frame   = (_faucet_frame + 1) % 3
		_faucet_img.texture = _faucet_tex[1 + _faucet_frame]

func _advance_veggie() -> void:
	# Save score for veggie that was being washed, restore alpha before hiding
	if _veg_idx >= 0 and _veg_idx < VEGGIES.size():
		_clean_scores[_veg_idx] = _cleanliness
		_veggies_done           += 1
		_bowl_img.texture        = _bowl_tex[_veggies_done]
		_veggie_img.modulate.a   = 1.0   # restore full alpha before swapping

	_veg_idx     += 1
	_cleanliness  = 0.0
	_flash_time   = 0.0   # reset pulse for next veggie
	_lbl_perfect.visible = false

	if _veg_idx >= VEGGIES.size():
		_veggie_img.visible   = false
		_done                 = true
		_finish_timer         = 1.5
		_show_end_popup(true)
		return

	# Hide queue icon for the veggie now becoming active
	_queue_icons[_veg_idx].visible = false

	# Get the icon node currently being processed
	var active_icon = _queue_icons[_veg_idx]
	
	# This gives us the exact local offset inside the SinkArea!
	_veggie_pos = active_icon.global_position - $SinkArea.global_position
	
	_veggie_img.custom_minimum_size = Vector2(175, 175)
	
	_veggie_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_veggie_img.stretch_mode = TextureRect.STRETCH_SCALE

	# Clamp spawn into sink bounds in case grid position is outside
	_veggie_pos.x = clampf(_veggie_pos.x, SINK_X_MIN, SINK_X_MAX)
	_veggie_pos.y = clampf(_veggie_pos.y, SINK_Y_MIN, SINK_Y_MAX)

	_veggie_img.visible    = true
	_veggie_img.modulate.a = 1.0
	_veggie_img.texture    = _veggie_large[_veg_idx]
	_apply_veggie_pos()

	_lbl_current.text = "Washing: " + VEGGIES[_veg_idx][1]
	_refresh_clean_bar()

func _apply_veggie_pos() -> void:
	_veggie_img.offset_left   = _veggie_pos.x
	_veggie_img.offset_top    = _veggie_pos.y
	_veggie_img.offset_right  = _veggie_pos.x + VEG_W
	_veggie_img.offset_bottom = _veggie_pos.y + VEG_H

func _is_under_stream() -> bool:
	var cx = _veggie_pos.x + VEG_W * 0.5
	var cy = _veggie_pos.y + VEG_H * 0.5
	return cx >= STREAM_X_MIN and cx <= STREAM_X_MAX \
		and cy >= STREAM_Y_MIN and cy <= STREAM_Y_MAX

func _drain_water(delta: float) -> void:
	_water = maxf(0.0, _water - WATER_DRAIN_RATE * delta)
	_refresh_water_bar()

func _refresh_water_bar() -> void:
	var bar_w = (WATER_RIGHT - WATER_LEFT) * _water
	_water_fill.offset_left   = WATER_LEFT
	_water_fill.offset_top    = WATER_TOP
	_water_fill.offset_right  = WATER_LEFT + bar_w
	_water_fill.offset_bottom = WATER_BOTTOM
	if _water < 0.25:
		_water_fill.color = Color(0.9, 0.3, 0.2, 1)
	elif _water < 0.5:
		_water_fill.color = Color(0.9, 0.75, 0.2, 1)
	else:
		_water_fill.color = Color(0.25, 0.60, 0.95, 1)

func _refresh_clean_bar() -> void:
	var bar_w = (CLEAN_RIGHT - CLEAN_LEFT) * _cleanliness
	_clean_fill.offset_left   = CLEAN_LEFT
	_clean_fill.offset_top    = CLEAN_TOP
	_clean_fill.offset_right  = CLEAN_LEFT + bar_w
	_clean_fill.offset_bottom = CLEAN_BOTTOM
	_lbl_cleanliness.text = "Cleanliness: %d%%" % int(_cleanliness * 100)
	_clean_fill.color = Color(0.1, 0.9, 0.3, 1) if _cleanliness >= 1.0 else Color(0.3, 0.85, 0.4, 1)

func _finish_with_score() -> void:
	if _veg_idx >= 0 and _veg_idx < VEGGIES.size():
		_clean_scores[_veg_idx] = _cleanliness
	var total = 0.0
	for s in _clean_scores:
		total += s
	var skill       = total / float(VEGGIES.size())
	var water_bonus = _water * 0.15
	complete_minigame(clampf(skill + water_bonus, 0.0, 1.0))

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)
		if remaining < 5.0:
			_lbl_timer.add_theme_color_override("font_color", Color(1, 0.2, 0.2))

func _force_finish() -> void:
	if _done:
		return
	# Time ran out before all veggies were washed — show fail popup, then finish.
	_faucet_on             = false
	_faucet_img.texture    = _faucet_tex[0]
	_done                  = true
	_finish_timer          = 1.6
	_show_end_popup(false)
