extends MinigameBase
# Mini-game: Smoky Grated Coconut Station (Randomized Key Input)

@onready var _lbl_key_coconut: TextureRect  = $GratedCoconutInSmallBowl/CoconutLabel
@onready var _lbl_key_vinegar: TextureRect  = $VinegarInSmallBowl/VinegarLabel
@onready var _lbl_key_charcoal: TextureRect = $CharcoalInSmallBowl/CharcoalLabel

@onready var tex_addedcoconut = $BigMixerBowl/addedcoconut
@onready var tex_addedvinegar = $BigMixerBowl/addedvinegar
@onready var tex_addedcharcoal = $BigMixerBowl/addedcharcoal

@onready var _lbl_timer: Label        = $TimerLabel
@onready var _lbl_action_name: Label  = $ActionNameLabel
@onready var _result_label: Label     = $ResultLabel
@onready var _lbl_title: Label        = $TitleLabel

var tex_w = preload("res://assets/assets/sprites/wasd/w (1).png")
var tex_a = preload("res://assets/assets/sprites/wasd/A (1).png")
var tex_d = preload("res://assets/assets/sprites/wasd/D (1).png")

var _base_ingredients: Array = [
	{"label": "Put Grated Coconut in Bowl", "keyword": "Coconut"},
	{"label": "Pour Vinegar next", "keyword": "Vinegar"},
	{"label": "Put Charcoal last", "keyword": "Charcoal"}
]

var _actions: Array = []
var _action_keys: Array = [] 
var _action_idx: int = 0
var _total_skill: float = 0.0

func _ready() -> void:
	if _lbl_key_coconut: _lbl_key_coconut.visible = true
	if _lbl_key_vinegar: _lbl_key_vinegar.visible = true
	if _lbl_key_charcoal: _lbl_key_charcoal.visible = true
	
	_on_init()

func _on_init() -> void:
	_action_idx = 0
	_total_skill = 0.0
	_actions.clear()
	_action_keys.clear()
	
	tex_addedcoconut.visible = false
	tex_addedvinegar.visible = false
	tex_addedcharcoal.visible = false

	randomize()
	_actions = _base_ingredients.duplicate()

	var key_pool = []
	if player_number == 1:
		key_pool = ["KEY_W", "KEY_A", "KEY_D"]
	else:
		key_pool = ["KEY_UP", "KEY_LEFT", "KEY_RIGHT"]
	key_pool.shuffle()
	_action_keys = key_pool
	
	for i in range(_actions.size()):
		var keyword = _actions[i].get("keyword", "")

		if keyword == "Coconut" and _lbl_key_coconut:
			_lbl_key_coconut.texture = get_key_texture(_action_keys[i])

		elif keyword == "Vinegar" and _lbl_key_vinegar:
			_lbl_key_vinegar.texture = get_key_texture(_action_keys[i])

		elif keyword == "Charcoal" and _lbl_key_charcoal:
			_lbl_key_charcoal.texture = get_key_texture(_action_keys[i])

	if _result_label:
		_result_label.text = "Press the necessary key for the ingredient"
		_result_label.visible = true


	_load_current_action()

func _load_current_action() -> void:
	if _action_idx >= _actions.size():
		return

	var action = _actions[_action_idx]
	
	if _lbl_title:
		_lbl_title.text = action.get("label", "Ingredient")

func _on_update(delta: float, _remaining: float) -> void:
	if _action_idx >= _actions.size():
		return

	if player_number == 1:
		if Input.is_action_just_pressed("move_up_p1"):
			_check_input_match("KEY_W")
		elif Input.is_action_just_pressed("move_left_p1"):
			_check_input_match("KEY_A")
		elif Input.is_action_just_pressed("move_right_p1"):
			_check_input_match("KEY_D")
	else:
		if Input.is_action_just_pressed("move_up_p2"):
			_check_input_match("KEY_UP")
		elif Input.is_action_just_pressed("move_left_p2"):
			_check_input_match("KEY_LEFT")
		elif Input.is_action_just_pressed("move_right_p2"):
			_check_input_match("KEY_RIGHT")

func _check_input_match(pressed_key: String) -> void:
	var target_key = _action_keys[_action_idx]

	if pressed_key == target_key:
		_total_skill += 1.0

		var keyword = _actions[_action_idx].get("keyword", "")

		_update_bowl_visual(keyword)

		if _result_label:
			_result_label.text = "✅ Tama!"

		AudioManager.play_sfx(AudioManager.SFX_SPLASH)

		_animate_ingredient_drop(keyword)
	else:
		_total_skill += 0.20
		if _result_label:
			_result_label.text = "❌ Wrong key! Try again."

func _animate_ingredient_drop(keyword: String) -> void:
	var source_node: TextureRect = null
	if keyword == "Coconut":
		source_node = $GratedCoconutInSmallBowl
	elif keyword == "Vinegar":
		source_node = $VinegarInSmallBowl
	elif keyword == "Charcoal":
		source_node = $CharcoalInSmallBowl

	if not source_node or not source_node.texture:
		_advance_game_step()
		return

	var temp_falling_item = TextureRect.new()
	temp_falling_item.texture = source_node.texture
	temp_falling_item.expand_mode = source_node.expand_mode
	temp_falling_item.stretch_mode = source_node.stretch_mode
	temp_falling_item.size = source_node.size
	
	add_child(temp_falling_item)
	temp_falling_item.global_position = source_node.global_position
	
	var target_pos = $BigMixerBowl.global_position + Vector2(30, -20) 

	source_node.visible = false

	var tween = create_tween().set_parallel(false)
	tween.tween_property(temp_falling_item, "global_position", target_pos, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(temp_falling_item, "modulate:a", 0.0, 0.15)
	
	tween.tween_callback(func():
		temp_falling_item.queue_free()
		_advance_game_step()
	)
	
func get_key_texture(key_name: String) -> Texture2D:
	match key_name:
		"KEY_W":
			return tex_w
		"KEY_A":
			return tex_a
		"KEY_D":
			return tex_d

	return null

func _update_bowl_visual(keyword: String) -> void:
	match keyword:
		"Coconut":
			tex_addedcoconut.visible = true

		"Vinegar":
			tex_addedvinegar.visible = true

		"Charcoal":
			tex_addedcharcoal.visible = true

func _advance_game_step() -> void:
	_action_idx += 1

	if _action_idx >= _actions.size():
		var avg_skill = _total_skill / float(_actions.size())
		if _result_label: _result_label.text = "✨ Handa na! ✨"
		
		if _lbl_key_coconut: _lbl_key_coconut.visible = false
		if _lbl_key_vinegar: _lbl_key_vinegar.visible = false
		if _lbl_key_charcoal: _lbl_key_charcoal.visible = false
		
		complete_minigame(clampf(avg_skill, 0.0, 1.0))
	else:
		_load_current_action()

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)

func _force_finish() -> void:
	_lbl_action_name.visible = false
	var ratio = float(_action_idx) / float(max(1, _actions.size()))
	var avg_skill = (_total_skill / float(max(1, _action_idx))) if _action_idx > 0 else 0.0
	complete_minigame(avg_skill * ratio)
