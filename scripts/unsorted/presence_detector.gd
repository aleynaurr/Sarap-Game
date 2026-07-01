extends Area2D

@onready var prompt_icon = $PromptIcon

var icon_base_y: float
var bob_tween: Tween

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt_icon.modulate.a = 0.0
	icon_base_y = prompt_icon.position.y

func _on_body_entered(body):
	if body.is_in_group("player"):
		fade_icon(1.0)
		start_bob()

func _on_body_exited(body):
	if body.is_in_group("player"):
		fade_icon(0.0)
		stop_bob()

func fade_icon(target_alpha: float):
	prompt_icon.visible = true
	var tween = create_tween()
	tween.tween_property(prompt_icon, "modulate:a", target_alpha, 0.1)
	if target_alpha == 0.0:
		tween.tween_callback(func(): prompt_icon.visible = false)

func start_bob():
	if bob_tween:
		bob_tween.kill()
	bob_tween = create_tween()
	bob_tween.set_loops()  # loops forever until killed
	bob_tween.tween_property(prompt_icon, "position:y", icon_base_y - 8, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob_tween.tween_property(prompt_icon, "position:y", icon_base_y, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func stop_bob():
	if bob_tween:
		bob_tween.kill()
	prompt_icon.position.y = icon_base_y
