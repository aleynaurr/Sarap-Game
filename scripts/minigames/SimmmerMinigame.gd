extends MinigameBase
# Simmer: keep a boiling indicator in a sweet spot for the required duration.
# Too hot = boils over. Too cold = under-cooked.
# Press UP to raise heat, DOWN to lower. Must hold in range for TARGET_SIMMER_TIME.

const TARGET_HEAT_MIN := 0.42
const TARGET_HEAT_MAX := 0.68
const HEAT_DRIFT      := 0.03
const HEAT_UP_RATE    := 0.07
const HEAT_DOWN_RATE  := 0.07
const TARGET_SIMMER_TIME := 8.0   # seconds of good-heat time needed
const OVERFLOW_FILL   := 0.06     # how fast pot overflows when too hot

var _heat: float = 0.2
var _good_heat_time: float = 0.0
var _overflow: float = 0.0
var _elapsed: float = 0.0

var _heat_bar: ProgressBar
var _simmer_bar: ProgressBar
var _overflow_bar: ProgressBar
var _lbl_timer: Label
var _lbl_status: Label
var _result_label: Label
var _steam_label: Label
var _bubble_anim: float = 0.0

func _on_init() -> void:
	_heat = 0.2
	_good_heat_time = 0.0
	_overflow = 0.0
	_elapsed = 0.0

	var bg = make_panel_bg(Vector2(640, 720))
	add_child(bg)

	var title = make_label("🍲  PAKULUAN!  (Simmer!)", 22, Color(1.0, 0.87, 0.3))
	title.position = Vector2(20, 14)
	add_child(title)

	var inst = make_label(step_data.get("instruction", ""), 13, Color(0.95, 0.92, 0.82))
	inst.position = Vector2(20, 50)
	inst.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inst.custom_minimum_size.x = 600
	add_child(inst)

	# Pot visual
	var pot_bg = ColorRect.new()
	pot_bg.color = Color(0.28, 0.26, 0.30)
	pot_bg.size = Vector2(160, 130)
	pot_bg.position = Vector2(240, 155)
	add_child(pot_bg)

	_steam_label = make_label("", 28, Color(0.9, 0.9, 0.95, 0.8))
	_steam_label.position = Vector2(278, 120)
	add_child(_steam_label)

	var pot_lbl = make_label("🍲", 60, Color(1, 1, 1))
	pot_lbl.position = Vector2(269, 165)
	add_child(pot_lbl)

	# Heat bar
	var hlbl = make_label("HEAT  (↑ UP / ↓ DOWN):", 13, Color(0.9, 0.9, 0.9))
	hlbl.position = Vector2(20, 360)
	add_child(hlbl)

	_heat_bar = make_progress_bar(100.0, Color(0.9, 0.4, 0.1))
	_heat_bar.position = Vector2(20, 385)
	_heat_bar.custom_minimum_size = Vector2(420, 20)
	add_child(_heat_bar)

	# Sweet spot
	var ss = ColorRect.new()
	ss.color = Color(0.2, 1.0, 0.3, 0.35)
	ss.size = Vector2(int(420 * (TARGET_HEAT_MAX - TARGET_HEAT_MIN)), 20)
	ss.position = Vector2(20 + int(420 * TARGET_HEAT_MIN), 385)
	add_child(ss)

	var ss_lbl = make_label("SIMMER ZONE", 9, Color(0.2, 1.0, 0.3))
	ss_lbl.position = Vector2(ss.position.x, 407)
	add_child(ss_lbl)

	# Good-heat progress
	var slbl = make_label("SIMMER PROGRESS:", 13, Color(0.9, 0.9, 0.9))
	slbl.position = Vector2(20, 435)
	add_child(slbl)

	_simmer_bar = make_progress_bar(TARGET_SIMMER_TIME, Color(0.3, 0.6, 0.9))
	_simmer_bar.position = Vector2(20, 460)
	_simmer_bar.custom_minimum_size = Vector2(420, 20)
	add_child(_simmer_bar)

	# Overflow
	var olbl = make_label("OVERFLOW:", 13, Color(0.9, 0.3, 0.1))
	olbl.position = Vector2(20, 510)
	add_child(olbl)

	_overflow_bar = make_progress_bar(100.0, Color(0.95, 0.2, 0.1))
	_overflow_bar.position = Vector2(20, 535)
	_overflow_bar.custom_minimum_size = Vector2(420, 14)
	add_child(_overflow_bar)

	_lbl_status = make_label("Keep heat in the green zone!", 16, Color(1, 0.9, 0.2))
	_lbl_status.position = Vector2(20, 575)
	add_child(_lbl_status)

	var prompt = make_label("↑ increase heat   ↓ decrease heat", 13, Color(0.7, 0.7, 0.7))
	prompt.position = Vector2(20, 615)
	add_child(prompt)

	_lbl_timer = make_label("Time: %.1f" % _time_limit, 15, Color(1.0, 0.6, 0.3))
	_lbl_timer.position = Vector2(500, 14)
	add_child(_lbl_timer)

	_result_label = make_label("", 22, Color(1, 0.85, 0.1))
	_result_label.position = Vector2(200, 670)
	_result_label.visible = false
	add_child(_result_label)

func _on_update(delta: float, _remaining: float) -> void:
	_elapsed += delta
	_bubble_anim += delta

	# Heat control
	if Input.is_action_pressed("move_up"):
		_heat = minf(1.0, _heat + HEAT_UP_RATE * delta)
	if Input.is_action_pressed("move_down"):
		_heat = maxf(0.0, _heat - HEAT_DOWN_RATE * delta)
	_heat = maxf(0.0, _heat - HEAT_DRIFT * delta)

	_heat_bar.value = _heat * 100.0

	if _heat >= TARGET_HEAT_MIN and _heat <= TARGET_HEAT_MAX:
		_good_heat_time += delta
		_lbl_status.text = "✅ Perfect! Keep simmering..."
		_lbl_status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		# Animate steam
		_steam_label.text = "〰️〰️" if int(_bubble_anim * 3) % 2 == 0 else "〜〜〜"
	elif _heat > TARGET_HEAT_MAX:
		_overflow = minf(1.0, _overflow + OVERFLOW_FILL * delta)
		_lbl_status.text = "🔥 Too hot – lower the heat!"
		_lbl_status.add_theme_color_override("font_color", Color(1, 0.3, 0.1))
		_steam_label.text = "💨💨💨"
	else:
		_lbl_status.text = "❄️ Too cold – raise the heat!"
		_lbl_status.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
		_steam_label.text = ""

	_simmer_bar.value = _good_heat_time
	_overflow_bar.value = _overflow * 100.0

	if _overflow >= 1.0:
		_result_label.text = "💦 Umaapaw! (Overflowed!)"
		_result_label.visible = true
		complete_minigame(0.1)
		return

	if _good_heat_time >= TARGET_SIMMER_TIME:
		var skill = 1.0 - (_overflow * 0.5)
		_result_label.text = "✨ Luto na! (Cooked!) ✨"
		_result_label.visible = true
		complete_minigame(clampf(skill, 0.0, 1.0))

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)
		if remaining < 5.0:
			_lbl_timer.add_theme_color_override("font_color", Color(1, 0.2, 0.2))

func _force_finish() -> void:
	var skill = clampf(_good_heat_time / TARGET_SIMMER_TIME, 0.0, 1.0) * (1.0 - _overflow * 0.5)
	complete_minigame(skill)
