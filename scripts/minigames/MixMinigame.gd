extends MinigameBase
# Mix: make circular motions with WASD (up→right→down→left→up).

const CIRCLES_NEEDED := 6
const WRONG_DIR_PENALTY := 0.5

# Direction states: 0=up, 1=right, 2=down, 3=left
# Rotating clockwise: 0→1→2→3→0
var _dir_seq: Array = [0, 1, 2, 3]
var _seq_pos: int = 0
var _circles_done: int = 0
var _total_smoothness: float = 0.0
var _last_input_time: float = 0.0
var _holding: int = -1

@onready var _lbl_timer: Label        = $TimerLabel
@onready var _lbl_circles: Label      = $CirclesLabel
@onready var _result_label: Label     = $ResultLabel
@onready var _lbl_title: Label        = $TitleLabel
@onready var _lbl_status: Label       = $StatusLabel

@onready var mix_up_sprite = $upmix
@onready var mix_right_sprite = $rightmix
@onready var mix_left_sprite = $leftmix
@onready var mix_down_sprite = $downmix
@onready var finish_sprite = $finish

@onready var sGlow = $sGlow
@onready var wGlow = $wGlow
@onready var dGlow = $dGlow
@onready var aGlow = $aGlow
@onready var downGlow = $downGlow
@onready var upGlow = $upGlow
@onready var rightGlow = $rightGlow
@onready var leftGlow = $leftGlow

func _ready() -> void:
	if _lbl_circles:
		_lbl_circles.visible = true
		_lbl_circles.text = "Circles: 0 / %d" % CIRCLES_NEEDED
	
	if _lbl_title:
		_lbl_title.text = "Mix in WASD or ↑→↓← order"
		
	_highlight_step()

func _on_init() -> void:
	_seq_pos = 0
	_circles_done = 0
	_total_smoothness = 0.0
	_holding = -1
	
	# Reset visual elements
	mix_up_sprite.visible = true
	mix_right_sprite.visible = false
	mix_down_sprite.visible = false
	mix_left_sprite.visible = false
	finish_sprite.visible = false
	
	_clear_all_glows()
	
	if _lbl_title:
		_lbl_title.text = "🥣  HALUIN"

	if _lbl_circles:
		_lbl_circles.visible = true
		_lbl_circles.text = "Circles: 0 / %d" % CIRCLES_NEEDED

	_highlight_step()

func _on_update(_delta: float, remaining: float) -> void:
	_update_timer_display(remaining)
	
	var expected_dir = _dir_seq[_seq_pos]
	var held = -1
	
	if expected_dir == 0 and (Input.is_action_pressed("move_up") or Input.is_key_pressed(KEY_W)):
		held = 0
	elif expected_dir == 1 and (Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D)):
		held = 1
	elif expected_dir == 2 and (Input.is_action_pressed("move_down") or Input.is_key_pressed(KEY_S)):
		held = 2
	elif expected_dir == 3 and (Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A)):
		held = 3
	else:
		if Input.is_action_pressed("move_up") or Input.is_key_pressed(KEY_W):       held = 0
		elif Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D): held = 1
		elif Input.is_action_pressed("move_down") or Input.is_key_pressed(KEY_S):   held = 2
		elif Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A):   held = 3

	if held != _holding:
		_holding = held

		if held != -1:
			show_mix_sprite(held)
		
		if held == expected_dir:
			if _lbl_status: 
				_lbl_status.text = "" 
			
			var t_since_last = Time.get_ticks_msec() / 1000.0 - _last_input_time
			var smoothness = clampf(1.0 - t_since_last * 0.3, 0.2, 1.0)
			_total_smoothness += smoothness
			_last_input_time = Time.get_ticks_msec() / 1000.0
			_seq_pos = (_seq_pos + 1) % 4
			
			if _seq_pos == 0:
				_circles_done += 1
				if _lbl_circles:
					_lbl_circles.text = "Circles: %d / %d" % [_circles_done, CIRCLES_NEEDED]
				
				if _circles_done >= CIRCLES_NEEDED:
					var skill = _total_smoothness / float(CIRCLES_NEEDED * 4)

					mix_up_sprite.visible = false
					mix_right_sprite.visible = false
					mix_down_sprite.visible = false
					mix_left_sprite.visible = false
					_clear_all_glows()
					
					if finish_sprite: finish_sprite.visible = true

					if _result_label:
						_result_label.text = "✨ Halo na! (Mixed!) ✨"
						_result_label.visible = true
						_lbl_circles.visible = false
						
					if _lbl_status:
						_lbl_status.text = ""

					complete_minigame(clampf(skill, 0.0, 1.0))
					return
			_highlight_step()
			
		elif held != -1:
			var previous_dir = (_dir_seq[3] if _seq_pos == 0 else _dir_seq[_seq_pos - 1])
			if held != previous_dir:
				if _lbl_status:
					_lbl_status.text = "Wrong direction! Reset"
				
				_total_smoothness = maxf(0.0, _total_smoothness - WRONG_DIR_PENALTY)
				
				_seq_pos = 0
				_holding = -1
				show_mix_sprite(0) 
				
				_clear_all_glows()
				wGlow.visible = true
				upGlow.visible = true

func _highlight_step() -> void:
	_clear_all_glows()

	match _dir_seq[_seq_pos]:
		0:
			wGlow.visible = true
			upGlow.visible = true
		1:
			dGlow.visible = true
			rightGlow.visible = true
		2:
			sGlow.visible = true
			downGlow.visible = true
		3:
			aGlow.visible = true
			leftGlow.visible = true

func _clear_all_glows() -> void:
	sGlow.visible = false
	wGlow.visible = false
	dGlow.visible = false
	aGlow.visible = false
	downGlow.visible = false
	upGlow.visible = false
	rightGlow.visible = false
	leftGlow.visible = false

func show_mix_sprite(dir: int) -> void:
	mix_up_sprite.visible = false
	mix_right_sprite.visible = false
	mix_down_sprite.visible = false
	mix_left_sprite.visible = false

	match dir:
		0: mix_up_sprite.visible = true
		1: mix_right_sprite.visible = true
		2: mix_down_sprite.visible = true
		3: mix_left_sprite.visible = true

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)

func _force_finish() -> void:
	var skill = (_total_smoothness / float(max(1, _circles_done) * 4)) * (float(_circles_done) / float(CIRCLES_NEEDED))
	_clear_all_glows()
	complete_minigame(clampf(skill, 0.0, 1.0))
