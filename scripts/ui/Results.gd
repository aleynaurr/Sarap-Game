extends Control

@onready var recipe_label: Label     = $RecipeLabel
@onready var grade_label: Label      = $GradeLabel
@onready var score_label: Label      = $ScoreLabel
@onready var step_breakdown: Label   = $StepBreakdown
@onready var grade_message: Label    = $GradeMessage
@onready var stars_row: HBoxContainer = $StarsRow
@onready var btn_again: Button       = $ButtonRow/BtnPlayAgain
@onready var btn_menu: Button        = $ButtonRow/BtnMenu

const GRADE_MESSAGES = {
	"S": "🌟 KAHANGA-HANGA! (Outstanding!) 🌟\nYou cook like a true Filipino Mama!",
	"A": "✨ NAPAKAGALING! (Excellent!)\nLola would be proud!",
	"B": "👍 MAGANDA! (Good job!)\nKeep practicing!",
	"C": "😊 SIGE NA! (Okay!)\nYou can do better next time!",
	"D": "😅 SUBUKAN MULI! (Try again!)\nEvery great cook starts somewhere!",
}

const STAR_THRESHOLDS = [0.35, 0.60, 0.85]   # % needed for 1st, 2nd, 3rd star

func _ready() -> void:
	var recipe  = RecipeData.get_recipe(GameManager.current_recipe_id)
	var steps   = recipe.get("steps", [])
	var grade   = GameManager.get_grade()
	var total   = GameManager.total_score
	var max_sc  = steps.size() * 100

	recipe_label.text = "🍽️ " + recipe.get("display_name", "Recipe")
	grade_label.text  = grade
	grade_label.add_theme_color_override("font_color", ScoreManager.grade_color(grade))
	score_label.text  = "Total Score: %d / %d" % [total, max_sc]
	grade_message.text = GRADE_MESSAGES.get(grade, "Good try!")

	# Stars
	var pct = float(total) / float(max(1, max_sc))
	var star_textures = stars_row.get_children()
	var star_full  = load("res://assets/sprites/ui/star_full.png")
	var star_empty = load("res://assets/sprites/ui/star_empty.png")
	for i in range(star_textures.size()):
		star_textures[i].texture = star_full if pct >= STAR_THRESHOLDS[i] else star_empty

	# Step breakdown
	var lines = []
	for i in range(steps.size()):
		var step_name  = steps[i].get("name", "Step %d" % (i + 1))
		var step_score = GameManager.step_scores[i] if i < GameManager.step_scores.size() else 0
		var done_mark  = "✅" if GameManager.is_step_done(i) else "⬜"
		lines.append("%s  %s  —  %d pts" % [done_mark, step_name, step_score])
	step_breakdown.text = "\n".join(lines)

	btn_again.pressed.connect(_on_play_again)
	btn_menu.pressed.connect(func(): GameManager.go_to_main_menu())

	_animate_grade()

func _on_play_again() -> void:
	AudioManager.play_sfx(AudioManager.SFX_CLICK)
	GameManager.go_to_recipe_select()

func _animate_grade() -> void:
	grade_label.scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.tween_property(grade_label, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
