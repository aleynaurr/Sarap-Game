extends MinigameBase

var _score_bonus: float = 0.0
var _has_dropped: bool = false
var _move_speed: float = 250.0 
var _mistakes_count: int = 0

var _min_x: float = 0
var _max_x: float = 480.0

var _pouring_bowl_height_y: float = 237.0 
var _big_mixer_bowl_height_y: float = 310.0

@onready var _lbl_timer: Label = $TimerLabel
@onready var _lbl_status: Label = $StatusLabel
var _lbl_wrong: Label = null

@onready var plate_target: Control = $TargetZone 
@onready var shadow_sprite: TextureRect = $PlatingShadow 
@onready var pouring_bowl: TextureRect = $PouringBowl 

@onready var big_mixer_bowl: TextureRect = $BigMixerBowl 

@onready var mixture_sprite: TextureRect = $PlatingMixtureOnTheEggplant 

func _ready() -> void:
	_on_init()

func _on_init() -> void:
	_score_bonus = 0.0
	_has_dropped = false
	
	if _lbl_wrong: _lbl_wrong.text = ""
	var interact_key = "E" if player_number == 1 else "Shift"
	if _lbl_status: _lbl_status.text = "Move with your movement keys, press %s to Pour!" % interact_key
	
	if pouring_bowl:
		pouring_bowl.visible = true
		pouring_bowl.rotation_degrees = 0.0
		pouring_bowl.global_position = Vector2((_min_x + _max_x) / 2.0, _pouring_bowl_height_y)
	
	if big_mixer_bowl:
		big_mixer_bowl.visible = false
		big_mixer_bowl.rotation_degrees = 0.0
	
	if shadow_sprite:
		shadow_sprite.visible = true
		shadow_sprite.modulate.a = 0.4
		
	if mixture_sprite:
		mixture_sprite.visible = false 
		mixture_sprite.scale = Vector2.ONE

	_update_shadow_position()

func _process(delta: float) -> void:
	if _has_dropped: return
	
	var input_dir := 0.0
	if player_number == 1:
		if Input.is_action_pressed("move_left_p1"):
			input_dir -= 1.0
		if Input.is_action_pressed("move_right_p1"):
			input_dir += 1.0
	else:
		if Input.is_action_pressed("move_left_p2"):
			input_dir -= 1.0
		if Input.is_action_pressed("move_right_p2"):
			input_dir += 1.0
		
	if input_dir != 0.0 and pouring_bowl:
		var next_x = pouring_bowl.global_position.x + (input_dir * _move_speed * delta)
		pouring_bowl.global_position.x = clampf(next_x, _min_x, _max_x)
		_update_shadow_position()
	
	if Input.is_action_just_pressed("interact_p%d" % player_number):
		_execute_plating_drop()

func _update_shadow_position() -> void:
	if pouring_bowl and shadow_sprite and plate_target:
		var target_center_y = plate_target.global_position.y + (plate_target.size.y / 2.0)
		var bowl_center_x = pouring_bowl.global_position.x + (pouring_bowl.size.x / 2.0)
		
		shadow_sprite.global_position = Vector2(
			bowl_center_x - (shadow_sprite.size.x / 2.0),
			target_center_y - (shadow_sprite.size.y / 2.0)
		)

func _execute_plating_drop() -> void:
	_has_dropped = true
	
	if shadow_sprite: shadow_sprite.visible = false
	
	var bowl_center_x = pouring_bowl.global_position.x + (pouring_bowl.size.x / 2.0)
	var target_center = plate_target.global_position + (plate_target.size / 2.0)
	var distance: float = absf(bowl_center_x - target_center.x)
	
	var tween = create_tween().set_parallel(true)
	
	# Swap the Sprites instantly!
	if pouring_bowl and big_mixer_bowl:
		# 🛠️ FIX: Put the big mixer bowl on its own lower Y coordinate so it doesn't block the UI text!
		big_mixer_bowl.global_position = Vector2(pouring_bowl.global_position.x, _big_mixer_bowl_height_y)
		big_mixer_bowl.visible = true
		pouring_bowl.visible = false
		
		tween.tween_property(big_mixer_bowl, "rotation_degrees", -45.0, 0.25).set_trans(Tween.TRANS_QUAD)
		
	if mixture_sprite:
		mixture_sprite.visible = true
		
		mixture_sprite.global_position = Vector2(
			bowl_center_x - (mixture_sprite.size.x / 2.0), 
			_pouring_bowl_height_y + 40.0
		)
		
		var drop_target_pos = Vector2(
			target_center.x - (mixture_sprite.size.x / 2.0),
			target_center.y - (mixture_sprite.size.y / 2.0)
		)
			
		tween.tween_property(mixture_sprite, "global_position", drop_target_pos, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween.chain().tween_callback(func():
		_evaluate_placement_score(distance)
	)

func _evaluate_placement_score(distance: float) -> void:
	if distance < 35.0:
		_score_bonus = 1.0
		if _lbl_status: _lbl_status.text = "Perfect Pour!"
	elif distance < 75.0:
		_score_bonus = 0.6
		if _lbl_status: _lbl_status.text = "Good Placement!"
	else:
		_score_bonus = 0.2
		_mistakes_count += 1
		if _lbl_wrong: _lbl_wrong.text = "Timing was off, but you managed to save it!"
		if _lbl_status: _lbl_status.text = "Minor adjustment needed."
			
	get_tree().create_timer(1.5).timeout.connect(_calculate_and_complete)

func _on_update(_delta: float, remaining: float) -> void:
	if not _has_dropped:
		_update_timer_display(remaining)

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)

func _force_finish() -> void:
	_calculate_and_complete()

func _calculate_and_complete() -> void:
	var final_score = clampf(_score_bonus, 0.0, 1.0)
	if not _has_dropped:
		final_score = 0.0
		
	if _lbl_status: _lbl_status.text = "Plating complete!"
	complete_minigame(final_score)
