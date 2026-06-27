extends MinigameBase
# Crack Egg: press LEFT+RIGHT together at the right moment (when indicator is in zone).
# A pendulum swings left-right. Hit at center = perfect crack, no shell.
# Miss or hit edge = shell fragments (skill penalty).

const EGGS_TO_CRACK  := 3
const PENDULUM_SPEED := 2.2      # radians per second
const PERFECT_ZONE   := 0.18    # ±ratio around center for perfect
const GOOD_ZONE      := 0.35

var _cracked: int = 0
var _pendulum_angle: float = 0.0   # -1..1 normalized
var _direction: float = 1.0
var _total_skill: float = 0.0
var _shell_count: int = 0

var _lbl_timer: Label
var _lbl_cracked: Label
var _result_label: Label
var _lbl_instruction: Label
var _lbl_status: Label
var _pendulum_indicator: ColorRect
var _bowl_label: Label

func _on_init() -> void:
	_cracked = 0
	_pendulum_angle = -1.0
	_direction = 1.0
	_total_skill = 0.0
	_shell_count = 0

	var bg = make_panel_bg(Vector2(640, 720))
	add_child(bg)

	var title = make_label("🥚  BASAGIN!  (Crack!)", 22, Color(1.0, 0.87, 0.3))
	title.position = Vector2(20, 14)
	add_child(title)

	_lbl_instruction = make_label(step_data.get("instruction", ""), 13, Color(0.95, 0.92, 0.82))
	_lbl_instruction.position = Vector2(20, 50)
	_lbl_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_instruction.custom_minimum_size.x = 600
	add_child(_lbl_instruction)

	# Bowl visual
	var bowl_bg = ColorRect.new()
	bowl_bg.color = Color(0.86, 0.82, 0.72)
	bowl_bg.size = Vector2(200, 80)
	bowl_bg.position = Vector2(220, 280)
	add_child(bowl_bg)

	_bowl_label = make_label("🥣", 52, Color(1, 1, 1))
	_bowl_label.position = Vector2(275, 275)
	add_child(_bowl_label)

	# Pendulum track
	var track_bg = ColorRect.new()
	track_bg.color = Color(0.18, 0.15, 0.14)
	track_bg.size = Vector2(420, 30)
	track_bg.position = Vector2(110, 200)
	add_child(track_bg)

	# Perfect zone marker
	var pz = ColorRect.new()
	pz.color = Color(0.2, 1.0, 0.3, 0.4)
	pz.size = Vector2(int(420 * PERFECT_ZONE * 2), 30)
	pz.position = Vector2(110 + int(420 * (0.5 - PERFECT_ZONE)), 200)
	add_child(pz)

	var pz_lbl = make_label("PERFECT", 9, Color(0.2, 1.0, 0.3))
	pz_lbl.position = Vector2(pz.position.x + 4, 232)
	add_child(pz_lbl)

	# Good zone marker
	var gz = ColorRect.new()
	gz.color = Color(0.9, 0.8, 0.1, 0.2)
	gz.size = Vector2(int(420 * GOOD_ZONE * 2), 30)
	gz.position = Vector2(110 + int(420 * (0.5 - GOOD_ZONE)), 200)
	add_child(gz)

	# Pendulum indicator (moves left-right on the track)
	_pendulum_indicator = ColorRect.new()
	_pendulum_indicator.color = Color(1.0, 0.9, 0.2)
	_pendulum_indicator.size = Vector2(16, 30)
	_pendulum_indicator.position = Vector2(110, 200)
	add_child(_pendulum_indicator)

	_lbl_status = make_label("Wait for the center...", 18, Color(1, 0.9, 0.2))
	_lbl_status.position = Vector2(180, 400)
	add_child(_lbl_status)

	_lbl_cracked = make_label("Eggs cracked: 0 / %d" % EGGS_TO_CRACK, 16, Color(0.9, 0.9, 0.9))
	_lbl_cracked.position = Vector2(20, 470)
	add_child(_lbl_cracked)

	var shell_lbl = make_label("Shell fragments in bowl:", 13, Color(0.8, 0.6, 0.4))
	shell_lbl.position = Vector2(20, 510)
	add_child(shell_lbl)

	var shell_hint = make_label("(Fewer shells = higher score)", 11, Color(0.6, 0.6, 0.6))
	shell_hint.position = Vector2(240, 513)
	add_child(shell_hint)

	var prompt = make_label("Press  SPACE / E  when indicator is in the center!", 16, Color(1, 0.85, 0.1))
	prompt.position = Vector2(100, 570)
	add_child(prompt)

	_lbl_timer = make_label("Time: %.1f" % _time_limit, 15, Color(1.0, 0.6, 0.3))
	_lbl_timer.position = Vector2(500, 14)
	add_child(_lbl_timer)

	_result_label = make_label("", 22, Color(1, 0.85, 0.1))
	_result_label.position = Vector2(200, 650)
	_result_label.visible = false
	add_child(_result_label)

func _on_update(delta: float, _remaining: float) -> void:
	# Advance pendulum
	_pendulum_angle += _direction * PENDULUM_SPEED * delta
	if _pendulum_angle >= 1.0:
		_pendulum_angle = 1.0
		_direction = -1.0
	elif _pendulum_angle <= -1.0:
		_pendulum_angle = -1.0
		_direction = 1.0

	# Position indicator: map -1..1 to track width
	var track_w = 420 - 16
	var t = (_pendulum_angle + 1.0) * 0.5   # 0..1
	_pendulum_indicator.position.x = 110 + int(track_w * t)

	# Check crack input
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
		_crack_egg()

func _crack_egg() -> void:
	var dist = absf(_pendulum_angle)   # 0 = center (perfect), 1 = edge
	var skill: float
	var msg: String
	if dist <= PERFECT_ZONE:
		skill = 1.0
		msg = "✨ PERFECT crack!"
		_lbl_status.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	elif dist <= GOOD_ZONE:
		skill = 0.6
		msg = "👍 Good crack!"
		_lbl_status.add_theme_color_override("font_color", Color(0.9, 0.8, 0.1))
		_shell_count += 1
	else:
		skill = 0.2
		msg = "💥 Shell fragments!"
		_lbl_status.add_theme_color_override("font_color", Color(1, 0.3, 0.1))
		_shell_count += 2

	_total_skill += skill
	_cracked += 1
	_lbl_status.text = msg
	_lbl_cracked.text = "Eggs cracked: %d / %d  (shells: %d)" % [_cracked, EGGS_TO_CRACK, _shell_count]
	AudioManager.play_sfx(AudioManager.SFX_CHOP)

	if _cracked >= EGGS_TO_CRACK:
		var avg_skill = _total_skill / float(EGGS_TO_CRACK)
		var shell_penalty = _shell_count * 0.08
		var final_skill = clampf(avg_skill - shell_penalty, 0.0, 1.0)
		_result_label.text = "🥚 Basag na! Done! (shells: %d)" % _shell_count
		_result_label.visible = true
		complete_minigame(final_skill)

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)
		if remaining < 5.0:
			_lbl_timer.add_theme_color_override("font_color", Color(1, 0.2, 0.2))

func _force_finish() -> void:
	var avg = _total_skill / float(max(1, _cracked))
	var ratio = float(_cracked) / float(EGGS_TO_CRACK)
	complete_minigame(avg * ratio)
