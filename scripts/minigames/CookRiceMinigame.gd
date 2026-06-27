extends MinigameBase
# Cook Rice: press E/SPACE to add water, then keep heat in sweet spot until done.
# Simple two-phase minigame: Phase 1 = pour water (timing bar), Phase 2 = simmer.

const WATER_DROP_ZONE_MIN := 0.38
const WATER_DROP_ZONE_MAX := 0.62
const SWEEP_PERIOD := 1.2
const TARGET_HEAT_MIN := 0.40
const TARGET_HEAT_MAX := 0.65
const HEAT_DRIFT := 0.025
const HEAT_UP_RATE := 0.07
const HEAT_DOWN_RATE := 0.06
const TARGET_COOK_TIME := 7.0

enum Phase { POUR_WATER, SIMMER }
var _phase: Phase = Phase.POUR_WATER
var _sweep_t: float = 0.0
var _sweep_dir: int = 1
var _water_skill: float = 0.0
var _heat: float = 0.2
var _cook_time: float = 0.0
var _overflow: float = 0.0

var _lbl_timer: Label
var _lbl_status: Label
var _lbl_phase: Label
var _result_label: Label
var _sweep_marker: ColorRect
var _drop_zone: ColorRect
var _heat_bar: ProgressBar
var _cook_bar: ProgressBar
var _overflow_bar: ProgressBar
var _rice_label: Label
var _steam_label: Label
var _bubble: float = 0.0

func _on_init() -> void:
	_phase = Phase.POUR_WATER
	_sweep_t = 0.0
	_sweep_dir = 1
	_heat = 0.2
	_cook_time = 0.0
	_overflow = 0.0

	var bg = make_panel_bg(Vector2(640, 720))
	add_child(bg)

	var title = make_label("🍚  MAGLUTO NG KANIN!  (Cook Rice!)", 20, Color(1.0, 0.87, 0.3))
	title.position = Vector2(20, 14)
	add_child(title)

	var inst = make_label(step_data.get("instruction", "Cook the rice properly!"), 13, Color(0.95, 0.92, 0.82))
	inst.position = Vector2(20, 50)
	inst.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inst.custom_minimum_size.x = 600
	add_child(inst)

	# Pot visual
	var pot_bg = ColorRect.new()
	pot_bg.color = Color(0.28, 0.26, 0.30)
	pot_bg.size = Vector2(160, 130)
	pot_bg.position = Vector2(240, 130)
	add_child(pot_bg)

	_rice_label = make_label("🍚", 55, Color(1, 1, 1))
	_rice_label.position = Vector2(269, 140)
	add_child(_rice_label)

	_steam_label = make_label("", 24, Color(0.9, 0.9, 0.95, 0.8))
	_steam_label.position = Vector2(282, 105)
	add_child(_steam_label)

	_lbl_phase = make_label("PHASE 1: Pour water into the pot!", 18, Color(0.4, 0.85, 1.0))
	_lbl_phase.position = Vector2(20, 285)
	add_child(_lbl_phase)

	# Water sweep bar (Phase 1)
	var track_bg = ColorRect.new()
	track_bg.color = Color(0.18, 0.15, 0.14)
	track_bg.size = Vector2(440, 26)
	track_bg.position = Vector2(20, 315)
	add_child(track_bg)

	_drop_zone = ColorRect.new()
	_drop_zone.color = Color(0.2, 0.6, 1.0, 0.4)
	_drop_zone.size = Vector2(440 * (WATER_DROP_ZONE_MAX - WATER_DROP_ZONE_MIN), 26)
	_drop_zone.position = Vector2(20 + 440 * WATER_DROP_ZONE_MIN, 315)
	add_child(_drop_zone)

	_sweep_marker = ColorRect.new()
	_sweep_marker.color = Color(0.4, 0.85, 1.0)
	_sweep_marker.size = Vector2(8, 26)
	_sweep_marker.position = Vector2(20, 315)
	add_child(_sweep_marker)

	var dz_lbl = make_label("POUR ZONE", 10, Color(0.4, 0.85, 1.0))
	dz_lbl.position = Vector2(20 + 440 * WATER_DROP_ZONE_MIN, 343)
	add_child(dz_lbl)

	_lbl_status = make_label("Press  SPACE / E  when in the blue zone!", 18, Color(1, 0.9, 0.2))
	_lbl_status.position = Vector2(80, 370)
	add_child(_lbl_status)

	# Heat bar (Phase 2, hidden initially)
	var hlbl = make_label("HEAT  (↑ UP / ↓ DOWN):", 13, Color(0.9, 0.9, 0.9))
	hlbl.position = Vector2(20, 415)
	hlbl.visible = false
	hlbl.name = "HeatLabel"
	add_child(hlbl)

	_heat_bar = make_progress_bar(100.0, Color(0.9, 0.4, 0.1))
	_heat_bar.position = Vector2(20, 438)
	_heat_bar.custom_minimum_size = Vector2(420, 20)
	_heat_bar.visible = false
	add_child(_heat_bar)

	var ss = ColorRect.new()
	ss.color = Color(0.2, 1.0, 0.3, 0.35)
	ss.size = Vector2(int(420 * (TARGET_HEAT_MAX - TARGET_HEAT_MIN)), 20)
	ss.position = Vector2(20 + int(420 * TARGET_HEAT_MIN), 438)
	ss.visible = false
	ss.name = "HeatZone"
	add_child(ss)

	var cook_lbl = make_label("COOK PROGRESS:", 13, Color(0.9, 0.9, 0.9))
	cook_lbl.position = Vector2(20, 470)
	cook_lbl.visible = false
	cook_lbl.name = "CookLabel"
	add_child(cook_lbl)

	_cook_bar = make_progress_bar(TARGET_COOK_TIME, Color(0.9, 0.75, 0.2))
	_cook_bar.position = Vector2(20, 493)
	_cook_bar.custom_minimum_size = Vector2(420, 20)
	_cook_bar.visible = false
	add_child(_cook_bar)

	var ov_lbl = make_label("OVERFLOW:", 13, Color(0.9, 0.3, 0.1))
	ov_lbl.position = Vector2(20, 525)
	ov_lbl.visible = false
	ov_lbl.name = "OvLabel"
	add_child(ov_lbl)

	_overflow_bar = make_progress_bar(100.0, Color(0.95, 0.2, 0.1))
	_overflow_bar.position = Vector2(20, 548)
	_overflow_bar.custom_minimum_size = Vector2(420, 14)
	_overflow_bar.visible = false
	add_child(_overflow_bar)

	_lbl_timer = make_label("Time: %.1f" % _time_limit, 15, Color(1.0, 0.6, 0.3))
	_lbl_timer.position = Vector2(500, 14)
	add_child(_lbl_timer)

	_result_label = make_label("", 22, Color(1, 0.85, 0.1))
	_result_label.position = Vector2(180, 650)
	_result_label.visible = false
	add_child(_result_label)

	var hint = make_label("Cook the rice until fluffy!", 12, Color(0.6, 0.6, 0.6))
	hint.position = Vector2(20, 695)
	add_child(hint)

func _on_update(delta: float, _remaining: float) -> void:
	_bubble += delta
	if _phase == Phase.POUR_WATER:
		_sweep_t += (delta / SWEEP_PERIOD) * _sweep_dir
		if _sweep_t >= 1.0: _sweep_t = 1.0; _sweep_dir = -1
		elif _sweep_t <= 0.0: _sweep_t = 0.0; _sweep_dir = 1
		_sweep_marker.position.x = 20 + (440 - 8) * _sweep_t
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
			if _sweep_t >= WATER_DROP_ZONE_MIN and _sweep_t <= WATER_DROP_ZONE_MAX:
				_water_skill = 1.0 - absf(_sweep_t - 0.5) * 2.0
				_lbl_status.text = "✅ Water added! Now simmer the rice."
				_lbl_status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
			else:
				_water_skill = 0.4
				_lbl_status.text = "💦 Spilled a bit! Simmer now."
				_lbl_status.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
			_start_simmer_phase()
	else:
		if Input.is_action_pressed("move_up"):
			_heat = minf(1.0, _heat + HEAT_UP_RATE * delta)
		if Input.is_action_pressed("move_down"):
			_heat = maxf(0.0, _heat - HEAT_DOWN_RATE * delta)
		_heat = maxf(0.0, _heat - HEAT_DRIFT * delta)
		_heat_bar.value = _heat * 100.0
		if _heat >= TARGET_HEAT_MIN and _heat <= TARGET_HEAT_MAX:
			_cook_time += delta
			_lbl_status.text = "✅ Perfect simmer!"
			_lbl_status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
			_steam_label.text = "〰️〰️" if int(_bubble * 3) % 2 == 0 else "〜〜〜"
		elif _heat > TARGET_HEAT_MAX:
			_overflow = minf(1.0, _overflow + 0.055 * delta)
			_lbl_status.text = "🔥 Too hot! Lower heat!"
			_lbl_status.add_theme_color_override("font_color", Color(1, 0.3, 0.1))
			_steam_label.text = "💨💨💨"
		else:
			_lbl_status.text = "❄️ Too cold! Raise heat!"
			_lbl_status.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
			_steam_label.text = ""
		_cook_bar.value = _cook_time
		_overflow_bar.value = _overflow * 100.0
		if _overflow >= 1.0:
			_result_label.text = "💦 Umaapaw! (Overflowed!) Rice is soggy."
			_result_label.visible = true
			complete_minigame(0.1)
			return
		if _cook_time >= TARGET_COOK_TIME:
			var skill = (_water_skill * 0.4) + ((1.0 - _overflow * 0.5) * 0.6)
			_result_label.text = "✨ Luto na ang kanin! (Rice is done!) ✨"
			_result_label.visible = true
			complete_minigame(clampf(skill, 0.0, 1.0))

func _start_simmer_phase() -> void:
	_phase = Phase.SIMMER
	_lbl_phase.text = "PHASE 2: Keep heat steady to cook the rice!"
	_lbl_phase.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	_sweep_marker.visible = false
	_drop_zone.visible = false
	for node_name in ["HeatLabel", "HeatZone", "CookLabel", "OvLabel"]:
		var n = get_node_or_null(node_name)
		if n: n.visible = true
	_heat_bar.visible = true
	_cook_bar.visible = true
	_overflow_bar.visible = true

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)
		if remaining < 5.0:
			_lbl_timer.add_theme_color_override("font_color", Color(1, 0.2, 0.2))

func _force_finish() -> void:
	if _phase == Phase.POUR_WATER:
		complete_minigame(0.2)
	else:
		var skill = (_water_skill * 0.4) + (clampf(_cook_time / TARGET_COOK_TIME, 0.0, 1.0) * 0.6)
		complete_minigame(clampf(skill * (1.0 - _overflow * 0.5), 0.0, 1.0))
