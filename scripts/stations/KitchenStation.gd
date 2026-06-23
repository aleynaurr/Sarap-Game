extends Area2D
class_name KitchenStation

@export var station_id: String = ""
@export var station_label: String = "Station"
@export var step_indices: Array = []   # which recipe step indices this station handles

var _player_inside: bool = false

signal player_entered(station: KitchenStation)
signal player_exited(station: KitchenStation)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		body.set_nearby_station(self)
		player_entered.emit(self)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		body.set_nearby_station(null)
		player_exited.emit(self)

func get_current_step() -> Dictionary:
	# Only returns a step if it is the GLOBAL next required step AND belongs
	# to this station. This enforces strict sequential ordering across the
	# whole recipe, not just "any undone step at this station".
	var next_idx = GameManager.get_next_required_step()
	if next_idx == -1:
		return {}
	var recipe = RecipeData.get_recipe(GameManager.current_recipe_id)
	var steps = recipe.get("steps", [])
	if next_idx >= steps.size():
		return {}
	var step = steps[next_idx]
	if step.get("station", "") == station_id:
		return step
	return {}

func has_pending_step() -> bool:
	return not get_current_step().is_empty()

func get_current_step_index() -> int:
	if has_pending_step():
		return GameManager.get_next_required_step()
	return -1
