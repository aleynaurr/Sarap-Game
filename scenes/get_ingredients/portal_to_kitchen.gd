extends Area2D

var player1_inside := false
var player2_inside := false

func _ready() -> void:

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is Player:
		if body.player_id == 1:
			player1_inside = true
		elif body.player_id == 2:
			player2_inside = true
			
		print("P1 Inside: ", player1_inside, " | P2 Inside: ", player2_inside)
		check_finish()

func _on_body_exited(body):
	if body is Player:
		if body.player_id == 1:
			player1_inside = false
		elif body.player_id == 2:
			player2_inside = false
		
		print("P1 Inside: ", player1_inside, " | P2 Inside: ", player2_inside)

func ingredients_complete() -> bool:
	
	return true
	
func check_finish():
	if player1_inside and player2_inside and ingredients_complete():
		AudioManager.play_sfx("chop")
		GameManager.go_to_kitchen()
