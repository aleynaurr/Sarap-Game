extends Node

# ─── Global State ───────────────────────────────────────────────────────────
var current_recipe_id: String = ""
var current_step_index: int = 0
var total_score: int = 0
var step_scores: Array = []
var time_remaining: float = 0.0
var game_active: bool = false

# Kitchen session
var recipe_steps_done: Array = []   # which steps the player has completed
var completed_ingredients: Dictionary = {}  # ingredient_id -> bool washed/prepped

signal recipe_step_completed(step_index: int, score: int)
signal recipe_finished(total_score: int, grade: String)
signal minigame_entered(minigame_id: String)
signal minigame_exited()

const TOTAL_RECIPE_TIME := 300.0   # 5 minutes per recipe

# ─── Scene transition ────────────────────────────────────────────────────────
func start_recipe(recipe_id: String) -> void:
	current_recipe_id = recipe_id
	current_step_index = 0
	total_score = 0
	step_scores = []
	recipe_steps_done = []
	completed_ingredients = {}
	time_remaining = TOTAL_RECIPE_TIME
	game_active = true
	get_tree().change_scene_to_file("res://scenes/SplitScreen.tscn")

func go_to_main_menu() -> void:
	game_active = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func go_to_recipe_select() -> void:
	get_tree().change_scene_to_file("res://scenes/RecipeSelect.tscn")

func go_to_results() -> void:
	get_tree().change_scene_to_file("res://scenes/Results.tscn")

# ─── Score helpers ───────────────────────────────────────────────────────────
func add_step_score(score: int, step_idx: int) -> void:
	while step_scores.size() <= step_idx:
		step_scores.append(0)
	step_scores[step_idx] = score
	total_score += score
	recipe_step_completed.emit(step_idx, score)

func get_grade() -> String:
	var steps = RecipeData.get_recipe(current_recipe_id).get("steps", [])
	var max_possible = steps.size() * 100
	if max_possible == 0:
		return "C"
	var pct = float(total_score) / float(max_possible)
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
func mark_step_done(step_idx: int) -> void:
	if step_idx not in recipe_steps_done:
		recipe_steps_done.append(step_idx)

func is_step_done(step_idx: int) -> bool:
	return step_idx in recipe_steps_done

func get_next_required_step() -> int:
	var steps = RecipeData.get_recipe(current_recipe_id).get("steps", [])
	for i in range(steps.size()):
		if not is_step_done(i):
			return i
	return -1   # all done

func all_steps_done() -> bool:
	var steps = RecipeData.get_recipe(current_recipe_id).get("steps", [])
	return recipe_steps_done.size() >= steps.size()
