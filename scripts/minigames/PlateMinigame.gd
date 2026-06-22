extends MinigameBase
# Plate: items are listed. Press 1/2/3/4 to place each ingredient into the correct zone.
# Zones are labeled on screen. Wrong zone = penalty.

var _ingredients: Array = []
var _current_ingredient_idx: int = 0
var _correct_placements: int = 0
var _wrong_placements: int = 0
var _zones: Array = []
var _zone_labels: Array = []
var _lbl_timer: Label
var _lbl_status: Label
var _result_label: Label
var _lbl_instruction: Label
var _current_ingr_lbl: Label
var _zone_flash: Array = []

# Simplified: show current ingredient + 3 zone options (one correct)
var _correct_zone_idx: int = 0

func _on_init() -> void:
	_ingredients = step_data.get("ingredients", ["item1", "item2"])
	if _ingredients.is_empty():
		_ingredients = ["item"]
	_current_ingredient_idx = 0
	_correct_placements = 0
	_wrong_placements = 0
	_generate_zones()

	var bg = make_panel_bg(Vector2(640, 480))
	add_child(bg)

	var title = make_label("🍽️  IHAIN!  (Plate!)", 22, Color(1.0, 0.87, 0.3))
	title.position = Vector2(20, 14)
	add_child(title)

	_lbl_instruction = make_label(step_data.get("instruction", ""), 13, Color(0.95, 0.92, 0.82))
	_lbl_instruction.position = Vector2(20, 50)
	_lbl_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_instruction.custom_minimum_size.x = 600
	add_child(_lbl_instruction)

	# Plate visual
	var plate_bg = ColorRect.new()
	plate_bg.color = Color(0.92, 0.90, 0.88)
	plate_bg.size = Vector2(160, 90)
	plate_bg.position = Vector2(240, 115)
	add_child(plate_bg)

	var plate_lbl = make_label("🍽️", 52, Color(1, 1, 1))
	plate_lbl.position = Vector2(286, 110)
	add_child(plate_lbl)

	# Current ingredient display
	var cur_lbl = make_label("Place this ingredient:", 15, Color(0.9, 0.9, 0.9))
	cur_lbl.position = Vector2(20, 225)
	add_child(cur_lbl)

	_current_ingr_lbl = make_label("", 22, Color(1, 0.87, 0.3))
	_current_ingr_lbl.position = Vector2(20, 248)
	add_child(_current_ingr_lbl)

	# Zone buttons (3 zones, press 1/2/3)
	var zone_colors = [Color(0.25, 0.5, 0.85), Color(0.75, 0.3, 0.3), Color(0.3, 0.65, 0.3)]
	var zone_positions = [Vector2(60, 310), Vector2(240, 310), Vector2(420, 310)]
	for i in range(3):
		var zb = ColorRect.new()
		zb.color = zone_colors[i]
		zb.size = Vector2(130, 80)
		zb.position = zone_positions[i]
		add_child(zb)
		_zones.append(zb)
		_zone_flash.append(0.0)

		var kb = make_label("[%d]" % (i + 1), 22, Color(1, 1, 1))
		kb.position = zone_positions[i] + Vector2(45, 10)
		add_child(kb)

		var zlbl = make_label("", 13, Color(1, 1, 1))
		zlbl.position = zone_positions[i] + Vector2(8, 42)
		add_child(zlbl)
		_zone_labels.append(zlbl)

	_lbl_status = make_label("", 18, Color(1, 0.9, 0.2))
	_lbl_status.position = Vector2(180, 405)
	add_child(_lbl_status)

	var hint = make_label("Press  1 / 2 / 3  to place ingredient in that zone", 13, Color(0.65, 0.65, 0.65))
	hint.position = Vector2(120, 430)
	add_child(hint)

	_lbl_timer = make_label("Time: %.1f" % _time_limit, 15, Color(1.0, 0.6, 0.3))
	_lbl_timer.position = Vector2(500, 14)
	add_child(_lbl_timer)

	_result_label = make_label("", 22, Color(1, 0.85, 0.1))
	_result_label.position = Vector2(180, 452)
	_result_label.visible = false
	add_child(_result_label)

	_refresh_display()

func _generate_zones() -> void:
	_correct_zone_idx = randi() % 3

func _refresh_display() -> void:
	if _current_ingredient_idx >= _ingredients.size():
		return

	var ingr = _ingredients[_current_ingredient_idx]
	# Format ingredient name nicely
	var nice = ingr.replace("icon_", "").replace("_", " ").capitalize()
	_current_ingr_lbl.text = "🥗 " + nice + " (%d/%d)" % [_current_ingredient_idx + 1, _ingredients.size()]

	_correct_zone_idx = randi() % 3
	# Generate zone names: one correct, two plausible-wrong
	var zone_names = ["Left side", "Center", "Right garnish", "On top", "Beside sauce", "Under flan"]
	zone_names.shuffle()
	# Correct zone gets the ingredient's name
	for i in range(3):
		if i == _correct_zone_idx:
			_zone_labels[i].text = nice
		else:
			_zone_labels[i].text = zone_names[i]

func _on_update(delta: float, _remaining: float) -> void:
	# Decay zone flashes
	for i in range(3):
		if _zone_flash[i] > 0.0:
			_zone_flash[i] -= delta
			var base_colors = [Color(0.25, 0.5, 0.85), Color(0.75, 0.3, 0.3), Color(0.3, 0.65, 0.3)]
			_zones[i].color = base_colors[i].lerp(Color.WHITE, _zone_flash[i])

func _input(event: InputEvent) -> void:
	if _finished:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			_place_ingredient(0)
		elif event.keycode == KEY_2:
			_place_ingredient(1)
		elif event.keycode == KEY_3:
			_place_ingredient(2)

func _place_ingredient(zone: int) -> void:
	if _current_ingredient_idx >= _ingredients.size():
		return
	if zone == _correct_zone_idx:
		_correct_placements += 1
		_lbl_status.text = "✅ Tama! (Correct!)"
		_lbl_status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		_zone_flash[zone] = 0.4
		_zones[zone].color = Color(0.2, 0.9, 0.3)
	else:
		_wrong_placements += 1
		_lbl_status.text = "❌ Mali! (Wrong spot!)"
		_lbl_status.add_theme_color_override("font_color", Color(1, 0.3, 0.1))
		_zone_flash[zone] = 0.4
		_zones[zone].color = Color(0.9, 0.2, 0.2)

	_current_ingredient_idx += 1
	if _current_ingredient_idx >= _ingredients.size():
		var skill = float(_correct_placements) / float(_ingredients.size())
		_result_label.text = "🍽️ Handa na! (Dish served!) ✨"
		_result_label.visible = true
		complete_minigame(skill)
	else:
		_refresh_display()

func _update_timer_display(remaining: float) -> void:
	if _lbl_timer:
		_lbl_timer.text = "Time: %.1f" % maxf(0.0, remaining)
		if remaining < 5.0:
			_lbl_timer.add_theme_color_override("font_color", Color(1, 0.2, 0.2))

func _force_finish() -> void:
	var total = _ingredients.size()
	var skill = float(_correct_placements) / float(max(1, total))
	complete_minigame(skill)
