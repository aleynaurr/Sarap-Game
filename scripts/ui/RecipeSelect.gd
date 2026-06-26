extends Control
# RecipeSelect — logic controller for the static book UI in RecipeSelect.tscn.
# All static layout nodes are defined in the .tscn and fully editable in the
# Godot editor. This script only handles:
#   • Connecting buttons to region-selection logic
#   • Styling region buttons (normal / selected states)
#   • Dynamically populating the right page with recipe cards at runtime

const REGION_DATA = {
	"luzon":    {"label": "LUZON",    "emoji": "🗺️", "color": Color(0.20, 0.55, 0.28)},
	"visayas":  {"label": "VISAYAS",  "emoji": "🌊", "color": Color(0.18, 0.42, 0.72)},
	"mindanao": {"label": "MINDANAO", "emoji": "🌿", "color": Color(0.58, 0.26, 0.14)},
}

const RECIPE_EMOJIS = {
	"kulawong_talong":   "🍆",
	"sinigang_na_baboy": "🍲",
	"kaldereta":         "🥩",
	"tortang_talong":    "🍳",
	"lumpiang_shanghai": "🌯",
	"halo_halo":         "🍧",
}

# Static nodes (set via @onready from the .tscn)
<<<<<<< HEAD
@onready var btn_luzon:    Button       = $LeftPage/BtnLuzon
@onready var btn_visayas:  Button       = $LeftPage/BtnVisayas
@onready var btn_mindanao: Button       = $LeftPage/BtnMindanao
=======
@onready var btn_luzon:    Button       = $LeftPage/VBoxContainer2/BtnLuzon
@onready var btn_visayas:  Button       = $LeftPage/VBoxContainer2/BtnVisayas
@onready var btn_mindanao: Button       = $LeftPage/VBoxContainer2/BtnMindanao
>>>>>>> krysta
@onready var back_button:  Button       = $LeftPage/BackButton
@onready var right_content: VBoxContainer = $RightPage/RightContent

var _selected_region: String = ""
var _region_btns: Dictionary = {}

func _ready() -> void:
	_region_btns = {
		"luzon":    btn_luzon,
		"visayas":  btn_visayas,
		"mindanao": btn_mindanao,
	}

	back_button.pressed.connect(func(): GameManager.go_to_main_menu())
	btn_luzon.pressed.connect(_on_region_selected.bind("luzon"))
	btn_visayas.pressed.connect(_on_region_selected.bind("visayas"))
	btn_mindanao.pressed.connect(_on_region_selected.bind("mindanao"))

	# Apply initial button styles
	for rkey in _region_btns:
		_apply_btn_style(_region_btns[rkey], REGION_DATA[rkey]["color"], false)

	# Open to Luzon by default
	_on_region_selected("luzon")

# ─── Region selection ─────────────────────────────────────────────────────────
func _on_region_selected(region_id: String) -> void:
	_selected_region = region_id
	for rkey in _region_btns:
		_apply_btn_style(_region_btns[rkey], REGION_DATA[rkey]["color"], rkey == region_id)
	_populate_right_page(region_id)

func _apply_btn_style(btn: Button, col: Color, selected: bool) -> void:
	var s = StyleBoxFlat.new()
	s.bg_color     = col.lightened(0.15) if selected else col.darkened(0.15)
	s.border_color = Color(1.0, 0.88, 0.2) if selected else col.lightened(0.3)
	s.set_border_width_all(3 if selected else 2)
	s.corner_radius_top_left     = 5
	s.corner_radius_top_right    = 5
	s.corner_radius_bottom_left  = 5
	s.corner_radius_bottom_right = 5
	btn.add_theme_stylebox_override("normal", s)

	var h = StyleBoxFlat.new()
	h.bg_color     = col.lightened(0.25)
	h.border_color = Color(1, 0.9, 0.4)
	h.set_border_width_all(3)
	h.corner_radius_top_left     = 5
	h.corner_radius_top_right    = 5
	h.corner_radius_bottom_left  = 5
	h.corner_radius_bottom_right = 5
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", h)

# ─── Right page content ───────────────────────────────────────────────────────
func _populate_right_page(region_id: String) -> void:
	for child in right_content.get_children():
		child.queue_free()

	var rd      = REGION_DATA[region_id]
	var recipes = RecipeData.get_recipes_for_region(region_id)
	var ri      = RecipeData.get_region_info(region_id)

	# Region header
	var reg_lbl = Label.new()
	reg_lbl.text = rd["emoji"] + "  " + ri.get("name", region_id.capitalize())
	reg_lbl.add_theme_font_size_override("font_size", 22)
	reg_lbl.add_theme_color_override("font_color", rd["color"])
	reg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_content.add_child(reg_lbl)

	var div = ColorRect.new()
	div.custom_minimum_size = Vector2(0, 2)
	div.color = rd["color"].lightened(0.3)
	right_content.add_child(div)

	if recipes.is_empty():
		var none_lbl = Label.new()
		none_lbl.text = "Recipes coming soon!"
		none_lbl.add_theme_font_size_override("font_size", 13)
		none_lbl.add_theme_color_override("font_color", Color(0.55, 0.40, 0.22))
		right_content.add_child(none_lbl)
		return

	for recipe in recipes:
		_add_recipe_card(recipe, rd["color"])

func _add_recipe_card(recipe: Dictionary, accent: Color) -> void:
	var rid   = recipe.get("id", "")
	var steps = recipe.get("steps", [])
	var emoji = RECIPE_EMOJIS.get(rid, "🍽️")

	var card = PanelContainer.new()
	var cs = StyleBoxFlat.new()
	cs.bg_color = Color(0.93, 0.88, 0.74)
	cs.border_color = accent.lightened(0.2)
	cs.set_border_width_all(2)
	cs.corner_radius_top_left     = 6
	cs.corner_radius_top_right    = 6
	cs.corner_radius_bottom_left  = 6
	cs.corner_radius_bottom_right = 6
	card.add_theme_stylebox_override("panel", cs)
	right_content.add_child(card)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	card.add_child(vbox)

	# Name + emoji row
	var name_row = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	vbox.add_child(name_row)

	var el = Label.new()
	el.text = emoji
	el.add_theme_font_size_override("font_size", 26)
	name_row.add_child(el)

	var name_col = VBoxContainer.new()
	name_row.add_child(name_col)

	var nl = Label.new()
	nl.text = recipe.get("display_name", "???")
	nl.add_theme_font_size_override("font_size", 15)
	nl.add_theme_color_override("font_color", Color(0.22, 0.14, 0.06))
	name_col.add_child(nl)

	var ll = Label.new()
	ll.text = "📍 Philippines  •  %d steps" % steps.size()
	ll.add_theme_font_size_override("font_size", 10)
	ll.add_theme_color_override("font_color", Color(0.45, 0.32, 0.18))
	name_col.add_child(ll)

	# Description
	var dl = Label.new()
	dl.text = recipe.get("description", "")
	dl.add_theme_font_size_override("font_size", 11)
	dl.add_theme_color_override("font_color", Color(0.35, 0.25, 0.14))
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(dl)

	# Steps preview
	var pl = Label.new()
	var lines: Array = []
	for i in mini(3, steps.size()):
		lines.append("  %d. %s" % [i+1, steps[i].get("name","Step")])
	if steps.size() > 3:
		lines.append("  ... and %d more steps" % (steps.size()-3))
	pl.text = "\n".join(lines)
	pl.add_theme_font_size_override("font_size", 10)
	pl.add_theme_color_override("font_color", Color(0.40, 0.28, 0.12))
	vbox.add_child(pl)

	# Play button
	var pb = Button.new()
	pb.text = "▶  MAGLUTO!  (Play)"
	pb.add_theme_font_size_override("font_size", 13)
	var ps = StyleBoxFlat.new()
	ps.bg_color = accent.darkened(0.05)
	ps.border_color = Color(1, 0.9, 0.3)
	ps.set_border_width_all(2)
	ps.corner_radius_top_left     = 5
	ps.corner_radius_top_right    = 5
	ps.corner_radius_bottom_left  = 5
	ps.corner_radius_bottom_right = 5
	pb.add_theme_stylebox_override("normal", ps)
	pb.add_theme_color_override("font_color", Color(1, 0.97, 0.88))
	pb.pressed.connect(_on_play.bind(rid))
	vbox.add_child(pb)

func _on_play(recipe_id: String) -> void:
	AudioManager.play_sfx(AudioManager.SFX_CLICK)
	GameManager.start_recipe(recipe_id)
