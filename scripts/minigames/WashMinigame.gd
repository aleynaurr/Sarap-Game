extends MinigameBase

# Wash minigame: alternate Left/Right arrow (or A/D) to scrub the ingredient.
# A "dirt meter" fills down as you scrub. Skill = how clean you got it.

const SCRUB_NEEDED   := 30      # total scrubs required for 100%
const SCRUB_PER_GOOD := 1.0     # progress per correct alternation
const PENALTY        := 0.5     # penalty for wrong direction

var _scrubs_done: float = 0.0
var _last_dir: int = 0           # -1 left, 1 right, 0 none
var _expect_right: bool = true

# UI nodes created in _on_init
var _lbl_instruction: Label
var _lbl_timer: Label
var _lbl_prompt: Label
var _progress_bar: ProgressBar
var _ingredient_label: Label
var _dirt_overlay: ColorRect
var _result_label: Label
var _lbl_scrubs: Label

func _on_init() -> void:
	_scrubs_done = 0.0
	_expect_right = true
	_last_dir = 0

	# Background
	var bg = make_panel_bg(Vector2(640, 720))
	add_child(bg)

	# Title banner
	var title = make_label("🚿  HUGASAN!  (Wash!)", 22, Color(1.0, 0.87, 0.3))
	title.position = Vector2(20, 14)
	add_child(title)

	# Instruction
	_lbl_instruction = make_label(step_data.get("instruction", ""), 13, Color(0.95, 0.92, 0.82))
	_lbl_instruction.position = Vector2(20, 50)
	_lbl_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_instruction.custom_minimum_size.x = 600
	add_child(_lbl_instruction)

	# Ingredient icons (just draw their names for now)
	var ingr_list = step_data.get("ingredients", [])
	_ingredient_label = make_label("Ingredients: " + ", ".join(ingr_list), 11, Color(0.75, 0.88, 0.75))
	_ingredient_label.position = Vector2(20, 95)
	add_child(_ingredient_label)

	# Main visual: a big soap-bubble region
	var soap_bg = ColorRect.new()
	soap_bg.color = Color(0.55, 0.75, 0.92, 0.5)
	soap_bg.size = Vector2(260, 180)
	soap_bg.position = Vector2(190, 200)
	add_child(soap_bg)

	_dirt_overlay = ColorRect.new()
	_dirt_overlay.color = Color(0.48, 0.34, 0.22, 0.75)
	_dirt_overlay.size = Vector2(256, 176)
	_dirt_overlay.position = Vector2(192, 202)
	add_child(_dirt_overlay)

	var soap_lbl = make_label("🧼", 48, Color(1, 1, 1))
	soap_lbl.position = Vector2(280, 240)
	add_child(soap_lbl)

	# Arrow prompt
	_lbl_prompt = make_label("← Press →", 28, Color(1, 0.9, 0.1))
	_lbl_prompt.position = Vector2(220, 460)
	add_child(_lbl_prompt)

	# Progress
	var pb_lbl = make_label("Cleanliness:", 13, Color(0.9, 0.9, 0.9))
	pb_lbl.position = Vector2(20, 530)
	add_child(pb_lbl)

	_progress_bar = make_progress_bar(float(SCRUB_NEEDED), Color(0.35, 0.72, 0.35))
	_progress_bar.position = Vector2(20, 555)
	_progress_bar.custom_minimum_size = Vector2(300, 20)
	add_child(_progress_bar)

	_lbl_scrubs = make_label("0 / %d scrubs" % SCRUB_NEEDED, 12, Color(0.8, 0.8, 0.8))
	_lbl_scrubs.position = Vector2(330, 558)
	add_child(_lbl_scrubs)

	# Timer
	_lbl_timer = make_label("Time: %.1f" % _time_limit, 15, Color(1.0, 0.6, 0.3))
	_lbl_timer.position = Vector2(500, 14)
	add_child(_lbl_timer)

	_result_label = make_label("", 22, Color(1, 0.85, 0.1))
	_result_label.position = Vector2(200, 630)
	_result_label.visible = false
	add_child(_result_label)

	# Controls hint
	var hint = make_label("Alternate  A / D  or  ← →  keys to scrub!", 11, Color(0.65, 0.65, 0.65))
	hint.position = Vector2(20, 690)
	add_child(hint)

func _on_update(_delta: float, _remaining: float) -> void:
	# Read input
	var pressed_right = Input.is_action_just_pressed("move_right")
	var pressed_left  = Input.is_action_just_pressed("move_left")

	if pressed_right or pressed_left:
		var dir = 1 if pressed_right else -1
		if dir == (_last_dir * -1) or _last_dir == 0:
			# Correct alternation
			_scrubs_done += SCRUB_PER_GOOD
			_last_dir = dir
			AudioManager.play_sfx(AudioManager.SFX_SPLASH)
		else:
			# Same direction repeated
			_scrubs_done = maxf(0.0, _scrubs_done - PENALTY)

		_progress_bar.value = _scrubs_done
		_lbl_scrubs.text = "%d / %d scrubs" % [int(_scrubs_done), SCRUB_NEEDED]

		# Update dirt overlay alpha
		var clean_ratio = _scrubs_done / float(SCRUB_NEEDED)
		_dirt_overlay.color.a = 0.75 * (1.0 - clean_ratio)

		# Update arrow prompt
		_expect_right = (_last_dir != 1)
		if _expect_right:
			_lbl_prompt.text = "→  Press  →"
		else:
			_lbl_prompt.text = "←  Press  ←"

		if _scrubs_done >= SCRUB_NEEDED:
			_scrubs_done = float(SCRUB_NEEDED)
			_result_label.text = "✨ Malinis na! (Clean!) ✨"
			_result_label.visible = true
			complete_minigame(1.0)

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)
		if remaining < 5.0:
			_lbl_timer.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
