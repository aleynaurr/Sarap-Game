extends Control

const DOOR_TRANSITION_SCENE := preload("res://scenes/DoorTransition.tscn")

# Update the extension if your export isn't .ogv (Godot's built-in video
# player only supports Ogg Theora out of the box — .webm/.mp4 need a
# separate plugin. If you're using a plugin format, just change this path).
const STARTUP_VIDEO_PATH := "res://assets/startvid.ogv"

@onready var btn_play: Button   = $MenuVBox/BtnPlay
@onready var btn_howto: Button  = $MenuVBox/BtnHowTo
@onready var btn_quit: Button   = $MenuVBox/BtnQuit
@onready var howto_panel: Panel = $HowToPanel
@onready var howto_close: Button = $HowToPanel/HowToClose
@onready var bg_pattern: ColorRect = $BgPattern
@onready var texture_rect: TextureRect = $TextureRect
@onready var texture_rect_2: TextureRect = $TextureRect2

const BG_PULSE_SCALE := 1.08
const BG_PULSE_DURATION := 5.0  # seconds per direction (grow, then shrink)

const RECT2_PULSE_SCALE := 1.08
const RECT2_PULSE_DURATION := 5.0  # seconds per direction (grow, then shrink)
const RECT2_ROTATE_DURATION := 8.0  # seconds for one full 360-degree spin

var _t: float = 0.0
var _startup_video: VideoStreamPlayer

# static = shared across every instance of this script for as long as the
# game process is running, so it survives scene changes (going back to the
# Main Menu from RecipeSelect) but resets on a full relaunch — exactly
# "only the first time they open the game."
static var _has_played_startup_video: bool = false


func _ready() -> void:
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
		_start_main_menu()
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

	_has_played_startup_video = true
	_start_main_menu()


# ─── Everything that used to run in _ready() now waits for the video ──────
func _start_main_menu() -> void:
	btn_play.pressed.connect(_on_play)
	btn_howto.pressed.connect(_on_howto)
	btn_quit.pressed.connect(_on_quit)
	howto_close.pressed.connect(func(): howto_panel.visible = false)
	AudioManager.play_music("menu")
	_style_buttons()
	_start_bg_pulse()
	_start_rect2_pulse_and_rotate()


func _start_bg_pulse() -> void:
	# Scale from the center so it grows/shrinks evenly on all sides
	# instead of drifting toward one corner.
	texture_rect.pivot_offset = texture_rect.size / 2.0

	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(texture_rect, "scale", Vector2(BG_PULSE_SCALE, BG_PULSE_SCALE), BG_PULSE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(texture_rect, "scale", Vector2.ONE, BG_PULSE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _start_rect2_pulse_and_rotate() -> void:
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
	btn_play.add_theme_stylebox_override("normal", red_style)

	var brown_style = StyleBoxFlat.new()
	brown_style.bg_color = Color(0.0, 0.0, 0.0, 0.4)
	brown_style.border_color = Color(0.961, 0.961, 0.961, 1.0)
	brown_style.set_border_width_all(2)
	brown_style.corner_radius_top_left = 4
	brown_style.corner_radius_top_right = 4
	brown_style.corner_radius_bottom_right = 4
	brown_style.corner_radius_bottom_left = 4
	btn_howto.add_theme_stylebox_override("normal", brown_style)
	btn_quit.add_theme_stylebox_override("normal", brown_style)

func _process(delta: float) -> void:
	_t += delta

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
