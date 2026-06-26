extends Node2D

@onready var player: CharacterBody2D    = $Player
@onready var hud: CanvasLayer           = $HUD
@onready var minigame_host: CanvasLayer = $MinigameHost
@onready var timer_lbl: Label           = $HUD/TimerLabel
@onready var recipe_lbl: Label          = $HUD/RecipeLabel
@onready var step_lbl: Label            = $HUD/StepLabel
@onready var score_lbl: Label           = $HUD/ScoreLabel
@onready var station_hint: Label        = $HUD/StationHint
@onready var step_list: VBoxContainer   = $HUD/StepList
@onready var side_panel: TextureRect    = $HUD/SidePanel
@onready var side_panel_label: Label    = $HUD/SidePanelLabel

var _recipe: Dictionary = {}
var _steps: Array = []
var _global_timer: float = 0.0
var _global_active: bool = true
var _step_labels: Array = []
var _player_current_station: KitchenStation = null

# Sidebar collapse state
var _sidebar_open: bool = true
var _sidebar_width: float = 130.0
var _pixelon_font: FontFile = null
var _toggle_btn: Button = null
var _tab_hint_lbl: Label = null

# ── Station indicator ─────────────────────────────────────────────────────────
# These positions can be tweaked here to match where each station visually sits.
# They are the world-space coordinates where the exclamation will appear.
@export var indicator_positions: Dictionary = {
	"sink":     Vector2(152, 440),
	"chopping": Vector2(96,  279),
	"frying":   Vector2(103, 102),
	"cooking":  Vector2(525, 416),
	"working":  Vector2(316, 438),
}

var _indicator: Sprite2D = null
var _bob_time: float = 0.0
const BOB_SPEED:  float = 3.0
const BOB_AMOUNT: float = 6.0
const INDICATOR_SCALE: Vector2 = Vector2(0.55, 0.55)

# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_recipe = RecipeData.get_recipe(GameManager.current_recipe_id)
	_steps  = _recipe.get("steps", [])
	GameManager.game_active = true

	_load_pixelon_font()
	_setup_hud()
	_setup_sidebar_toggle()
	_setup_station_indicator()
	_connect_stations()

	player.interact_pressed.connect(_on_player_interact)
	minigame_host.minigame_done.connect(_on_minigame_done)

	_global_timer = GameManager.TOTAL_RECIPE_TIME
	_update_step_list()
	_update_station_indicator()

# ─── Font ─────────────────────────────────────────────────────────────────────

func _load_pixelon_font() -> void:
	var font = load("res://assets/fonts/Pixelon.ttf")
	if font is FontFile:
		_pixelon_font = font

func _apply_pixelon(lbl: Label, size: int = 11) -> void:
	if _pixelon_font:
		lbl.add_theme_font_override("font", _pixelon_font)
	lbl.add_theme_font_size_override("font_size", size)

# ─── HUD ──────────────────────────────────────────────────────────────────────

func _setup_hud() -> void:
	recipe_lbl.text = "🍳 " + _recipe.get("display_name", "Recipe")
	score_lbl.text  = "Score: 0"
	step_lbl.text   = "Next: " + _get_next_step_name()
	_apply_pixelon(side_panel_label, 11)
	_apply_pixelon(step_lbl, 11)

func _setup_sidebar_toggle() -> void:
	_toggle_btn = Button.new()
	_toggle_btn.text = "«"
	_toggle_btn.custom_minimum_size = Vector2(18, 48)
	_toggle_btn.position = Vector2(_sidebar_width, 36)
	_toggle_btn.flat = false
	if _pixelon_font:
		_toggle_btn.add_theme_font_override("font", _pixelon_font)
	_toggle_btn.add_theme_font_size_override("font_size", 10)
	_toggle_btn.pressed.connect(_toggle_sidebar)
	hud.add_child(_toggle_btn)

	_tab_hint_lbl = Label.new()
	_tab_hint_lbl.text = "[Tab]"
	_tab_hint_lbl.position = Vector2(2, 88)
	_tab_hint_lbl.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45, 0.8))
	_apply_pixelon(_tab_hint_lbl, 9)
	hud.add_child(_tab_hint_lbl)

func _toggle_sidebar() -> void:
	_sidebar_open = not _sidebar_open
	_refresh_sidebar_visibility()

func _refresh_sidebar_visibility() -> void:
	side_panel.visible       = _sidebar_open
	side_panel_label.visible = _sidebar_open
	step_list.visible        = _sidebar_open
	step_lbl.visible         = _sidebar_open
	_toggle_btn.text         = "«" if _sidebar_open else "»"
	_toggle_btn.position.x   = _sidebar_width if _sidebar_open else 0

# ─── Station indicator ────────────────────────────────────────────────────────

func _setup_station_indicator() -> void:
	var tex = load("res://assets/sprites/ui/exclamation.png")
	if tex == null:
		return
	_indicator = Sprite2D.new()
	_indicator.texture = tex
	_indicator.scale = INDICATOR_SCALE
	_indicator.z_index = 10
	_indicator.visible = false
	add_child(_indicator)

func _update_station_indicator() -> void:
	if _indicator == null:
		return
	var next_idx = GameManager.get_next_required_step()
	if next_idx == -1:
		_indicator.visible = false
		return
	var station_id: String = _steps[next_idx].get("station", "")
	if station_id == "" or not indicator_positions.has(station_id):
		_indicator.visible = false
		return
	_indicator.position = indicator_positions[station_id]
	_bob_time = 0.0   # reset bob so it always starts from the same place
	_indicator.visible = true

# ─── Game loop ────────────────────────────────────────────────────────────────

func _connect_stations() -> void:
	var stations_node = get_node_or_null("Stations")
	if stations_node == null:
		return
	for child in stations_node.get_children():
		if child is KitchenStation:
			child.player_entered.connect(_on_station_entered.bind(child))
			child.player_exited.connect(_on_station_exited)

func _process(delta: float) -> void:
	if _indicator != null and _indicator.visible:
		_bob_time += delta * BOB_SPEED
		_indicator.position.y = indicator_positions.get(
			_get_current_station_id(), Vector2.ZERO).y + sin(_bob_time) * BOB_AMOUNT

	if not _global_active:
		return

	_global_timer -= delta
	if _global_timer <= 0.0:
		_global_timer = 0.0
		_global_active = false
		_on_time_up()

	var secs = int(_global_timer)
	timer_lbl.text = "%02d:%02d" % [secs / 60, secs % 60]
	if _global_timer < 60.0:
		timer_lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.2))
	elif _global_timer < 120.0:
		timer_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))

func _get_current_station_id() -> String:
	var next_idx = GameManager.get_next_required_step()
	if next_idx == -1:
		return ""
	return _steps[next_idx].get("station", "")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to_recipe_select()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			_toggle_sidebar()

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
	player.disable()
	minigame_host.launch(step_dict, step_index)

func _on_minigame_done(step_index: int, skill_ratio: float, time_ratio: float) -> void:
	var score = ScoreManager.calculate_step_score(skill_ratio, time_ratio)
	GameManager.add_step_score(score, step_index)
	GameManager.mark_step_done(step_index)

	score_lbl.text = "Score: %d" % GameManager.total_score
	_update_step_list()
	step_lbl.text  = "Next: " + _get_next_step_name()
	_update_station_indicator()

	if GameManager.all_steps_done():
		player.enable()
		_global_active = false
		await get_tree().create_timer(1.2).timeout
		GameManager.go_to_results()
		return

	var completed_station_id = _steps[step_index].get("station", "")
	var next_idx = GameManager.get_next_required_step()
	if next_idx != -1 and _player_current_station != null:
		var next_step = _steps[next_idx]
		if next_step.get("station", "") == completed_station_id and _player_current_station.station_id == completed_station_id:
			await get_tree().create_timer(0.35).timeout
			if not GameManager.game_active:
				return
			minigame_host.launch(next_step, next_idx)
			return

	player.enable()

func _on_time_up() -> void:
	player.disable()
	await get_tree().create_timer(1.5).timeout
	GameManager.go_to_results()

# ─── Helpers ──────────────────────────────────────────────────────────────────

func _get_next_step_name() -> String:
	var next_idx = GameManager.get_next_required_step()
	if next_idx == -1:
		return "All done! 🎉"
	return _steps[next_idx].get("name", "???")

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
		lbl.text = ("✅" if done else "⬜") + " " + step.get("name", "???")
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size.x = 120
		_apply_pixelon(lbl, 10)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.88, 0.5) if done else Color(0.88, 0.88, 0.88))
		step_list.add_child(lbl)
		_step_labels.append(lbl)

func _show_popup(msg: String) -> void:
	var popup = Label.new()
	popup.text = msg
	popup.add_theme_font_size_override("font_size", 14)
	popup.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	popup.position = Vector2(160, 200)
	popup.z_index = 100
	add_child(popup)
	await get_tree().create_timer(2.5).timeout
	popup.queue_free()
