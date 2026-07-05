extends MinigameBase
# Mini-game: Fanning Station (Alternating Up & Down Controls)

# Configuration
const PENALTY_PER_MISTAKE := 0.15

var _target_fans: int = 0
var _fans_done: int = 0
var _last_input_time: float = 0.0
var _mistakes_count: int = 0

var _expected_dir: int = 0 
var _finished_fanning: bool = false

# UI Nodes
@onready var _lbl_timer: Label        = $TimerLabel
#@onready var _result_label: Label     = $ResultLabel
@onready var _lbl_title: Label        = $TitleLabel
@onready var _lbl_status: Label       = $StatusLabel

# Fanning Progressive Stage Sprites
@onready var fanning_0 = $Fanning1# Starting / Raw
@onready var fanning_1 = $Fanning2 # Lightly cooked
@onready var fanning_2 = $Fanning3 # PERFECT STAGE!
@onready var fanning_3 = $Fanning4

# Action Moving Sprites
@onready var up = $up
@onready var down = $down

# Smoke Particles/Puffs
@onready var smoke1 = $smoke1
@onready var smoke2 = $smoke2

# Control Layout Glow Highlights
@onready var wGlow = $wGlow
@onready var upGlow = $upGlow
@onready var sGlow = $sGlow
@onready var downGlow = $downGlow

func _ready() -> void:
	_on_init()

func _on_init() -> void:
	randomize()
	_target_fans = randi_range(10, 20)
	_fans_done = 0
	_expected_dir = 0
	_mistakes_count = 0
	_finished_fanning = false
	
	if _lbl_title:
		_lbl_title.text = "🔥 PAYPAYAN"
		
	_apply_sprites_from_state(GameManager.fanning_result_state)

	_update_action_sprites(0)
	_highlight_step()

func _on_update(_delta: float, remaining: float) -> void:
	if not _finished_fanning:
		_update_timer_display(remaining)
		
func _unhandled_input(event: InputEvent) -> void:
	if _finished_fanning or not event.is_pressed() or event.is_echo(): 
		return
		
	var input_pressed = -1
	if event.is_action_pressed("move_up") or (event is InputEventKey and event.keycode == KEY_W):
		input_pressed = 0
	elif event.is_action_pressed("move_down") or (event is InputEventKey and event.keycode == KEY_S):
		input_pressed = 2

	if input_pressed != -1:
		# Check alternating sequence match
		if input_pressed == _expected_dir:
			_fans_done += 1
			_last_input_time = Time.get_ticks_msec() / 1000.0
			
			# Swap expectation to enforce alternating mechanical rhythm
			_expected_dir = 2 if _expected_dir == 0 else 0
			
			_update_action_sprites(input_pressed)
			_update_fanning_sprites()
			_highlight_step()
			_check_game_status()
		else:
			_mistakes_count += 1
			if _lbl_status:
				_lbl_status.text = "Wrong rhythm! Alternate keys!"
				_lbl_status.modulate = Color.BLACK

func _check_game_status() -> void:
	if _fans_done < _target_fans:
		_lbl_status.text = "Fan more!"
		_lbl_status.modulate = Color.BLACK
	elif _fans_done <= _target_fans + 5:
		_lbl_status.text = "Perfect!"
		_lbl_status.modulate = Color.GREEN
	elif _fans_done <= _target_fans + 10:
		_lbl_status.text = "Too much!"
		_lbl_status.modulate = Color.CRIMSON
	else:
		_lbl_status.text = "Burnt!"
		_lbl_status.modulate = Color.RED

func _update_action_sprites(current_dir: int) -> void:
	if current_dir == 0:
		if up: up.visible = true
		if down: down.visible = false
		if smoke1: smoke1.visible = true
		if smoke2: smoke2.visible = false
	else:
		if up: up.visible = false
		if down: down.visible = true
		if smoke1: smoke1.visible = false
		if smoke2: smoke2.visible = true

func _update_fanning_sprites() -> void:
	_hide_all_fanning_sprites()
	if _fans_done == 0:
		fanning_0.visible = true
	elif _fans_done < _target_fans:
		fanning_1.visible = true
	elif _fans_done <= _target_fans + 5:
		fanning_2.visible = true   # Perfect state
	elif _fans_done <= _target_fans + 10:
		fanning_3.visible = true   # Too much state
	else:
		fanning_3.visible = true

func _apply_sprites_from_state(state: String) -> void:
	_hide_all_fanning_sprites()
	match state:
		"raw": fanning_0.visible = true
		"under": fanning_1.visible = true
		"perfect": fanning_2.visible = true
		"toomuch": fanning_3.visible = true
		"burnt": fanning_3.visible = true
		_: fanning_0.visible = true

func _hide_all_fanning_sprites() -> void:
	if fanning_0: fanning_0.visible = false
	if fanning_1: fanning_1.visible = false
	if fanning_2: fanning_2.visible = false
	if fanning_3: fanning_3.visible = false

func _highlight_step() -> void:
	if wGlow: wGlow.visible = (_expected_dir == 0)
	if upGlow: upGlow.visible = (_expected_dir == 0)
	if sGlow: sGlow.visible = (_expected_dir == 2)
	if downGlow: downGlow.visible = (_expected_dir == 2)

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)

func _force_finish() -> void:
	_calculate_and_complete()

func finish_fanning_action() -> void:
	_calculate_and_complete()

func _calculate_and_complete() -> void:
	_finished_fanning = true
	var base_score: float = 0.0
	var state_result: String = "raw"
	
	if smoke1: smoke1.visible = false
	if smoke2: smoke2.visible = false
	
	if _fans_done == 0:
		base_score = 0.0
		state_result = "raw"
	elif _fans_done < _target_fans:
		base_score = (float(_fans_done) / float(_target_fans)) * 0.7
		state_result = "under"
	elif _fans_done <= _target_fans + 5:
		base_score = 1.0 
		state_result = "perfect"
	elif _fans_done <= _target_fans + 10:
		base_score = 0.5 
		state_result = "toomuch"
	else:
		base_score = 0.1 
		state_result = "burnt" # This will now successfully pass to Straining!

	GameManager.fanning_result_state = state_result

	var total_penalty := _mistakes_count * PENALTY_PER_MISTAKE
	var final_score := clampf(base_score - total_penalty, 0.0, 1.0)

	complete_minigame(final_score)
