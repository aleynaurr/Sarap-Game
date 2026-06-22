extends CharacterBody2D

const SPEED := 120.0

# Sprite sheet layout: 4 cols × 4 rows (frames × directions)
# Row 0 = down, Row 1 = up, Row 2 = left, Row 3 = right
const FRAME_W   := 64
const FRAME_H   := 128
const ANIM_FPS  := 8.0

var _facing: int = 0   # 0=down 1=up 2=left 3=right
var _frame: int = 0
var _anim_timer: float = 0.0
var _moving: bool = false

# Nearest station in range
var _nearby_station = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt_node: Node2D = $InteractPrompt
@onready var collision: CollisionShape2D = $CollisionShape2D

signal interact_pressed(station)

func _ready() -> void:
	_update_frame()
	if prompt_node:
		prompt_node.visible = false

func _physics_process(delta: float) -> void:
	if not GameManager.game_active:
		return

	var dir := Vector2.ZERO
	if Input.is_action_pressed("move_up"):    dir.y -= 1
	if Input.is_action_pressed("move_down"):  dir.y += 1
	if Input.is_action_pressed("move_left"):  dir.x -= 1
	if Input.is_action_pressed("move_right"): dir.x += 1

	_moving = dir.length_squared() > 0.0

	if _moving:
		dir = dir.normalized()
		velocity = dir * SPEED
		# Determine facing from dominant axis
		if abs(dir.x) >= abs(dir.y):
			_facing = 3 if dir.x > 0 else 2
		else:
			_facing = 0 if dir.y > 0 else 1
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED * 2 * delta)

	move_and_slide()

	# Animate walk cycle
	_anim_timer += delta
	if _anim_timer >= 1.0 / ANIM_FPS:
		_anim_timer = 0.0
		if _moving:
			_frame = (_frame + 1) % 4
		else:
			_frame = 0
	_update_frame()

	# E to interact
	if Input.is_action_just_pressed("interact") and _nearby_station != null:
		interact_pressed.emit(_nearby_station)

func _update_frame() -> void:
	if not sprite:
		return
	var col = _frame
	var row = _facing
	sprite.region_enabled = true
	sprite.region_rect = Rect2(col * FRAME_W, row * FRAME_H, FRAME_W, FRAME_H)

func set_nearby_station(station) -> void:
	_nearby_station = station
	if prompt_node:
		prompt_node.visible = (station != null)

func disable() -> void:
	set_physics_process(false)
	velocity = Vector2.ZERO
	if prompt_node:
		prompt_node.visible = false

func enable() -> void:
	set_physics_process(true)
