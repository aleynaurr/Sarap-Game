extends MinigameBase
# Add to Bowl: Cooking-Mama style "pour/put ingredient into the bigger bowl"
# minigame, KEYBOARD ONLY (no mouse). Used for Work Station steps that group
# several consecutive small actions (e.g. "put coconut in bowl", "put live
# charcoal in bowl", "pour vinegar") into one continuous sequence — matching
# how the original .tscn files group multiple instructions under one station.
#
# step_data["actions"]: Array of { label, icon (optional) } — one per
# sub-instruction, performed strictly in order. If "actions" isn't provided,
# falls back to one action per entry in step_data["ingredients"].
#
# For each action: a timing bar sweeps; press SPACE/E when the marker is in
# the green "drop zone" to add it cleanly. Hitting it well = high skill score
# for that action. All actions must be done before the step completes.

const SWEEP_PERIOD := 1.1          # seconds for the marker to sweep across
const DROP_ZONE_MIN := 0.40
const DROP_ZONE_MAX := 0.62
const PERFECT_CENTER := 0.51

var _actions: Array = []
var _action_idx: int = 0
var _sweep_t: float = 0.0
var _sweep_dir: int = 1
var _total_skill: float = 0.0
var _per_action_done: int = 0

var _lbl_timer: Label
var _lbl_instruction: Label
var _lbl_action_name: Label
var _lbl_status: Label
var _lbl_progress: Label
var _result_label: Label
var _bowl_label: Label
var _ingredient_label: Label
var _sweep_track_bg: ColorRect
var _sweep_marker: ColorRect
var _drop_zone_visual: ColorRect
var _bowl_fill: ColorRect
var _action_dots: Array = []

func _on_init() -> void:
	_actions = step_data.get("actions", [])
	if _actions.is_empty():
		# fall back: one action per ingredient
		var ingr = step_data.get("ingredients", ["Ingredient"])
		for i in ingr.size():
			_actions.append({"label": _nice_name(ingr[i])})
		if _actions.is_empty():
			_actions = [{"label": "Ingredient"}]

	_action_idx = 0
	_sweep_t = 0.0
	_sweep_dir = 1
	_total_skill = 0.0
	_per_action_done = 0

	var bg = make_panel_bg(Vector2(640, 480))
	add_child(bg)

	var title = make_label("🥣  IDAGDAG SA MANGKOK!  (Add to Bowl!)", 19, Color(1.0, 0.87, 0.3))
	title.position = Vector2(16, 14)
	add_child(title)

	_lbl_instruction = make_label(step_data.get("instruction", ""), 13, Color(0.95, 0.92, 0.82))
	_lbl_instruction.position = Vector2(20, 46)
	_lbl_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_instruction.custom_minimum_size.x = 600
	add_child(_lbl_instruction)

	# Big bowl visual (center)
	var bowl_bg = ColorRect.new()
	bowl_bg.color = Color(0.30, 0.24, 0.18)
	bowl_bg.size = Vector2(220, 130)
	bowl_bg.position = Vector2(210, 110)
	add_child(bowl_bg)

	_bowl_fill = ColorRect.new()
	_bowl_fill.color = Color(0.55, 0.42, 0.22, 0.85)
	_bowl_fill.size = Vector2(212, 0)
	_bowl_fill.position = Vector2(214, 236)
	add_child(_bowl_fill)

	_bowl_label = make_label("🥣", 64, Color(1, 1, 1))
	_bowl_label.position = Vector2(278, 110)
	add_child(_bowl_label)

	# Current ingredient flying toward the bowl
	_ingredient_label = make_label("", 30, Color(1, 1, 1))
	_ingredient_label.position = Vector2(290, 60)
	add_child(_ingredient_label)

	_lbl_action_name = make_label("", 18, Color(1, 0.9, 0.5))
	_lbl_action_name.position = Vector2(20, 250)
	add_child(_lbl_action_name)

	# Sweep timing bar
	_sweep_track_bg = ColorRect.new()
	_sweep_track_bg.color = Color(0.18, 0.15, 0.14)
	_sweep_track_bg.size = Vector2(440, 26)
	_sweep_track_bg.position = Vector2(20, 285)
	add_child(_sweep_track_bg)

	_drop_zone_visual = ColorRect.new()
	_drop_zone_visual.color = Color(0.2, 1.0, 0.3, 0.4)
	_drop_zone_visual.size = Vector2(440 * (DROP_ZONE_MAX - DROP_ZONE_MIN), 26)
	_drop_zone_visual.position = Vector2(20 + 440 * DROP_ZONE_MIN, 285)
	add_child(_drop_zone_visual)

	_sweep_marker = ColorRect.new()
	_sweep_marker.color = Color(1.0, 0.9, 0.2)
	_sweep_marker.size = Vector2(8, 26)
	_sweep_marker.position = Vector2(20, 285)
	add_child(_sweep_marker)

	var zone_lbl = make_label("DROP ZONE", 10, Color(0.2, 1.0, 0.3))
	zone_lbl.position = Vector2(20 + 440 * DROP_ZONE_MIN, 312)
	add_child(zone_lbl)

	_lbl_status = make_label("Press  SPACE / E  when in the zone!", 18, Color(1, 0.9, 0.2))
	_lbl_status.position = Vector2(80, 335)
	add_child(_lbl_status)

	# Progress dots — one per action
	var dots_lbl = make_label("Steps:", 12, Color(0.85, 0.85, 0.85))
	dots_lbl.position = Vector2(20, 375)
	add_child(dots_lbl)

	var dots_row = HBoxContainer.new()
	dots_row.position = Vector2(80, 372)
	dots_row.add_theme_constant_override("separation", 6)
	add_child(dots_row)
	for i in _actions.size():
		var dot = make_label("●", 16, Color(0.45, 0.45, 0.45))
		dots_row.add_child(dot)
		_action_dots.append(dot)

	_lbl_progress = make_label("", 13, Color(0.85, 0.85, 0.85))
	_lbl_progress.position = Vector2(20, 400)
	add_child(_lbl_progress)

	_lbl_timer = make_label("Time: %.1f" % _time_limit, 15, Color(1.0, 0.6, 0.3))
	_lbl_timer.position = Vector2(500, 14)
	add_child(_lbl_timer)

	_result_label = make_label("", 22, Color(1, 0.85, 0.1))
	_result_label.position = Vector2(170, 430)
	_result_label.visible = false
	add_child(_result_label)

	var hint = make_label("Keyboard only — SPACE or E to drop the ingredient in!", 11, Color(0.6, 0.6, 0.6))
	hint.position = Vector2(20, 458)
	add_child(hint)

	_load_current_action()

func _nice_name(s: String) -> String:
	return s.replace("icon_", "").replace("_", " ").capitalize()

func _load_current_action() -> void:
	if _action_idx >= _actions.size():
		return
	var action = _actions[_action_idx]
	_lbl_action_name.text = "👉 " + action.get("label", "Ingredient")
	_ingredient_label.text = action.get("emoji", "🥄")
	_lbl_status.text = "Press  SPACE / E  when in the zone!"
	_lbl_status.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	_lbl_progress.text = "Action %d / %d" % [_action_idx + 1, _actions.size()]
	_sweep_t = 0.0
	_sweep_dir = 1
	for i in _action_dots.size():
		if i < _action_idx:
			_action_dots[i].text = "✅"
			_action_dots[i].add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		elif i == _action_idx:
			_action_dots[i].add_theme_color_override("font_color", Color(1, 0.9, 0.2))
		else:
			_action_dots[i].add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))

func _on_update(delta: float, _remaining: float) -> void:
	if _action_idx >= _actions.size():
		return

	# Sweep marker back and forth
	_sweep_t += (delta / SWEEP_PERIOD) * _sweep_dir
	if _sweep_t >= 1.0:
		_sweep_t = 1.0
		_sweep_dir = -1
	elif _sweep_t <= 0.0:
		_sweep_t = 0.0
		_sweep_dir = 1

	_sweep_marker.position.x = 20 + (440 - 8) * _sweep_t

	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
		_attempt_drop()

func _attempt_drop() -> void:
	var dist_from_center = absf(_sweep_t - PERFECT_CENTER)
	var skill: float
	if _sweep_t >= DROP_ZONE_MIN and _sweep_t <= DROP_ZONE_MAX:
		skill = 1.0 - clampf(dist_from_center / 0.3, 0.0, 0.5)
		_lbl_status.text = "✅ Tama! Added cleanly!"
		_lbl_status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		AudioManager.play_sfx(AudioManager.SFX_SPLASH)
	else:
		skill = 0.25
		_lbl_status.text = "💦 Messy! Spilled a bit..."
		_lbl_status.add_theme_color_override("font_color", Color(1, 0.4, 0.1))

	_total_skill += skill
	_per_action_done += 1
	_action_idx += 1

	# Fill the bowl proportionally
	var fill_ratio = float(_action_idx) / float(_actions.size())
	_bowl_fill.size.y = 110 * fill_ratio
	_bowl_fill.position.y = 240 - (110 * fill_ratio)

	if _action_idx >= _actions.size():
		var avg_skill = _total_skill / float(_actions.size())
		_result_label.text = "✨ Nadagdag na lahat! (All added!) ✨"
		_result_label.visible = true
		for dot in _action_dots:
			dot.text = "✅"
			dot.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		complete_minigame(avg_skill)
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
