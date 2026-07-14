extends MinigameBase

@onready var tex_full = $FullEggplant
@onready var tex_one_poke = $"FullEggplant/1poke"
@onready var tex_two_pokes = $"FullEggplant/2pokes"
@onready var tex_three_pokes = $"FullEggplant/3pokes"
@onready var tex_fully_poked = $"FullEggplant/4pokes"

@onready var tex_one_salt = $"FullEggplant/1salt"
@onready var tex_two_salt = $"FullEggplant/2salts"
@onready var tex_three_salt = $"FullEggplant/3salts"
@onready var tex_final = $FullEggplant/final

@onready var _eggplant_sprite: TextureRect = $FullEggplant
@onready var _fork_sprite: TextureRect     = $Fork
@onready var _salt_sprite: TextureRect     = $Salt

@onready var _lbl_timer: Label         = $TimerLabel
@onready var _lbl_status: Label        = $StatusLabel
@onready var _lbl_phase: Label         = $TitleLabel     
@onready var _result_label: Label      = $ResultLabel
@onready var _lbl_progress: Label      = $ProgressLabel
@onready var _lbl_label: RichTextLabel = $Phase2Label
@onready var _salt_particles: CPUParticles2D = $Salt/SaltedSprite

enum Phase { PRICK, SEASON }
var _phase: Phase = Phase.PRICK

# Phase 1 Config
const POKES_NEEDED := 4
var _pricks: int = 0
var _fork_start_pos: Vector2 = Vector2(308, 286)
var _fork_area: int = 0
var _has_finished: bool = false

# Phase 2 Config
var _current_area: int = 0
const AREA_Y_POSITIONS := [238, 288, 336, 368] 
var _area_salt_counts := [0, 0, 0, 0]
var _salt_start_x: float = 303
var _secret_targets = [0, 0, 0, 0]

func _on_init() -> void:
	_phase = Phase.PRICK
	_pricks = 0
	_current_area = 0
	_fork_area = 0
	_area_salt_counts = [0, 0, 0, 0]
	_has_finished = false

	if _fork_sprite:
		_fork_sprite.position = _fork_start_pos
		_fork_sprite.visible = true
		
	if _salt_sprite:
		_salt_sprite.visible = false
		_salt_x_alignment()
		
	_hide_all_eggplant_stages()
	
	if _eggplant_sprite:
		_eggplant_sprite.visible = true

	if _result_label:
		_result_label.visible = false

	if _lbl_progress: _lbl_progress.visible = false
	if _lbl_phase: _lbl_phase.text = "Poke the Eggplant!"
	if _lbl_status: _lbl_status.text = "Press 'E' or 'Shift' to poke (%d/%d)" % [_pricks, POKES_NEEDED]

func _on_update(delta: float, remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)
		
	if remaining <= 0.0 and not _has_finished:
		if _phase == Phase.PRICK:
			_start_season_phase()
		else:
			_finish_minigame()
		return

	if _phase == Phase.PRICK:
		if Input.is_action_just_pressed("interact_p%d" % player_number):
			_pricks += 1
			_shake_eggplant_effect()
			
			if _fork_sprite:
				var target_y = AREA_Y_POSITIONS[_fork_area]
				var tween = create_tween()
				var target_poke_pos = Vector2(250, target_y)
				var resting_pos = Vector2(_fork_start_pos.x, target_y)
				
				tween.tween_property(_fork_sprite, "position", target_poke_pos, 0.05)
				tween.tween_property(_fork_sprite, "position", resting_pos, 0.05)
			
			_fork_area = min(_fork_area + 1, 3)
			
			_hide_all_eggplant_stages()
			match _pricks:
				0: pass 
				1: if tex_one_poke: tex_one_poke.visible = true
				2: if tex_two_pokes: tex_two_pokes.visible = true
				3: if tex_three_pokes: tex_three_pokes.visible = true
				4: if tex_fully_poked: tex_fully_poked.visible = true
				_: if tex_fully_poked: tex_fully_poked.visible = true
				
			if _lbl_status:
				_lbl_status.text = "Press 'E' or 'SHIFT' to poke (%d/%d)" % [_pricks, POKES_NEEDED]
				
			if _pricks >= POKES_NEEDED:
				_start_season_phase()

func _unhandled_input(event: InputEvent) -> void:
	if _phase != Phase.SEASON or _has_finished: 
		return
	
	if not event.is_pressed() or event.is_echo():
		return
	
	if player_number == 1:
		if Input.is_action_just_pressed("move_up_p1"):
			if _current_area > 0:
				_current_area -= 1
				_update_salt_shaker_position()
		elif Input.is_action_just_pressed("move_down_p1"):
			if _current_area < 3:
				_current_area += 1
				_update_salt_shaker_position()
		elif Input.is_action_just_pressed("grab_p1"):
			_pour_salt_in_area()
	else:
		if Input.is_action_just_pressed("move_up_p2"):
			if _current_area > 0:
				_current_area -= 1
				_update_salt_shaker_position()
		elif Input.is_action_just_pressed("move_down_p2"):
			if _current_area < 3:
				_current_area += 1
				_update_salt_shaker_position()
		elif Input.is_action_just_pressed("grab_p2"):
			_pour_salt_in_area()

func _shake_eggplant_effect() -> void:
	if not _eggplant_sprite: return
	var tween = create_tween()

func _start_season_phase() -> void:
	randomize()
	
	_secret_targets[0] = randi_range(1, 4)
	_secret_targets[1] = randi_range(1, 4)
	_secret_targets[2] = randi_range(1, 4)
	_secret_targets[3] = randi_range(1, 4)
	
	_phase = Phase.SEASON
	if _lbl_phase: _lbl_phase.text = "Salt the Eggplant"
	if _fork_sprite: _fork_sprite.visible = false
	
	if _salt_sprite:
		_salt_sprite.visible = true
		_update_salt_shaker_position()
		
	if _lbl_status:
		_lbl_status.text = "Press 'Q' or '/' to season salt"
		_lbl_status.visible = true
		
	if _lbl_progress: _lbl_progress.visible = true
	_refresh_seasoning_ui_labels()

func _update_salt_shaker_position() -> void:
	if _salt_sprite:
		var target_y = AREA_Y_POSITIONS[_current_area]
		var tween = create_tween()
		tween.tween_property(_salt_sprite, "position", Vector2(_salt_start_x, target_y), 0.1)
	_refresh_seasoning_ui_labels()

func _pour_salt_in_area() -> void:
	_area_salt_counts[_current_area] += 1
	
	if _salt_particles:
		_salt_particles.emitting = true
	
	if _salt_sprite:
		var tween = create_tween()
		tween.tween_property(_salt_sprite, "rotation", 0.25, 0.04)
		tween.tween_property(_salt_sprite, "rotation", -0.25, 0.04)
		tween.tween_property(_salt_sprite, "rotation", 0.0, 0.04)
		
	var total_salts = 0
	for count in _area_salt_counts:
		total_salts += count
		
	_hide_all_eggplant_stages()
	match total_salts:
		0: if tex_fully_poked: tex_fully_poked.visible = true
		1, 2: if tex_one_salt: tex_one_salt.visible = true
		3, 4: if tex_two_salt: tex_two_salt.visible = true
		5, 6: if tex_three_salt: tex_three_salt.visible = true
		_: if total_salts >= 7 and tex_final: tex_final.visible = true

	_refresh_seasoning_ui_labels()

	# Finish if NO areas are left un-salted (meaning all are Perfect or Too Salty)
	var can_continue_salting := false
	for i in range(4):
		if _area_salt_counts[i] < _secret_targets[i]:
			can_continue_salting = true
			break
			
	if not can_continue_salting:
		_finish_minigame()

func _refresh_seasoning_ui_labels() -> void:
	var dashboard_text = ""

	for i in range(4):
		var taps = _area_salt_counts[i]
		var target = _secret_targets[i]
		var status_text = "Bland"
		var color_hex = "#90e0ef"

		if taps > 0:
			if taps == target:
				status_text = "Perfect!"
				color_hex = "#08f26e"
			elif taps < target:
				status_text = "Salt More!"
				color_hex = "#ffeb3b"
			else:
				status_text = "Too Salty!"
				color_hex = "#ff2400"

		var colored_status = "[color=" + color_hex + "]" + status_text + "[/color]"
		
		if i == _current_area:
			dashboard_text += "👉 [Area %d]: %s\n" % [i + 1, colored_status]
		else:
			dashboard_text += "      [Area %d]: %s\n" % [i + 1, colored_status]

	if _lbl_label:
		_lbl_label.text = dashboard_text
		_lbl_label.visible = true

func _finish_minigame() -> void:
	if _has_finished:
		return
		
	_has_finished = true
	set_process(false)
	
	if _salt_sprite: _salt_sprite.visible = false
	if _lbl_progress: _lbl_progress.visible = false
	if _lbl_status: _lbl_status.visible = false
	if _lbl_label: _lbl_label.visible = false
	
	var total_perfect_areas := 0
	for i in range(4):
		if _area_salt_counts[i] == _secret_targets[i]:
			total_perfect_areas += 1
			
	var prick_accuracy = clampf(float(_pricks) / float(POKES_NEEDED), 0.0, 1.0)
	var salt_accuracy = float(total_perfect_areas) / 4.0
	var final_score = (prick_accuracy * 0.4) + (salt_accuracy * 0.6)
	
	if _result_label:
		_result_label.text = "✨ Handa na! (Ready to grill!) ✨"
		_result_label.visible = true
		
	_hide_all_eggplant_stages()
	if tex_final: tex_final.visible = true

	complete_minigame(clampf(final_score, 0.0, 1.0))
	
func _hide_all_eggplant_stages() -> void:
	if tex_one_poke: tex_one_poke.visible = false
	if tex_two_pokes: tex_two_pokes.visible = false
	if tex_three_pokes: tex_three_pokes.visible = false
	if tex_fully_poked: tex_fully_poked.visible = false
	if tex_one_salt: tex_one_salt.visible = false
	if tex_two_salt: tex_two_salt.visible = false
	if tex_three_salt: tex_three_salt.visible = false
	if tex_final: tex_final.visible = false
	
	if _eggplant_sprite: 
		_eggplant_sprite.visible = true
		_eggplant_sprite.modulate.a = 1.0
		
		if _pricks > 0:
			_eggplant_sprite.texture = ImageTexture.new()

func _salt_x_alignment() -> void:
	if _salt_sprite:
		_salt_start_x = _salt_sprite.position.x

func _update_timer_display(remaining: float) -> void:
	pass

func _force_finish() -> void:
	if not _has_finished:
		_finish_minigame()
