extends MinigameBase

enum State { COVER, FILL_RICE, FILL_WATER, ARROW_DOWN, PRE_COOK, COOKING, DONE }

const ASSET_DIR := "res://assets/sprites/minigames/Dish1CookRiceMinigame/"

# --- Exported Inspector Properties ---
@export var move_speed: float = 220.0

# Timer settings (added 30s each)
@export var time_1_cup: float = 80.0
@export var time_2_cups: float = 100.0
@export var time_3_cups: float = 115.0
@export var time_4_cups: float = 120.0
@export var cook_time: float = 25.0

# Rice cooker
@export var cooker_pos: Vector2 = Vector2(9, 108)
@export var cooker_size: Vector2 = Vector2(382, 429.41455)

# Cup
@export var cup_home: Vector2 = Vector2(341, 482)
@export var cup_size: Vector2 = Vector2(60, 90)

# Ingredients
@export var sack_pos: Vector2 = Vector2(399, 101)
@export var pail_pos: Vector2 = Vector2(399, 331)
@export var ingredient_size: Vector2 = Vector2(140, 140)

# Arrow
@export var arrow_pos: Vector2 = Vector2(159, 166)
@export var arrow_size: Vector2 = Vector2(80, 100)

# Hand
@export var hand_size: Vector2 = Vector2(56, 56)
@export var hand_start: Vector2 = Vector2(300, 470)
@export var hand_move_min: Vector2 = Vector2(0, 0)
@export var hand_move_max: Vector2 = Vector2(584, 664)

# Cooking meter
@export var meter_left: float = 40.0
@export var meter_right: float = 400.0
@export var meter_y: float = 590.0
@export var meter_h: float = 22.0
@export var zone_half_yellow: float = 45.0
@export var zone_half_green: float = 16.0
@export var green_rate: float = 1.0
@export var yellow_rate: float = 0.45

# Zone movement settings (slower!)
@export var zone_min_speed: float = 15.0
@export var zone_max_speed: float = 40.0
@export var zone_retime_min: float = 2.0
@export var zone_retime_max: float = 4.0

# Popup images
@export var popup_start: Texture2D = preload("res://assets/sprites/minigames/Dish1CookRiceMinigame/popup_start.png")
@export var popup_startaddingrice: Texture2D = preload("res://assets/sprites/minigames/Dish1CookRiceMinigame/popup_startaddingrice.png")
@export var popup_startaddingwater: Texture2D = preload("res://assets/sprites/minigames/Dish1CookRiceMinigame/popup_startaddingwater.png")
@export var popup_addingrice_1: Texture2D = preload("res://assets/sprites/minigames/Dish1CookRiceMinigame/popup_addingrice_1.png")
@export var popup_addingrice_2: Texture2D = preload("res://assets/sprites/minigames/Dish1CookRiceMinigame/popup_addingrice_2.png")
@export var popup_addingrice_3: Texture2D = preload("res://assets/sprites/minigames/Dish1CookRiceMinigame/popup_addingrice_3.png")
@export var popup_addingrice_4: Texture2D = preload("res://assets/sprites/minigames/Dish1CookRiceMinigame/popup_addingrice_4.png")
@export var popup_rice_added: Texture2D = preload("res://assets/sprites/minigames/Dish1CookRiceMinigame/popup_rice_added.png")
@export var popup_all_rice: Texture2D = preload("res://assets/sprites/minigames/Dish1CookRiceMinigame/popup_all_rice.png")
@export var popup_water_added: Texture2D = preload("res://assets/sprites/minigames/Dish1CookRiceMinigame/popup_water_added.png")
@export var popup_all_water: Texture2D = preload("res://assets/sprites/minigames/Dish1CookRiceMinigame/popup_all_water.png")
@export var popup_cooking: Texture2D = preload("res://assets/sprites/minigames/Dish1CookRiceMinigame/popup_cooking.png")
@export var popup_done: Texture2D = preload("res://assets/sprites/minigames/Dish1CookRiceMinigame/popup_done.png")
@export var popup_fail: Texture2D = preload("res://assets/sprites/minigames/Dish1CookRiceMinigame/popup_fail.png")
@export var cookfeedback_awesome: Texture2D = preload("res://assets/sprites/minigames/Dish1CookRiceMinigame/cookfeedback_awesome.png")
@export var cookfeedback_great: Texture2D = preload("res://assets/sprites/minigames/Dish1CookRiceMinigame/cookfeedback_great.png")
@export var cookfeedback_timebetter: Texture2D = preload("res://assets/sprites/minigames/Dish1CookRiceMinigame/cookfeedback_timebetter.png")

var _state: int = State.COVER

var _hand_pos: Vector2
var _cup_pos: Vector2
var _cup_content: String = "empty"

var _target_rice: int = 2
var _target_water: int = 4
var _rice_added: int = 0
var _water_added: int = 0

var _qte_active: bool = false
var _qte_start_y: float = 0.0

var _overall_remaining: float = 0.0
var _cook_timer: float = 0.0

var _zone_center: float = 0.0
var _zone_dir: float = 1.0
var _zone_speed: float = 70.0
var _zone_retime: float = 0.0
var _marker_pos: float = 0.0
var _cook_score_accum: float = 0.0
var _cook_score_max: float = 0.0

var _popup_queue: Array = []
var _popup_busy: bool = false

var _done: bool = false
var _finish_timer: float = 0.0
var _final_score: float = 0.0

var _arrow_bob_time: float = 0.0
var _cook_feedback_mode: String = "timebetter"
var _cook_feedback_tween: Tween

@onready var _lbl_timer: Label = $TimerLabel
@onready var _lbl_cook_timer: Label = $CookTimerLabel

@onready var _hand_img: TextureRect = $HandSprite
@onready var _cooker_img: TextureRect = $RiceCookerSprite
@onready var _cup_img: TextureRect = $CupSprite
@onready var _sack_img: TextureRect = $SackRice
@onready var _pail_img: TextureRect = $PailWater
@onready var _arrow_img: TextureRect = $ArrowSprite

@onready var _popup_box: Control = $PopupBox
@onready var _popup_bg: TextureRect = $PopupBox/PopupBg
@onready var _popup_lbl: Label = $PopupBox/PopupLabel
@onready var _start_popup: Control = $StartPopup

@onready var _meter_track: ColorRect = $CookingMeter/Track
@onready var _meter_yellow: ColorRect = $CookingMeter/ZoneYellow
@onready var _meter_green: ColorRect = $CookingMeter/ZoneGreen
@onready var _meter_white_left: ColorRect = $CookingMeter/ZoneWhiteLeft
@onready var _meter_white_right: ColorRect = $CookingMeter/ZoneWhiteRight
@onready var _meter_marker: ColorRect = $CookingMeter/MarkerCircle
@onready var _meter_marker_inner: ColorRect = $CookingMeter/MarkerInner
@onready var _meter_group: Control = $CookingMeter

@onready var _cook_feedback: Control = $CookFeedback
@onready var _cook_feedback_awesome: TextureRect = $CookFeedback/CookFeedbackAwesome
@onready var _cook_feedback_great: TextureRect = $CookFeedback/CookFeedbackGreat
@onready var _cook_feedback_timebetter: TextureRect = $CookFeedback/CookFeedbackTimeBetter

var _tex := {}

func _load_tex() -> void:
	_tex["closed"] = load(ASSET_DIR + "ricecooker_closed.png")
	for n in range(5):
		_tex["open_%d" % n] = load(ASSET_DIR + "ricecooker_open_%d.png" % n)
	for n in range(1, 5):
		_tex["water_%d" % n] = load(ASSET_DIR + "ricecooker_water_%d.png" % n)
	_tex["cooking"] = load(ASSET_DIR + "ricecooker_cooking.png")
	_tex["hand_point"] = load(ASSET_DIR + "hand_point.png")
	_tex["hand_pinch"] = load(ASSET_DIR + "hand_pinch.png")
	_tex["cup_empty"] = load(ASSET_DIR + "cup_empty.png")
	_tex["cup_rice"] = load(ASSET_DIR + "cup_rice.png")
	_tex["cup_water"] = load(ASSET_DIR + "cup_water.png")
	_tex["sack"] = load(ASSET_DIR + "sack_rice.png")
	_tex["pail"] = load(ASSET_DIR + "pail_water.png")
	_tex["arrow_up"] = load(ASSET_DIR + "arrow_up.png")
	_tex["arrow_down"] = load(ASSET_DIR + "arrow_down.png")
	_tex["popup_bg"] = load(ASSET_DIR + "popup_bg.png")

func _is_grab_pressed() -> bool:
	return Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_SLASH)

func _on_init() -> void:
	_load_tex()

	_state = State.COVER
	_hand_pos = hand_start
	_cup_pos = cup_home
	_cup_content = "empty"
	_rice_added = 0
	_water_added = 0
	_qte_active = false
	_popup_queue.clear()
	_popup_busy = false
	_done = false
	_finish_timer = 0.0
	_final_score = 0.0
	_arrow_bob_time = 0.0
	_cook_feedback_mode = "timebetter"

	randomize()
	_target_rice = randi_range(1, 4)
	_target_water = _target_rice * 2

	# Set overall time based on rice cups
	match _target_rice:
		1: _overall_remaining = time_1_cup
		2: _overall_remaining = time_2_cups
		3: _overall_remaining = time_3_cups
		4: _overall_remaining = time_4_cups

	_cook_timer = cook_time

	# _time_limit is MinigameBase's own hard safety-net timer
	_time_limit = _overall_remaining + cook_time + 15.0
	_lbl_timer.text = "Time: %.1f" % _overall_remaining

	_cooker_img.texture = _tex["closed"]
	_hand_img.texture = _tex["hand_point"]
	_cup_img.texture = _tex["cup_empty"]
	_sack_img.texture = _tex["sack"]
	_pail_img.texture = _tex["pail"]
	_arrow_img.texture = _tex["arrow_up"]
	_arrow_img.visible = false
	_arrow_img.scale = Vector2(0, 0)

	_popup_bg.texture = _tex["popup_bg"]
	_popup_box.visible = false
	_popup_box.scale = Vector2(0, 0)
	_popup_lbl.text = ""

	_start_popup.visible = true
	_start_popup.scale = Vector2(0, 0)

	_meter_group.visible = false
	_cook_feedback.visible = false
	_cook_feedback.scale = Vector2(0,0)
	_hand_img.visible = true

	_apply_hand_pos()
	_apply_cup_pos()
	_lbl_cook_timer.text = ""

	# Animate start popup IN
	var tw := create_tween()
	tw.tween_property(_start_popup, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_start_popup, "scale", Vector2(1.0, 1.0), 0.1)

	# Auto-hide after 3 seconds
	var hide_tw := create_tween()
	hide_tw.tween_interval(3.0)
	hide_tw.tween_property(_start_popup, "scale", Vector2(0, 0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	hide_tw.tween_callback(func(): 
		_start_popup.visible = false
		_show_arrow_up()
	)

func _show_arrow_up() -> void:
	_arrow_img.texture = _tex["arrow_up"]
	_arrow_img.visible = true
	_arrow_img.scale = Vector2(0,0)
	var tw := create_tween()
	tw.tween_property(_arrow_img, "scale", Vector2(1.3, 1.3), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_arrow_img, "scale", Vector2(1.0, 1.0), 0.1)

func _hide_arrow() -> void:
	var tw := create_tween()
	tw.tween_property(_arrow_img, "scale", Vector2(0, 0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): _arrow_img.visible = false)

func _show_arrow_down() -> void:
	_arrow_img.texture = _tex["arrow_down"]
	_arrow_img.visible = true
	_arrow_img.scale = Vector2(0,0)
	var tw := create_tween()
	tw.tween_property(_arrow_img, "scale", Vector2(1.3, 1.3), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_arrow_img, "scale", Vector2(1.0, 1.0), 0.1)

func _hide_cup() -> void:
	var tw := create_tween()
	tw.tween_property(_cup_img, "scale", Vector2(0, 0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): _cup_img.visible = false)

func _pop_animation() -> void:
	var tw1 := create_tween()
	tw1.tween_property(_cup_img, "scale", Vector2(1.25, 1.25), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var tw2 := create_tween()
	tw2.tween_property(_hand_img, "scale", Vector2(1.25, 1.25), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var tw3 := create_tween()
	tw3.tween_property(_cup_img, "scale", Vector2(1.0, 1.0), 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	var tw4 := create_tween()
	tw4.tween_property(_hand_img, "scale", Vector2(1.0, 1.0), 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

func _on_update(delta: float, _remaining: float) -> void:
	if _done:
		_finish_timer -= delta
		if _finish_timer <= 0.0:
			complete_minigame(_final_score)
		return

	# Always update overall timer, even during cooking!
	_overall_remaining = maxf(0.0, _overall_remaining - delta)
	_lbl_timer.text = "Time: %.1f" % _overall_remaining
	if _overall_remaining <= 0.0:
		_fail_out_of_time()
		return

	if _arrow_img.visible:
		_arrow_bob_time += delta
		var bob = sin(_arrow_bob_time * 4.0) * 5.0
		_arrow_img.offset_top = arrow_pos.y + bob

	# Always update hand texture based on grab
	_hand_img.texture = _tex["hand_pinch"] if _is_grab_pressed() else _tex["hand_point"]

	match _state:
		State.COVER:
			_update_hand(delta)
			_update_cover_qte(delta)
		State.FILL_RICE, State.FILL_WATER:
			_update_hand(delta)
			_update_cup_drag(delta)
		State.ARROW_DOWN:
			_update_hand(delta)
			_update_arrow_down_qte(delta)
		State.PRE_COOK:
			pass
		State.COOKING:
			_update_cooking(delta)

func _update_hand(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("move_up"): dir.y -= 1
	if Input.is_action_pressed("move_down"): dir.y += 1
	if Input.is_action_pressed("move_left"): dir.x -= 1
	if Input.is_action_pressed("move_right"): dir.x += 1
	if dir != Vector2.ZERO:
		_hand_pos += dir.normalized() * move_speed * delta
		_hand_pos.x = clampf(_hand_pos.x, hand_move_min.x, hand_move_max.x)
		_hand_pos.y = clampf(_hand_pos.y, hand_move_min.y, hand_move_max.y)
		_apply_hand_pos()

func _apply_hand_pos() -> void:
	_hand_img.offset_left = _hand_pos.x
	_hand_img.offset_top = _hand_pos.y
	_hand_img.offset_right = _hand_pos.x + hand_size.x
	_hand_img.offset_bottom = _hand_pos.y + hand_size.y

func _apply_cup_pos() -> void:
	_cup_img.offset_left = _cup_pos.x
	_cup_img.offset_top = _cup_pos.y
	_cup_img.offset_right = _cup_pos.x + cup_size.x
	_cup_img.offset_bottom = _cup_pos.y + cup_size.y

func _rect_overlap(pos_a: Vector2, size_a: Vector2, pos_b: Vector2, size_b: Vector2) -> bool:
	return pos_a.x < pos_b.x + size_b.x and pos_a.x + size_a.x > pos_b.x \
		and pos_a.y < pos_b.y + size_b.y and pos_a.y + size_a.y > pos_b.y

func _hand_over_cooker() -> bool:
	return _rect_overlap(_hand_pos, hand_size, cooker_pos, cooker_size)

func _hand_over_cup() -> bool:
	return _rect_overlap(_hand_pos, hand_size, _cup_pos, cup_size)

func _cup_over_cooker() -> bool:
	return _rect_overlap(_cup_pos, cup_size, cooker_pos, cooker_size)

func _cup_over_sack() -> bool:
	return _rect_overlap(_cup_pos, cup_size, sack_pos, ingredient_size)

func _cup_over_pail() -> bool:
	return _rect_overlap(_cup_pos, cup_size, pail_pos, ingredient_size)

func _update_cover_qte(delta: float) -> void:
	var hovering := _hand_over_cooker()
	_cooker_img.modulate = Color(1.25, 1.25, 1.15) if hovering else Color(1, 1, 1)

	var grab := _is_grab_pressed()

	if not _qte_active:
		if hovering and grab:
			if _start_popup.visible:
				var tw := create_tween()
				tw.tween_property(_start_popup, "scale", Vector2(0, 0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
				tw.tween_callback(func(): _start_popup.visible = false)
			_qte_active = true
			_qte_start_y = _hand_pos.y
		return

	if not grab:
		_qte_active = false
		return

	var traveled := _qte_start_y - _hand_pos.y
	if traveled >= arrow_size.y:
		_qte_active = false
		_hide_arrow()
		_cooker_img.texture = _tex["open_0"]
		_target_water = _target_rice * 2
		
		# Queue the correct adding rice popup based on _target_rice
		var adding_rice_tex: Texture2D
		match _target_rice:
			1: adding_rice_tex = popup_addingrice_1
			2: adding_rice_tex = popup_addingrice_2
			3: adding_rice_tex = popup_addingrice_3
			4: adding_rice_tex = popup_addingrice_4
		
		_queue_popup_then("startaddingrice", popup_startaddingrice, func():
			_queue_popup("addingrice", adding_rice_tex)
		)
		_state = State.FILL_RICE

func _update_cup_drag(delta: float) -> void:
	var grab := _is_grab_pressed()
	var carrying := grab and _hand_over_cup()

	if carrying:
		_cup_pos = _hand_pos
		_apply_cup_pos()
		if _state == State.FILL_RICE and _cup_over_sack() and _cup_content != "rice":
			_cup_content = "rice"
			_cup_img.texture = _tex["cup_rice"]
			_pop_animation()
		elif _state == State.FILL_WATER and _cup_over_pail() and _cup_content != "water":
			_cup_content = "water"
			_cup_img.texture = _tex["cup_water"]
			_pop_animation()

	if not grab and _cup_content != "empty":
		if _cup_over_cooker():
			if _state == State.FILL_RICE and _cup_content == "rice":
				_rice_added += 1
				_cooker_img.texture = _tex["open_%d" % _rice_added]
				_cup_content = "empty"
				_cup_img.texture = _tex["cup_empty"]
				if _rice_added >= _target_rice:
					# Don't switch to water yet! Wait for first water added.
					_queue_popup("all_rice", popup_all_rice)
					_state = State.FILL_WATER
					_queue_popup("startaddingwater", popup_startaddingwater)
				else:
					_queue_popup("rice_added", popup_rice_added)
			elif _state == State.FILL_WATER and _cup_content == "water":
				_water_added += 1
				if _water_added == 1:
					# Now switch to water ricecooker sprite!
					_cooker_img.texture = _tex["water_%d" % _target_rice]
				_cup_content = "empty"
				_cup_img.texture = _tex["cup_empty"]
				if _water_added >= _target_water:
					_queue_popup_then("all_water", popup_all_water, func(): 
						_hide_cup()
						_start_arrow_down()
					)
				else:
					_queue_popup("water_added", popup_water_added)

func _start_arrow_down() -> void:
	_state = State.ARROW_DOWN
	_show_arrow_down()

func _update_arrow_down_qte(delta: float) -> void:
	var hovering := _hand_over_cooker()
	_cooker_img.modulate = Color(1.25, 1.25, 1.15) if hovering else Color(1, 1, 1)
	var grab := _is_grab_pressed()

	if not _qte_active:
		if hovering and grab:
			_qte_active = true
			_qte_start_y = _hand_pos.y
		return

	if not grab:
		_qte_active = false
		return

	var traveled := _hand_pos.y - _qte_start_y
	if traveled >= arrow_size.y:
		_qte_active = false
		_hide_arrow()
		_cooker_img.texture = _tex["closed"]
		_cooker_img.modulate = Color(1,1,1)
		_queue_popup_then("cooking", popup_cooking, func(): _start_cooking())

func _start_cooking() -> void:
	_state = State.PRE_COOK
	_hand_img.visible = false
	_meter_group.visible = true
	_cook_feedback.visible = true
	var track_w = meter_right - meter_left
	_zone_center = track_w / 2.0
	_zone_dir = 1.0
	_zone_speed = (zone_min_speed + zone_max_speed) / 2.0
	_zone_retime = 2.0
	_marker_pos = _zone_center
	_cook_score_accum = 0.0
	_cook_score_max = 0.0
	_cook_timer = cook_time
	_cooker_img.texture = _tex["cooking"]
	_state = State.COOKING

func _update_cooking(delta: float) -> void:
	_cook_timer = maxf(0.0, _cook_timer - delta)
	_lbl_cook_timer.text = "%02d:%02d" % [int(_cook_timer) / 60, int(_cook_timer) % 60]

	_zone_retime -= delta
	if _zone_retime <= 0.0:
		_zone_retime = randf_range(zone_retime_min, zone_retime_max)
		if randf() < 0.5:
			_zone_dir *= -1.0
		_zone_speed = randf_range(zone_min_speed, zone_max_speed)
	_zone_center += _zone_dir * _zone_speed * delta
	var track_w := meter_right - meter_left
	if _zone_center < zone_half_yellow:
		_zone_center = zone_half_yellow
		_zone_dir = 1.0
	elif _zone_center > track_w - zone_half_yellow:
		_zone_center = track_w - zone_half_yellow
		_zone_dir = -1.0

	var mdir := 0.0
	if Input.is_action_pressed("move_left"): mdir -= 1.0
	if Input.is_action_pressed("move_right"): mdir += 1.0
	_marker_pos = clampf(_marker_pos + mdir * move_speed * delta, 0.0, track_w)

	_cook_score_max += green_rate * delta
	var dist := absf(_marker_pos - _zone_center)
	var new_mode = "timebetter"
	if dist <= zone_half_green:
		_cook_score_accum += green_rate * delta
		new_mode = "awesome"
	elif dist <= zone_half_yellow:
		_cook_score_accum += yellow_rate * delta
		new_mode = "great"
	else:
		new_mode = "timebetter"

	if new_mode != _cook_feedback_mode:
		_set_cook_feedback(new_mode)

	_refresh_meter_visual(track_w)

	if _cook_timer <= 0.0:
		var ratio := 0.0
		if _cook_score_max > 0.0:
			ratio = clampf(_cook_score_accum / _cook_score_max, 0.0, 1.0)
		_final_score = clampf(0.3 + 0.7 * ratio, 0.0, 1.0)
		_state = State.DONE
		_meter_group.visible = false
		_cook_feedback.visible = false
		_queue_popup("done", popup_done)
		_done = true
		_finish_timer = 1.6

func _set_cook_feedback(mode: String) -> void:
	_cook_feedback_mode = mode
	# Pop out old
	var tween_out := create_tween()
	tween_out.tween_property(_cook_feedback, "scale", Vector2(0,0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween_out.tween_callback(func():
		_cook_feedback_awesome.visible = (mode == "awesome")
		_cook_feedback_great.visible = (mode == "great")
		_cook_feedback_timebetter.visible = (mode == "timebetter")
		# Pop in new
		var tween_in := create_tween()
		tween_in.tween_property(_cook_feedback, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_in.tween_property(_cook_feedback, "scale", Vector2(1.0, 1.0), 0.1)
	)

func _refresh_meter_visual(track_w: float) -> void:
	_meter_yellow.offset_left = meter_left + _zone_center - zone_half_yellow
	_meter_yellow.offset_right = meter_left + _zone_center + zone_half_yellow
	_meter_yellow.offset_top = meter_y
	_meter_yellow.offset_bottom = meter_y + meter_h

	_meter_green.offset_left = meter_left + _zone_center - zone_half_green
	_meter_green.offset_right = meter_left + _zone_center + zone_half_green
	_meter_green.offset_top = meter_y
	_meter_green.offset_bottom = meter_y + meter_h

	_meter_white_left.offset_left = meter_left
	_meter_white_left.offset_right = meter_left + _zone_center - zone_half_yellow
	_meter_white_left.offset_top = meter_y
	_meter_white_left.offset_bottom = meter_y + meter_h

	_meter_white_right.offset_left = meter_left + _zone_center + zone_half_yellow
	_meter_white_right.offset_right = meter_right
	_meter_white_right.offset_top = meter_y
	_meter_white_right.offset_bottom = meter_y + meter_h

	var mx := meter_left + _marker_pos
	var circle_radius = meter_h / 2.0
	_meter_marker.offset_left = mx - circle_radius
	_meter_marker.offset_right = mx + circle_radius
	_meter_marker.offset_top = meter_y
	_meter_marker.offset_bottom = meter_y + meter_h

	var inner_radius = circle_radius - 2.0
	_meter_marker_inner.offset_left = mx - inner_radius
	_meter_marker_inner.offset_right = mx + inner_radius
	_meter_marker_inner.offset_top = meter_y + 2.0
	_meter_marker_inner.offset_bottom = meter_y + meter_h - 2.0

	var dist := absf(_marker_pos - _zone_center)
	if dist <= zone_half_green:
		_meter_marker_inner.color = Color(0.25, 0.8, 0.3, 1.0)
	elif dist <= zone_half_yellow:
		_meter_marker_inner.color = Color(0.95, 0.82, 0.2, 1.0)
	else:
		_meter_marker_inner.color = Color(0.85, 0.15, 0.1, 1.0)

func _queue_popup(type: String, tex: Texture2D) -> void:
	_popup_queue.append({"type": type, "tex": tex, "cb": Callable()})
	_process_popup_queue()

func _queue_popup_then(type: String, tex: Texture2D, cb: Callable) -> void:
	_popup_queue.append({"type": type, "tex": tex, "cb": cb})
	_process_popup_queue()

func _process_popup_queue() -> void:
	if _popup_busy or _popup_queue.is_empty():
		return
	_popup_busy = true
	var item = _popup_queue.pop_front()
	_show_popup(item.type, item.tex, item.cb)

func _show_popup(type: String, tex: Texture2D, cb: Callable) -> void:
	if tex:
		_popup_bg.texture = tex
	else:
		_popup_bg.texture = _tex["popup_bg"]
	_popup_lbl.text = ""
	_popup_box.visible = true
	_popup_box.scale = Vector2(0, 0)
	var tw := create_tween()
	tw.tween_property(_popup_box, "scale", Vector2(1.25, 1.25), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_popup_box, "scale", Vector2(1.15, 1.15), 0.1)
	tw.tween_interval(1.5)
	tw.tween_property(_popup_box, "scale", Vector2(0.0, 0.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		_popup_box.visible = false
		_popup_busy = false
		if cb.is_valid():
			cb.call()
		_process_popup_queue())

func _fail_out_of_time() -> void:
	var progress := float(_rice_added + _water_added) / float(max(1, _target_rice + _target_water))
	_final_score = clampf(progress * 0.5, 0.0, 1.0)
	_state = State.DONE
	_meter_group.visible = false
	_arrow_img.visible = false
	_cook_feedback.visible = false
	_queue_popup("fail", popup_fail)
	_done = true
	_finish_timer = 1.6

func _update_timer_display(remaining: float) -> void:
	pass

func _force_finish() -> void:
	if _done:
		complete_minigame(_final_score)
		return
	_fail_out_of_time()
	complete_minigame(_final_score)
