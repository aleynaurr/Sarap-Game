extends MinigameBase

enum State {
	FILL_WATER, ADD_KADYOS, BOILING, DONE
}

var _state: State = State.FILL_WATER

@export var move_speed: float = 400.0 

@export var pot_pos: Vector2 = Vector2(100, 100)
@export var pot_size: Vector2 = Vector2(200, 200)

@export var water_source_pos: Vector2 = Vector2(400, 100)
@export var water_source_size: Vector2 = Vector2(120, 120)

@export var cup_home: Vector2 = Vector2(300, 500)
@export var cup_size: Vector2 = Vector2(60, 80)

@export var hand_size: Vector2 = Vector2(56, 56)

# Kadyos tracking variables
var kadyos_home := Vector2.ZERO
var kadyos_size := Vector2.ZERO
var _kadyos_pos := Vector2.ZERO
var _holding_kadyos := false
var _kadyos_grab_offset := Vector2.ZERO

var _hand_pos := Vector2.ZERO
var _cup_pos := Vector2.ZERO
var _holding_cup := false
var _cup_grab_offset := Vector2.ZERO

var _cup_content := "empty"
var _water_added: int = 0
const MAX_WATER := 6

# --- Boiling Balancing Meter Properties ---
@export var boil_time: float = 15.0
var _boil_timer: float = 0.0

# Independent tuning parameters for smooth boil simulation
@export var boil_drift_strength: float = 80.0    # Lower this if it drifts too fast
@export var boil_shift_smoothness: float = 4.0   # Lower = softer/lazier direction shifts

var meter_left: float = 120.0
var meter_right: float = 520.0
var meter_y: float = 600.0
var meter_h: float = 20.0

var zone_half_yellow: float = 50.0
var zone_half_green: float = 20.0

var _zone_center: float = 0.0
var _marker_pos: float = 0.0

# Drift physics processing states
var _target_drift_speed: float = 0.0
var _auto_drift_speed: float = 0.0
var _player_input_velocity: float = 0.0

@onready var _kadyos_img: TextureRect = $kadyos
@onready var _wtkadyos_img: TextureRect = $withkadyos
@onready var _threecups_img: TextureRect = $threecups
@onready var _sixcups_img: TextureRect = $sixcups
@onready var _hand_img: TextureRect = $HandSprite
@onready var _handclose_img: TextureRect = $HandPinch
@onready var _cup_img: TextureRect = $CupSprite
@onready var _cupwtwater_img: TextureRect = $CupwithWater
@onready var _pailwater_img: TextureRect = $PailWater

# --- Onready Nodes for your UI Meter Layout ---
@onready var _meter_group: Control = $CookingMeter
@onready var _meter_yellow: ColorRect = $CookingMeter/ZoneYellow
@onready var _meter_green: ColorRect = $CookingMeter/ZoneGreen
@onready var _meter_white_left: ColorRect = $CookingMeter/ZoneWhiteLeft
@onready var _meter_white_right: ColorRect = $CookingMeter/ZoneWhiteRight
@onready var _meter_marker: ColorRect = $CookingMeter/MarkerCircle

func _ready() -> void:
	_state = State.FILL_WATER
	_water_added = 0
	_cup_content = "empty"
	_holding_cup = false
	_holding_kadyos = false
	
	_time_limit = 90.0 
	
	_hand_img.visible = true
	_handclose_img.visible = false
	
	_hand_pos = Vector2(_hand_img.offset_left, _hand_img.offset_top)
	_cup_pos = Vector2(_cup_img.offset_left, _cup_img.offset_top)
	cup_home = _cup_pos 

	_sixcups_img.visible = false
	_threecups_img.visible = false
	_pailwater_img.visible = true
	_wtkadyos_img.visible = false
	
	kadyos_home = Vector2(_kadyos_img.offset_left, _kadyos_img.offset_top)
	kadyos_size = Vector2(_kadyos_img.offset_right - _kadyos_img.offset_left, _kadyos_img.offset_bottom - _kadyos_img.offset_top)
	_kadyos_pos = kadyos_home
	_kadyos_img.visible = false 
	
	_cup_img.visible = true
	_cupwtwater_img.visible = false
	
	_meter_group.visible = false

	_apply_hand_pos()
	_apply_cup_pos()
	
func _on_update(delta: float, remaining: float) -> void:
	if _state != State.BOILING:
		_update_hand(delta)
	
	match _state:
		State.FILL_WATER:
			_update_cup_drag()
		State.ADD_KADYOS:
			_update_kadyos_drag()
		State.BOILING:
			_update_boiling_balance(delta)

func _update_hand(delta: float) -> void:
	var grab := Input.is_action_pressed("grab_p%d" % player_number)

	if grab:
		_hand_img.visible = false
		_handclose_img.visible = true
	else:
		_hand_img.visible = false if (_holding_cup or _holding_kadyos) else true
		_handclose_img.visible = true if (_holding_cup or _holding_kadyos) else false
	
	var dir := Vector2.ZERO
	if player_number == 1:
		if Input.is_action_pressed("move_up_p1"): dir.y -= 1
		if Input.is_action_pressed("move_down_p1"): dir.y += 1
		if Input.is_action_pressed("move_left_p1"): dir.x -= 1
		if Input.is_action_pressed("move_right_p1"): dir.x += 1
	else:
		if Input.is_action_pressed("move_up_p2"): dir.y -= 1
		if Input.is_action_pressed("move_down_p2"): dir.y += 1
		if Input.is_action_pressed("move_left_p2"): dir.x -= 1
		if Input.is_action_pressed("move_right_p2"): dir.x += 1

	if dir != Vector2.ZERO:
		_hand_pos += dir.normalized() * move_speed * delta

	_hand_pos.x = clamp(_hand_pos.x, 0, 640 - hand_size.x)
	_hand_pos.y = clamp(_hand_pos.y, 0, 720 - hand_size.y)
	_apply_hand_pos()

func _update_cup_drag():
	var grab := Input.is_action_pressed("grab_p%d" % player_number)

	if grab and not _holding_cup:
		if _hand_over_cup():
			_holding_cup = true
			_cup_pos = _hand_pos + (hand_size / 2.0) - (cup_size / 2.0) + Vector2(0, 30)
			_cup_grab_offset = _cup_pos - _hand_pos
			
			_cup_img.move_to_front()
			_cupwtwater_img.move_to_front()
			_hand_img.move_to_front()
			_handclose_img.move_to_front()

	if _holding_cup and grab:
		_cup_pos = _hand_pos + _cup_grab_offset
		_apply_cup_pos()

		if _cup_over_water() and _cup_content == "empty":
			_cup_content = "water"
			_cup_img.visible = false
			_cupwtwater_img.visible = true

	elif _holding_cup and not grab:
		_holding_cup = false

		if _cup_over_pot() and _cup_content == "water":
			_water_added += 1

			if _water_added >= 6:
				if _threecups_img.visible: _threecups_img.visible = false
				if !_sixcups_img.visible: _sixcups_img.visible = true
			elif _water_added >= 3:
				if !_threecups_img.visible: _threecups_img.visible = true
				if _sixcups_img.visible: _sixcups_img.visible = false
			else:
				if _threecups_img.visible: _threecups_img.visible = false
				if _sixcups_img.visible: _sixcups_img.visible = false

			_cup_content = "empty"
			
		_cup_img.visible = true
		_cupwtwater_img.visible = false
		_cup_pos = cup_home
		_apply_cup_pos()

		if _water_added >= MAX_WATER:
			_switch_to_kadyos_phase()

func _switch_to_kadyos_phase():
	_cup_img.visible = false
	_cupwtwater_img.visible = false
	_pailwater_img.visible = false
	
	_kadyos_pos = kadyos_home
	_apply_kadyos_pos()
	
	_kadyos_img.visible = true
	
	_kadyos_img.move_to_front()
	_hand_img.move_to_front()
	_handclose_img.move_to_front()
	
	_state = State.ADD_KADYOS

func _update_kadyos_drag():
	var grab := Input.is_action_pressed("grab_p%d" % player_number)

	if grab and not _holding_kadyos:
		if _hand_over_kadyos():
			_holding_kadyos = true
			_kadyos_pos = _hand_pos + (hand_size / 2.0) - (kadyos_size / 2.0) + Vector2(0, 25)
			_kadyos_grab_offset = _kadyos_pos - _hand_pos
			
			_kadyos_img.move_to_front()
			_hand_img.move_to_front()
			_handclose_img.move_to_front()

	if _holding_kadyos and grab:
		_kadyos_pos = _hand_pos + _kadyos_grab_offset
		_apply_kadyos_pos()

	elif _holding_kadyos and not grab:
		_holding_kadyos = false
		
		if _kadyos_over_pot():
			_kadyos_img.visible = false
			_sixcups_img.visible = false
			_wtkadyos_img.visible = true
			
			_start_boiling_phase()
		else:
			_kadyos_pos = kadyos_home
			_apply_kadyos_pos()

func _start_boiling_phase():
	_hand_img.visible = false
	_handclose_img.visible = false
	
	_meter_group.visible = true
	
	var track_w: float = meter_right - meter_left
	_zone_center = track_w / 2.0
	_marker_pos = _zone_center
	_target_drift_speed = 0.0
	_auto_drift_speed = 0.0
	_player_input_velocity = 0.0
	_boil_timer = boil_time
	
	_state = State.BOILING

func _update_boiling_balance(delta: float):
	_boil_timer = maxf(0.0, _boil_timer - delta)
	var track_w := meter_right - meter_left
	
	# 1. Smoothly wander the target boiling drift vector
	if absf(_target_drift_speed) < 1.0 or randf() < 0.02:
		var drift_direction = 1.0 if randf() < 0.5 else -1.0
		_target_drift_speed = drift_direction * randf_range(boil_drift_strength * 0.5, boil_drift_strength)
		
	# Linearly interpolate current drift velocity to get rid of snapping gaps
	_auto_drift_speed = lerpf(_auto_drift_speed, _target_drift_speed, boil_shift_smoothness * delta)
		
	# 2. Collect responsive player input values
	var input_dir := 0.0
	if player_number == 1:
		if Input.is_action_pressed("move_left_p1"): input_dir -= 1.0
		if Input.is_action_pressed("move_right_p1"): input_dir += 1.0
	else:
		if Input.is_action_pressed("move_left_p2"): input_dir -= 1.0
		if Input.is_action_pressed("move_right_p2"): input_dir += 1.0
		
	if input_dir != 0.0:
		_player_input_velocity += input_dir * move_speed * 4.5 * delta
	else:
		_player_input_velocity = lerpf(_player_input_velocity, 0.0, 14.0 * delta)
		
	_player_input_velocity = clampf(_player_input_velocity, -move_speed * 0.8, move_speed * 0.8)
	
	# 3. Sum up systems and push coordinates
	var final_movement = (_auto_drift_speed + _player_input_velocity) * delta
	_marker_pos = clampf(_marker_pos + final_movement, 0.0, track_w)
	
	_refresh_meter_visual(track_w)
	
	if _boil_timer <= 0.0:
		_meter_group.visible = false
		_state = State.DONE
		complete_minigame(1.0)

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

func _apply_hand_pos():
	_hand_img.offset_left = _hand_pos.x
	_hand_img.offset_top = _hand_pos.y
	_hand_img.offset_right = _hand_pos.x + hand_size.x
	_hand_img.offset_bottom = _hand_pos.y + hand_size.y

	_handclose_img.offset_left = _hand_pos.x
	_handclose_img.offset_top = _hand_pos.y
	_handclose_img.offset_right = _hand_pos.x + hand_size.x
	_handclose_img.offset_bottom = _hand_pos.y + hand_size.y

func _apply_cup_pos():
	_cup_img.offset_left = _cup_pos.x
	_cup_img.offset_top = _cup_pos.y
	_cup_img.offset_right = _cup_pos.x + cup_size.x
	_cup_img.offset_bottom = _cup_pos.y + cup_size.y

	_cupwtwater_img.offset_left = _cup_pos.x
	_cupwtwater_img.offset_top = _cup_pos.y
	_cupwtwater_img.offset_right = _cup_pos.x + cup_size.x
	_cupwtwater_img.offset_bottom = _cup_pos.y + cup_size.y

func _apply_kadyos_pos():
	_kadyos_img.offset_left = _kadyos_pos.x
	_kadyos_img.offset_top = _kadyos_pos.y
	_kadyos_img.offset_right = _kadyos_pos.x + kadyos_size.x
	_kadyos_img.offset_bottom = _kadyos_pos.y + kadyos_size.y

func _rect_overlap(pos_a: Vector2, size_a: Vector2, pos_b: Vector2, size_b: Vector2) -> bool:
	return pos_a.x < pos_b.x + size_b.x \
	and pos_a.x + size_a.x > pos_b.x \
	and pos_a.y < pos_b.y + size_b.y \
	and pos_a.y + size_a.y > pos_b.y

func _hand_over_cup() -> bool:
	return _rect_overlap(_hand_pos - Vector2(20, 20), hand_size + Vector2(40, 40), _cup_pos, cup_size)

func _hand_over_kadyos() -> bool:
	return _rect_overlap(_hand_pos - Vector2(20, 20), hand_size + Vector2(40, 40), _kadyos_pos, kadyos_size)

func _cup_over_water() -> bool:
	return _rect_overlap(_cup_pos, cup_size, water_source_pos, water_source_size)

func _cup_over_pot() -> bool:
	return _rect_overlap(_cup_pos, cup_size, pot_pos, pot_size)

func _kadyos_over_pot() -> bool:
	return _rect_overlap(_kadyos_pos, kadyos_size, pot_pos, pot_size)
