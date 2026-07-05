class_name GI_Input_Events2

static var direction: Vector2
static var last_direction: Vector2 = Vector2.DOWN

static func movement_input() -> Vector2:
	if Input.is_action_pressed("p2_up"):
		direction = Vector2.UP
	elif Input.is_action_pressed("p2_down"):
		direction = Vector2.DOWN
	elif Input.is_action_pressed("p2_left"):
		direction = Vector2.LEFT
	elif Input.is_action_pressed("p2_right"):
		direction = Vector2.RIGHT
	else:
		direction = Vector2.ZERO

	if direction != Vector2.ZERO:
		last_direction = direction

	return direction
	
static func is_movement_input() -> bool:
	if direction == Vector2.ZERO:
		return false
	else:
		return true
