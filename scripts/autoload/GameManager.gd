extends Node

# ─── Global state per player ─────────────────────────────────────────────────
var current_recipe_id: String = ""

# Player-specific state
var _player_state: Dictionary = {}
var _shared_timer: float = 0.0
var _shared_timer_active: bool = false

signal recipe_step_completed(player: int, step_index: int, score: int)
signal recipe_finished(player: int, total_score: int, grade: String)
signal minigame_entered(minigame_id: String)
signal minigame_exited()
signal all_players_finished()
signal shared_timer_up()

const TOTAL_RECIPE_TIME := 300.0   # 5 minutes per recipe

# ─── Init player states ──────────────────────────────────────────────────────
func _ready() -> void:
	_reset_player(1)
	_reset_player(2)

func _reset_player(player_num: int) -> void:
	_player_state[player_num] = {
		"total_score": 0,
		"step_scores": [],
		"time_remaining": TOTAL_RECIPE_TIME,
		"game_active": false,
		"recipe_steps_done": [],
		"completed_ingredients": {},
		"fanning_result_state": "",
		"is_finished": false
	}

# ─── Shared timer handling ────────────────────────────────────────────────────
func start_shared_timer() -> void:
	_shared_timer = TOTAL_RECIPE_TIME
	_shared_timer_active = true
	set_process(true)

func stop_shared_timer() -> void:
	_shared_timer_active = false

func get_shared_timer_remaining() -> float:
	return _shared_timer

func _process(delta: float) -> void:
	if not _shared_timer_active:
		return
	_shared_timer -= delta
	if _shared_timer <= 0.0:
		_shared_timer = 0.0
		_shared_timer_active = false
		shared_timer_up.emit()

# ─── Player finished state ───────────────────────────────────────────────────
func set_player_finished(player: int) -> void:
	_player_state[player]["is_finished"] = true
	recipe_finished.emit(player, get_total_score(player), get_grade(player))
	_check_all_players_finished()

func is_player_finished(player: int) -> bool:
	return _player_state[player]["is_finished"]

func _check_all_players_finished() -> void:
	if is_player_finished(1) and is_player_finished(2):
		stop_shared_timer()
		all_players_finished.emit()

# ─── Scene transition ────────────────────────────────────────────────────────
func start_recipe(recipe_id: String) -> void:
	current_recipe_id = recipe_id
	_reset_player(1)
	_reset_player(2)
	_player_state[1]["game_active"] = true
	_player_state[2]["game_active"] = true
	start_shared_timer()
	print("Changing scene...")
	get_tree().change_scene_to_file("res://scenes/get_ingredients/GetIngredients.tscn")

func go_to_main_menu() -> void:
	_player_state[1]["game_active"] = false
	_player_state[2]["game_active"] = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func go_to_recipe_select() -> void:
	get_tree().change_scene_to_file("res://scenes/RecipeSelect.tscn")

func go_to_kitchen() -> void:
	get_tree().change_scene_to_file("res://scenes/SplitScreen.tscn")

func go_to_results() -> void:
	get_tree().change_scene_to_file("res://scenes/SplitScreenResults.tscn")

# ─── Player-specific getters/setters ─────────────────────────────────────────
func get_total_score(player: int) -> int:
	return _player_state[player]["total_score"]

func set_total_score(player: int, value: int) -> void:
	_player_state[player]["total_score"] = value

func get_step_scores(player: int) -> Array:
	return _player_state[player]["step_scores"]

func get_time_remaining(player: int) -> float:
	return _player_state[player]["time_remaining"]

func set_time_remaining(player: int, value: float) -> void:
	_player_state[player]["time_remaining"] = value

func get_game_active(player: int) -> bool:
	return _player_state[player]["game_active"]

func set_game_active(player: int, value: bool) -> void:
	_player_state[player]["game_active"] = value

func get_recipe_steps_done(player: int) -> Array:
	return _player_state[player]["recipe_steps_done"]

func get_completed_ingredients(player: int) -> Dictionary:
	return _player_state[player]["completed_ingredients"]

func get_fanning_result_state(player: int) -> String:
	return _player_state[player]["fanning_result_state"]

func set_fanning_result_state(player: int, value: String) -> void:
	_player_state[player]["fanning_result_state"] = value

# ─── Score helpers ───────────────────────────────────────────────────────────
func add_step_score(player: int, score: int, step_idx: int) -> void:
	var state = _player_state[player]
	while state["step_scores"].size() <= step_idx:
		state["step_scores"].append(0)
	state["step_scores"][step_idx] = score
	state["total_score"] += score
	recipe_step_completed.emit(player, step_idx, score)

func get_grade(player: int) -> String:
	var state = _player_state[player]
	var steps = RecipeData.get_recipe(current_recipe_id).get("steps", [])
	var max_possible = steps.size() * 100
	if max_possible == 0:
		return "C"
	var pct = float(state["total_score"]) / float(max_possible)
	if pct >= 0.90:
		return "S"
	elif pct >= 0.75:
		return "A"
	elif pct >= 0.55:
		return "B"
	elif pct >= 0.35:
		return "C"
	else:
		return "D"

# ─── Step tracking ───────────────────────────────────────────────────────────
func mark_step_done(player: int, step_idx: int) -> void:
	var state = _player_state[player]
	if step_idx not in state["recipe_steps_done"]:
		state["recipe_steps_done"].append(step_idx)

func is_step_done(player: int, step_idx: int) -> bool:
	return step_idx in _player_state[player]["recipe_steps_done"]

func get_next_required_step(player: int) -> int:
	var state = _player_state[player]
	var steps = RecipeData.get_recipe(current_recipe_id).get("steps", [])
	for i in range(steps.size()):
		if not is_step_done(player, i):
			return i
	return -1   # all done

func all_steps_done(player: int) -> bool:
	var state = _player_state[player]
	var steps = RecipeData.get_recipe(current_recipe_id).get("steps", [])
	return state["recipe_steps_done"].size() >= steps.size()
