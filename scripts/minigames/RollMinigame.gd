extends MinigameBase
# Roll: press a sequence of arrow keys shown on screen (like a QTE).
# Good for Lumpiang Shanghai rolling step.

const SEQUENCE_LENGTH := 12
const INPUT_TIMEOUT   := 2.0   # seconds to press each key

var _sequence: Array = []
var _current_idx: int = 0
var _correct_hits: int = 0
var _missed: int = 0
var _step_timer: float = 0.0

var _lbl_timer: Label
var _lbl_progress: Label
var _result_label: Label
var _lbl_instruction: Label
var _lbl_status: Label
var _arrow_displays: Array = []
var _step_bar: ProgressBar
var _roll_visual: ColorRect
var _flash_t: float = 0.0
var _roll_width: float = 0.0

const DIR_ICONS = {0: "↑", 1: "→", 2: "↓", 3: "←"}
const ACTIONS   = {0: "move_up", 1: "move_right", 2: "move_down", 3: "move_left"}

func _on_init() -> void:
	_current_idx = 0
	_correct_hits = 0
	_missed = 0
	_step_timer = 0.0
	_roll_width = 0.0
	_generate_sequence()

	var bg = make_panel_bg(Vector2(640, 720))
	add_child(bg)

	var title = make_label("🌯  IROLYO!  (Roll!)", 22, Color(1.0, 0.87, 0.3))
	title.position = Vector2(20, 14)
	add_child(title)

	_lbl_instruction = make_label(step_data.get("instruction", ""), 13, Color(0.95, 0.92, 0.82))
	_lbl_instruction.position = Vector2(20, 50)
	_lbl_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_instruction.custom_minimum_size.x = 600
	add_child(_lbl_instruction)

	# Lumpia roll visual (grows as you complete steps)
	var roll_bg = ColorRect.new()
	roll_bg.color = Color(0.82, 0.75, 0.60)
	roll_bg.size = Vector2(380, 50)
	roll_bg.position = Vector2(130, 165)
	add_child(roll_bg)

	_roll_visual = ColorRect.new()
	_roll_visual.color = Color(0.78, 0.55, 0.28)
	_roll_visual.size = Vector2(0, 50)
	_roll_visual.position = Vector2(130, 165)
	add_child(_roll_visual)

	var roll_lbl = make_label("🌯 ROLLING...", 18, Color(0.85, 0.65, 0.35))
	roll_lbl.position = Vector2(230, 225)
	add_child(roll_lbl)

	# Arrow display — show next 4 arrows
	var row_lbl = make_label("PRESS:", 16, Color(0.9, 0.9, 0.9))
	row_lbl.position = Vector2(20, 345)
	add_child(row_lbl)

	for i in range(4):
		var al = make_label("?", 32, Color(0.45, 0.45, 0.45))
		al.position = Vector2(80 + i * 80, 335)
		add_child(al)
		_arrow_displays.append(al)

	# Timing bar for current key
	var tb_lbl = make_label("Time per key:", 12, Color(0.8, 0.8, 0.8))
	tb_lbl.position = Vector2(20, 410)
	add_child(tb_lbl)

	_step_bar = make_progress_bar(INPUT_TIMEOUT, Color(0.9, 0.7, 0.1))
	_step_bar.position = Vector2(20, 430)
	_step_bar.custom_minimum_size = Vector2(350, 16)
	add_child(_step_bar)

	_lbl_status = make_label("Follow the arrows!", 20, Color(1, 0.9, 0.2))
	_lbl_status.position = Vector2(200, 480)
	add_child(_lbl_status)

	_lbl_progress = make_label("0 / %d" % SEQUENCE_LENGTH, 16, Color(0.9, 0.9, 0.9))
	_lbl_progress.position = Vector2(20, 540)
	add_child(_lbl_progress)

	_lbl_timer = make_label("Time: %.1f" % _time_limit, 15, Color(1.0, 0.6, 0.3))
	_lbl_timer.position = Vector2(500, 14)
	add_child(_lbl_timer)

	_result_label = make_label("", 22, Color(1, 0.85, 0.1))
	_result_label.position = Vector2(200, 600)
	_result_label.visible = false
	add_child(_result_label)

	_update_arrow_display()

func _generate_sequence() -> void:
	_sequence.clear()
	for i in range(SEQUENCE_LENGTH):
		_sequence.append(randi() % 4)

func _on_update(delta: float, _remaining: float) -> void:
	_step_timer += delta
	_step_bar.value = maxf(0.0, INPUT_TIMEOUT - _step_timer)

	if _step_timer >= INPUT_TIMEOUT:
		# Missed this key
		_missed += 1
		_current_idx += 1
		_step_timer = 0.0
		_lbl_status.text = "⏱️ Too slow!"
		_lbl_status.add_theme_color_override("font_color", Color(1, 0.3, 0.1))
		if _current_idx >= SEQUENCE_LENGTH:
			_finish_roll()
			return
		_update_arrow_display()

	# Check input
	for dir in range(4):
		if Input.is_action_just_pressed(ACTIONS[dir]):
			if dir == _sequence[_current_idx]:
				_correct_hits += 1
				_lbl_status.text = "✅ " + DIR_ICONS[dir] + " !"
				_lbl_status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
			else:
				_missed += 1
				_lbl_status.text = "❌ Wrong! Expected " + DIR_ICONS[_sequence[_current_idx]]
				_lbl_status.add_theme_color_override("font_color", Color(1, 0.3, 0.1))
			_current_idx += 1
			_step_timer = 0.0
			_roll_width = float(_current_idx) / float(SEQUENCE_LENGTH) * 380.0
			_roll_visual.size.x = _roll_width
			_lbl_progress.text = "%d / %d" % [_current_idx, SEQUENCE_LENGTH]
			if _current_idx >= SEQUENCE_LENGTH:
				_finish_roll()
				return
			_update_arrow_display()
			break

func _update_arrow_display() -> void:
	for i in range(4):
		var seq_i = _current_idx + i
		if seq_i < _sequence.size():
			var icon = DIR_ICONS[_sequence[seq_i]]
			_arrow_displays[i].text = icon
			if i == 0:
				_arrow_displays[i].add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
			else:
				_arrow_displays[i].add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
		else:
			_arrow_displays[i].text = ""

func _finish_roll() -> void:
	var skill = float(_correct_hits) / float(SEQUENCE_LENGTH)
	if skill >= 0.9:
		_result_label.text = "✨ Perpekto! (Perfect Roll!) ✨"
	elif skill >= 0.6:
		_result_label.text = "👍 Maganda! (Nice Roll!)"
	else:
		_result_label.text = "😅 Medyo maluwag (Loose roll)"
	_result_label.visible = true
	complete_minigame(skill)

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)
		if remaining < 5.0:
			_lbl_timer.add_theme_color_override("font_color", Color(1, 0.2, 0.2))

func _force_finish() -> void:
	var skill = float(_correct_hits) / float(max(1, _current_idx))
	complete_minigame(clampf(skill * float(_current_idx) / float(SEQUENCE_LENGTH), 0.0, 1.0))
