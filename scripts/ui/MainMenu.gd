extends Control

@onready var btn_play: Button   = $MenuVBox/BtnPlay
@onready var btn_howto: Button  = $MenuVBox/BtnHowTo
@onready var btn_quit: Button   = $MenuVBox/BtnQuit
@onready var howto_panel: Panel = $HowToPanel
@onready var howto_close: Button = $HowToPanel/HowToClose
@onready var bg_pattern: ColorRect = $BgPattern

var _t: float = 0.0

func _ready() -> void:
	btn_play.pressed.connect(_on_play)
	btn_howto.pressed.connect(_on_howto)
	btn_quit.pressed.connect(_on_quit)
	howto_close.pressed.connect(func(): howto_panel.visible = false)
	AudioManager.play_music("menu")
	_style_buttons()

func _style_buttons() -> void:
	var red_style = StyleBoxFlat.new()
	red_style.bg_color = Color(0.65, 0.18, 0.15)
	red_style.border_color = Color(0.88, 0.66, 0.22)
	red_style.set_border_width_all(2)
	red_style.corner_radius_top_left = 4
	red_style.corner_radius_top_right = 4
	red_style.corner_radius_bottom_right = 4
	red_style.corner_radius_bottom_left = 4
	btn_play.add_theme_stylebox_override("normal", red_style)

	var brown_style = StyleBoxFlat.new()
	brown_style.bg_color = Color(0.40, 0.26, 0.15)
	brown_style.border_color = Color(0.65, 0.48, 0.28)
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
	GameManager.go_to_recipe_select()

func _on_howto() -> void:
	AudioManager.play_sfx(AudioManager.SFX_CLICK)
	howto_panel.visible = true

func _on_quit() -> void:
	get_tree().quit()
