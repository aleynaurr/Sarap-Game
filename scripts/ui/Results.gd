extends Control

## Results screen for one player's split-screen panel (640x720).
## Plays a looping "results" video chosen by star rank (1/2/3 stars,
## reusing the game's existing scoring thresholds), then fades in a
## "Main Menu" button once the video hits BUTTON_APPEAR_TIME seconds.
## The button bobs gently and never disappears until pressed.

@onready var video_player: VideoStreamPlayer = $VideoPlayer
@onready var menu_button: TextureButton    = $MenuButton
@export var player_number: int = 1

@onready var ingredients_score = $ScorePanel/VBoxContainer/PanelContainer2/IngredientsScore
@onready var kitchen_score = $ScorePanel/VBoxContainer/PanelContainer3/KitchenScore
@onready var total_score = $ScorePanel/VBoxContainer/PanelContainer4/TotalScore
# ---- Config ----------------------------------------------------------

const VIDEO_DIR := "res://assets/resultvideos/"

# NOTE: Godot 4's built-in VideoStreamPlayer only natively decodes Ogg
# Theora (.ogv). If talong1/2/3 are .mp4 or .webm you'll need to either
# convert them to .ogv or install a video decoder plugin for that format.
const VIDEO_FILES := {
	1: "talong1.ogv",
	2: "talong2.ogv",
	3: "talong3.ogv",
}

# Same thresholds used by the old letter-grade Results screen.
# pct = total_score / max_possible_score. Count how many thresholds are
# cleared to get the star count (0..3). There is no 0-star video, so the
# result is floored at 1.
const STAR_THRESHOLDS := [0.35, 0.60, 0.85]

const BUTTON_APPEAR_TIME := 29.0  # seconds into the video

const DOOR_TRANSITION_SCENE := preload("res://scenes/DoorTransition.tscn")

const HOVER_BRIGHTNESS := Color(1.25, 1.25, 1.25, 1.0)
const HOVER_TWEEN_DURATION := 0.15

# ---- State -------------------------------------------------------------

var _button_shown := false
var _bob_tween: Tween
var _button_base_y: float

# -------------------------------------------------------------------------

func _ready() -> void:
	print(ingredients_score)
	print(kitchen_score)
	print(total_score)
	AudioManager.fade_out_music(1.5)
	
	var ingredient := GameManager.get_ingredient_score(player_number)
	var kitchen := GameManager.get_total_score(player_number)
	var total := GameManager.get_final_score(player_number)

	ingredients_score.text = str(ingredient)
	kitchen_score.text = str(kitchen)
	total_score.text = str(total)
	
	
	menu_button.modulate.a = 0.0
	_button_base_y = menu_button.position.y

	# Ignore mouse input until the button has actually faded in, so it
	# can't be hovered/clicked while invisible.
	menu_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_setup_video()
	_update_score_panel()
	
	menu_button.pressed.connect(_on_menu_pressed)
	menu_button.mouse_entered.connect(_on_button_hover)
	menu_button.mouse_exited.connect(_on_button_unhover)
	video_player.finished.connect(_on_video_finished)

	set_process(true)

func _update_score_panel() -> void:
	var ingredient = GameManager.get_ingredient_score(player_number)
	var kitchen = GameManager.get_total_score(player_number)
	var total = GameManager.get_final_score(player_number)

	ingredients_score.text = str(ingredient)
	kitchen_score.text = str(kitchen)
	total_score.text = str(total)
	
func _process(_delta: float) -> void:
	if not _button_shown and video_player.is_playing() and video_player.stream_position >= BUTTON_APPEAR_TIME:
		_show_menu_button()


# ---- Video -------------------------------------------------------------

func _setup_video() -> void:
	var stars := _calculate_stars()
	var filename: String = VIDEO_FILES.get(stars, VIDEO_FILES[1])
	var stream := load(VIDEO_DIR + filename)

	if stream == null:
		push_warning("Results: could not load video '%s%s'" % [VIDEO_DIR, filename])
		return

	video_player.stream = stream
	video_player.autoplay = false
	video_player.play()


func _on_video_finished() -> void:
	# Loop the backdrop video forever.
	video_player.play()


func _calculate_stars() -> int:
	var recipe := RecipeData.get_recipe(GameManager.current_recipe_id)
	var steps: Array = recipe.get("steps", [])
	var max_sc: int = (steps.size() * 100) + 100
	var total: int = GameManager.get_final_score(player_number)
	var pct: float = float(total) / float(max(1, max_sc))

	var stars := 0
	for threshold in STAR_THRESHOLDS:
		if pct >= threshold:
			stars += 1

	return max(stars, 1)


# ---- Main Menu button ----------------------------------------------------

func _show_menu_button() -> void:
	_button_shown = true
	menu_button.mouse_filter = Control.MOUSE_FILTER_STOP

	var fade_tween := create_tween()
	fade_tween.tween_property(menu_button, "modulate:a", 1.0, 0.6)
	fade_tween.finished.connect(_start_bob)


func _start_bob() -> void:
	_bob_tween = create_tween()
	_bob_tween.set_loops()
	_bob_tween.tween_property(menu_button, "position:y", _button_base_y - 8.0, 0.8)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(menu_button, "position:y", _button_base_y, 0.8)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ---- Hover feedback -----------------------------------------------------

func _on_button_hover() -> void:
	var t := create_tween()
	t.tween_property(menu_button, "modulate", HOVER_BRIGHTNESS, HOVER_TWEEN_DURATION)


func _on_button_unhover() -> void:
	var t := create_tween()
	t.tween_property(menu_button, "modulate", Color(1, 1, 1, 1), HOVER_TWEEN_DURATION)


# ---- Menu transition ------------------------------------------------------

func _on_menu_pressed() -> void:
	AudioManager.play_sfx(AudioManager.SFX_CLICK)

	# Prevent double-triggering the transition on a second click.
	menu_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _bob_tween:
		_bob_tween.kill()

	var door := DOOR_TRANSITION_SCENE.instantiate()
	get_tree().root.add_child(door)
	door.play_transition(func(): GameManager.go_to_main_menu())
