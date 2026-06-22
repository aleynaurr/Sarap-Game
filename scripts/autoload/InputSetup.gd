extends Node
# InputSetup — defines all custom input actions in code at startup.
# This avoids hand-authoring the [input] section of project.godot, which is
# fragile across Godot versions. Runs before any other autoload needs it
# because autoloads execute _ready in declaration order, and actions are
# added in _enter_tree (earliest possible point).

func _enter_tree() -> void:
	_add_action("move_up", [KEY_W, KEY_UP])
	_add_action("move_down", [KEY_S, KEY_DOWN])
	_add_action("move_left", [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("interact", [KEY_E])

func _add_action(action_name: String, keys: Array) -> void:
	if InputMap.has_action(action_name):
		InputMap.erase_action(action_name)
	InputMap.add_action(action_name)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action_name, ev)
