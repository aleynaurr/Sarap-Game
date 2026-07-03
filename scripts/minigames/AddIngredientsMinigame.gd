extends MinigameBase
# Plate/Assembly Minigame: Add ingredients in strict sequence: Chili -> Garlic -> Ginger -> Onion.
# Key bindings (W, A, S, D) are randomized across bowls each game.

# Strict Recipe Order
const INGREDIENT_SEQUENCE := ["chili", "garlic", "ginger", "onion"]
var _current_step_idx := 0
var _mistakes_count := 0

var _ingredient_key_map := {}
var _original_textures := {}

# Preloaded Key Textures
const TEX_W = preload("res://assets/assets/sprites/wasd/w (1).png")
const TEX_A = preload("res://assets/assets/sprites/wasd/A (1).png")
const TEX_S = preload("res://assets/assets/sprites/wasd/S.png")
const TEX_D = preload("res://assets/assets/sprites/wasd/D (1).png")

# UI & Station Nodes
@onready var _lbl_timer: Label = $TimerLabel
@onready var _lbl_status: Label = $StatusLabel
@onready var _lbl_wrong: Label = $Wrong

# WASD Key Icons
@onready var ginger_icon: TextureRect = $GingerLabel
@onready var onion_icon: TextureRect = $OnionLabel
@onready var garlic_icon: TextureRect = $GarlicLabel
@onready var chili_icon: TextureRect = $ChiliLabel

@onready var ginger_bowl: TextureRect = $SlicedGingerBowl
@onready var onion_bowl: TextureRect = $SlicedOnion
@onready var garlic_bowl: TextureRect = $MincedGarlic
@onready var chili_bowl: TextureRect = $SlicedRedChilis

@onready var big_mixer_bowl = $BigMixerBowl
@onready var mixer_chili = $Chili
@onready var mixer_garlic = $Garlic
@onready var mixer_ginger = $Ginger
@onready var mixer_onion = $Onion

@onready var finish_sprite = $finish

func _ready() -> void:
	if ginger_bowl: _original_textures[ginger_bowl] = ginger_bowl.texture
	if onion_bowl: _original_textures[onion_bowl] = onion_bowl.texture
	if garlic_bowl: _original_textures[garlic_bowl] = garlic_bowl.texture
	if chili_bowl: _original_textures[chili_bowl] = chili_bowl.texture
	_on_init()

func _on_init() -> void:
	_current_step_idx = 0
	_mistakes_count = 0
	
	if finish_sprite: finish_sprite.visible = false
	if big_mixer_bowl: big_mixer_bowl.visible = true
	
	if mixer_chili: mixer_chili.visible = false
	if mixer_garlic: mixer_garlic.visible = false
	if mixer_ginger: mixer_ginger.visible = false
	if mixer_onion: mixer_onion.visible = false
	
	var bowls = [ginger_bowl, onion_bowl, garlic_bowl, chili_bowl]
	for bowl in bowls:
		if bowl:
			bowl.visible = true
			if _original_textures.has(bowl):
				bowl.texture = _original_textures[bowl]
				
	if ginger_icon: ginger_icon.visible = true
	if onion_icon: onion_icon.visible = true
	if garlic_icon: garlic_icon.visible = true
	if chili_icon: chili_icon.visible = true
	
	_randomize_key_assignments()
	_update_status_instruction()

func _randomize_key_assignments() -> void:
	randomize()
	
	var available_keys = [
		{"code": KEY_W, "tex": TEX_W},
		{"code": KEY_A, "tex": TEX_A},
		{"code": KEY_S, "tex": TEX_S},
		{"code": KEY_D, "tex": TEX_D}
	]
	available_keys.shuffle()
	
	_ingredient_key_map["ginger"] = available_keys[0]
	_ingredient_key_map["onion"] = available_keys[1]
	_ingredient_key_map["garlic"] = available_keys[2]
	_ingredient_key_map["chili"] = available_keys[3]
	
	if ginger_icon: ginger_icon.texture = _ingredient_key_map["ginger"]["tex"]
	if onion_icon: onion_icon.texture = _ingredient_key_map["onion"]["tex"]
	if garlic_icon: garlic_icon.texture = _ingredient_key_map["garlic"]["tex"]
	if chili_icon: chili_icon.texture = _ingredient_key_map["chili"]["tex"]

func _on_update(_delta: float, remaining: float) -> void:
	_update_timer_display(remaining)

func _input(event: InputEvent) -> void:
	if _finished or _current_step_idx >= INGREDIENT_SEQUENCE.size():
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		var target_ingredient = INGREDIENT_SEQUENCE[_current_step_idx]
		var correct_key_code: int = _ingredient_key_map[target_ingredient]["code"]
		
		if event.keycode == correct_key_code:
			_animate_and_pour_ingredient(target_ingredient)
		else:
			if event.keycode in [KEY_W, KEY_A, KEY_S, KEY_D]:
				_trigger_wrong_input_penalty()

func _animate_and_pour_ingredient(ingredient: String) -> void:
	if _lbl_wrong:
		_lbl_wrong.text = ""
	
	var parent_bowl: TextureRect = null
	var overlay_icon: TextureRect = null
	var target_mixer_sprite: TextureRect = null
	
	match ingredient:
		"chili":
			parent_bowl = chili_bowl
			overlay_icon = chili_icon
			target_mixer_sprite = mixer_chili
		"garlic":
			parent_bowl = garlic_bowl
			overlay_icon = garlic_icon
			target_mixer_sprite = mixer_garlic
		"ginger":
			parent_bowl = ginger_bowl
			overlay_icon = ginger_icon
			target_mixer_sprite = mixer_ginger
		"onion":
			parent_bowl = onion_bowl
			overlay_icon = onion_icon
			target_mixer_sprite = mixer_onion

	if overlay_icon: 
		overlay_icon.visible = false
	
	if parent_bowl and big_mixer_bowl and parent_bowl.texture:
		var fly_duplicate = TextureRect.new()
		fly_duplicate.texture = parent_bowl.texture
		fly_duplicate.size = parent_bowl.size
		fly_duplicate.expand_mode = parent_bowl.expand_mode
		fly_duplicate.stretch_mode = parent_bowl.stretch_mode
		fly_duplicate.global_position = parent_bowl.global_position
		
		get_parent().add_child(fly_duplicate)
		
		parent_bowl.texture = null
		
		var mixer_center = big_mixer_bowl.position + (big_mixer_bowl.size / 2.0)
		var target_pos = mixer_center - (fly_duplicate.size / 2.0)
		
		var tween = create_tween().set_parallel(true)
		
		tween.tween_property(fly_duplicate, "position", target_pos, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(fly_duplicate, "scale", Vector2.ZERO, 0.35)
		
		var target_pivot = fly_duplicate.size / 2.0
		fly_duplicate.pivot_offset = target_pivot
		
		tween.chain().tween_callback(func():
			if target_mixer_sprite:
				target_mixer_sprite.visible = true
			fly_duplicate.queue_free()
		)

	_current_step_idx += 1
	
	if _current_step_idx >= INGREDIENT_SEQUENCE.size():
		get_tree().create_timer(0.4).timeout.connect(_calculate_and_complete)
	else:
		_update_status_instruction()

func _trigger_wrong_input_penalty() -> void:
	_mistakes_count += 1
	if _lbl_wrong:
		_lbl_wrong.text = "Wrong Ingredient Order! Follow the recipe!"

func _update_status_instruction() -> void:
	if _lbl_status and _current_step_idx < INGREDIENT_SEQUENCE.size():
		var next_item = INGREDIENT_SEQUENCE[_current_step_idx].capitalize()
		_lbl_status.text = "Add " + next_item

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)

func _force_finish() -> void:
	_calculate_and_complete()

func _calculate_and_complete() -> void:
	var completion_ratio = float(_current_step_idx) / float(INGREDIENT_SEQUENCE.size())
	var penalty_deduction = _mistakes_count * 0.15
	var final_score = clampf(completion_ratio - penalty_deduction, 0.0, 1.0)
	
	if finish_sprite: finish_sprite.visible = true
	if _lbl_status: _lbl_status.text = "Complete!"
	
	complete_minigame(final_score)
