extends MinigameBase
# Prick & Season Eggplant: two phases.
# Phase 1 — prick the eggplant: mash SPACE/E rapidly (like MinceMinigame).
# Phase 2 — season: timing-bar drops for salt, pepper, oil (AddToBowl style).

const PRICKS_NEEDED := 12
const SEASON_ACTIONS := [
	{"label": "Rub salt all over the eggplant", "emoji": "🧂"},
	{"label": "Sprinkle black pepper", "emoji": "🫙"},
	{"label": "Brush with a little oil", "emoji": "🫒"},
]
const DROP_ZONE_MIN := 0.38
const DROP_ZONE_MAX := 0.62
const SWEEP_PERIOD := 1.0

enum Phase { PRICK, SEASON }
var _phase: Phase = Phase.PRICK
var _pricks: int = 0
var _action_idx: int = 0
var _sweep_t: float = 0.0
var _sweep_dir: int = 1
var _total_skill: float = 0.0
var _flash_t: float = 0.0

var _lbl_timer: Label
var _lbl_status: Label
var _lbl_phase: Label
var _result_label: Label
var _prick_bar: ProgressBar
var _flash: ColorRect
var _sweep_marker: ColorRect
var _drop_zone: ColorRect
var _lbl_action: Label
var _lbl_progress: Label
var _action_dots: Array = []
var _eggplant_label: Label

func _on_init() -> void:
	_phase = Phase.PRICK
	_pricks = 0
	_action_idx = 0
	_sweep_t = 0.0
	_sweep_dir = 1
	_total_skill = 0.0

	var bg = make_panel_bg(Vector2(640, 720))
	add_child(bg)

	var title = make_label("🍆  TUSUKAN AT TIMPLAHAN!  (Prick & Season!)", 17, Color(1.0, 0.87, 0.3))
	title.position = Vector2(20, 14)
	add_child(title)

	var inst = make_label(step_data.get("instruction", "Prick and season the eggplant!"), 13, Color(0.95, 0.92, 0.82))
	inst.position = Vector2(20, 50)
	inst.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inst.custom_minimum_size.x = 600
	add_child(inst)

	# Eggplant visual
	var eg_bg = ColorRect.new()
	eg_bg.color = Color(0.28, 0.13, 0.35)
	eg_bg.size = Vector2(180, 100)
	eg_bg.position = Vector2(230, 140)
	add_child(eg_bg)

	_eggplant_label = make_label("🍆", 60, Color(1, 1, 1))
	_eggplant_label.position = Vector2(273, 140)
	add_child(_eggplant_label)

	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0.0)
	_flash.size = Vector2(180, 100)
	_flash.position = Vector2(230, 140)
	add_child(_flash)

	_lbl_phase = make_label("PHASE 1: Prick the eggplant skin!", 18, Color(0.4, 0.85, 1.0))
	_lbl_phase.position = Vector2(20, 265)
	add_child(_lbl_phase)

	# Prick progress bar
	var pb_lbl = make_label("Pricks:", 13, Color(0.9, 0.9, 0.9))
	pb_lbl.position = Vector2(20, 300)
	add_child(pb_lbl)

	_prick_bar = make_progress_bar(float(PRICKS_NEEDED), Color(0.7, 0.3, 0.85))
	_prick_bar.position = Vector2(20, 322)
	_prick_bar.custom_minimum_size = Vector2(420, 22)
	add_child(_prick_bar)

	_lbl_status = make_label("Mash  SPACE / E  to prick!", 20, Color(1, 0.9, 0.2))
	_lbl_status.position = Vector2(160, 360)
	add_child(_lbl_status)

	# Season sweep bar (hidden in phase 1)
	var track_bg = ColorRect.new()
	track_bg.color = Color(0.18, 0.15, 0.14)
	track_bg.size = Vector2(440, 26)
	track_bg.position = Vector2(20, 415)
	track_bg.visible = false
	track_bg.name = "SweepBG"
	add_child(track_bg)

	_drop_zone = ColorRect.new()
	_drop_zone.color = Color(0.2, 1.0, 0.3, 0.4)
	_drop_zone.size = Vector2(440 * (DROP_ZONE_MAX - DROP_ZONE_MIN), 26)
	_drop_zone.position = Vector2(20 + 440 * DROP_ZONE_MIN, 415)
	_drop_zone.visible = false
	add_child(_drop_zone)

	_sweep_marker = ColorRect.new()
	_sweep_marker.color = Color(1.0, 0.9, 0.2)
	_sweep_marker.size = Vector2(8, 26)
	_sweep_marker.position = Vector2(20, 415)
	_sweep_marker.visible = false
	add_child(_sweep_marker)

	_lbl_action = make_label("", 18, Color(1, 0.9, 0.5))
	_lbl_action.position = Vector2(20, 455)
	_lbl_action.visible = false
	_lbl_action.name = "ActionLbl"
	add_child(_lbl_action)

	# Action dots
	var dots_row = HBoxContainer.new()
	dots_row.position = Vector2(20, 500)
	dots_row.add_theme_constant_override("separation", 8)
	dots_row.visible = false
	dots_row.name = "DotsRow"
	add_child(dots_row)
	for i in SEASON_ACTIONS.size():
		var dot = make_label("●", 18, Color(0.45, 0.45, 0.45))
		dots_row.add_child(dot)
		_action_dots.append(dot)

	_lbl_progress = make_label("", 13, Color(0.85, 0.85, 0.85))
	_lbl_progress.position = Vector2(20, 530)
	_lbl_progress.visible = false
	_lbl_progress.name = "ProgressLbl"
	add_child(_lbl_progress)

	_lbl_timer = make_label("Time: %.1f" % _time_limit, 15, Color(1.0, 0.6, 0.3))
	_lbl_timer.position = Vector2(500, 14)
	add_child(_lbl_timer)

	_result_label = make_label("", 22, Color(1, 0.85, 0.1))
	_result_label.position = Vector2(160, 640)
	_result_label.visible = false
	add_child(_result_label)

	var hint = make_label("Prepare the eggplant for grilling!", 12, Color(0.6, 0.6, 0.6))
	hint.position = Vector2(20, 695)
	add_child(hint)

func _on_update(delta: float, _remaining: float) -> void:
	if _flash_t > 0.0:
		_flash_t -= delta
		_flash.color.a = _flash_t * 3.0

	if _phase == Phase.PRICK:
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
			_pricks += 1
			_flash.color.a = 0.5
			_flash_t = 0.15
			AudioManager.play_sfx(AudioManager.SFX_CHOP)
			_prick_bar.value = float(_pricks)
			_lbl_status.text = "Pricks: %d / %d — Keep going!" % [_pricks, PRICKS_NEEDED]
			if _pricks >= PRICKS_NEEDED:
				_lbl_status.text = "✅ Pricked! Now season it."
				_lbl_status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
				_start_season_phase()
	else:
		_sweep_t += (delta / SWEEP_PERIOD) * _sweep_dir
		if _sweep_t >= 1.0: _sweep_t = 1.0; _sweep_dir = -1
		elif _sweep_t <= 0.0: _sweep_t = 0.0; _sweep_dir = 1
		_sweep_marker.position.x = 20 + (440 - 8) * _sweep_t
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
			_do_season_action()

func _start_season_phase() -> void:
	_phase = Phase.SEASON
	_lbl_phase.text = "PHASE 2: Season the eggplant!"
	_lbl_phase.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	_prick_bar.visible = false
	for nm in ["SweepBG", "ActionLbl", "DotsRow", "ProgressLbl"]:
		var n = get_node_or_null(nm)
		if n: n.visible = true
	_drop_zone.visible = true
	_sweep_marker.visible = true
	_load_season_action()

func _load_season_action() -> void:
	if _action_idx >= SEASON_ACTIONS.size(): return
	var action = SEASON_ACTIONS[_action_idx]
	_lbl_action.text = "👉 " + action.get("label", "")
	_lbl_progress.text = "Action %d / %d" % [_action_idx + 1, SEASON_ACTIONS.size()]
	_lbl_status.text = "Press  SPACE / E  in the green zone!"
	_lbl_status.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	_sweep_t = 0.0; _sweep_dir = 1
	for i in _action_dots.size():
		if i < _action_idx:
			_action_dots[i].text = "✅"
			_action_dots[i].add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		elif i == _action_idx:
			_action_dots[i].add_theme_color_override("font_color", Color(1, 0.9, 0.2))

func _do_season_action() -> void:
	var skill: float
	if _sweep_t >= DROP_ZONE_MIN and _sweep_t <= DROP_ZONE_MAX:
		skill = 1.0 - absf(_sweep_t - 0.5) * 2.0
		_lbl_status.text = "✅ Seasoned!"
		_lbl_status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		AudioManager.play_sfx(AudioManager.SFX_SPLASH)
	else:
		skill = 0.3
		_lbl_status.text = "💨 Too much! Wiped off some."
		_lbl_status.add_theme_color_override("font_color", Color(1, 0.5, 0.2))
	_total_skill += skill
	_action_idx += 1
	if _action_idx >= SEASON_ACTIONS.size():
		var prick_skill = clampf(float(_pricks) / float(PRICKS_NEEDED), 0.0, 1.0)
		var season_skill = _total_skill / float(SEASON_ACTIONS.size())
		var final_skill = prick_skill * 0.4 + season_skill * 0.6
		_result_label.text = "✨ Handa na! (Ready to grill!) ✨"
		_result_label.visible = true
		complete_minigame(clampf(final_skill, 0.0, 1.0))
	else:
		_load_season_action()

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)
		if remaining < 5.0:
			_lbl_timer.add_theme_color_override("font_color", Color(1, 0.2, 0.2))

func _force_finish() -> void:
	var prick_skill = clampf(float(_pricks) / float(PRICKS_NEEDED), 0.0, 1.0)
	var season_skill = (_total_skill / float(max(1, _action_idx))) if _action_idx > 0 else 0.0
	complete_minigame(clampf(prick_skill * 0.4 + season_skill * 0.6, 0.0, 1.0))
