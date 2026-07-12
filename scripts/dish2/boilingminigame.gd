extends MinigameBase

enum State {
	FILL_WATER, BOILING, ADD_PORK, DONE
}

var _state: State = State.FILL_WATER

@export var move_speed: float = 220.0

@export var pot_pos: Vector2 = Vector2(100, 100)
@export var pot_size: Vector2 = Vector2(200, 200)

@export var water_source_pos: Vector2 = Vector2(400, 100)
@export var water_source_size: Vector2 = Vector2(120, 120)

@export var cup_home: Vector2 = Vector2(300, 500)
@export var cup_size: Vector2 = Vector2(60, 80)

@export var hand_size: Vector2 = Vector2(56, 56)

var _hand_pos := Vector2.ZERO
var _cup_pos := Vector2.ZERO

var _cup_content := "empty"

var _water_added: int = 0
const MAX_WATER := 6


@onready var _hand_img: TextureRect = $HandSprite
@onready var _cup_img: TextureRect = $CupSprite
@onready var _pot_img: TextureRect = $PotSprite

func _on_init():
	_hand_pos = Vector2(300, 400)
	_cup_pos = cup_home

	_cup_content = "empty"
	_water_added = 0

	_apply_hand_pos()
	_apply_cup_pos()
	
func _on_update(delta: float, remaining: float) -> void:
	if _state == State.FILL_WATER:
		_update_hand(delta)
		_update_cup_drag()


func _is_grab_pressed() -> bool:
	return Input.is_action_pressed("grab_p%d" % player_number)
	
	
func _update_hand(delta: float) -> void:

	var dir := Vector2.ZERO

	if player_number == 1:
		if Input.is_action_pressed("move_up_p1"):
			dir.y -= 1
		if Input.is_action_pressed("move_down_p1"):
			dir.y += 1
		if Input.is_action_pressed("move_left_p1"):
			dir.x -= 1
		if Input.is_action_pressed("move_right_p1"):
			dir.x += 1

	else:
		if Input.is_action_pressed("move_up_p2"):
			dir.y -= 1
		if Input.is_action_pressed("move_down_p2"):
			dir.y += 1
		if Input.is_action_pressed("move_left_p2"):
			dir.x -= 1
		if Input.is_action_pressed("move_right_p2"):
			dir.x += 1


	if dir != Vector2.ZERO:
		_hand_pos += dir.normalized() * move_speed * delta


	# Keep hand inside screen
	_hand_pos.x = clamp(
		_hand_pos.x,
		0,
		640 - hand_size.x
	)

	_hand_pos.y = clamp(
		_hand_pos.y,
		0,
		720 - hand_size.y
	)
	_apply_hand_pos()

func _apply_hand_pos():

	_hand_img.offset_left = _hand_pos.x
	_hand_img.offset_top = _hand_pos.y
	_hand_img.offset_right = _hand_pos.x + hand_size.x
	_hand_img.offset_bottom = _hand_pos.y + hand_size.y

func _apply_cup_pos():

	_cup_img.offset_left = _cup_pos.x
	_cup_img.offset_top = _cup_pos.y
	_cup_img.offset_right = _cup_pos.x + cup_size.x
	_cup_img.offset_bottom = _cup_pos.y + cup_size.y
	
	
func _rect_overlap(pos_a, size_a, pos_b, size_b):

	return pos_a.x < pos_b.x + size_b.x \
	and pos_a.x + size_a.x > pos_b.x \
	and pos_a.y < pos_b.y + size_b.y \
	and pos_a.y + size_a.y > pos_b.y
	
func _hand_over_cup():

	return _rect_overlap(
		_hand_pos,
		hand_size,
		_cup_pos,
		cup_size
	)
	
func _cup_over_water():

	return _rect_overlap(
		_cup_pos,
		cup_size,
		water_source_pos,
		water_source_size
	)
	
func _cup_over_pot():

	return _rect_overlap(
		_cup_pos,
		cup_size,
		pot_pos,
		pot_size
	)
	
	
#--------------
func _update_cup_drag():

	var grab := Input.is_action_pressed("grab_p%d" % player_number)


	# Pick up cup
	if grab and _hand_over_cup():

		_cup_pos = _hand_pos
		_apply_cup_pos()


		# Fill cup
		if _cup_over_water() and _cup_content == "empty":

			_cup_content = "water"
			print("Cup filled")


	# Release cup
	if not grab and _cup_content == "water":

		if _cup_over_pot():

			_water_added += 1

			print("Water added:", _water_added)

			_cup_content = "empty"
			_cup_pos = cup_home
			_apply_cup_pos()


			if _water_added >= MAX_WATER:
				print("Water complete!")
				_state = State.DONE
