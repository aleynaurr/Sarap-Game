extends Node
# InputSetup — defines all custom input actions in code at startup.
# This avoids hand-authoring the [input] section of project.godot, which is
# fragile across Godot versions. Runs before any other autoload needs it
# because autoloads execute _ready in declaration order, and actions are
# added in _enter_tree (earliest possible point).

func _enter_tree() -> void:
	# Player 1 inputs
	_add_action("move_up_p1",      [KEY_W])
	_add_action("move_down_p1",    [KEY_S])
	_add_action("move_left_p1",    [KEY_A])
	_add_action("move_right_p1",   [KEY_D])
	_add_action("interact_p1",     [KEY_E])
	_add_action("grab_p1",         [KEY_Q])
	
	# Player 2 inputs
	_add_action("move_up_p2",      [KEY_UP])
	_add_action("move_down_p2",    [KEY_DOWN])
	_add_action("move_left_p2",    [KEY_LEFT])
	_add_action("move_right_p2",   [KEY_RIGHT])
	_add_action("interact_p2",     [KEY_SHIFT])
	_add_action("grab_p2",         [KEY_SLASH])

func _add_action(action_name: String, keys: Array) -> void:
	if InputMap.has_action(action_name):
		InputMap.erase_action(action_name)
	InputMap.add_action(action_name)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action_name, ev)
