extends Control
# RecipeSelect — logic controller for the map-pointer book UI in RecipeSelect.tscn.
#
# Left page  : a map of the Philippines with 3 pointer hotspots. Pointer
#              positions are now set directly in the .tscn (drag them in the
#              editor); this script just reads whatever position each pointer
#              node already has and uses that as its "rest" position for
#              hover/bob animation. Only the top ("Luzon") pointer is
#              currently unlocked.
# Right page : shows recipe details for whichever unlocked pointer is
#              selected, or a prompt label when nothing is selected yet.
#
# All static layout is defined in RecipeSelect.tscn and fully editable in the
# Godot editor. Placeholder art referenced here lives in:
#   res://assets/sprites/ui/RecipeSelectImg/
# and is safe to swap out for final art later (see note at bottom of file).

# ─── Pointer / recipe configuration ────────────────────────────────────────
# NOTE: positions are no longer computed from a "frac" value here — they are
# whatever you've placed the PointerLuzon / PointerVisayas / PointerMindanao
# nodes at in RecipeSelect.tscn. This dictionary now only holds recipe data.
const POINTER_CONFIG := {
	"luzon": {
		"unlocked": true,
		"recipe_id": "kulawong_talong",
		"dish_name": "Kulawong Talong",
		"region": "Luzon",
		"location": "Laguna, Philippines",
		"description": "Kulawong Talong is a traditional Filipino dish featuring char-grilled eggplants in a creamy, smoky dressing made from grated coconut meat toasted over hot embers. Originating as a pre-colonial delicacy in the provinces of Laguna and Quezon, it remains a celebrated regional treasure crafted by ancestral households.",
	},
	"visayas": {
		"unlocked": false,
	},
	"mindanao": {
		"unlocked": false,
	},
}

const POINTER_ORDER := ["luzon", "visayas", "mindanao"]

const IMG_DIR := "res://assets/sprites/ui/RecipeSelectImg/"
const TEX_POINTER_NORMAL   := IMG_DIR + "map_pointer_normal.png"
const TEX_POINTER_SELECTED := IMG_DIR + "map_pointer_selected.png"

const HOVER_BRIGHTEN      := Color(1.35, 1.35, 1.35, 1.0)
const NORMAL_MODULATE     := Color(1, 1, 1, 1)
const VIDEO_HOVER_BRIGHT  := Color(1.18, 1.18, 1.18, 1.0)
const PLAY_HOVER_BRIGHT   := Color(1.35, 1.35, 1.35, 1.0)

const FADE_IN_DURATION    := 0.35
const FADE_STAGGER_DELAY  := 0.15
const POINTER_POP_DELAY   := 0.12
const BOB_AMPLITUDE        := 5.0
const BOB_DURATION         := 0.55
const LOCKED_POPUP_SECONDS := 3.0

# ─── Video frame styling (rounded/circular mask + drop shadow) ─────────────
# Bump this toward min(video_box.size)/2 to make the video a full circle
# instead of a rounded rectangle.
const VIDEO_CORNER_RADIUS  := 28.0
const VIDEO_SHADOW_COLOR   := Color(0, 0, 0, 0.25)
const VIDEO_SHADOW_SIZE    := 100
const VIDEO_SHADOW_OFFSET  := Vector2(0, 2)
const ROUNDED_MASK_SHADER  := "res://assets/shaders/rounded_mask.gdshader"

# ─── Static nodes ───────────────────────────────────────────────────────────
@onready var back_button:  Button = $LeftPage/BackButton
@onready var map_image:    TextureRect = $LeftPage/MapContainer/MapImage

@onready var right_content:      VBoxContainer = $RightPage/RightContent
@onready var default_label:      Label = $RightPage/RightContent/DefaultLabel
@onready var dish_name_label:    Label = $RightPage/RightContent/DishNameLabel
@onready var video_box:          Control = $RightPage/RightContent/VideoBox
@onready var video_placeholder_bg: TextureRect = $RightPage/RightContent/VideoBox/VideoPlaceholderBG
@onready var video_player:       VideoStreamPlayer = $RightPage/RightContent/VideoBox/VideoStreamPlayer
@onready var play_button:        TextureButton = $RightPage/RightContent/VideoBox/PlayButton
@onready var region_label:       Label = $RightPage/RightContent/RegionLabel
@onready var location_label:     Label = $RightPage/RightContent/LocationLabel
@onready var description_label:  Label = $RightPage/RightContent/DescriptionLabel

@onready var popup_locked: Control = $PopupLocked
@onready var popup_label:  Label = $PopupLocked/PopupBG/PopupLabel

var _pointer_nodes: Dictionary = {}       # id -> TextureButton
var _pointer_base_pos: Dictionary = {}    # id -> Vector2 (rest position, read from .tscn)
var _pointer_bob_tween: Dictionary = {}   # id -> Tween (currently running bob)
var _selected_id: String = ""
var _reveal_token: int = 0

# Hover is now tracked as two independent flags. The play button only ever
# hides when NEITHER the video box NOR the play button itself is hovered.
var _video_area_hovered: bool = false
var _play_button_hovered: bool = false
var _hover_update_queued: bool = false

var _popup_tween: Tween
var _video_shadow_panel: Panel


func _ready() -> void:
	back_button.pressed.connect(func(): GameManager.go_to_main_menu())

	_pointer_nodes = {
		"luzon":    $LeftPage/MapContainer/PointerLuzon,
		"visayas":  $LeftPage/MapContainer/PointerVisayas,
		"mindanao": $LeftPage/MapContainer/PointerMindanao,
	}

	for id in POINTER_ORDER:
		var btn: TextureButton = _pointer_nodes[id]
		btn.pressed.connect(_on_pointer_pressed.bind(id))
		btn.mouse_entered.connect(_on_pointer_hover.bind(id, true))
		btn.mouse_exited.connect(_on_pointer_hover.bind(id, false))
		btn.pivot_offset = btn.size / 2.0

	play_button.pressed.connect(_on_play_pressed)
	play_button.mouse_entered.connect(_on_play_hover.bind(true))
	play_button.mouse_exited.connect(_on_play_hover.bind(false))

	video_box.mouse_entered.connect(_on_video_hover.bind(true))
	video_box.mouse_exited.connect(_on_video_hover.bind(false))
	video_box.pivot_offset = video_box.size / 2.0

	popup_locked.pivot_offset = popup_locked.size / 2.0
	popup_locked.visible = false
	popup_locked.scale = Vector2.ZERO

	_setup_video_frame_style()
	_update_video_display()
	_layout_pointers()
	_init_right_page_state()
	_play_entrance_animation()


# ─── Layout ─────────────────────────────────────────────────────────────────
func _layout_pointers() -> void:
	# Pointer positions are now hand-placed in RecipeSelect.tscn. We simply
	# record whatever position each pointer already has as its "rest"
	# position, which the hover/bob/select animations tween relative to.
	# (If you drag a pointer to a new spot in the editor, this will just
	# pick up the new position automatically — no script changes needed.)
	for id in POINTER_ORDER:
		var btn: TextureButton = _pointer_nodes[id]
		_pointer_base_pos[id] = btn.position


# ─── Video frame styling (rounded/circular mask + drop shadow) ─────────────
func _setup_video_frame_style() -> void:
	# 1) Drop shadow: a Panel placed behind the video content, using a
	#    StyleBoxFlat whose corner radius matches the mask shader below and
	#    whose fill is fully transparent (so only the shadow renders).
	_video_shadow_panel = Panel.new()
	_video_shadow_panel.name = "VideoShadow"
	_video_shadow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video_shadow_panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.shadow_color = VIDEO_SHADOW_COLOR
	sb.shadow_size = VIDEO_SHADOW_SIZE
	sb.shadow_offset = VIDEO_SHADOW_OFFSET
	sb.corner_radius_top_left = int(VIDEO_CORNER_RADIUS)
	sb.corner_radius_top_right = int(VIDEO_CORNER_RADIUS)
	sb.corner_radius_bottom_left = int(VIDEO_CORNER_RADIUS)
	sb.corner_radius_bottom_right = int(VIDEO_CORNER_RADIUS)
	_video_shadow_panel.add_theme_stylebox_override("panel", sb)

	video_box.add_child(_video_shadow_panel)
	video_box.move_child(_video_shadow_panel, 0)  # behind everything else in the box

	# 2) Rounded/circular mask: a canvas_item shader that discards pixels
	#    outside a rounded-rect (push VIDEO_CORNER_RADIUS up toward
	#    min(size)/2 for a full circle) applied to whatever actually shows
	#    the video frame (placeholder art and the real video player).
	var mask_shader := load(ROUNDED_MASK_SHADER)
	if mask_shader == null:
		push_warning("RecipeSelect: rounded_mask.gdshader not found at " + ROUNDED_MASK_SHADER)
		return

	for node in [video_placeholder_bg, video_player]:
		var mat := ShaderMaterial.new()
		mat.shader = mask_shader
		mat.set_shader_parameter("corner_radius", VIDEO_CORNER_RADIUS)
		node.material = mat


# ─── Entrance animation ─────────────────────────────────────────────────────
func _init_right_page_state() -> void:
	default_label.modulate.a = 0.0
	default_label.visible = true

	for n in [dish_name_label, video_box, region_label, location_label, description_label]:
		n.visible = false
		n.modulate.a = 0.0

	map_image.modulate.a = 0.0
	for id in POINTER_ORDER:
		var btn: TextureButton = _pointer_nodes[id]
		btn.modulate.a = 0.0
		btn.scale = Vector2.ZERO


func _play_entrance_animation() -> void:
	# 1) Fade in the map + the default prompt label together.
	var fade_tw := create_tween().set_parallel(true)
	fade_tw.tween_property(map_image, "modulate:a", 1.0, 0.5)
	fade_tw.tween_property(default_label, "modulate:a", 1.0, 0.5)
	await fade_tw.finished

	# 2) Pop the pointers in, one by one, top to bottom.
	for id in POINTER_ORDER:
		var btn: TextureButton = _pointer_nodes[id]
		var pop_tw := create_tween()
		pop_tw.tween_property(btn, "modulate:a", 1.0, 0.18)
		pop_tw.parallel().tween_property(btn, "scale", Vector2(1.15, 1.15), 0.16) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop_tw.tween_property(btn, "scale", Vector2.ONE, 0.10) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(POINTER_POP_DELAY).timeout


# ─── Pointer hover / selection ──────────────────────────────────────────────
func _on_pointer_hover(is_entering: bool, id: String) -> void:
	var btn: TextureButton = _pointer_nodes[id]
	var target := HOVER_BRIGHTEN if is_entering else NORMAL_MODULATE
	var tw := create_tween()
	tw.tween_property(btn, "modulate", target, 0.15)


func _on_pointer_pressed(id: String) -> void:
	var cfg: Dictionary = POINTER_CONFIG[id]
	if not cfg.get("unlocked", false):
		AudioManager.play_sfx(AudioManager.SFX_CLICK)
		_show_locked_popup()
		return

	if _selected_id == id:
		return

	AudioManager.play_sfx(AudioManager.SFX_CLICK)
	_select_pointer(id)


func _select_pointer(id: String) -> void:
	var previous_id := _selected_id
	_selected_id = id

	if previous_id != "" and previous_id != id:
		_set_pointer_selected_visual(previous_id, false)

	_set_pointer_selected_visual(id, true)
	_reveal_recipe_content(POINTER_CONFIG[id])


func _set_pointer_selected_visual(id: String, selected: bool) -> void:
	var btn: TextureButton = _pointer_nodes[id]
	if selected:
		btn.texture_normal = load(TEX_POINTER_SELECTED)
		_start_pointer_bob(id)
	else:
		btn.texture_normal = load(TEX_POINTER_NORMAL)
		_stop_pointer_bob(id)
		btn.position = _pointer_base_pos[id]


func _start_pointer_bob(id: String) -> void:
	_stop_pointer_bob(id)
	var btn: TextureButton = _pointer_nodes[id]
	var base_pos: Vector2 = _pointer_base_pos[id]
	btn.position = base_pos
	var tw := create_tween()
	tw.set_loops()
	tw.tween_property(btn, "position:y", base_pos.y - BOB_AMPLITUDE, BOB_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(btn, "position:y", base_pos.y + BOB_AMPLITUDE * 0.4, BOB_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(btn, "position:y", base_pos.y, BOB_DURATION * 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pointer_bob_tween[id] = tw


func _stop_pointer_bob(id: String) -> void:
	if _pointer_bob_tween.has(id) and _pointer_bob_tween[id] != null:
		var tw: Tween = _pointer_bob_tween[id]
		if tw.is_valid():
			tw.kill()
		_pointer_bob_tween[id] = null


# ─── Right page reveal ───────────────────────────────────────────────────────
func _reveal_recipe_content(data: Dictionary) -> void:
	_reveal_token += 1
	var my_token := _reveal_token

	# Hide the default prompt immediately.
	var hide_tw := create_tween()
	hide_tw.tween_property(default_label, "modulate:a", 0.0, 0.15)
	hide_tw.tween_callback(func():
		if my_token == _reveal_token:
			default_label.visible = false
	)

	dish_name_label.text = data.get("dish_name", "")
	region_label.text = data.get("region", "")
	location_label.text = data.get("location", "")
	description_label.text = data.get("description", "")
	_update_video_display()

	var sequence := [dish_name_label, video_box, region_label, location_label, description_label]
	for n in sequence:
		if my_token != _reveal_token:
			return
		n.modulate.a = 0.0
		n.visible = true
		var tw := create_tween()
		tw.tween_property(n, "modulate:a", 1.0, FADE_IN_DURATION).set_trans(Tween.TRANS_SINE)
		await get_tree().create_timer(FADE_STAGGER_DELAY).timeout


# ─── Video box hover / play button ───────────────────────────────────────────
func _update_video_display() -> void:
	# No real video assigned yet -> show the placeholder art instead.
	var has_stream: bool = video_player != null and video_player.stream != null
	video_placeholder_bg.visible = not has_stream
	video_player.visible = has_stream


func _on_video_hover(is_entering: bool) -> void:
	_video_area_hovered = is_entering
	_queue_hover_update()


func _on_play_hover(is_entering: bool) -> void:
	_play_button_hovered = is_entering

	# Only tween the RGB channels here so this doesn't fight with the alpha
	# fade driven by _update_play_button_visibility() below.
	var target: Color = PLAY_HOVER_BRIGHT if is_entering else Color(1, 1, 1)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(play_button, "modulate:r", target.r, 0.12)
	tw.tween_property(play_button, "modulate:g", target.g, 0.12)
	tw.tween_property(play_button, "modulate:b", target.b, 0.12)

	_queue_hover_update()


func _queue_hover_update() -> void:
	# video_box and play_button overlap, and Godot can fire video_box's
	# mouse_exited followed immediately by play_button's mouse_entered (or
	# vice versa) within the same input event. Evaluating state right away
	# would apply the "exited" state for one frame and then immediately
	# undo it, which looks like a flicker/shrink. Deferring the actual
	# update lets all of that frame's hover signals land first, so we only
	# ever react to the final, settled state.
	if _hover_update_queued:
		return
	_hover_update_queued = true
	call_deferred("_apply_hover_update")


func _apply_hover_update() -> void:
	_hover_update_queued = false
	_update_video_scale_and_tint()
	_update_play_button_visibility()


func _update_video_scale_and_tint() -> void:
	# Scale/tint stays "hovered" as long as EITHER the video box OR the play
	# button is hovered, so mousing over the button doesn't snap the video
	# back down to its resting size.
	var should_grow := _video_area_hovered or _play_button_hovered

	var tw := create_tween().set_parallel(true)
	if should_grow:
		tw.tween_property(video_box, "scale", Vector2(1.05, 1.05), 0.2) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(video_box, "modulate", VIDEO_HOVER_BRIGHT, 0.2)
	else:
		tw.tween_property(video_box, "scale", Vector2.ONE, 0.25) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(video_box, "modulate", NORMAL_MODULATE, 0.25)


func _update_play_button_visibility() -> void:
	# The button should stay visible as long as EITHER the video box OR the
	# button itself is hovered — this is what stops it from disappearing
	# out from under the cursor while the user is hovering it directly.
	var should_show := _video_area_hovered or _play_button_hovered

	if should_show:
		play_button.visible = true
		var tw := create_tween()
		tw.tween_property(play_button, "modulate:a", 1.0, 0.2)
	else:
		var tw := create_tween()
		tw.tween_property(play_button, "modulate:a", 0.0, 0.2)
		tw.tween_callback(func():
			if not _video_area_hovered and not _play_button_hovered:
				play_button.visible = false
		)


func _on_play_pressed() -> void:
	if _selected_id == "":
		return
	var cfg: Dictionary = POINTER_CONFIG[_selected_id]
	var recipe_id: String = cfg.get("recipe_id", "")
	if recipe_id == "":
		return
	AudioManager.play_sfx(AudioManager.SFX_CLICK)
	GameManager.start_recipe(recipe_id)


# ─── Locked-region popup ─────────────────────────────────────────────────────
func _show_locked_popup() -> void:
	if _popup_tween != null and _popup_tween.is_valid():
		_popup_tween.kill()

	popup_locked.visible = true
	popup_locked.scale = Vector2.ZERO

	_popup_tween = create_tween()
	# Pop in with a little overshoot.
	_popup_tween.tween_property(popup_locked, "scale", Vector2(1.08, 1.08), 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_popup_tween.tween_property(popup_locked, "scale", Vector2.ONE, 0.10) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Hold, then pop out.
	_popup_tween.tween_interval(LOCKED_POPUP_SECONDS)
	_popup_tween.tween_property(popup_locked, "scale", Vector2(1.1, 1.1), 0.08) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_popup_tween.tween_property(popup_locked, "scale", Vector2.ZERO, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_popup_tween.tween_callback(func(): popup_locked.visible = false)


# ─── Notes for swapping in final art later ──────────────────────────────────
# All placeholder textures live in res://assets/sprites/ui/RecipeSelectImg/ :
#   map_placeholder.png      -> LeftPage/MapContainer/MapImage.texture
#   map_pointer_normal.png   -> unselected pointer state (TEX_POINTER_NORMAL)
#   map_pointer_selected.png -> selected/red pointer state (TEX_POINTER_SELECTED)
#   video_placeholder.png    -> shown behind VideoStreamPlayer until a real
#                               video stream is assigned to VideoStreamPlayer.stream
#   play_button.png          -> PlayButton.texture_normal
#   popup_bg.png              -> PopupLocked/PopupBG texture
# Simply replace the PNGs (same filenames) or repoint the .tscn/exported
# fields to new resources — no script changes required for a pure art swap.
#
# Pointer positions: drag PointerLuzon / PointerVisayas / PointerMindanao to
# wherever you want in the RecipeSelect.tscn editor — _layout_pointers()
# reads their .tscn position automatically, no script edits needed.
#
# Video rounding/shadow: tune VIDEO_CORNER_RADIUS, VIDEO_SHADOW_COLOR,
# VIDEO_SHADOW_SIZE and VIDEO_SHADOW_OFFSET above. Set VIDEO_CORNER_RADIUS to
# min(video_box.size.x, video_box.size.y) / 2.0 for a perfect circle
# (requires video_box to be square). Requires the shader file at
# res://assets/shaders/rounded_mask.gdshader (see rounded_mask.gdshader).
