extends MinigameBase
# Mix: make circular motions with WASD (up→right→down→left→up).
# Track direction transitions to count complete circles.

const CIRCLES_NEEDED := 6

# Direction states: 0=up, 1=right, 2=down, 3=left
# Rotating clockwise: 0→1→2→3→0
var _dir_seq: Array = [0, 1, 2, 3]
var _seq_pos: int = 0          # next expected step in rotation
var _circles_done: int = 0
var _total_smoothness: float = 0.0
var _last_input_time: float = 0.0
var _holding: int = -1   # which dir is currently held

var _lbl_timer: Label
var _lbl_circles: Label
var _result_label: Label
var _lbl_instruction: Label
var _lbl_status: Label
var _arrow_labels: Array = []

func _on_init() -> void:
	_seq_pos = 0
	_circles_done = 0
	_total_smoothness = 0.0
	_holding = -1

	var bg = make_panel_bg(Vector2(640, 720))
	add_child(bg)

	var title = make_label("🥣  HALUIN!  (Mix!)", 22, Color(1.0, 0.87, 0.3))
	title.position = Vector2(20, 14)
	add_child(title)

	_lbl_instruction = make_label(step_data.get("instruction", ""), 13, Color(0.95, 0.92, 0.82))
	_lbl_instruction.position = Vector2(20, 50)
	_lbl_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_instruction.custom_minimum_size.x = 600
	add_child(_lbl_instruction)

	# Bowl visual
	var bowl_bg = ColorRect.new()
	bowl_bg.color = Color(0.84, 0.80, 0.70)
	bowl_bg.size = Vector2(180, 120)
	bowl_bg.position = Vector2(230, 160)
	add_child(bowl_bg)

	var bowl_emoji = make_label("🥣", 55, Color(1, 1, 1))
	bowl_emoji.position = Vector2(280, 160)
	add_child(bowl_emoji)

	# Circular arrow guide
	var guide_lbl = make_label("Rotate clockwise with WASD:", 15, Color(0.9, 0.9, 0.9))
	guide_lbl.position = Vector2(20, 360)
	add_child(guide_lbl)

	# Direction indicators: Up Right Down Left
	var dirs = ["↑ (W)", "→ (D)", "↓ (S)", "← (A)"]
	var positions = [Vector2(300, 380), Vector2(380, 415), Vector2(300, 445), Vector2(200, 415)]
	for i in range(4):
		var lbl = make_label(dirs[i], 18, Color(0.55, 0.55, 0.55))
		lbl.position = positions[i]
		add_child(lbl)
		_arrow_labels.append(lbl)

	_lbl_status = make_label("Start with  ↑ W  !", 20, Color(1, 0.9, 0.2))
	_lbl_status.position = Vector2(200, 530)
	add_child(_lbl_status)

	_lbl_circles = make_label("Circles: 0 / %d" % CIRCLES_NEEDED, 16, Color(0.9, 0.9, 0.9))
	_lbl_circles.position = Vector2(20, 590)
	add_child(_lbl_circles)

	_lbl_timer = make_label("Time: %.1f" % _time_limit, 15, Color(1.0, 0.6, 0.3))
	_lbl_timer.position = Vector2(500, 14)
	add_child(_lbl_timer)

	_result_label = make_label("", 22, Color(1, 0.85, 0.1))
	_result_label.position = Vector2(200, 660)
	_result_label.visible = false
	add_child(_result_label)

	var hint = make_label("Hold each direction in order: W → D → S → A → repeat", 12, Color(0.6, 0.6, 0.6))
	hint.position = Vector2(20, 695)
	add_child(hint)

	_highlight_step()

func _on_update(_delta: float, _remaining: float) -> void:
	# Detect currently held direction (only one at a time)
	var held = -1
	if Input.is_action_pressed("move_up"):    held = 0
	elif Input.is_action_pressed("move_right"): held = 1
	elif Input.is_action_pressed("move_down"):  held = 2
	elif Input.is_action_pressed("move_left"):  held = 3

	if held != _holding:
		_holding = held
		if held == _dir_seq[_seq_pos]:
			# Correct next step
			var t_since_last = Time.get_ticks_msec() / 1000.0 - _last_input_time
			var smoothness = clampf(1.0 - t_since_last * 0.3, 0.2, 1.0)
			_total_smoothness += smoothness
			_last_input_time = Time.get_ticks_msec() / 1000.0
			_seq_pos = (_seq_pos + 1) % 4
			if _seq_pos == 0:
				_circles_done += 1
				_lbl_circles.text = "Circles: %d / %d" % [_circles_done, CIRCLES_NEEDED]
				AudioManager.play_sfx(AudioManager.SFX_SPLASH)
				if _circles_done >= CIRCLES_NEEDED:
					var skill = _total_smoothness / float(CIRCLES_NEEDED * 4)
					_result_label.text = "✨ Halo na! (Mixed!) ✨"
					_result_label.visible = true
					complete_minigame(clampf(skill, 0.0, 1.0))
					return
			_highlight_step()
		elif held != -1:
			# Wrong direction
			_lbl_status.text = "Wrong direction! Reset..."
			_seq_pos = 0
			_highlight_step()

func _highlight_step() -> void:
	for i in range(4):
		if i == _dir_seq[_seq_pos]:
			_arrow_labels[i].add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
			_lbl_status.text = "Now: " + ["↑ W (Up)", "→ D (Right)", "↓ S (Down)", "← A (Left)"][_dir_seq[_seq_pos]]
		else:
			_arrow_labels[i].add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)
		if remaining < 5.0:
			_lbl_timer.add_theme_color_override("font_color", Color(1, 0.2, 0.2))

func _force_finish() -> void:
	var skill = (_total_smoothness / float(max(1, _circles_done) * 4)) * (float(_circles_done) / float(CIRCLES_NEEDED))
	complete_minigame(clampf(skill, 0.0, 1.0))
