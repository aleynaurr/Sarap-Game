extends Area2D

var player1_inside := false
var player2_inside := false

func _on_body_entered(body):
	if body is Player:
		if body.player_id == 1:
			player1_inside = true
		else:
			player2_inside = true

	check_finish()

func _on_body_exited(body):
	if body is Player:
		if body.player_id == 1:
			player1_inside = false
		else:
			player2_inside = false
			
func ingredients_complete() -> bool:
	return (
		Player1Inventory.has("eggplant")
		and Player2Inventory.has("eggplant")
	)
	
func check_finish():
	if player1_inside and player2_inside and ingredients_complete():
		AudioManager.play_sfx(AudioManager.SFX_CLICK)
		GameManager.go_to_kitchen()
