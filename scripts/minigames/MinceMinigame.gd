extends MinigameBase
# Mince: tap SPACE as fast as possible within the time limit.
# Skill is based on how many taps per second achieved vs a target.

const TARGET_TAPS := 40
const MAX_TAPS    := 55   # 100% skill

var _taps: int = 0
var _lbl_timer: Label
var _lbl_taps: Label
var _progress_bar: ProgressBar
var _result_label: Label
var _lbl_instruction: Label
var _frenzy_label: Label
var _flash: ColorRect
var _flash_t: float = 0.0

func _on_init() -> void:
	_taps = 0

	var bg = make_panel_bg(Vector2(640, 720))
	add_child(bg)

	var title = make_label("🔪🔪  DURUGIN!  (Mince!)", 22, Color(1.0, 0.87, 0.3))
	title.position = Vector2(20, 14)
	add_child(title)

	_lbl_instruction = make_label(step_data.get("instruction", ""), 13, Color(0.95, 0.92, 0.82))
	_lbl_instruction.position = Vector2(20, 50)
	_lbl_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_instruction.custom_minimum_size.x = 600
	add_child(_lbl_instruction)

	# Mince board visual
	var board = ColorRect.new()
	board.color = Color(0.68, 0.48, 0.28)
	board.size = Vector2(320, 160)
	board.position = Vector2(160, 170)
	add_child(board)

	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 0.5, 0.0)
	_flash.size = Vector2(320, 160)
	_flash.position = Vector2(160, 170)
	add_child(_flash)

	_frenzy_label = make_label("TAP FASTER!", 34, Color(1, 0.3, 0.1))
	_frenzy_label.position = Vector2(195, 210)
	_frenzy_label.visible = false
	add_child(_frenzy_label)

	var mince_emoji = make_label("🔪", 50, Color(0.8, 0.85, 0.9))
	mince_emoji.position = Vector2(290, 180)
	add_child(mince_emoji)

	var pb_lbl = make_label("Progress:", 13, Color(0.9, 0.9, 0.9))
	pb_lbl.position = Vector2(20, 420)
	add_child(pb_lbl)

	_progress_bar = make_progress_bar(float(MAX_TAPS), Color(0.9, 0.55, 0.1))
	_progress_bar.position = Vector2(20, 445)
	_progress_bar.custom_minimum_size = Vector2(400, 22)
	add_child(_progress_bar)

	_lbl_taps = make_label("0 taps", 18, Color(1, 0.9, 0.5))
	_lbl_taps.position = Vector2(430, 445)
	add_child(_lbl_taps)

	var prompt = make_label("Mash  SPACE / E  as fast as you can!", 20, Color(1, 0.9, 0.2))
	prompt.position = Vector2(120, 520)
	add_child(prompt)

	_lbl_timer = make_label("Time: %.1f" % _time_limit, 15, Color(1.0, 0.6, 0.3))
	_lbl_timer.position = Vector2(500, 14)
	add_child(_lbl_timer)

	_result_label = make_label("", 22, Color(1, 0.85, 0.1))
	_result_label.position = Vector2(200, 610)
	_result_label.visible = false
	add_child(_result_label)

func _on_update(delta: float, _remaining: float) -> void:
	if _flash_t > 0.0:
		_flash_t -= delta
		_flash.color.a = _flash_t * 4.0

	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
		_taps += 1
		_flash.color.a = 0.5
		_flash_t = 0.12
		AudioManager.play_sfx(AudioManager.SFX_CHOP)
		_lbl_taps.text = "%d taps" % _taps
		_progress_bar.value = float(_taps)
		_frenzy_label.visible = _taps > TARGET_TAPS / 2

	if _taps >= MAX_TAPS:
		_result_label.text = "🔥 Durug na! (Minced!) 🔥"
		_result_label.visible = true
		complete_minigame(1.0)

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)
		if remaining < 5.0:
			_lbl_timer.add_theme_color_override("font_color", Color(1, 0.2, 0.2))

func _force_finish() -> void:
	var skill = clampf(float(_taps) / float(TARGET_TAPS), 0.0, 1.0)
	complete_minigame(skill)
