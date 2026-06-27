extends MinigameBase
# Fry: maintain heat in a sweet spot, then press SPACE to flip at the right moment.
# Heat drifts; press UP to increase heat, DOWN to decrease.
# A "doneness" meter fills; flip when in the golden zone for best result.

const TARGET_HEAT_MIN := 0.38
const TARGET_HEAT_MAX := 0.65
const HEAT_DRIFT      := 0.035  # how fast heat drifts down per second
const HEAT_UP_RATE    := 0.08
const HEAT_DOWN_RATE  := 0.06
const DONENESS_RATE   := 0.028  # doneness fills per second at good heat
const BURN_RATE       := 0.055  # burn fills at high heat
const FLIP_WINDOW_MIN := 0.38
const FLIP_WINDOW_MAX := 0.72

var _heat: float = 0.25
var _doneness: float = 0.0
var _burn: float = 0.0
var _flipped: bool = false
var _flip_count: int = 0
var _total_good_heat_time: float = 0.0
var _elapsed: float = 0.0
var _flip_skill: float = 0.0

var _heat_bar: ProgressBar
var _done_bar: ProgressBar
var _burn_bar: ProgressBar
var _lbl_timer: Label
var _lbl_status: Label
var _lbl_instruction: Label
var _result_label: Label
var _flame_label: Label
var _food_label: Label

func _on_init() -> void:
	_heat = 0.25
	_doneness = 0.0
	_burn = 0.0
	_flipped = false
	_flip_count = 0
	_total_good_heat_time = 0.0
	_elapsed = 0.0

	var bg = make_panel_bg(Vector2(640, 720))
	add_child(bg)

	var title = make_label("🍳  IPRITO!  (Fry!)", 22, Color(1.0, 0.87, 0.3))
	title.position = Vector2(20, 14)
	add_child(title)

	_lbl_instruction = make_label(step_data.get("instruction", ""), 13, Color(0.95, 0.92, 0.82))
	_lbl_instruction.position = Vector2(20, 50)
	_lbl_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_instruction.custom_minimum_size.x = 600
	add_child(_lbl_instruction)

	# Pan visual area
	var pan_bg = ColorRect.new()
	pan_bg.color = Color(0.22, 0.20, 0.22)
	pan_bg.size = Vector2(220, 120)
	pan_bg.position = Vector2(210, 160)
	add_child(pan_bg)

	_flame_label = make_label("🔥", 36, Color(1, 0.6, 0.1))
	_flame_label.position = Vector2(280, 265)
	add_child(_flame_label)

	_food_label = make_label("🥩", 42, Color(1, 1, 1))
	_food_label.position = Vector2(278, 180)
	add_child(_food_label)

	# Heat bar
	var hlbl = make_label("HEAT  (↑ UP / ↓ DOWN):", 13, Color(0.9, 0.9, 0.9))
	hlbl.position = Vector2(20, 360)
	add_child(hlbl)

	_heat_bar = make_progress_bar(100.0, Color(0.9, 0.4, 0.1))
	_heat_bar.position = Vector2(20, 385)
	_heat_bar.custom_minimum_size = Vector2(420, 20)
	add_child(_heat_bar)

	# Sweet spot overlay on heat bar
	var ss = ColorRect.new()
	ss.color = Color(0.2, 1.0, 0.3, 0.35)
	ss.size = Vector2(int(420 * (TARGET_HEAT_MAX - TARGET_HEAT_MIN)), 20)
	ss.position = Vector2(20 + int(420 * TARGET_HEAT_MIN), 385)
	add_child(ss)

	var ss_lbl = make_label("IDEAL HEAT ZONE", 9, Color(0.2, 1.0, 0.3))
	ss_lbl.position = Vector2(ss.position.x, 407)
	add_child(ss_lbl)

	# Doneness bar
	var dlbl = make_label("DONENESS:", 13, Color(0.9, 0.9, 0.9))
	dlbl.position = Vector2(20, 430)
	add_child(dlbl)

	_done_bar = make_progress_bar(100.0, Color(0.8, 0.55, 0.1))
	_done_bar.position = Vector2(20, 455)
	_done_bar.custom_minimum_size = Vector2(420, 20)
	add_child(_done_bar)

	# Flip window markers on doneness bar
	var fw = ColorRect.new()
	fw.color = Color(0.3, 0.8, 1.0, 0.35)
	fw.size = Vector2(int(420 * (FLIP_WINDOW_MAX - FLIP_WINDOW_MIN)), 20)
	fw.position = Vector2(20 + int(420 * FLIP_WINDOW_MIN), 455)
	add_child(fw)

	var fw_lbl = make_label("FLIP ZONE", 9, Color(0.3, 0.8, 1.0))
	fw_lbl.position = Vector2(fw.position.x, 477)
	add_child(fw_lbl)

	# Burn bar
	var blbl = make_label("BURN:", 13, Color(0.9, 0.4, 0.1))
	blbl.position = Vector2(20, 500)
	add_child(blbl)

	_burn_bar = make_progress_bar(100.0, Color(0.9, 0.15, 0.1))
	_burn_bar.position = Vector2(20, 520)
	_burn_bar.custom_minimum_size = Vector2(420, 14)
	add_child(_burn_bar)

	_lbl_status = make_label("Keep heat in the green zone!", 16, Color(1, 0.9, 0.2))
	_lbl_status.position = Vector2(20, 560)
	add_child(_lbl_status)

	var prompt = make_label("↑/↓ Heat   SPACE/E = Flip", 14, Color(0.75, 0.75, 0.75))
	prompt.position = Vector2(20, 600)
	add_child(prompt)

	_lbl_timer = make_label("Time: %.1f" % _time_limit, 15, Color(1.0, 0.6, 0.3))
	_lbl_timer.position = Vector2(500, 14)
	add_child(_lbl_timer)

	_result_label = make_label("", 22, Color(1, 0.85, 0.1))
	_result_label.position = Vector2(200, 660)
	_result_label.visible = false
	add_child(_result_label)

func _on_update(delta: float, _remaining: float) -> void:
	_elapsed += delta

	# Heat control
	if Input.is_action_pressed("move_up"):
		_heat = minf(1.0, _heat + HEAT_UP_RATE * delta)
	if Input.is_action_pressed("move_down"):
		_heat = maxf(0.0, _heat - HEAT_DOWN_RATE * delta)

	# Natural heat drift down
	_heat = maxf(0.0, _heat - HEAT_DRIFT * delta)

	# Doneness / burn
	if _heat >= TARGET_HEAT_MIN and _heat <= TARGET_HEAT_MAX:
		_doneness = minf(1.0, _doneness + DONENESS_RATE * delta)
		_total_good_heat_time += delta
	elif _heat > TARGET_HEAT_MAX:
		_doneness = minf(1.0, _doneness + DONENESS_RATE * 0.5 * delta)
		_burn = minf(1.0, _burn + BURN_RATE * delta)

	_heat_bar.value = _heat * 100.0
	_done_bar.value = _doneness * 100.0
	_burn_bar.value = _burn * 100.0

	# Flame feedback
	if _heat > TARGET_HEAT_MAX:
		_lbl_status.text = "🔥 Too hot! Lower the heat!"
		_lbl_status.add_theme_color_override("font_color", Color(1, 0.2, 0.1))
		_flame_label.text = "🔥🔥"
	elif _heat < TARGET_HEAT_MIN:
		_lbl_status.text = "❄️ Too cold! Raise the heat!"
		_lbl_status.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
		_flame_label.text = ""
	else:
		_lbl_status.text = "✅ Perfect heat – keep it there!"
		_lbl_status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		_flame_label.text = "🔥"

	if _burn >= 1.0:
		_result_label.text = "💀 Nasunog! (Burned!)"
		_result_label.visible = true
		complete_minigame(0.05)
		return

	# Flip
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
		if not _flipped and _doneness >= FLIP_WINDOW_MIN:
			_flipped = true
			_flip_count += 1
			_flip_skill = 1.0 - absf(_doneness - 0.55) * 2.0
			_food_label.text = "🥩✨"
			_lbl_status.text = "🎉 Great flip! Keep cooking!"
		elif _flipped and _doneness >= 0.85:
			# Done after second side
			var heat_skill = _total_good_heat_time / _elapsed
			var skill = (_flip_skill * 0.5 + heat_skill * 0.4 + (1.0 - _burn) * 0.1)
			_result_label.text = "✨ Luto na! (Done!) ✨"
			_result_label.visible = true
			complete_minigame(clampf(skill, 0.0, 1.0))

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)
		if remaining < 5.0:
			_lbl_timer.add_theme_color_override("font_color", Color(1, 0.2, 0.2))

func _force_finish() -> void:
	var heat_skill = _total_good_heat_time / maxf(1.0, _elapsed)
	var skill = heat_skill * 0.7 + (_flip_skill * 0.3 if _flipped else 0.0)
	complete_minigame(clampf(skill * (_doneness), 0.0, 1.0))
