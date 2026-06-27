extends MinigameBase

# Chop minigame: press SPACE (or interact key) to chop.
# A rhythm bar pulses; hitting at peak gives bonus points.

const CHOPS_NEEDED   := 15
const BEAT_PERIOD    := 0.7     # seconds per beat
const PEAK_WINDOW    := 0.15    # seconds around peak for bonus

var _chops_done: int = 0
var _beat_timer: float = 0.0
var _beat_ratio: float = 0.0     # 0..1 within current beat
var _total_accuracy: float = 0.0

var _lbl_timer: Label
var _lbl_chops: Label
var _lbl_prompt: Label
var _beat_bar: ProgressBar
var _chop_flash: ColorRect
var _flash_timer: float = 0.0
var _result_label: Label
var _lbl_instruction: Label

func _on_init() -> void:
	_chops_done = 0
	_beat_timer = 0.0
	_total_accuracy = 0.0

	var bg = make_panel_bg(Vector2(640, 720))
	add_child(bg)

	var title = make_label("🔪  TADTARIN!  (Chop!)", 22, Color(1.0, 0.87, 0.3))
	title.position = Vector2(20, 14)
	add_child(title)

	_lbl_instruction = make_label(step_data.get("instruction", ""), 13, Color(0.95, 0.92, 0.82))
	_lbl_instruction.position = Vector2(20, 50)
	_lbl_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_instruction.custom_minimum_size.x = 600
	add_child(_lbl_instruction)

	# Cutting board visual
	var board = ColorRect.new()
	board.color = Color(0.71, 0.51, 0.31)
	board.size = Vector2(300, 180)
	board.position = Vector2(170, 160)
	add_child(board)

	# Chop flash overlay (flashes on hit)
	_chop_flash = ColorRect.new()
	_chop_flash.color = Color(1, 1, 1, 0.0)
	_chop_flash.size = Vector2(300, 180)
	_chop_flash.position = Vector2(170, 160)
	add_child(_chop_flash)

	var knife_lbl = make_label("🔪", 60, Color(0.8, 0.85, 0.9))
	knife_lbl.position = Vector2(280, 180)
	add_child(knife_lbl)

	# Beat bar
	var beat_lbl = make_label("BEAT →", 13, Color(0.8, 0.8, 0.8))
	beat_lbl.position = Vector2(20, 440)
	add_child(beat_lbl)

	_beat_bar = make_progress_bar(100.0, Color(0.9, 0.7, 0.1))
	_beat_bar.position = Vector2(20, 465)
	_beat_bar.custom_minimum_size = Vector2(400, 22)
	add_child(_beat_bar)

	# Sweet spot indicator
	var ss = ColorRect.new()
	ss.color = Color(0.2, 1.0, 0.3, 0.6)
	ss.size = Vector2(int(400 * PEAK_WINDOW * 2 / BEAT_PERIOD), 22)
	ss.position = Vector2(20 + int(400 * (0.5 - PEAK_WINDOW / BEAT_PERIOD)), 465)
	add_child(ss)

	var ss_lbl = make_label("SWEET SPOT", 9, Color(0.2, 1.0, 0.3))
	ss_lbl.position = Vector2(ss.position.x, 489)
	add_child(ss_lbl)

	_lbl_prompt = make_label("SPACE / E  to CHOP!", 26, Color(1, 0.9, 0.2))
	_lbl_prompt.position = Vector2(200, 530)
	add_child(_lbl_prompt)

	_lbl_chops = make_label("0 / %d chops" % CHOPS_NEEDED, 15, Color(0.9, 0.9, 0.9))
	_lbl_chops.position = Vector2(20, 590)
	add_child(_lbl_chops)

	_lbl_timer = make_label("Time: %.1f" % _time_limit, 15, Color(1.0, 0.6, 0.3))
	_lbl_timer.position = Vector2(500, 14)
	add_child(_lbl_timer)

	_result_label = make_label("", 22, Color(1, 0.85, 0.1))
	_result_label.position = Vector2(210, 640)
	_result_label.visible = false
	add_child(_result_label)

	var hint = make_label("Press SPACE or E on the beat for bonus accuracy!", 11, Color(0.6, 0.6, 0.6))
	hint.position = Vector2(20, 695)
	add_child(hint)

func _on_update(delta: float, _remaining: float) -> void:
	_beat_timer += delta
	if _beat_timer >= BEAT_PERIOD:
		_beat_timer -= BEAT_PERIOD
	_beat_ratio = _beat_timer / BEAT_PERIOD
	_beat_bar.value = _beat_ratio * 100.0

	# Flash decay
	if _flash_timer > 0.0:
		_flash_timer -= delta
		_chop_flash.color.a = _flash_timer * 3.0

	# Check chop input
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
		_do_chop()

func _do_chop() -> void:
	_chops_done += 1
	AudioManager.play_sfx(AudioManager.SFX_CHOP)

	# Accuracy based on distance from beat peak (0.5)
	var dist_from_peak = abs(_beat_ratio - 0.5)
	var accuracy = 1.0 - clampf(dist_from_peak / (BEAT_PERIOD * 0.5), 0.0, 1.0)
	_total_accuracy += accuracy

	_chop_flash.color.a = 0.6
	_flash_timer = 0.2

	_lbl_chops.text = "%d / %d chops" % [_chops_done, CHOPS_NEEDED]

	if _chops_done >= CHOPS_NEEDED:
		var skill = _total_accuracy / float(CHOPS_NEEDED)
		_result_label.text = "✨ Tadtad na! (Chopped!) ✨"
		_result_label.visible = true
		complete_minigame(skill)

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)
		if remaining < 5.0:
			_lbl_timer.add_theme_color_override("font_color", Color(1, 0.2, 0.2))

func _force_finish() -> void:
	var skill = _total_accuracy / float(max(1, _chops_done)) if _chops_done > 0 else 0.0
	complete_minigame(skill * (_chops_done / float(CHOPS_NEEDED)))
