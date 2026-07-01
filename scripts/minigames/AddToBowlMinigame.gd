extends MinigameBase
# Mini-game: Smoky Grated Coconut Station (Randomized Key Input)

# The base sequence pool
var _base_ingredients: Array = [
	{"label": "Put Grated Coconut in Bowl", "emoji": "🥥"},
	{"label": "Pour Vinegar next", "emoji": "🍾"},
	{"label": "Put Charcoal last", "emoji": "🪵"}
]

var _actions: Array = []
var _action_keys: Array = [] # Stores which key goes with which step
var _action_idx: int = 0
var _total_skill: float = 0.0
var _per_action_done: int = 0

# UI Node References
var _lbl_timer: Label
var _lbl_instruction: Label
var _lbl_action_name: Label
var _lbl_status: Label
var _lbl_progress: Label
var _result_label: Label
var _bowl_label: Label
var _ingredient_label: Label
var _bowl_fill: ColorRect
var _action_dots: Array = []

func _on_init() -> void:
	_action_idx = 0
	_total_skill = 0.0
	_per_action_done = 0
	_actions.clear()
	_action_keys.clear()

	# 🎲 1. Randomize the actual ingredient order sequence
	randomize()
	var ingredient_pool = _base_ingredients.duplicate()
	ingredient_pool.shuffle() 
	_actions = ingredient_pool

	# 🎲 2. Randomize the keys (W, A, D) assigned to each step
	var key_pool = ["KEY_W", "KEY_A", "KEY_D"]
	key_pool.shuffle()
	_action_keys = key_pool

	var bg = make_panel_bg(Vector2(640, 720))
	add_child(bg)

	var title = make_label("🥣  SMOKY GRATED COCONUT STATION", 19, Color(1.0, 0.87, 0.3))
	title.position = Vector2(16, 14)
	add_child(title)

	_lbl_instruction = make_label("Sundin ang tamang pagkakasunod-sunod para sa mas mataas na puntos!", 13, Color(0.95, 0.92, 0.82))
	_lbl_instruction.position = Vector2(20, 46)
	_lbl_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_instruction.custom_minimum_size.x = 600
	add_child(_lbl_instruction)

	# Big bowl visual (center)
	var bowl_bg = ColorRect.new()
	bowl_bg.color = Color(0.30, 0.24, 0.18)
	bowl_bg.size = Vector2(220, 130)
	bowl_bg.position = Vector2(210, 145)
	add_child(bowl_bg)

	_bowl_fill = ColorRect.new()
	_bowl_fill.color = Color(0.85, 0.80, 0.70, 0.85)
	_bowl_fill.size = Vector2(212, 0)
	_bowl_fill.position = Vector2(214, 275)
	add_child(_bowl_fill)

	_bowl_label = make_label("🥣", 64, Color(1, 1, 1))
	_bowl_label.position = Vector2(278, 145)
	add_child(_bowl_label)

	# Current ingredient visual flying down
	_ingredient_label = make_label("", 30, Color(1, 1, 1))
	_ingredient_label.position = Vector2(290, 90)
	add_child(_ingredient_label)

	_lbl_action_name = make_label("", 18, Color(1, 0.9, 0.5))
	_lbl_action_name.position = Vector2(20, 340)
	add_child(_lbl_action_name)

	_lbl_status = make_label("Press the correct key shown above!", 18, Color(1, 0.9, 0.2))
	_lbl_status.position = Vector2(80, 435)
	add_child(_lbl_status)

	# Progress Step tracking setup
	var dots_lbl = make_label("Ingredients Sequence:", 12, Color(0.85, 0.85, 0.85))
	dots_lbl.position = Vector2(20, 510)
	add_child(dots_lbl)

	var dots_row = HBoxContainer.new()
	dots_row.position = Vector2(170, 507)
	dots_row.add_theme_constant_override("separation", 10)
	add_child(dots_row)
	for i in _actions.size():
		var dot = make_label("●", 16, Color(0.45, 0.45, 0.45))
		dots_row.add_child(dot)
		_action_dots.append(dot)

	_lbl_progress = make_label("", 13, Color(0.85, 0.85, 0.85))
	_lbl_progress.position = Vector2(20, 545)
	add_child(_lbl_progress)

	_lbl_timer = make_label("Time: %.1f" % _time_limit, 15, Color(1.0, 0.6, 0.3))
	_lbl_timer.position = Vector2(500, 14)
	add_child(_lbl_timer)

	_result_label = make_label("", 22, Color(1, 0.85, 0.1))
	_result_label.position = Vector2(250, 620)
	_result_label.visible = false
	add_child(_result_label)

	var hint = make_label("Keyboard only — Press W, A, or D depending on the randomized instruction!", 11, Color(0.6, 0.6, 0.6))
	hint.position = Vector2(20, 695)
	add_child(hint)

	_load_current_action()

func _load_current_action() -> void:
	if _action_idx >= _actions.size():
		return
		
	var action = _actions[_action_idx]
	var current_key_string = _action_keys[_action_idx]
	var display_letter = current_key_string.get_slice("_", 1) # Turns "KEY_W" into "W"
	
	# Displays the dynamic randomized command in the label text
	_lbl_action_name.text = "👉 [%s] to: %s" % [display_letter, action.get("label", "Ingredient")]
	_ingredient_label.text = action.get("emoji", "🥄")
	
	_lbl_progress.text = "Step %d / %d" % [_action_idx + 1, _actions.size()]
	
	for i in _action_dots.size():
		if i < _action_idx:
			_action_dots[i].text = "✅"
			_action_dots[i].add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		elif i == _action_idx:
			_action_dots[i].add_theme_color_override("font_color", Color(1, 0.9, 0.2))
		else:
			_action_dots[i].text = "●"
			_action_dots[i].add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))

func _on_update(delta: float, _remaining: float) -> void:
	if _action_idx >= _actions.size():
		return

	# Handle the key selection via standard keyboard event checking
	if Input.is_action_just_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		_check_input_match("KEY_W")
	elif Input.is_key_pressed(KEY_A):
		_check_input_match("KEY_A")
	elif Input.is_action_just_pressed("ui_down") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_D):
		_check_input_match("KEY_D")

func _check_input_match(pressed_key: String) -> void:
	var target_key = _action_keys[_action_idx]
	var skill: float
	
	if pressed_key == target_key:
		skill = 1.0
		_lbl_status.text = "✅ Tama! Added cleanly!"
		_lbl_status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		AudioManager.play_sfx(AudioManager.SFX_SPLASH)
	else:
		skill = 0.20
		_lbl_status.text = "💦 Wrong ingredient order! Spilled..."
		_lbl_status.add_theme_color_override("font_color", Color(1, 0.4, 0.1))

	_total_skill += skill
	_per_action_done += 1
	_action_idx += 1

	var fill_ratio = float(_action_idx) / float(_actions.size())
	_bowl_fill.size.y = 110 * fill_ratio
	_bowl_fill.position.y = 275 - (110 * fill_ratio)

	if _action_idx >= _actions.size():
		var avg_skill = _total_skill / float(_actions.size())
		
		_result_label.text = "Handa na!"
		_result_label.visible = true
		
		for dot in _action_dots:
			dot.text = "✅"
			dot.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
			
		complete_minigame(clampf(avg_skill, 0.0, 1.0))
	else:
		_load_current_action()

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)
		if remaining < 5.0:
			_lbl_timer.add_theme_color_override("font_color", Color(1, 0.2, 0.2))

func _force_finish() -> void:
	var ratio = float(_action_idx) / float(max(1, _actions.size()))
	var avg_skill = (_total_skill / float(max(1, _action_idx))) if _action_idx > 0 else 0.0
	complete_minigame(avg_skill * ratio)
