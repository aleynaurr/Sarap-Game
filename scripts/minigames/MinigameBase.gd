extends Control
class_name MinigameBase

# Override these in subclasses
var minigame_id: String = "base"
var step_data: Dictionary = {}

var _skill_score: float = 0.0   # 0..1
var _start_time: float = 0.0
var _time_limit: float = 20.0
var _finished: bool = false

signal minigame_completed(skill_ratio: float, time_ratio: float)

func init_step(step: Dictionary) -> void:
	step_data = step
	_time_limit = step.get("time_limit", 20.0)
	_start_time = Time.get_ticks_msec() / 1000.0
	_finished = false
	_skill_score = 0.0
	_on_init()

func _on_init() -> void:
	pass  # override

func _process(delta: float) -> void:
	if _finished:
		return
	var elapsed = (Time.get_ticks_msec() / 1000.0) - _start_time
	var remaining = _time_limit - elapsed
	_update_timer_display(remaining)
	if remaining <= 0.0:
		_force_finish()
	_on_update(delta, remaining)

func _on_update(_delta: float, _remaining: float) -> void:
	pass  # override

func _update_timer_display(_remaining: float) -> void:
	pass  # override in each minigame

func complete_minigame(skill_ratio: float) -> void:
	if _finished:
		return
	_finished = true
	_skill_score = clampf(skill_ratio, 0.0, 1.0)
	var elapsed = (Time.get_ticks_msec() / 1000.0) - _start_time
	var remaining = maxf(0.0, _time_limit - elapsed)
	var time_ratio = ScoreManager.time_ratio_from_remaining(remaining, _time_limit)
	await get_tree().create_timer(0.3).timeout
	minigame_completed.emit(_skill_score, time_ratio)

func _force_finish() -> void:
	complete_minigame(_skill_score)

# ─── Shared UI helpers ───────────────────────────────────────────────────────
func make_label(text: String, font_size: int = 14, color: Color = Color.WHITE) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

func make_panel_bg(bg_size: Vector2, color: Color = Color(0.12, 0.08, 0.06)) -> ColorRect:
	var cr = ColorRect.new()
	cr.size = bg_size
	cr.color = color
	return cr

func make_progress_bar(max_val: float = 100.0, color: Color = Color(0.35, 0.72, 0.35)) -> ProgressBar:
	var pb = ProgressBar.new()
	pb.max_value = max_val
	pb.value = 0
	pb.custom_minimum_size = Vector2(200, 18)
	pb.add_theme_color_override("fill_color", color)
	return pb
