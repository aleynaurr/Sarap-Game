extends Control
## Draws the broken (dashed) guide line for the current peel zone.
## Untraced points render as a bright marker; traced points render dimmed,
## giving the player live feedback on how much of the line they've covered.

const POINT_RADIUS_UNTRACED := 8.0
const POINT_RADIUS_TRACED   := 6.0
const COLOR_UNTRACED := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_TRACED   := Color(0.3, 1.0, 0.4, 0.8)
const COLOR_CONNECT  := Color(1.0, 1.0, 1.0, 0.7)
const COLOR_BORDER   := Color(0.0, 0.0, 0.0, 1.0)

@onready var _owner_script = get_parent().get_parent()  # EggplantArea -> PeelMinigame

func _draw() -> void:
	if _owner_script == null:
		return
	var points: Array = _owner_script.get_path_points()
	var traced: Array  = _owner_script.get_path_traced()
	if points.is_empty():
		return
	
	# Convert points from EggplantArea's coords to PathDraw's local coords
	var local_points: Array = []
	for p in points:
		var eggplant_global = get_parent().global_position
		var pathdraw_global = global_position
		# Calculate position relative to PathDraw
		var local_p = (eggplant_global + p) - pathdraw_global
		local_points.append(local_p)

	# Faint connecting line so the dashed path still reads as one path, with black border
	for i in range(local_points.size() - 1):
		# Draw black border first (thicker)
		draw_line(local_points[i], local_points[i + 1], COLOR_BORDER, 5.0)
		# Then white line on top
		draw_line(local_points[i], local_points[i + 1], COLOR_CONNECT, 3.0)

	for i in range(local_points.size()):
		var is_traced: bool = (i < traced.size() and traced[i])
		var col := COLOR_TRACED if is_traced else COLOR_UNTRACED
		var rad := POINT_RADIUS_TRACED if is_traced else POINT_RADIUS_UNTRACED
		# Draw black border circle first
		draw_circle(local_points[i], rad + 2.0, COLOR_BORDER)
		# Then white/colored circle on top
		draw_circle(local_points[i], rad, col)
