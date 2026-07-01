
extends MinigameBase

const MOVE_SPEED := 300.0
const FLASH_SPEED := 2.0  # Flashes per second
const CARRY_SCALE := 1.15  # 15% bigger when carrying
const SMOKE_ANIM_SPEED := 5.0  # Smoke frames per second

# Cooking state durations (each state lasts 7 seconds, total 28 seconds to burnt)
const STATE_DURATION := 7.0

# States: 0 = raw, 1 = rare, 2 = medium, 3 = cooked, 4 = burnt
enum COOK_STATES { RAW, RARE, MEDIUM, COOKED, BURNT }

# State points: raw=0, rare=20, medium=40, cooked=100, burnt=0
const STATE_POINTS = [0, 20, 40, 100, 0]

# Bounds (left half 640x720)
const EGGPLANT_W := 150.0
const EGGPLANT_H := 200.0
const BOUNDS_LEFT := 0.0
const BOUNDS_RIGHT := 640.0 - EGGPLANT_W
const BOUNDS_TOP := 0.0
const BOUNDS_BOTTOM := 720.0 - EGGPLANT_H

# Stove position and size (updated from the scene file!
const STOVE_X := 28.0
const STOVE_Y := 266.0
const STOVE_W := 379.78848
const STOVE_H := 227.0

# Plate position and size
const PLATE_X := 490.0
const PLATE_Y := 250.0
const PLATE_W := 141.0
const PLATE_H := 200.0

# Progress bar positions
const BAR_LEFT := 40.0
const BAR_RIGHT := 600.0
const BAR_A_TOP := 80.0
const BAR_A_BOTTOM := 100.0
const BAR_B_TOP := 110.0
const BAR_B_BOTTOM := 130.0

# Game states
enum GAME_STATES { EGGPLANT_ON_PLATE, EGGPLANT_CARRYING, EGGPLANT_ON_STOVE }

var _game_state: int = GAME_STATES.EGGPLANT_ON_PLATE
var _eggplant_pos: Vector2 = Vector2.ZERO
var _current_side: int = 0  # 0 = Side A, 1 = Side B
var _side_progress: Array[float] = [0.0, 0.0]  # [Side A progress, Side B progress] (0.0 to 4.0)
var _done: bool = false
var _finish_timer: float = 0.0
var _flash_timer: float = 0.0  # Timer for flashing effect
var _smoke_timer: float = 0.0  # Timer for smoke animation

var _eggplant_tex_sideA: Array = []
var _eggplant_tex_sideB: Array = []
var _stove_tex_normal: Texture2D
var _stove_tex_hover: Texture2D
var _stove_tex_red: Texture2D
var _smoke_tex: Array = []

@onready var _lbl_timer: Label = $TimerLabel
@onready var _result_label: Label = $ResultLabel
@onready var _eggplant_img: TextureRect = $Eggplant
@onready var _stove_img: TextureRect = $Stove
@onready var _stove_red_img: TextureRect = $StoveRed
@onready var _smoke_img: TextureRect = $Smoke
@onready var _barA_fill: ColorRect = $SideABarFill
@onready var _barB_fill: ColorRect = $SideBBarFill
@onready var _barA_bg: ColorRect = $SideABarBg
@onready var _barB_bg: ColorRect = $SideBBarBg
@onready var _marker1_A: ColorRect = $Marker1A
@onready var _marker2_A: ColorRect = $Marker2A
@onready var _marker3_A: ColorRect = $Marker3A
@onready var _marker4_A: ColorRect = $Marker4A
@onready var _marker1_B: ColorRect = $Marker1B
@onready var _marker2_B: ColorRect = $Marker2B
@onready var _marker3_B: ColorRect = $Marker3B
@onready var _marker4_B: ColorRect = $Marker4B

func _on_init() -> void:
	_game_state = GAME_STATES.EGGPLANT_ON_PLATE
	_eggplant_pos = Vector2(PLATE_X + (PLATE_W - EGGPLANT_W) / 2, PLATE_Y + (PLATE_H - EGGPLANT_H) / 2)
	_current_side = 0
	_side_progress = [0.0, 0.0]
	_done = false
	_finish_timer = 0.0
	_flash_timer = 0.0
	_smoke_timer = 0.0
	
	_result_label.visible = false
	
	# Load textures
	_eggplant_tex_sideA.clear()
	_eggplant_tex_sideA.append(load("res://assets/sprites/minigames/Dish1FryMinigame/eggplant_sideA_raw.png"))
	_eggplant_tex_sideA.append(load("res://assets/sprites/minigames/Dish1FryMinigame/eggplant_sideA_rare.png"))
	_eggplant_tex_sideA.append(load("res://assets/sprites/minigames/Dish1FryMinigame/eggplant_sideA_medium.png"))
	_eggplant_tex_sideA.append(load("res://assets/sprites/minigames/Dish1FryMinigame/eggplant_sideA_cooked.png"))
	_eggplant_tex_sideA.append(load("res://assets/sprites/minigames/Dish1FryMinigame/eggplant_sideA_burnt.png"))
	
	_eggplant_tex_sideB.clear()
	_eggplant_tex_sideB.append(load("res://assets/sprites/minigames/Dish1FryMinigame/eggplant_sideB_raw.png"))
	_eggplant_tex_sideB.append(load("res://assets/sprites/minigames/Dish1FryMinigame/eggplant_sideB_rare.png"))
	_eggplant_tex_sideB.append(load("res://assets/sprites/minigames/Dish1FryMinigame/eggplant_sideB_medium.png"))
	_eggplant_tex_sideB.append(load("res://assets/sprites/minigames/Dish1FryMinigame/eggplant_sideB_cooked.png"))
	_eggplant_tex_sideB.append(load("res://assets/sprites/minigames/Dish1FryMinigame/eggplant_sideB_burnt.png"))
	
	_stove_tex_normal = load("res://assets/sprites/minigames/Dish1FryMinigame/stove_normal.png")
	_stove_tex_hover = load("res://assets/sprites/minigames/Dish1FryMinigame/stove_hover.png")
	_stove_tex_red = load("res://assets/sprites/minigames/Dish1FryMinigame/stove_red.png")
	
	_smoke_tex.clear()
	_smoke_tex.append(load("res://assets/sprites/minigames/Dish1FryMinigame/smoke_1.png"))
	_smoke_tex.append(load("res://assets/sprites/minigames/Dish1FryMinigame/smoke_2.png"))
	
	_stove_img.texture = _stove_tex_normal
	_stove_red_img.texture = _stove_tex_red
	_stove_red_img.modulate.a = 0.0
	_smoke_img.visible = false
	_update_eggplant_texture()
	_apply_eggplant_pos()
	_update_progress_bars()
	
	_time_limit = 60.0
	_lbl_timer.text = "Time: %.1f" % _time_limit

func _on_update(delta: float, _remaining: float) -> void:
	if _done:
		_finish_timer -= delta
		if _finish_timer <= 0.0:
			_finish_with_score()
		return
	
	# Update flash timer
	_flash_timer += delta
	
	# Check for pick/place (E / Shift)
	if Input.is_action_just_pressed("wash_faucet"):
		_handle_pick_place()
	
	# Check for flip (Q / ÷)
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("wash_next"):
		_handle_flip()
	
	# Handle movement if carrying
	if _game_state == GAME_STATES.EGGPLANT_CARRYING:
		_handle_movement(delta)
		_check_stove_hover()
	
	# Handle cooking if on stove
	var is_cooking := false
	if _game_state == GAME_STATES.EGGPLANT_ON_STOVE:
		_side_progress[_current_side] = minf(4.0, _side_progress[_current_side] + delta / STATE_DURATION)
		_update_progress_bars()
		_update_eggplant_texture()
		is_cooking = true
	
	# Update visual state of eggplant
	_update_eggplant_visuals()
	
	# Update stove red intensity
	var total_progress := (_side_progress[0] + _side_progress[1]) / 8.0
	_stove_red_img.modulate.a = total_progress
	
	# Update smoke animation
	if is_cooking:
		_smoke_timer += delta
		_smoke_img.visible = true
		var smoke_idx := int(floor(_smoke_timer * SMOKE_ANIM_SPEED)) % 2
		_smoke_img.texture = _smoke_tex[smoke_idx]
	else:
		_smoke_img.visible = false

func _handle_pick_place() -> void:
	match _game_state:
		GAME_STATES.EGGPLANT_ON_PLATE:
			_game_state = GAME_STATES.EGGPLANT_CARRYING
		GAME_STATES.EGGPLANT_CARRYING:
			if _is_on_stove():
				_game_state = GAME_STATES.EGGPLANT_ON_STOVE
				_eggplant_pos = Vector2(STOVE_X + (STOVE_W - EGGPLANT_W) / 2, STOVE_Y + (STOVE_H - EGGPLANT_H) / 2)
				_apply_eggplant_pos()
			elif _is_on_plate():
				_game_state = GAME_STATES.EGGPLANT_ON_PLATE
				_eggplant_pos = Vector2(PLATE_X + (PLATE_W - EGGPLANT_W) / 2, PLATE_Y + (PLATE_H - EGGPLANT_H) / 2)
				_apply_eggplant_pos()
				_finish_game()
			else:
				pass  # Do nothing if not on stove or plate
		GAME_STATES.EGGPLANT_ON_STOVE:
			_game_state = GAME_STATES.EGGPLANT_CARRYING

func _handle_flip() -> void:
	_current_side = 1 - _current_side
	_update_eggplant_texture()

func _handle_movement(delta: float) -> void:
	var dir = Vector2.ZERO
	if Input.is_action_pressed("move_up"):    dir.y -= 1
	if Input.is_action_pressed("move_down"):  dir.y += 1
	if Input.is_action_pressed("move_left"):  dir.x -= 1
	if Input.is_action_pressed("move_right"): dir.x += 1
	if dir == Vector2.ZERO: return
	_eggplant_pos += dir.normalized() * MOVE_SPEED * delta
	_eggplant_pos.x = clampf(_eggplant_pos.x, BOUNDS_LEFT, BOUNDS_RIGHT)
	_eggplant_pos.y = clampf(_eggplant_pos.y, BOUNDS_TOP, BOUNDS_BOTTOM)
	_apply_eggplant_pos()

func _is_on_stove() -> bool:
	var cx = _eggplant_pos.x + EGGPLANT_W / 2
	var cy = _eggplant_pos.y + EGGPLANT_H / 2
	return cx >= STOVE_X and cx <= STOVE_X + STOVE_W and cy >= STOVE_Y and cy <= STOVE_Y + STOVE_H

func _is_on_plate() -> bool:
	var cx = _eggplant_pos.x + EGGPLANT_W / 2
	var cy = _eggplant_pos.y + EGGPLANT_H / 2
	return cx >= PLATE_X and cx <= PLATE_X + PLATE_W and cy >= PLATE_Y and cy <= PLATE_Y + PLATE_H

func _check_stove_hover() -> void:
	if _is_on_stove():
		_stove_img.texture = _stove_tex_hover
	else:
		_stove_img.texture = _stove_tex_normal

func _update_eggplant_visuals() -> void:
	if _game_state == GAME_STATES.EGGPLANT_CARRYING:
		# Flash and scale up when carrying
		var flash_t = (_flash_timer * FLASH_SPEED)
		var alpha = 0.5 + 0.5 * sin(flash_t * PI * 2.0)
		_eggplant_img.modulate.a = alpha
		_eggplant_img.scale = Vector2(CARRY_SCALE, CARRY_SCALE)
	else:
		# Normal state
		_eggplant_img.modulate.a = 1.0
		_eggplant_img.scale = Vector2(1.0, 1.0)

func _apply_eggplant_pos() -> void:
	_eggplant_img.offset_left = _eggplant_pos.x
	_eggplant_img.offset_top = _eggplant_pos.y
	_eggplant_img.offset_right = _eggplant_pos.x + EGGPLANT_W
	_eggplant_img.offset_bottom = _eggplant_pos.y + EGGPLANT_H

func _update_eggplant_texture() -> void:
	var state_idx = int(floor(_side_progress[_current_side]))
	state_idx = clamp(state_idx, 0, 4)
	if _current_side == 0:
		_eggplant_img.texture = _eggplant_tex_sideA[state_idx]
	else:
		_eggplant_img.texture = _eggplant_tex_sideB[state_idx]

func _update_progress_bars() -> void:
	# Side A bar
	var progressA = clampf(_side_progress[0] / 4.0, 0.0, 1.0)
	var bar_wA = (BAR_RIGHT - BAR_LEFT) * progressA
	_barA_fill.offset_left = BAR_LEFT
	_barA_fill.offset_top = BAR_A_TOP
	_barA_fill.offset_right = BAR_LEFT + bar_wA
	_barA_fill.offset_bottom = BAR_A_BOTTOM
	
	# Side B bar
	var progressB = clampf(_side_progress[1] / 4.0, 0.0, 1.0)
	var bar_wB = (BAR_RIGHT - BAR_LEFT) * progressB
	_barB_fill.offset_left = BAR_LEFT
	_barB_fill.offset_top = BAR_B_TOP
	_barB_fill.offset_right = BAR_LEFT + bar_wB
	_barB_fill.offset_bottom = BAR_B_BOTTOM

func _finish_game() -> void:
	_done = true
	_finish_timer = 1.5
	_result_label.visible = true
	var stateA = int(floor(_side_progress[0]))
	stateA = clamp(stateA, 0, 4)
	var stateB = int(floor(_side_progress[1]))
	stateB = clamp(stateB, 0, 4)
	var scoreA = STATE_POINTS[stateA]
	var scoreB = STATE_POINTS[stateB]
	_result_label.text = "Cooking done!\nSide A: %d pts | Side B: %d pts" % [scoreA, scoreB]

func _finish_with_score() -> void:
	var stateA = int(floor(_side_progress[0]))
	stateA = clamp(stateA, 0, 4)
	var stateB = int(floor(_side_progress[1]))
	stateB = clamp(stateB, 0, 4)
	var scoreA = STATE_POINTS[stateA]
	var scoreB = STATE_POINTS[stateB]
	var total = (scoreA + scoreB) / 200.0  # Normalize to 0-1
	complete_minigame(clampf(total, 0.0, 1.0))

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)
		if remaining < 5.0:
			_lbl_timer.add_theme_color_override("font_color", Color(1, 0.2, 0.2))

func _force_finish() -> void:
	_finish_with_score()
