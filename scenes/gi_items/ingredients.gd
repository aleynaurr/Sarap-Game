extends Node2D


@onready var interact_area: Interactable = $Interactable
@onready var label: Control = $Interactable/PressE
@onready var crop: AnimatedSprite2D = $AnimatedSprite2D
@onready var collectible_item: Collectable = get_node_or_null("Collect")

@onready var collect_area: Area2D = $Collect
@onready var collect_collision: CollisionShape2D = $Collect/CollisionShape2D

var is_already_collected: bool = false

var players_in_range: Array[Player] = []
var is_dropped: bool = false

func _ready() -> void:
	interact_area.interact_activated.connect(on_activated)
	interact_area.interact_deactivated.connect(on_deactivated)
	label.hide()
	
	collect_area.monitoring = false
	collect_collision.disabled = true
	

func on_activated(player: Player):
	if !players_in_range.has(player):
		players_in_range.append(player)

	label.show()
	crop.play("interact")
	
func on_deactivated(player: Player):
	players_in_range.erase(player)

	if players_in_range.is_empty():
		label.hide()
		crop.play("idle")
	
func _unhandled_input(event: InputEvent) -> void:
	if is_dropped:
		return

	for player in players_in_range:
		if player.interact_pressed(event):
			harvest_crop()
			return

func harvest_crop() -> void:
	is_dropped = true

	players_in_range.clear()

	label.hide()


	interact_area.monitoring = false
	interact_area.process_mode = PROCESS_MODE_DISABLED


	crop.play("dropped")

	collect_area.monitoring = true
	collect_collision.set_deferred("disabled", false)

	print("Crop harvested! Crop is on the ground.")
