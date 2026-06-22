extends Node2D

@onready var player: CharacterBody2D   = $Player
@onready var hud: CanvasLayer          = $HUD
@onready var minigame_host: CanvasLayer = $MinigameHost
@onready var timer_lbl: Label          = $HUD/TimerLabel
@onready var recipe_lbl: Label         = $HUD/RecipeLabel
@onready var step_lbl: Label           = $HUD/StepLabel
@onready var score_lbl: Label          = $HUD/ScoreLabel
@onready var station_hint: Label       = $HUD/StationHint
@onready var step_list: VBoxContainer  = $HUD/StepList

var _recipe: Dictionary = {}
var _steps: Array = []
var _global_timer: float = 0.0
var _global_active: bool = true
var _step_labels: Array = []
var _player_current_station: KitchenStation = null

func _ready() -> void:
	_recipe = RecipeData.get_recipe(GameManager.current_recipe_id)
	_steps  = _recipe.get("steps", [])
	GameManager.game_active = true

	_setup_hud()
	_connect_stations()

	player.interact_pressed.connect(_on_player_interact)
	minigame_host.minigame_done.connect(_on_minigame_done)

	_global_timer = GameManager.TOTAL_RECIPE_TIME
	_update_step_list()

func _setup_hud() -> void:
	recipe_lbl.text = "🍳 " + _recipe.get("display_name", "Recipe")
	score_lbl.text  = "Score: 0"
	step_lbl.text   = "Next: " + _get_next_step_name()

func _connect_stations() -> void:
	var stations_node = get_node_or_null("Stations")
	if stations_node == null:
		return
	for child in stations_node.get_children():
		if child is KitchenStation:
			child.player_entered.connect(_on_station_entered.bind(child))
			child.player_exited.connect(_on_station_exited)

func _process(delta: float) -> void:
	if not _global_active:
		return

	_global_timer -= delta
	if _global_timer <= 0.0:
		_global_timer = 0.0
		_global_active = false
		_on_time_up()

	var secs = int(_global_timer)
	var mins = secs / 60
	var sec2 = secs % 60
	timer_lbl.text = "%02d:%02d" % [mins, sec2]
	if _global_timer < 60.0:
		timer_lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.2))
	elif _global_timer < 120.0:
		timer_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))

func _on_station_entered(station: KitchenStation) -> void:
	_player_current_station = station
	if station.has_pending_step():
		var step = station.get_current_step()
		station_hint.text = "Press [E] — " + step.get("name", "Cook")
		station_hint.visible = true
	else:
		station_hint.text = "Station: " + station.station_label
		station_hint.visible = true

func _on_station_exited(_station: KitchenStation) -> void:
	if _player_current_station == _station:
		_player_current_station = null
	station_hint.visible = false

func _on_player_interact(station: KitchenStation) -> void:
	if not station.has_pending_step():
		_show_popup("No tasks here yet!\nComplete earlier steps first.")
		return

	var step_dict = station.get_current_step()
	var step_index = _get_step_index(step_dict)

	if step_index == -1:
		return

	# Disable player while minigame runs
	player.disable()
	minigame_host.launch(step_dict, step_index)

func _on_minigame_done(step_index: int, skill_ratio: float, time_ratio: float) -> void:
	var score = ScoreManager.calculate_step_score(skill_ratio, time_ratio)
	GameManager.add_step_score(score, step_index)
	GameManager.mark_step_done(step_index)

	score_lbl.text = "Score: %d" % GameManager.total_score
	_update_step_list()
	step_lbl.text  = "Next: " + _get_next_step_name()

	if GameManager.all_steps_done():
		player.enable()
		_global_active = false
		await get_tree().create_timer(1.2).timeout
		GameManager.go_to_results()
		return

	# Auto-advance: if the next required step is at the SAME station the
	# player is currently standing at, continue immediately without needing
	# to press [E] again — mirrors Cooking Mama's continuous-task flow.
	var completed_station_id = _steps[step_index].get("station", "")
	var next_idx = GameManager.get_next_required_step()
	if next_idx != -1 and _player_current_station != null:
		var next_step = _steps[next_idx]
		if next_step.get("station", "") == completed_station_id and _player_current_station.station_id == completed_station_id:
			await get_tree().create_timer(0.35).timeout
			if not GameManager.game_active:
				return
			minigame_host.launch(next_step, next_idx)
			return   # player stays disabled; minigame chain continues

	player.enable()

func _on_time_up() -> void:
	player.disable()
	await get_tree().create_timer(1.5).timeout
	GameManager.go_to_results()

func _get_next_step_name() -> String:
	var next_idx = GameManager.get_next_required_step()
	if next_idx == -1:
		return "All done! 🎉"
	var step = _steps[next_idx]
	return step.get("name", "???")

func _get_step_index(step_dict: Dictionary) -> int:
	for i in range(_steps.size()):
		if _steps[i].get("id", "") == step_dict.get("id", ""):
			return i
	return -1

func _update_step_list() -> void:
	for lbl in _step_labels:
		lbl.queue_free()
	_step_labels.clear()

	for i in range(_steps.size()):
		var step = _steps[i]
		var done = GameManager.is_step_done(i)
		var lbl  = Label.new()
		var check = "✅" if done else "⬜"
		lbl.text = check + " " + step.get("name", "???")
		lbl.add_theme_font_size_override("font_size", 11)
		var col = Color(0.5, 0.88, 0.5) if done else Color(0.88, 0.88, 0.88)
		lbl.add_theme_color_override("font_color", col)
		step_list.add_child(lbl)
		_step_labels.append(lbl)

func _show_popup(msg: String) -> void:
	# Simple one-shot popup using a timed label
	var popup = Label.new()
	popup.text = msg
	popup.add_theme_font_size_override("font_size", 14)
	popup.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	popup.position = Vector2(160, 200)
	popup.z_index = 100
	add_child(popup)
	await get_tree().create_timer(2.5).timeout
	popup.queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to_recipe_select()
