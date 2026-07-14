extends Node2D

const SMALL_DOOR_TRANSITION_SCENE := preload("res://scenes/SmallDoorTransition.tscn")
const DOOR_TRANSITION_SCENE := preload("res://scenes/DoorTransition.tscn")
const VERSUS_VIDEO_PATH := "res://assets/versus.ogv"

static var _versus_video_played_global := false  # Shared between both players!
var _versus_video: VideoStreamPlayer = null
var _versus_backdrop: ColorRect = null
var _versus_transition_started := false
var _versus_start_time := 0.0
var _versus_stream_length := 0.0

@export var player_number: int = 1  # 1 or 2

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

var _waiting_popup: CanvasLayer = null
var _waiting_bob_tween: Tween = null
var _waiting_popup_base_y: float = 0.0

var _recipe: Dictionary = {}
var _steps: Array = []
var _global_active: bool = true
var _global_timer: float = 0.0
var _step_labels: Array = []
var _player_current_station: KitchenStation = null

# Sidebar collapse state
var _sidebar_open: bool = true
var _sidebar_width: float = 130.0
var _pixelon_font: FontFile = null
var _toggle_btn: Button = null
var _tab_hint_lbl: Label = null

# ─── Station indicator ─────────────────────────────────────────────────────────
# These positions can be tweaked here to match where each station visually sits.
# They are the world-space coordinates where the exclamation will appear.
@export var indicator_positions: Dictionary = {
	"sink":     Vector2(152, 510),
	"chopping": Vector2(96,  349),
	"frying":   Vector2(103, 172),
	"cooking":  Vector2(525, 486),
	"working":  Vector2(316, 508),
	"rice":     Vector2(96, 172),
}

var _indicator: Sprite2D = null
var _bob_time: float = 0.0
const BOB_SPEED:  float = 3.0
const BOB_AMOUNT: float = 6.0
const INDICATOR_SCALE: Vector2 = Vector2(0.55, 0.55)

# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_play_versus_video()

func _play_versus_video() -> void:
	# Only Player 1 should handle the versus video (or if already played globally)
	if player_number != 1 or _versus_video_played_global:
		# Wait a tiny bit to make sure P1's video is done before initializing?
		# Or just initialize right away if video is already played
		if _versus_video_played_global:
			_initialize_kitchen()
		else:
			# Wait for P1 to finish
			await get_tree().process_frame
			while not _versus_video_played_global:
				await get_tree().process_frame
			_initialize_kitchen()
		return
	
	# Set global flag that video is playing FIRST THING!
	GameManager.versus_video_playing = true
	
	var stream = load(VERSUS_VIDEO_PATH)
	if stream == null:
		_versus_video_played_global = true
		GameManager.versus_video_playing = false
		_initialize_kitchen()
		# Also let P2 know it's done
		return
	
	# Try to get stream length—if not available, we'll just use finished signal
	if stream.has_method("get_length"):
		_versus_stream_length = stream.get_length()
	else:
		_versus_stream_length = 0.0  # Fallback: use finished signal
	
	_versus_backdrop = ColorRect.new()
	_versus_backdrop.color = Color.BLACK
	_versus_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(_versus_backdrop)
	
	_versus_video = VideoStreamPlayer.new()
	_versus_video.stream = stream
	_versus_video.expand = true
	_versus_video.set_anchors_preset(Control.PRESET_FULL_RECT)
	_versus_video.finished.connect(_on_versus_video_finished)
	get_tree().root.add_child(_versus_video)
	
	_versus_start_time = Time.get_ticks_msec() / 1000.0
	_versus_video.play()

func _on_versus_video_finished() -> void:
	if not _versus_transition_started:
		_start_versus_transition()

func _start_versus_transition() -> void:
	_versus_transition_started = true
	var door := DOOR_TRANSITION_SCENE.instantiate()
	get_tree().root.add_child(door)
	await door._close_doors()
	# Now initialize the kitchens!
	_versus_video_played_global = true
	_initialize_kitchen()
	# Keep video playing until the end, then clean up
	var elapsed = Time.get_ticks_msec() / 1000.0 - _versus_start_time
	var remaining = max(0.0, _versus_stream_length - elapsed) if _versus_stream_length > 0 else 0.0
	if remaining > 0:
		await get_tree().create_timer(remaining).timeout
	else:
		# If we couldn't get stream length, just wait a tiny bit
		await get_tree().create_timer(0.5).timeout
	# Now clean up
	GameManager.versus_video_playing = false
	if _versus_backdrop and is_instance_valid(_versus_backdrop):
		_versus_backdrop.queue_free()
	if _versus_video and is_instance_valid(_versus_video):
		_versus_video.queue_free()
	_versus_backdrop = null
	_versus_video = null
	# Continue door transition
	await get_tree().create_timer(0.4)  # Hold duration (like DoorTransition)
	await door._open_doors()
	door.queue_free()

func _initialize_kitchen() -> void:
	_recipe = RecipeData.get_recipe(GameManager.current_recipe_id)
	_steps  = _recipe.get("steps", [])
	GameManager.set_game_active(player_number, true)

	AudioManager.play_music("kitchen", 1.5)

	_load_pixelon_font()
	_setup_hud()
	_setup_sidebar_toggle()
	_setup_station_indicator()
	_connect_stations()

	player.player_number = player_number
	player.interact_pressed.connect(_on_player_interact)
	minigame_host.player_number = player_number
	minigame_host.minigame_done.connect(_on_minigame_done)
	
	# Set player sprite sheet based on player number
	var player_sprite = $Player/Sprite2D
	if player_sprite:
		if player_number == 1:
			player_sprite.texture = load("res://assets/player_sheet.png")
		else:
			player_sprite.texture = load("res://assets/player_sheet2.png")
	
	# Set interact prompt sprite based on player number
	var prompt_sprite = $Player/InteractPrompt/PromptSprite
	if prompt_sprite:
		if player_number == 1:
			prompt_sprite.texture = load("res://assets/sprites/ui/key_prompt_e.png")
		else:
			prompt_sprite.texture = load("res://assets/sprites/ui/key_prompt_shift.png")

	_global_timer = GameManager.TOTAL_RECIPE_TIME
	GameManager.set_time_remaining(player_number, _global_timer)
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
	recipe_lbl.text = ("P%d " % player_number) + "🍳 " + _recipe.get("display_name", "Recipe")
	score_lbl.text  = "Score: 0"
	step_lbl.text   = "Next: " + _get_next_step_name()
	_apply_pixelon(side_panel_label, 25)
	_apply_pixelon(step_lbl, 20)

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

# ─── Station indicator ─────────────────────────────────────────────────────────

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
	var next_idx = GameManager.get_next_required_step(player_number)
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

# ─── Game loop ─────────────────────────────────────────────────────────────────

func _connect_stations() -> void:
	var stations_node = get_node_or_null("Stations")
	if stations_node == null:
		return
	for child in stations_node.get_children():
		if child is KitchenStation:
			child.player_number = player_number
			child.player_entered.connect(_on_station_entered)
			child.player_exited.connect(_on_station_exited)

func _process(delta: float) -> void:
	if player_number == 1 and _versus_video and not _versus_transition_started and _versus_stream_length > 0:
		var elapsed = Time.get_ticks_msec() / 1000.0 - _versus_start_time
		if elapsed >= _versus_stream_length - 1.2:
			_start_versus_transition()

	if _indicator != null and _indicator.visible:
		_bob_time += delta * BOB_SPEED
		_indicator.position.y = indicator_positions.get(
			_get_current_station_id(), Vector2.ZERO).y + sin(_bob_time) * BOB_AMOUNT

	if not _global_active:
		return

	var shared_timer = GameManager.get_shared_timer_remaining()
	var secs = int(shared_timer)
	timer_lbl.text = "%02d:%02d" % [secs / 60, secs % 60]
	if shared_timer < 60.0:
		timer_lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.2))
	elif shared_timer < 120.0:
		timer_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))

func _get_current_station_id() -> String:
	var next_idx = GameManager.get_next_required_step(player_number)
	if next_idx == -1:
		return ""
	return _steps[next_idx].get("station", "")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		AudioManager.fade_out_music(1.5)
		GameManager.go_to_recipe_select()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			_toggle_sidebar()

func _on_station_entered(station: KitchenStation) -> void:
	_player_current_station = station
	if station.has_pending_step():
		var step = station.get_current_step()
		var interact_key = "E" if player_number == 1 else "Shift"
		station_hint.text = "Press [%s] — " % interact_key + step.get("name", "Cook")
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
	_play_small_door_transition(func(): minigame_host.launch(step_dict, step_index))

func _on_minigame_done(step_index: int, skill_ratio: float, time_ratio: float) -> void:
	# Grab a snapshot of exactly what's on screen right now — still the
	# minigame — before anything else (including minigame_host's own
	# internal teardown) has a chance to change it visually. We'll show
	# this in place of the real scene until the doors are fully closed.
	var freeze_layer := _capture_freeze_layer()

	var score = ScoreManager.calculate_step_score(skill_ratio, time_ratio)
	GameManager.add_step_score(player_number, score, step_index)
	GameManager.mark_step_done(player_number, step_index)

	var all_done := GameManager.all_steps_done(player_number)

	if all_done:
		freeze_layer.queue_free()
		_refresh_hud_after_step()
		player.enable()
		_global_active = false
		GameManager.set_player_finished(player_number)
		_show_waiting_popup()
		return

	# Returning to full kitchen control for ALL cases now!
	add_child(freeze_layer)

	var door := SMALL_DOOR_TRANSITION_SCENE.instantiate()
	add_child(door)
	door.play_transition(func():
		_refresh_hud_after_step()
		player.enable()
		freeze_layer.queue_free()
	)

func _capture_freeze_layer() -> CanvasLayer:
	var img := get_viewport().get_texture().get_image()
	var tex := ImageTexture.create_from_image(img)

	var layer := CanvasLayer.new()
	layer.layer = 90  # above the kitchen/HUD/minigame, below the doors (layer 100)

	var rect := TextureRect.new()
	rect.texture = tex
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	layer.add_child(rect)

	return layer

func _refresh_hud_after_step() -> void:
	score_lbl.text = "Score: %d" % GameManager.get_total_score(player_number)
	_update_step_list()
	step_lbl.text   = "Next: " + _get_next_step_name()
	_update_station_indicator()

func _play_small_door_transition(on_midpoint: Callable) -> void:
	var door := SMALL_DOOR_TRANSITION_SCENE.instantiate()
	add_child(door)
	door.play_transition(on_midpoint)

func _on_time_up() -> void:
	player.disable()
	await get_tree().create_timer(1.5).timeout
	# Don't go to results yet

# ─── Helpers ──────────────────────────────────────────────────────────────────

func _get_next_step_name() -> String:
	var next_idx = GameManager.get_next_required_step(player_number)
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
	var step_scores = GameManager.get_step_scores(player_number)
	for i in range(_steps.size()):
		var step = _steps[i]
		var done = GameManager.is_step_done(player_number, i)
		var lbl  = Label.new()
		var step_text = ("✅" if done else "⬜") + " " + step.get("name", "???")
		if done and i < step_scores.size():
			step_text += " | %d pts" % step_scores[i]
		lbl.text = step_text
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size.x = 120
		_apply_pixelon(lbl, 14)
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

func _show_waiting_popup() -> void:
	# Don't show popup if both players are already done
	if GameManager.is_player_finished(1) and GameManager.is_player_finished(2):
		return
	_waiting_popup = CanvasLayer.new()
	_waiting_popup.layer = 99
	var bg_rect = ColorRect.new()
	bg_rect.offset_left = 0
	bg_rect.offset_top = 0
	bg_rect.offset_right = 640
	bg_rect.offset_bottom = 720
	bg_rect.color = Color(0,0,0,0.6)
	_waiting_popup.add_child(bg_rect)

	var waiting_lbl = Label.new()
	waiting_lbl.text = "Waiting for other player..."
	waiting_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	waiting_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	waiting_lbl.offset_left = 0
	waiting_lbl.offset_top = 320  # 720/2 - some offset
	waiting_lbl.offset_right = 640
	waiting_lbl.offset_bottom = 400
	waiting_lbl.add_theme_font_size_override("font_size", 32)
	waiting_lbl.add_theme_color_override("font_color", Color(1,1,1,1))
	if _pixelon_font:
		waiting_lbl.add_theme_font_override("font", _pixelon_font)
	_waiting_popup.add_child(waiting_lbl)
	_waiting_popup_base_y = waiting_lbl.position.y

	add_child(_waiting_popup)

	# Pop-in animation
	waiting_lbl.scale = Vector2(0.1, 0.1)
	var pop_tween = create_tween()
	pop_tween.tween_property(waiting_lbl, "scale", Vector2(1.2, 1.2), 0.2)
	pop_tween.tween_property(waiting_lbl, "scale", Vector2(1, 1), 0.1)

	# Bobbing animation
	await pop_tween.finished
	_waiting_bob_tween = create_tween()
	_waiting_bob_tween.set_loops()
	_waiting_bob_tween.tween_property(waiting_lbl, "position:y", _waiting_popup_base_y - 10, 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_waiting_bob_tween.tween_property(waiting_lbl, "position:y", _waiting_popup_base_y, 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
