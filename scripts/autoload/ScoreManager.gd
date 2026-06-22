extends Node

signal timer_updated(seconds_left: float)
signal time_up()

var _timer_active: bool = false
var _time_left: float = 0.0

# Per-minigame scoring weights
const TIME_WEIGHT := 0.4      # 40% from time
const SKILL_WEIGHT := 0.6     # 60% from skill performance

func start_timer(seconds: float) -> void:
	_time_left = seconds
	_timer_active = true

func stop_timer() -> void:
	_timer_active = false

func get_time_left() -> float:
	return _time_left

func _process(delta: float) -> void:
	if not _timer_active:
		return
	_time_left -= delta
	timer_updated.emit(_time_left)
	if _time_left <= 0.0:
		_time_left = 0.0
		_timer_active = false
		time_up.emit()

# ─── Score calculation ────────────────────────────────────────────────────────
# skill_ratio: 0.0 - 1.0 based on minigame performance
# time_ratio:  0.0 - 1.0 based on remaining time vs step time_limit
func calculate_step_score(skill_ratio: float, time_ratio: float) -> int:
	var skill_score = skill_ratio * SKILL_WEIGHT
	var time_score  = time_ratio  * TIME_WEIGHT
	return int((skill_score + time_score) * 100.0)

func time_ratio_from_remaining(remaining: float, total_limit: float) -> float:
	if total_limit <= 0.0:
		return 0.0
	return clampf(remaining / total_limit, 0.0, 1.0)

func grade_label(total_score: int, max_score: int) -> String:
	if max_score == 0:
		return "C"
	var pct = float(total_score) / float(max_score)
	if pct >= 0.90: return "S"
	elif pct >= 0.75: return "A"
	elif pct >= 0.55: return "B"
	elif pct >= 0.35: return "C"
	else: return "D"

func grade_color(grade: String) -> Color:
	match grade:
		"S": return Color(1.0, 0.85, 0.1)
		"A": return Color(0.2, 0.85, 0.3)
		"B": return Color(0.2, 0.6, 1.0)
		"C": return Color(0.85, 0.55, 0.1)
		_:   return Color(0.7, 0.2, 0.2)
