extends Control

const DOOR_TRANSITION_SCENE := preload("res://scenes/DoorTransition.tscn")

# Update the extension if your export isn't .ogv (Godot's built-in video
# player only supports Ogg Theora out of the box — .webm/.mp4 need a
# separate plugin. If you're using a plugin format, just change this path).
const STARTUP_VIDEO_PATH := "res://assets/startvid.ogv"
const CUTSCENE_VIDEO_PATH := "res://assets/cutscene.ogv"

@onready var btn_play: Button   = $MenuVBox/BtnPlay
@onready var btn_howto: Button  = $MenuVBox/BtnHowTo
@onready var btn_quit: Button   = $MenuVBox/BtnQuit
@onready var howto_panel: Panel = $HowToPanel
@onready var howto_close: Button = $HowToPanel/HowToClose
@onready var bg_pattern: ColorRect = $BgPattern
@onready var texture_rect: TextureRect = $Background
@onready var texture_rect_2: TextureRect = $TextureRect2
@onready var rays_texture_rect: TextureRect = $Rays

const BG_PULSE_SCALE := 1.08
const BG_PULSE_DURATION := 5.0  # seconds per direction (grow, then shrink)

const RECT2_PULSE_SCALE := 1.08
const RECT2_PULSE_DURATION := 5.0  # seconds per direction (grow, then shrink)
const RECT2_ROTATE_DURATION := 8.0  # seconds for one full 360-degree spin
const DOOR_HOLD_DURATION := 0.4

var _t: float = 0.0
var _startup_video: VideoStreamPlayer
var _cutscene_video: VideoStreamPlayer
var _skip_button: Button
var _cutscene_backdrop: ColorRect
var _cutscene_playing: bool = false

# static = shared across every instance of this script for as long as the
# game process is running, so it survives scene changes (going back to the
# Main Menu from RecipeSelect) but resets on a full relaunch — exactly
# "only the first time they open the game."
static var _has_played_startup_video: bool = false


func _ready() -> void:
	# Hide all main menu elements initially (with null checks)
	if btn_play: btn_play.visible = false
	if btn_howto: btn_howto.visible = false
	if btn_quit: btn_quit.visible = false
	if howto_panel: howto_panel.visible = false
	if bg_pattern: bg_pattern.visible = false
	if texture_rect: texture_rect.visible = false
	if texture_rect_2: texture_rect_2.visible = false
	if rays_texture_rect: rays_texture_rect.visible = false

	if _has_played_startup_video:
		_start_main_menu()
	else:
		_play_startup_video()


# ─── Startup video ───────────────────────────────────────────────────────────
func _play_startup_video() -> void:
	var stream: VideoStream = load(STARTUP_VIDEO_PATH)
	if stream == null:
		push_warning("MainMenu: couldn't load startup video at " + STARTUP_VIDEO_PATH + " — skipping straight to the menu.")
		_has_played_startup_video = true
		_play_cutscene()
		return

	# Black backdrop in case the video's aspect ratio doesn't exactly match
	# the screen (letterboxing instead of showing whatever's behind it).
	var backdrop := ColorRect.new()
	backdrop.name = "StartupVideoBackdrop"
	backdrop.color = Color.BLACK
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	_startup_video = VideoStreamPlayer.new()
	_startup_video.name = "StartupVideo"
	_startup_video.stream = stream
	_startup_video.expand = true
	_startup_video.set_anchors_preset(Control.PRESET_FULL_RECT)
	_startup_video.finished.connect(_on_startup_video_finished)
	add_child(_startup_video)

	_startup_video.play()


func _on_startup_video_finished() -> void:
	var backdrop := get_node_or_null("StartupVideoBackdrop")
	if backdrop:
		backdrop.queue_free()
	if _startup_video:
		_startup_video.queue_free()
		_startup_video = null

	_play_cutscene()
	
func _play_cutscene() -> void:
	var stream: VideoStream = load(CUTSCENE_VIDEO_PATH)
	if stream == null:
		push_warning("MainMenu: couldn't load cutscene at " + CUTSCENE_VIDEO_PATH + " — skipping straight to the menu.")
		_has_played_startup_video = true
		_start_main_menu()
		return

	# Black backdrop for cutscene
	_cutscene_backdrop = ColorRect.new()
	_cutscene_backdrop.name = "CutsceneBackdrop"
	_cutscene_backdrop.color = Color.BLACK
	_cutscene_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_cutscene_backdrop)

	_cutscene_video = VideoStreamPlayer.new()
	_cutscene_video.name = "CutsceneVideo"
	_cutscene_video.stream = stream
	_cutscene_video.expand = true
	_cutscene_video.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cutscene_video.finished.connect(_on_cutscene_finished)
	add_child(_cutscene_video)
	
	# Add Skip Story button in bottom right
	_skip_button = Button.new()
	_skip_button.name = "SkipStoryButton"
	_skip_button.text = "Skip Story"
	_skip_button.custom_minimum_size = Vector2(100, 40)
	# Position in bottom right: anchor at bottom right, offset by -10 from edges
	_skip_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_button.offset_left = -110
	_skip_button.offset_top = -50
	_skip_button.offset_right = -10
	_skip_button.offset_bottom = -10
	# Style the button
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0,0,0,0.6)
	button_style.border_color = Color.WHITE
	button_style.set_border_width_all(2)
	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	button_style.corner_radius_bottom_right = 8
	button_style.corner_radius_bottom_left = 8
	_skip_button.add_theme_stylebox_override("normal", button_style)
	# Load Pixelon font for Skip button (change this path to use your own font!)
	var pixelon_font = load("res://assets/fonts/Pixelon.ttf")
	if pixelon_font:
		_skip_button.add_theme_font_override("font", pixelon_font)
	_skip_button.add_theme_font_size_override("font_size", 16)
	_skip_button.add_theme_color_override("font_color", Color.WHITE)
	_skip_button.pressed.connect(_on_skip_pressed)
	add_child(_skip_button)

	_cutscene_playing = true
	_cutscene_video.play()

func _process(delta: float):
	_t += delta

func _on_cutscene_finished() -> void:
	_start_cutscene_transition(false)

func _on_skip_pressed() -> void:
	# Fade out audio
	AudioManager.fade_out_music()
	_start_cutscene_transition(true)
	
func _start_cutscene_transition(is_skip: bool):
	# Prevent double triggering
	_cutscene_playing = false
	if _skip_button:
		_skip_button.disabled = true
		_skip_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Start door transition
	var door := DOOR_TRANSITION_SCENE.instantiate()
	get_tree().root.add_child(door)
	
	# Wait for doors to close first (calling _close_doors is okay here)
	await door._close_doors()
	# Now clean up and call callback
	if _cutscene_backdrop:
		_cutscene_backdrop.queue_free()
	if _cutscene_video:
		_cutscene_video.stop()
		_cutscene_video.queue_free()
		_cutscene_video = null
	if _skip_button:
		_skip_button.queue_free()
		_skip_button = null
	_has_played_startup_video = true
	
	# Continue door transition (hold, open, callback)
	await get_tree().create_timer(DOOR_HOLD_DURATION).timeout
	_start_main_menu()
	
	await get_tree().process_frame
	await door._open_doors()
	door.queue_free()


# ─── Everything that used to run in _ready() now waits for the video ──────
func _start_main_menu() -> void:
	if btn_play: btn_play.visible = true
	if btn_howto: btn_howto.visible = true
	if btn_quit: btn_quit.visible = true
	if bg_pattern: bg_pattern.visible = true
	if texture_rect: texture_rect.visible = true
	if texture_rect_2: texture_rect_2.visible = true
	if rays_texture_rect: rays_texture_rect.visible = true
	
	# Fade-in effect
	var fade_tween = create_tween()
	
	if bg_pattern: 
		bg_pattern.modulate.a = 0.0
		fade_tween.tween_property(bg_pattern, "modulate:a", 1.0, 0.5)
	if texture_rect: 
		texture_rect.modulate.a = 0.0
		fade_tween.parallel().tween_property(texture_rect, "modulate:a", 1.0, 0.5)
	if texture_rect_2: 
		texture_rect_2.modulate.a = 0.0
		fade_tween.parallel().tween_property(texture_rect_2, "modulate:a", 1.0, 0.5)
	if rays_texture_rect: 
		rays_texture_rect.modulate.a = 0.0
		fade_tween.parallel().tween_property(rays_texture_rect, "modulate:a", 1.0, 0.5)
	if btn_play: 
		btn_play.modulate.a = 0.0
		fade_tween.parallel().tween_property(btn_play, "modulate:a", 1.0, 0.5)
	if btn_howto: 
		btn_howto.modulate.a = 0.0
		fade_tween.parallel().tween_property(btn_howto, "modulate:a", 1.0, 0.5)
	if btn_quit: 
		btn_quit.modulate.a = 0.0
		fade_tween.parallel().tween_property(btn_quit, "modulate:a", 1.0, 0.5)
	
	if btn_play: btn_play.pressed.connect(_on_play)
	if btn_howto: btn_howto.pressed.connect(_on_howto)
	if btn_quit: btn_quit.pressed.connect(_on_quit)
	if howto_close: howto_close.pressed.connect(func(): if howto_panel: howto_panel.visible = false)
	AudioManager.play_music("menu")
	_style_buttons()
	_start_bg_pulse()
	_start_rect2_pulse_and_rotate()


func _start_bg_pulse() -> void:
	if not texture_rect: return
	# Scale from the center so it grows/shrinks evenly on all sides
	# instead of drifting toward one corner.
	texture_rect.pivot_offset = texture_rect.size / 2.0
	texture_rect.scale = Vector2.ONE

	var main_tween := create_tween()
	main_tween.set_loops()

	# Background scale animation
	main_tween.tween_property(texture_rect, "scale", Vector2(BG_PULSE_SCALE, BG_PULSE_SCALE), BG_PULSE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	main_tween.tween_property(texture_rect, "scale", Vector2.ONE, BG_PULSE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Animate Rays as well!
	if rays_texture_rect:
		rays_texture_rect.pivot_offset = rays_texture_rect.size / 2.0
		rays_texture_rect.scale = Vector2.ONE
		rays_texture_rect.modulate.a = 1.0

		# Use the same main tween with parallel for rays!
		main_tween.parallel().tween_property(rays_texture_rect, "scale", Vector2(BG_PULSE_SCALE, BG_PULSE_SCALE), BG_PULSE_DURATION)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		main_tween.parallel().tween_property(rays_texture_rect, "scale", Vector2.ONE, BG_PULSE_DURATION)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		# Opacity animation: 1.0 → 0.0 over 2s, then 0.0 → 1.0 over 2s, loop
		var opacity_tween := create_tween()
		opacity_tween.set_loops()
		opacity_tween.tween_property(rays_texture_rect, "modulate:a", 0.0, 1.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		opacity_tween.tween_property(rays_texture_rect, "modulate:a", 1.0, 1.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _start_rect2_pulse_and_rotate() -> void:
	if not texture_rect_2: return
	texture_rect_2.pivot_offset = texture_rect_2.size / 2.0

	var pulse_tween := create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(texture_rect_2, "scale", Vector2(RECT2_PULSE_SCALE, RECT2_PULSE_SCALE), RECT2_PULSE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(texture_rect_2, "scale", Vector2.ONE, RECT2_PULSE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Separate tween for rotation, using as_relative() so each loop adds
	# another full 360 degrees on top of the current angle instead of
	# resetting back to 0 — this keeps the spin perfectly seamless with
	# no visible snap at the loop point.
	var rotate_tween := create_tween()
	rotate_tween.set_loops()
	rotate_tween.tween_property(texture_rect_2, "rotation_degrees", 360.0, RECT2_ROTATE_DURATION)\
		.as_relative().set_trans(Tween.TRANS_LINEAR)

func _style_buttons() -> void:
	var red_style = StyleBoxFlat.new()
	red_style.bg_color = Color(0.0, 0.0, 0.0, 0.4)
	red_style.border_color = Color(0.88, 0.88, 0.88, 1.0)
	red_style.set_border_width_all(2)
	red_style.corner_radius_top_left = 4
	red_style.corner_radius_top_right = 4
	red_style.corner_radius_bottom_right = 4
	red_style.corner_radius_bottom_left = 4
	if btn_play: btn_play.add_theme_stylebox_override("normal", red_style)

	var brown_style = StyleBoxFlat.new()
	brown_style.bg_color = Color(0.0, 0.0, 0.0, 0.4)
	brown_style.border_color = Color(0.961, 0.961, 0.961, 1.0)
	brown_style.set_border_width_all(2)
	brown_style.corner_radius_top_left = 4
	brown_style.corner_radius_top_right = 4
	brown_style.corner_radius_bottom_right = 4
	brown_style.corner_radius_bottom_left = 4
	if btn_howto: btn_howto.add_theme_stylebox_override("normal", brown_style)
	if btn_quit: btn_quit.add_theme_stylebox_override("normal", brown_style)

func _on_play() -> void:
	AudioManager.play_sfx(AudioManager.SFX_CLICK)

	# Prevent double-triggering the transition on a second click.
	btn_play.disabled = true

	var door := DOOR_TRANSITION_SCENE.instantiate()
	get_tree().root.add_child(door)
	door.play_transition(func(): GameManager.go_to_recipe_select())

func _on_howto() -> void:
	AudioManager.play_sfx(AudioManager.SFX_CLICK)
	howto_panel.visible = true

func _on_quit() -> void:
	get_tree().quit()
